<#
.SYNOPSIS
    RBACGOVG-Discovery.ps1 — inventory Intune roles, scope tags, assignments, and access policies (GCC High).
.DESCRIPTION
    PURPOSE
        Read-only inventory of the Intune administrative governance surface on a US Government
        (GCC High / DoD) tenant: custom and built-in role definitions, scope tags, role assignments
        (with their scope tags and members), and multi-admin approval access policies. Use it as a
        baseline before designing least-privilege roles and approval gates. Placeholders like
        your-tenant-id are literal — replace them with your own values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RBACGOVG-Discovery.ps1
        Connects to US Gov Graph with -Environment USGov (graph.microsoft.us). Requires the Microsoft
        Graph SDK and consent to DeviceManagementRBAC.Read.All and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        Console listing of role definitions (built-in vs custom), scope tags, role assignments, and
        access policies. Read-only — no changes are made. Pass = the inventory prints without error;
        if operationApprovalPolicies errors, multi-admin approval may not be surfaced on your tenant.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param(
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementRBAC.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

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
try { $pol = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/operationApprovalPolicies').value } catch { $pol = @(); Write-Host "  operationApprovalPolicies not available on this tenant — verify multi-admin approval for GCC High." -ForegroundColor Yellow }
if ($pol) { foreach ($p in $pol) { Write-Host ("  {0}  [type: {1}]" -f $p.displayName, $p.policyType) } }
elseif (-not $pol) { Write-Host "  No operation approval policies found." -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
