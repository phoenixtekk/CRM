<#
.SYNOPSIS
    ENROLLID-Report.ps1 — inventory reconciliation against a "should exist" list, with gap analysis (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Pulls the Intune managed-device inventory and reconciles it against an external "should exist"
        list (procurement/CMDB/HR export). Flags the gaps that corrupt a service desk's source of
        truth: stale records (no recent sync), duplicates (same serial number), devices with no
        primary user, and expected devices that never enrolled.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENROLLID-Report.ps1 -ExpectedCsv C:\Temp\expected.csv -StaleDays 30 -CsvPath C:\Temp\recon.csv
        The expected CSV needs a 'SerialNumber' and/or 'DeviceName' column.
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Counts and lists for: stale records, duplicate serials, missing primary user, and
        expected-but-not-enrolled — plus an optional reconciliation CSV.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param(
    [string]$ExpectedCsv,
    [int]$StaleDays = 30,
    [string]$CsvPath
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
$devs = @(); $uri = "/v1.0/deviceManagement/managedDevices?`$select=deviceName,serialNumber,operatingSystem,userPrincipalName,managedDeviceOwnerType,lastSyncDateTime"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$cut = (Get-Date).AddDays(-$StaleDays)
$inv = $devs | ForEach-Object {
    [pscustomobject]@{
        Device      = $_.deviceName
        Serial      = $_.serialNumber
        OS          = $_.operatingSystem
        PrimaryUser = $_.userPrincipalName
        Ownership   = $_.managedDeviceOwnerType
        LastSync    = $_.lastSyncDateTime
        Stale       = ($_.lastSyncDateTime -and ([datetime]$_.lastSyncDateTime -lt $cut))
    }
}
$stale     = $inv | Where-Object Stale
$dupes     = $inv | Where-Object Serial | Group-Object Serial | Where-Object Count -gt 1
$noPrimary = $inv | Where-Object { -not $_.PrimaryUser -and $_.Ownership -ne 'company' -or (-not $_.PrimaryUser) }
Write-Host "`n=== Inventory reconciliation ===" -ForegroundColor Cyan
Write-Host ("Total enrolled devices : {0}" -f $inv.Count)
Write-Host ("Stale (> {0} days)      : {1}" -f $StaleDays, $stale.Count) -ForegroundColor ($(if($stale.Count){'Yellow'}else{'Green'}))
Write-Host ("Duplicate serials      : {0}" -f $dupes.Count) -ForegroundColor ($(if($dupes.Count){'Yellow'}else{'Green'}))
Write-Host ("Missing primary user   : {0}" -f $noPrimary.Count) -ForegroundColor ($(if($noPrimary.Count){'Yellow'}else{'Green'}))
if ($ExpectedCsv -and (Test-Path $ExpectedCsv)) {
    $expected = Import-Csv $ExpectedCsv
    $haveSerials = $inv.Serial | Where-Object { $_ }
    $haveNames   = $inv.Device | Where-Object { $_ }
    $missing = $expected | Where-Object {
        $s = $_.SerialNumber; $n = $_.DeviceName
        -not (($s -and $haveSerials -contains $s) -or ($n -and $haveNames -contains $n))
    }
    Write-Host ("Expected-but-not-enrolled : {0}" -f @($missing).Count) -ForegroundColor ($(if(@($missing).Count){'Yellow'}else{'Green'}))
    $missing | Select-Object SerialNumber, DeviceName | Format-Table -AutoSize
}
if ($CsvPath) { $inv | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
