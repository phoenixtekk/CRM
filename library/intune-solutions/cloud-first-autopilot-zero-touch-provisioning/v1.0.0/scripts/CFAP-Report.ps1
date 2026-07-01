<#
.SYNOPSIS
    CFAP-Report.ps1 — Provisioning-success and technician-touch report for Cloud-First Autopilot
    Zero-Touch Provisioning.

PURPOSE
    Read-only. Produces a fleet/group-level report of cloud-first provisioning health and the
    technician-touch picture: which Autopilot devices have provisioned, their enrollment/join state,
    profile-assignment status, and an inferred technician-touch classification (zero-touch when the
    device enrolled via Autopilot and is Entra-joined, versus higher-touch when it was domain-joined
    or has no Autopilot identity). Uses Microsoft Graph windowsAutopilotDeviceIdentities and
    managedDevices.

HOW TO RUN
    Requires the Microsoft Graph PowerShell SDK and scopes
    DeviceManagementServiceConfig.Read.All + DeviceManagementManagedDevices.Read.All + Group.Read.All.

        powershell -ExecutionPolicy Bypass -File .\CFAP-Report.ps1

    Scope to the dynamic Autopilot group and export CSV:
        .\CFAP-Report.ps1 -GroupName 'Autopilot Devices - All Cloud-First - Provisioning' -OutputCsv .\CFAP-Report.csv

EXPECTED RESULTS
    A per-device table (serial, model, group tag, enrollment state, profile-assignment status, join
    type, OS version, last sync) plus a technician-touch summary: counts of zero-touch vs. higher-touch
    devices and the zero-touch percentage. Read-only; changes nothing.
#>
[CmdletBinding()]
param(
    [string]$GroupName,
    [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementManagedDevices.Read.All','Group.Read.All' | Out-Null
}

function Get-AllGraph($uri) {
    $items = @()
    do {
        $page = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($page.value) { $items += $page.value }
        $uri = $page.'@odata.nextLink'
    } while ($uri)
    return $items
}

Write-Host 'Reading Autopilot device identities...' -ForegroundColor Cyan
$autopilot = Get-AllGraph 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities'

Write-Host 'Reading Intune managed devices...' -ForegroundColor Cyan
$managed = Get-AllGraph 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices'
$managedBySerial = @{}
foreach ($m in $managed) { if ($m.serialNumber) { $managedBySerial[$m.serialNumber] = $m } }

# Optional: restrict to a target group's member serials
$groupSerials = $null
if ($GroupName) {
    $g = Get-AllGraph ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName.Replace("'","''"))
    if ($g) {
        $members = Get-AllGraph ("https://graph.microsoft.com/v1.0/groups/{0}/members?`$select=id,deviceId,displayName" -f $g[0].id)
        $groupSerials = New-Object System.Collections.Generic.HashSet[string]
        foreach ($mem in $members) {
            $md = $managed | Where-Object { $_.azureADDeviceId -eq $mem.deviceId } | Select-Object -First 1
            if ($md.serialNumber) { [void]$groupSerials.Add($md.serialNumber) }
        }
        Write-Host ("Scoped to group '{0}' ({1} resolvable members)" -f $GroupName, $groupSerials.Count)
    } else {
        Write-Warning "Group '$GroupName' not found; reporting on all Autopilot devices."
    }
}

$rows = foreach ($ap in $autopilot) {
    if ($groupSerials -and -not $groupSerials.Contains($ap.serialNumber)) { continue }
    $m = $managedBySerial[$ap.serialNumber]
    $joinType = if ($m) { $m.joinType } else { 'unknown' }
    $provisioned = ($ap.enrollmentState -eq 'enrolled') -and ($m -ne $null)
    # Zero-touch heuristic: Autopilot-enrolled AND Entra-joined (azureADJoined) -> power-on only
    $zeroTouch = $provisioned -and ($joinType -match 'azureADJoined|azureADRegistered' -and $joinType -notmatch 'hybrid|onPremises')
    [pscustomobject]@{
        Serial            = $ap.serialNumber
        Model             = $ap.model
        GroupTag          = $ap.groupTag
        EnrollmentState   = $ap.enrollmentState
        ProfileAssignment = $ap.deploymentProfileAssignmentStatus
        JoinType          = $joinType
        OSVersion         = $m.osVersion
        LastSync          = $m.lastSyncDateTime
        Provisioned       = $provisioned
        TouchClass        = if ($zeroTouch) { 'zero-touch' } elseif ($provisioned) { 'higher-touch' } else { 'not-provisioned' }
    }
}

Write-Host "`n=== Provisioning detail ===" -ForegroundColor Cyan
$rows | Sort-Object TouchClass, Serial | Format-Table -AutoSize

$total   = ($rows | Measure-Object).Count
$zero    = ($rows | Where-Object TouchClass -eq 'zero-touch' | Measure-Object).Count
$higher  = ($rows | Where-Object TouchClass -eq 'higher-touch' | Measure-Object).Count
$notProv = ($rows | Where-Object TouchClass -eq 'not-provisioned' | Measure-Object).Count
$pct = if ($total) { [math]::Round(($zero / $total) * 100, 1) } else { 0 }

Write-Host "`n=== Technician-touch summary ===" -ForegroundColor Cyan
[pscustomobject]@{
    TotalDevices     = $total
    ZeroTouch        = $zero
    HigherTouch      = $higher
    NotProvisioned   = $notProv
    ZeroTouchPercent = "$pct%"
} | Format-List

if ($OutputCsv) {
    $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("Exported to {0}" -f $OutputCsv) -ForegroundColor Green
}
