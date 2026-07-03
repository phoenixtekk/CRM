<#
.SYNOPSIS
    RBACGOVG-Report.ps1 — governance-coverage and over-privilege report for Intune administration (GCC High).
.DESCRIPTION
    PURPOSE
        Read-only report summarizing governance coverage and flagging over-privileged assignments on
        a US Government (GCC High / DoD) tenant: how many roles are custom vs built-in, scope-tag
        coverage, which assignments lack a scope tag, which use a broad built-in role, and which
        high-risk resource types are NOT covered by an access policy (multi-admin approval).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RBACGOVG-Report.ps1
        Connects to US Gov Graph with -Environment USGov (graph.microsoft.us). Requires the Microsoft
        Graph SDK and consent to DeviceManagementRBAC.Read.All.
    EXPECTED RESULTS
        A coverage summary plus an OVER-PRIVILEGE section listing assignments with no scope tag or a
        broad built-in role, and gated-resource gaps. Read-only — no changes are made. Pass = no
        over-privilege findings and no gated-resource gaps.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param(
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementRBAC.Read.All' -NoWelcome

$roles = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions').value
$tags  = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleScopeTags').value
try { $pol = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/operationApprovalPolicies').value } catch { $pol = @(); Write-Host "operationApprovalPolicies not available — verify multi-admin approval for GCC High." -ForegroundColor Yellow }

$custom = ($roles | Where-Object { -not $_.isBuiltIn }).Count
$builtin = ($roles | Where-Object { $_.isBuiltIn }).Count

Write-Host "=== Governance coverage ===" -ForegroundColor Cyan
Write-Host ("  Roles: {0} custom, {1} built-in" -f $custom, $builtin)
Write-Host ("  Scope tags defined: {0}" -f $tags.Count)
Write-Host ("  Access policies (multi-admin approval): {0}" -f $pol.Count)

Write-Host "=== Over-privilege findings ===" -ForegroundColor Cyan
$findings = 0
foreach ($r in $roles) {
    try { $asg = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/roleDefinitions/$($r.id)/roleAssignments").value } catch { $asg = @() }
    foreach ($a in $asg) {
        if (-not $a.scopeTags) { Write-Host ("  OVER-PRIVILEGE: assignment '{0}' (role '{1}') has NO scope tag — unbounded reach." -f $a.displayName, $r.displayName) -ForegroundColor Yellow; $findings++ }
        if ($r.isBuiltIn -and $r.displayName -match 'Administrator') { Write-Host ("  REVIEW: assignment '{0}' uses broad built-in role '{1}' — prefer a least-privilege custom role." -f $a.displayName, $r.displayName) -ForegroundColor Yellow; $findings++ }
    }
}
if ($findings -eq 0) { Write-Host "  None found." -ForegroundColor Green }

Write-Host "=== Gated-resource gaps ===" -ForegroundColor Cyan
$gatedTypes = @('apps','scripts')
$covered = $pol | ForEach-Object { "$($_.policyType)".ToLower() }
foreach ($g in $gatedTypes) {
    if (($covered -join ' ') -match $g) { Write-Host ("  COVERED: '{0}' has an access policy." -f $g) -ForegroundColor Green }
    else { Write-Host ("  GAP: high-risk type '{0}' has NO multi-admin approval policy." -f $g) -ForegroundColor Yellow }
}

Disconnect-MgGraph | Out-Null
