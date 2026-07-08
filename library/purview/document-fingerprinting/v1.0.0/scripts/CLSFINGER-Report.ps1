<#
.SYNOPSIS
    CLSFINGER-Report.ps1 — export DLP detections for the fingerprint policy for TP/FP classification (read-only).
.DESCRIPTION
    PURPOSE
        Read-only detection report for the Document Fingerprinting solution. Pulls DLP detection activity so
        you can classify each match as true positive vs false positive and compute the false-positive rate
        that gates enforcement (Testing Gate B). Uses Get-DlpDetectionsReport where available; if that
        reporting cmdlet is not available in your session it falls back to a unified-audit-log query for DLP
        record types. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession -UserPrincipalName admin@contoso.com
          .\CLSFINGER-Report.ps1 -Days 14
          .\CLSFINGER-Report.ps1 -Days 14 -PolicyName "DLP - Fingerprinted Forms - Simulation" -CsvPath .\CLSFINGER-Matches.csv
    EXPECTED RESULTS
        A console summary and (with -CsvPath) a CSV of detections (date, policy, workload, SIT/action where
        available) for TP/FP classification. No matches yet can simply mean the policy needs more dwell time
        or audit logging is still surfacing events — widen -Days and re-run.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets (Get-DlpDetectionsReport,
    Search-UnifiedAuditLog) are standard Microsoft reporting cmdlets; none are invented. DLP reporting/audit
    availability is licensing-/tenant-dependent — the script warns and falls back rather than assuming.
#>
[CmdletBinding()]
param(
    [int]$Days = 14,
    [string]$PolicyName,
    [string]$CsvPath
)

$ErrorActionPreference = "Stop"
$start = (Get-Date).AddDays(-$Days)
$end   = Get-Date
Write-Host ("=== CLSFINGER Report — DLP detections, last {0} day(s) (read-only) ===" -f $Days) -ForegroundColor Cyan

$rows = [System.Collections.Generic.List[object]]::new()

# --- Preferred: Get-DlpDetectionsReport ---
$usedReport = $false
if (Get-Command Get-DlpDetectionsReport -ErrorAction SilentlyContinue) {
    try {
        $params = @{ StartDate = $start; EndDate = $end }
        $det = Get-DlpDetectionsReport @params -ErrorAction Stop
        foreach ($d in $det) {
            if ($PolicyName -and ($d.DlpPolicy -ne $PolicyName)) { continue }
            $rows.Add([pscustomobject]@{
                Date       = $d.Date
                Policy     = $d.DlpPolicy
                Rule       = $d.DlpRule
                Workload   = $d.Workload
                EventType  = $d.EventType
                Count      = $d.MessageCount
                Source     = "Get-DlpDetectionsReport"
            })
        }
        $usedReport = $true
        Write-Host ("  Get-DlpDetectionsReport returned {0} row(s)." -f @($det).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: Get-DlpDetectionsReport failed ($($_.Exception.Message)); trying audit-log fallback." -ForegroundColor Yellow }
} else {
    Write-Host "  Get-DlpDetectionsReport not available in this session; using audit-log fallback." -ForegroundColor DarkGray
}

# --- Fallback: unified audit log DLP record types ---
if (-not $usedReport) {
    if (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue) {
        $recordTypes = @("ComplianceDLPExchange", "ComplianceDLPSharePoint", "ComplianceDLPEndpoint")
        foreach ($rt in $recordTypes) {
            try {
                $events = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt -ResultSize 5000 -ErrorAction Stop
                foreach ($e in $events) {
                    $rows.Add([pscustomobject]@{
                        Date      = $e.CreationDate
                        Policy    = $PolicyName
                        Rule      = ""
                        Workload  = $rt
                        EventType = $e.Operations
                        Count     = 1
                        Source    = "Search-UnifiedAuditLog"
                    })
                }
                Write-Host ("  {0}: {1} event(s)." -f $rt, @($events).Count) -ForegroundColor Green
            } catch { Write-Host "  WARN: could not query $rt ($($_.Exception.Message))." -ForegroundColor Yellow }
        }
    } else {
        Write-Host "  Neither Get-DlpDetectionsReport nor Search-UnifiedAuditLog is available. Connect Exchange Online / confirm audit logging is enabled and the View-Only DLP/Audit role." -ForegroundColor Red
    }
}

Write-Host ("`n  Total detection rows: {0}" -f $rows.Count) -ForegroundColor Cyan
if ($rows.Count -eq 0) {
    Write-Host "  No detections found. Possible causes: policy needs more dwell time, audit latency, audit logging off, or no matching traffic yet. Widen -Days and re-run." -ForegroundColor Yellow
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nDetections written to {0}. Classify each row TP/FP and compute the false-positive rate (Testing Gate B)." -f $CsvPath) -ForegroundColor Green
} else {
    $rows | Select-Object -First 25 | Format-Table -AutoSize
    Write-Host "Add -CsvPath to export the full set for TP/FP classification." -ForegroundColor DarkGray
}
