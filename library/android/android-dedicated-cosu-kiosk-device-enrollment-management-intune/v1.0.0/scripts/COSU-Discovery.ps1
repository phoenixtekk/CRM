<#
.SYNOPSIS
    COSU-Discovery.ps1 — Android dedicated (COSU) readiness assessment: binding, profiles, apps, restrictions (read-only).
.DESCRIPTION
    PURPOSE
        Assesses whether the tenant is ready to enroll Android Enterprise DEDICATED (COSU) devices:
        the managed Google Play account-enterprise binding, the corporate-owned dedicated enrollment
        profile(s) with token expiry and enrolled-device count, managed Google Play apps available to
        assign, and any device-platform enrollment restriction that would block corporate-owned
        Android. Read-only against Microsoft Graph — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\COSU-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
        DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        The managed Google Play binding state, each dedicated enrollment profile with token expiry +
        enrolled count, a count of managed store apps, and a flag if a default enrollment restriction
        blocks corporate-owned Android. OEM console + zero-touch reseller portal are deferred to vendor docs.
.NOTES
    Android category — Android dedicated (COSU)/kiosk. Read-only. AMAPI/re-enrollment behavior: verify against current Microsoft guidance / your tenant.
#>
[CmdletBinding()]
param(
    [string]$ProfileNameFilter = 'Android Dedicated - COSU'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' -NoWelcome

Write-Host "`n=== Android dedicated (COSU) readiness ===" -ForegroundColor Cyan

# 1) Managed Google Play (account enterprise) binding
Write-Host "`n-- Managed Google Play binding --" -ForegroundColor Cyan
try {
    $ase = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings"
    if ($ase -and $ase.bindStatus) {
        Write-Host ("Binding status   : {0}" -f $ase.bindStatus) -ForegroundColor Green
        if ($ase.ownerUserPrincipalName) { Write-Host ("Bound by         : {0}" -f $ase.ownerUserPrincipalName) }
        if ($null -ne $ase.lastAppSyncDateTime) { Write-Host ("Last app sync    : {0}" -f $ase.lastAppSyncDateTime) }
    } else {
        Write-Host "Binding status   : NOT bound — establish the managed Google Play connection first (category G2)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Binding status   : unable to read (managed Google Play may not be bound — category G2)." -ForegroundColor Yellow
}

# 2) Corporate-owned dedicated enrollment profiles + token expiry + enrolled count
Write-Host "`n-- Dedicated enrollment profiles --" -ForegroundColor Cyan
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles").value
    $dedicated = $profiles | Where-Object { $_.enrollmentMode -eq 'corporateOwnedDedicatedDevice' -or $_.displayName -like "*$ProfileNameFilter*" }
    if (-not $dedicated -or $dedicated.Count -eq 0) {
        Write-Host "Profiles         : none found — create the dedicated profile (Implementation Step 2)." -ForegroundColor Yellow
    } else {
        foreach ($p in $dedicated) {
            Write-Host ("Profile          : {0}" -f $p.displayName) -ForegroundColor Green
            Write-Host ("  mode           : {0}" -f $p.enrollmentMode)
            Write-Host ("  enrolled count : {0}" -f $p.enrolledDeviceCount)
            if ($p.tokenExpirationDateTime) {
                $days = ([datetime]$p.tokenExpirationDateTime - (Get-Date)).Days
                $col = if ($days -lt 14) { 'Yellow' } else { 'Green' }
                Write-Host ("  token expiry   : {0}  ({1} day(s) left)" -f $p.tokenExpirationDateTime, $days) -ForegroundColor $col
            }
        }
    }
} catch {
    Write-Host "Profiles         : unable to read androidDeviceOwnerEnrollmentProfiles." -ForegroundColor Yellow
}

# 3) Managed Google Play apps available to assign
Write-Host "`n-- Managed Google Play apps --" -ForegroundColor Cyan
try {
    $apps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.androidManagedStoreApp')&`$select=id,displayName,packageId").value
    if (-not $apps -or $apps.Count -eq 0) {
        Write-Host "Managed store    : no managed Google Play apps yet — approve the kiosk app(s) (Implementation Step 4)." -ForegroundColor Yellow
    } else {
        Write-Host ("Managed store    : {0} app(s) available" -f $apps.Count) -ForegroundColor Green
        $apps | Select-Object -First 15 | ForEach-Object { Write-Host ("    {0}  [{1}]" -f $_.displayName, $_.packageId) }
        Write-Host "    (note the packageId values — the kiosk allow-list references them.)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "Managed store    : unable to read managed Google Play apps." -ForegroundColor Yellow
}

# 4) Enrollment restriction that could block corporate-owned Android
Write-Host "`n-- Enrollment restrictions (platform) --" -ForegroundColor Cyan
try {
    $cfgs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceEnrollmentConfigurations").value
    $plat = $cfgs | Where-Object { "$($_.'@odata.type')" -like '*PlatformRestriction*' -or "$($_.'@odata.type')" -like '*limitConfiguration*PlatformRestriction*' }
    $flagged = $false
    foreach ($c in $cfgs) {
        $t = "$($c.'@odata.type')"
        if ($t -like '*PlatformRestrictionsConfiguration*' -or $t -like '*PlatformRestriction*') {
            $ao = $c.androidForWorkRestriction
            if ($ao -and ($ao.platformBlocked -eq $true)) {
                Write-Host ("  BLOCK          : '{0}' blocks Android Enterprise enrollment." -f $c.displayName) -ForegroundColor Yellow
                $flagged = $true
            }
        }
    }
    if (-not $flagged) { Write-Host "  OK             : no restriction seen blocking Android Enterprise (verify scoping in the portal)." -ForegroundColor Green }
} catch {
    Write-Host "  (unable to read deviceEnrollmentConfigurations — verify enrollment restrictions in the portal.)" -ForegroundColor DarkGray
}

Write-Host "`nOEM (Zebra/Samsung) consoles and the zero-touch reseller portal are deferred to vendor documentation." -ForegroundColor DarkGray
Write-Host "AMAPI transition / whether a change forces re-enrollment: verify against current Microsoft guidance / your tenant." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
