<#
.SYNOPSIS
    WS1COEX-Report.ps1 — coexistence & cutover status report (read-only).
.DESCRIPTION
    PURPOSE
        Produces the live management-state picture used for go/no-go decisions: for each managed
        device, whether it is Intune-only or likely DUAL-MANAGED (still carrying a Workspace ONE /
        AirWatch agent), plus its compliance state and last sync. Optionally narrows the report to a
        single cohort group. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1COEX-Report.ps1 -CsvPath C:\Temp\ws1coex-status.csv
        (optional) -CohortGroupId <entra-group-guid>
        Requires the Microsoft Graph PowerShell SDK. Scopes:
        DeviceManagementManagedDevices.Read.All, Group.Read.All.
    EXPECTED RESULTS
        Counts by management state (Intune-only / likely dual-managed) and compliance, and a
        per-device CSV. After a clean cutover a cohort should be Intune-only and compliant.
        NOTE: dual-management is inferred from Intune-side signals only — the Workspace ONE console is
        authoritative for source enrollment (see VMware docs).
#>
[CmdletBinding()]
param([string]$CsvPath,[string]$CohortGroupId)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All' -NoWelcome

Write-Host "=== WS1COEX Status Report (read-only) ===" -ForegroundColor Cyan

# Optional cohort filter
$cohortUpns = $null
if ($CohortGroupId) {
    $members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$CohortGroupId/members?`$select=userPrincipalName").value
    $cohortUpns = @($members | ForEach-Object { $_.userPrincipalName } | Where-Object { $_ })
    Write-Host ("Scoped to cohort group {0} ({1} members)" -f $CohortGroupId,@($cohortUpns).Count) -ForegroundColor Cyan
}

$devs = @()
$uri = '/v1.0/deviceManagement/managedDevices?$select=deviceName,operatingSystem,managementAgent,complianceState,userPrincipalName,lastSyncDateTime'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
if ($cohortUpns) { $devs = @($devs | Where-Object { $cohortUpns -contains $_.userPrincipalName }) }

$report = foreach ($d in $devs) {
    $agent = "$($d.managementAgent)"
    $dual  = $agent -match 'eas|configurationManager|unknown' -or $agent -match 'Mdm.*Eas'
    [pscustomobject]@{
        Device          = $d.deviceName
        OS              = $d.operatingSystem
        ManagementAgent = $agent
        ManagementState = $(if($dual){'Likely dual-managed'}else{'Intune-only'})
        Compliance      = $d.complianceState
        User            = $d.userPrincipalName
        LastSync        = $d.lastSyncDateTime
    }
}

Write-Host "`n--- By management state ---" -ForegroundColor Cyan
$report | Group-Object ManagementState | Select-Object Count,@{n='State';e={$_.Name}} | Format-Table -AutoSize
Write-Host "--- By compliance state ---" -ForegroundColor Cyan
$report | Group-Object Compliance | Select-Object Count,@{n='Compliance';e={$_.Name}} | Format-Table -AutoSize
Write-Host ("Total devices reported: {0}" -f $report.Count) -ForegroundColor Cyan
Write-Host "Confirm any 'Likely dual-managed' devices in the Workspace ONE console (see VMware docs)." -ForegroundColor Yellow

if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "`nSaved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
