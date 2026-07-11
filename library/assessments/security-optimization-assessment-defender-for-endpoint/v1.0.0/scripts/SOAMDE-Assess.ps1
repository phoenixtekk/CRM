<#
.SYNOPSIS
    SOAMDE-Assess.ps1 — read-only scoring of Defender for Endpoint posture against a named best-practice baseline.
.DESCRIPTION
    PURPOSE
        Evaluates the discovery/coverage evidence as a set of checks, each scored Pass / Partial / Fail /
        N-A against the named baseline (Microsoft security baseline + Secure Score endpoint
        recommendations, and/or the org standard). Every non-pass gets a severity (High/Medium/Low) and
        becomes a finding with evidence and a remediation pointer. The areas roll up into a weighted
        posture score (%) so it can be trended. Unlicensed/inapplicable features are scored N-A, not Fail.
    HOW TO RUN
        pwsh -File .\SOAMDE-Assess.ps1 -InputDir ".\SOAMDE-Run - 2026-07-11 - Assess" -Baseline "Microsoft security baseline + Secure Score (2026-07, verify)" -OutputCsv ".\SOAMDE-Scorecard - Fleet - Assess.csv"
        Run SOAMDE-Discovery.ps1 and SOAMDE-Coverage.ps1 first.
    EXPECTED RESULTS
        A scorecard CSV (one row per check) + findings.json in the run folder, and a posture score to console.
