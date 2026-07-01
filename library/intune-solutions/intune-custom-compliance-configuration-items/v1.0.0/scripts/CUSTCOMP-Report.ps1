<#
.SYNOPSIS
    CUSTCOMP-Report.ps1 — fleet-wide device compliance status + custom compliance policies (Graph).
.DESCRIPTION
    PURPOSE
        Lists the custom compliance policies in Intune and reports each managed Windows device's
        overall compliance state and last sync, so you can see which devices are failing after a
        custom rule is assigned.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CUSTCOMP-Report.ps1 -CsvPath C:\Temp\custcomp.csv
        Requires Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All +
        DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        The custom compliance policies found, a breakdown of devices by compliance state, and a
        per-device CSV (device, compliance state, last sync).
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

# Custom compliance policies (deviceCompliancePolicies with a custom compliance script reference)
Write-Host "=== Custom compliance policies ===" -ForegroundColor Cyan
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceCompliancePolicies').value
$custom = $pols | Where-Object { $_.'@odata.type' -match 'windows10CompliancePolicy' -and $_.deviceCompliancePolicyScript }
if ($custom) { foreach ($c in $custom) { Write-Host ("  {0}" -f $c.displayName) } }
else { Write-Host "  (none with a custom compliance script — check policy config)" -ForegroundColor Yellow }

# Device compliance state
$devs = @(); $uri = '/v1.0/deviceManagement/managedDevices?$select=deviceName,complianceState,osVersion,lastSyncDateTime&$filter=operatingSystem eq ''Windows'''
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$report = $devs | ForEach-Object { [pscustomobject]@{ Device=$_.deviceName; Compliance=$_.complianceState; OSVersion=$_.osVersion; LastSync=$_.lastSyncDateTime } }
Write-Host "`n=== Windows devices by compliance state ===" -ForegroundColor Cyan
$report | Group-Object Compliance | Sort-Object Name | Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
Write-Host ("Total Windows devices: {0}" -f $report.Count) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
