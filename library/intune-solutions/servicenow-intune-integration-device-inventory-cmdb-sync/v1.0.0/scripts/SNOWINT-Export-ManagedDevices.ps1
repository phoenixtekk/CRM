<#
.SYNOPSIS
    SNOWINT-Export-ManagedDevices.ps1 — export the Intune managed-device dataset ServiceNow imports.
.DESCRIPTION
    PURPOSE
        Produces a CSV of the same managed-device inventory the ServiceNow Service Graph Connector
        pulls from Graph (serial number, name, OS, ownership, compliance, last check-in). Use it as
        the Microsoft-side "source of truth" to reconcile against what actually landed in the CMDB.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SNOWINT-Export-ManagedDevices.ps1 `
            -CsvPath C:\Temp\intune-devices.csv [-Cloud Global|USGov|USGovDoD]
        Requires the Microsoft.Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A CSV (and on-screen count) of all Intune managed devices with the fields the CMDB maps.
        Hand this to SNOWINT-Validate-Sync.ps1 (or compare to a CMDB export) to prove the feed.
.NOTES
    Intune Solutions — read-only. Cloud-aware (Global / USGov / USGovDoD).
#>
[CmdletBinding()]
param(
    [string]$CsvPath = ".\SNOWINT-intune-devices.csv",
    [ValidateSet('Global','USGov','USGovDoD')][string]$Cloud = 'Global'
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -Environment $Cloud -NoWelcome

$base = switch ($Cloud) {
    'USGov'    { 'https://graph.microsoft.us' }
    'USGovDoD' { 'https://dod-graph.microsoft.us' }
    default    { 'https://graph.microsoft.com' }
}

$select = 'id,deviceName,serialNumber,manufacturer,model,operatingSystem,osVersion,' +
          'managedDeviceOwnerType,complianceState,userPrincipalName,emailAddress,lastSyncDateTime'
$uri = "$base/v1.0/deviceManagement/managedDevices?`$select=$select&`$top=200"

$rows = New-Object System.Collections.Generic.List[object]
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($d in $page.value) {
        $rows.Add([pscustomobject]@{
            DeviceName   = $d.deviceName
            SerialNumber = $d.serialNumber
            Manufacturer = $d.manufacturer
            Model        = $d.model
            OS           = $d.operatingSystem
            OSVersion    = $d.osVersion
            Ownership    = $d.managedDeviceOwnerType
            Compliance   = $d.complianceState
            PrimaryUser  = $d.userPrincipalName
            LastCheckIn  = $d.lastSyncDateTime
        })
    }
    $uri = $page.'@odata.nextLink'
} while ($uri)

$rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host ("Exported {0} managed devices to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
$rows | Group-Object OS | Sort-Object Count -Descending |
    Select-Object @{n='Platform';e={$_.Name}}, Count | Format-Table -AutoSize
Disconnect-MgGraph | Out-Null