.NOTES
    White-label. Read-only. Scoring only; makes no changes. Risk-acceptance is the customer's decision.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$InputDir,
    [string]$Baseline = 'Microsoft security baseline + Secure Score endpoint recommendations (verify current guidance)',
    [Parameter(Mandatory = $true)] [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'
function Load([string]$Name) { $p = Join-Path $InputDir "$Name.json"; if (Test-Path $p) { Get-Content $p -Raw | ConvertFrom-Json } else { @() } }

$devices   = @(Load 'devices')
$asrConfig = @(Load 'asr-tamper-config')
$coverage  = if (Test-Path (Join-Path $InputDir 'coverage-summary.csv')) { Import-Csv (Join-Path $InputDir 'coverage-summary.csv') } else { @() }
function CovPct([string]$area) { $r = $coverage | Where-Object { $_.Area -like "*$area*" } | Select-Object -First 1; if ($r) { [double]$r.CoveragePct } else { $null } }

$checks = [System.Collections.Generic.List[object]]::new()
# weight: relative importance in the rolled-up score. severity: for non-pass findings.
function Add-Check($id, $area, $desc, $weight, $result, $severity, $evidence, $remediation) {
    $checks.Add([pscustomobject]@{
        CheckId = $id; Area = $area; Description = $desc; Weight = $weight
        Result = $result; Severity = $(if ($result -eq 'Pass' -or $result -eq 'N-A') { '' } else { $severity })
        Evidence = $evidence; Remediation = $remediation; Baseline = $Baseline
    })
}
function Grade([double]$pct, [double]$passAt = 95, [double]$partialAt = 70) {
    if ($null -eq $pct) { return 'N-A' }
    if ($pct -ge $passAt) { return 'Pass' } elseif ($pct -ge $partialAt) { return 'Partial' } else { return 'Fail' }
}

# --- Coverage-driven checks --------------------------------------------------
$onb = CovPct 'Onboarding'
Add-Check 'MDE-01' 'Onboarding' 'All in-scope devices onboarded' 3 (Grade $onb) 'High' "onboarding coverage = $onb%" 'Remediation Playbook: onboard missing devices (DEFXDR for deployment).'

$sensor = CovPct 'Sensor health'
Add-Check 'MDE-02' 'Onboarding' 'Onboarded devices report an Active sensor' 2 (Grade $sensor) 'Medium' "active sensor = $sensor%" 'Investigate Inactive/ImpairedCommunication devices (see coverage-inactive-devices.csv).'

$asr = CovPct 'ASR rules compliant'
Add-Check 'MDE-03' 'ASR' 'ASR rules enforcing in Block (not Audit)' 3 (Grade $asr) 'High' "ASR compliant = $asr%" 'Move audit-mode ASR rules to Block, pilot-first, via the Remediation Playbook.'

$tamper = CovPct 'Tamper protection'
Add-Check 'MDE-04' 'Tamper protection' 'Tamper protection enforced on all devices' 3 (Grade $tamper 99 90) 'High' "tamper on = $tamper%" 'Enforce tamper protection tenant-wide; it underpins every other control.'

$netp = CovPct 'Network protection'
Add-Check 'MDE-05' 'Network protection' 'Network protection in Block mode' 1 (Grade $netp) 'Medium' "network protection = $netp%" 'Move network protection from Audit to Block after validation.'

# --- Presence/config checks (from discovery) ---------------------------------
$edrBlock = @($devices | Where-Object { $_.'edrBlockMode' -eq 'Enabled' -or $_.edrBlockModeConfigured -eq $true }).Count
$edrResult = if ($devices.Count -eq 0) { 'N-A' } elseif ($edrBlock -gt 0) { 'Partial' } else { 'Fail' }
Add-Check 'MDE-06' 'EDR block mode' 'EDR in block mode enabled (esp. where non-MS AV is primary)' 2 $edrResult 'Medium' "devices with EDR block mode signal = $edrBlock" 'Enable EDR in block mode; validate no conflict with primary AV.'

$policies = @(Load 'delivery-policies')
# Policy hygiene: overlapping policies targeting the same settings is a hygiene finding (heuristic).
$dupNames = @($policies | Group-Object name | Where-Object { $_.Count -gt 1 })
$hygiene = if ($policies.Count -eq 0) { 'N-A' } elseif ($dupNames.Count -gt 0) { 'Partial' } else { 'Pass' }
Add-Check 'MDE-07' 'Policy hygiene' 'No duplicate/overlapping delivery policies' 1 $hygiene 'Low' "duplicate-named policies = $($dupNames.Count); total policies = $($policies.Count)" 'Consolidate overlapping endpoint security policies to make enforcement deterministic.'

# --- Exposure signal ---------------------------------------------------------
$exposure = Load 'exposure-score'
$expVal = $null; if ($exposure.score) { $expVal = [double]$exposure.score }
$expResult = if ($null -eq $expVal) { 'N-A' } elseif ($expVal -le 30) { 'Pass' } elseif ($expVal -le 50) { 'Partial' } else { 'Fail' }
Add-Check 'MDE-08' 'Exposure' 'Exposure score within acceptable range' 1 $expResult 'Medium' "exposure score = $expVal (lower is better; *verify current scale*)" 'Address top exposure recommendations from TVM; see Secure Score controls.'

# --- Roll-up -----------------------------------------------------------------
$scoreable = $checks | Where-Object { $_.Result -ne 'N-A' }
$map = @{ 'Pass' = 1.0; 'Partial' = 0.5; 'Fail' = 0.0 }
$wsum = ($scoreable | Measure-Object -Property Weight -Sum).Sum
$achieved = 0.0
foreach ($c in $scoreable) { $achieved += ($map[$c.Result] * $c.Weight) }
$posture = if ($wsum -gt 0) { [math]::Round(100.0 * $achieved / $wsum, 1) } else { 0 }

$checks | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
($checks | Where-Object { $_.Result -in @('Fail','Partial') }) | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $InputDir 'findings.json') -Encoding UTF8

Write-Host "SOAMDE posture score: $posture% against baseline: $Baseline`n" -ForegroundColor Cyan
$checks | Select-Object CheckId, Area, Result, Severity, Description | Format-Table -AutoSize
Write-Host "`nScorecard: $OutputCsv  |  Findings: findings.json  (N-A = unlicensed/inapplicable, not a fail)" -ForegroundColor Green
Write-Host "Read-only. Risk-acceptance & remediation priority are the security owners' decisions." -ForegroundColor Green
