<#
.SYNOPSIS
    DLCSPO-Report.ps1 — Produce the retention coverage report (read-only; optional CSV export).
.DESCRIPTION
    PURPOSE
        Builds 'Lifecycle - Coverage Report' — for each retention policy/rule: whether it covers
        SharePoint/OneDrive, its enabled state, retention period, and action (retain / retain-then-delete /
        delete-only) — as the management evidence artifact. Read-only; writing a CSV is opt-in.
    HOW TO RUN
        .\DLCSPO-Report.ps1
        .\DLCSPO-Report.ps1 -CsvPath .\LifecycleReport.csv
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession. No secret is stored in the script.
    EXPECTED RESULTS
        A table (and optional CSV) of each policy/rule with locations, period, and action — re-runnable on a
        schedule. Makes no configuration change.
.NOTES
    Purview — SharePoint & OneDrive Lifecycle Policies. Read-only reporting. Verify your licensing/tenant;
    property/action names vary by module version.
#>
[CmdletBinding()]
param([string]$CsvPath)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

Write-Host "`n=== SharePoint & OneDrive Lifecycle — coverage report (read-only) ===" -ForegroundColor Cyan
if (-not (Test-Command 'Get-RetentionCompliancePolicy')) { Write-Host "Run Connect-IPPSSession first." -ForegroundColor Yellow; return }

$policies = @(Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)
$rows = foreach ($p in $policies) {
    $spo = ($p.PSObject.Properties.Name -contains 'SharePointLocation' -and $p.SharePointLocation)
    $od  = ($p.PSObject.Properties.Name -contains 'OneDriveLocation'   -and $p.OneDriveLocation)
    $rules = @(Get-RetentionComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue)
    if ($rules.Count -eq 0) {
        [pscustomobject]@{ Policy=$p.Name; Enabled=$p.Enabled; SharePoint=[bool]$spo; OneDrive=[bool]$od; Rule='(none)'; Period=''; Action='' }
    } else {
        foreach ($r in $rules) {
            [pscustomobject]@{
                Policy    = $p.Name
                Enabled   = $p.Enabled
                SharePoint= [bool]$spo
                OneDrive  = [bool]$od
                Rule      = $r.Name
                Period    = "$($r.RetentionDuration)"
                Action    = "$($r.RetentionComplianceAction)"
            }
        }
    }
}

if ($rows) {
    $rows | Format-Table -AutoSize
    if ($CsvPath) {
        try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Report written: {0}" -f (Resolve-Path $CsvPath)) -ForegroundColor Green }
        catch { Write-Host ("Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    } else {
        Write-Host "INFO  Console-only. Pass -CsvPath to export 'Lifecycle - Coverage Report'." -ForegroundColor DarkGray
    }
} else {
    Write-Host "No retention policies to report yet." -ForegroundColor Yellow
}
