<#
.SYNOPSIS
    NEWSITE-Report.ps1 — site rollout status report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Reports the rollout status for a site's device group: how many devices are enrolled
        (provisioned), compliant (baselined), and present — so you can see at a glance whether the
        site is ready to open. Reads the site device group membership and each member's managed-device
        state from Intune via Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NEWSITE-Report.ps1 -GroupName "New Site - Site A - Pilot"
        Requires the Microsoft Graph SDK and the scopes Group.Read.All and
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A per-site summary: total devices, enrolled, compliant, and a list of any devices stuck in an
        earlier stage.
.NOTES
    New-Site Endpoint Rollout Playbook. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GroupName
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host ("`n=== Site Rollout Status — {0} ===" -f $GroupName) -ForegroundColor Cyan

$grp = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)).value | Select-Object -First 1
if (-not $grp) { Write-Host "Group not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

$members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members" -f $grp.id)).value
$total = 0; $enrolled = 0; $compliant = 0; $stuck = @()

foreach ($m in $members) {
    $total++
    $devName = $m.displayName
    $md = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}'" -f $devName)).value | Select-Object -First 1
    if ($md) {
        $enrolled++
        if ($md.complianceState -eq 'compliant') { $compliant++ }
        else { $stuck += ("{0} (compliance: {1})" -f $devName, $md.complianceState) }
    } else {
        $stuck += ("{0} (not enrolled)" -f $devName)
    }
}

Write-Host ("Devices in group : {0}" -f $total)
Write-Host ("Enrolled         : {0}" -f $enrolled) -ForegroundColor Green
Write-Host ("Compliant        : {0}" -f $compliant) -ForegroundColor Green
if ($stuck.Count) {
    Write-Host "Stuck in an earlier stage:" -ForegroundColor Yellow
    $stuck | ForEach-Object { Write-Host ("  - {0}" -f $_) -ForegroundColor Yellow }
} else {
    Write-Host "All devices enrolled and compliant — site ready for the go-live checklist." -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
