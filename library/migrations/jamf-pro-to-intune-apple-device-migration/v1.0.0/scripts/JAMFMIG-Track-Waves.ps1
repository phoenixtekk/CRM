<#
.SYNOPSIS
    Reconcile the Jamf inventory against Intune enrollment to report per-device migration progress:
    migrated / pending / (still in Jamf only).

.DESCRIPTION
    Phase 3-5 tracker. Joins the Jamf inventory export (by serial) with Intune's managed Apple devices
    and reports, for each Jamf serial, whether it now exists in Intune (migrated) or not (pending).
    Run it after each wave to know exactly what is left.

.HOW TO RUN
    .\JAMFMIG-Track-Waves.ps1 -JamfCsv .\Jamf-Computers-<stamp>.csv,.\Jamf-MobileDevices-<stamp>.csv
    Sovereign cloud: add  -Environment USGov.

.EXPECTED RESULT
    JAMFMIG-WaveTracker-<stamp>.csv with each Jamf serial marked Migrated or Pending, plus a summary.

.NOTES
    Migrations — read-only (Microsoft Graph + local Jamf CSVs).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string[]]$JamfCsv,
    [string]$OutputPath = ".",
    [string]$Environment = "Global"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -Environment $Environment -NoWelcome
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- Intune serials (Apple) ---
$intune = @{}
Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'macOS' or operatingSystem eq 'iOS'" -All -ErrorAction Stop |
    ForEach-Object { if ($_.SerialNumber) { $intune[$_.SerialNumber.Trim().ToUpper()] = $_ } }
Write-Host "Intune Apple devices: $($intune.Count)" -ForegroundColor Cyan

# --- Jamf serials from the export CSV(s) ---
$jamf = foreach ($f in $JamfCsv) {
    if (-not (Test-Path $f)) { Write-Warning "Not found: $f"; continue }
    Import-Csv $f
}

$rows = foreach ($j in $jamf) {
    $sn = ("$($j.Serial)").Trim().ToUpper()
    if (-not $sn) { continue }
    $mig = $intune.ContainsKey($sn)
    [pscustomobject]@{
        Type     = $j.Type
        Name     = $j.Name
        Serial   = $sn
        Status   = if ($mig) { 'Migrated' } else { 'Pending' }
        IntuneDevice = if ($mig) { $intune[$sn].DeviceName } else { '' }
        Compliance   = if ($mig) { $intune[$sn].ComplianceState } else { '' }
    }
}

$out = Join-Path $OutputPath "JAMFMIG-WaveTracker-$stamp.csv"
$rows | Export-Csv $out -NoTypeInformation -Encoding UTF8
$mig = ($rows | Where-Object Status -eq 'Migrated').Count
$pend = ($rows | Where-Object Status -eq 'Pending').Count
Write-Host "`nMigrated: $mig    Pending: $pend    Total: $($rows.Count)" -ForegroundColor $(if($pend -eq 0){'Green'}else{'Yellow'})
Write-Host "Exported: $out" -ForegroundColor Green
if ($pend -eq 0) { Write-Host "All Jamf devices are enrolled in Intune — ready for Phase 5 (decommission Jamf)." -ForegroundColor Green }
