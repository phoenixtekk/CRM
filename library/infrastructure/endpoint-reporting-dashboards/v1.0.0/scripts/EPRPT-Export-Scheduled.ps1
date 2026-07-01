<#
.SYNOPSIS
    EPRPT-Export-Scheduled.ps1 — Microsoft Graph exportJobs helper for Intune report data.
.DESCRIPTION
    PURPOSE
        Requests an Intune report export through the Microsoft Graph deviceManagement reports
        exportJobs endpoint, polls until the job completes, and downloads the resulting file
        (CSV inside a ZIP) to a reporting destination. This is the automatable pull that lets the
        same KPI data be reproduced on a schedule. DEFAULTS TO A DRY SINGLE RUN — it performs one
        export and exits; it does NOT install a recurring schedule (do that in Task Scheduler /
        Azure Automation once the dry run succeeds).
    HOW TO RUN
        Dry single run (default):
          powershell -ExecutionPolicy Bypass -File .\EPRPT-Export-Scheduled.ps1 -OutputPath C:\Reporting\export
        Choose a report (default DeviceCompliance):
          ... -ReportName Devices -OutputPath C:\Reporting\export
        Unattended (app registration), pass app credentials via environment secrets, not literals.
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All (read).
    EXPECTED RESULTS
        One downloaded export file in -OutputPath and a SUCCESS line; no recurring schedule is created.
.NOTES
    Workplace Marketplace — Infrastructure. Reads/exports Intune report data via Microsoft Graph.
    Common report names: DeviceCompliance, Devices, DeviceInstallStatusByApp, BitLockerReport,
    FeatureUpdateDeviceState (confirm the current list in your tenant before scheduling).
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$OutputPath,
    [string]$ReportName = 'DeviceCompliance',
    [int]$TimeoutSeconds = 300
)
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== Endpoint Reporting — export (dry single run) ===" -ForegroundColor Cyan
Write-Host ("Report: {0}  ->  {1}" -f $ReportName,$OutputPath)

# 1) Create the export job
$body = @{ reportName = $ReportName; format = 'csv' } | ConvertTo-Json
$job  = Invoke-MgGraphRequest -Method POST -Uri '/beta/deviceManagement/reports/exportJobs' -Body $body -ContentType 'application/json'
$jobId = $job.id
Write-Host ("Export job created: {0} (status {1})" -f $jobId,$job.status)

# 2) Poll until complete
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
    Start-Sleep -Seconds 5
    $job = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/reports/exportJobs('$jobId')"
    Write-Host ("  status: {0}" -f $job.status)
} while ($job.status -ne 'completed' -and (Get-Date) -lt $deadline)

if ($job.status -ne 'completed') { Write-Host "Result: TIMED OUT — job not complete (see Troubleshooting C)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }

# 3) Download the file (job.url is a short-lived SAS link to a ZIP)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dest  = Join-Path $OutputPath ("{0}-{1}.zip" -f $ReportName,$stamp)
Invoke-WebRequest -Uri $job.url -OutFile $dest -UseBasicParsing
Write-Host ("`nResult: SUCCESS — downloaded {0}" -f $dest) -ForegroundColor Green
Write-Host "This was a single dry run. To recur, register this script as a scheduled task using the" -ForegroundColor DarkGray
Write-Host "app registration 'Endpoint Reporting Export - Tenant - Prod' (credentials from env secrets)." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
