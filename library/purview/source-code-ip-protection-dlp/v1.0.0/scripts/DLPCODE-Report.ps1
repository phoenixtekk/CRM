<#
.SYNOPSIS
    DLPCODE-Report.ps1 — Produce the source-code/IP DLP coverage report (read-only; optional CSV export).
.DESCRIPTION
    PURPOSE
        Builds 'Source-Code DLP - Coverage Report' — for each DLP policy/rule: which channels it covers
        (Exchange/SharePoint/OneDrive/Teams/Endpoint), its mode (test/enforce), and its rules — as the
        management evidence artifact. Read-only; writing a CSV is opt-in.
    HOW TO RUN
        .\DLPCODE-Report.ps1
        .\DLPCODE-Report.ps1 -CsvPath .\CodeDlpReport.csv
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A table (and optional CSV) of each policy/rule with channels and mode — re-runnable on a schedule.
        Makes no configuration change.
.NOTES
    Purview — Source-Code & IP Protection DLP. Read-only reporting. Verify your licensing/tenant; property
    names vary by module version.
#>
[CmdletBinding()]
param([string]$CsvPath)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== Source-Code & IP Protection DLP — coverage report (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-DlpCompliancePolicy')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$chanProps = @{ 'Exchange'='ExchangeLocation'; 'SharePoint'='SharePointLocation'; 'OneDrive'='OneDriveLocation'; 'Teams'='TeamsLocation'; 'Endpoint'='EndpointDlpLocation' }
$policies = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)

$rows = foreach ($p in $policies) {
    $covered = foreach ($k in $chanProps.Keys) { $prop=$chanProps[$k]; if ($p.PSObject.Properties.Name -contains $prop -and $p.$prop) { $k } }
    $rules = @(Get-DlpComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue)
    if ($rules.Count -eq 0) {
        [pscustomobject]@{ Policy=$p.Name; Mode="$($p.Mode)"; Channels=($covered -join ', '); Rule='(none)'; RuleDisabled='' }
    } else {
        foreach ($r in $rules) {
            [pscustomobject]@{ Policy=$p.Name; Mode="$($p.Mode)"; Channels=($covered -join ', '); Rule=$r.Name; RuleDisabled="$($r.Disabled)" }
        }
    }
}

if ($rows) {
    $rows | Format-Table -AutoSize
    if ($CsvPath) {
        try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Report written: {0}" -f (Resolve-Path $CsvPath)) -ForegroundColor Green }
        catch { Write-Host ("Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    } else {
        Write-Host "INFO  Console-only. Pass -CsvPath to export 'Source-Code DLP - Coverage Report'." -ForegroundColor DarkGray
    }
} else {
    Write-Host "No DLP policies to report yet." -ForegroundColor Yellow
}
