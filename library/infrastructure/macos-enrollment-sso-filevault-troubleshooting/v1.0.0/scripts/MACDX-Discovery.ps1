<#
.SYNOPSIS
    MACDX-Discovery.ps1 — read-only inventory of macOS managed devices and their enrollment/health context.
.DESCRIPTION
    PURPOSE
        Discovers the macOS + Intune fleet so a technician can triage at scale instead of clicking
        each device. Pulls managed macOS device inventory, ownership, enrollment/compliance state,
        last check-in, and OS build from Microsoft Graph. Read-only: it never changes the tenant.
        This is Step 0 of the Diagnostic Playbook — see which layer a device has reached and get the
        device id the other scripts use.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACDX-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\MACDX-Discovery.ps1 -DeviceName device-name-or-serial -StaleDays 14 -CsvPath .\macos-devices.csv

        Required Graph scopes (read-only):
            DeviceManagementManagedDevices.Read.All
            DeviceManagementConfiguration.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A table (and optional CSV via -CsvPath) of macOS devices with enrollment/health columns.
        PASS when it connects with the read scopes and lists devices without any write; FAIL if
        sign-in or the read scopes are missing.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    # Optional: filter to a single device by name or serial (substring match).
    [string]$DeviceName,

    # Optional: only devices whose last check-in is older than this many days (stale devices).
    [int]$StaleDays,

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

try {
    Connect-Graph

    Write-Host "Reading managed macOS devices from Intune..." -ForegroundColor Cyan
    $base = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
    $devices = Invoke-GraphGet -Uri $base

    $now = Get-Date
    $rows = foreach ($d in $devices) {
        if ($DeviceName -and ($d.deviceName -notlike "*$DeviceName*") -and ($d.serialNumber -notlike "*$DeviceName*")) { continue }

        $lastSync = if ($d.lastSyncDateTime) { [datetime]$d.lastSyncDateTime } else { $null }
        $ageDays = if ($lastSync) { [math]::Round(($now - $lastSync).TotalDays, 1) } else { $null }

        if ($StaleDays -and (-not $ageDays -or $ageDays -lt $StaleDays)) { continue }

        [pscustomobject]@{
            DeviceName     = $d.deviceName
            Serial         = $d.serialNumber
            PrimaryUser    = $d.userPrincipalName
            Ownership      = $d.managedDeviceOwnerType
            Enrolled       = [bool]$d.enrolledDateTime
            EnrollProfile  = $d.deviceEnrollmentType
            Compliance     = $d.complianceState
            OSVersion      = $d.osVersion
            Model          = $d.model
            LastCheckIn    = $lastSync
            CheckInAgeDays = $ageDays
        }
    }

    $rows = $rows | Sort-Object CheckInAgeDays -Descending

    if (-not $rows) {
        Write-Warning "No macOS devices matched the given filters."
    }
    else {
        $rows | Format-Table -AutoSize
        Write-Host ("Discovered {0} macOS device(s)." -f $rows.Count) -ForegroundColor Green
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
