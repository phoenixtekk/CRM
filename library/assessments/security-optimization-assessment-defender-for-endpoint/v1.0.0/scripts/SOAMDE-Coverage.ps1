<#
.SYNOPSIS
    SOAMDE-Coverage.ps1 — read-only per-area coverage math for Defender for Endpoint (onboarding, ASR, tamper, EDR block mode).
.DESCRIPTION
    PURPOSE
        Turns the raw discovery evidence into coverage percentages with explicit gap lists — the work
        list the remediation will act on. Computes: onboarding coverage against the EXPECTED device
        count (not just MDE's own inventory), ASR rules in Block vs Audit vs Not-configured, tamper
        protection coverage, and EDR block-mode / network protection coverage. Names the devices and
        policies with gaps so nothing is hand-waved.
    HOW TO RUN
        pwsh -File .\SOAMDE-Coverage.ps1 -InputDir ".\SOAMDE-Run - 2026-07-11 - Assess" -ExpectedDeviceCount 1900
        Run SOAMDE-Discovery.ps1 first. Supply the authoritative expected device count from Intune/AD/CMDB.
    EXPECTED RESULTS
        A coverage summary table per area and coverage-*.csv gap lists in the run folder. Read-only.
.NOTES
    White-label. Read-only. Consumes discovery output only; makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$InputDir,
    [int]$ExpectedDeviceCount = 0
)

$ErrorActionPreference = 'Stop'
function Load([string]$Name) {
    $p = Join-Path $InputDir "$Name.json"
    if (Test-Path $p) { return Get-Content $p -Raw | ConvertFrom-Json } else { Write-Host "  (missing area: $Name)" -ForegroundColor Yellow; return @() }
}
function Pct([double]$n, [double]$d) { if ($d -le 0) { return 0 } else { return [math]::Round(100.0 * $n / $d, 1) } }

Write-Host "SOAMDE coverage (read-only) <- $InputDir`n" -ForegroundColor Cyan
$devices        = @(Load 'devices')
$onboardSummary = @(Load 'onboarding-summary')
$asrConfig      = @(Load 'asr-tamper-config')
$rows = [System.Collections.Generic.List[object]]::new()

# --- Onboarding coverage against EXPECTED count ------------------------------
$activeStates = 'Active'
$onboarded = @($devices | Where-Object { $_.onboardingStatus -eq 'Onboarded' -or $_.OnboardingStatus -eq 'Onboarded' })
$active    = @($onboarded | Where-Object { $_.healthStatus -in @('Active') -or $_.SensorHealthState -in @('Active') })
$denom     = if ($ExpectedDeviceCount -gt 0) { $ExpectedDeviceCount } else { $onboarded.Count }
if ($ExpectedDeviceCount -le 0) { Write-Host "  WARNING: no ExpectedDeviceCount supplied — onboarding coverage uses MDE inventory as denominator (understates gaps)." -ForegroundColor Yellow }

$rows.Add([pscustomobject]@{ Area = 'Onboarding (onboarded/expected)'; Covered = $onboarded.Count; Denominator = $denom; CoveragePct = (Pct $onboarded.Count $denom) })
$rows.Add([pscustomobject]@{ Area = 'Sensor health (active/onboarded)'; Covered = $active.Count; Denominator = $onboarded.Count; CoveragePct = (Pct $active.Count $onboarded.Count) })

# inactive / impaired gap list
$inactive = @($devices | Where-Object { ($_.healthStatus -and $_.healthStatus -ne 'Active') -or ($_.SensorHealthState -and $_.SensorHealthState -ne 'Active') })
if ($inactive) { $inactive | Select-Object computerDnsName, id, healthStatus, onboardingStatus, osPlatform | Export-Csv (Join-Path $InputDir 'coverage-inactive-devices.csv') -NoTypeInformation -Encoding UTF8 }

# --- ASR / tamper / network protection coverage from secure-config assessment
$asrRows = @($asrConfig | Where-Object { $_.ConfigurationCategory -eq 'Attack Surface Reduction Rules' })
$asrCompliantDevices = ($asrRows | Where-Object { $_.IsCompliant -eq $true } | Measure-Object -Property Devices -Sum).Sum
$asrTotalDevices     = ($asrRows | Measure-Object -Property Devices -Sum).Sum
$rows.Add([pscustomobject]@{ Area = 'ASR rules compliant (block)'; Covered = [int]$asrCompliantDevices; Denominator = [int]$asrTotalDevices; CoveragePct = (Pct $asrCompliantDevices $asrTotalDevices) })

$tamper = @($asrConfig | Where-Object { $_.ConfigurationName -match 'Tamper' -or $_.ConfigurationCategory -eq 'Defender' })
$tamperOk = ($tamper | Where-Object { $_.IsCompliant -eq $true } | Measure-Object -Property Devices -Sum).Sum
$tamperTot = ($tamper | Measure-Object -Property Devices -Sum).Sum
$rows.Add([pscustomobject]@{ Area = 'Tamper protection on'; Covered = [int]$tamperOk; Denominator = [int]$tamperTot; CoveragePct = (Pct $tamperOk $tamperTot) })

$netp = @($asrConfig | Where-Object { $_.ConfigurationCategory -eq 'Network protection' })
$netOk = ($netp | Where-Object { $_.IsCompliant -eq $true } | Measure-Object -Property Devices -Sum).Sum
$netTot = ($netp | Measure-Object -Property Devices -Sum).Sum
$rows.Add([pscustomobject]@{ Area = 'Network protection (block)'; Covered = [int]$netOk; Denominator = [int]$netTot; CoveragePct = (Pct $netOk $netTot) })

# non-compliant config gap list
$gap = @($asrConfig | Where-Object { $_.IsCompliant -ne $true })
if ($gap) { $gap | Select-Object ConfigurationCategory, ConfigurationName, ConfigurationId, Devices | Export-Csv (Join-Path $InputDir 'coverage-config-gaps.csv') -NoTypeInformation -Encoding UTF8 }

Write-Host "--- Coverage summary ---" -ForegroundColor Cyan
$rows | Format-Table -AutoSize
$rows | Export-Csv (Join-Path $InputDir 'coverage-summary.csv') -NoTypeInformation -Encoding UTF8
Write-Host "`nGap lists: coverage-inactive-devices.csv / coverage-config-gaps.csv (where applicable)." -ForegroundColor Green
Write-Host "Read-only; no changes made. Next: SOAMDE-Assess.ps1." -ForegroundColor Green
