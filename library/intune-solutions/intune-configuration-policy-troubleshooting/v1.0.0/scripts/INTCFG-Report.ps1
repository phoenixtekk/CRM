<#
.SYNOPSIS
    INTCFG-Report.ps1 — assignment + conflict coverage report for Intune configuration policies.
.DESCRIPTION
    PURPOSE
        Builds the tenant-wide conflict picture the console cannot show directly: it reads every
        settings-catalog / device-configuration policy, records each setting and the groups it targets,
        then reports any setting that appears in MORE THAN ONE assigned policy (overlap = conflict
        risk). Use it before and after changes to keep every setting owned by exactly one policy.
        Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCFG-Report.ps1
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A coverage summary (policies + assigned groups) and a CONFLICT RISK list of settings owned by
        more than one assigned policy. "No overlapping settings" if the estate is conflict-free.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome

Write-Host "`n=== Intune Configuration — Assignment & Conflict Coverage ===" -ForegroundColor Cyan

# settingId -> list of policy names that define it
$settingOwners = @{}
$assignedPolicies = 0

$policies = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/configurationPolicies?$expand=assignments,settings').value
foreach ($p in $policies) {
    $isAssigned = ($p.assignments -and $p.assignments.Count -gt 0)
    if (-not $isAssigned) { continue }   # only assigned policies can conflict on a device
    $assignedPolicies++

    $grpIds = @()
    foreach ($a in $p.assignments) { if ($a.target.groupId) { $grpIds += $a.target.groupId } }
    Write-Host ("`nPOLICY: {0}   [assigned groups: {1}]" -f $p.name, ($grpIds -join ', ')) -ForegroundColor Cyan

    foreach ($s in $p.settings) {
        $sid = $s.settingInstance.settingDefinitionId
        if (-not $sid) { continue }
        if (-not $settingOwners.ContainsKey($sid)) { $settingOwners[$sid] = New-Object System.Collections.Generic.List[string] }
        if (-not $settingOwners[$sid].Contains($p.name)) { $settingOwners[$sid].Add($p.name) }
    }
}

Write-Host ("`nAssigned policies analysed: {0}" -f $assignedPolicies) -ForegroundColor Cyan
Write-Host "`n--- CONFLICT RISK (setting defined by more than one assigned policy) ---" -ForegroundColor Yellow
$conflicts = 0
foreach ($sid in $settingOwners.Keys) {
    if ($settingOwners[$sid].Count -gt 1) {
        $conflicts++
        $short = ($sid -split '_')[-1]
        Write-Host ("  SETTING {0}" -f $short) -ForegroundColor Yellow
        Write-Host ("     defined by: {0}" -f ($settingOwners[$sid] -join '  |  ')) -ForegroundColor Gray
    }
}
if ($conflicts -eq 0) {
    Write-Host "  No overlapping settings — every setting is owned by exactly one assigned policy." -ForegroundColor Green
} else {
    Write-Host ("`nTotal settings with conflict risk: {0}. Make each owned by ONE policy." -f $conflicts) -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
