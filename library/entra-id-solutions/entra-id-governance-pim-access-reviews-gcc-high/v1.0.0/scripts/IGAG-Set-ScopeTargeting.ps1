<#
.SYNOPSIS
    IGAG-Set-ScopeTargeting.ps1 — build the GCC High governance-scope and approver groups for PIM/reviews/packages.
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the security groups the governance model targets in a US Government
        (GCC High/DoD) tenant: a pilot governance scope group and an approver group used by PIM
        activation approval and access-package requests. Optionally seeds members by UPN. Consistent
        group names make PIM, access reviews, and entitlement-management policies repeatable. Runs in
        -WhatIf (preview) mode by default; add -WhatIf:$false to create/modify. Use USGovDoD on DoD.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\IGAG-Set-ScopeTargeting.ps1 -ApproverUpns "alice@your-tenant.onmicrosoft.us","bob@your-tenant.onmicrosoft.us"
        Apply:            add -WhatIf:$false to the same command after reviewing the preview.
        Connects to US Gov Graph (-Environment USGov). Scopes: Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        The scope and approver groups exist (created if missing) with the requested members; their
        object IDs are printed for use in PIM policy, access reviews, and access packages.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]$ScopeGroupName    = 'IGAG Pilot – Governance Scope – Pilot',
    [string]$ApproverGroupName = 'IGAG Approvers – Privileged Roles – Pilot',
    [string[]]$ScopeUpns    = @(),
    [string[]]$ApproverUpns = @(),
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome
Write-Host "=== IGAG Scope Targeting (GCC High, env: $Environment) ===" -ForegroundColor Cyan

function Get-OrNewGroup([string]$name) {
    $esc = $name.Replace("'","''")
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$esc'").value | Select-Object -First 1
    if ($g) { Write-Host ("  exists : {0} ({1})" -f $name, $g.id); return $g }
    if (-not $PSCmdlet.ShouldProcess($name, "Create security group")) { Write-Host ("  WHATIF would create group: {0}" -f $name) -ForegroundColor Yellow; return $null }
    $mail = ($name -replace '[^a-zA-Z0-9]','').ToLower()
    $body = @{ displayName=$name; mailEnabled=$false; mailNickname=$mail; securityEnabled=$true }
    $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host ("  created: {0} ({1})" -f $name, $g.id) -ForegroundColor Green
    return $g
}
function Add-Members($group, [string[]]$upns) {
    if (-not $group) { return }
    foreach ($upn in $upns) {
        if (-not $PSCmdlet.ShouldProcess($upn, "Add to group $($group.displayName)")) { Write-Host ("    WHATIF would add: {0}" -f $upn) -ForegroundColor Yellow; continue }
        try {
            $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn")
            $ref = @{ '@odata.id' = "https://graph.microsoft.us/v1.0/directoryObjects/$($u.id)" }
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($group.id)/members/`$ref" -Body ($ref | ConvertTo-Json) | Out-Null
            Write-Host ("    + {0}" -f $upn) -ForegroundColor Green
        } catch { Write-Host ("    ! {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
    }
}

$scope    = Get-OrNewGroup $ScopeGroupName
$approver = Get-OrNewGroup $ApproverGroupName
if ($ScopeUpns)    { Write-Host "Adding scope members:";    Add-Members $scope    $ScopeUpns }
if ($ApproverUpns) { Write-Host "Adding approver members:"; Add-Members $approver $ApproverUpns }

Write-Host "`nUse these group IDs in PIM activation approval, access reviews, and access-package policies:" -ForegroundColor Cyan
if ($scope)    { Write-Host ("  Scope group    : {0}" -f $scope.id) }
if ($approver) { Write-Host ("  Approver group : {0}" -f $approver.id) }
Disconnect-MgGraph | Out-Null
