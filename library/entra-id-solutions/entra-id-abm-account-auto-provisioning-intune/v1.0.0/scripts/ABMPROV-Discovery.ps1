<#
.SYNOPSIS
    ABMPROV-Discovery.ps1 — Entra ID + ABM federation / provisioning / ADE / APNs readiness (read-only).
.DESCRIPTION
    PURPOSE
        Reports the Entra "Apple Business Manager" provisioning application, its SCIM synchronization
        job status (Managed Apple ID provisioning), the Intune Apple MDM Push (APNs) certificate, and
        the Automated Device Enrollment (ADE) enrollment program token(s) — so you can assess
        readiness before federating and enrolling. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ABMPROV-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Application.Read.All, Synchronization.Read.All, DeviceManagementServiceConfig.Read.All,
        DeviceManagementConfiguration.Read.All, Group.Read.All.
    EXPECTED RESULTS
        The provisioning app + object id, the SCIM job status, the APNs certificate state/expiry, and
        each ADE token with its expiry. ABM-side federation/identity-provider configuration is
        deferred to Apple's official documentation.
.NOTES
    Entra ID Solutions — Entra ID + ABM federation & auto-provisioning. Read-only. ABM console deferred.
#>
[CmdletBinding()]
param(
    [string]$AppDisplayName = 'Apple Business Manager - Federation - Prod',
    [string]$PilotGroup     = 'Managed Apple ID Provisioning - Pilot - Stage'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Synchronization.Read.All','DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Entra ID + ABM federation / provisioning readiness ===" -ForegroundColor Cyan

# Provisioning application (service principal)
$escaped = $AppDisplayName.Replace("'","''")
$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$escaped'").value | Select-Object -First 1
if (-not $sp) {
    Write-Host ("Provisioning app : NOT FOUND ('{0}') — add it from the gallery (Implementation Step 2)." -f $AppDisplayName) -ForegroundColor Yellow
} else {
    Write-Host ("Provisioning app : {0}  (id {1})" -f $sp.displayName, $sp.id) -ForegroundColor Green
    $jobs = @()
    try { $jobs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs").value } catch {}
    if ($jobs.Count -gt 0) {
        foreach ($j in $jobs) { Write-Host ("SCIM job         : {0}  status={1}" -f $j.templateId, $j.status.code) }
    } else {
        Write-Host "SCIM job         : none (Managed Apple ID provisioning not yet enabled)" -ForegroundColor Yellow
    }
    try {
        $assign = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo").value
        Write-Host ("Assigned scope   : {0} object(s)" -f $assign.Count)
    } catch { Write-Host "Assigned scope   : (unable to read)" -ForegroundColor Yellow }
}

# APNs certificate
Write-Host "`n-- Apple MDM Push (APNs) certificate --" -ForegroundColor Cyan
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/applePushNotificationCertificate"
    if ($apns) {
        Write-Host ("APNs Apple ID    : {0}" -f $apns.appleIdentifier)
        Write-Host ("APNs expiry      : {0}" -f $apns.expirationDateTime)
        if ($apns.expirationDateTime) {
            $days = ([datetime]$apns.expirationDateTime - (Get-Date)).Days
            if ($days -lt 30) { Write-Host ("APNs WARNING     : expires in {0} day(s) — renew soon." -f $days) -ForegroundColor Yellow }
            else { Write-Host ("APNs status      : OK ({0} days remaining)" -f $days) -ForegroundColor Green }
        }
    } else { Write-Host "APNs certificate : NOT configured — create it (Implementation Step 7)." -ForegroundColor Yellow }
} catch { Write-Host "APNs certificate : NOT configured — create it (Implementation Step 7)." -ForegroundColor Yellow }

# ADE enrollment program tokens (depOnboardingSettings)
Write-Host "`n-- ADE enrollment program token(s) --" -ForegroundColor Cyan
try {
    $deps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/depOnboardingSettings").value
    if (-not $deps -or $deps.Count -eq 0) {
        Write-Host "ADE token        : none — connect ABM to Intune (Implementation Step 8)." -ForegroundColor Yellow
    } else {
        foreach ($d in $deps) {
            Write-Host ("ADE token        : {0}  expiry={1}" -f $d.tokenName, $d.tokenExpirationDateTime)
            if ($d.tokenExpirationDateTime) {
                $td = ([datetime]$d.tokenExpirationDateTime - (Get-Date)).Days
                if ($td -lt 30) { Write-Host ("ADE WARNING      : token expires in {0} day(s) — renew." -f $td) -ForegroundColor Yellow }
            }
        }
    }
} catch { Write-Host "ADE token        : (unable to read depOnboardingSettings)" -ForegroundColor Yellow }

# Pilot scope group
$ge = $PilotGroup.Replace("'","''")
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ge'").value | Select-Object -First 1
if ($grp) { Write-Host ("`nPilot group      : {0}  (id {1})" -f $PilotGroup, $grp.id) -ForegroundColor Green }
else      { Write-Host ("`nPilot group      : missing — create with ABMPROV-Set-ScopeTargeting.ps1" -f $PilotGroup) -ForegroundColor Yellow }

Write-Host "`nABM-side federation / identity-provider setup is deferred to Apple's official documentation." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
