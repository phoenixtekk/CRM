<#
.SYNOPSIS
    ESB-ConflictCheck.ps1 — list configuration/security policies that may conflict with a baseline.
.DESCRIPTION
    PURPOSE
        Enumerates Intune configuration profiles and endpoint-security intents with their
        assignments, so you can spot overlapping policies that cause baseline setting conflicts.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ESB-ConflictCheck.ps1
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A combined list of profiles/intents + assigned groups to review for overlap.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
function Groups($uri){ try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch { @() } }
Write-Host "=== Configuration profiles ===" -ForegroundColor Cyan
foreach ($p in (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceConfigurations').value) {
    Write-Host ("  {0}  [groups: {1}]" -f $p.displayName, ((Groups "/beta/deviceManagement/deviceConfigurations/$($p.id)/assignments") -join ','))
}
Write-Host "`n=== Endpoint security intents (baselines/policies) ===" -ForegroundColor Cyan
foreach ($i in (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/intents').value) {
    Write-Host ("  {0}  [groups: {1}]" -f $i.displayName, ((Groups "/beta/deviceManagement/intents/$($i.id)/assignments") -join ','))
}
Write-Host "`nReview items that target the same groups and set the same security area — make one authoritative." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
