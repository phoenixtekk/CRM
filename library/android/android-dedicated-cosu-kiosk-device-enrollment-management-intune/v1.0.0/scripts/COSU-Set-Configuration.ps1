<#
.SYNOPSIS
    COSU-Set-Configuration.ps1 — create the dedicated enrollment profile + kiosk device-restrictions profile (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates the two Intune objects this solution relies on: (1) the corporate-owned DEDICATED
        (COSU) Android enrollment profile that produces the enrollment token/QR, and (2) the Android
        Enterprise device-restrictions profile that configures the KIOSK — single-app (lock to one
        package) or multi-app (Managed Home Screen with a curated app list). Idempotent: skips objects
        that already exist by display name. Default -WhatIf; pass -Apply to make changes.
    HOW TO RUN
        Preview (default):   powershell -ExecutionPolicy Bypass -File .\COSU-Set-Configuration.ps1
        Single-app kiosk:    ... -Apply -KioskMode Single -KioskApps 'com.vendor.scanapp'
        Multi-app kiosk:     ... -Apply -KioskMode Multi  -KioskApps 'com.vendor.a','com.vendor.b'
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All.
    EXPECTED RESULTS
        The dedicated enrollment profile and the kiosk device-restrictions profile exist (created if
        missing). Assign apps (Required-to-device) and the kiosk profile to the device group per the
        Implementation Guide. Multi-app also requires the Managed Home Screen app assigned to the group.
.NOTES
    Android category — Android dedicated (COSU)/kiosk. Default -WhatIf. Verify the current schema/portal against Microsoft guidance before -Apply.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$EnrollmentProfileName = 'Android Dedicated - COSU - Pilot',
    [int]$TokenValidityDays        = 90,
    [string]$KioskProfileName       = 'Android Dedicated - Kiosk - Pilot',
    [ValidateSet('Single','Multi')]
    [string]$KioskMode              = 'Single',
    [string[]]$KioskApps            = @(),
    [switch]$Apply
)

$WhatIfPreference = -not $Apply

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.ReadWrite.All','DeviceManagementConfiguration.ReadWrite.All' -NoWelcome

Write-Host "=== Configure Android dedicated (COSU) enrollment profile + kiosk ===" -ForegroundColor Cyan
if (-not $Apply) { Write-Host "(preview mode — re-run with -Apply to make changes)" -ForegroundColor Yellow }

# ---------- 1) Dedicated enrollment profile ----------
Write-Host "`n-- Enrollment profile --" -ForegroundColor Cyan
$existing = $null
try {
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles").value |
                Where-Object { $_.displayName -eq $EnrollmentProfileName } | Select-Object -First 1
} catch {}
if ($existing) {
    Write-Host ("  OK   : enrollment profile '{0}' already exists (id {1})." -f $EnrollmentProfileName, $existing.id) -ForegroundColor Green
} elseif ($PSCmdlet.ShouldProcess($EnrollmentProfileName, "Create dedicated enrollment profile")) {
    $body = @{
        displayName          = $EnrollmentProfileName
        description          = 'Corporate-owned dedicated (COSU) enrollment profile.'
        enrollmentMode       = 'corporateOwnedDedicatedDevice'
        tokenValidityInSeconds = ([int]$TokenValidityDays * 86400)
    } | ConvertTo-Json
    try {
        $new = Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles" -Body $body -ContentType 'application/json'
        Write-Host ("  DONE : created '{0}' (id {1}). Open it in Intune to view the token/QR." -f $EnrollmentProfileName, $new.id) -ForegroundColor Green
    } catch {
        Write-Host ("  FAIL : could not create enrollment profile: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host ("  WOULD: create dedicated enrollment profile '{0}' (token valid {1} day(s))." -f $EnrollmentProfileName, $TokenValidityDays) -ForegroundColor Cyan
}

# ---------- 2) Kiosk device-restrictions profile ----------
Write-Host "`n-- Kiosk device-restrictions profile --" -ForegroundColor Cyan
if ($KioskApps.Count -eq 0) {
    Write-Host "  NOTE : no -KioskApps supplied — pass the package name(s) the kiosk should allow." -ForegroundColor Yellow
}
$kExisting = $null
try {
    $kExisting = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=displayName eq '$($KioskProfileName.Replace("'","''"))'").value | Select-Object -First 1
} catch {}
if ($kExisting) {
    Write-Host ("  OK   : kiosk profile '{0}' already exists (id {1})." -f $KioskProfileName, $kExisting.id) -ForegroundColor Green
} elseif ($PSCmdlet.ShouldProcess($KioskProfileName, "Create $KioskMode-app kiosk profile")) {
    $kioskAppList = @()
    foreach ($pkg in $KioskApps) { $kioskAppList += @{ '@odata.type' = 'microsoft.graph.androidDeviceOwnerKioskModeApp'; packageId = $pkg } }
    $cfg = @{
        '@odata.type'                    = 'microsoft.graph.androidDeviceOwnerGeneralDeviceConfiguration'
        displayName                      = $KioskProfileName
        description                      = "Dedicated (COSU) $KioskMode-app kiosk."
        kioskModeApps                    = $kioskAppList
        kioskModeManagedHomeScreenEnabled = ($KioskMode -eq 'Multi')
    }
    if ($KioskMode -eq 'Single') {
        $cfg.kioskModeUseManagedHomeScreenApp = 'notConfigured'
    }
    $body = $cfg | ConvertTo-Json -Depth 6
    try {
        $new = Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/deviceConfigurations" -Body $body -ContentType 'application/json'
        Write-Host ("  DONE : created kiosk profile '{0}' (id {1}, {2}-app)." -f $KioskProfileName, $new.id, $KioskMode) -ForegroundColor Green
        if ($KioskMode -eq 'Multi') { Write-Host "  NEXT : ensure Managed Home Screen (com.microsoft.launcher.enterprise) is assigned Required to the device group." -ForegroundColor DarkGray }
    } catch {
        Write-Host ("  FAIL : could not create kiosk profile: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "         The device-restrictions/kiosk schema evolves — verify property names against current Microsoft guidance, or build it in the portal (Implementation Step 5)." -ForegroundColor DarkGray
    }
} else {
    Write-Host ("  WOULD: create {0}-app kiosk profile '{1}' allowing: {2}" -f $KioskMode, $KioskProfileName, ($KioskApps -join ', ')) -ForegroundColor Cyan
}

Write-Host "`nNext: assign the kiosk app(s) Required-to-device and the kiosk profile to 'Android Dedicated - Devices - Pilot' (Implementation Steps 4-5)." -ForegroundColor DarkGray
Write-Host "Validate with COSU-Validation.ps1 (only-allowed-apps report)." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
