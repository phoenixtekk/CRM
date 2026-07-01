<#
.SYNOPSIS
    EPICWS-Report.ps1 — Produces a fleet standardization / drift report (printers, default, peripherals) to CSV.

.DESCRIPTION
    PURPOSE
        Builds a fleet-level report of clinical-workstation standardization across the managed devices,
        using Microsoft Graph (Intune managed-device data) for inventory, and writes it to CSV for
        triage and drift detection. Reports each device's unit group membership where available, its
        compliance/management state, and last-sync — the signals that show whether the standard is
        holding. For deep per-device printer/default/peripheral checks, run EPICWS-Validation.ps1 on
        the device. Read-only.

    HOW TO RUN
        Requires the Microsoft.Graph SDK and an operator with device-read rights:
            Install-Module Microsoft.Graph -Scope CurrentUser     # one time
            powershell -ExecutionPolicy Bypass -File .\EPICWS-Report.ps1 `
                -GroupName "EPIC - Clinical Workstations" -OutCsv .\EPICWS-fleet-report.csv

    EXPECTED RESULTS
        A CSV (default .\EPICWS-fleet-report.csv) with one row per in-scope device: device name, OS,
        compliance state, management state, last sync, and the EPIC unit group(s) it belongs to. Review
        for devices that are non-compliant, not recently synced, or missing a unit group (which means
        no per-unit printers/default printer) — those are your drift candidates.

.NOTES
    Healthcare Solutions — read-only. Makes no changes. Reports device/management state only; never
    captures patient data.
#>
[CmdletBinding()]
param(
    [string]$GroupName = 'EPIC - Clinical Workstations',
    [string]$OutCsv    = ".\EPICWS-fleet-report.csv"
)

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Import-Module Microsoft.Graph.DeviceManagement -ErrorAction SilentlyContinue
    Import-Module Microsoft.Graph.Groups -ErrorAction SilentlyContinue
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All','GroupMember.Read.All' -NoWelcome
    }
} catch {
    Write-Error "Microsoft Graph SDK required. Run: Install-Module Microsoft.Graph -Scope CurrentUser. Details: $($_.Exception.Message)"
    return
}

# Map each managed device -> the EPIC unit groups it belongs to (best-effort).
$unitGroups = Get-MgGroup -Filter "startswith(displayName,'EPIC - Clinical Workstations')" -All -ErrorAction SilentlyContinue
$deviceToUnits = @{}
foreach ($g in $unitGroups) {
    $members = Get-MgGroupMember -GroupId $g.Id -All -ErrorAction SilentlyContinue
    foreach ($m in $members) {
        $name = $m.AdditionalProperties['displayName']
        if ($name) {
            if (-not $deviceToUnits.ContainsKey($name)) { $deviceToUnits[$name] = New-Object System.Collections.Generic.List[string] }
            $deviceToUnits[$name].Add($g.DisplayName)
        }
    }
}

Write-Host "Querying Intune managed Windows devices..." -ForegroundColor Cyan
$devices = Get-MgDeviceManagementManagedDevice -All -Filter "operatingSystem eq 'Windows'" -ErrorAction SilentlyContinue

$rows = foreach ($d in $devices) {
    $units = if ($deviceToUnits.ContainsKey($d.DeviceName)) { ($deviceToUnits[$d.DeviceName] -join '; ') } else { '' }
    [pscustomobject]@{
        DeviceName       = $d.DeviceName
        OS               = "$($d.OperatingSystem) $($d.OsVersion)"
        Compliance       = $d.ComplianceState
        ManagementState  = $d.ManagementState
        LastSync         = $d.LastSyncDateTime
        EnrolledDate     = $d.EnrolledDateTime
        EpicUnitGroups   = $units
        HasUnitGroup     = [bool]$units
    }
}

$rows | Sort-Object HasUnitGroup, DeviceName | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $($rows.Count) device row(s) to $OutCsv" -ForegroundColor Green
$drift = $rows | Where-Object { -not $_.HasUnitGroup -or $_.Compliance -ne 'compliant' }
if ($drift) {
    Write-Host "Drift candidates (no unit group or non-compliant): $($drift.Count). Triage with EPICWS-Validation.ps1 / EPICWS-Remediation.ps1." -ForegroundColor Yellow
}
