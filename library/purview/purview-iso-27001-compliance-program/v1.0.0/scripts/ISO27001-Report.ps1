<#
.SYNOPSIS
    ISO27001-Report.ps1 — read-only control-coverage + evidence-gap report and logging-evidence pull.
.DESCRIPTION
    PURPOSE
        Produces the audit-ready coverage view for the ISO 27001 Purview program: rolls up mapped-control
        coverage from a control-map CSV (Control,Capability,Owner,Collected) if provided, and pulls
        logging/monitoring evidence (A.8.15/8.16) from the unified audit log for the DLP/label/retention
        record types over a time window. Read-only — queries Search-UnifiedAuditLog only; makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISO27001-Report.ps1 -ControlMap .\ISO27001-ControlMap.csv -Days 30 -CsvPath .\ISO27001-Coverage.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and audit logging enabled.
    EXPECTED RESULTS
        A console coverage summary (controls mapped / evidenced / gaps) and a breakdown of compliance
        activity events by record type, plus an optional CSV. PASS gate: coverage report shows every
        in-scope control mapped and evidenced with no unexplained gap, and audit activity is present for
        the configured controls.
.NOTES
    Purview — ISO 27001 Compliance Program. Read-only reporting from control map + unified audit log.
#>
[CmdletBinding()]
param(
    [string]$ControlMap,
    [int]$Days = 30,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host '=== ISO 27001 Coverage & Evidence Report (read-only) ===' -ForegroundColor Cyan

# --- Control-map coverage roll-up (if supplied) ---
if ($ControlMap -and (Test-Path $ControlMap)) {
    $map = @(Import-Csv $ControlMap)
    $total     = $map.Count
    $mapped    = @($map | Where-Object { $_.Capability -and $_.Capability -notmatch '^(?i)out.?of.?purview' }).Count
    $evidenced = @($map | Where-Object { $_.Collected -match '^(?i)y' }).Count
    $gaps      = @($map | Where-Object { ($_.Capability -and $_.Capability -notmatch '^(?i)out.?of.?purview') -and ($_.Collected -notmatch '^(?i)y') })
    Write-Host '--- Control-map coverage ---' -ForegroundColor Cyan
    Write-Host ("  In-scope controls : {0}" -f $total)
    Write-Host ("  Mapped to Purview : {0}" -f $mapped)
    Write-Host ("  Evidenced         : {0}" -f $evidenced)
    if ($gaps.Count -gt 0) {
        Write-Host ("  EVIDENCE GAPS     : {0}" -f $gaps.Count) -ForegroundColor Yellow
        $gaps | ForEach-Object { Write-Host ("     * {0} -> {1}" -f $_.Control, $_.Capability) -ForegroundColor Yellow }
    } else {
        Write-Host '  No evidence gaps in the mapped controls.' -ForegroundColor Green
    }
} else {
    Write-Host 'No -ControlMap supplied — reporting audit activity only. Provide the control map for the coverage roll-up.' -ForegroundColor Yellow
}

# --- Logging/monitoring evidence (A.8.15 / A.8.16) from the unified audit log ---
$start = (Get-Date).AddDays(-$Days); $end = Get-Date
$recordTypes = 'ComplianceDLPExchange','ComplianceDLPSharePoint','DLPEndpoint','SensitivityLabelAction','SensitivityLabeledFileAction'
Write-Host ("--- Compliance activity: {0:yyyy-MM-dd} to {1:yyyy-MM-dd} ({2} days) ---" -f $start, $end, $Days) -ForegroundColor Cyan

$events = @()
foreach ($rt in $recordTypes) {
    $sid = "ISO27001-$rt-$(Get-Random)"
    do {
        $batch = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt `
                    -SessionId $sid -SessionCommand ReturnLargeSet -ResultSize 5000 -ErrorAction SilentlyContinue
        if ($batch) { $events += $batch }
    } while ($batch -and $batch.Count -eq 5000)
}

if (-not $events -or $events.Count -eq 0) {
    Write-Host '  No compliance activity found in the window. Freshly configured controls need dwell time; widen -Days and confirm audit logging is on.' -ForegroundColor Yellow
} else {
    $events | Group-Object RecordType | Sort-Object Count -Descending |
        Select-Object @{n='RecordType';e={$_.Name}}, Count | Format-Table -AutoSize
    Write-Host ("  Total compliance activity events: {0}" -f $events.Count) -ForegroundColor Green
}

if ($CsvPath -and $ControlMap -and (Test-Path $ControlMap)) {
    (Import-Csv $ControlMap) | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Coverage roll-up exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Use this coverage view for the audit record; re-run on the continual-improvement cadence.' -ForegroundColor Cyan
