<#
.SYNOPSIS
    OPSEXEC-Discovery.ps1 - assess which executive-dashboard signal sources are reachable/licensed (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and Microsoft Graph and classifies each dashboard
        KPI source as reachable-by-API, portal-only, or not-licensed: sensitivity labels, DLP policies,
        retention policies, Content/Activity Explorer, plus Insider Risk / DSPM / advanced-DLP licensing
        (Graph subscribedSkus). Read-only - changes nothing. Optional CSV export.
    HOW TO RUN
        powershell -File .\OPSEXEC-Discovery.ps1 -CsvPath .\Exec-Sources.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession) and Microsoft.Graph (licensing).
        Interactive modern-auth sign-in; no secrets in code.
    EXPECTED RESULTS
        A per-source table (Source / Reachable / Detail) and a licensing summary. "CHECK" means
        verify your licensing/tenant, not a defect. Feeds "Exec Metrics - Compliance Signals - Definition".
.NOTES
    Purview category - Executive Dashboard. Read-only. Sources are licensing-/tenant-dependent and the
    portal evolves - some values are portal-only in your tenant. No client names; no secrets.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$CsvPath,
    [switch]$SkipGraphLicensing
)

$ErrorActionPreference = 'Stop'
$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($source,$state,$detail){ $rows.Add([pscustomobject]@{ Source=$source; State=$state; Detail=$detail }) }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{}; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# --- Security & Compliance PowerShell sources ---
try {
    Connect-IPPSSession @cp -ErrorAction Stop | Out-Null

    try { $labels = @(Get-Label -ErrorAction Stop)
          Add-Row 'Sensitivity labels' 'REACHABLE' ("$($labels.Count) label(s) published/defined") }
    catch { Add-Row 'Sensitivity labels' 'CHECK' $_.Exception.Message }

    try { $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
          Add-Row 'DLP policies' 'REACHABLE' ("$($dlp.Count) DLP policy(ies)") }
    catch { Add-Row 'DLP policies' 'CHECK' $_.Exception.Message }

    try { $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
          Add-Row 'Retention policies' 'REACHABLE' ("$($ret.Count) retention policy(ies)") }
    catch { Add-Row 'Retention policies' 'CHECK' $_.Exception.Message }

    if (Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue) {
        Add-Row 'Activity Explorer (DLP/label activity)' 'REACHABLE' 'Export-ActivityExplorerData available'
    } else { Add-Row 'Activity Explorer (DLP/label activity)' 'CHECK' 'cmdlet not available - portal-read/verify tenant' }

    if (Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue) {
        Add-Row 'Content Explorer (sensitive items)' 'REACHABLE' 'Export-ContentExplorerData available (preview/tenant-dependent)'
    } else { Add-Row 'Content Explorer (sensitive items)' 'CHECK' 'cmdlet not available - portal-read/verify tenant' }
}
catch { Add-Row 'Security & Compliance PowerShell' 'CHECK' "Connect-IPPSSession failed: $($_.Exception.Message)" }

# Portal-only signals (no stable public API in many tenants)
Add-Row 'Compliance Manager score' 'PORTAL' 'Read from Compliance Manager dashboard - enter in definition with read date'
Add-Row 'Insider Risk aggregate alerts' 'PORTAL' 'Aggregate/severity only (no names) - separate IR role - portal-read'
Add-Row 'DSPM open recommendations' 'PORTAL' 'Read from DSPM (E5/preview) - enter in definition with read date'

# --- Graph licensing ---
if (-not $SkipGraphLicensing -and (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome
        $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
        $planNames = $skus | ForEach-Object { $_.servicePlans.servicePlanName } | Sort-Object -Unique
        $checks = @{
            'Insider Risk (INSIDER_RISK_MANAGEMENT)' = 'INSIDER_RISK_MANAGEMENT'
            'Advanced DLP (INFORMATION_BARRIERS/MIP_S_CLP2)' = 'MIP_S_CLP2'
            'Records Management (RECORDS_MANAGEMENT)' = 'RECORDS_MANAGEMENT'
            'Customer Lockbox / E5 Compliance (M365_ADVANCED_AUDITING)' = 'M365_ADVANCED_AUDITING'
        }
        foreach ($k in $checks.Keys) {
            $present = $planNames -contains $checks[$k]
            Add-Row "Licensing: $k" ($(if($present){'PRESENT'}else{'CHECK'})) ($(if($present){"$($checks[$k]) in subscribedSkus"}else{"$($checks[$k]) not found - verify licensing/tenant"}))
        }
    } catch { Add-Row 'Graph licensing' 'CHECK' $_.Exception.Message }
} else { Add-Row 'Graph licensing' 'CHECK' 'Graph licensing check skipped/unavailable' }

Write-Host "`n=== Exec Dashboard - Source & Licensing Discovery ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "PORTAL = read from the Purview portal and enter in the metric definition (no stable API in many tenants)." -ForegroundColor Yellow
Write-Host "CHECK  = verify your licensing/tenant before relying on this source." -ForegroundColor Yellow
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported to $CsvPath" -ForegroundColor Green }
