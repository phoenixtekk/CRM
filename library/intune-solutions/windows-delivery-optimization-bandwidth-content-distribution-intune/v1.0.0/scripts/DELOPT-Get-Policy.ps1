<#
.SYNOPSIS
    DELOPT-Get-Policy.ps1 — export the Intune Delivery Optimization policy + assignments (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Finds Settings Catalog configuration policies that contain Delivery Optimization settings in
        Intune and lists their assigned groups, so you can confirm the DELOPT policy exists and is
        assigned to the intended Pilot/Production groups (and spot conflicting duplicates).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DELOPT-Get-Policy.ps1
        Sovereign cloud:  .\DELOPT-Get-Policy.ps1 -Environment USGov      (or USGovDoD)
        Requires the Microsoft.Graph SDK and delegated DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A list of Delivery Optimization configuration policies with their assigned group IDs.
        Read-only against Graph (no changes made).
.NOTES
    White-label — Intune Solutions. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome

function Assignments($policyId) {
    try {
        (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$policyId/assignments").value |
            ForEach-Object { $_.target.groupId } | Where-Object { $_ }
    } catch { @() }
}

Write-Host "`n=== Intune Delivery Optimization policies ===" -ForegroundColor Cyan
$policies = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/configurationPolicies?$top=200').value
$found = @()
foreach ($p in $policies) {
    try {
        $settings = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/settings").value
        $json = ($settings | ConvertTo-Json -Depth 15 -Compress)
        if ($json -match 'deliveryoptimization') {
            $found += $p
            $groups = (Assignments $p.id) -join ', '
            Write-Host ("  {0}  [groups: {1}]" -f $p.name, $(if($groups){$groups}else{'UNASSIGNED'}))
        }
    } catch {}
}
if (-not $found) { Write-Host "  No Delivery Optimization configuration policies found." -ForegroundColor Yellow }
else { Write-Host ("`n{0} Delivery Optimization policy(ies) found." -f $found.Count) -ForegroundColor Green }

Disconnect-MgGraph | Out-Null
