<#
.SYNOPSIS
    WS1COEX-Discovery.ps1 — discover the current coexistence state (read-only).
.DESCRIPTION
    PURPOSE
        Inventories Windows/Apple/Android devices managed in the Intune target, flags likely
        DUAL-MANAGED devices (still carrying a Workspace ONE / AirWatch management agent while
        present in Intune), and snapshots Conditional Access policies and Entra cohort groups so you
        can baseline before any cutover. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1COEX-Discovery.ps1 -CsvPath C:\Temp\ws1coex-discovery.csv
        Requires the Microsoft Graph PowerShell SDK. Consents to read-only scopes:
        DeviceManagementManagedDevices.Read.All, Policy.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A summary of devices by management state (Intune-only vs likely dual-managed), a list of
        Conditional Access policies that require a compliant/Entra-joined device, the existing cohort
        groups, and an optional per-device CSV. No changes are made.
        NOTE: Workspace ONE-side enrollment is authoritative in the source console — see VMware docs;
        this script infers dual management from Intune-side signals only.
#>
[CmdletBinding()]
param([string]$CsvPath)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Policy.Read.All','Group.Read.All' -NoWelcome

Write-Host "=== WS1COEX Discovery — coexistence baseline (read-only) ===" -ForegroundColor Cyan

# --- Managed devices: detect likely dual management from management agent / enrollment signals ---
$devs = @()
$uri = '/v1.0/deviceManagement/managedDevices?$select=deviceName,operatingSystem,osVersion,managementAgent,complianceState,ownerType,enrolledDateTime,lastSyncDateTime'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$report = foreach ($d in $devs) {
    # An Intune-managed device whose management agent indicates a third-party/EAS or MDM/MAM combo is
    # a candidate for dual management; confirm against the Workspace ONE console (see VMware docs).
    $agent = "$($d.managementAgent)"
    $dual  = $agent -match 'eas|googleCloudDevicePolicyController|configurationManager|unknown' -or $agent -match 'Mdm.*Eas'
    [pscustomobject]@{
        Device          = $d.deviceName
        OS              = $d.operatingSystem
        OSVersion       = $d.osVersion
        ManagementAgent = $agent
        Compliance      = $d.complianceState
        Owner           = $d.ownerType
        LikelyDual      = [bool]$dual
        LastSync        = $d.lastSyncDateTime
    }
}

Write-Host "`n--- Devices by management agent ---" -ForegroundColor Cyan
$report | Group-Object ManagementAgent | Sort-Object Count -Descending |
    Select-Object Count, @{n='ManagementAgent';e={$_.Name}} | Format-Table -AutoSize
Write-Host ("Total Intune-managed devices: {0}" -f $report.Count) -ForegroundColor Cyan
Write-Host ("Likely DUAL-MANAGED (verify in Workspace ONE — see VMware docs): {0}" -f (@($report | Where-Object LikelyDual)).Count) -ForegroundColor Yellow

# --- Conditional Access policies that gate on device compliance/join ---
Write-Host "`n--- Conditional Access policies requiring compliant / Entra-joined device ---" -ForegroundColor Cyan
$ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$caGate = foreach ($p in $ca) {
    $controls = @($p.grantControls.builtInControls)
    if ($controls -contains 'compliantDevice' -or $controls -contains 'domainJoinedDevice') {
        [pscustomobject]@{
            Policy   = $p.displayName
            State    = $p.state
            Controls = ($controls -join ',')
            AllUsers = [bool](@($p.conditions.users.includeUsers) -contains 'All')
        }
    }
}
if ($caGate) { $caGate | Format-Table -AutoSize
    if (@($caGate | Where-Object AllUsers).Count) {
        Write-Host "  WARNING: a device-compliance policy targets All users — scope it to a cohort group before coexistence." -ForegroundColor Yellow }
} else { Write-Host "  (none found)" }

# --- Cohort groups (Entra security groups) ---
Write-Host "`n--- Candidate cohort groups (security groups) ---" -ForegroundColor Cyan
$groups = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=securityEnabled eq true&`$select=displayName,id").value
$groups | Select-Object displayName, id | Sort-Object displayName | Format-Table -AutoSize

if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "`nSaved device inventory to $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
