<#
.SYNOPSIS
    ISEPOST-Report.ps1 — fleet compliance-coverage report plus a conceptual access-decision (granted vs denied) breakdown.
.DESCRIPTION
    PURPOSE
        Read-only fleet report. Enumerates Intune managed devices via Microsoft Graph and
        summarizes enrollment + compliance coverage, then applies this solution's mapping
        (compliant+enrolled = granted; else denied/quarantine) to show a conceptual
        access-decision split ISE would enforce. Optionally writes a CSV.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Report.ps1 -CsvPath .\ise-posture-report.csv

        Required Graph scopes: DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        Console summary of totals by compliance state and platform, plus a granted/denied
        breakdown. With -CsvPath, a per-device CSV is written. Read-only; nothing changes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'

function Connect-GraphSafe {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) {
        Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome | Out-Null
    }
}

Write-Host "=== ISEPOST Report — fleet compliance coverage + conceptual access decisions ===" -ForegroundColor Cyan
Connect-GraphSafe

$devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop
if (-not $devices -or $devices.Count -eq 0) {
    Write-Host "No Intune managed devices found." -ForegroundColor Yellow
    return
}

$total = $devices.Count
Write-Host "`nTotal managed devices: $total" -ForegroundColor Cyan

# --- Compliance-state breakdown ---------------------------------------------
Write-Host "`n--- Compliance coverage ---" -ForegroundColor Cyan
$devices | Group-Object ComplianceState | Sort-Object Count -Descending | ForEach-Object {
    "{0,-16} {1,6}  ({2,5:P0})" -f $_.Name, $_.Count, ($_.Count / $total)
}

# --- Platform breakdown ------------------------------------------------------
Write-Host "`n--- By platform ---" -ForegroundColor Cyan
$devices | Group-Object OperatingSystem | Sort-Object Count -Descending | ForEach-Object {
    "{0,-16} {1,6}" -f $_.Name, $_.Count
}

# --- Conceptual access decision (this solution's mapping) --------------------
# compliant             -> GRANTED
# inGracePeriod         -> GRANTED (warned)
# anything else         -> DENIED / quarantine
$granted = @($devices | Where-Object { $_.ComplianceState -in @('compliant','inGracePeriod') }).Count
$denied  = $total - $granted

Write-Host "`n--- Conceptual ISE access decision ---" -ForegroundColor Cyan
Write-Host ("  ACCESS GRANTED (compliant / in grace) : {0,6}  ({1,5:P0})" -f $granted, ($granted / $total)) -ForegroundColor Green
Write-Host ("  ACCESS DENIED  (non-compliant)        : {0,6}  ({1,5:P0})" -f $denied,  ($denied  / $total)) -ForegroundColor Red
Write-Host "`n  (Enforcement is performed by Cisco ISE; ISE authorization policy is deferred to Cisco documentation.)"

# --- Optional CSV ------------------------------------------------------------
if ($CsvPath) {
    $rows = $devices | ForEach-Object {
        $verdict = if ($_.ComplianceState -in @('compliant','inGracePeriod')) { 'GRANTED' } else { 'DENIED' }
        [pscustomobject]@{
            DeviceName       = $_.DeviceName
            OperatingSystem  = $_.OperatingSystem
            OsVersion        = $_.OsVersion
            Enrolled         = $true
            ComplianceState  = $_.ComplianceState
            LastSync         = $_.LastSyncDateTime
            ConceptualAccess = $verdict
        }
    }
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nCSV written: $CsvPath" -ForegroundColor Green
}

Write-Host "`n=== Report complete ===" -ForegroundColor Cyan
