<#
.SYNOPSIS
    WS1WIN-Report.ps1 — fleet migration status + compliance for Windows devices (read-only, Graph).
.DESCRIPTION
    PURPOSE
        Produces a fleet-wide view of the Workspace ONE to Intune Windows migration from Microsoft
        Graph: which Windows devices are managed by Intune, their management/ownership and
        compliance state, and the migration-ring group membership — so you can track progress and
        catch laggards. Read-only against Graph: changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1WIN-Report.ps1
        Requires the Microsoft Graph PowerShell SDK and:
          DeviceManagementManagedDevices.Read.All, Group.Read.All
    EXPECTED RESULTS
        A per-device table (name, OS, managementAgent, compliance) for Windows devices, a summary
        count by compliance state, and the member counts of the migration groups.
.NOTES
    Workplace Marketplace — Migrations. Read-only against Graph.
#>
[CmdletBinding()] param(
    [string]$PilotGroup = 'Group - Migration Pilot - Windows',
    [string]$BroadGroup = 'Group - Migration Broad - Windows',
    [string]$SourceGroup = 'Group - Workspace ONE Managed - Windows'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All' -NoWelcome

# Windows managed devices
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$select=deviceName,operatingSystem,osVersion,managementAgent,complianceState,ownerType"
$devs = @()
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    $devs += $page.value
    $uri = $page.'@odata.nextLink'
} while ($uri)

Write-Host "`n=== Windows devices in Intune ($($devs.Count)) ===" -ForegroundColor Cyan
$devs | Sort-Object complianceState, deviceName |
    Select-Object deviceName, osVersion, managementAgent, complianceState |
    Format-Table -AutoSize

Write-Host "--- Compliance summary ---" -ForegroundColor Cyan
$devs | Group-Object complianceState | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-14}: {1}" -f $_.Name, $_.Count) }

# Migration group member counts
function GroupCount($displayName){
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$displayName'&`$select=id,displayName").value | Select-Object -First 1
    if (-not $g) { return $null }
    $m = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($g.id)/members/`$count" -Headers @{ ConsistencyLevel = 'eventual' })
    return $m
}
Write-Host "`n--- Migration ring groups ---" -ForegroundColor Cyan
foreach ($n in @($PilotGroup,$BroadGroup,$SourceGroup)) {
    $c = GroupCount $n
    if ($null -eq $c) { Write-Host ("  {0,-40}: NOT FOUND" -f $n) -ForegroundColor Yellow }
    else { Write-Host ("  {0,-40}: {1} members" -f $n, $c) }
}
Write-Host "`nMigration is complete when '$SourceGroup' is empty and all devices are Intune + compliant." -ForegroundColor Green

Disconnect-MgGraph | Out-Null
