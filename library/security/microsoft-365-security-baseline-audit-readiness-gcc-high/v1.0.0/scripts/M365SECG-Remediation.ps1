<#
.SYNOPSIS
    M365SECG-Remediation.ps1 — safe, preview-first remediation of common baseline actions on GCC High.
.DESCRIPTION
    PURPOSE
        Applies a small set of well-understood Secure Score baseline improvement actions on a Microsoft
        365 GCC High tenant via Microsoft Graph US Gov: enable a named Conditional Access policy that
        requires MFA for a target group, and (optionally) a policy that blocks legacy authentication.
        Defaults to -WhatIf (preview only) — it changes nothing until you re-run with -Execute. Set
        your own values for placeholders such as your-pilot-group-name.
    HOW TO RUN
        Preview : powershell -ExecutionPolicy Bypass -File .\M365SECG-Remediation.ps1 -PilotGroupName "SEC-Baseline-Pilot"
        Apply   : powershell -ExecutionPolicy Bypass -File .\M365SECG-Remediation.ps1 -PilotGroupName "SEC-Baseline-Pilot" -Execute
        (Graph scopes: Policy.ReadWrite.ConditionalAccess, Group.Read.All, Policy.Read.All;
         connects with -Environment USGov)
    EXPECTED RESULTS
        In -WhatIf (default): a preview of each change and NO modification. With -Execute: the named
        policies are created/updated in report-only or enabled state and scoped to the pilot group.
        PASS = preview matches your approved change ticket; then execute deliberately.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; targets Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$PilotGroupName = "SEC-Baseline-Pilot",
    [string]$MfaPolicyName  = "CA-Baseline-Admins-MFA",
    [string]$LegacyAuthPolicyName = "CA-Baseline-BlockLegacyAuth",
    [switch]$IncludeBlockLegacyAuth,
    [switch]$Execute,                 # default OFF => -WhatIf/preview only
    [string]$Environment = "USGov"
)

$ErrorActionPreference = "Stop"
$WhatIf = -not $Execute   # preview unless -Execute is explicitly passed

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
    return $ctx
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
}

Write-Host "==================================================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host " MODE: PREVIEW (-WhatIf).  No changes will be made." -ForegroundColor Yellow
    Write-Host " Re-run with -Execute to apply, after reviewing this preview." -ForegroundColor Yellow
} else {
    Write-Host " MODE: EXECUTE.  Changes WILL be applied to the GCC High tenant." -ForegroundColor Red
}
Write-Host "==================================================================" -ForegroundColor Cyan

$scopes = @("Policy.ReadWrite.ConditionalAccess","Group.Read.All","Policy.Read.All")
$ctx = Connect-USGovGraph -Scopes $scopes -Env $Environment
Write-Host "Connected. Environment = $($ctx.Environment); Tenant = $($ctx.TenantId)" -ForegroundColor Green

# Resolve pilot group
$group = Get-MgGroup -Filter "displayName eq '$PilotGroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $group) {
    throw "Pilot group '$PilotGroupName' not found. Create it first (entra.microsoft.us or M365SECG-Set-ScopeTargeting.ps1 -Execute)."
}
Write-Host "Pilot group: $PilotGroupName ($($group.Id))" -ForegroundColor Green

function Set-CaPolicy {
    param([string]$Name, [hashtable]$Conditions, [hashtable]$Grant, [string]$State)
    $existing = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -eq $Name } | Select-Object -First 1
    $verb = if ($existing) { "UPDATE" } else { "CREATE" }
    Write-Host ("`n[{0}] Conditional Access policy '{1}' -> state '{2}', scoped to '{3}'" -f $verb,$Name,$State,$PilotGroupName)
    Write-Host  "      (New/updated policies are staged; expand scope only after Gate 3 validation.)"
    if ($WhatIf) {
        Write-Host "      PREVIEW ONLY - not applied." -ForegroundColor Yellow
        return
    }
    $body = @{
        displayName = $Name
        state       = $State
        conditions  = $Conditions
        grantControls = $Grant
    }
    if ($existing) {
        Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $existing.Id -BodyParameter $body
        Write-Host "      UPDATED." -ForegroundColor Green
    } else {
        New-MgIdentityConditionalAccessPolicy -BodyParameter $body | Out-Null
        Write-Host "      CREATED." -ForegroundColor Green
    }
}

# 1) Require MFA for the pilot group (created report-only for safety; enable after validation)
$mfaConditions = @{
    users        = @{ includeGroups = @($group.Id) }
    applications = @{ includeApplications = @("All") }
    clientAppTypes = @("all")
}
$mfaGrant = @{ operator = "OR"; builtInControls = @("mfa") }
Set-CaPolicy -Name $MfaPolicyName -Conditions $mfaConditions -Grant $mfaGrant -State "enabledForReportingButNotEnforced"

# 2) Optionally block legacy authentication for the pilot group
if ($IncludeBlockLegacyAuth) {
    $legacyConditions = @{
        users        = @{ includeGroups = @($group.Id) }
        applications = @{ includeApplications = @("All") }
        clientAppTypes = @("exchangeActiveSync","other")
    }
    $legacyGrant = @{ operator = "OR"; builtInControls = @("block") }
    Set-CaPolicy -Name $LegacyAuthPolicyName -Conditions $legacyConditions -Grant $legacyGrant -State "enabledForReportingButNotEnforced"
}

Write-Host "`n------------------------------------------------------------------" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "PREVIEW complete. Nothing changed. If this matches your approved ticket, re-run with -Execute." -ForegroundColor Yellow
} else {
    Write-Host "EXECUTE complete. Policies are staged in report-only mode, scoped to the pilot group." -ForegroundColor Green
    Write-Host "Validate with M365SECG-Validation.ps1, then flip to 'enabled' and expand in gated waves." -ForegroundColor Green
}
Write-Host "Reminder: In GCC High an auth-impacting mistake has NO Commercial fallback. Pilot first." -ForegroundColor Yellow
