<#
.SYNOPSIS
    PURVIEW-MaturityScore.ps1 — score the ten Purview domains against the maturity rubric (read-only).
.DESCRIPTION
    PURPOSE
        Applies the "Purview Maturity Model - 10 Domains x 6 Levels" rubric to the evidence collected
        by PURVIEW-Discovery.ps1 and emits the Purview Maturity Scorecard: a 0-5 score per domain with
        the evidence sentence behind it, and a weighted overall maturity band. Read-only — it evaluates,
        it does not change the tenant. Licensing-capped domains are scored against their achievable
        ceiling and flagged, never silently zeroed.
    HOW TO RUN
        # 1) produce evidence:  .\PURVIEW-Discovery.ps1 -JsonPath .\purview-evidence.json
        # 2) score it:
        powershell -ExecutionPolicy Bypass -File .\PURVIEW-MaturityScore.ps1 -EvidencePath .\purview-evidence.json
        # optional: supply target levels + weights to compute gap and a weighted band
        .\PURVIEW-MaturityScore.ps1 -EvidencePath .\purview-evidence.json -TargetLevel 3 -CsvPath .\scorecard.csv
    EXPECTED RESULTS
        A scorecard table (Domain, Score L0-L5, Evidence, Target, Gap) and the weighted overall band,
        optionally exported to CSV for the readout.
.NOTES
    White-label — Purview Solutions. READ-ONLY (scoring/analysis; no tenant writes).
    The rubric is deterministic and transparent; adjust thresholds/weights to your agreed model.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$EvidencePath,
    [ValidateRange(0,5)][int]$TargetLevel = 3,
    [hashtable]$Weights,
    [string]$CsvPath
)

if (-not (Test-Path $EvidencePath)) { throw "Evidence file not found: $EvidencePath. Run PURVIEW-Discovery.ps1 -JsonPath first." }
$evidence = Get-Content $EvidencePath -Raw | ConvertFrom-Json

# Default equal weighting; override with -Weights @{ D3=2; D6=2; D7=2 } for a regulated profile.
$defaultWeights = @{ D1=1; D2=1; D3=1; D4=1; D5=1; D6=1; D7=1; D8=1; D9=1; D10=1 }
if ($Weights) { foreach ($k in $Weights.Keys) { $defaultWeights[$k] = $Weights[$k] } }

$levelName = @('L0 Absent','L1 Initial','L2 Developing','L3 Defined','L4 Managed','L5 Optimized')

