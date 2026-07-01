<#
.SYNOPSIS
    DCP-TenantReport.ps1 — tenant-wide device compliance status report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Summarizes managed-device compliance state (compliant / noncompliant / in grace / unknown)
        so you can measure coverage and chase failures.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DCP-TenantReport.ps1 -CsvPath C:\Temp\compliance.csv
        Requires Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A status breakdown and an optional per-device CSV.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
$devs = @(); $uri = '/v1.0/deviceManagement/managedDevices?$select=deviceName,operatingSystem,complianceState,userPrincipalName,lastSyncDateTime'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$report = $devs | ForEach-Object { [pscustomobject]@{ Device=$_.deviceName; OS=$_.operatingSystem; State=$_.complianceState; User=$_.userPrincipalName; LastSync=$_.lastSyncDateTime } }
$report | Group-Object State | Select-Object Name, Count | Format-Table -AutoSize
$comp = ($report | Where-Object State -eq 'compliant').Count
Write-Host ("Compliant: {0}/{1} devices." -f $comp, $report.Count) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
