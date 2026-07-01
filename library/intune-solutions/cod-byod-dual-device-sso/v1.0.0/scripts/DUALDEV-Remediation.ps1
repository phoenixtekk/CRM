<#
.SYNOPSIS
    DUALDEV-Remediation.ps1 — safe fixes for ownership and policy targeting.

.DESCRIPTION
    PURPOSE
        The common fixes that unblock the COD/BYOD model: correct a device's ownership
        (Corporate/Personal) so the right filtered policies apply, and audit for devices whose
        ownership is Unknown. Read-only by default.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        # Audit only (no changes):
        .\DUALDEV-Remediation.ps1
        # Set a device's ownership (explicit opt-in):
        .\DUALDEV-Remediation.ps1 -Apply -DeviceName "Jane-Surface" -Ownership company

    EXPECTED RESULTS
        Without -Apply: a list of devices with Unknown ownership (which get no filtered policy).
        With -Apply: the named device's ownership is set.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Defaults to read-only; changes require -Apply.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Apply,
    [string]$DeviceName,
    [string]$Serial,
    [ValidateSet('company','personal')] [string]$Ownership
)

$ErrorActionPreference = 'Stop'
$scopes = if ($Apply) { 'DeviceManagementManagedDevices.ReadWrite.All' } else { 'DeviceManagementManagedDevices.Read.All' }
Connect-MgGraph -Scopes $scopes | Out-Null

# Audit: devices with Unknown ownership
Write-Host '== Ownership audit ==' -ForegroundColor Cyan
$resp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=managedDeviceOwnerType eq 'unknown'"
$unknown = @($resp.value)
if ($unknown.Count -eq 0) { Write-Host 'No devices with Unknown ownership.' -ForegroundColor Green }
else {
    Write-Host "$($unknown.Count) device(s) have Unknown ownership (they receive NO ownership-filtered policy):" -ForegroundColor Yellow
    $unknown | Select-Object deviceName, operatingSystem, userPrincipalName | Format-Table -AutoSize
}

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Read-only mode. Re-run with -Apply -DeviceName/-Serial <x> -Ownership company|personal to set ownership.' -ForegroundColor Yellow
    return
}

if (-not $Ownership -or (-not $DeviceName -and -not $Serial)) {
    throw 'With -Apply, provide -Ownership and one of -DeviceName / -Serial.'
}

$filter = if ($Serial) { "serialNumber eq '$Serial'" } else { "deviceName eq '$DeviceName'" }
$dev = @((Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=$filter").value)[0]
if (-not $dev) { throw "No device found for $filter." }

if ($PSCmdlet.ShouldProcess($dev.deviceName, "Set ownership = $Ownership")) {
    $body = @{ managedDeviceOwnerType = $Ownership } | ConvertTo-Json
    Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($dev.id)" -Body $body -ContentType 'application/json' | Out-Null
    Write-Host "Set $($dev.deviceName) ownership to '$Ownership'. Filtered policies apply on next sync." -ForegroundColor Green
}
