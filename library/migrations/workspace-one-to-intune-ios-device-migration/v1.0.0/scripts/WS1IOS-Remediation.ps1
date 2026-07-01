<#
.SYNOPSIS
    WS1IOS-Remediation.ps1 — safe remediation for stuck iOS/iPadOS migrations (default -WhatIf).

.DESCRIPTION
    PURPOSE
        Surfaces migrated devices that look stuck and offers a safe action: a device that has been
        re-assigned and re-enrolled but has not checked in recently (stale lastSyncDateTime), or is
        present but not yet compliant. With -Apply it triggers a managed-device Sync (syncDevice) to
        nudge the device to check in and re-evaluate. It does NOT wipe, retire, or re-assign devices —
        ABM re-assignment and any erase are performed deliberately in the consoles per the guide.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\WS1IOS-Remediation.ps1                                   # audit only (default -WhatIf)
        .\WS1IOS-Remediation.ps1 -Apply                            # sync all stale iOS devices
        .\WS1IOS-Remediation.ps1 -Apply -DeviceName "IPAD-PILOT-01"

    EXPECTED RESULTS
        Without -Apply: lists stale / non-compliant iOS devices and the action that would be taken.
        With -Apply: issues a Sync to the targeted device(s). Read-only otherwise.

.NOTES
    Defaults to read-only (-WhatIf); changes require -Apply. The repeatable Workspace ONE to Intune
    iOS/iPadOS migration. Never wipes or re-assigns — those are deliberate console actions.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Apply,
    [string]$DeviceName,
    [int]$StaleHours = 24
)

$ErrorActionPreference = 'Stop'
$scopes = if ($Apply) { 'DeviceManagementManagedDevices.PrivilegedOperations.All','DeviceManagementManagedDevices.Read.All' } else { 'DeviceManagementManagedDevices.Read.All' }
Connect-MgGraph -Scopes $scopes | Out-Null

$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=id,deviceName,serialNumber,complianceState,lastSyncDateTime"
$devices = @()
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devices += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$cutoff = (Get-Date).AddHours(-$StaleHours)
$stale  = $devices | Where-Object { -not $_.lastSyncDateTime -or [datetime]$_.lastSyncDateTime -lt $cutoff }
$nonCompliant = $devices | Where-Object { $_.complianceState -ne 'compliant' }

if ($DeviceName) {
    $stale = $stale | Where-Object { $_.deviceName -eq $DeviceName }
}

Write-Host "iOS devices total                  : $($devices.Count)"
Write-Host "Stale (> $StaleHours h since sync) : $($stale.Count)" -ForegroundColor $(if ($stale) { 'Yellow' } else { 'Green' })
Write-Host "Not compliant (review)             : $($nonCompliant.Count)" -ForegroundColor $(if ($nonCompliant) { 'Yellow' } else { 'Green' })
if ($stale)        { Write-Host ''; $stale | Format-Table deviceName, serialNumber, complianceState, lastSyncDateTime -AutoSize }
if ($nonCompliant) { Write-Host 'Not compliant:'; $nonCompliant | Format-Table deviceName, serialNumber, complianceState -AutoSize }

if (-not $Apply) {
    Write-Host ''
    Write-Host '[WhatIf] Audit only. Re-run with -Apply to issue a Sync to the stale device(s).'
    return
}

$targets = if ($DeviceName) { $stale } else { $stale }
if (-not $targets) { Write-Host 'No stale devices to sync.' -ForegroundColor Green; return }

foreach ($d in $targets) {
    if ($PSCmdlet.ShouldProcess($d.deviceName, 'Sync managed device (syncDevice)')) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($d.id)/syncDevice" | Out-Null
            Write-Host "Sync requested for '$($d.deviceName)'." -ForegroundColor Green
        } catch {
            Write-Host "Sync failed for '$($d.deviceName)': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
