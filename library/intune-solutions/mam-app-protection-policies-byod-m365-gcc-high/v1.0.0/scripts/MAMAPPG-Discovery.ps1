<#
.SYNOPSIS
    MAMAPPG-Discovery.ps1 — confirm the GCC High cloud, then inventory MAM App Protection / App Configuration policies and the CA app-protection grant.
.DESCRIPTION
    PURPOSE
        Confirms you are targeting the US Government (GCC High) cloud (Graph must be graph.microsoft.us),
        then enumerates the tenant's iOS and Android App Protection Policies, managed-app App
        Configuration policies, and any Conditional Access policy that grants 'Require app protection
        policy'. Read-only. Use it first, before making any changes. Uses placeholders like
        your-tenant-id (no angle brackets).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MAMAPPG-Discovery.ps1
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementApps.Read.All','Policy.Read.All'
    EXPECTED RESULTS
        Graph environment = USGov (graph.microsoft.us), then a list of iOS/Android App Protection
        Policies, App Configuration policies, and any CA policy requiring app protection / approved app.
        PASS when the environment shows USGov; FAIL/wrong-cloud if it shows graph.microsoft.com.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementApps.Read.All','Policy.Read.All' -NoWelcome

$envName = (Get-MgContext).Environment
Write-Host ("Graph environment : {0}" -f $envName) -ForegroundColor ($(if($envName -eq 'USGov'){'Green'}else{'Red'}))
if ($envName -ne 'USGov') {
    Write-Host "WRONG CLOUD: not connected to US Gov (graph.microsoft.us). Reconnect with -Environment USGov." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit 1
}
Write-Host "Graph host        : https://graph.microsoft.us (GCC High)" -ForegroundColor Green

Write-Host "`n=== iOS App Protection Policies ===" -ForegroundColor Cyan
$ios = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/iosManagedAppProtections').value
if ($ios) { foreach ($p in $ios) { Write-Host ("  {0}" -f $p.displayName) } } else { Write-Host "  none" -ForegroundColor Yellow }

Write-Host "=== Android App Protection Policies ===" -ForegroundColor Cyan
$and = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/androidManagedAppProtections').value
if ($and) { foreach ($p in $and) { Write-Host ("  {0}" -f $p.displayName) } } else { Write-Host "  none" -ForegroundColor Yellow }

Write-Host "=== App Configuration Policies (managed apps) ===" -ForegroundColor Cyan
$cfg = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/targetedManagedAppConfigurations').value
if ($cfg) { foreach ($c in $cfg) { Write-Host ("  {0}" -f $c.displayName) } } else { Write-Host "  none" -ForegroundColor Yellow }

Write-Host "=== Conditional Access — Require app protection policy ===" -ForegroundColor Cyan
$ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$appCa = $ca | Where-Object { $_.grantControls -and ($_.grantControls.builtInControls -contains 'compliantApplication' -or $_.grantControls.builtInControls -contains 'approvedApplication') }
if ($appCa) { foreach ($c in $appCa) { Write-Host ("  {0}  [state: {1}]" -f $c.displayName, $c.state) } } else { Write-Host "  no CA policy requires app protection / approved app" -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
