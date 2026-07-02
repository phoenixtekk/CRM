<#
.SYNOPSIS
    WDAC-PolicyReport.ps1 — tenant-wide App Control (WDAC) policy + assignment report (Graph).
.DESCRIPTION
    PURPOSE
        Lists Intune App Control for Business policies (configuration profiles / intents) and their
        assignments, so you can audit which devices are targeted and in which mode.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WDAC-PolicyReport.ps1
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A list of App Control policies and assigned group IDs.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
function Groups($uri){ try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch { @() } }
$found = 0
# Settings-catalog configuration policies mentioning App Control
foreach ($p in (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/configurationPolicies').value) {
    if ($p.name -match 'App Control|Application Control|WDAC') {
        $found++
        Write-Host ("POLICY (catalog): {0}  [groups: {1}]" -f $p.name, ((Groups "/beta/deviceManagement/configurationPolicies/$($p.id)/assignments") -join ', ')) -ForegroundColor Cyan
    }
}
# endpoint-security intents mentioning App Control
foreach ($i in (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/intents').value) {
    if ($i.displayName -match 'App Control|Application Control|WDAC') {
        $found++
        Write-Host ("POLICY (intent):  {0}  [groups: {1}]" -f $i.displayName, ((Groups "/beta/deviceManagement/intents/$($i.id)/assignments") -join ', ')) -ForegroundColor Cyan
    }
}
if (-not $found) { Write-Host "No App Control policies found — confirm the policy exists and is named clearly." -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null
