<#
.SYNOPSIS
    WFM-ConflictCheck.ps1 — list Intune firewall policies and assignments to spot conflicts.
.DESCRIPTION
    PURPOSE
        Enumerates Intune endpoint-security firewall policies (intents) and their assigned groups,
        so you can spot multiple firewall policies targeting the same devices.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WFM-ConflictCheck.ps1
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A list of firewall policies with assigned group IDs; review for overlap. Also reminds you
        to check for a legacy GPO firewall.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
$intents = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/intents').value | Where-Object { $_.displayName -match 'firewall' -or $_.templateId }
$fw = $intents | Where-Object { $_.displayName -match 'firewall' }
if (-not $fw) { $fw = $intents }
foreach ($i in $fw) {
    $asg = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/intents/$($i.id)/assignments").value
    $groups = $asg | ForEach-Object { $_.target.groupId } | Where-Object { $_ }
    Write-Host ("FIREWALL POLICY: {0}  [groups: {1}]" -f $i.displayName, ($groups -join ', ')) -ForegroundColor Cyan
}
Write-Host "`nAlso confirm no legacy GPO firewall and no firewall settings in the security baseline target these devices." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
