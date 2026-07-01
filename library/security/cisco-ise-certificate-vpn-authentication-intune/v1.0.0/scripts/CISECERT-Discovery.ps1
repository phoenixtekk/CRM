<#
.SYNOPSIS
    CISECERT-Discovery.ps1 — certificate readiness: Intune certificate connectors + cert profiles (Graph).
.DESCRIPTION
    PURPOSE
        Enumerates the tenant's Intune certificate connectors (state / last check-in) and the existing
        certificate device configuration profiles (Trusted certificate, SCEP, PKCS) with their assigned
        groups, so you can confirm the certificate infrastructure for Cisco EAP-TLS VPN is in place
        before you issue certificates. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISECERT-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and consent to:
        DeviceManagementConfiguration.Read.All, DeviceManagementServiceConfig.Read.All.
    EXPECTED RESULTS
        A list of certificate connectors with state / last-connection, and a list of trusted-cert /
        SCEP / PKCS profiles with their assigned group IDs. Flags if no connector or profile is found.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE internals deferred to vendor docs.
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

Write-Host "`n=== Intune certificate connectors (SCEP/NDES/PKCS) ===" -ForegroundColor Cyan
try {
    $connectors = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/ndesConnectors').value
} catch { $connectors = @() }
if ($connectors) {
    foreach ($c in $connectors) {
        Write-Host ("  {0}  state={1}  lastConnection={2}" -f $c.displayName, $c.state, $c.lastConnectionDateTime)
    }
} else {
    Write-Host "  No certificate (NDES/SCEP) connectors returned. If you issue from an on-prem CA, confirm" -ForegroundColor Yellow
    Write-Host "  the Intune Certificate Connector is installed and active: Intune > Tenant administration >" -ForegroundColor Yellow
    Write-Host "  Connectors and tokens > Certificate connectors. (A Cloud PKI with native SCEP may not appear here.)" -ForegroundColor Yellow
}

Write-Host "`n=== Certificate device configuration profiles ===" -ForegroundColor Cyan
$cfgs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceConfigurations').value
$trusted = $cfgs | Where-Object { $_.'@odata.type' -match 'trustedRootCertificate|trustedCertificate' }
$scep    = $cfgs | Where-Object { $_.'@odata.type' -match 'scepCertificate' }
$pkcs    = $cfgs | Where-Object { $_.'@odata.type' -match 'pkcsCertificate' }

Write-Host "-- Trusted certificate profiles (expect: Cisco VPN - Trusted Root) --"
foreach ($t in $trusted) { Write-Host ("  {0}  [groups: {1}]" -f $t.displayName, ((Get-AssignedGroups $t.id) -join ', ')) }
Write-Host "-- SCEP certificate profiles (expect: Cisco VPN - SCEP Device/User Cert) --"
foreach ($s in $scep)    { Write-Host ("  {0}  [groups: {1}]" -f $s.displayName, ((Get-AssignedGroups $s.id) -join ', ')) }
Write-Host "-- PKCS certificate profiles (expect: Cisco VPN - PKCS User Cert) --"
foreach ($p in $pkcs)    { Write-Host ("  {0}  [groups: {1}]" -f $p.displayName, ((Get-AssignedGroups $p.id) -join ', ')) }

if (-not ($trusted -or $scep -or $pkcs)) {
    Write-Host "  No certificate profiles found yet — expected before Implementation Steps 2-3." -ForegroundColor Yellow
}

Write-Host "`nReadiness gate: a certificate connector (or Cloud PKI SCEP) is active AND the Trusted Root +" -ForegroundColor Yellow
Write-Host "SCEP/PKCS profiles exist and are assigned to PILOT - Cisco Cert VPN Users." -ForegroundColor Yellow
Disconnect-MgGraph | Out-Null