# Transparent rubric: map a domain's evidence signal to 0-5. Absent/unreadable => 0 (flagged).
function Score-Domain {
    param($e)
    if (-not $e.Readable) { return @{ Score = 0; Why = "unreadable/unlicensed — verify your licensing/tenant" } }
    $s = [string]$e.Signal
    # Parse the first integer following each known token, defaulting to 0.
    function Num([string]$token) {
        if ($s -match "$token=(\d+)") { return [int]$Matches[1] } else { return 0 }
    }
    switch -Regex ($e.Key) {
        'D1' {
            $labels = Num 'labels'; $pols = Num 'labelPolicies'; $auto = Num 'autoLabelPolicies'
            if ($labels -eq 0) { return @{ Score=0; Why=$s } }
            if ($pols  -eq 0) { return @{ Score=1; Why="labels exist but none published — $s" } }
            if ($auto  -eq 0) { return @{ Score=2; Why="labels published, no auto-labeling — $s" } }
            return @{ Score=3; Why="labels published with auto-labeling — $s (L4/L5 require measured/automated evidence — confirm manually)" }
        }
        'D2' {
            $dlp = Num 'dlpPolicies'; $enf = Num 'enforcing'
            if ($dlp -eq 0) { return @{ Score=0; Why=$s } }
            if ($enf -eq 0) { return @{ Score=2; Why="DLP present, all in test/audit — $s" } }
            return @{ Score=3; Why="DLP enforcing — $s (L4/L5 require tuning/reporting evidence — confirm manually)" }
        }
        'D3' {
            $tags = Num 'retentionLabels'; $rpol = Num 'retentionPolicies'; $rec = Num 'recordLabels'
            if ($tags -eq 0 -and $rpol -eq 0) { return @{ Score=0; Why=$s } }
            if ($rpol -eq 0) { return @{ Score=1; Why="retention labels only, no policy — $s" } }
            if ($rec  -eq 0) { return @{ Score=2; Why="retention policy present, no records — $s" } }
            return @{ Score=3; Why="retention + records present — $s (schedule correctness = records/legal determination)" }
        }
        'D4' { $p = Num 'insiderRiskPolicies'; if ($p -eq 0) { return @{ Score=0; Why=$s } } return @{ Score=2; Why="insider-risk policy present (HR/legal-gated) — $s" } }
        'D5' { $p = Num 'commCompliancePolicies'; if ($p -eq 0) { return @{ Score=0; Why=$s } } return @{ Score=2; Why="comm-compliance policy present (HR/legal-gated) — $s" } }
        'D6' {
            if ($s -match 'UnifiedAuditLogIngestionEnabled=True') { return @{ Score=3; Why="unified audit log ON — $s (Premium/SIEM = L4/L5, confirm)" } }
            return @{ Score=0; Why="unified audit log OFF — $s" }
        }
        'D7' { $c = Num 'eDiscoveryCases'; if ($c -eq 0) { return @{ Score=1; Why="eDiscovery available, no cases — $s" } } return @{ Score=3; Why="eDiscovery in use — $s" } }
        default {
            # D8/D9/D10 are portal/preview-surfaced — score conservatively and require manual confirmation.
            return @{ Score=0; Why="portal/preview-surfaced — verify in the Purview portal and set manually — $s" }
        }
    }
}

Write-Host "`n=== Purview Maturity Scorecard (Purview Maturity Model - 10 Domains x 6 Levels) ===" -ForegroundColor Cyan
Write-Host ("Target level: L{0} for all domains (override per domain in your agreed model)`n" -f $TargetLevel)

$rows = @()
$weightedSum = 0.0; $weightTotal = 0.0
foreach ($e in $evidence) {
    $r = Score-Domain $e
    $w = if ($defaultWeights.ContainsKey($e.Key)) { $defaultWeights[$e.Key] } else { 1 }
    $gap = [Math]::Max(0, $TargetLevel - $r.Score)
    $rows += [pscustomobject]@{
        Domain   = $e.Domain
        Key      = $e.Key
        Score    = $r.Score
        Level    = $levelName[$r.Score]
        Target   = "L$TargetLevel"
        Gap      = $gap
        Weight   = $w
        Evidence = $r.Why
    }
    $weightedSum += ($r.Score * $w); $weightTotal += $w
}

$rows | Sort-Object Key | Format-Table Key, @{n='Score';e={$_.Level}}, Target, Gap, Weight, Evidence -Wrap -AutoSize

$overall = if ($weightTotal -gt 0) { [Math]::Round($weightedSum / $weightTotal, 2) } else { 0 }
$overallBand = $levelName[[int][Math]::Floor($overall)]
Write-Host ("`nWeighted overall maturity: {0} / 5  ->  {1}" -f $overall, $overallBand) -ForegroundColor Green
Write-Host "Domains below target (roadmap candidates):" -ForegroundColor Yellow
$rows | Where-Object { $_.Gap -gt 0 } | Sort-Object -Descending Gap | ForEach-Object {
    Write-Host ("  {0} {1}: {2} -> L{3} (gap {4})" -f $_.Key, ($_.Domain -replace '^D\d+\s'), $_.Level, $TargetLevel, $_.Gap)
}

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "`nScorecard exported to $CsvPath" -ForegroundColor Green }
Write-Host "`nNote: L4/L5 (Managed/Optimized) and D8-D10 need measured/manual confirmation — see the rubric in the Implementation Guide." -ForegroundColor DarkGray
Write-Host "Next: build the Purview Maturity Roadmap - 3 Horizons from the gaps for the readout." -ForegroundColor Green
