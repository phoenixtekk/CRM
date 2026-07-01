<#
.SYNOPSIS
    CPKI-Discovery.ps1 — cloud PKI + Intune readiness: certificate connectors and cert profiles (Graph).
.DESCRIPTION
    PURPOSE
        Enumerates the tenant's Intune certificate connectors (and their health/last check-in) and
        the existing certificate-related device configuration profiles (Trusted certificate, SCEP,
        PKCS), so you can confirm the cloud PKI's Intune connector is connected and see what cert
        infrastructure already exists before you configure issuance. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPKI-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and consent to:
        DeviceManagementConfiguration.Read.All, DeviceManagementServiceConfig.Read.All.
    EXPECTED RESULTS
        A list of certificate connectors with status/last-connection, and a list of trusted-cert /
        SCEP / PKCS profiles with their assigned group IDs. Flags if no connector is found.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
    Cloud-PKI PRODUCT-specific issuance APIs are deferred to the vendor's documentation; this script
    only reads the Intune/Graph side (deviceManagement certificate connectors + deviceConfigurations).
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementServiceConfig.Read.All' -NoWelcome

function Get-AssignedGroups([string]$id) {
    try {
        (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$id/assignments").value |
            ForEach-Object { $_.target.groupId } | Where-Object { $_ }
    } catch { @() }
}

Write-Host "`n=== Cloud PKI / Intune certificate connectors ===" -ForegroundColor Cyan
try {
    $connectors = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/ndesConnectors').value
} catch { $connectors = @() }
if ($connectors) {
    foreach ($c in $connectors) {
        Write-Host ("  {0}  state={1}  lastConnection={2}" -f $c.displayName, $c.state, $c.lastConnectionDateTime)
    }
} else {
    Write-Host "  No certificate (NDES/SCEP) connectors returned. Confirm the cloud PKI's Intune" -ForegroundColor Yellow
    Write-Host "  connector/plugin is registered (vendor docs) and check Intune > Tenant administration >" -ForegroundColor Yellow
    Write-Host "  Connectors and tokens > Certificate connectors." -ForegroundColor Yellow
}

Write-Host "`n=== Certificate device configuration profiles ===" -ForegroundColor Cyan
$cfgs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceConfigurations').value
$trusted = $cfgs | Where-Object { $_.'@odata.type' -match 'trustedRootCertificate|trustedCertificate' }
$scep    = $cfgs | Where-Object { $_.'@odata.type' -match 'scepCertificate' }
$pkcs    = $cfgs | Where-Object { $_.'@odata.type' -match 'pkcsCertificate' }

Write-Host "-- Trusted certificate profiles --"
foreach ($t in $trusted) { Write-Host ("  {0}  [groups: {1}]" -f $t.displayName, ((Get-AssignedGroups $t.id) -join ', ')) }
Write-Host "-- SCEP certificate profiles --"
foreach ($s in $scep)    { Write-Host ("  {0}  [groups: {1}]" -f $s.displayName, ((Get-AssignedGroups $s.id) -join ', ')) }
Write-Host "-- PKCS certificate profiles --"
foreach ($p in $pkcs)    { Write-Host ("  {0}  [groups: {1}]" -f $p.displayName, ((Get-AssignedGroups $p.id) -join ', ')) }

if (-not ($trusted -or $scep -or $pkcs)) {
    Write-Host "  No certificate profiles found yet — expected on a fresh tenant." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
