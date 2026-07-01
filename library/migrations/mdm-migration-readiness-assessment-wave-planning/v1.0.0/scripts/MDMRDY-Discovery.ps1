<#
.SYNOPSIS
    MDMRDY-Discovery.ps1 — build the estate inventory for an MDM migration (vendor-neutral).
.DESCRIPTION
    PURPOSE
        Produces the "Estate Inventory - MDM Migration - Assess" artifact: a normalized CSV of every
        in-scope device with platform, OS, owner, department/region, enrollment type, compliance,
        apps, and profiles. Reads a generic CSV export from ANY source MDM, or (optional) pulls a
        live inventory from Microsoft Graph when the current/target MDM is Intune-adjacent.
        Read-only: it never writes to the source platform.
    HOW TO RUN
        CSV source (any MDM):
          powershell -ExecutionPolicy Bypass -File .\MDMRDY-Discovery.ps1 -InputCsv .\source-export.csv -OutputFolder C:\MDMRDY
        Intune source/target (optional):
          powershell -ExecutionPolicy Bypass -File .\MDMRDY-Discovery.ps1 -UseGraph -OutputFolder C:\MDMRDY
        Graph mode needs Microsoft.Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Writes estate-inventory.csv (the "Estate Inventory - MDM Migration - Assess") to the output
        folder and prints a device/platform summary. No source-side changes.
.NOTES
    Migrations — vendor-neutral pre-migration assessment. Read-only.
#>
[CmdletBinding()]
param(
    [string]$InputCsv,
    [switch]$UseGraph,
    [string]$OutputFolder = (Join-Path $PWD 'MDMRDY')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$outFile = Join-Path $OutputFolder 'estate-inventory.csv'

$columns = 'DeviceName','Platform','OSVersion','Owner','Department','Region','EnrollmentType','Compliance','LastCheckIn','Apps','Profiles','Criticality'

function New-Row { param($src)
    $row = [ordered]@{}
    foreach ($c in $columns) { $row[$c] = if ($src.PSObject.Properties.Name -contains $c) { $src.$c } else { '' } }
    [pscustomobject]$row
}

$inventory = New-Object System.Collections.Generic.List[object]

if ($UseGraph) {
    Write-Host "=== Discovery via Microsoft Graph ===" -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
    $devices = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/managedDevices?$top=999').value
    foreach ($d in $devices) {
        $plat = switch -Regex ($d.operatingSystem) {
            'iPadOS' { 'iPadOS' } 'iOS'  { 'iOS' } 'macOS' { 'macOS' }
            'Android' { 'Android' } 'Windows' { 'Windows' } default { $d.operatingSystem }
        }
        $inventory.Add( (New-Row ([pscustomobject]@{
            DeviceName     = $d.deviceName
            Platform       = $plat
            OSVersion      = $d.osVersion
            Owner          = $d.userPrincipalName
            Department     = ''
            Region         = ''
            EnrollmentType = $d.deviceEnrollmentType
            Compliance     = $d.complianceState
            LastCheckIn    = $d.lastSyncDateTime
            Apps           = ''
            Profiles       = ''
            Criticality    = ''
        })) )
    }
    Disconnect-MgGraph | Out-Null
}
elseif ($InputCsv) {
    Write-Host "=== Discovery via CSV export ($InputCsv) ===" -ForegroundColor Cyan
    if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }
    foreach ($r in (Import-Csv -Path $InputCsv)) { $inventory.Add( (New-Row $r) ) }
}
else {
    throw "Provide -InputCsv <path> for a generic source export, or -UseGraph for an Intune-adjacent source."
}

$inventory | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8

# Summary
$total = $inventory.Count
Write-Host ("Devices inventoried : {0}" -f $total) -ForegroundColor Green
Write-Host "By platform:"
$inventory | Group-Object Platform | Sort-Object Count -Descending |
    ForEach-Object { Write-Host ("  {0,-10} {1}" -f $_.Name, $_.Count) }
Write-Host ("Artifact written    : {0}  (Estate Inventory - MDM Migration - Assess)" -f $outFile) -ForegroundColor Green
