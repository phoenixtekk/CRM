<#
.SYNOPSIS
    DCP-ConflictCheck.ps1 — list compliance policies and their assignments to spot conflicts.
.DESCRIPTION
    PURPOSE
        Enumerates Intune device compliance policies and the groups they target, so you can spot
        devices/users covered by multiple (potentially conflicting) compliance policies.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DCP-ConflictCheck.ps1
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A list of compliance policies with assigned group IDs; review for overlap.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/deviceCompliancePolicies').value
foreach ($p in $pols) {
    $asg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/deviceCompliancePolicies/$($p.id)/assignments").value
    $groups = $asg | ForEach-Object { $_.target.groupId } | Where-Object { $_ }
    Write-Host ("POLICY: {0}" -f $p.displayName) -ForegroundColor Cyan
    Write-Host ("  platform: {0} | assigned groups: {1}" -f $p.'@odata.type', ($groups -join ', '))
}
Write-Host "`nReview policies that target overlapping groups — consolidate to one authoritative policy per scope." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
