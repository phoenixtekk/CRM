<#
.SYNOPSIS
    RMMTUNE-Validation — Compare post-tune metrics against the baseline and emit PASS/FAIL.

.DESCRIPTION
    Part of the "RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting" solution
    (Validate phase). Loads the "Alert Inventory & Baseline – RMM Estate – Assess" baseline (JSON,
    from RMMTUNE-Set-AlertBaseline.ps1) and a post-tune report row, then evaluates the testing gates:

      Gate 1 — Noise reduced vs baseline (alerts/endpoint/day down by >= NoiseTargetPct).
      Gate 2 — % actionable increased (>= ActionableTargetPct).
      Gate 3 — No missed criticals (MissedCriticals must be 0; non-waivable).
      Gate 4 — Alert-to-ticket mapping correct (pass via -TicketMappingPass).

    Read-only: consumes metric files/parameters and prints results. It changes nothing live.

.PARAMETER BaselinePath
    Path to the baseline JSON produced in the Assess phase.

.PARAMETER PostAlertsPerEndpointPerDay
    Post-tune alerts/endpoint/day (from RMMTUNE-Report.ps1).

.PARAMETER PostPctActionable
    Post-tune % actionable.

.PARAMETER MissedCriticals
    Count of criticals that should have alerted but did not (Gate 3). Default 0.

.PARAMETER NoiseTargetPct
    Required minimum % reduction in alerts/endpoint/day. Default 50.

.PARAMETER ActionableTargetPct
    Required minimum post-tune % actionable. Default 60.

.PARAMETER TicketMappingPass
    Switch indicating Gate 4 (alert-to-ticket mapping) was verified correct.

.EXAMPLE
    .\RMMTUNE-Validation.ps1 -BaselinePath .\RMMTUNE-baseline.json `
        -PostAlertsPerEndpointPerDay 0.9 -PostPctActionable 68 -MissedCriticals 0 -TicketMappingPass

.NOTES
    Managed — read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BaselinePath,

    [Parameter(Mandatory = $true)]
    [double]$PostAlertsPerEndpointPerDay,

    [double]$PostPctActionable,

    [int]$MissedCriticals = 0,

    [double]$NoiseTargetPct = 50,
    [double]$ActionableTargetPct = 60,

    [switch]$TicketMappingPass
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $BaselinePath)) { throw "Baseline not found: $BaselinePath" }
$base = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json

$baseNoise = [double]$base.AlertsPerEndpointPerDay
if ($baseNoise -le 0) { throw "Baseline AlertsPerEndpointPerDay is not usable: $baseNoise" }

$noiseReductionPct = [math]::Round((($baseNoise - $PostAlertsPerEndpointPerDay) / $baseNoise) * 100, 2)

$results = New-Object System.Collections.Generic.List[object]

# Gate 1 — Noise reduced
$g1 = $noiseReductionPct -ge $NoiseTargetPct
$results.Add([pscustomobject]@{
    Gate   = "1 - Noise reduced vs baseline"
    Detail = "baseline=$baseNoise post=$PostAlertsPerEndpointPerDay reduction=$noiseReductionPct% (target >= $NoiseTargetPct%)"
    Result = if ($g1) { "PASS" } else { "FAIL" }
})

# Gate 2 — % actionable increased
$g2 = $false
$g2detail = "no PostPctActionable supplied"
if ($PSBoundParameters.ContainsKey('PostPctActionable')) {
    $basePct = if ($null -ne $base.PctActionable) { [double]$base.PctActionable } else { $null }
    $g2 = $PostPctActionable -ge $ActionableTargetPct -and ($null -eq $basePct -or $PostPctActionable -ge $basePct)
    $g2detail = "baseline=$basePct post=$PostPctActionable (target >= $ActionableTargetPct% and >= baseline)"
}
$results.Add([pscustomobject]@{
    Gate   = "2 - % actionable increased"
    Detail = $g2detail
    Result = if ($g2) { "PASS" } else { "FAIL" }
})

# Gate 3 — No missed criticals (non-waivable)
$g3 = $MissedCriticals -eq 0
$results.Add([pscustomobject]@{
    Gate   = "3 - No missed criticals (non-waivable)"
    Detail = "missed criticals = $MissedCriticals (must be 0)"
    Result = if ($g3) { "PASS" } else { "FAIL" }
})

# Gate 4 — Alert-to-ticket mapping correct
$g4 = [bool]$TicketMappingPass
$results.Add([pscustomobject]@{
    Gate   = "4 - Alert-to-ticket mapping correct"
    Detail = if ($g4) { "verified via -TicketMappingPass" } else { "not verified (pass -TicketMappingPass after manual check)" }
    Result = if ($g4) { "PASS" } else { "FAIL" }
})

Write-Host "RMMTUNE-Validation — Tuning Baseline Report gates (read-only):" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$overall = ($g1 -and $g2 -and $g3 -and $g4)
if ($overall) {
    Write-Host "OVERALL: PASS — safe to roll tuned policies beyond the pilot client." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "OVERALL: FAIL — do not roll out; re-tune the failing gate(s) and re-validate." -ForegroundColor Red
    if (-not $g3) { Write-Host "Gate 3 is non-waivable: a real critical was missed." -ForegroundColor Red }
    exit 1
}
