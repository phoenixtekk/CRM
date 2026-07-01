<#
.SYNOPSIS
    NSSSO-Validation.ps1 — confirm Netskope SSO is configured and SCIM provisioning is enabled (read-only).
.DESCRIPTION
    PURPOSE
        Verifies that the Netskope enterprise application has SAML single sign-on set and that its
        SCIM provisioning job exists and is active — the two integration surfaces this solution
        configures on the Entra ID side. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSSSO-Validation.ps1
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Application.Read.All, Synchronization.Read.All.
    EXPECTED RESULTS
        "SSO + SCIM CONFIGURED" when SSO mode is saml and a provisioning job is active. Exit 0 on
        pass, 1 otherwise. Netskope-side SSO/SCIM specifics are deferred to the Netskope documentation.
.NOTES
    Network Solutions — Netskope + Entra ID SSO. Read-only. Netskope console specifics deferred.
#>
[CmdletBinding()]
param([string]$AppDisplayName = 'Netskope SSO - Corp - Prod')

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Synchronization.Read.All' -NoWelcome

Write-Host "=== Netskope SSO/SCIM validation ===" -ForegroundColor Cyan
$escaped = $AppDisplayName.Replace("'","''")
$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$escaped'").value | Select-Object -First 1
if (-not $sp) {
    Write-Host ("App '{0}' not found." -f $AppDisplayName) -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; exit 1
}

$ssoOk = ($sp.preferredSingleSignOnMode -eq 'saml')
Write-Host ("SAML SSO mode    : {0}" -f ($(if($ssoOk){'YES (saml)'}else{"NO ($($sp.preferredSingleSignOnMode))"}))) -ForegroundColor ($(if($ssoOk){'Green'}else{'Yellow'}))

$scimOk = $false
try {
    $jobs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs").value
    $active = $jobs | Where-Object { $_.status.code -in @('Active','Quarantine') -or $_.schedule.state -eq 'Active' }
    $scimOk = [bool]$active
    if ($jobs.Count -gt 0) { foreach ($j in $jobs) { Write-Host ("Provisioning job : {0}  status={1}" -f $j.templateId, $j.status.code) } }
    else { Write-Host "Provisioning job : none" -ForegroundColor Yellow }
} catch { Write-Host "Provisioning job : (unable to read)" -ForegroundColor Yellow }
Write-Host ("SCIM enabled     : {0}" -f ($(if($scimOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($scimOk){'Green'}else{'Yellow'}))

Disconnect-MgGraph | Out-Null
if ($ssoOk -and $scimOk) { Write-Host "`nResult: SSO + SCIM CONFIGURED" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT FULLY CONFIGURED — complete SAML SSO and/or enable SCIM provisioning (Implementation Steps 2-6)" -ForegroundColor Yellow; exit 1 }
