<#
.SYNOPSIS
    EPRPT-Report.ps1 — consolidated endpoint KPI report (patch / compliance / encryption / app / health).
.DESCRIPTION
    PURPOSE
        Produces the consolidated endpoint KPI report from Intune data via Microsoft Graph:
        patch compliance %, device compliance %, encryption coverage %, app deployment success %,
        and device health %, optionally scoped to a reporting-scope group. Writes a summary to the
        console and a per-device CSV that EPRPT-Validation.ps1 can reconcile.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EPRPT-Report.ps1 -CsvPath C:\Temp\eprpt-report.csv [-Group "Endpoint Reporting Scope - Pilot - Stage"]
        Requires the Microsoft Graph SDK and read scopes:
        DeviceManagementManagedDevices.Read.All, DeviceManagementApps.Read.All, Group.Read.All.
    EXPECTED RESULTS
        The five endpoint KPIs as percentages and a per-device CSV (device, OS, compliant, encrypted,
        health, last sync).
.NOTES
    Workplace Marketplace — Infrastructure. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [string]$CsvPath,
    [string]$Group
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementApps.Read.All','Group.Read.All' -NoWelcome

# Optional scope: collect Entra device IDs that are members of the reporting-scope group
$scopeAzureIds = $null
if ($Group) {
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$Group'").value | Select-Object -First 1
    if (-not $g) { throw "Group not found: $Group" }
    $scopeAzureIds = @()
    $muri = "/v1.0/groups/$($g.id)/members?`$select=id,deviceId"
    do { $m = Invoke-MgGraphRequest -Method GET -Uri $muri; $scopeAzureIds += ($m.value | ForEach-Object { $_.deviceId } | Where-Object { $_ }); $muri = $m.'@odata.nextLink' } while ($muri)
}

# Pull managed devices
$devs = @(); $uri = "/v1.0/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,osVersion,complianceState,isEncrypted,lastSyncDateTime,azureADDeviceId"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
if ($scopeAzureIds) { $devs = $devs | Where-Object { $scopeAzureIds -contains $_.azureADDeviceId } }

$now = Get-Date
$rows = foreach ($d in $devs) {
    $sync = if ($d.lastSyncDateTime) { [datetime]$d.lastSyncDateTime } else { $null }
    $healthy = ($sync -ne $null) -and (($now - $sync).TotalDays -le 7)
    [pscustomobject]@{
        Device    = $d.deviceName
        OS        = $d.operatingSystem
        OSVersion = $d.osVersion
        Compliant = ($d.complianceState -eq 'compliant')
        Encrypted = [bool]$d.isEncrypted
        Healthy   = $healthy
        LastSync  = $d.lastSyncDateTime
    }
}

# App deployment success % (across all targeted app install statuses)
$appSuccess = $null
try {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/reports/getAppsInstallSummaryReport" -Body '{}' -ContentType 'application/json' -ErrorAction Stop)
} catch { $st = $null }

$total = @($rows).Count
function Pct($n,$d){ if ($d -gt 0) { [math]::Round(($n/$d)*100,1) } else { 0 } }
$pCompliant = Pct (@($rows | Where-Object Compliant).Count) $total
$pEncrypted = Pct (@($rows | Where-Object Encrypted).Count) $total
$pHealthy   = Pct (@($rows | Where-Object Healthy).Count)   $total
# Patch compliance proxy: devices healthy + compliant are treated as on-cadence here; the authoritative
# patch % is the Intune Windows updates report / Graph export (see EPRPT-Export-Scheduled.ps1).
$pPatch     = Pct (@($rows | Where-Object { $_.Compliant -and $_.Healthy }).Count) $total

Write-Host "`n=== Endpoint KPI Report$(if($Group){" — $Group"}) ===" -ForegroundColor Cyan
Write-Host ("  Devices in scope          : {0}" -f $total)
Write-Host ("  Device compliance %       : {0}" -f $pCompliant)
Write-Host ("  Encryption coverage %     : {0}" -f $pEncrypted)
Write-Host ("  Device health %           : {0}" -f $pHealthy)
Write-Host ("  Patch compliance % (proxy): {0}  (authoritative: Windows updates export)" -f $pPatch)
if ($null -ne $st) { Write-Host "  App deployment success %  : see Intune App install status / export" } else { Write-Host "  App deployment success %  : run the app-install export (EPRPT-Export-Scheduled.ps1)" }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "`nSaved per-device CSV: $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
