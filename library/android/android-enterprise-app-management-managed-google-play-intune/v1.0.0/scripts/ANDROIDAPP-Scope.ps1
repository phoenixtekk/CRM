<#
.SYNOPSIS
    ANDROIDAPP-Scope.ps1 — managed Google Play binding + app-sync health and scope pre-flight (read-only, Graph).
.DESCRIPTION
    PURPOSE
        Pre-flight check before app work: reports the managed Google Play (Android managed store account
        enterprise) binding — bind status, owner, enrollment target, and the LAST APP SYNC status/time —
        plus a count of managed Google Play apps and app-config policies currently in the tenant. A stale
        or errored sync is the top reason an approved app never reaches devices.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDAPP-Scope.ps1
        Requires the Microsoft Graph SDK and DeviceManagementConfiguration.Read.All + DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        Binding status + last app-sync time, and app/config counts. PASS = bound, sync recent/successful.
.NOTES
    White-label — Android Solutions. Read-only against Microsoft Graph. No credentials stored.
.EXAMPLE
    .\ANDROIDAPP-Scope.ps1 -WhatIf
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' -NoWelcome

Write-Host "`n=== Managed Google Play binding / sync health ===" -ForegroundColor Cyan
try {
    $s = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings"
    Write-Host ("Bind status         : {0}" -f $s.bindStatus)
    Write-Host ("Owner UPN           : {0}" -f $s.ownerUserPrincipalName)
    Write-Host ("Enrollment target   : {0}" -f $s.enrollmentTarget)
    Write-Host ("Last app sync status: {0}" -f $s.lastAppSyncStatus) -ForegroundColor ($(if ($s.lastAppSyncStatus -eq 'success') { 'Green' } else { 'Yellow' }))
    Write-Host ("Last app sync time  : {0}" -f $s.lastAppSyncDateTime)
    if ($s.lastAppSyncDateTime) {
        $age = (Get-Date) - [datetime]$s.lastAppSyncDateTime
        if ($age.TotalHours -gt 24) { Write-Host ("  WARNING: last sync was {0:N0}h ago — apps may be stale." -f $age.TotalHours) -ForegroundColor Yellow }
    }
} catch {
    Write-Host "Could not read androidManagedStoreAccountEnterpriseSettings — the managed Google Play binding may not exist, or your tenant uses the Google Workspace EMM model. Verify against current Microsoft guidance / your tenant." -ForegroundColor Yellow
}

# App + config counts (scope snapshot).
$androidTypes = @('#microsoft.graph.androidManagedStoreApp','#microsoft.graph.androidManagedStoreWebApp')
$apps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps").value | Where-Object { $androidTypes -contains $_.'@odata.type' }
$cfgs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileAppConfigurations").value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.androidManagedStoreAppConfiguration' }
Write-Host ("`nManaged Google Play apps in tenant : {0}" -f $apps.Count) -ForegroundColor Cyan
Write-Host ("Android app-config policies        : {0}" -f $cfgs.Count) -ForegroundColor Cyan
Write-Host "`n(Run ANDROIDAPP-Discovery.ps1 for per-app assignment posture, ANDROIDAPP-Validation.ps1 for the four gates.)" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
