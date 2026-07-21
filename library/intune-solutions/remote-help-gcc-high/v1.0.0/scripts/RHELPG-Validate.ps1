<#
.SYNOPSIS
    RHELPG-Validate.ps1 — PASS/FAIL readiness check for Remote Help on a US Government tenant.
.DESCRIPTION
    PURPOSE
        Deterministic PASS/FAIL validation for the Government edition. Checks: (1) the SDK is connected
        to the expected sovereign environment (national-cloud endpoints, not commercial); (2) whether a
        Remote Help configuration is deployed and enabled — IF the feature is available for the tier;
        (3) an Intune RBAC role with Remote Help permissions exists. Because Remote Help is NOT offered
        on GCC High/DoD at authoring time, on those tiers checks (2)/(3) are reported as NOT-AVAILABLE
        (by design), not silently failed — the compliant alternative applies (see gcc-high-parity-notes).
        Verify availability against current Microsoft documentation. For a GCC tenant use -Environment Global.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELPG-Validate.ps1                 # GCC High (default)
        powershell -ExecutionPolicy Bypass -File .\RHELPG-Validate.ps1 -Environment USGovDoD
    GRAPH SCOPES
        DeviceManagementConfiguration.Read.All, DeviceManagementRBAC.Read.All
    EXPECTED RESULTS
        A PASS/FAIL/NOT-AVAILABLE line per check and an overall verdict. On GCC High/DoD a healthy
        result is: endpoints PASS, Remote Help NOT-AVAILABLE (expected) -> follow the alternative path.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
    All sovereign specifics are "verify against current Microsoft documentation".
#>
[CmdletBinding()] param([ValidateSet('USGov','USGovDoD','Global')][string]$Environment = 'USGov')
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementRBAC.Read.All' -NoWelcome

$sovereign = $Environment -in @('USGov','USGovDoD')
function Result($label,$state){ $c = switch($state){'PASS'{'Green'}'FAIL'{'Red'}default{'Yellow'}}; Write-Host ("  [{0,-13}] {1}" -f $state,$label) -ForegroundColor $c }
Write-Host "`n=== Remote Help validation — Government edition (env: $Environment) ===" -ForegroundColor Cyan

# Check 1 — connected to the expected sovereign environment
$ctx = Get-MgContext
$envOk = ($ctx.Environment -eq $Environment) -or ($Environment -eq 'Global' -and $ctx.Environment -in @('Global','USGov','USGovDoD'))
Result ("Connected to expected cloud plane ($($ctx.Environment))") ($(if($envOk){'PASS'}else{'FAIL'}))

# Check 2 — Remote Help deployed + enabled (only meaningful where the feature exists)
$rhState = $null
try { $rhState = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/remoteAssistanceSettings' -ErrorAction Stop).remoteAssistanceState } catch { $rhState = $null }
if ($null -eq $rhState) {
    if ($sovereign) { Result "Remote Help deployed (NOT offered on GCC High/DoD — expected; use the alternative)" 'NOT-AVAILABLE' }
    else            { Result "Remote Help deployed (no configuration found — enable it in Tenant administration)" 'FAIL' }
} else {
    Result ("Remote Help deployed + enabled (state=$rhState)") ($(if($rhState -eq 'enabled'){'PASS'}else{'FAIL'}))
}

# Check 3 — an RBAC role with Remote Help permissions exists
try {
    $roles = @((Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions?$top=200').value)
    $hasRh = $roles | Where-Object { (@($_.rolePermissions.resourceActions.allowedResourceActions) -join ';') -match 'RemoteAssistance|RemoteHelp|RemoteTasks' }
    if ($hasRh) { Result "RBAC role with Remote Help permissions present" 'PASS' }
    elseif ($sovereign) { Result "RBAC role with Remote Help permissions (absent — expected on GCC High/DoD)" 'NOT-AVAILABLE' }
    else { Result "RBAC role with Remote Help permissions present" 'FAIL' }
} catch { Result ("RBAC read failed: " + $_.Exception.Message) 'FAIL' }

Write-Host "`nVerdict:" -ForegroundColor Cyan
if ($sovereign -and $null -eq $rhState) {
    Write-Host "  GCC High/DoD: Remote Help not available (verify). Deploy the COMPLIANT ALTERNATIVE" -ForegroundColor Yellow
    Write-Host "  (see gcc-high-parity-notes.md §4) and monitor the Microsoft roadmap." -ForegroundColor Yellow
} elseif ($rhState -eq 'enabled') {
    Write-Host "  Remote Help is enabled on the correct plane — proceed to pilot/expand." -ForegroundColor Green
} else {
    Write-Host "  Not ready — resolve the FAIL items above. Verify against current Microsoft documentation." -ForegroundColor Red
}
Disconnect-MgGraph | Out-Null
