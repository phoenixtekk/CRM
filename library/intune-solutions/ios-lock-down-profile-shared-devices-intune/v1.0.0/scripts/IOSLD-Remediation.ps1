<#
.SYNOPSIS
    IOSLD-Remediation.ps1 — safe drift fixes for the shared + corporate iPhone fleet (-WhatIf default).

.DESCRIPTION
    PURPOSE
        Surfaces and (opt-in) fixes the common drift on the dual-model fleet:
          - A SHARED phone that has a primary user (should be no-user)  -> can clear the primary user.
          - A device that needs a fresh policy check-in                  -> can request a Sync.
        The script defaults to -WhatIf: it shows exactly what it WOULD do and changes nothing until you
        re-run with -WhatIf:$false (or -Confirm).

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        # Preview (no changes — default):
        .\IOSLD-Remediation.ps1
        # Clear the primary user from a shared phone (make it truly shared):
        .\IOSLD-Remediation.ps1 -WhatIf:$false -ClearPrimaryUser -DeviceName "SHARED-IPHONE-01"
        # Request a device sync (re-evaluate policy):
        .\IOSLD-Remediation.ps1 -WhatIf:$false -Sync -DeviceName "IPHONE-07"

    EXPECTED RESULTS
        Default: an audit of shared phones that have a primary user, plus unsupervised shared phones.
        With an action switch and -WhatIf:$false: performs the named, scoped fix on the named device.

.NOTES
    White-label — Intune Solutions. -WhatIf is ON by default; actions are explicit.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [string]$DeviceName,
    [switch]$ClearPrimaryUser,
    [switch]$Sync
)

# Default to a dry run unless the caller turns it off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
$needWrite = $ClearPrimaryUser -or $Sync
$scopes = if ($needWrite) { 'DeviceManagementManagedDevices.ReadWrite.All' } else { 'DeviceManagementManagedDevices.Read.All' }
Connect-MgGraph -Scopes $scopes | Out-Null

# Audit: shared phones (no group lookup here) — flag iOS devices with a primary user and unsupervised.
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=id,deviceName,serialNumber,isSupervised,userId,userPrincipalName"
$devices = @()
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devices += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$withUser     = $devices | Where-Object { -not [string]::IsNullOrEmpty($_.userId) }
$unsupervised = $devices | Where-Object { -not $_.isSupervised }

Write-Host "iOS devices total                 : $($devices.Count)"
Write-Host "With a primary user (review)      : $($withUser.Count)" -ForegroundColor $(if ($withUser) { 'Yellow' } else { 'Green' })
Write-Host "Not supervised (lock-down risk)   : $($unsupervised.Count)" -ForegroundColor $(if ($unsupervised) { 'Yellow' } else { 'Green' })
if ($withUser)     { Write-Host ''; $withUser | Format-Table deviceName, serialNumber, userPrincipalName -AutoSize }
if ($unsupervised) { Write-Host 'Not supervised:'; $unsupervised | Format-Table deviceName, serialNumber -AutoSize }

if (-not $needWrite) {
    Write-Host ''
    Write-Host 'Audit only. Re-run with an action switch (-ClearPrimaryUser / -Sync), -DeviceName, and -WhatIf:$false to apply.'
    Disconnect-MgGraph | Out-Null
    return
}

if (-not $DeviceName) { throw 'An action switch requires -DeviceName.' }
$target = $devices | Where-Object { $_.deviceName -eq $DeviceName } | Select-Object -First 1
if (-not $target) { throw "Device '$DeviceName' not found among iOS devices." }

if ($ClearPrimaryUser) {
    if ($PSCmdlet.ShouldProcess($DeviceName, 'Remove primary user (make it a shared device)')) {
        Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($target.id)/users/`$ref"
        Write-Host "Removed primary user from '$DeviceName' — it is now a shared device." -ForegroundColor Green
    }
}

if ($Sync) {
    if ($PSCmdlet.ShouldProcess($DeviceName, 'Request device sync (re-evaluate policy)')) {
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($target.id)/syncDevice"
        Write-Host "Sync requested for '$DeviceName' — it will re-check policy at next check-in." -ForegroundColor Green
    }
}

Disconnect-MgGraph | Out-Null
