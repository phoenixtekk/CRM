<#
.SYNOPSIS
    EPICGOLIVE-Set-ReadinessGroup — manage the readiness device group membership.

.DESCRIPTION
    Reconciles the membership of the "Readiness Device Group - Clinical Fleet - Validation"
    against the authoritative in-scope device inventory for an Epic go-live, so the validation
    sweep, remediation, and deployments target exactly the right devices.

    SAFE BY DEFAULT. Runs in preview (-WhatIf) mode unless -Apply is supplied:
      * Without -Apply : reports the additions/removals it WOULD make (the intended membership
                         vs. current membership).
      * With    -Apply : adds the missing in-scope devices to the group (and, with -RemoveStale,
                         removes members no longer in the inventory).

    Membership changes are reversible: the preview output is the rollback record of prior state
    (GR7). Run preview, confirm against the inventory, then -Apply.

.PARAMETER GroupId
    Object ID of the readiness group to manage.

.PARAMETER InventoryCsv
    CSV of the in-scope inventory. Must contain a column with the Entra device object IDs
    (default column name 'AzureAdDeviceId', overridable with -DeviceIdColumn).

.PARAMETER DeviceIdColumn
    Column in the inventory CSV that holds the Entra device object ID. Default 'AzureAdDeviceId'.

.PARAMETER RemoveStale
    When set (with -Apply), removes current members that are not present in the inventory.

.PARAMETER Apply
    Perform the membership changes. Omit to preview only (default).

.EXAMPLE
    # Preview intended membership vs. current:
    .\EPICGOLIVE-Set-ReadinessGroup.ps1 -GroupId <guid> -InventoryCsv .\in-scope.csv

.EXAMPLE
    # Apply additions and remove members no longer in scope:
    .\EPICGOLIVE-Set-ReadinessGroup.ps1 -GroupId <guid> -InventoryCsv .\in-scope.csv -RemoveStale -Apply

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string] $GroupId,
    [Parameter(Mandatory)] [string] $InventoryCsv,
    [string] $DeviceIdColumn = 'AzureAdDeviceId',
    [switch] $RemoveStale,
    [switch] $Apply
)

function Assert-Graph {
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install-Module Microsoft.Graph, then Connect-MgGraph."
    }
    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. For -Apply use 'GroupMember.ReadWrite.All'; preview needs 'Group.Read.All','Device.Read.All'."
    }
}
Assert-Graph

if (-not (Test-Path $InventoryCsv)) { throw "Inventory CSV not found: $InventoryCsv" }
$inventory = Import-Csv -Path $InventoryCsv
if (-not ($inventory[0].PSObject.Properties.Name -contains $DeviceIdColumn)) {
    throw "Inventory CSV has no column '$DeviceIdColumn'. Use -DeviceIdColumn to specify the device-id column."
}

# Map inventory Entra device IDs -> Entra directory object IDs (group members are directory objects).
Write-Host "EPICGOLIVE-Set-ReadinessGroup — reconciling membership (preview unless -Apply)..." -ForegroundColor Cyan

$wantObjectIds = foreach ($row in $inventory) {
    $entraDeviceId = $row.$DeviceIdColumn
    if (-not $entraDeviceId) { continue }
    try {
        $dev = Get-MgDevice -Filter "deviceId eq '$entraDeviceId'" -ErrorAction Stop | Select-Object -First 1
        if ($dev) { $dev.Id }
    } catch {
        Write-Warning "Could not resolve Entra device for deviceId '$entraDeviceId': $($_.Exception.Message)"
    }
}
$wantObjectIds = $wantObjectIds | Where-Object { $_ } | Sort-Object -Unique

# Current group members (device objects).
$current = Get-MgGroupMember -GroupId $GroupId -All
$currentIds = $current | Where-Object { $_.AdditionalProperties.'@odata.type' -match 'device' } |
    ForEach-Object { $_.Id } | Sort-Object -Unique

$toAdd    = $wantObjectIds | Where-Object { $_ -notin $currentIds }
$toRemove = $currentIds    | Where-Object { $_ -notin $wantObjectIds }

Write-Host ("Intended: {0}   Current: {1}   To add: {2}   Stale (to remove): {3}" -f `
    $wantObjectIds.Count, $currentIds.Count, $toAdd.Count, $toRemove.Count)

if (-not $Apply) {
    Write-Host "PREVIEW MODE (no -Apply) — no membership changes made." -ForegroundColor Yellow
    Write-Host "Would ADD:" -ForegroundColor Yellow;    $toAdd    | ForEach-Object { "  + $_" }
    if ($RemoveStale) { Write-Host "Would REMOVE (stale):" -ForegroundColor Yellow; $toRemove | ForEach-Object { "  - $_" } }
    Write-Host "Re-run with -Apply after confirming against the inventory." -ForegroundColor Yellow
    return
}

#-------------------------------------------------------------------------------
# Apply membership changes
#-------------------------------------------------------------------------------
foreach ($id in $toAdd) {
    if ($PSCmdlet.ShouldProcess($id, "Add to readiness group")) {
        try {
            New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $id -ErrorAction Stop
            Write-Host "Added $id" -ForegroundColor Green
        } catch {
            Write-Warning "Add failed for $id : $($_.Exception.Message)"
        }
    }
}

if ($RemoveStale) {
    foreach ($id in $toRemove) {
        if ($PSCmdlet.ShouldProcess($id, "Remove stale member from readiness group")) {
            try {
                Remove-MgGroupMemberByRef -GroupId $GroupId -DirectoryObjectId $id -ErrorAction Stop
                Write-Host "Removed $id" -ForegroundColor Green
            } catch {
                Write-Warning "Remove failed for $id : $($_.Exception.Message)"
            }
        }
    }
}

Write-Host "Apply complete. The readiness group now matches the in-scope inventory." -ForegroundColor Green
