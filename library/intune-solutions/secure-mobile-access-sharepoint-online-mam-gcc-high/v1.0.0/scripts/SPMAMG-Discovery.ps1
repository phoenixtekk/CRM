<#
.SYNOPSIS
    SPMAMG-Discovery.ps1 — GCC High sovereign-cloud check + inventory of App Protection and CA policies.
.DESCRIPTION
    PURPOSE
        Confirms you are targeting the US Government (GCC High) cloud, then inventories the objects this
        solution depends on: Intune App Protection Policies (iOS/Android) and Conditional Access policies.
        Read-only. Run it first, before making any changes, to avoid colliding with existing config.
        Replace placeholders like your-tenant-id only if you pin a tenant; none are required to run.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SPMAMG-Discovery.ps1
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','DeviceManagementApps.Read.All'
    EXPECTED RESULTS
        Graph host = graph.microsoft.us (USGov), a count of iOS/Android App Protection Policies, and a
        Conditional Access policy count. PASS when the environment shows USGov; FAIL/wrong-cloud if it
        shows graph.microsoft.com.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param()

Write-Host "=== Secure Mobile Access to SharePoint (GCC High) — discovery ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','DeviceManagementApps.Read.All' -NoWelcome

$ctx = Get-MgContext
$env = $ctx.Environment
Write-Host ("Graph environment : {0}" -f $env) -ForegroundColor ($(if($env -eq 'USGov'){'Green'}else{'Red'}))
if ($env -ne 'USGov') {
    Write-Host "WRONG CLOUD: not connected to US Gov (graph.microsoft.us). Reconnect with -Environment USGov." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null; return
}
Write-Host "Graph host        : https://graph.microsoft.us (GCC High)" -ForegroundColor Green

# --- App Protection Policies (MAM) ---
try {
    $ios = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/iosManagedAppProtections').value
    $and = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceAppManagement/androidManagedAppProtections').value
    Write-Host ("`nApp Protection Policies: iOS {0}  |  Android {1}" -f $ios.Count, $and.Count) -ForegroundColor Cyan
    $ios + $and | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }
} catch {
    Write-Host "Could not read App Protection Policies (check scope DeviceManagementApps.Read.All)." -ForegroundColor Yellow
}

# --- Conditional Access inventory ---
try {
    $pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
    $enf = ($pols | Where-Object state -eq 'enabled').Count
    $ro  = ($pols | Where-Object state -eq 'enabledForReportingButNotEnforced').Count
    $off = ($pols | Where-Object state -eq 'disabled').Count
    Write-Host ("`nConditional Access policies: {0} total  |  enforced {1}  |  report-only {2}  |  disabled {3}" -f $pols.Count, $enf, $ro, $off) -ForegroundColor Cyan
} catch {
    Write-Host "Could not read CA policies (check role / scope Policy.Read.All)." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
