<#
.SYNOPSIS
    ESB-TenantReport.ps1 — security baseline assignment + state report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Lists Intune security baseline (intent) profiles and their assignment, so you can confirm
        coverage of your baselines across the fleet.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ESB-TenantReport.ps1
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A list of baseline profiles with template family and assigned groups.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
$intents = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/intents').value | Where-Object { $_.templateId -or $_.displayName -match 'baseline' }
if (-not $intents) { $intents = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/intents').value }
foreach ($i in $intents) {
    $asg = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/intents/$($i.id)/assignments").value
    $groups = $asg | ForEach-Object { $_.target.groupId } | Where-Object { $_ }
    Write-Host ("BASELINE: {0}" -f $i.displayName) -ForegroundColor Cyan
    Write-Host ("  assigned groups: {0}" -f ($groups -join ', '))
}
Write-Host ("`nTotal baseline/intent profiles: {0}" -f $intents.Count) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
