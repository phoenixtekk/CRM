<#
.SYNOPSIS
    SOAMDI-Assess.ps1 — read-only scoring of Defender for Identity posture against a named best-practice baseline.
.DESCRIPTION
    PURPOSE
        Evaluates the discovery/coverage evidence as checks, each scored Pass / Partial / Fail / N-A
        against the named baseline (Microsoft MDI guidance + identity Secure Score, and/or the org
        standard). Every non-pass gets a severity (an un-sensored DC = High) and becomes a finding with
        evidence and a remediation pointer. Areas roll up into a weighted posture score (%). Absent roles
        (e.g. no AD CS in the environment) are scored N-A, not Fail. Items still needing portal
        confirmation carry a 'verify' note rather than a false Fail.
    HOW TO RUN
        pwsh -File .\SOAMDI-Assess.ps1 -InputDir ".\SOAMDI-Run - 2026-07-11 - Assess" -Baseline "MDI guidance + identity Secure Score (2026-07, verify)" -OutputCsv ".\SOAMDI-Scorecard - Forest - Assess.csv"
        Run SOAMDI-Discovery.ps1 and SOAMDI-Coverage.ps1 first.
    EXPECTED RESULTS
        A scorecard CSV + findings.json in the run folder, and a posture score to console.
.NOTES
    White-label. Read-only. Scoring only. Risk-acceptance is the customer's decision.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$InputDir,
    [string]$Baseline = 'Microsoft Defender for Identity guidance + identity Secure Score (verify current guidance)',
    [Parameter(Mandatory = $true)] [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'
$coverage = if (Test-Path (Join-Path $InputDir 'coverage-summary.csv')) { @(Import-Csv (Join-Path $InputDir 'coverage-summary.csv')) } else { @() }
$blind    = if (Test-Path (Join-Path $InputDir 'coverage-blindspots.csv')) { @(Import-Csv (Join-Path $InputDir 'coverage-blindspots.csv')) } else { @() }
function Cov([string]$area) { $r = $coverage | Where-Object { $_.Area -like "*$area*" } | Select-Object -First 1; return $r }

$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check($id, $area, $desc, $weight, $result, $severity, $evidence, $remediation) {
    $checks.Add([pscustomobject]@{
        CheckId = $id; Area = $area; Description = $desc; Weight = $weight
        Result = $result; Severity = $(if ($result -in @('Pass','N-A')) { '' } else { $severity })
        Evidence = $evidence; Remediation = $remediation; Baseline = $Baseline
    })
}
function GradePct($r, [double]$passAt = 100, [double]$partialAt = 80) {
    if (-not $r) { return @('N-A', $null) }
    $p = $null; [double]::TryParse(("$($r.CoveragePct)"), [ref]$p) | Out-Null
    if ($null -eq $p) { return @('N-A', $r.CoveragePct) }
    if ($p -ge $passAt) { return @('Pass', $p) } elseif ($p -ge $partialAt) { return @('Partial', $p) } else { return @('Fail', $p) }
}

# --- DC sensor coverage (the critical check) ---------------------------------
$dc = Cov 'DC sensor coverage'
$g = GradePct $dc 100 90
$dcBlind = @($blind | Where-Object { $_.Role -eq 'DomainController' })
Add-Check 'MDI-01' 'Sensor coverage' 'Every domain controller has a healthy MDI sensor' 4 $g[0] 'High' "DC coverage = $($g[1])%; un-sensored DCs = $($dcBlind.Count) (see coverage-blindspots.csv)" 'Install/repair MDI sensors on all un-sensored DCs (Remediation Playbook, pilot-first).'

# --- AD FS / AD CS coverage --------------------------------------------------
$adfs = Cov 'AD FS sensor coverage'
$gf = GradePct $adfs 100 80
Add-Check 'MDI-02' 'Sensor coverage' 'AD FS servers have an MDI sensor (where present)' 2 $gf[0] 'High' "AD FS coverage = $($gf[1])%" 'Install MDI sensors on AD FS servers; they are prime credential-theft targets.'
$adcs = Cov 'AD CS sensor coverage'
$gc = GradePct $adcs 100 80
Add-Check 'MDI-03' 'Sensor coverage' 'AD CS servers have an MDI sensor (where present)' 2 $gc[0] 'High' "AD CS coverage = $($gc[1])%" 'Install MDI sensors on AD CS servers to detect certificate-based attacks.'

# --- DSA ---------------------------------------------------------------------
$dsa = Cov 'Directory service account'
Add-Check 'MDI-04' 'Directory service account' 'DSA present and hardened (gMSA, least privilege)' 2 'Partial' 'Medium' "DSA: $($dsa.CoveragePct) — confirm in portal (verify)" 'Confirm a least-privilege gMSA DSA is configured; replace password-based/over-privileged accounts.'

# --- Honeytokens -------------------------------------------------------------
$hy = Cov 'Honeytoken'
$hyResult = if ("$($hy.CoveragePct)" -match 'present') { 'Pass' } else { 'Fail' }
Add-Check 'MDI-05' 'Honeytokens' 'Honeytoken accounts exist and are tagged' 2 $hyResult 'Medium' "honeytoken signal: $($hy.CoveragePct)" 'Plant and tag honeytoken accounts as high-fidelity tripwires (confirm in Entity tags).'

# --- ISPM --------------------------------------------------------------------
$controls = if (Test-Path (Join-Path $InputDir 'secure-score-controls.json')) { @(Get-Content (Join-Path $InputDir 'secure-score-controls.json') -Raw | ConvertFrom-Json) } else { @() }
$openIspm = @($controls | Where-Object { $_.implementationStatus -notmatch 'Completed|Resolved' })
$ispmResult = if ($controls.Count -eq 0) { 'N-A' } elseif ($openIspm.Count -eq 0) { 'Pass' } elseif ($openIspm.Count -le 5) { 'Partial' } else { 'Fail' }
Add-Check 'MDI-06' 'ISPM' 'Identity posture (ISPM) recommendations worked down' 2 $ispmResult 'Medium' "open identity recommendations = $($openIspm.Count) of $($controls.Count)" 'Work the ISPM backlog: unsecure protocols, risky delegations, exposed credentials.'

# --- Detection tuning signal -------------------------------------------------
$events = if (Test-Path (Join-Path $InputDir 'identity-directory-events-30d.json')) { @(Get-Content (Join-Path $InputDir 'identity-directory-events-30d.json') -Raw | ConvertFrom-Json) } else { @() }
$tuneResult = if ($events.Count -eq 0) { 'N-A' } else { 'Partial' }
Add-Check 'MDI-07' 'Detection tuning' 'Detections active and reasonably tuned (not blind, not noisy)' 1 $tuneResult 'Low' "identity directory event types seen (30d) = $($events.Count) — review exclusions in portal (verify)" 'Review detection exclusions and action-account scope; avoid over-exclusion (blind) and under-tuning (noise).'

# --- Roll-up -----------------------------------------------------------------
$scoreable = $checks | Where-Object { $_.Result -ne 'N-A' }
$map = @{ 'Pass' = 1.0; 'Partial' = 0.5; 'Fail' = 0.0 }
$wsum = ($scoreable | Measure-Object -Property Weight -Sum).Sum
$ach = 0.0; foreach ($c in $scoreable) { $ach += ($map[$c.Result] * $c.Weight) }
$posture = if ($wsum -gt 0) { [math]::Round(100.0 * $ach / $wsum, 1) } else { 0 }

$checks | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
($checks | Where-Object { $_.Result -in @('Fail','Partial') }) | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $InputDir 'findings.json') -Encoding UTF8

Write-Host "SOAMDI posture score: $posture% against baseline: $Baseline`n" -ForegroundColor Cyan
$checks | Select-Object CheckId, Area, Result, Severity, Description | Format-Table -AutoSize
Write-Host "`nScorecard: $OutputCsv  |  Findings: findings.json  (N-A = role absent/inapplicable; 'verify' = confirm in portal)" -ForegroundColor Green
Write-Host "Read-only. Risk-acceptance & remediation priority are the security owners' decisions." -ForegroundColor Green
