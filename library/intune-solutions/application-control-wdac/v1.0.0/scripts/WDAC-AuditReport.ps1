<#
.SYNOPSIS
    WDAC-AuditReport.ps1 — summarize Code Integrity audit/block events for App Control.
.DESCRIPTION
    PURPOSE
        Reads the Code Integrity Operational log for events 3076 (audit / would-block) and 3077
        (enforced block) and summarizes the files/publishers involved, so you can decide what to
        add to trust before enforcing.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WDAC-AuditReport.ps1 -Days 14 -CsvPath C:\Temp\wdac.csv
    EXPECTED RESULTS
        A breakdown of flagged files by path/publisher; review for legitimate apps to trust.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param([int]$Days = 14, [string]$CsvPath)
$start = (Get-Date).AddDays(-$Days)
try {
    $events = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-CodeIntegrity/Operational'; Id=3076,3077; StartTime=$start } -ErrorAction Stop
} catch { Write-Host "No Code Integrity 3076/3077 events in the last $Days days (or log unavailable)." -ForegroundColor Yellow; return }
$rows = foreach ($e in $events) {
    $x = [xml]$e.ToXml()
    $d = @{}; $x.Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
    [pscustomobject]@{
        Time = $e.TimeCreated
        Type = if ($e.Id -eq 3077) { 'Enforced-Block' } else { 'Audit' }
        File = $d['File Name']
        Publisher = $d['Publisher Name']
    }
}
Write-Host "=== App Control (WDAC) events (last $Days days) — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$rows | Group-Object Type | Select-Object Name, Count | Format-Table -AutoSize
Write-Host "Top flagged files:" -ForegroundColor Cyan
$rows | Group-Object File | Sort-Object Count -Descending | Select-Object -First 15 Count, Name | Format-Table -AutoSize
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Write-Host "Add legitimate apps to trust (prefer Intune managed-installer deployment) before enforcing." -ForegroundColor Gray
