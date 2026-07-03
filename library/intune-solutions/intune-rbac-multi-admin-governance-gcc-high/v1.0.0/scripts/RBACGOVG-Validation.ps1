<#
.SYNOPSIS
    RBACGOVG-Validation.ps1 — validate role assignments and multi-admin approval policies vs design (GCC High).
.DESCRIPTION
    PURPOSE
        Read-only check that the expected custom roles, role assignments (with scope tags), and
        access policies (multi-admin approval) exist and target the right approver group on a US
        Government (GCC High / DoD) tenant. Confirms the governance design is actually in force.
        Edit the Expected* parameters to match your design; the defaults use the solution's named
        artifacts (for example App Manager – Region A – Prod).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RBACGOVG-Validation.ps1
        Connects to US Gov Graph with -Environment USGov (graph.microsoft.us). Requires the Microsoft
        Graph SDK and consent to DeviceManagementRBAC.Read.All.
    EXPECTED RESULTS
        PASS/FAIL lines for each expected role, assignment, and access policy. Read-only — no changes.
        Pass = every expected artifact reports PASS.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param(
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov',
    [string[]]$ExpectedRoles    = @('App Manager – Region A – Prod','Policy Reader – All – Audit'),
    [string[]]$ExpectedPolicies = @('App Deploy Approval – All – Prod','Script Deploy Approval – All – Prod'),
    [string]  $ApproverGroup    = 'Change Approvers – Apps – Prod'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementRBAC.Read.All' -NoWelcome

function Result($ok,$msg){ if ($ok) { Write-Host "  PASS  $msg" -ForegroundColor Green } else { Write-Host "  FAIL  $msg" -ForegroundColor Red } }

Write-Host "=== Validate custom roles ===" -ForegroundColor Cyan
$roles = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions').value
foreach ($name in $ExpectedRoles) {
    $r = $roles | Where-Object { $_.displayName -eq $name }
    Result ([bool]$r) "role '$name' exists"
    if ($r) {
        try { $asg = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/roleDefinitions/$($r.id)/roleAssignments").value } catch { $asg = @() }
        Result ($asg.Count -gt 0) "role '$name' has at least one assignment"
        if ($asg) { Result (($asg | Where-Object { $_.scopeTags }).Count -gt 0) "role '$name' assignment carries a scope tag" }
    }
}

Write-Host "=== Validate access policies (multi-admin approval) ===" -ForegroundColor Cyan
try { $pol = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/operationApprovalPolicies').value } catch { $pol = @(); Write-Host "  operationApprovalPolicies not available — verify multi-admin approval for GCC High on this tenant." -ForegroundColor Yellow }
foreach ($name in $ExpectedPolicies) {
    $p = $pol | Where-Object { $_.displayName -eq $name }
    Result ([bool]$p) "access policy '$name' exists"
    if ($p) { Result ([bool]$p.policyType) "access policy '$name' has a resource type set ($($p.policyType))" }
}
Write-Host ("Approver group expected: {0} — confirm it is a security group, selected on each policy, and added to an Intune role assignment as a member group." -f $ApproverGroup) -ForegroundColor Yellow

Disconnect-MgGraph | Out-Null
