<#
.SYNOPSIS
    ANDROIDENT-Set-EnrollmentRestrictions.ps1 — set the Android enrollment platform restriction (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Configures an Intune device-platform enrollment restriction so Android Enterprise (work profile /
        corporate-owned) is ALLOWED and legacy Android device administrator is BLOCKED, and sets whether
        personally-owned Android Enterprise devices may enrol (this is what enables/blocks BYOD work
        profile — BYOD has no device-side profile). Targets an existing restriction by display name (does
        NOT create the restriction object, and does NOT change its assignments). Default -WhatIf; -Apply
        writes. Enrollment restrictions apply at NEXT enrollment; existing devices are not retro-enrolled.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\ANDROIDENT-Set-EnrollmentRestrictions.ps1
        Apply:              ... -Apply
        Block BYOD:         ... -Apply -BlockPersonallyOwned
        Named restriction:  ... -RestrictionName 'Android Enterprise - Platform Restrictions - Pilot' -Apply
        Requires the Microsoft Graph PowerShell SDK and delegated scope: DeviceManagementServiceConfig.ReadWrite.All.
    EXPECTED RESULTS
        The named restriction's Android Enterprise setting is allowed (personal allowed unless
        -BlockPersonallyOwned) and legacy device administrator is blocked. Re-run ANDROIDENT-Discovery.ps1
        to confirm. AMAPI note: restriction labels/defaults are evolving — verify against current Microsoft
        guidance / your tenant.
.NOTES
    Android category — Android Enterprise connection & managed Google Play setup. Default -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$RestrictionName = 'Android Enterprise - Platform Restrictions - Pilot',
    [switch]$BlockPersonallyOwned,
    [switch]$Apply
)

$WhatIfPreference = -not $Apply

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.ReadWrite.All' -NoWelcome

Write-Host "=== Android enrollment platform restriction ===" -ForegroundColor Cyan
if (-not $Apply) { Write-Host "(preview mode — re-run with -Apply to make changes)" -ForegroundColor Yellow }

# Locate the platform-restrictions configuration by display name
$cfgs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceEnrollmentConfigurations?`$top=100").value
$restr = $cfgs | Where-Object {
    ($_.'@odata.type' -like '*deviceEnrollmentPlatformRestrictionsConfiguration*') -and
    ($_.displayName -eq $RestrictionName)
} | Select-Object -First 1

if (-not $restr) {
    Write-Host ("Restriction '{0}' not found." -f $RestrictionName) -ForegroundColor Yellow
    Write-Host "Create it first in Intune > Devices > Enrollment > Enrollment restrictions > Device platform restrictions" -ForegroundColor Yellow
    Write-Host "(Implementation Step 5), then re-run this script to set the Android values." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    return
}

Write-Host ("Target restriction : {0}  (id {1})" -f $restr.displayName, $restr.id) -ForegroundColor Green

# Desired Android values: AE allowed; personal allowed unless -BlockPersonallyOwned; legacy DA blocked.
$personalBlocked = [bool]$BlockPersonallyOwned
$body = @{
    '@odata.type' = '#microsoft.graph.deviceEnrollmentPlatformRestrictionsConfiguration'
    androidForWorkRestriction = @{
        '@odata.type'                    = 'microsoft.graph.deviceEnrollmentPlatformRestriction'
        platformBlocked                  = $false          # Android Enterprise ALLOWED
        personalDeviceEnrollmentBlocked  = $personalBlocked # BYOD work profile allowed unless blocked
    }
    androidRestriction = @{
        '@odata.type'                    = 'microsoft.graph.deviceEnrollmentPlatformRestriction'
        platformBlocked                  = $true           # legacy device administrator BLOCKED
        personalDeviceEnrollmentBlocked  = $true
    }
} | ConvertTo-Json -Depth 6

Write-Host ("Planned            : Android Enterprise = ALLOWED (personal {0}); legacy device admin = BLOCKED." -f ($(if($personalBlocked){'BLOCKED'}else{'allowed'})))

if ($PSCmdlet.ShouldProcess($RestrictionName, "PATCH Android enrollment platform restriction")) {
    try {
        Invoke-MgGraphRequest -Method PATCH -Uri "/beta/deviceManagement/deviceEnrollmentConfigurations/$($restr.id)" -Body $body -ContentType 'application/json' | Out-Null
        Write-Host "  DONE : restriction updated. Applies at NEXT enrollment (existing devices unaffected)." -ForegroundColor Green
    } catch {
        Write-Host ("  FAIL : could not update restriction: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "         Property names/shape for the Android restriction are evolving with AMAPI — verify the current" -ForegroundColor Yellow
        Write-Host "         schema against Microsoft's documentation for your tenant, or set the values in the Intune portal." -ForegroundColor Yellow
    }
} else {
    Write-Host "  WOULD: PATCH the restriction with the planned Android values above." -ForegroundColor Cyan
}

Write-Host "`nReminder: confirm the restriction is assigned to your pilot group only (Implementation Step 5)." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
