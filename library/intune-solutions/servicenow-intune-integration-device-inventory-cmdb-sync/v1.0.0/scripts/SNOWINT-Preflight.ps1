<#
.SYNOPSIS
    SNOWINT-Preflight.ps1 — verify the Entra app registration ServiceNow uses can read Intune.
.DESCRIPTION
    PURPOSE
        Confirms the Microsoft side of the ServiceNow <-> Intune CMDB feed is ready: that the
        signed-in identity can reach Graph, that the read-only device-management scopes are present,
        and that managed devices are actually readable. Run this BEFORE configuring the ServiceNow
        connection so a broken app registration / missing admin consent is caught early.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SNOWINT-Preflight.ps1 [-Cloud Global|USGov|USGovDoD]
        Requires the Microsoft.Graph PowerShell SDK. Sign in as an admin who can read device mgmt.
        (This checks the tenant is ready; the ServiceNow connection itself uses the app's client
        secret via client-credentials — configure that in ServiceNow, not here.)
    EXPECTED RESULTS
        Green PASS lines for: Graph connect, each expected scope, and a managed-device read count.
        Any red FAIL tells you exactly what to fix (missing scope, no consent, no devices).
.NOTES
    Intune Solutions — read-only. Cloud-aware (Global / USGov / USGovDoD).
#>
[CmdletBinding()]
param([ValidateSet('Global','USGov','USGovDoD')][string]$Cloud = 'Global')

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$expected = @(
    'DeviceManagementManagedDevices.Read.All',
    'DeviceManagementApps.Read.All',
    'DeviceManagementServiceConfig.Read.All',
    'Directory.Read.All'
)

Write-Host "=== SNOWINT Preflight ($Cloud) ===" -ForegroundColor Cyan
try {
    Connect-MgGraph -Scopes $expected -Environment $Cloud -NoWelcome
    Write-Host "  PASS  Connected to Microsoft Graph ($Cloud)." -ForegroundColor Green
} catch {
    Write-Host "  FAIL  Could not connect to Graph: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$ctx = Get-MgContext
$granted = @($ctx.Scopes)
foreach ($s in $expected) {
    if ($granted -contains $s) { Write-Host "  PASS  Scope present: $s" -ForegroundColor Green }
    else { Write-Host "  WARN  Scope not in this token: $s (confirm it is app-consented for the ServiceNow app)" -ForegroundColor Yellow }
}

# Managed-device read test (the core inventory the ServiceNow connector imports)
$base = switch ($Cloud) {
    'USGov'    { 'https://graph.microsoft.us' }
    'USGovDoD' { 'https://dod-graph.microsoft.us' }
    default    { 'https://graph.microsoft.com' }
}
try {
    $resp = Invoke-MgGraphRequest -Method GET -Uri "$base/v1.0/deviceManagement/managedDevices?`$top=5"
    $count = @($resp.value).Count
    if ($count -gt 0) { Write-Host "  PASS  Managed devices are readable (sample returned $count)." -ForegroundColor Green }
    else { Write-Host "  WARN  Connected, but 0 managed devices returned — confirm devices are enrolled." -ForegroundColor Yellow }
} catch {
    Write-Host "  FAIL  Could not read managedDevices: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host "`nPreflight complete. Fix any FAIL/WARN before configuring the ServiceNow connection." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
