<#
.SYNOPSIS
    IOSSDM-Remediation.ps1 — safe audit/fixes for the shared iOS iPhone fleet.

.DESCRIPTION
    PURPOSE
        Surfaces the common problems on a shared-device fleet and offers a safe, opt-in fix:
          - iOS devices that have a primary user (should be shared / no user)
          - iOS devices that are NOT supervised (kiosk lockdown will not hold)
        With -Apply, it can REMOVE the primary user from a named shared device (so it behaves as a
        true shared device). Read-only by default.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        # Audit only (no changes):
        .\IOSSDM-Remediation.ps1
        # Remove the primary user from a specific shared device (explicit opt-in):
        .\IOSSDM-Remediation.ps1 -Apply -DeviceName "SHARED-IPHONE-01"

    EXPECTED RESULTS
        Without -Apply: lists iOS devices with a primary user and/or not supervised.
        With -Apply: removes the primary user from the named device (makes it shared).

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Defaults to read-only; changes require -Apply.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Apply,
    [string]$DeviceName
)

$ErrorActionPreference = 'Stop'
$scopes = if ($Apply) { 'DeviceManagementManagedDevices.ReadWrite.All' } else { 'DeviceManagementManagedDevices.Read.All' }
Connect-MgGraph -Scopes $scopes | Out-Null

# Audit
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=id,deviceName,serialNumber,isSupervised,userId,userPrincipalName"
$devices = @()
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devices += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$withUser    = $devices | Where-Object { -not [string]::IsNullOrEmpty($_.userId) }
$unsupervised = $devices | Where-Object { -not $_.isSupervised }

Write-Host "iOS devices total            : $($devices.Count)"
Write-Host "With a primary user (review) : $($withUser.Count)" -ForegroundColor $(if ($withUser) { 'Yellow' } else { 'Green' })
Write-Host "Not supervised (kiosk risk)  : $($unsupervised.Count)" -ForegroundColor $(if ($unsupervised) { 'Yellow' } else { 'Green' })
if ($withUser)     { Write-Host ''; $withUser | Format-Table deviceName, serialNumber, userPrincipalName -AutoSize }
if ($unsupervised) { Write-Host 'Not supervised:'; $unsupervised | Format-Table deviceName, serialNumber -AutoSize }

if (-not $Apply) { Write-Host ''; Write-Host 'Audit only. Re-run with -Apply -DeviceName <name> to clear a primary user.'; return }

if (-not $DeviceName) { throw 'With -Apply you must specify -DeviceName.' }
$target = $devices | Where-Object { $_.deviceName -eq $DeviceName } | Select-Object -First 1
if (-not $target) { throw "Device '$DeviceName' not found among iOS devices." }

if ($PSCmdlet.ShouldProcess($DeviceName, 'Remove primary user (make shared)')) {
    # DELETE the users navigation reference => no primary user
    Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($target.id)/users/`$ref"
    Write-Host "Removed primary user from '$DeviceName' — it is now a shared device." -ForegroundColor Green
}
