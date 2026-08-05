<#
.SYNOPSIS
    SNOWINT-Validate-Sync.ps1 — compare the Intune device set against a CMDB export (reconciliation).
.DESCRIPTION
    PURPOSE
        Proves the ServiceNow feed is correct and de-duplicated. Reads live Intune managed devices
        and a CSV the admin exports from the ServiceNow CMDB, then reports: matched (in both),
        missing in CMDB (in Intune, not yet imported), stale in CMDB (in CMDB, not in Intune), and
        DUPLICATE serials in the CMDB (an IRE / identifier problem to fix).
    HOW TO RUN
        1) Export the CMDB device list to CSV with at least a serial-number column (e.g. a report
           on cmdb_ci_computer + the handheld class; column name passed via -CmdbSerialColumn).
        2) powershell -ExecutionPolicy Bypass -File .\SNOWINT-Validate-Sync.ps1 `
              -CmdbCsv C:\Temp\cmdb-devices.csv [-CmdbSerialColumn serial_number] [-Cloud Global|USGov|USGovDoD]
        Requires the Microsoft.Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Counts + a breakdown for matched / missing-in-CMDB / stale-in-CMDB / duplicate serials, with
        optional detail CSVs. Zero duplicates and near-zero missing = a healthy, reconciled feed.
.NOTES
    Intune Solutions — read-only (reads Graph + a local CSV; writes only report CSVs). Cloud-aware.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$CmdbCsv,
    [string]$CmdbSerialColumn = 'serial_number',
    [string]$OutDir = ".",
    [ValidateSet('Global','USGov','USGovDoD')][string]$Cloud = 'Global'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $CmdbCsv)) { Write-Host "CMDB CSV not found: $CmdbCsv" -ForegroundColor Red; exit 1 }
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

# --- live Intune serials ---
$intune = @{}
$uri = "$base/v1.0/deviceManagement/managedDevices?`$select=deviceName,serialNumber&`$top=200"
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($d in $page.value) {
        $sn = ("$($d.serialNumber)").Trim().ToUpper()
        if ($sn) { $intune[$sn] = $d.deviceName }
    }
    $uri = $page.'@odata.nextLink'
} while ($uri)
Disconnect-MgGraph | Out-Null

# --- CMDB serials (detect duplicates) ---
$cmdbRows = Import-Csv -Path $CmdbCsv
if (-not ($cmdbRows | Get-Member -Name $CmdbSerialColumn -MemberType NoteProperty)) {
    Write-Host "Column '$CmdbSerialColumn' not found in $CmdbCsv. Use -CmdbSerialColumn to name the serial column." -ForegroundColor Red
    exit 1
}
$cmdbSerials = $cmdbRows | ForEach-Object { ("$($_.$CmdbSerialColumn)").Trim().ToUpper() } | Where-Object { $_ }
$cmdbSet = @{}; $dupes = @()
foreach ($s in $cmdbSerials) { if ($cmdbSet.ContainsKey($s)) { $dupes += $s } else { $cmdbSet[$s] = $true } }

$matched  = $intune.Keys | Where-Object { $cmdbSet.ContainsKey($_) }
$missing  = $intune.Keys | Where-Object { -not $cmdbSet.ContainsKey($_) }   # in Intune, not in CMDB
$stale    = $cmdbSet.Keys | Where-Object { -not $intune.ContainsKey($_) }   # in CMDB, not in Intune

Write-Host "`n=== SNOWINT Sync Validation ($Cloud) ===" -ForegroundColor Cyan
Write-Host ("  Intune devices        : {0}" -f $intune.Count)
Write-Host ("  CMDB unique serials   : {0}" -f $cmdbSet.Count)
Write-Host ("  Matched (both)        : {0}" -f @($matched).Count) -ForegroundColor Green
Write-Host ("  Missing in CMDB       : {0}" -f @($missing).Count) -ForegroundColor Yellow
Write-Host ("  Stale in CMDB         : {0}" -f @($stale).Count)   -ForegroundColor Yellow
Write-Host ("  DUPLICATE serials     : {0}" -f @($dupes | Select-Object -Unique).Count) -ForegroundColor $(if($dupes){'Red'}else{'Green'})

if ($missing) { $missing | ForEach-Object { [pscustomobject]@{ Serial=$_; IntuneName=$intune[$_] } } | Export-Csv (Join-Path $OutDir 'SNOWINT-missing-in-cmdb.csv') -NoTypeInformation }
if ($stale)   { $stale   | ForEach-Object { [pscustomobject]@{ Serial=$_ } } | Export-Csv (Join-Path $OutDir 'SNOWINT-stale-in-cmdb.csv') -NoTypeInformation }
if ($dupes)   { $dupes | Select-Object -Unique | ForEach-Object { [pscustomobject]@{ Serial=$_ } } | Export-Csv (Join-Path $OutDir 'SNOWINT-duplicate-serials.csv') -NoTypeInformation }
Write-Host "`nDetail CSVs written to $OutDir (where applicable). Duplicates indicate an IRE/identifier issue — fix the serial-number identification rule." -ForegroundColor Cyan
