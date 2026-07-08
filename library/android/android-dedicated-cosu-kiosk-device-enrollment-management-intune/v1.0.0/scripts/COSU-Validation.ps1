<#
.SYNOPSIS
    COSU-Validation.ps1 — kiosk allow-list vs assigned apps ("only allowed apps") validation report (read-only).
.DESCRIPTION
    PURPOSE
        Validates that the kiosk is coherent: it reads the kiosk device-restrictions profile's
        allow-list (kioskModeApps) and the managed Google Play apps that are assigned (Required) to the
        dedicated DEVICE group, then reports mismatches — apps named in the kiosk but NOT assigned
        (they will not appear on the device) and apps assigned but NOT in the kiosk (exposed/uncurated).
        For multi-app, checks that the Managed Home Screen launcher is assigned. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\COSU-Validation.ps1
        ... -KioskProfileName 'Android Dedicated - Kiosk - Pilot' -DeviceGroup 'Android Dedicated - Devices - Pilot'
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementConfiguration.Read.All, DeviceManagementApps.Read.All, Group.Read.All.
    EXPECTED RESULTS
        The kiosk allow-list, the apps assigned Required to the device group, and a PASS/FAIL on whether
        they match (only allowed apps). Any mismatch is listed with the fix. Read-only.
.NOTES
    Android category — Android dedicated (COSU)/kiosk. Read-only. Kiosk schema evolves — verify property names against current Microsoft guidance.
#>
[CmdletBinding()]
param(
    [string]$KioskProfileName = 'Android Dedicated - Kiosk - Pilot',
    [string]$DeviceGroup      = 'Android Dedicated - Devices - Pilot',
    [string]$ManagedHomeScreenPackage = 'com.microsoft.launcher.enterprise'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Kiosk 'only allowed apps' validation ===" -ForegroundColor Cyan

# 1) Resolve the device group id
$ge = $DeviceGroup.Replace("'","''")
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ge'").value | Select-Object -First 1
if (-not $grp) { Write-Host ("Device group     : MISSING ('{0}') — create it (COSU-Set-ScopeTargeting.ps1)." -f $DeviceGroup) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
Write-Host ("Device group     : {0} (id {1})" -f $DeviceGroup, $grp.id) -ForegroundColor Green

# 2) Kiosk allow-list from the device-restrictions profile
$kiosk = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=displayName eq '$($KioskProfileName.Replace("'","''"))'").value | Select-Object -First 1
if (-not $kiosk) { Write-Host ("Kiosk profile    : MISSING ('{0}') — create it (COSU-Set-Configuration.ps1)." -f $KioskProfileName) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
$full = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($kiosk.id)"
$allowed = @()
if ($full.kioskModeApps) { $allowed = @($full.kioskModeApps | ForEach-Object { $_.packageId }) }
$mode = if ($full.kioskModeManagedHomeScreenEnabled) { 'Multi-app (Managed Home Screen)' } else { 'Single-app' }
Write-Host ("Kiosk profile    : {0}  [{1}]" -f $KioskProfileName, $mode) -ForegroundColor Green
Write-Host ("Kiosk allow-list : {0}" -f ($(if ($allowed.Count) { $allowed -join ', ' } else { '(none)' })))

# 3) Managed Google Play apps assigned (Required) to the device group
$assignedPkgs = @()
try {
    $apps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.androidManagedStoreApp')&`$select=id,displayName,packageId").value
    foreach ($a in $apps) {
        $asg = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps/$($a.id)/assignments").value
        foreach ($x in $asg) {
            if ("$($x.intent)" -eq 'required' -and "$($x.target.groupId)" -eq $grp.id) { $assignedPkgs += $a.packageId }
        }
    }
    $assignedPkgs = $assignedPkgs | Sort-Object -Unique
} catch { Write-Host "  (unable to read app assignments)" -ForegroundColor Yellow }
Write-Host ("Assigned (Req.)  : {0}" -f ($(if ($assignedPkgs.Count) { $assignedPkgs -join ', ' } else { '(none)' })))

# 4) Cross-check
Write-Host "`n-- Cross-check --" -ForegroundColor Cyan
$inKioskNotAssigned = $allowed | Where-Object { $_ -and ($assignedPkgs -notcontains $_) -and ($_ -ne $ManagedHomeScreenPackage) }
$assignedNotInKiosk = $assignedPkgs | Where-Object { $_ -and ($allowed -notcontains $_) -and ($_ -ne $ManagedHomeScreenPackage) }

$fail = $false
if ($inKioskNotAssigned) {
    $fail = $true
    Write-Host "  FAIL : in kiosk but NOT assigned to the device group (will NOT appear on device):" -ForegroundColor Yellow
    $inKioskNotAssigned | ForEach-Object { Write-Host ("        - {0}   -> assign it Required to '{1}'" -f $_, $DeviceGroup) }
}
if ($assignedNotInKiosk) {
    Write-Host "  WARN : assigned to the group but NOT in the kiosk allow-list (installed, not curated):" -ForegroundColor Yellow
    $assignedNotInKiosk | ForEach-Object { Write-Host ("        - {0}   -> add to kiosk or remove the assignment" -f $_) }
}

# Multi-app requires Managed Home Screen assigned
if ($full.kioskModeManagedHomeScreenEnabled) {
    if ($assignedPkgs -contains $ManagedHomeScreenPackage) {
        Write-Host ("  OK   : Managed Home Screen ({0}) is assigned to the group." -f $ManagedHomeScreenPackage) -ForegroundColor Green
    } else {
        $fail = $true
        Write-Host ("  FAIL : multi-app kiosk but Managed Home Screen ({0}) is NOT assigned Required to the group." -f $ManagedHomeScreenPackage) -ForegroundColor Yellow
    }
}

if (-not $fail -and -not $assignedNotInKiosk) { Write-Host "  PASS : kiosk allow-list matches assigned apps — only allowed apps are exposed." -ForegroundColor Green }
elseif (-not $fail) { Write-Host "  PASS (with warnings): every kiosk app is assigned; review the WARN items above." -ForegroundColor Green }

Write-Host "`nDetected per-device inventory can be reviewed in Intune (Devices > detectedApps); this report validates policy intent." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
