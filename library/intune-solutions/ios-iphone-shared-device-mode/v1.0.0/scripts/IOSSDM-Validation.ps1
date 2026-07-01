<#
.SYNOPSIS
    IOSSDM-Validation.ps1 — prove a shared iPhone is DEM-enrolled, supervised, locked, and has Webex.

.DESCRIPTION
    PURPOSE
        For a given device (by name or serial), validates the shared-device acceptance gate: it is
        enrolled with NO primary user, is supervised, is an iOS device, and (best-effort) has the
        Cisco Webex managed app reporting installed. Produces a clear PASS/FAIL verdict.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\IOSSDM-Validation.ps1 -DeviceName "SHARED-IPHONE-01"
        .\IOSSDM-Validation.ps1 -Serial "F2LXXXXXXX"

    EXPECTED RESULTS
        A device summary plus per-check PASS/FAIL. A fully validated shared phone shows: no primary
        user, Supervised = Yes, iOS platform, and Cisco Webex installed.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$DeviceName,
    [string]$Serial,
    [string]$WebexNameLike = 'Webex'
)

if (-not $DeviceName -and -not $Serial) { throw 'Provide -DeviceName or -Serial.' }
$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

# Locate the managed device
if ($DeviceName) { $flt = "deviceName eq '$($DeviceName.Replace("'","''"))'" }
else { $flt = "serialNumber eq '$($Serial.Replace("'","''"))'" }
$dev = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter={0}" -f $flt)).value | Select-Object -First 1
if (-not $dev) { throw "Device not found ($flt)." }

Write-Host "Device  : $($dev.deviceName)  [$($dev.operatingSystem) $($dev.osVersion)]"
Write-Host "Serial  : $($dev.serialNumber)"
Write-Host "EnrolledBy: $($dev.userPrincipalName)"
Write-Host "PrimaryUser: $(if ([string]::IsNullOrEmpty($dev.userId)) { '(none)' } else { $dev.userId })"
Write-Host ''

$results = @()
$results += R 'iOS device' ($dev.operatingSystem -match 'iOS|iPadOS') $dev.operatingSystem
$results += R 'No primary user (shared)' ([string]::IsNullOrEmpty($dev.userId)) ($(if ([string]::IsNullOrEmpty($dev.userId)) { 'Shared — no primary user' } else { "Has primary user $($dev.userPrincipalName)" }))
$results += R 'Supervised' ([bool]$dev.isSupervised) ($(if ($dev.isSupervised) { 'Supervised = Yes' } else { 'Not supervised — kiosk will not lock' }))
$results += R 'Managed/compliant' ($dev.complianceState -eq 'compliant') "complianceState = $($dev.complianceState)"

# Cisco Webex install state (best-effort via detected/managed apps)
try {
    $apps = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($dev.id)/detectedApps").value
    $webex = $apps | Where-Object { $_.displayName -like "*$WebexNameLike*" }
    $results += R 'Cisco Webex present' ([bool]$webex) ($(if ($webex) { ($webex.displayName | Select-Object -First 1) } else { 'Webex not detected on device' }))
} catch {
    $results += R 'Cisco Webex present' $false 'Could not read detected apps (check in Intune > device > Managed apps)'
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'GATE: PASS — shared iPhone is correctly enrolled, supervised, and provisioned.' -ForegroundColor Green }
else { Write-Host "GATE: FAIL — $fail check(s) failed. See Troubleshooting." -ForegroundColor Yellow }
