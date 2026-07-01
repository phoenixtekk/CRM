<#
.SYNOPSIS
    CISEDIAG-Check-Compliance.ps1 — read the device compliance/enrollment state as ISE would read it (via Graph).
.DESCRIPTION
    PURPOSE
        Reads a managed device's compliance, enrollment, management, and ownership state from Microsoft
        Intune through Microsoft Graph — the same signal Cisco ISE consumes over the Entra-to-ISE
        compliance connector when it authorizes a session. Use it in Branch E to decide whether a
        quarantine is a genuine non-compliance (fix the device) or a connector/identity problem (Intune
        says compliant, ISE disagrees). Supports interactive sign-in, or app-only with your-tenant-id /
        your-client-id / your-cert-thumbprint. Read-only: read scopes only, no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-Compliance.ps1 -DeviceName your-device-name

        Interactive (delegated):
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Directory.Read.All"
        App-only:
            powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-Compliance.ps1 -DeviceName your-device-name -TenantId your-tenant-id -ClientId your-client-id -CertThumbprint your-cert-thumbprint
        Required Graph scopes: DeviceManagementManagedDevices.Read.All, Directory.Read.All
    EXPECTED RESULTS
        A table of ComplianceState / ManagementState / enrollment / ownership per matching device.
        Compliant + managed => posture signal is good; if ISE still quarantines, suspect the connector
        (Branch F / Branch E step 3). Non-compliant => genuine policy failure; read which policy fails
        in Intune. Not enrolled/Unknown => enrollment problem (Branch A step 3).
.NOTES
    White-label — the repeatable way. Read-only. Cisco ISE / Secure Client internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $DeviceName = $env:COMPUTERNAME,
    [string] $TenantId,
    [string] $ClientId,
    [string] $CertThumbprint,
    [string] $JsonOut
)

$ErrorActionPreference = 'Stop'
Write-Host "CISEDIAG-Check-Compliance : reading Intune compliance via Graph (read-only)" -ForegroundColor Cyan

# Ensure the Graph SDK is available.
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement)) {
    Write-Warning "Microsoft.Graph.DeviceManagement not installed. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
}

try {
    $ctx = Get-MgContext -ErrorAction SilentlyContinue
    if (-not $ctx) {
        if ($TenantId -and $ClientId -and $CertThumbprint) {
            Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertThumbprint -NoWelcome
        } else {
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Directory.Read.All" -NoWelcome
        }
        $ctx = Get-MgContext
    }
    Write-Host ("Connected as {0} (AuthType: {1})" -f $ctx.Account, $ctx.AuthType) -ForegroundColor Gray
} catch {
    Write-Error "Graph connection failed: $($_.Exception.Message)"
    return
}

$devices = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$DeviceName'" -ErrorAction SilentlyContinue
if (-not $devices) {
    Write-Host "RESULT: No managed device named '$DeviceName' in Intune -> device is Not enrolled/Unknown to ISE (Branch A step 3)." -ForegroundColor Yellow
    return
}

$out = $devices | Select-Object DeviceName, Id, AzureAdDeviceId, ComplianceState, ManagementState,
    ManagedDeviceOwnerType, EnrolledDateTime, LastSyncDateTime, OperatingSystem, OsVersion
$out | Format-Table DeviceName, ComplianceState, ManagementState, ManagedDeviceOwnerType, LastSyncDateTime -AutoSize

foreach ($d in $out) {
    switch ($d.ComplianceState) {
        'compliant'    { Write-Host "  $($d.DeviceName): COMPLIANT -> if ISE still quarantines, suspect the Entra-to-ISE connector (Branch F / E step 3)." -ForegroundColor Green }
        'noncompliant' { Write-Host "  $($d.DeviceName): NON-COMPLIANT -> genuine policy failure; read the failing compliance policy in Intune." -ForegroundColor Yellow }
        default        { Write-Host "  $($d.DeviceName): compliance '$($d.ComplianceState)' -> unknown/unenrolled to ISE (Branch A step 3)." -ForegroundColor Yellow }
    }
}

if ($JsonOut) { $out | ConvertTo-Json -Depth 4 | Out-File $JsonOut -Encoding utf8; Write-Host "Wrote $JsonOut" -ForegroundColor Gray }
