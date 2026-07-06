<#
.SYNOPSIS
    MACRUN-Discovery.ps1 — read-only Mac fleet health and context discovery for Intune-managed macOS.
.DESCRIPTION
    PURPOSE
        Discovers health and support context across the Intune-managed Mac fleet so a technician can
        triage at scale instead of clicking each device. Pulls managed-device inventory, ownership,
        compliance state, last check-in, macOS build, and primary user from Microsoft Graph, and
        flags whether a FileVault personal recovery key is escrowed. Read-only: it never changes the
        tenant.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACRUN-Discovery.ps1

        Required Graph scopes (read-only):
            DeviceManagementManagedDevices.Read.All
            DeviceManagementConfiguration.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A table (and optional CSV via -CsvPath) of Macs with health/context columns, including a
        FileVaultKeyEscrowed indicator. PASS when it connects with the read scopes and lists Macs
        without attempting any write; FAIL if sign-in or the read scopes are missing.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    # Optional: filter to a single Mac by name or serial (substring match).
    [string]$DeviceName,

    # Optional: only Macs whose last check-in is older than this many days (stale devices).
    [int]$StaleDays,

    # Optional: also query the escrowed-recovery-key indicator per device (adds one call each).
    [switch]$IncludeFileVault,

    # Optional: write the results to a CSV file at this path.
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
    $ctx = Get-MgContext
    Write-Host ("Connected as {0} (tenant {1})." -f $ctx.Account, $ctx.TenantId) -ForegroundColor Green
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

function Test-FileVaultEscrow {
    param([string]$DeviceId)
    # Read-only: try to read the escrowed FileVault key metadata. A 200 means a key is escrowed;
    # any error (e.g. 404) means no key is available to this account for that device.
    try {
        $r = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceId/getFileVaultKey"
        if ($r) { return 'Yes' } else { return 'No' }
    }
    catch { return 'No' }
}

try {
    Connect-Graph

    Write-Host "Reading managed macOS devices from Intune..." -ForegroundColor Cyan
    $base = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
    $devices = Invoke-GraphGet -Uri $base

    $now = Get-Date
    $rows = foreach ($d in $devices) {
        if ($DeviceName -and ($d.deviceName -notlike "*$DeviceName*") -and ($d.serialNumber -notlike "*$DeviceName*")) { continue }

        $lastSync = $null
        if ($d.lastSyncDateTime) { $lastSync = [datetime]$d.lastSyncDateTime }
        $ageDays = if ($lastSync) { [math]::Round(($now - $lastSync).TotalDays, 1) } else { $null }

        if ($StaleDays -and (-not $ageDays -or $ageDays -lt $StaleDays)) { continue }

        $fv = 'Not checked'
        if ($IncludeFileVault) { $fv = Test-FileVaultEscrow -DeviceId $d.id }

        [pscustomobject]@{
            DeviceName            = $d.deviceName
            Serial                = $d.serialNumber
            PrimaryUser           = $d.userPrincipalName
            Ownership             = $d.managedDeviceOwnerType
            Compliance            = $d.complianceState
            OSVersion             = $d.osVersion
            Model                 = $d.model
            LastCheckIn           = $lastSync
            CheckInAgeDays        = $ageDays
            Enrolled              = [bool]$d.enrolledDateTime
            FileVaultKeyEscrowed  = $fv
        }
    }

    $rows = $rows | Sort-Object CheckInAgeDays -Descending

    if (-not $rows) {
        Write-Warning "No macOS devices matched the given filters."
    }
    else {
        $rows | Format-Table -AutoSize
        Write-Host ("Discovered {0} Mac(s)." -f $rows.Count) -ForegroundColor Green
        if (-not $IncludeFileVault) {
            Write-Host "Tip: add -IncludeFileVault to check escrowed-recovery-key status per Mac (extra read per device)." -ForegroundColor DarkCyan
        }
        if ($CsvPath) {
            $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
            Write-Host ("Saved report to {0}" -f $CsvPath) -ForegroundColor Green
        }
    }
}
catch {
    Write-Error ("Discovery failed: {0}" -f $_.Exception.Message)
    exit 1
}
