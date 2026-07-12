<#
.SYNOPSIS
    EKIDMOD-Validate.ps1 — Read-only check that the enablement-lab prerequisites are met.
.DESCRIPTION
    PURPOSE
        Confirm the lab is ready before the guided labs: the pilot group exists, sample users are
        present and in it, the Microsoft.Graph module is available, and the tenant's licensing
        (P1/P2/Governance/GSA hints) is detected. Prints PASS/FAIL per check.
    HOW TO RUN
        .\EKIDMOD-Validate.ps1
        Sign in when prompted (read-only scopes). No changes are made.
    EXPECTED RESULTS
        A PASS/FAIL list. Resolve any FAIL (usually by running EKIDMOD-LabSetup.ps1 -Commit) before
        starting the labs.
.NOTES
    White-label. Read-only.
#>
[CmdletBinding()] param(
    [string]$PilotGroupName = 'Identity Modernization - Pilot - Lab'
)

$ErrorActionPreference = 'Stop'
$fail = 0
function Check($ok,$msg){ if($ok){Write-Host "  PASS  $msg" -ForegroundColor Green}else{Write-Host "  FAIL  $msg" -ForegroundColor Red; $script:fail++} }

Write-Host "`n=== Identity Modernization — Lab Prerequisite Validation ===" -ForegroundColor Cyan

# Module present
$mod = Get-Module Microsoft.Graph -ListAvailable | Select-Object -First 1
Check ($null -ne $mod) ("Microsoft.Graph module installed" + $(if($mod){" (v$($mod.Version))"}else{" — Install-Module Microsoft.Graph"}))

try { Connect-MgGraph -Scopes 'Directory.Read.All','Group.Read.All','User.Read.All' -NoWelcome } catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Red; return }

# Pilot group present (accept en-dash or hyphen)
$grp = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ErrorAction SilentlyContinue
if (-not $grp) { $grp = Get-MgGroup -All | Where-Object { $_.DisplayName -replace '[–—-]','-' -eq ($PilotGroupName -replace '[–—-]','-') } | Select-Object -First 1 }
Check ($null -ne $grp) "Pilot group present: '$PilotGroupName'"

# Members present
if ($grp) {
    $members = Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction SilentlyContinue
    Check (@($members).Count -ge 1) ("Pilot group has sample members ({0})" -f @($members).Count)
}

# Licensing hints
try {
    $skus = Get-MgSubscribedSku -All
    $plans = $skus.ServicePlans.ServicePlanName
    Check ($plans -match 'AAD_PREMIUM')    ("Entra ID P1 detected (Conditional Access)")
    Check ($plans -match 'AAD_PREMIUM_P2') ("Entra ID P2 detected (Identity Protection / PIM)")
    if ($plans -match 'Global_Secure_Access|GSA') { Write-Host "  INFO  Global Secure Access plan hint present" -ForegroundColor Cyan } else { Write-Host "  INFO  No GSA plan hint — Lab 5 may be concept-only (verify)" -ForegroundColor Cyan }
} catch { Write-Host "  INFO  Could not read SKUs: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host ""
if ($fail -eq 0) { Write-Host "All required checks passed — start Lab 1." -ForegroundColor Green }
else { Write-Host "$fail check(s) failed — resolve before starting the labs (see 06-troubleshooting.md)." -ForegroundColor Red }
