<#
.SYNOPSIS
    SNOWINT-Report-Coverage.ps1 — Intune managed-device coverage by platform, ownership, compliance.
.DESCRIPTION
    PURPOSE
        Summarizes the Intune managed-device estate the CMDB feed should reflect: counts by platform
        (Windows/macOS/iOS/Android), by ownership (corporate/personal), by compliance state, and how
        many devices have a stale last check-in. Use it to set expectations for CMDB coverage and to
        track the feed wave over wave during a Workspace ONE -> Intune transition.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SNOWINT-Report-Coverage.ps1 `
            [-StaleDays 30] [-CsvPath C:\Temp\coverage.csv] [-Cloud Global|USGov|USGovDoD]
        Requires the Microsoft.Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        On-screen breakdowns (platform / ownership / compliance / stale) and an optional CSV. The
        totals should match the device count that lands in the ServiceNow CMDB.
.NOTES
    Intune Solutions — read-only. Cloud-aware (Global / USGov / USGovDoD).
#>
[CmdletBinding()]
param(
    [int]$StaleDays = 30,
    [string]$CsvPath,
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

$select = 'deviceName,serialNumber,operatingSystem,managedDeviceOwnerType,complianceState,lastSyncDateTime'
$uri = "$base/v1.0/deviceManagement/managedDevices?`$select=$select&`$top=200"
$all = New-Object System.Collections.Generic.List[object]
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    $page.value | ForEach-Object { $all.Add($_) }
    $uri = $page.'@odata.nextLink'
} while ($uri)
Disconnect-MgGraph | Out-Null

$cutoff = (Get-Date).AddDays(-$StaleDays)
$stale = @($all | Where-Object { $_.lastSyncDateTime -and ([datetime]$_.lastSyncDateTime) -lt $cutoff }).Count
$noSerial = @($all | Where-Object { -not ("$($_.serialNumber)").Trim() }).Count

Write-Host "`n=== SNOWINT Coverage ($Cloud) — $($all.Count) managed devices ===" -ForegroundColor Cyan
Write-Host "-- By platform --" -ForegroundColor Cyan
$all | Group-Object operatingSystem | Sort-Object Count -Descending | Select-Object @{n='Platform';e={$_.Name}},Count | Format-Table -AutoSize
Write-Host "-- By ownership --" -ForegroundColor Cyan
$all | Group-Object managedDeviceOwnerType | Select-Object @{n='Ownership';e={$_.Name}},Count | Format-Table -AutoSize
Write-Host "-- By compliance --" -ForegroundColor Cyan
$all | Group-Object complianceState | Select-Object @{n='Compliance';e={$_.Name}},Count | Format-Table -AutoSize
Write-Host ("Stale (> $StaleDays days no check-in): {0}" -f $stale) -ForegroundColor $(if($stale){'Yellow'}else{'Green'})
Write-Host ("Devices with NO serial number (will not reconcile by serial): {0}" -f $noSerial) -ForegroundColor $(if($noSerial){'Yellow'}else{'Green'})

if ($CsvPath) {
    $all | Select-Object deviceName,serialNumber,operatingSystem,managedDeviceOwnerType,complianceState,lastSyncDateTime |
        Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Saved $CsvPath" -ForegroundColor Green
}
