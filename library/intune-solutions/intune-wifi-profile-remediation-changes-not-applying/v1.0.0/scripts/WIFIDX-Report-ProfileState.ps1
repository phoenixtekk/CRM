<#
.SYNOPSIS
    WIFIDX-Report-ProfileState.ps1 — reconcile REPORTED (Succeeded) vs APPLIED state per device for a Wi-Fi profile.
.DESCRIPTION
    PURPOSE
        For a chosen Wi-Fi configuration profile, pulls the per-device REPORTED status from Intune
        (Succeeded / Error / Not applicable / Pending) so you can line it up against the APPLIED state
        you read on the device with WIFIDX-Validate-Device.ps1. The report highlights devices that
        Intune calls Succeeded — those are exactly the ones to spot-check on the device for the Branch A
        stale-network / Branch E delivery-vs-application gap. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIFIDX-Report-ProfileState.ps1 -NameLike CORP-WIFI
        powershell -ExecutionPolicy Bypass -File .\WIFIDX-Report-ProfileState.ps1 -Environment USGov -NameLike "WIFIDX - WiFi - Corrected"
        Requires scopes DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        For each matching profile: a per-device table of reported status, and a summary count by status.
        A note lists the Succeeded devices to verify on-device (reported != applied is not visible to
        Intune — you must read the device). "No matching profiles" if the name filter matches nothing.
.NOTES
    Intune Solutions — read-only. Cloud-aware (Global | USGov | USGovDoD). Reported vs applied reconciliation.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$Environment = 'Global',
    [string]$NameLike
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

# Gather Wi-Fi profiles (legacy templates + settings-catalog), filter by name if requested.
$odataWifi = "isof('microsoft.graph.windowsWifiConfiguration') or isof('microsoft.graph.windowsWifiEnterpriseEAPConfiguration') or isof('microsoft.graph.iosWiFiConfiguration') or isof('microsoft.graph.iosEnterpriseWiFiConfiguration') or isof('microsoft.graph.androidWorkProfileWiFiConfiguration') or isof('microsoft.graph.androidDeviceOwnerWiFiConfiguration')"
try { $legacy = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=$odataWifi").value } catch { $legacy = @() }

$targets = @()
foreach ($c in $legacy) {
    if ($NameLike -and ($c.displayName -notmatch [regex]::Escape($NameLike))) { continue }
    $targets += [pscustomobject]@{ Id = $c.id; Name = $c.displayName; Kind = 'deviceConfiguration' }
}

if ($targets.Count -eq 0) { Write-Host "No matching Wi-Fi profiles found — check -NameLike or environment." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

foreach ($t in $targets) {
    Write-Host ("`n=== Reported state: {0} ===" -f $t.Name) -ForegroundColor Cyan
    try {
        $statuses = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($t.Id)/deviceStatuses").value
    } catch {
        Write-Host "  Could not read device statuses: $($_.Exception.Message)" -ForegroundColor Yellow
        continue
    }
    if (-not $statuses -or $statuses.Count -eq 0) { Write-Host "  (no device status yet — not delivered/reported)" -ForegroundColor Yellow; continue }

    $statuses | Sort-Object status | ForEach-Object {
        $color = switch ($_.status) { 'compliant' {'Green'} 'error' {'Red'} 'notApplicable' {'Yellow'} default {'Gray'} }
        Write-Host ("  {0,-35} {1}" -f $_.deviceDisplayName, $_.status) -ForegroundColor $color
    }

    $succeeded = $statuses | Where-Object { $_.status -eq 'compliant' }
    Write-Host ("`n  Summary — total: {0}  Succeeded: {1}  Error: {2}  NotApplicable: {3}" -f `
        $statuses.Count, ($succeeded.Count), (($statuses | Where-Object status -eq 'error').Count), (($statuses | Where-Object status -eq 'notApplicable').Count)) -ForegroundColor Cyan
    if ($succeeded) {
        Write-Host "  ACTION: 'Succeeded' = DELIVERED, not proven applied. Spot-check these on-device with" -ForegroundColor Yellow
        Write-Host "          WIFIDX-Validate-Device.ps1 (a previously-joined device is the real test — Branch A/E)." -ForegroundColor Yellow
    }
}

Disconnect-MgGraph | Out-Null
