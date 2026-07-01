<#
.SYNOPSIS
    NSSSO-Report.ps1 — Netskope SSO/SCIM coverage report (read-only).
.DESCRIPTION
    PURPOSE
        Reports the Netskope enterprise application's SSO mode, SCIM provisioning status, the groups
        and users assigned to the app (the SSO + provisioning scope), and the membership of the
        identity scope groups — so you can audit identity coverage. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSSSO-Report.ps1
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Application.Read.All, Group.Read.All, Synchronization.Read.All.
    EXPECTED RESULTS
        A coverage report: SSO mode, provisioning status, assigned groups/users, and scope-group
        member counts. Netskope-side provisioned-object state is deferred to the Netskope console.
.NOTES
    Network Solutions — Netskope + Entra ID SSO. Read-only. Netskope console specifics deferred.
#>
[CmdletBinding()]
param(
    [string]$AppDisplayName = 'Netskope SSO - Corp - Prod',
    [string]$PilotGroup     = 'Netskope Identity - Pilot - Stage',
    [string]$ProdGroup      = 'Netskope Identity - Corp - Prod'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Group.Read.All','Synchronization.Read.All' -NoWelcome

function Resolve-Name($id) {
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/directoryObjects/$id").displayName } catch { $id }
}

Write-Host "`n=== Netskope SSO/SCIM coverage report ===" -ForegroundColor Cyan
$escaped = $AppDisplayName.Replace("'","''")
$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$escaped'").value | Select-Object -First 1
if (-not $sp) { Write-Host ("App '{0}' not found." -f $AppDisplayName) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

Write-Host ("App              : {0}" -f $sp.displayName)
Write-Host ("SSO mode         : {0}" -f ($(if($sp.preferredSingleSignOnMode){$sp.preferredSingleSignOnMode}else{'not set'})))

try {
    $jobs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs").value
    if ($jobs.Count -gt 0) { foreach ($j in $jobs) { Write-Host ("Provisioning     : {0}  status={1}  lastRun={2}" -f $j.templateId, $j.status.code, $j.status.lastSuccessfulExecution.timeBegan) } }
    else { Write-Host "Provisioning     : none" -ForegroundColor Yellow }
} catch { Write-Host "Provisioning     : (unable to read)" -ForegroundColor Yellow }

Write-Host "`n-- Assigned to app (SSO + SCIM scope) --" -ForegroundColor Cyan
try {
    $assign = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo").value
    if ($assign.Count -eq 0) { Write-Host "  (none assigned)" -ForegroundColor Yellow }
    foreach ($a in $assign) { Write-Host ("  {0}  ({1})" -f $a.principalDisplayName, $a.principalType) }
} catch { Write-Host "  (unable to read assignments)" -ForegroundColor Yellow }

Write-Host "`n-- Identity scope groups --" -ForegroundColor Cyan
foreach ($g in @($PilotGroup,$ProdGroup)) {
    $ge = $g.Replace("'","''")
    $grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ge'").value | Select-Object -First 1
    if (-not $grp) { Write-Host ("  {0} : MISSING" -f $g) -ForegroundColor Yellow; continue }
    $members = @()
    try { $members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=id").value } catch {}
    Write-Host ("  {0} : {1} member(s)" -f $g, $members.Count) -ForegroundColor Green
}

Write-Host "`nProvisioned-object state inside Netskope is deferred to the Netskope console/documentation." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
