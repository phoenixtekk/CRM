<#
.SYNOPSIS
    WS1PROG-Report.ps1 - Read-only program/wave status dashboard for a Workspace ONE -> Intune migration.

    PURPOSE:
        Reads the wave plan (output of WS1PROG-Set-WaveTargeting.ps1) and the live Intune state (via
        Microsoft Graph) and produces, per platform and per wave: % migrated (device is Intune-managed),
        % compliant, and a device count. This is the program dashboard used to decide when a wave has
        passed and when Workspace ONE may be decommissioned (no source teardown until 100% per wave).

    HOW TO RUN:
        1. Install the Microsoft Graph PowerShell SDK (run once):
             Install-Module Microsoft.Graph -Scope CurrentUser
        2. Run against the wave plan:
             .\WS1PROG-Report.ps1 -WavePlanCsv ".\Wave-Plan - Program - Program.csv" `
                                  -OutputCsv ".\Program-Status - Program - Program.csv"
        Sign in interactively when prompted; read-only Graph scopes are sufficient.

    EXPECTED RESULTS:
        A CSV with one row per (Wave, Platform): TotalDevices, MigratedCount, MigratedPct,
        CompliantCount, CompliantPct, plus a console summary table. Strictly READ-ONLY.

.NOTES
    Migrations - read-only. Intune/Entra side via Microsoft Graph PowerShell.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$WavePlanCsv,
    [string]$OutputCsv = ".\Program-Status - Program - Program.csv"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $WavePlanCsv)) { throw "Wave plan CSV not found: $WavePlanCsv" }
$plan = Import-Csv $WavePlanCsv
if (-not $plan) { throw "Wave plan is empty: $WavePlanCsv" }

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Write-Host "Connecting to Microsoft Graph (read-only)..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Directory.Read.All" -NoWelcome
Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop

# --- Snapshot Intune managed devices once, index by device name ---
Write-Host "Reading Intune managed device state..." -ForegroundColor Cyan
$intune = @{}
Get-MgDeviceManagementManagedDevice -All | ForEach-Object {
    if ($_.DeviceName) { $intune[$_.DeviceName] = $_ }
}

function Get-Platform {
    param($PlanRow, $Device)
    if ($PlanRow.Scope -and $PlanRow.Scope -in @('Windows','iOS','Android','macOS')) { return $PlanRow.Scope }
    if ($Device) {
        switch -Wildcard ($Device.OperatingSystem) {
            'Windows*' { return 'Windows' } 'iOS*' { return 'iOS' } 'iPadOS*' { return 'iOS' }
            'Android*' { return 'Android' } 'macOS*' { return 'macOS' }
        }
    }
    return 'Unknown'
}

# --- Tally per (Wave, Platform) ---
$buckets = @{}
foreach ($row in $plan) {
    $name = $row.ObjectName
    $dev  = $intune[$name]
    $platform = Get-Platform -PlanRow $row -Device $dev
    $wave = $row.Wave
    $key  = "$wave|$platform"
    if (-not $buckets.ContainsKey($key)) {
        $buckets[$key] = [pscustomobject]@{ Wave=$wave; Platform=$platform; Total=0; Migrated=0; Compliant=0 }
    }
    $b = $buckets[$key]
    $b.Total++
    if ($dev -and $dev.ManagementAgent) { $b.Migrated++ }
    if ($dev -and $dev.ComplianceState -eq 'compliant') { $b.Compliant++ }
}

$report = $buckets.Values | ForEach-Object {
    [pscustomobject]@{
        Wave          = $_.Wave
        Platform      = $_.Platform
        TotalDevices  = $_.Total
        MigratedCount = $_.Migrated
        MigratedPct   = if ($_.Total) { [math]::Round(100 * $_.Migrated / $_.Total, 1) } else { 0 }
        CompliantCount= $_.Compliant
        CompliantPct  = if ($_.Total) { [math]::Round(100 * $_.Compliant / $_.Total, 1) } else { 0 }
    }
} | Sort-Object Wave, Platform

$report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nStatus report written to {0}" -f $OutputCsv) -ForegroundColor Green

Write-Host "`n=== Program status (Wave x Platform) ===" -ForegroundColor Cyan
Write-Host ("  {0,-20} {1,-9} {2,-7} {3,-10} {4,-10}" -f 'Wave','Platform','Total','Migrated%','Compliant%')
foreach ($r in $report) {
    Write-Host ("  {0,-20} {1,-9} {2,-7} {3,-10} {4,-10}" -f $r.Wave, $r.Platform, $r.TotalDevices, $r.MigratedPct, $r.CompliantPct)
}

$incomplete = $report | Where-Object { $_.MigratedPct -lt 100 -or $_.CompliantPct -lt 100 }
if ($incomplete) {
    Write-Host "`nWaves NOT yet 100% migrated-and-compliant (do not decommission Workspace ONE for these):" -ForegroundColor Yellow
    $incomplete | ForEach-Object { Write-Host ("  {0} / {1}" -f $_.Wave, $_.Platform) }
} else {
    Write-Host "`nAll reported waves are 100% migrated-and-compliant." -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
