<#
.SYNOPSIS
    MACRUN-Validation.ps1 — read-only per-device state validation for an Intune-managed Mac.
.DESCRIPTION
    PURPOSE
        Validates the support-relevant state of a single Mac so a technician can confirm what a
        runbook check expects. Reports enrollment/ownership state, compliance (with the specific
        non-compliant policies named), assigned configuration profiles, and whether a FileVault
        personal recovery key is escrowed, from Microsoft Graph. Read-only: it never changes the
        tenant.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACRUN-Validation.ps1 -DeviceName device-name-or-serial

        Required Graph scopes (read-only):
            DeviceManagementManagedDevices.Read.All
            DeviceManagementConfiguration.Read.All
            DeviceManagementApps.Read.All
    EXPECTED RESULTS
        A per-device summary: enrolled/compliant yes/no, named non-compliant settings, assigned
        profiles, and FileVault-key-escrowed yes/no. PASS when the reported state matches the Intune
        portal for a pilot Mac; FAIL if scopes are missing or the Mac is not found.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    # Mac name or serial to validate (substring match). Required.
    [Parameter(Mandatory = $true)]
    [string]$DeviceName,

    # Optional tenant id, e.g. your-tenant-id. Leave blank for interactive/default tenant.
    [string]$TenantId
)

$ErrorActionPreference = 'Stop'

$RequiredScopes = @(
    'DeviceManagementManagedDevices.Read.All',
    'DeviceManagementConfiguration.Read.All',
    'DeviceManagementApps.Read.All'
)

function Connect-Graph {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph.Authentication is not installed. Run: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
        Write-Host "Connecting to Microsoft Graph (read-only scopes)..." -ForegroundColor Cyan
        if ($TenantId) { Connect-MgGraph -Scopes $RequiredScopes -TenantId $TenantId | Out-Null }
        else { Connect-MgGraph -Scopes $RequiredScopes | Out-Null }
    }
    Write-Host ("Connected as {0}." -f (Get-MgContext).Account) -ForegroundColor Green
}

function Invoke-GraphGet {
    param([string]$Uri)
    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } else { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

try {
    Connect-Graph

    Write-Host ("Locating Mac matching '{0}'..." -f $DeviceName) -ForegroundColor Cyan
    $all = Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
    $device = $all | Where-Object { $_.deviceName -like "*$DeviceName*" -or $_.serialNumber -like "*$DeviceName*" } | Select-Object -First 1

    if (-not $device) {
        Write-Warning "No macOS device matched '$DeviceName'. Confirm you searched by device name, serial, or primary user (Requirement R4)."
        exit 1
    }

    $id = $device.id
    Write-Host ""
    Write-Host "=== Mac state ===" -ForegroundColor Yellow
    [pscustomobject]@{
        DeviceName   = $device.deviceName
        Serial       = $device.serialNumber
        PrimaryUser  = $device.userPrincipalName
        Ownership    = $device.managedDeviceOwnerType
        Enrolled     = [bool]$device.enrolledDateTime
        Compliance   = $device.complianceState
        OSVersion    = $device.osVersion
        LastCheckIn  = $device.lastSyncDateTime
    } | Format-List

    Write-Host "=== Compliance detail (non-compliant policies named) ===" -ForegroundColor Yellow
    $states = Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/deviceCompliancePolicyStates"
    if ($states) {
        $states | ForEach-Object {
            [pscustomobject]@{ Policy = $_.displayName; State = $_.state; Version = $_.version }
        } | Format-Table -AutoSize
        $bad = $states | Where-Object { $_.state -ne 'compliant' }
        if ($bad) { Write-Host ("NON-COMPLIANT: {0}" -f (($bad.displayName) -join ', ')) -ForegroundColor Red }
        else { Write-Host "All evaluated compliance policies are compliant." -ForegroundColor Green }
    }
    else { Write-Host "No compliance policy states returned." }

    Write-Host ""
    Write-Host "=== Assigned configuration profiles ===" -ForegroundColor Yellow
    $cfg = Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/deviceConfigurationStates"
    if ($cfg) {
        $cfg | ForEach-Object { [pscustomobject]@{ Profile = $_.displayName; State = $_.state } } | Format-Table -AutoSize
    }
    else { Write-Host "No configuration profile states returned." }

    Write-Host ""
    Write-Host "=== FileVault recovery key escrow ===" -ForegroundColor Yellow
    # Read-only check: a successful read means a personal recovery key is escrowed for this Mac.
    # The key VALUE is never printed — only whether one is available.
    $escrowed = 'No'
    try {
        $fv = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/getFileVaultKey"
        if ($fv) { $escrowed = 'Yes' }
    }
    catch { $escrowed = 'No' }
    if ($escrowed -eq 'Yes') {
        Write-Host "FileVault personal recovery key: ESCROWED (safe to proceed with FileVault-adjacent actions)." -ForegroundColor Green
    }
    else {
        Write-Host "FileVault personal recovery key: NOT ESCROWED (or not readable by this account). Do NOT change FileVault until resolved — see Runbook 4/7." -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "Validation complete. Compare the above to the Intune portal for this Mac." -ForegroundColor Green
}
catch {
    Write-Error ("Validation failed: {0}" -f $_.Exception.Message)
    exit 1
}
