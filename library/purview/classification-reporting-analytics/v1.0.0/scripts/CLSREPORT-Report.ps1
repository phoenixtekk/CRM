<#
.SYNOPSIS
    CLSREPORT-Report.ps1 — read-only export of classification coverage (label/SIT distribution) and label/DLP activity to CSV for dashboards.
.DESCRIPTION
    PURPOSE
        Produces the two repeatable dashboard feeds: (1) COVERAGE — items per sensitivity label / retention
        label / SIT / trainable classifier, via Export-ContentExplorerData WHERE that cmdlet is available in
        your tenant (flagged VERIFY otherwise, with the Content Explorer portal as the fallback); and
        (2) ACTIVITY — sensitivity-label lifecycle, DLP matches, and egress activity over a rolling window,
        via Search-UnifiedAuditLog. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CLSREPORT-Report.ps1 -Days 30 -OutputFolder .\CLSREPORT-out
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and Exchange Online PowerShell
        (Connect-ExchangeOnline). PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        Writes coverage-by-tag.csv (or an explicit VERIFY note if Export-ContentExplorerData is absent) and
        activity-summary.csv into -OutputFolder. PASS signal: at least one tag returns >= 1 item (or an
        explicit BASELINE note for an unclassified estate) and >= 1 classification/DLP activity row (or an
        explicit ingestion-lag note). Load the CSVs into Excel or Power BI to render the Coverage/Activity views.
.NOTES
    Purview — Classification Reporting & Analytics. Read-only against S&C PowerShell / Exchange Online. No changes, no credentials in code.
    Expected results: coverage + activity CSVs written; empty-estate and ingestion-lag are valid findings, not failures. Export-ContentExplorerData availability is licensing-/tenant-dependent — VERIFY in your tenant.
#>
[CmdletBinding()]
param(
    [int]$Days = 30,
    [string]$OutputFolder = '.\CLSREPORT-out',
    [ValidateSet('SensitiveInformationType','SensitivityLabel','RetentionLabel','TrainableClassifier')]
    [string[]]$TagTypes = @('SensitivityLabel','RetentionLabel','SensitiveInformationType'),
    # Audit record types that surface classification/DLP/egress activity (parameterized — values evolve; VERIFY in your tenant).
    [string[]]$RecordTypes = @('SensitivityLabelAction','SensitivityLabeledFileAction','ComplianceDLPSharePoint','ComplianceDLPExchange','DLPEndpoint'),
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}
if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-ExchangeOnline -ShowBanner:$false }
}

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$coveragePath = Join-Path $OutputFolder 'coverage-by-tag.csv'
$activityPath = Join-Path $OutputFolder 'activity-summary.csv'

Write-Host '=== Classification Reporting Export (read-only) ===' -ForegroundColor Cyan

