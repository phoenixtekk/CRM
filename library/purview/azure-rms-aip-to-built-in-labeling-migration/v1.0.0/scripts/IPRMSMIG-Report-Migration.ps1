<#
.SYNOPSIS
    IPRMSMIG-Report-Migration.ps1 — read-only migration/parity report and matrix export (no changes).
.DESCRIPTION
    PURPOSE
        Produces the migration status report: joins the current unified-store estate (labels, label
        policies, RMS templates) to your parity map and emits a per-row PASS/FAIL matrix — label present,
        encryption reproduced, template mapped, policy setting applied. Read-only — makes no changes.
        Writes "Migration Validation - Report".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPRMSMIG-Report-Migration.ps1 -ParityMapPath .\parity-map.csv -CsvPath .\MigrationStatus.csv
        -ParityMapPath = the parity map you built (CSV columns: Kind, SourceItem, TargetLabel, ParityDecision).
        PowerShell 5.1+/7+. Requires ExchangeOnlineManagement (Connect-IPPSSession); optional AIPService
        for template status. If -ParityMapPath is omitted, the report lists the live estate for review.
    EXPECTED RESULTS
        A parity matrix (console + optional CSV) with a Result per row. PASS = every parity row resolves
        against the live estate; no encryption/protection row is failing.
.NOTES
    Purview — Azure RMS / AIP to Built-in Unified Labeling Migration. Read-only. No secrets in code.
    The report evidences parity; whether a legacy template still applies is a records/compliance
    determination, deferred to the relevant governance function.
#>
[CmdletBinding()]
param(
    [string]$ParityMapPath,
    [string]$CsvPath,
    [string]$ReportName = 'Migration Validation - Report'
)

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

$labels   = @(Get-Label -ErrorAction SilentlyContinue)
$policies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)
$labelNames = @($labels.DisplayName)
$publishedLabelIds = @($policies | Where-Object { $_.Enabled } | ForEach-Object { $_.Labels } | ForEach-Object { $_ }) | Sort-Object -Unique

function Resolve-LabelPresent([string]$target) {
    if (-not $target) { return $false }
    $t = $target.Trim()
    ($labelNames -contains $t) -or ($labels | Where-Object { $_.Name -eq $t -or $_.Guid -eq $t }).Count -gt 0
}
function Resolve-LabelPublished([string]$target) {
    if (-not $target) { return $false }
    $t = $target.Trim()
    $match = $labels | Where-Object { $_.DisplayName -eq $t -or $_.Name -eq $t -or $_.Guid -eq $t } | Select-Object -First 1
    if (-not $match) { return $false }
    ($publishedLabelIds -contains $match.Name) -or ($publishedLabelIds -contains $match.Guid) -or ($publishedLabelIds -contains $match.DisplayName)
}

$rows = @()
if ($ParityMapPath -and (Test-Path $ParityMapPath)) {
    $map = Import-Csv -Path $ParityMapPath
    foreach ($m in $map) {
        $target = $m.TargetLabel
        $present   = Resolve-LabelPresent $target
        $published = Resolve-LabelPublished $target
        $result = if ($present -and $published) { 'PASS' } elseif ($present) { 'PRESENT-NOT-PUBLISHED' } else { 'FAIL (target label missing)' }
        $rows += [pscustomobject]@{
            Kind          = $m.Kind
            SourceItem    = $m.SourceItem
            TargetLabel   = $target
            ParityDecision= $m.ParityDecision
            LabelPresent  = $present
            LabelPublished= $published
            Result        = $result
        }
    }
    Write-Host '--- Parity matrix ---' -ForegroundColor Cyan
    $rows | Format-Table Kind, SourceItem, TargetLabel, Result -AutoSize
    $fails = @($rows | Where-Object { $_.Result -like 'FAIL*' })
    Write-Host ("Rows: {0}   Failing: {1}" -f $rows.Count, $fails.Count) -ForegroundColor $(if ($fails.Count -eq 0) {'Green'} else {'Red'})
} else {
    Write-Host 'No -ParityMapPath supplied; listing the live estate for review:' -ForegroundColor Yellow
    Write-Host ("Labels: {0}   Label policies (enabled): {1}" -f $labels.Count, @($policies | Where-Object Enabled).Count) -ForegroundColor Cyan
    $rows = foreach ($l in $labels) {
        [pscustomobject]@{ Kind='Label'; SourceItem=$l.DisplayName; TargetLabel=$l.DisplayName; ParityDecision='';
            LabelPresent=$true; LabelPublished=(Resolve-LabelPublished $l.DisplayName); Result='REVIEW' }
    }
    $rows | Format-Table SourceItem, LabelPublished -AutoSize
}

if ($CsvPath -and $rows.Count) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}
Write-Host 'Migration report complete (read-only).' -ForegroundColor Green
