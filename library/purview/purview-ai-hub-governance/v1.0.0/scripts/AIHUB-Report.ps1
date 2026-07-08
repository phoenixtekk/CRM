<#
.SYNOPSIS
    AIHUB-Report.ps1 — export AI-interaction activity and the DLP-for-AI match summary over N days to CSV (read-only).
.DESCRIPTION
    Builds the evidence artifact for the governance owner: (1) AI-interaction activity from the unified
    audit log over the last N days (best-effort by record type / free text, since AI record types evolve),
    and (2) a summary of DLP policies that look AI/Copilot-scoped with their mode. Read-only - makes no
    changes. Writes timestamped CSVs to the folder you supply (or prints to the console).
.EXAMPLE
    .\AIHUB-Report.ps1 -Days 30
    Prints the AI-interaction activity and DLP-for-AI summary for the last 30 days.
.EXAMPLE
    .\AIHUB-Report.ps1 -Days 30 -CsvFolder C:\Purview\Evidence
    Exports AIHUB-AIActivity-<timestamp>.csv and AIHUB-DlpForAI-<timestamp>.csv as evidence.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession). Role: Audit reader +
    Compliance/DLP reader.
    Expected results: PASS = the report lists AI-interaction events (if any in window) and AI/Copilot-scoped
    DLP policies with their mode. Verify = no events (allow latency / confirm AI usage / verify the AI record
    type for your tenant). DSPM for AI is new/evolving/PREVIEW - the DSPM-for-AI portal reports are the
    authoritative view; this is a scripted evidence supplement. Nothing is modified.
#>
[CmdletBinding()]
param(
    [int]$Days = 30,
    [string]$CsvFolder
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

Write-Host "=== AIHUB AI-governance report (read-only, last $Days days) ===" -ForegroundColor Cyan

# --- 1. AI-interaction activity (best-effort) ---
$aiRows = @()
try {
    $events = @()
    try { $events = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-$Days) -EndDate (Get-Date) -RecordType 'CopilotInteraction' -ResultSize 500 -ErrorAction Stop } catch {}
    if (-not $events -or @($events).Count -eq 0) {
        try { $events = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-$Days) -EndDate (Get-Date) -FreeText 'Copilot' -ResultSize 500 -ErrorAction Stop } catch {}
    }
    foreach ($e in @($events)) {
        $aiRows += [pscustomobject]@{
            CreationDate = $e.CreationDate
            UserIds      = $e.UserIds
            Operations   = $e.Operations
            RecordType   = $e.RecordType
        }
    }
    Write-Host ("`n-- AI-interaction events: {0} --" -f $aiRows.Count) -ForegroundColor $(if ($aiRows.Count -gt 0) { 'Green' } else { 'Yellow' })
    if ($aiRows.Count -eq 0) { Write-Host "  (none in window - allow ingestion latency, confirm AI usage, VERIFY the AI record type for your tenant)" -ForegroundColor Yellow }
} catch { Write-Host ("  AI-activity query failed ({0})." -f $_.Exception.Message) -ForegroundColor Yellow }

# --- 2. DLP-for-AI policy summary ---
$dlpRows = @()
try {
    foreach ($p in (Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -match 'AI|Copilot' })) {
        $dlpRows += [pscustomobject]@{ Policy = $p.Name; Mode = "$($p.Mode)"; WhenChanged = $p.WhenChanged }
    }
    Write-Host ("`n-- AI/Copilot-scoped DLP policies: {0} --" -f $dlpRows.Count) -ForegroundColor Cyan
    $dlpRows | Format-Table -AutoSize | Out-Host
    if ($dlpRows.Count -eq 0) { Write-Host "  (none named AI/Copilot - create the DLP-for-AI policy in Step 5)" -ForegroundColor Gray }
} catch { Write-Host ("  DLP query failed ({0})." -f $_.Exception.Message) -ForegroundColor Yellow }

if ($CsvFolder) {
    if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder -Force | Out-Null }
    $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
    if ($aiRows.Count -gt 0) { $aiRows | Export-Csv -Path (Join-Path $CsvFolder "AIHUB-AIActivity-$ts.csv") -NoTypeInformation -Encoding UTF8 }
    $dlpRows | Export-Csv -Path (Join-Path $CsvFolder "AIHUB-DlpForAI-$ts.csv") -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported to {0}" -f $CsvFolder) -ForegroundColor Green
} else {
    Write-Host "`n(No -CsvFolder supplied - console only. Add -CsvFolder <path> to export evidence.)" -ForegroundColor Yellow
}
Write-Host "`nNOTE: the DSPM-for-AI portal reports are the authoritative view; this scripted report supplements them. Verify your licensing/tenant." -ForegroundColor Yellow
