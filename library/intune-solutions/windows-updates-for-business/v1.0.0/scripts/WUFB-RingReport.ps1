<#
.SYNOPSIS
    WUFB-RingReport.ps1 — list Intune update rings + feature update profiles and assignments (Graph).
.DESCRIPTION
    PURPOSE
        Enumerates Windows Update for Business policies in Intune (update rings and feature update
        profiles) with their assigned groups, so you can audit your ring strategy and coverage.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WUFB-RingReport.ps1
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A list of update rings and feature update profiles with assigned group IDs.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
function Groups($id){ try { (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$id/assignments").value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch { @() } }
$cfgs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceConfigurations').value
$rings = $cfgs | Where-Object { $_.'@odata.type' -match 'windowsUpdateForBusiness' }
$feat  = $cfgs | Where-Object { $_.'@odata.type' -match 'windowsFeatureUpdate' }
Write-Host "=== Update rings ===" -ForegroundColor Cyan
foreach ($r in $rings) { Write-Host ("  {0}  [groups: {1}]" -f $r.displayName, ((Groups $r.id) -join ', ')) }
Write-Host "=== Feature update profiles ===" -ForegroundColor Cyan
foreach ($f in $feat)  { Write-Host ("  {0}  -> {1}  [groups: {2}]" -f $f.displayName, $f.featureUpdateVersion, ((Groups $f.id) -join ', ')) }
if (-not $rings -and -not $feat) { Write-Host "No WUfB rings/feature profiles found." -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null
