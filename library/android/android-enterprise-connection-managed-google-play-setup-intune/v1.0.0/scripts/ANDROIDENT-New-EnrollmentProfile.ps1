<#
.SYNOPSIS
    ANDROIDENT-New-EnrollmentProfile.ps1 — create a corporate-owned Android Enterprise enrollment profile (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates one corporate-owned Android Enterprise enrollment profile (androidDeviceOwnerEnrollmentProfile)
        for the chosen model: FullyManaged, CorporateOwnedWorkProfile, or Dedicated (COSU). The profile
        yields the enrollment token / QR code used at device first-run. BYOD personally-owned work profile
        has NO profile object (it is restriction-driven — use ANDROIDENT-Set-EnrollmentRestrictions.ps1).
        Default -WhatIf; pass -Apply to create. No credentials/secrets in code.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\ANDROIDENT-New-EnrollmentProfile.ps1 -Model FullyManaged
        Apply:              ... -Model FullyManaged -Apply
        Other models:       ... -Model CorporateOwnedWorkProfile -Apply   |   ... -Model Dedicated -Apply
        Requires the Microsoft Graph PowerShell SDK and delegated scope: DeviceManagementServiceConfig.ReadWrite.All.
    EXPECTED RESULTS
        A corporate-owned enrollment profile named per the solution convention (Android FM/COPE/COSU -
        Enroll - Pilot) exists with the requested enrollment mode; retrieve its QR/token from Intune to
        enrol a reset company device. AMAPI note: enrollment modes/availability (esp. corporate-owned work
        profile) are evolving — verify against current Microsoft guidance / your tenant.
.NOTES
    Android category — Android Enterprise connection & managed Google Play setup. Default -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('FullyManaged','CorporateOwnedWorkProfile','Dedicated')]
    [string]$Model,
    [string]$DisplayName,
    [int]$TokenValidDays = 90,
    [switch]$Apply
)

$WhatIfPreference = -not $Apply

# Map the friendly model to the Graph enrollmentMode value and default profile name.
$map = @{
    'FullyManaged'               = @{ mode = 'corporateOwnedFullyManaged';   name = 'Android FM - Enroll - Pilot' }
    'CorporateOwnedWorkProfile'  = @{ mode = 'corporateOwnedWorkProfile';    name = 'Android COPE - Enroll - Pilot' }
    'Dedicated'                  = @{ mode = 'corporateOwnedDedicatedDevice';name = 'Android COSU - Enroll - Pilot' }
}
$sel  = $map[$Model]
$name = if ($DisplayName) { $DisplayName } else { $sel.name }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.ReadWrite.All' -NoWelcome

Write-Host "=== Create corporate-owned Android Enterprise enrollment profile ===" -ForegroundColor Cyan
if (-not $Apply) { Write-Host "(preview mode — re-run with -Apply to create)" -ForegroundColor Yellow }
Write-Host ("Model            : {0}  (enrollmentMode = {1})" -f $Model, $sel.mode)
Write-Host ("Profile name     : {0}" -f $name)
Write-Host ("Token validity   : {0} day(s)" -f $TokenValidDays)

# Idempotency: skip if a profile with this name already exists
try {
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles?`$top=100").value |
                Where-Object { $_.displayName -eq $name } | Select-Object -First 1
    if ($existing) {
        Write-Host ("  OK   : a profile named '{0}' already exists (id {1}) — nothing to do." -f $name, $existing.id) -ForegroundColor Green
        Disconnect-MgGraph | Out-Null
        return
    }
} catch {
    Write-Host "  NOTE : could not enumerate existing profiles — verify tenant/AMAPI availability." -ForegroundColor DarkGray
}

$body = @{
    '@odata.type'                = '#microsoft.graph.androidDeviceOwnerEnrollmentProfile'
    displayName                  = $name
    description                  = "Created by ANDROIDENT solution — $Model corporate-owned enrollment."
    enrollmentMode              = $sel.mode
    tokenValidityInSeconds       = [int]($TokenValidDays * 86400)
} | ConvertTo-Json -Depth 5

if ($PSCmdlet.ShouldProcess($name, "Create $Model enrollment profile")) {
    try {
        $new = Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles" -Body $body -ContentType 'application/json'
        Write-Host ("  DONE : created '{0}' (id {1})." -f $name, $new.id) -ForegroundColor Green
        Write-Host  "  Retrieve the QR code / token from Intune > Devices > Android > Corporate-owned devices to enrol a reset device." -ForegroundColor Green
    } catch {
        Write-Host ("  FAIL : could not create profile: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host  "         The enrollmentMode value/availability (esp. corporate-owned work profile) is evolving with AMAPI —" -ForegroundColor Yellow
        Write-Host  "         verify the current mode for your tenant against Microsoft's documentation, or create it in the portal." -ForegroundColor Yellow
    }
} else {
    Write-Host "  WOULD: create the enrollment profile with the values above." -ForegroundColor Cyan
}

Disconnect-MgGraph | Out-Null
