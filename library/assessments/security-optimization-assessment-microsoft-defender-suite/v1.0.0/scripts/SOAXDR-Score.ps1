<#
.SYNOPSIS
    SOAXDR-Score.ps1 — compute deterministic per-domain and overall suite posture scores for the
    Microsoft Defender suite against the recommended baseline. Read-only.
.DESCRIPTION
    PURPOSE
        Consumes the validation output (SOAXDR-Validate.ps1) and computes a posture score per domain
        and an overall weighted suite score (0-100). Scoring is DETERMINISTIC for a fixed input so runs
        are comparable. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOAXDR-Score.ps1 `
            -ValidationPath ".\SOAXDR-validation.json" `
            -OutputPath ".\Posture Score - Defender Suite - Pilot.json"
    SCORING MODEL (default weights — edit here to re-weight; record the change in SOA Scope):
        crossPillarCoverage = 35   (a dark pillar is a blind spot across the whole story)
        unifiedRbac         = 25   (least-privilege cross-pillar access)
        incidentCorrelation = 20   (the XDR value-add — one story, not five silos)
        suiteSecureScore    = 20   (headline suite posture)
        Domain score = (passed controls / total controls) * 100. Overall = weighted average.
    EXPECTED RESULTS
        A JSON score record: per-domain score, weight, overall score, band, and run date.
.NOTES
    White-label. Read-only. Baseline evolves — verify current Microsoft guidance each cycle. Weights
    are a starting point, not a mandate.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ValidationPath,
    [string]$OutputPath = ".\Posture Score - Defender Suite - Pilot.json"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ValidationPath)) { throw "Validation output not found: $ValidationPath. Run SOAXDR-Validate.ps1 first." }
$validation = Get-Content $ValidationPath -Raw | ConvertFrom-Json

$weights = [ordered]@{
    crossPillarCoverage = 35
    unifiedRbac         = 25
    incidentCorrelation = 20
    suiteSecureScore    = 20
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
    solution     = "SOAXDR"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    readOnly     = $true
    domainScores = $domainScores
    overallScore = $overall
    band         = $band
    note         = "Deterministic suite posture score vs recommended baseline. Verify current Microsoft guidance; weights configurable in the header."
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Suite posture score (read-only):" -ForegroundColor Cyan
foreach ($domain in $weights.Keys) {
    $d = $domainScores[$domain]
    Write-Host ("  {0,-20} {1,5}/100  (w{2})  [{3}/{4} controls]" -f $domain, $d.score, $d.weight, $d.passed, $d.total)
}
Write-Host ("OVERALL: {0}/100 — {1}" -f $overall, $band) -ForegroundColor Green
Write-Host "Written: $OutputPath" -ForegroundColor Green
