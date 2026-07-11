<#
.SYNOPSIS
    SOAREM-Rescore.ps1 — read-only re-score after remediation; compares the new posture score to the
    pre-change baseline to prove the finding closed.
.DESCRIPTION
    PURPOSE
        The objective proof of closure. Takes a fresh posture-score file (produced by re-running the
        relevant assessment's *-Score.ps1 after the change) and compares it to the pre-change baseline
        captured before remediation. Reports the per-domain and overall DELTA — a rise proves the fix
        moved the needle. READ-ONLY — it compares scores; it changes nothing.
    HOW TO RUN
        # 1) Re-run the relevant assessment score (e.g. SOAMCA-Score.ps1) AFTER the change, then:
        powershell -ExecutionPolicy Bypass -File .\SOAREM-Rescore.ps1 `
            -BaselinePath ".\Rescore Baseline - Defender SOA - Assess.json" `
            -NewScorePath ".\Posture Score - Cloud Apps - Pilot (post-change).json" `
            -OutputPath ".\Rescore Result - Defender SOA - Validate.json"
    EXPECTED RESULTS
        A delta report: baseline vs new per-domain and overall scores, with the improvement (or note if
        flat — allow warm-up). This is the evidence the finding closed.
.NOTES
    White-label. Read-only. Secure Score / Defender assessments take time to reflect a change — allow a
    warm-up window before trusting a flat re-score. A verified control with a flat score may not be the
    exact scored control; investigate before claiming closure.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaselinePath,
    [Parameter(Mandatory)][string]$NewScorePath,
    [string]$OutputPath = ".\Rescore Result - Defender SOA - Validate.json"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $BaselinePath)) { throw "Pre-change baseline not found: $BaselinePath." }
if (-not (Test-Path $NewScorePath)) { throw "New score not found: $NewScorePath. Re-run the relevant assessment score after the change first." }
$before = Get-Content $BaselinePath -Raw | ConvertFrom-Json
$after  = Get-Content $NewScorePath -Raw | ConvertFrom-Json

$deltas = [ordered]@{}
foreach ($domain in $after.domainScores.PSObject.Properties.Name) {
    $b = if ($before.domainScores.$domain) { [double]$before.domainScores.$domain.score } else { $null }
    $a = [double]$after.domainScores.$domain.score
    $deltas[$domain] = [ordered]@{ before = $b; after = $a; delta = if ($b -ne $null) { [math]::Round($a - $b, 1) } else { 'n/a' } }
}
$overallDelta = [math]::Round([double]$after.overallScore - [double]$before.overallScore, 1)

$verdict = if ($overallDelta -gt 0) { "IMPROVED (+$overallDelta) — finding(s) moving toward closure" }
           elseif ($overallDelta -eq 0) { "FLAT — allow warm-up and re-run; or the change may not affect the scored control" }
           else { "REGRESSED ($overallDelta) — investigate; a change may have introduced a new gap" }

$out = [ordered]@{
    solution      = "SOAREM"
    generatedUtc  = (Get-Date).ToUniversalTime().ToString("o")
    readOnly      = $true
    sourceSolution= $after.solution
    overallBefore = $before.overallScore
    overallAfter  = $after.overallScore
    overallDelta  = $overallDelta
    domainDeltas  = $deltas
    verdict       = $verdict
    note          = "Re-score is the objective proof of closure. Allow warm-up before trusting a flat result (Global Requirements G5)."
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Re-score (read-only):" -ForegroundColor Cyan
Write-Host ("  OVERALL {0} -> {1}  (delta {2})" -f $before.overallScore, $after.overallScore, $overallDelta) -ForegroundColor Green
foreach ($domain in $deltas.Keys) {
    $d = $deltas[$domain]
    Write-Host ("  {0,-22} {1} -> {2}  (delta {3})" -f $domain, $d.before, $d.after, $d.delta)
}
Write-Host ("Verdict: {0}" -f $verdict) -ForegroundColor Yellow
Write-Host "Written: $OutputPath" -ForegroundColor Green
