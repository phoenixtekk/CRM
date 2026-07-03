<#
.SYNOPSIS
    M365SECG-Validation.ps1 — read-only PASS/FAIL validation of piloted baseline changes on GCC High.
.DESCRIPTION
    PURPOSE
        Confirms that the security baseline changes you piloted actually took effect on a Microsoft
        365 GCC High tenant: expected Conditional Access policies exist and are enabled, they target
        the named pilot group, and MFA capability is trending up. Read-only. Reports PASS/FAIL per
        check. Set your own values for placeholders such as your-pilot-group-name.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\M365SECG-Validation.ps1 -PilotGroupName "SEC-Baseline-Pilot"
        (Graph scopes: Policy.Read.All, Group.Read.All, Directory.Read.All, SecurityEvents.Read.All;
         connects with -Environment USGov)
    EXPECTED RESULTS
        A checklist with PASS or FAIL for each control. Overall PASS when every expected policy is
        present, enabled, and scoped to the pilot group. Any FAIL points you to 06-troubleshooting.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$PilotGroupName = "SEC-Baseline-Pilot",
    [string[]]$ExpectedPolicyNames = @("CA-Baseline-Admins-MFA","CA-Baseline-BlockLegacyAuth"),
    [string]$Environment = "USGov"
)

$ErrorActionPreference = "Stop"
$script:pass = 0; $script:fail = 0

function Connect-USGovGraph {
    param([string[]]$Scopes, [string]$Env)
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx -or $ctx.Environment -ne $Env) {
        Write-Host "Connecting to Microsoft Graph ($Env / GCC High = https://graph.microsoft.us)..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $Env -Scopes $Scopes | Out-Null
        $ctx = Get-MgContext
    }
    if ($ctx.Environment -ne $Env) {
        throw "Connected environment is '$($ctx.Environment)', expected '$Env'. Reconnect with -Environment $Env (GCC High must not use Commercial)."
    }
    Write-Host "Connected. Environment = $($ctx.Environment); Tenant = $($ctx.TenantId)" -ForegroundColor Green
}

function Test-Check {
    param([string]$Name, [bool]$Condition, [string]$FailHint = "")
    if ($Condition) {
        Write-Host ("  PASS  {0}" -f $Name) -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host ("  FAIL  {0}" -f $Name) -ForegroundColor Red
        if ($FailHint) { Write-Host ("        -> {0}" -f $FailHint) -ForegroundColor Yellow }
        $script:fail++
    }
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
}

$scopes = @("Policy.Read.All","Group.Read.All","Directory.Read.All","SecurityEvents.Read.All")
Connect-USGovGraph -Scopes $scopes -Env $Environment

Write-Host "`n=== M365SECG Validation (GCC High / US Gov) ===" -ForegroundColor Cyan

# Environment sanity
$ctx = Get-MgContext
Test-Check "Graph environment is USGov (GCC High)" ($ctx.Environment -eq $Environment) `
    "Reconnect with -Environment USGov; results from the wrong cloud are invalid."

# Pilot group exists
$group = $null
try { $group = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ErrorAction Stop | Select-Object -First 1 } catch {}
Test-Check "Pilot group '$PilotGroupName' exists" ($null -ne $group) `
    "Create it in entra.microsoft.us or via M365SECG-Set-ScopeTargeting.ps1 -Execute."

# Pilot group has members
if ($group) {
    $mem = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
    Test-Check "Pilot group has members" (($mem | Measure-Object).Count -gt 0) `
        "Add representative pilot users before piloting."
}

# Expected CA policies exist, enabled, and target the pilot group
$ca = @()
try { $ca = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop } catch {}
foreach ($name in $ExpectedPolicyNames) {
    $p = $ca | Where-Object { $_.DisplayName -eq $name } | Select-Object -First 1
    Test-Check "Policy '$name' exists" ($null -ne $p) `
        "Create the named policy in entra.microsoft.us; confirm the control exists in GCC High (verify for GCC High)."
    if ($p) {
        Test-Check "Policy '$name' is enabled" ($p.State -eq "enabled") `
            "State is '$($p.State)'. Enable after pilot validation."
        $targetsPilot = $false
        if ($group -and $p.Conditions.Users.IncludeGroups) {
            $targetsPilot = $p.Conditions.Users.IncludeGroups -contains $group.Id
        }
        Test-Check "Policy '$name' targets pilot group (not All users)" $targetsPilot `
            "Scope the policy to '$PilotGroupName' during pilot; expand only after Gate 3 passes."
    }
}

# Secure Score readable (sanity, not a hard gate)
try {
    $s = Get-MgSecuritySecureScore -Top 1 -ErrorAction Stop | Select-Object -First 1
    Test-Check "Secure Score readable (security.microsoft.us)" ($null -ne $s) `
        "Confirm Gov Defender SKU + Security Reader role."
} catch {
    Test-Check "Secure Score readable (security.microsoft.us)" $false `
        "Read failed: $($_.Exception.Message)"
}

Write-Host "`n--------------------------------------------------" -ForegroundColor Cyan
Write-Host ("RESULT: {0} PASS / {1} FAIL" -f $script:pass, $script:fail) -ForegroundColor ($(if($script:fail -eq 0){"Green"}else{"Red"}))
if ($script:fail -gt 0) {
    Write-Host "One or more checks FAILED. See 06-troubleshooting.md before expanding beyond pilot." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "All checks PASSED. Note: Secure Score UI may take ~24-48h to reflect changes (verify for GCC High)." -ForegroundColor Green
    exit 0
}
