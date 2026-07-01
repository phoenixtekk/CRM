<#
.SYNOPSIS
    RBACGOV-Discovery.ps1 — inventory Intune roles, scope tags, role assignments, and access policies.
.DESCRIPTION
    PURPOSE
        Read-only inventory of the Intune administrative governance surface: custom and built-in
        role definitions, scope tags, role assignments (with their scope tags and members), and
        multi-admin approval access policies. Use it as a baseline before designing least-privilege
        roles and approval gates.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RBACGOV-Discovery.ps1
        Requires the Microsoft Graph SDK and consent to DeviceManagementRBAC.Read.All and
        DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        Console listing of role definitions (built-in vs custom), scope tags, role assignments, and
        access policies. Read-only — no changes are made.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementRBAC.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

Write-Host "=== Role definitions ===" -ForegroundColor Cyan
$roles = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions').value
foreach ($r in $roles) { Write-Host ("  {0}  [{1}]" -f $r.displayName, ($(if ($r.isBuiltIn) { 'built-in' } else { 'custom' }))) }

Write-Host "=== Scope tags ===" -ForegroundColor Cyan
$tags = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleScopeTags').value
foreach ($t in $tags) { Write-Host ("  {0}  (id {1})" -f $t.displayName, $t.id) }

Write-Host "=== Role assignments ===" -ForegroundColor Cyan
foreach ($r in $roles) {
    try { $asg = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/roleDefinitions/$($r.id)/roleAssignments").value } catch { $asg = @() }
    foreach ($a in $asg) { Write-Host ("  {0}  <- role '{1}'  [scopeTags: {2}]" -f $a.displayName, $r.displayName, (($a.scopeTags) -join ', ')) }
}

Write-Host "=== Access policies (multi-admin approval) ===" -ForegroundColor Cyan
try { $pol = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/operationApprovalPolicies').value } catch { $pol = @() }
if ($pol) { foreach ($p in $pol) { Write-Host ("  {0}  [type: {1}]" -f $p.displayName, $p.policyType) } }
else { Write-Host "  No operation approval policies found." -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
