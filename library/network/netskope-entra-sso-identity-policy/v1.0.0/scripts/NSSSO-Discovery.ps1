<#
.SYNOPSIS
    NSSSO-Discovery.ps1 — Netskope + Entra ID SSO/SCIM readiness discovery (read-only).
.DESCRIPTION
    PURPOSE
        Reports the Netskope enterprise application in Entra ID, its SAML single sign-on mode, its
        SCIM provisioning status, and the identity scope groups — so you can assess readiness before
        configuring SSO and provisioning. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSSSO-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Application.Read.All, Group.Read.All.
    EXPECTED RESULTS
        The app's display name + object id, SSO mode, provisioning job status, and whether the
        pilot/production identity scope groups exist. Netskope-side SSO/SCIM specifics are deferred
        to the official Netskope documentation.
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
Connect-MgGraph -Scopes 'Application.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Netskope + Entra ID SSO/SCIM discovery ===" -ForegroundColor Cyan

# Enterprise application (service principal)
$escaped = $AppDisplayName.Replace("'","''")
$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$escaped'").value | Select-Object -First 1
if (-not $sp) {
    Write-Host ("Enterprise app   : NOT FOUND ('{0}') — create it (Implementation Step 1)." -f $AppDisplayName) -ForegroundColor Yellow
} else {
    Write-Host ("Enterprise app   : {0}  (id {1})" -f $sp.displayName, $sp.id) -ForegroundColor Green
    Write-Host ("SSO mode         : {0}" -f ($(if($sp.preferredSingleSignOnMode){$sp.preferredSingleSignOnMode}else{'not set (expect saml)'})))

    # SCIM provisioning sync job(s)
    $jobs = @()
    try { $jobs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs").value } catch {}
    if ($jobs.Count -gt 0) {
        foreach ($j in $jobs) { Write-Host ("Provisioning job : {0}  status={1}" -f $j.templateId, $j.status.code) }
    } else {
        Write-Host "Provisioning job : none (SCIM provisioning not yet enabled)" -ForegroundColor Yellow
    }

    # App role assignments (assigned users/groups count)
    try {
        $assign = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo").value
        Write-Host ("Assigned objects : {0}" -f $assign.Count)
    } catch { Write-Host "Assigned objects : (unable to read)" -ForegroundColor Yellow }
}

# Scope groups
foreach ($g in @($PilotGroup,$ProdGroup)) {
    $ge = $g.Replace("'","''")
    $grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ge'").value | Select-Object -First 1
    if ($grp) { Write-Host ("Group present    : {0}  (id {1})" -f $g, $grp.id) -ForegroundColor Green }
    else      { Write-Host ("Group missing    : {0} — create with NSSSO-Set-IdentityScopeTargeting.ps1" -f $g) -ForegroundColor Yellow }
}

Write-Host "`nNetskope-side SAML/SCIM configuration is deferred to the official Netskope documentation." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
