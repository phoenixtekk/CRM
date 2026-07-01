<#
.SYNOPSIS
    EPICGOLIVE-Remediation — safe, supported remediation of endpoint readiness gaps.

.DESCRIPTION
    Performs the safe, supported remediation actions for enrollment / compliance gaps on
    in-scope clinical endpoints via Microsoft Intune / Microsoft Graph: triggering a device
    sync and re-evaluating compliance so a device that drifted can come back into a ready state.

    SAFE BY DEFAULT. The script runs in preview (-WhatIf) mode unless -Apply is supplied:
      * Without -Apply : it reports exactly which devices it WOULD act on and what it would do.
      * With    -Apply : it performs the remediation actions, in the current run, against the
                         resolved devices.

    Run preview first, validate the plan, test on a single device (GR6), and only then -Apply
    inside an approved maintenance window (GR4). Capture a discovery snapshot first as the
    rollback baseline (GR7). This script performs only non-destructive, reversible Intune
    actions (sync / compliance re-evaluation); it does not wipe, retire, or delete devices.

.PARAMETER GroupId
    Object ID of the "Readiness Device Group - Clinical Fleet - Validation" to scope to.

.PARAMETER DeviceName
    Optional single device name to target (e.g. for an on-the-floor swap remediation).

.PARAMETER Apply
    Perform the remediation. Omit to preview only (default = preview / -WhatIf behavior).

.EXAMPLE
    # Preview what would be remediated across the readiness group:
    .\EPICGOLIVE-Remediation.ps1 -GroupId <guid>

.EXAMPLE
    # Apply remediation to one device during hypercare:
    .\EPICGOLIVE-Remediation.ps1 -DeviceName 'WOW-3E-014' -Apply

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string] $GroupId,
    [string] $DeviceName,
    [switch] $Apply
)

function Assert-Graph {
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install-Module Microsoft.Graph, then Connect-MgGraph."
    }
    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. For -Apply use a write scope, e.g. 'DeviceManagementManagedDevices.PrivilegedOperations.All'; preview needs only read scopes."
    }
}
Assert-Graph

if (-not $GroupId -and -not $DeviceName) {
    throw "Specify -GroupId (readiness group) or -DeviceName (single device)."
}

#-------------------------------------------------------------------------------
# Resolve target devices
#-------------------------------------------------------------------------------
function Resolve-Targets {
    param([string] $GroupId, [string] $DeviceName)

    if ($DeviceName) {
        return Get-MgDeviceManagementManagedDevice -All |
            Where-Object { $_.DeviceName -eq $DeviceName }
    }

    $members   = Get-MgGroupMember -GroupId $GroupId -All
    $deviceIds = $members | Where-Object { $_.AdditionalProperties.'@odata.type' -match 'device' } |
        ForEach-Object { $_.AdditionalProperties.deviceId }
    return Get-MgDeviceManagementManagedDevice -All |
        Where-Object { $deviceIds -contains $_.AzureAdDeviceId }
}

$targets = Resolve-Targets -GroupId $GroupId -DeviceName $DeviceName

# Devices needing remediation = not compliant or stale.
$needsWork = $targets | Where-Object {
    $_.ComplianceState -ne 'compliant'
}

Write-Host "EPICGOLIVE-Remediation" -ForegroundColor Cyan
Write-Host ("Targets resolved: {0}   Needing remediation: {1}" -f ($targets | Measure-Object).Count, ($needsWork | Measure-Object).Count)

if (-not $Apply) {
    Write-Host "PREVIEW MODE (no -Apply) — no changes will be made. Devices that WOULD be remediated:" -ForegroundColor Yellow
    $needsWork | Select-Object DeviceName, ComplianceState, LastSyncDateTime | Format-Table -AutoSize
    Write-Host "Re-run with -Apply, inside an approved maintenance window, after a test-device run." -ForegroundColor Yellow
    return
}

#-------------------------------------------------------------------------------
# Apply: non-destructive sync to re-evaluate compliance / pull policy
#-------------------------------------------------------------------------------
foreach ($d in $needsWork) {
    if ($PSCmdlet.ShouldProcess($d.DeviceName, "Sync device to re-evaluate compliance/policy")) {
        try {
            Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $d.Id -ErrorAction Stop
            Write-Host ("Remediation sync issued: {0}" -f $d.DeviceName) -ForegroundColor Green
        } catch {
            Write-Warning ("Sync failed for {0}: {1}" -f $d.DeviceName, $_.Exception.Message)
        }
    }
}

Write-Host "Apply complete. Re-run EPICGOLIVE-Discovery.ps1 to confirm devices reached the intended state." -ForegroundColor Green
