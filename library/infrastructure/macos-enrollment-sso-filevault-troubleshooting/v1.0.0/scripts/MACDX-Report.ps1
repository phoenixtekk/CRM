<#
.SYNOPSIS
    MACDX-Report.ps1 — read-only fleet-health and FileVault escrow-coverage summary for macOS + Intune.
.DESCRIPTION
    PURPOSE
        Produces a macOS fleet summary a lead can use to spot trends and coverage gaps: counts by
        enrollment and compliance state, stale (not-checked-in) Macs, OS-version spread, and the
        FileVault personal-recovery-key escrow coverage across the fleet. Drawn from Microsoft Graph.
        Read-only: it never changes the tenant.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACDX-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\MACDX-Report.ps1 -StaleDays 14 -CsvPath .\macos-fleet.csv

        Required Graph scopes (read-only):
            DeviceManagementManagedDevices.Read.All
            DeviceManagementConfiguration.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A printed summary (and optional CSV via -CsvPath) of macOS fleet health and escrow coverage.
        PASS when it runs read-only and the figures reconcile with the Intune portal for your scope;
        FAIL if sign-in or scopes are missing.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    # Devices with no check-in within this many days are counted as stale.
    [int]$StaleDays = 14,

    # Optional: also check FileVault recovery-key escrow per device (adds one Graph call each).
    [switch]$IncludeEscrow = $true,

    # Optional: write the per-device detail behind the summary to this CSV path.
    [string]$CsvPath,

    # Optional tenant id, e.g. your-tenant-id. Leave blank for interactive/default tenant.
    [string]$TenantId
)

$ErrorActionPreference = 'Stop'

$RequiredScopes = @(
    'DeviceManagementManagedDevices.Read.All',
    'DeviceManagementConfiguration.Read.All',
    'Directory.Read.All'
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

    Write-Host "Reading managed macOS devices..." -ForegroundColor Cyan
    $devices = Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
    $now = Get-Date

    $detail = foreach ($d in $devices) {
        $lastSync = if ($d.lastSyncDateTime) { [datetime]$d.lastSyncDateTime } else { $null }
        $ageDays = if ($lastSync) { [math]::Round(($now - $lastSync).TotalDays, 1) } else { $null }

        $escrowed = $null
        if ($IncludeEscrow) {
            try {
                $k = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($d.id)/getFileVaultKey" -ErrorAction Stop
                $escrowed = [bool]$k
            }
            catch { $escrowed = $false }
        }

        [pscustomobject]@{
            DeviceName     = $d.deviceName
            Serial         = $d.serialNumber
            Enrolled       = [bool]$d.enrolledDateTime
            Compliance     = $d.complianceState
            Ownership      = $d.managedDeviceOwnerType
            OSVersion      = $d.osVersion
            CheckInAgeDays = $ageDays
            Stale          = ($null -eq $ageDays -or $ageDays -ge $StaleDays)
            KeyEscrowed    = $escrowed
        }
    }

    $total = $detail.Count
    Write-Host ""
    Write-Host "======== macOS + INTUNE — FLEET HEALTH SUMMARY ========" -ForegroundColor Yellow
    Write-Host ("Generated: {0}" -f $now)
    Write-Host ("Total macOS devices in scope: {0}" -f $total)
    Write-Host ""

    Write-Host "-- By compliance state --" -ForegroundColor Cyan
    $detail | Group-Object Compliance | Sort-Object Count -Descending |
        ForEach-Object { "{0,-15} {1,5}" -f $_.Name, $_.Count }

    Write-Host ""
    Write-Host "-- By enrollment state --" -ForegroundColor Cyan
    $detail | Group-Object Enrolled | Sort-Object Count -Descending |
        ForEach-Object { "{0,-15} {1,5}" -f ("Enrolled=" + $_.Name), $_.Count }

    Write-Host ""
    Write-Host ("-- Stale devices (no check-in >= {0} days) --" -f $StaleDays) -ForegroundColor Cyan
    $staleCount = ($detail | Where-Object Stale).Count
    $pct = if ($total) { [math]::Round(($staleCount / $total) * 100, 1) } else { 0 }
    Write-Host ("{0} of {1} ({2}%)" -f $staleCount, $total, $pct)

    if ($IncludeEscrow) {
        Write-Host ""
        Write-Host "-- FileVault personal-recovery-key escrow coverage --" -ForegroundColor Cyan
        $escrowedCount = ($detail | Where-Object KeyEscrowed).Count
        $ePct = if ($total) { [math]::Round(($escrowedCount / $total) * 100, 1) } else { 0 }
        Write-Host ("{0} of {1} Macs have an escrowed recovery key ({2}%)" -f $escrowedCount, $total, $ePct)
        if ($ePct -lt 100) { Write-Host "Macs without an escrowed key risk an unrecoverable lock-out (Playbook Branch C/E)." -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "-- Top OS versions --" -ForegroundColor Cyan
    $detail | Group-Object OSVersion | Sort-Object Count -Descending | Select-Object -First 8 |
        ForEach-Object { "{0,-20} {1,5}" -f $_.Name, $_.Count }

    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Yellow

    if ($CsvPath) {
        $detail | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host ("Per-device detail saved to {0}" -f $CsvPath) -ForegroundColor Green
    }
}
catch {
    Write-Error ("Report failed: {0}" -f $_.Exception.Message)
    exit 1
}
