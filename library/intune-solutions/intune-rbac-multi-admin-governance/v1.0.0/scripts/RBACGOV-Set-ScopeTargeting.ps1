<#
.SYNOPSIS
    RBACGOV-Set-ScopeTargeting.ps1 — build the admin and approver scope groups for Intune governance.
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Entra security groups used by this solution: the admin group that
        custom-role assignments target, and the approver group that multi-admin approval access
        policies target. Run once during setup; safe to re-run (skips groups that already exist).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RBACGOV-Set-ScopeTargeting.ps1
        Requires the Microsoft Graph SDK and consent to Group.ReadWrite.All.
        Edit $AdminGroup / $ApproverGroup below if you use different names.
    EXPECTED RESULTS
        The groups 'Intune Admins – Region A – Prod' and 'Change Approvers – Apps – Prod' exist
        (created if missing). Add members in Entra, then use them on the role assignment and access
        policies. This script creates groups only; it does not assign roles.
.NOTES
    White-label — Intune Solutions. Creates Entra groups (write).
#>
[CmdletBinding()] param(
    [string]$AdminGroup    = 'Intune Admins – Region A – Prod',
    [string]$ApproverGroup = 'Change Approvers – Apps – Prod'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

function Ensure-Group([string]$name) {
    $filter = "displayName eq '" + ($name -replace "'", "''") + "'"
    $found = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter={0}" -f [uri]::EscapeDataString($filter))).value
    if ($found) { Write-Host ("  EXISTS: '{0}' (id {1})" -f $name, $found[0].id) -ForegroundColor Green; return }
    $nick = ($name -replace '[^A-Za-z0-9]', '')
    $body = @{ displayName = $name; mailEnabled = $false; mailNickname = $nick; securityEnabled = $true } | ConvertTo-Json
    try {
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
        Write-Host ("  CREATED: '{0}' (id {1})" -f $name, $g.id) -ForegroundColor Green
    } catch { Write-Host ("  ERROR creating '{0}': {1}" -f $name, $_.Exception.Message) -ForegroundColor Red }
}

Write-Host "=== RBACGOV scope groups ===" -ForegroundColor Cyan
Ensure-Group $AdminGroup
Ensure-Group $ApproverGroup
Write-Host "`nAdd members in Entra, then target these groups on the role assignment and access policies." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
