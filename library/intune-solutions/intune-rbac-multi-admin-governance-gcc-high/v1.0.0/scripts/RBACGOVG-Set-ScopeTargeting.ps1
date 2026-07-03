<#
.SYNOPSIS
    RBACGOVG-Set-ScopeTargeting.ps1 — build the admin and approver scope groups for Intune governance (GCC High).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Entra security groups this solution uses on a US Government
        (GCC High / DoD) tenant: the admin group that custom-role assignments target, and the
        approver group that multi-admin approval access policies target. Both are created as security
        groups, which multi-admin approval requires. Run once during setup; safe to re-run (skips
        groups that already exist). Change AdminGroup / ApproverGroup if you use different names.
        This script defaults to -WhatIf; pass -Apply to actually create groups.
    HOW TO RUN
        Preview (safe, default):  powershell -ExecutionPolicy Bypass -File .\RBACGOVG-Set-ScopeTargeting.ps1
        Create the groups:        powershell -ExecutionPolicy Bypass -File .\RBACGOVG-Set-ScopeTargeting.ps1 -Apply
        Connects to US Gov Graph with -Environment USGov (graph.microsoft.us). Requires the Microsoft
        Graph SDK and consent to Group.ReadWrite.All (write happens only with -Apply).
    EXPECTED RESULTS
        In preview: WHATIF lines for any group that would be created. With -Apply: the groups
        'Intune Admins – Region A – Prod' and 'Change Approvers – Apps – Prod' exist (created if
        missing). Add members in Entra, add the approver group to an Intune role assignment, then use
        them on the role assignment and access policies. Creates groups only; it does not assign roles.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf. Writes only with -Apply, against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param(
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov',
    [string]$AdminGroup    = 'Intune Admins – Region A – Prod',
    [string]$ApproverGroup = 'Change Approvers – Apps – Prod',
    [switch]$Apply
)
$whatIf = -not $Apply
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Apply) { @('Group.ReadWrite.All') } else { @('Group.Read.All') }
Connect-MgGraph -Environment $Environment -Scopes $scopes -NoWelcome

function Ensure-Group([string]$name,[bool]$preview) {
    $filter = "displayName eq '" + ($name -replace "'", "''") + "'"
    $found = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter={0}" -f [uri]::EscapeDataString($filter))).value
    if ($found) { Write-Host ("  EXISTS: '{0}' (id {1})" -f $name, $found[0].id) -ForegroundColor Green; return }
    if ($preview) { Write-Host ("  WHATIF: would create security group '{0}'." -f $name) -ForegroundColor Yellow; return }
    $nick = ($name -replace '[^A-Za-z0-9]', '')
    $body = @{ displayName = $name; mailEnabled = $false; mailNickname = $nick; securityEnabled = $true } | ConvertTo-Json
    try {
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
        Write-Host ("  CREATED: '{0}' (id {1})" -f $name, $g.id) -ForegroundColor Green
    } catch { Write-Host ("  ERROR creating '{0}': {1}" -f $name, $_.Exception.Message) -ForegroundColor Red }
}

Write-Host ("=== RBACGOVG scope groups ({0}) ===" -f ($(if ($whatIf) { 'WhatIf preview — no changes' } else { 'APPLY' }))) -ForegroundColor Cyan
Ensure-Group $AdminGroup $whatIf
Ensure-Group $ApproverGroup $whatIf
Write-Host "`nAdd members in Entra (entra.microsoft.us), add the approver group to an Intune role assignment as a member group, then target these groups on the role assignment and access policies." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
