<#
.SYNOPSIS
    Autopilot-TenantReport.ps1 — tenant-wide Windows Autopilot device + profile report (Graph).
.DESCRIPTION
    PURPOSE
        Lists registered Autopilot devices with their serial, model, enrollment state, and
        deployment-profile assignment status, so you can confirm registration/assignment coverage.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\Autopilot-TenantReport.ps1 -CsvPath C:\Temp\autopilot.csv
        Requires Microsoft Graph SDK (installs if missing) and DeviceManagementServiceConfig.Read.All.
    EXPECTED RESULTS
        A table (and optional CSV) of Autopilot devices and their profile assignment status.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All' -NoWelcome
$devs = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities').value
$report = foreach ($d in $devs) {
    [pscustomobject]@{
        Serial = $d.serialNumber; Model = $d.model
        EnrollmentState = $d.enrollmentState; ProfileStatus = $d.deploymentProfileAssignmentStatus
        LastContact = $d.lastContactedDateTime
    }
}
$report | Sort-Object ProfileStatus, Serial | Format-Table -AutoSize
$assigned = ($report | Where-Object { $_.ProfileStatus -like 'assigned*' }).Count
Write-Host ("`nProfile assigned: {0}/{1} Autopilot devices." -f $assigned, $report.Count) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
