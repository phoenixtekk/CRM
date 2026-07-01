<#
.SYNOPSIS
    ADOBELIC-Set-ScopeTargeting.ps1 — build the reclaim-review group from the right-sizing register.
.DESCRIPTION
    PURPOSE
        Assembles the reclaim and downsize candidates from the right-sizing register into a single
        review group (Reclaim-Review Group - Pilot Scope - Validate) for routing to confirmation
        owners. It writes the group as a CSV and, where the Adobe User Management API is available and
        -StageAdobeGroup is set, can stage a named Adobe user group. It does NOT remove any user.
    HOW TO RUN
        Build the review CSV (default):
          powershell -ExecutionPolicy Bypass -File .\ADOBELIC-Set-ScopeTargeting.ps1 -RegisterPath .\Right-Sizing-Register-Pilot-Validate.csv
        Also stage an Adobe user group (where the API is available):
          powershell -ExecutionPolicy Bypass -File .\ADOBELIC-Set-ScopeTargeting.ps1 -RegisterPath .\Right-Sizing-Register-Pilot-Validate.csv -StageAdobeGroup -GroupName "Reclaim-Review Group - Pilot Scope - Validate"
    EXPECTED RESULTS
        Reclaim-Review-Group-Pilot-Validate.csv listing the candidates and their confirmation owners,
        ready to route. Optionally, a staged Adobe user group (no assignments are removed).
.NOTES
    White-label SAM tooling. No removals are performed.
    Adobe specifics: creating/staging an Adobe user group is deferred to Adobe's official User
    Management API documentation. Complete Invoke-AdobeStageGroup below; read secrets from the
    environment, never from this file.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RegisterPath,
    [switch]$StageAdobeGroup,
    [string]$GroupName = "Reclaim-Review Group - Pilot Scope - Validate",
    [string]$OutPath = ".\Reclaim-Review-Group-Pilot-Validate.csv"
)

if (-not (Test-Path $RegisterPath)) { throw "Register not found: $RegisterPath (run ADOBELIC-Validation.ps1)" }
$reg = Import-Csv -Path $RegisterPath

$group = $reg | Where-Object { $_.RecommendedAction -in @('reclaim','downsize') } |
    Select-Object User, ProductProfile, Product, RecommendedAction, Evidence, ConfirmationOwner

Write-Host "=== ADOBELIC Set-ScopeTargeting ===" -ForegroundColor Cyan
Write-Host ("Group name      : {0}" -f $GroupName)
Write-Host ("Members (review): {0}" -f $group.Count)
$group | Group-Object RecommendedAction | ForEach-Object { Write-Host ("  {0,-10} {1}" -f $_.Name, $_.Count) }

$group | Export-Csv -Path $OutPath -NoTypeInformation
Write-Host ("`nReclaim-review group written to {0}" -f $OutPath) -ForegroundColor Green
Write-Host "Route this to the confirmation owners. Reclamation only proceeds for approved rows (ADOBELIC-Remediation.ps1)." -ForegroundColor Yellow

function Invoke-AdobeStageGroup {
    # ADOBE-SPECIFIC: create/stage an Adobe user group and add the members here, per Adobe's official
    # User Management API documentation. Read credentials from the environment. This stub does not
    # invent an endpoint and performs no removals.
    param([string]$Name, [object[]]$Members)
    throw "Adobe group staging not implemented — complete Invoke-AdobeStageGroup per Adobe's documentation, or create the group in the Admin Console."
}

if ($StageAdobeGroup) {
    try { Invoke-AdobeStageGroup -Name $GroupName -Members $group; Write-Host ("Staged Adobe user group '{0}'." -f $GroupName) -ForegroundColor Green }
    catch { Write-Host ("Adobe group staging skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}
