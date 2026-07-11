<#
.SYNOPSIS
    SOPMDE-Report.ps1 — before/after metrics for the tuning engagement: alert volume,
    false-positive proportion, ASR block coverage, and onboarding/sensor-health coverage.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Solution Optimization — Microsoft Defender for Endpoint"
        solution. Computes the key optimization metrics from advanced hunting and the machines
        API, and — with -SaveBaseline — writes them as the 'before' snapshot. On later runs,
        -BaselinePath compares current metrics to the baseline so the improvement is measurable
        (this is what proves the deployment got better). Makes no changes.
    HOW TO RUN
        # Capture the BEFORE baseline (Implementation Step 1):
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Report.ps1 -SaveBaseline
        # Measure the AFTER delta (Implementation Step 6):
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Report.ps1 -BaselinePath .\sopmde-baseline.json
        Requires Microsoft.Graph.Authentication with ThreatHunting.Read.All (+ Machine.Read.All).
    EXPECTED RESULTS
        A metrics block (alert volume, FP proportion, ASR block coverage, sensor-health coverage).
        With -SaveBaseline: writes sopmde-baseline.json. With -BaselinePath: prints the delta
        for each metric versus the baseline.
.NOTES
    White-label. Read-only. FP proportion is derived from alert determination/classification where
    set by analysts; ensure analysts classify alerts for this metric to be meaningful.
#>
[CmdletBinding()]
param(
    [switch]$SaveBaseline,
    [string]$BaselinePath,
    [int]$LookbackDays = 14,
    [string]$OutFile = ".\sopmde-baseline.json"
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Machine.Read.All' -NoWelcome | Out-Null }

function Run-Kql($kql) {
    try {
        $body = @{ Query = $kql } | ConvertTo-Json
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
        return $r.results
    } catch { return @() }
}

Write-Host "`n=== SOPMDE before/after metrics (read-only) ===" -ForegroundColor Cyan
$metrics = [ordered]@{ Timestamp = (Get-Date).ToString('s'); LookbackDays = $LookbackDays }

# --- Alert volume + false-positive proportion ---
$alertRows = Run-Kql @"
let Window = ${LookbackDays}d;
AlertInfo
| where Timestamp > ago(Window)
| summarize Total = count(),
            FalsePositive = countif(Category == 'FalsePositive' or DetectionSource == '')
| extend AnyDetermination = Total
"@
$total = 0; $fp = 0
if ($alertRows -and $alertRows.Count -gt 0) { $total = [int]$alertRows[0].Total; $fp = [int]$alertRows[0].FalsePositive }
$fpPct = if ($total) { [math]::Round(100.0 * $fp / $total, 1) } else { 0 }
$metrics.AlertVolume = $total
$metrics.FalsePositivePct = $fpPct
Write-Host ("   Alert volume ({0}d) ......... {1}" -f $LookbackDays, $total)
Write-Host ("   False-positive proportion .. {0}%" -f $fpPct)

# --- ASR block coverage (share of ASR events that are enforced vs audited) ---
$asrRows = Run-Kql @"
let Window = ${LookbackDays}d;
DeviceEvents
| where Timestamp > ago(Window) and ActionType startswith 'Asr'
| summarize Blocked = countif(ActionType endswith 'Blocked'),
            Audited = countif(ActionType endswith 'Audited')
"@
$blk = 0; $aud = 0
if ($asrRows -and $asrRows.Count -gt 0) { $blk = [int]$asrRows[0].Blocked; $aud = [int]$asrRows[0].Audited }
$asrCovPct = if (($blk + $aud) -gt 0) { [math]::Round(100.0 * $blk / ($blk + $aud), 1) } else { 0 }
$metrics.ASRBlockCoveragePct = $asrCovPct
Write-Host ("   ASR block coverage ......... {0}%  (blocked {1} / audited {2})" -f $asrCovPct, $blk, $aud)

# --- Onboarding / sensor-health coverage ---
$sensorPct = 0
try {
    $m = Invoke-MgGraphRequest -Method GET -Uri 'https://api.securitycenter.microsoft.com/api/machines' -ErrorAction SilentlyContinue
    if ($m -and $m.value) {
        $t = $m.value.Count; $a = ($m.value | Where-Object { $_.healthStatus -eq 'Active' }).Count
        $sensorPct = if ($t) { [math]::Round(100.0 * $a / $t, 1) } else { 0 }
    }
} catch {}
$metrics.SensorHealthCoveragePct = $sensorPct
Write-Host ("   Sensor-health coverage ..... {0}%" -f $sensorPct)

# --- Save or compare ---
if ($SaveBaseline) {
    $metrics | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host ("`nBaseline saved: {0}  (this is the 'before' — tune, then re-run with -BaselinePath)" -f $OutFile) -ForegroundColor Green
} elseif ($BaselinePath -and (Test-Path $BaselinePath)) {
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    Write-Host "`n-- Delta vs baseline (improvement = noise/FP down, coverage up) --" -ForegroundColor Cyan
    function Delta($label, $now, $was, $lowerIsBetter) {
        $d = [math]::Round($now - $was, 1)
        $good = if ($lowerIsBetter) { $d -le 0 } else { $d -ge 0 }
        $arrow = if ($d -eq 0) { '=' } elseif ($d -gt 0) { '+' } else { '' }
        Write-Host ("   {0,-28} {1} -> {2}  ({3}{4})" -f $label, $was, $now, $arrow, $d) -ForegroundColor $(if ($good) { 'Green' } else { 'Yellow' })
    }
    Delta 'Alert volume'            $metrics.AlertVolume            $base.AlertVolume            $true
    Delta 'False-positive %'        $metrics.FalsePositivePct       $base.FalsePositivePct       $true
    Delta 'ASR block coverage %'    $metrics.ASRBlockCoveragePct    $base.ASRBlockCoveragePct    $false
    Delta 'Sensor-health coverage %' $metrics.SensorHealthCoveragePct $base.SensorHealthCoveragePct $false
} else {
    Write-Host "`n(No -SaveBaseline and no valid -BaselinePath — metrics shown above only.)" -ForegroundColor DarkGray
}
