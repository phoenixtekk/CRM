<#
.SYNOPSIS
    MACRUN-Report.ps1 — read-only support-metrics and Mac-fleet-health summary for Intune-managed macOS.
.DESCRIPTION
    PURPOSE
        Produces a support-metrics and Mac-fleet-health summary a lead can use to spot trends: counts
        by compliance state, stale (not-checked-in) Macs, macOS-version spread, and ownership mix
        (corporate vs. personal/BYOD), drawn from Microsoft Graph. Read-only: it never changes the
        tenant. Use it during the Document stage and to decide whether a rising category needs a new
        or refined runbook, or a feature evaluation.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACRUN-Report.ps1

        Required Graph scopes (read-only):
            DeviceManagementManagedDevices.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A printed summary (and optional CSV via -CsvPath) of Mac health/support metrics. PASS when it
        runs read-only and the figures reconcile with the Intune portal for your scope; FAIL if
        sign-in or scopes are missing.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    # Macs with no check-in within this many days are counted as stale.
    [int]$StaleDays = 14,

    # Optional: write the per-device detail behind the summary to this CSV path.
    [string]$CsvPath,

    # Optional tenant id, e.g. your-tenant-id. Leave blank for interactive/default tenant.
    [string]$TenantId
)

$ErrorActionPreference = 'Stop'

$RequiredScopes = @(
    'DeviceManagementManagedDevices.Read.All',
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
        [pscustomobject]@{
            DeviceName     = $d.deviceName
            Compliance     = $d.complianceState
            Ownership      = $d.managedDeviceOwnerType
            OSVersion      = $d.osVersion
            CheckInAgeDays = $ageDays
            Stale          = ($ageDays -eq $null -or $ageDays -ge $StaleDays)
        }
    }

    $total = $detail.Count
    Write-Host ""
    Write-Host "======== macOS SUPPORT — FLEET HEALTH SUMMARY ========" -ForegroundColor Yellow
    Write-Host ("Generated: {0}" -f $now)
    Write-Host ("Total macOS devices in scope: {0}" -f $total)
    Write-Host ""

    Write-Host "-- By compliance state --" -ForegroundColor Cyan
    $detail | Group-Object Compliance | Sort-Object Count -Descending |
        ForEach-Object { "{0,-15} {1,5}" -f $_.Name, $_.Count }

    Write-Host ""
    Write-Host ("-- Stale Macs (no check-in >= {0} days) --" -f $StaleDays) -ForegroundColor Cyan
    $staleCount = ($detail | Where-Object Stale).Count
    $pct = if ($total) { [math]::Round(($staleCount / $total) * 100, 1) } else { 0 }
    Write-Host ("{0} of {1} ({2}%)" -f $staleCount, $total, $pct)

    Write-Host ""
    Write-Host "-- By ownership (corporate vs. personal/BYOD) --" -ForegroundColor Cyan
    $detail | Group-Object Ownership | Sort-Object Count -Descending |
        ForEach-Object { "{0,-15} {1,5}" -f $_.Name, $_.Count }

    Write-Host ""
    Write-Host "-- Top macOS versions --" -ForegroundColor Cyan
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
