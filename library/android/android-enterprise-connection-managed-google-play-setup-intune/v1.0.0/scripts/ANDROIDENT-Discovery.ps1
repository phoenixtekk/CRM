<#
.SYNOPSIS
    ANDROIDENT-Discovery.ps1 — assess the managed Google Play connection + Android enrollment config (read-only).
.DESCRIPTION
    PURPOSE
        Reports the Intune managed Google Play connection (Android Enterprise account-enterprise binding:
        bind status, owner account, last app-catalog sync), the Android enrollment platform restrictions
        (which Android Enterprise models are allowed/blocked), and any corporate-owned Android Enterprise
        enrollment profiles (fully managed / corporate-owned work profile / dedicated) with token expiry —
        so you can assess the foundation before configuring anything. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDENT-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        PASS = connection bind status 'bound' with a recent SUCCESS app sync; the Android platform
        restriction present and matching your plan; the corporate-owned enrollment profiles present.
        Missing/blocked items are called out with the Implementation step that creates them. The Google-
        hosted managed Google Play sign-in is deferred to Google's documentation.
.NOTES
    Android category — Android Enterprise connection & managed Google Play setup. Read-only. Google console deferred.
    AMAPI note: enrollment/restriction surfaces are evolving — verify against current Microsoft guidance / your tenant.
#>
[CmdletBinding()]
param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

Write-Host "`n=== Android Enterprise / managed Google Play readiness ===" -ForegroundColor Cyan

# 1) Managed Google Play connection (account enterprise binding)
Write-Host "`n-- Managed Google Play connection --" -ForegroundColor Cyan
try {
    $mgp = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings"
    if ($mgp -and $mgp.bindStatus) {
        $col = if ($mgp.bindStatus -eq 'bound') { 'Green' } else { 'Yellow' }
        Write-Host ("Bind status      : {0}" -f $mgp.bindStatus) -ForegroundColor $col
        Write-Host ("Owner account    : {0}" -f $mgp.ownerUserPrincipalName)
        Write-Host ("Last app sync    : {0}  status={1}" -f $mgp.lastAppSyncDateTime, $mgp.lastAppSyncStatus)
        if ($mgp.lastAppSyncStatus -and $mgp.lastAppSyncStatus -ne 'success') {
            Write-Host "App sync WARNING : last sync did not succeed — check endpoint reachability / owner account (Req 2.6)." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Connection       : NOT bound — connect managed Google Play (Implementation Step 3)." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Connection       : NOT configured — connect managed Google Play (Implementation Step 3)." -ForegroundColor Yellow
}

# 2) Android enrollment platform restrictions
Write-Host "`n-- Android enrollment platform restrictions --" -ForegroundColor Cyan
try {
    $cfgs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceEnrollmentConfigurations?`$top=100").value
    $restr = $cfgs | Where-Object { $_.'@odata.type' -like '*deviceEnrollmentPlatformRestrictionsConfiguration*' -or $_.'@odata.type' -like '*deviceEnrollmentPlatformRestriction*' }
    if (-not $restr) {
        Write-Host "Platform restr.  : none found — configure Android restrictions (Implementation Step 5)." -ForegroundColor Yellow
    } else {
        foreach ($r in $restr) {
            Write-Host ("Restriction      : {0}  (priority {1})" -f $r.displayName, $r.priority)
            $aw = $r.androidForWorkRestriction
            $ad = $r.androidRestriction
            if ($aw) {
                $awBlk = if ($aw.platformBlocked) { 'BLOCKED' } else { 'allowed' }
                $awPer = if ($aw.personalDeviceEnrollmentBlocked) { 'personal BLOCKED' } else { 'personal allowed' }
                Write-Host ("   Android Enterprise (work profile/AE) : {0}, {1}" -f $awBlk, $awPer)
            }
            if ($ad) {
                $adBlk = if ($ad.platformBlocked) { 'BLOCKED' } else { 'allowed' }
                Write-Host ("   Android device administrator (legacy): {0}  (best practice: BLOCKED)" -f $adBlk)
            }
        }
    }
} catch {
    Write-Host "Platform restr.  : (unable to read deviceEnrollmentConfigurations)" -ForegroundColor Yellow
}

# 3) Corporate-owned Android Enterprise enrollment profiles
Write-Host "`n-- Corporate-owned enrollment profiles (FM / COPE / dedicated) --" -ForegroundColor Cyan
try {
    $profs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles?`$top=100").value
    if (-not $profs -or $profs.Count -eq 0) {
        Write-Host "Enroll profiles  : none — create per-model profiles (Implementation Steps 6-8)." -ForegroundColor Yellow
    } else {
        foreach ($p in $profs) {
            Write-Host ("Profile          : {0}  mode={1}  tokenExpiry={2}" -f $p.displayName, $p.enrollmentMode, $p.tokenExpirationDateTime)
            if ($p.tokenExpirationDateTime) {
                $d = ([datetime]$p.tokenExpirationDateTime - (Get-Date)).Days
                if ($d -lt 30) { Write-Host ("   WARNING       : enrollment token expires in {0} day(s) — rotate." -f $d) -ForegroundColor Yellow }
            }
        }
    }
} catch {
    Write-Host "Enroll profiles  : (unable to read androidDeviceOwnerEnrollmentProfiles — verify tenant/AMAPI availability)." -ForegroundColor Yellow
}

Write-Host "`nNote: BYOD personally-owned work profile has NO enrollment-profile object — it is enabled by the" -ForegroundColor DarkGray
Write-Host "Android platform restriction (allow personally-owned work profile) and users enrol from Company Portal." -ForegroundColor DarkGray
Write-Host "AMAPI transition / enrollment behavior is evolving — verify against current Microsoft guidance / your tenant." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
