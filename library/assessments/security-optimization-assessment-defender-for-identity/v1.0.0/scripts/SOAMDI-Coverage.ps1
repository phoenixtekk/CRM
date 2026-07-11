<#
.SYNOPSIS
    SOAMDI-Coverage.ps1 — read-only sensor-coverage reconciliation for Defender for Identity (the centerpiece check).
.DESCRIPTION
    PURPOSE
        Reconciles what SHOULD be covered (the AD-derived inventory of domain controllers and AD FS / AD CS
        role holders) against what IS covered (the MDI sensor list), and NAMES every un-sensored or
        unhealthy server — the critical blind spots. Also reports honeytoken presence and the DSA signal.
        Coverage is computed against the AD inventory as the denominator (never the sensor list alone,
        which can't reveal a server with no sensor).
    HOW TO RUN
        pwsh -File .\SOAMDI-Coverage.ps1 -InputDir ".\SOAMDI-Run - 2026-07-11 - Assess"
        Run SOAMDI-Discovery.ps1 first. Where sensor data was 'verify'-flagged (no API), confirm the
        sensor list in the portal and, if needed, supply it via -SensorHostsCsv for exact reconciliation.
    EXPECTED RESULTS
        A coverage summary + coverage-blindspots.csv in the run folder. Read-only.
.NOTES
    White-label. Read-only. Consumes discovery output only; makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$InputDir,
    # Optional: a CSV/txt of sensor host names confirmed from the portal, one per line, when no API is available.
    [string]$SensorHostsCsv = ''
)

$ErrorActionPreference = 'Stop'
function Load([string]$Name) { $p = Join-Path $InputDir "$Name.json"; if (Test-Path $p) { @(Get-Content $p -Raw | ConvertFrom-Json) } else { Write-Host "  (missing area: $Name)" -ForegroundColor Yellow; @() } }
function Pct([double]$n, [double]$d) { if ($d -le 0) { 0 } else { [math]::Round(100.0 * $n / $d, 1) } }

Write-Host "SOAMDI coverage (read-only) <- $InputDir`n" -ForegroundColor Cyan
$dcs      = Load 'domain-controllers'
$adfs     = Load 'adfs-servers'
$adcs     = Load 'adcs-servers'
$sensors  = Load 'mdi-sensors'
$honey    = Load 'honeytoken-signal'
$dsa      = Load 'dsa-signal'

# Build the set of hosts that have a sensor. Prefer an explicit portal-confirmed list when supplied.
$sensorHosts = @()
if ($SensorHostsCsv -and (Test-Path $SensorHostsCsv)) {
    $sensorHosts = @(Get-Content $SensorHostsCsv | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim().ToLower() })
    Write-Host "  Using portal-confirmed sensor host list ($($sensorHosts.Count) hosts) from $SensorHostsCsv" -ForegroundColor Green
} else {
    # Best-effort from API data (may be empty / 'verify' — reconcile in portal).
    $sensorHosts = @($sensors | ForEach-Object { $_.machineName ?? $_.hostName ?? $_.name } | Where-Object { $_ } | ForEach-Object { ("$_").ToLower() })
    if ($sensorHosts.Count -eq 0) { Write-Host "  WARNING: no sensor host data (API 'verify'). Supply -SensorHostsCsv from Settings > Identities > Sensors for exact reconciliation." -ForegroundColor Yellow }
}
function Has-Sensor([string]$host) {
    if (-not $host) { return $false }
    $h = $host.ToLower()
    return [bool]($sensorHosts | Where-Object { $h -like "*$_*" -or $_ -like "*$($h.Split('.')[0])*" })
}

$rows = [System.Collections.Generic.List[object]]::new()
$blind = [System.Collections.Generic.List[object]]::new()

# --- DC sensor coverage (the critical check) ---------------------------------
$dcTotal = $dcs.Count
$dcCovered = 0
foreach ($dc in $dcs) {
    $host = $dc.HostName ?? $dc.Name
    if (Has-Sensor $host) { $dcCovered++ } else { $blind.Add([pscustomobject]@{ Role = 'DomainController'; Host = $host; Site = $dc.Site; OS = $dc.OperatingSystem; Issue = 'NO SENSOR (or unconfirmed)' }) }
}
$rows.Add([pscustomobject]@{ Area = 'DC sensor coverage'; Covered = $dcCovered; Total = $dcTotal; CoveragePct = (Pct $dcCovered $dcTotal) })

# --- AD FS / AD CS coverage ---------------------------------------------------
$adfsHosts = @($adfs | ForEach-Object { $_.dNSHostName ?? $_.Name } | Where-Object { $_ })
$adfsCov = @($adfsHosts | Where-Object { Has-Sensor $_ }).Count
if ($adfsHosts.Count -gt 0) { $rows.Add([pscustomobject]@{ Area = 'AD FS sensor coverage'; Covered = $adfsCov; Total = $adfsHosts.Count; CoveragePct = (Pct $adfsCov $adfsHosts.Count) }) }
foreach ($h in $adfsHosts) { if (-not (Has-Sensor $h)) { $blind.Add([pscustomobject]@{ Role = 'AD FS'; Host = $h; Site = ''; OS = ''; Issue = 'NO SENSOR (or unconfirmed)' }) } }

$adcsHosts = @($adcs | ForEach-Object { $_.dNSHostName ?? $_.Name } | Where-Object { $_ })
$adcsCov = @($adcsHosts | Where-Object { Has-Sensor $_ }).Count
if ($adcsHosts.Count -gt 0) { $rows.Add([pscustomobject]@{ Area = 'AD CS sensor coverage'; Covered = $adcsCov; Total = $adcsHosts.Count; CoveragePct = (Pct $adcsCov $adcsHosts.Count) }) }
foreach ($h in $adcsHosts) { if (-not (Has-Sensor $h)) { $blind.Add([pscustomobject]@{ Role = 'AD CS'; Host = $h; Site = ''; OS = ''; Issue = 'NO SENSOR (or unconfirmed)' }) } }

# --- Honeytoken + DSA signals ------------------------------------------------
$honeyCount = @($honey | Where-Object { $_.AccountName }).Count
$rows.Add([pscustomobject]@{ Area = 'Honeytoken-tagged identities'; Covered = $honeyCount; Total = '(>=1 expected)'; CoveragePct = $(if ($honeyCount -gt 0) { 'present' } else { 'NONE (verify in portal)' }) })
$dsaNote = ($dsa | Select-Object -First 1).note
$rows.Add([pscustomobject]@{ Area = 'Directory service account (DSA)'; Covered = 'verify'; Total = ''; CoveragePct = $dsaNote })

Write-Host "--- Coverage summary ---" -ForegroundColor Cyan
$rows | Format-Table -AutoSize -Wrap
$rows | Export-Csv (Join-Path $InputDir 'coverage-summary.csv') -NoTypeInformation -Encoding UTF8
if ($blind.Count -gt 0) {
    Write-Host "`n--- BLIND SPOTS: servers with no (confirmed) MDI sensor — review first ---" -ForegroundColor Yellow
    $blind | Format-Table -AutoSize
    $blind | Export-Csv (Join-Path $InputDir 'coverage-blindspots.csv') -NoTypeInformation -Encoding UTF8
}
Write-Host "`nRead-only; no changes made. Confirm 'verify' items in Settings > Identities. Next: SOAMDI-Assess.ps1." -ForegroundColor Green
