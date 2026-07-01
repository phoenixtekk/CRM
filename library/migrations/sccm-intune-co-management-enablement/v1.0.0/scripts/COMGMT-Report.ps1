<#
.SYNOPSIS
    COMGMT-Report.ps1 — Fleet co-management enrollment + workload-authority report (READ-ONLY).

PURPOSE
    Produces a fleet-wide report of co-management state from Microsoft Intune via
    Microsoft Graph: which Windows devices are co-managed, their management agent,
    and (where exposed) the workloads owned by Intune. Helps confirm enrollment
    coverage and that an equivalent Intune policy exists before moving a workload.
    Read-only — queries only.

HOW TO RUN
    Requires the Microsoft.Graph PowerShell SDK:
        Install-Module Microsoft.Graph -Scope CurrentUser
    Then:
        Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All'
        .\COMGMT-Report.ps1 -OutputCsv .\comgmt-fleet.csv

EXPECTED RESULTS
    A table (and optional CSV) of managed Windows devices showing DeviceName,
    managementAgent (e.g. configurationManagerClientMdm = co-managed),
    complianceState, and last sync — so you can see enrollment coverage and
    co-management spread across the fleet.
#>

[CmdletBinding()]
param(
    [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'

if (-not (Get-MgContext)) {
    Write-Host 'Not connected to Microsoft Graph. Run: Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"'
    return
}

# Pull Windows managed devices. managementAgent of configurationManagerClientMdm
# (or configurationManagerClientMdmEas) indicates a co-managed device.
$devices = Get-MgDeviceManagementManagedDevice -All -Filter "operatingSystem eq 'Windows'"

$report = foreach ($d in $devices) {
    $coManaged = $d.ManagementAgent -in @('configurationManagerClientMdm', 'configurationManagerClientMdmEas')
    [pscustomobject]@{
        DeviceName       = $d.DeviceName
        ManagementAgent  = $d.ManagementAgent
        CoManaged        = $coManaged
        ComplianceState  = $d.ComplianceState
        OSVersion        = $d.OSVersion
        LastSync         = $d.LastSyncDateTime
        UserPrincipal    = $d.UserPrincipalName
    }
}

$report | Sort-Object -Property CoManaged -Descending | Format-Table -AutoSize

$total = ($report | Measure-Object).Count
$co = ($report | Where-Object CoManaged).Count
Write-Host ''
Write-Host ("Co-managed: {0} of {1} Windows devices." -f $co, $total)

if ($OutputCsv) {
    $report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Saved fleet report to $OutputCsv"
}
