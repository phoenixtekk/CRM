<#
.SYNOPSIS
    APPCFG-Preflight.ps1 — confirm Graph scopes/roles and the correct cloud before app-config work (read-only).
.DESCRIPTION
    PURPOSE
        Pre-flight check before creating or editing App Configuration Policies. Connects to Microsoft
        Graph in the requested cloud (Commercial or US Government), confirms the delegated scopes the
        other APPCFG tools need are granted, and prints the signed-in identity, tenant, and cloud so
        you know you are pointed at the right environment. Read-only; makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Preflight.ps1
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Preflight.ps1 -Environment USGov
        Requires the Microsoft Graph SDK. Consents DeviceManagementApps.Read.All +
        DeviceManagementConfiguration.Read.All (read-only).
    EXPECTED RESULTS
        Signed-in user, tenant id, cloud, and a PASS/FAIL line per required scope.
        PASS = every required scope present and the expected cloud is connected.
.NOTES
    Intune Solutions — read-only. Cloud-aware (Commercial / USGov). No credentials stored.
.EXAMPLE
    .\APPCFG-Preflight.ps1 -Environment USGov
#>
[CmdletBinding()]
param(
    [ValidateSet('Global', 'USGov', 'USGovDoD')]
    [string]$Environment = 'Global'
)

$required = @('DeviceManagementApps.Read.All', 'DeviceManagementConfiguration.Read.All')

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph (CurrentUser)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

Write-Host "Connecting to Microsoft Graph (cloud: $Environment)..." -ForegroundColor Cyan
Connect-MgGraph -Scopes $required -Environment $Environment -NoWelcome

$ctx = Get-MgContext
if (-not $ctx) { Write-Host "FAIL: no Graph context — connection failed." -ForegroundColor Red; return }

Write-Host ""
Write-Host ("Account : {0}" -f $ctx.Account)
Write-Host ("Tenant  : {0}" -f $ctx.TenantId)
Write-Host ("Cloud   : {0}" -f $ctx.Environment)
Write-Host ""

$granted = @($ctx.Scopes)
$allOk = $true
foreach ($s in $required) {
    if ($granted -contains $s) {
        Write-Host ("PASS  scope {0}" -f $s) -ForegroundColor Green
    } else {
        Write-Host ("FAIL  scope {0} (not consented)" -f $s) -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host ""
if ($allOk) {
    Write-Host "Pre-flight PASS — scopes present. Proceed with the APPCFG tools." -ForegroundColor Green
} else {
    Write-Host "Pre-flight FAIL — reconnect and consent the missing scope(s)." -ForegroundColor Red
}
Disconnect-MgGraph | Out-Null
