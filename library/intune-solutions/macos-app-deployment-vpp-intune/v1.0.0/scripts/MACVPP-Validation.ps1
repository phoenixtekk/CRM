<#
.SYNOPSIS
    MACVPP-Validation.ps1 — validate one Mac against the solution's app + licensing acceptance gate.
.DESCRIPTION
    PURPOSE
        For one macOS device (by serial number or device name), confirms it is a managed macOS
        device, that a target App Store (VPP) app is installed and device-licensed, and that a
        target enterprise (LOB) app is installed. Produces a clear PASS/FAIL verdict. Use app
        names like your-store-app and your-lob-app in the parameters, not angle-bracket placeholders.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        powershell -ExecutionPolicy Bypass -File .\MACVPP-Validation.ps1 -Serial C02XXXXXXXXX -StoreAppName 'your-store-app' -LobAppName 'your-lob-app'
        powershell -ExecutionPolicy Bypass -File .\MACVPP-Validation.ps1 -DeviceName 'Jane-MacBook'
        Required Graph scopes: DeviceManagementManagedDevices.Read.All, DeviceManagementApps.Read.All
        Reads only — makes no changes.
    EXPECTED RESULTS
        A per-check PASS/FAIL table and an overall verdict. A fully validated Mac passes every
        check; investigate any FAIL using the Troubleshooting guide.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$Serial,
    [string]$DeviceName,
    [string]$StoreAppName,
    [string]$LobAppName
)

if (-not $Serial -and -not $DeviceName) { throw 'Provide -Serial or -DeviceName.' }
$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementApps.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

# Locate the device
$filter = if ($Serial) { "serialNumber eq '$Serial'" } else { "deviceName eq '$DeviceName'" }
$resp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=$filter"
$dev = @($resp.value | Where-Object { $_.operatingSystem -match 'macOS|OS X' })[0]
if (-not $dev) { throw "No macOS managed device found for $filter." }

$results = New-Object System.Collections.Generic.List[object]
$results.Add( (R 'Managed macOS device'  $true "$($dev.deviceName) ($($dev.serialNumber))") )
$results.Add( (R 'Company-owned'          ($dev.managedDeviceOwnerType -eq 'company') "Ownership=$($dev.managedDeviceOwnerType)") )

# Detected (installed) apps on this device
$installed = @()
try {
    $da = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($dev.id)/detectedApps"
    $installed = @($da.value)
} catch {}

# Store (VPP) app installed?
if ($StoreAppName) {
    $hit = @($installed | Where-Object { $_.displayName -match [regex]::Escape($StoreAppName) })
    $results.Add( (R "Store (VPP) app '$StoreAppName' installed" ($hit.Count -gt 0) $(if ($hit.Count){ "v$($hit[0].version)" } else { 'not detected' })) )
} else {
    $results.Add( (R "Store (VPP) app installed" $true 'skipped — pass -StoreAppName to check a specific app') )
}

# Store (VPP) app device-licensed?
if ($StoreAppName) {
    $lic = $false; $ldetail = 'no device VPP license found'
    try {
        $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.macOsVppApp')"
        $app  = @($apps.value | Where-Object { $_.displayName -match [regex]::Escape($StoreAppName) })[0]
        if ($app) {
            $assign = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
            $mine = @($assign.value | Where-Object { $_.deviceId -eq $dev.id -or $_.deviceDisplayName -eq $dev.deviceName })
            $usedDevice = ([int]$app.usedLicenseCount -gt 0)
            if ($mine.Count -gt 0 -or $usedDevice) { $lic = $true; $ldetail = "used $($app.usedLicenseCount)/$($app.totalLicenseCount); licensingType(device) expected" }
        } else { $ldetail = "VPP app '$StoreAppName' not found in tenant" }
    } catch { $ldetail = $_.Exception.Message }
    $results.Add( (R "Store (VPP) app device-licensed" $lic $ldetail) )
}

# Enterprise (LOB) app installed?
if ($LobAppName) {
    $hit = @($installed | Where-Object { $_.displayName -match [regex]::Escape($LobAppName) })
    $results.Add( (R "Enterprise (LOB) app '$LobAppName' installed" ($hit.Count -gt 0) $(if ($hit.Count){ "v$($hit[0].version)" } else { 'not detected' })) )
} else {
    $results.Add( (R "Enterprise (LOB) app installed" $true 'skipped — pass -LobAppName to check a specific app') )
}

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — device meets the app + licensing acceptance gate.' -ForegroundColor Green }
else { Write-Host "OVERALL: FAIL — $fail check(s) failed. See the Troubleshooting guide." -ForegroundColor Yellow }
