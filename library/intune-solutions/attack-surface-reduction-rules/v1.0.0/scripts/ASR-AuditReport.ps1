<#
.SYNOPSIS
    ASR-AuditReport.ps1 — summarize local Defender ASR audit/block events.
.DESCRIPTION
    PURPOSE
        Reads the Microsoft Defender Operational log for ASR events — 1122 (audited / would block)
        and 1121 (blocked) — and summarizes by rule and process so you can find false positives
        before switching rules to Block.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\ASR-AuditReport.ps1 -Days 14 -CsvPath C:\Temp\asr.csv
    EXPECTED RESULTS
        A breakdown of ASR events by rule/process; review for legitimate apps to exclude.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param([int]$Days = 14, [string]$CsvPath)
$start = (Get-Date).AddDays(-$Days)
try {
    $events = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Windows Defender/Operational'; Id=1121,1122; StartTime=$start } -ErrorAction Stop
} catch { Write-Host "No ASR events in the last $Days days (or log unavailable)." -ForegroundColor Yellow; return }
$rows = foreach ($e in $events) {
    $x = [xml]$e.ToXml()
    $d = @{}; $x.Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
    [pscustomobject]@{
        Time = $e.TimeCreated
        Type = if ($e.Id -eq 1121) { 'Block' } else { 'Audit' }
        Rule = $d['ID']
        Process = $d['Process Name']
        Target = $d['Path']
    }
}
Write-Host "=== ASR events (last $Days days) — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$rows | Group-Object Type | Select-Object Name, Count | Format-Table -AutoSize
Write-Host "Top processes triggering ASR:" -ForegroundColor Cyan
$rows | Group-Object Process | Sort-Object Count -Descending | Select-Object -First 10 Count, Name | Format-Table -AutoSize
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Write-Host "Review these for legitimate apps to exclude before switching rules to Block." -ForegroundColor Gray
