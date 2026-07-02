<#
.SYNOPSIS
    WFM-RuleReport.ps1 — list effective Windows Firewall rules on the device.
.DESCRIPTION
    PURPOSE
        Reports enabled firewall rules with direction, action, and (where available) ports/program,
        so you can confirm required allow rules exist and spot unexpected openings.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WFM-RuleReport.ps1 -Direction Inbound -CsvPath C:\Temp\fwrules.csv
    EXPECTED RESULTS
        A table (and optional CSV) of enabled rules.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param([ValidateSet('Inbound','Outbound','Both')][string]$Direction='Inbound', [string]$CsvPath)
$dirs = if ($Direction -eq 'Both') { 'Inbound','Outbound' } else { ,$Direction }
$rows = foreach ($d in $dirs) {
    Get-NetFirewallRule -Direction $d -Enabled True -ErrorAction SilentlyContinue | ForEach-Object {
        $pf = $_ | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
        [pscustomobject]@{ Name=$_.DisplayName; Direction=$_.Direction; Action=$_.Action; Protocol=$pf.Protocol; LocalPort=($pf.LocalPort -join ',') ; Profile=$_.Profile }
    }
}
Write-Host "=== Enabled firewall rules ($Direction) — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$rows | Sort-Object Direction, Name | Select-Object -First 60 | Format-Table -AutoSize
Write-Host ("Total enabled rules: {0}" -f $rows.Count) -ForegroundColor Cyan
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
