<#
.SYNOPSIS
    SOAMDC-Score.ps1 — compute deterministic per-domain and overall posture scores for Defender for
    Cloud against the recommended baseline. Read-only.
.DESCRIPTION
    PURPOSE
        Consumes the validation output (SOAMDC-Validate.ps1) and computes a posture score per domain
        and an overall weighted score (0-100). Scoring is DETERMINISTIC for a fixed input so runs are
        comparable. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOAMDC-Score.ps1 `
            -ValidationPath ".\SOAMDC-validation.json" `
            -OutputPath ".\Posture Score - Defender for Cloud - Pilot.json"
    SCORING MODEL (default weights — edit here to re-weight; record the change in SOA Scope):
        secureScore          = 25   (the headline posture measure)
        planCoverage         = 30   (protection only exists where the plan is on)
        regulatoryCompliance = 20   (mapped standard + pass rate)
        agentCoverage        = 25   (unassessed machines are blind spots)
        Domain score = (passed controls / total controls) * 100. Overall = weighted average.
    EXPECTED RESULTS
        A JSON score record: per-domain score, weight, overall score, band, and run date.
.NOTES
    White-label. Read-only. The baseline this scores against evolves — verify current Microsoft
    guidance each cycle. Weights are a starting point, not a mandate.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ValidationPath,
    [string]$OutputPath = ".\Posture Score - Defender for Cloud - Pilot.json"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ValidationPath)) { throw "Validation output not found: $ValidationPath. Run SOAMDC-Validate.ps1 first." }
$validation = Get-Content $ValidationPath -Raw | ConvertFrom-Json

$weights = [ordered]@{
    secureScore          = 25
    planCoverage         = 30
    regulatoryCompliance = 20
    agentCoverage        = 25
}

$domainScores = [ordered]@{}
foreach ($domain in $weights.Keys) {
    $domainChecks = @($validation.checks | Where-Object { $_.domain -eq $domain })
    $total = $domainChecks.Count
    $passed = @($domainChecks | Where-Object { $_.result -eq 'Pass' }).Count
    $score = if ($total -gt 0) { [math]::Round(($passed / $total) * 100, 1) } else { 0 }
    $domainScores[$domain] = [ordered]@{ passed=$passed; total=$total; score=$score; weight=$weights[$domain] }
}

$weightSum = ($weights.Values | Measure-Object -Sum).Sum
$weighted = 0.0
foreach ($domain in $weights.Keys) { $weighted += ($domainScores[$domain].score * $weights[$domain]) }
$overall = [math]::Round($weighted / $weightSum, 1)

$band = switch ($overall) {
    { $_ -ge 85 } { 'Strong' ; break }
    { $_ -ge 65 } { 'Moderate' ; break }
    { $_ -ge 40 } { 'Weak' ; break }
    default        { 'Critical' }
}

$out = [ordered]@{
    solution     = "SOAMDC"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    readOnly     = $true
    domainScores = $domainScores
    overallScore = $overall
    band         = $band
    note         = "Deterministic score vs recommended baseline. Verify current Microsoft guidance; weights configurable in the header. Plan-off findings carry a cost the customer accepts."
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Posture score (read-only):" -ForegroundColor Cyan
foreach ($domain in $weights.Keys) {
    $d = $domainScores[$domain]
    Write-Host ("  {0,-22} {1,5}/100  (w{2})  [{3}/{4} controls]" -f $domain, $d.score, $d.weight, $d.passed, $d.total)
}
Write-Host ("OVERALL: {0}/100 — {1}" -f $overall, $band) -ForegroundColor Green
Write-Host "Written: $OutputPath" -ForegroundColor Green
