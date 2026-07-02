<#
.SYNOPSIS
    DYNTGT-Discovery.ps1 — inventory dynamic security groups and assignment filters (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Lists Entra dynamic device groups with their membership rules, and Intune assignment filters
        with their rules and platform, so you can audit the current dynamic targeting taxonomy.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DYNTGT-Discovery.ps1
        Requires Microsoft Graph SDK and scopes Group.Read.All, DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A list of dynamic device groups (name + membership rule) and assignment filters (name,
        platform, rule).
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

Write-Host "=== Dynamic device groups (membership rules) ===" -ForegroundColor Cyan
$uri = "/v1.0/groups?`$filter=groupTypes/any(c:c eq 'DynamicMembership')&`$select=id,displayName,membershipRule,membershipRuleProcessingState"
$groups = @(); do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $groups += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
foreach ($g in $groups) { Write-Host ("  {0}`n     rule: {1}  [{2}]" -f $g.displayName, $g.membershipRule, $g.membershipRuleProcessingState) }
if (-not $groups) { Write-Host "  No dynamic groups found." -ForegroundColor Yellow }

Write-Host "`n=== Assignment filters ===" -ForegroundColor Cyan
$filters = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/assignmentFilters').value
foreach ($f in $filters) { Write-Host ("  {0}  [{1}]`n     rule: {2}" -f $f.displayName, $f.platform, $f.rule) }
if (-not $filters) { Write-Host "  No assignment filters found." -ForegroundColor Yellow }

Write-Host ("`nTotals: {0} dynamic groups, {1} filters" -f $groups.Count, $filters.Count) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