# --- 1. COVERAGE — Content Explorer distribution by tag (licensing-/tenant-dependent) ---
Write-Host '--- Coverage by tag (Content Explorer) ---' -ForegroundColor Cyan
$coverageRows = New-Object System.Collections.Generic.List[object]
$exportCmd = Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue
if ($exportCmd) {
    Write-Host 'Export-ContentExplorerData resolved (version-dependent). VERIFY the returned counts against the Content Explorer portal in your tenant before relying on them.' -ForegroundColor Yellow
    foreach ($tt in $TagTypes) {
        try {
            # Export-ContentExplorerData returns items for a given tag type/name; parameters are tenant/version-dependent — VERIFY.
            $items = @(Export-ContentExplorerData -TagType $tt -ErrorAction Stop)
            $byTag = $items | Group-Object -Property TagName
            foreach ($g in $byTag) {
                $coverageRows.Add([pscustomobject]@{ TagType = $tt; TagName = $g.Name; ItemCount = $g.Count })
            }
            if (-not $byTag) { $coverageRows.Add([pscustomobject]@{ TagType = $tt; TagName = '(none returned)'; ItemCount = 0 }) }
        } catch {
            Write-Host ("  {0}: Export-ContentExplorerData failed ({1}) — use the Content Explorer PORTAL for this tag type; VERIFY licensing/tenant." -f $tt, $_.Exception.Message) -ForegroundColor Yellow
            $coverageRows.Add([pscustomobject]@{ TagType = $tt; TagName = 'VERIFY (export unavailable — use portal)'; ItemCount = $null })
        }
    }
} else {
    Write-Host 'Export-ContentExplorerData is NOT available in this tenant. Content Explorer coverage is a PORTAL (or Graph, where available) surface here — capturing the published tag inventory instead, and flagging VERIFY.' -ForegroundColor Yellow
    # Fall back to the published tag inventory so the dashboard still has the tag list to report portal counts against.
    try { foreach ($l in @(Get-Label -ErrorAction Stop))                       { $coverageRows.Add([pscustomobject]@{ TagType='SensitivityLabel';        TagName=$l.DisplayName; ItemCount='VERIFY (portal)' }) } } catch {}
    try { foreach ($t in @(Get-ComplianceTag -ErrorAction Stop))               { $coverageRows.Add([pscustomobject]@{ TagType='RetentionLabel';          TagName=$t.Name;        ItemCount='VERIFY (portal)' }) } } catch {}
}
if ($coverageRows.Count -eq 0) {
    Write-Host 'BASELINE: no coverage rows — likely a largely unclassified estate. Record as baseline coverage (a finding to route to governance), not a failure (Req 2.5).' -ForegroundColor Yellow
}
$coverageRows | Export-Csv -Path $coveragePath -NoTypeInformation -Encoding UTF8
Write-Host ("Coverage written to {0} ({1} row(s))." -f $coveragePath, $coverageRows.Count) -ForegroundColor Green

# --- 2. ACTIVITY — label lifecycle / DLP / egress over the window ---
Write-Host '--- Activity summary (unified audit log) ---' -ForegroundColor Cyan
$start = (Get-Date).AddDays(-1 * [math]::Abs($Days))
$end   = Get-Date
$activityRows = New-Object System.Collections.Generic.List[object]
foreach ($rt in $RecordTypes) {
    $count = 0
    try {
        $records = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt -ResultSize 5000 -ErrorAction Stop)
        $count = $records.Count
        # Break down by operation where present.
        $byOp = $records | ForEach-Object {
            $op = $_.Operations; if (-not $op) { $op = $_.Operation }
            [pscustomobject]@{ Op = $op }
        } | Group-Object -Property Op
        if ($byOp) {
            foreach ($g in $byOp) { $activityRows.Add([pscustomobject]@{ RecordType = $rt; Operation = $g.Name; EventCount = $g.Count }) }
        } else {
            $activityRows.Add([pscustomobject]@{ RecordType = $rt; Operation = '(total)'; EventCount = $count })
        }
    } catch {
        Write-Host ("  {0}: Search-UnifiedAuditLog failed ({1}) — confirm this RecordType is valid in your tenant (values evolve — VERIFY)." -f $rt, $_.Exception.Message) -ForegroundColor Yellow
        $activityRows.Add([pscustomobject]@{ RecordType = $rt; Operation = 'VERIFY (record type)'; EventCount = $null })
    }
    Write-Host ("  {0}: {1} event(s) in the last {2} day(s)." -f $rt, $count, [math]::Abs($Days))
}
$totalActivity = (@($activityRows | Where-Object { $_.EventCount -is [int] }) | Measure-Object -Property EventCount -Sum).Sum
if (-not $totalActivity) {
    Write-Host 'INGESTION LAG / PRE-ACTIVITY: no activity rows in the window. If ingestion was just enabled, allow time and re-run; otherwise confirm classification activity has occurred (not a failure).' -ForegroundColor Yellow
}
$activityRows | Export-Csv -Path $activityPath -NoTypeInformation -Encoding UTF8
Write-Host ("Activity written to {0} ({1} row(s))." -f $activityPath, $activityRows.Count) -ForegroundColor Green

Write-Host 'Done. Load coverage-by-tag.csv and activity-summary.csv into Excel or Power BI for the Coverage/Activity dashboard views.' -ForegroundColor Cyan
