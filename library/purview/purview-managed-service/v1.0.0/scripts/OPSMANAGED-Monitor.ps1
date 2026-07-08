<#
.SYNOPSIS
    OPSMANAGED-Monitor.ps1 — daily monitoring/triage sweep of DLP + activity signals (read-only).
.DESCRIPTION
    PURPOSE
        The daily monitoring sweep for the managed service. Confirms the unified audit log is on, then
        pulls recent DLP events (and a general activity sample) from the unified audit log, groups them by
        workload, and emits a triage view for `Managed Service – Triage Queue`. It also flags any DLP
        policy stuck in test mode (drift signal). Read-only — it surfaces signals to triage; it changes
        nothing. Insider-risk / communication-compliance surfaces are NOT read here (posture only, handled
        in the portal).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSMANAGED-Monitor.ps1 -Days 1
        powershell -ExecutionPolicy Bypass -File .\OPSMANAGED-Monitor.ps1 -Days 7 -CsvPath .\opsmanaged-triage.csv
        Prereqs: ExchangeOnlineManagement; MFA-capable read admin; audit logging enabled (Requirement 2.5).
    EXPECTED RESULTS
        Audit-log ON confirmation, a per-workload DLP-event count, an activity sample, and any test-mode
        DLP drift flags — the raw material for the triage queue. Optionally exported to CSV.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Exchange Online. No credentials in code.
#>
[CmdletBinding()]
param(
    [int]    $Days = 1,
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    Write-Section 'Connecting'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) { Connect-IPPSSession | Out-Null }
    Write-Host 'Connected to Security & Compliance PowerShell.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect: {0}" -f $_.Exception.Message); return }

# --- Confirm audit is on (foundational) ------------------------------------------------------------
Write-Section 'Unified audit log (foundational)'
try {
    if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }
    $ual = (Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled
    if ($ual) { Write-Host 'Unified audit log: ON.' -ForegroundColor Green }
    else { Write-Host 'Unified audit log: OFF — High-severity triage item; the estate is un-evidenced. Route to the Audit owner.' -ForegroundColor Red }
}
catch { Write-Warning ("Audit-log status unreadable: {0}" -f $_.Exception.Message) }

# --- DLP drift: policies stuck in test -------------------------------------------------------------
Write-Section 'DLP drift (policies stuck in simulation/test)'
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    $stuck = @($dlp | Where-Object { $_.Mode -like 'Test*' })
    if ($stuck.Count -gt 0) { Write-Host ("{0} DLP policy(ies) in test mode — triage as drift if past pilot:" -f $stuck.Count) -ForegroundColor Yellow; $stuck | Select-Object Name, Mode | Format-Table -AutoSize }
    else { Write-Host 'No DLP policies stuck in test.' -ForegroundColor Green }
}
catch { Write-Warning ("DLP read unavailable: {0}" -f $_.Exception.Message) }

# --- Recent DLP events (triage queue material) -----------------------------------------------------
Write-Section ("DLP events (last {0} day(s))" -f $Days)
$start = (Get-Date).AddDays(-$Days); $end = Get-Date
$rows = @()
try {
    $events = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType DLP -ResultSize 5000 -ErrorAction Stop
    if ($events) {
        $rows = foreach ($e in $events) {
            $d = $null; try { $d = $e.AuditData | ConvertFrom-Json } catch {}
            [pscustomobject]@{
                Date     = $e.CreationDate
                Workload = $(if($d.Workload){$d.Workload}else{$e.RecordType})
                Policy   = $(if($d.PolicyDetails){($d.PolicyDetails | Select-Object -First 1).PolicyName}else{''})
                Severity = $(if($d.PolicyDetails){($d.PolicyDetails | Select-Object -First 1).Rules[0].Severity}else{''})
                User     = $e.UserIds
            }
        }
        Write-Host 'By workload:' -ForegroundColor Cyan
        $rows | Group-Object Workload | Sort-Object Count -Descending | Select-Object Count, @{n='Workload';e={$_.Name}} | Format-Table -AutoSize
        Write-Host ("Total DLP events: {0}" -f $rows.Count) -ForegroundColor Cyan
    } else { Write-Host 'No DLP events in the window (or audit not yet populated).' -ForegroundColor Yellow }
}
catch { Write-Warning ("DLP event search unavailable: {0} — confirm audit logging (Requirement 2.5)." -f $_.Exception.Message) }

# --- Activity sample -------------------------------------------------------------------------------
Write-Section 'Activity sample (accountability signal)'
try {
    $sample = Search-UnifiedAuditLog -StartDate $start -EndDate $end -ResultSize 5 -ErrorAction Stop
    if ($sample) { $sample | Select-Object CreationDate, Operations, RecordType | Format-Table -AutoSize }
    else { Write-Host 'No activity records in the window — verify audit is enabled.' -ForegroundColor Yellow }
}
catch { Write-Warning ("Activity sample unavailable: {0}" -f $_.Exception.Message) }

if ($CsvPath -and $rows.Count) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("`nTriage rows written to {0}" -f $CsvPath) -ForegroundColor Green }
Write-Host "`nFeed the output into `Managed Service – Triage Queue` (assign severity + route to the owning capability). Report volume with OPSMANAGED-Report.ps1." -ForegroundColor Green
