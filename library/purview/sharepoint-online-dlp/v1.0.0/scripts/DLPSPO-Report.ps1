<#
.SYNOPSIS
    DLPSPO-Report.ps1 — Produce the SharePoint/OneDrive DLP coverage report (read-only; optional CSV export).
.DESCRIPTION
    PURPOSE
        Builds 'SPO DLP - Coverage Report' — for each DLP policy/rule: whether it covers SharePoint/OneDrive,
        its mode (test/enforce), and its rules — as the management evidence artifact. Read-only; writing a
        CSV is opt-in.
    HOW TO RUN
        .\DLPSPO-Report.ps1
        .\DLPSPO-Report.ps1 -CsvPath .\SpoDlpReport.csv
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A table (and optional CSV) of each policy/rule with locations and mode — re-runnable on a schedule.
        Makes no configuration change.
.NOTES
    Purview — SharePoint Online DLP. Read-only reporting. Verify your licensing/tenant; property names vary
    by module version.
#>
[CmdletBinding()]
param([string]$CsvPath)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== SharePoint Online DLP — coverage report (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-DlpCompliancePolicy')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$policies = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
$rows = foreach ($p in $policies) {
    $spo = ($p.PSObject.Properties.Name -contains 'SharePointLocation' -and $p.SharePointLocation)
    $od  = ($p.PSObject.Properties.Name -contains 'OneDriveLocation'   -and $p.OneDriveLocation)
    $rules = @(Get-DlpComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue)
    if ($rules.Count -eq 0) {
        [pscustomobject]@{ Policy=$p.Name; Mode="$($p.Mode)"; SharePoint=[bool]$spo; OneDrive=[bool]$od; Rule='(none)'; RuleDisabled='' }
    } else {
        foreach ($r in $rules) {
            [pscustomobject]@{ Policy=$p.Name; Mode="$($p.Mode)"; SharePoint=[bool]$spo; OneDrive=[bool]$od; Rule=$r.Name; RuleDisabled="$($r.Disabled)" }
        }
    }
}

if ($rows) {
    $rows | Format-Table -AutoSize
    if ($CsvPath) {
        try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Report written: {0}" -f (Resolve-Path $CsvPath)) -ForegroundColor Green }
        catch { Write-Host ("Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    } else {
        Write-Host "INFO  Console-only. Pass -CsvPath to export 'SPO DLP - Coverage Report'." -ForegroundColor DarkGray
    }
} else {
    Write-Host "No DLP policies to report yet." -ForegroundColor Yellow
}
