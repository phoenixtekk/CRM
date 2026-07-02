<#
.SYNOPSIS
    IGA-Set-ScopeTargeting.ps1 — build the governance-scope and approver groups for PIM/reviews/packages.
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the security groups the governance model targets: a pilot governance
        scope group and an approver group used by PIM activation approval and access-package requests.
        Optionally seeds members by UPN. Consistent group names make PIM, access reviews, and
        entitlement-management policies repeatable across the tenant.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IGA-Set-ScopeTargeting.ps1 `
            -ScopeGroupName "IGA Pilot – Governance Scope – Pilot" `
            -ApproverGroupName "IGA Approvers – Privileged Roles – Pilot" `
            -ApproverUpns "alice@contoso.com","bob@contoso.com"
        Requires the Microsoft Graph PowerShell SDK. Scopes: Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        The scope and approver groups exist (created if missing) with the requested members; their
        object IDs are printed for use in PIM policy, access reviews, and access packages.
.NOTES
    White-label — Entra ID Solutions. Creates/updates groups.
#>
[CmdletBinding()]
param(
    [string]$ScopeGroupName    = 'IGA Pilot – Governance Scope – Pilot',
    [string]$ApproverGroupName = 'IGA Approvers – Privileged Roles – Pilot',
    [string[]]$ScopeUpns    = @(),
    [string[]]$ApproverUpns = @()
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome
Write-Host "=== IGA Scope Targeting ===" -ForegroundColor Cyan

function Get-OrNewGroup([string]$name) {
    $esc = $name.Replace("'","''")
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$esc'").value | Select-Object -First 1
    if ($g) { Write-Host ("  exists : {0} ({1})" -f $name, $g.id); return $g }
    $mail = ($name -replace '[^a-zA-Z0-9]','').ToLower()
    $body = @{ displayName=$name; mailEnabled=$false; mailNickname=$mail; securityEnabled=$true }
    $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host ("  created: {0} ({1})" -f $name, $g.id) -ForegroundColor Green
    return $g
}
function Add-Members($group, [string[]]$upns) {
    foreach ($upn in $upns) {
        try {
            $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn")
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" }
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
Write-Host ("  Scope group    : {0}" -f $scope.id)
Write-Host ("  Approver group : {0}" -f $approver.id)
Disconnect-MgGraph | Out-Null
