<#
.SYNOPSIS
    CPAVPN-Validation.ps1 — confirm the per-app VPN profile + app association state for a device (read-only).
.DESCRIPTION
    PURPOSE
        For one named managed mobile device, confirms the Cisco per-app VPN profile
        ('Cisco Per-App VPN - iOS' / 'Cisco Per-App VPN - Android') is assigned/applied and reports
        the app-to-VPN association state — which managed apps are in scope to tunnel. Read-only, per
        device. Cisco head-end session/posture state is confirmed on the Cisco side, not here.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPAVPN-Validation.ps1 -DeviceName your-pilot-device

        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All,
        DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A pass/fail per device: profile present = PASS, profile missing = FAIL, plus the list of
        managed apps associated with the per-app VPN profile. No changes are made (read-only).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco internals deferred to vendor docs.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)] [string] $DeviceName,
    [string] $ProfileName = 'Cisco Per-App VPN'
)

Write-Host "`n=== CPAVPN Validation — device '$DeviceName' (read-only) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' -NoWelcome

# --- Resolve the managed device ---
$device = $null
try {
    $f = "deviceName eq '$($DeviceName.Replace("'","''"))'"
    $device = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=$f").value | Select-Object -First 1
} catch { }
if (-not $device) {
    Write-Host "  FAIL  Device '$DeviceName' not found in Intune managed devices." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null; return
}
$plat = $device.operatingSystem
Write-Host ("  Device: {0}  OS: {1}  Compliance: {2}" -f $device.deviceName, $plat, $device.complianceState)

# --- Per-app VPN profile presence (via device config states) ---
Write-Host "`n[Per-app VPN profile state]" -ForegroundColor Cyan
$profileFound = $false
try {
    $states = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/managedDevices/$($device.id)/deviceConfigurationStates").value
    $vpnStates = $states | Where-Object { $_.displayName -match $ProfileName }
    if ($vpnStates) {
        foreach ($s in $vpnStates) {
            $profileFound = $true
            $col = if ($s.state -eq 'compliant') { 'Green' } else { 'Yellow' }
            Write-Host ("  {0}  state: {1}" -f $s.displayName, $s.state) -ForegroundColor $col
        }
    }
} catch {
    Write-Host ("  Could not read device configuration states: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}
if ($profileFound) { Write-Host "  PASS  Per-app VPN profile is applied to this device." -ForegroundColor Green }
else               { Write-Host "  FAIL  No '$ProfileName' profile applied — check assignment to 'PILOT - Per-App VPN Users'." -ForegroundColor Red }

# --- App-to-VPN association state (which apps carry the association) ---
Write-Host "`n[App association state]" -ForegroundColor Cyan
try {
    $vpnProfiles = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/deviceConfigurations?`$top=200").value |
        Where-Object { $_.displayName -match $ProfileName }
    foreach ($p in $vpnProfiles) {
        $json = $p | ConvertTo-Json -Depth 8
        # iOS per-app: onlyAssociatedAppsCanUseConnection / safariDomains; Android: allowed/excluded apps by package
        $apps = @()
        if ($json -match '"identifier"\s*:\s*"([^"]+)"') {
            $apps = [regex]::Matches($json, '"identifier"\s*:\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
        }
        if ($json -match '"packageId"\s*:\s*"([^"]+)"') {
            $apps += [regex]::Matches($json, '"packageId"\s*:\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
        }
        $apps = $apps | Sort-Object -Unique
        Write-Host ("  {0}:" -f $p.displayName) -ForegroundColor Cyan
        if ($apps) {
            $apps | ForEach-Object { Write-Host ("     associated app: {0}" -f $_) -ForegroundColor Green }
        } else {
            Write-Host "     WARN  no explicit app association found — confirm per-app scope (iOS association / Android allow-list)." -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host ("  Could not read association state: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`n[Cisco head-end session — DEFERRED]" -ForegroundColor DarkYellow
Write-Host "  Confirm the live tunnel/session and posture on the Cisco head-end per Cisco docs." -ForegroundColor DarkYellow

Write-Host "`nValidation complete for '$DeviceName'." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
