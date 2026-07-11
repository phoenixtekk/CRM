<#
.SYNOPSIS
    SOAMDI-Report.ps1 — read-only generation of the prioritized, risk-ranked Defender for Identity findings report (HTML + CSV).
.DESCRIPTION
    PURPOSE
        Turns the scorecard, coverage, and blind-spot list into a deliverable: a risk-ranked HTML report
        (findings sorted High -> Low with area, description, evidence, and remediation pointer), the
        headline posture score, the coverage summary, and — surfaced prominently at the top — the list of
        un-sensored / unhealthy domain controllers and role servers. Plus a companion tracking CSV. This
        is the artifact the security owner reviews and hands to the Remediation Playbook.
    HOW TO RUN
        pwsh -File .\SOAMDI-Report.ps1 -InputDir ".\SOAMDI-Run - 2026-07-11 - Assess" -Scorecard ".\SOAMDI-Scorecard - Forest - Assess.csv" -OutputHtml ".\SOAMDI-Findings - Forest - Assess.html"
        Run SOAMDI-Assess.ps1 first. Confirm any 'verify' items in the portal before delivery.
    EXPECTED RESULTS
        An HTML findings report and findings-tracking.csv. Read-only — reads run output only.
.NOTES
    White-label. Read-only. Store output securely — it names your identity blind spots.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$InputDir,
    [Parameter(Mandatory = $true)] [string]$Scorecard,
    [Parameter(Mandatory = $true)] [string]$OutputHtml,
    [string]$Title = 'Security Optimization Assessment — Defender for Identity'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
if (-not (Test-Path $Scorecard)) { Write-Error "Scorecard not found: $Scorecard. Run SOAMDI-Assess.ps1 first."; exit 1 }
$checks   = Import-Csv $Scorecard
$coverage = if (Test-Path (Join-Path $InputDir 'coverage-summary.csv')) { Import-Csv (Join-Path $InputDir 'coverage-summary.csv') } else { @() }
$blind    = if (Test-Path (Join-Path $InputDir 'coverage-blindspots.csv')) { Import-Csv (Join-Path $InputDir 'coverage-blindspots.csv') } else { @() }
$manifest = if (Test-Path (Join-Path $InputDir 'discovery-manifest.json')) { Get-Content (Join-Path $InputDir 'discovery-manifest.json') -Raw | ConvertFrom-Json } else { $null }

$map = @{ 'Pass' = 1.0; 'Partial' = 0.5; 'Fail' = 0.0 }
$scoreable = $checks | Where-Object { $_.Result -ne 'N-A' }
$wsum = ($scoreable | ForEach-Object { [double]$_.Weight } | Measure-Object -Sum).Sum
$ach  = ($scoreable | ForEach-Object { $map[$_.Result] * [double]$_.Weight } | Measure-Object -Sum).Sum
$posture = if ($wsum -gt 0) { [math]::Round(100.0 * $ach / $wsum, 1) } else { 0 }

$sevOrder = @{ 'High' = 0; 'Medium' = 1; 'Low' = 2; '' = 3 }
$findings = $checks | Where-Object { $_.Result -in @('Fail','Partial') } | Sort-Object @{ Expression = { $sevOrder[$_.Severity] } }, Area
function Enc([string]$s) { if ($null -eq $s) { return '' } [System.Web.HttpUtility]::HtmlEncode($s) }
$baseline = ($checks | Select-Object -First 1).Baseline

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('<!doctype html><html><head><meta charset="utf-8"><title>' + (Enc $Title) + '</title>')
[void]$sb.AppendLine('<style>body{font-family:Segoe UI,Arial,sans-serif;margin:2rem;color:#1b1b1b}h1{margin-bottom:.2rem}
.score{font-size:2.4rem;font-weight:700}.muted{color:#666}table{border-collapse:collapse;width:100%;margin:1rem 0}
th,td{border:1px solid #ddd;padding:.5rem .6rem;text-align:left;vertical-align:top;font-size:.92rem}
th{background:#f3f3f3}.High{color:#a80000;font-weight:700}.Medium{color:#8a6d00;font-weight:700}.Low{color:#3a6ea5}
.Pass{color:#107c10}.Fail{color:#a80000}.Partial{color:#8a6d00}.note{background:#fff8e1;border:1px solid #ffe08a;padding:.6rem;border-radius:4px}
.blind{background:#fdecea;border:1px solid #f5b1a8;padding:.4rem;border-radius:4px;font-weight:700}</style></head><body>')
[void]$sb.AppendLine('<h1>' + (Enc $Title) + '</h1>')
[void]$sb.AppendLine('<p class="muted">Read-only Security Optimization Assessment · Run date: ' + (Enc ($manifest.runDate)) + ' · Baseline: ' + (Enc $baseline) + '</p>')
[void]$sb.AppendLine('<p class="score">Posture score: ' + $posture + '%</p>')
[void]$sb.AppendLine('<p class="note">Point-in-time snapshot. Items flagged &ldquo;verify&rdquo; must be confirmed in Settings &rarr; Identities before delivery. Risk-acceptance and remediation priority are the security owners&rsquo; decisions; response actions and IR determinations belong to the SOC. Fixes are delivered pilot-first by the paired Remediation Playbook.</p>')

# Blind spots first (highest value)
[void]$sb.AppendLine('<h2>Blind spots — servers with no (confirmed) MDI sensor (fix first)</h2>')
if ($blind.Count -gt 0) {
    [void]$sb.AppendLine('<table><tr><th>Role</th><th>Host</th><th>Site</th><th>OS</th><th>Issue</th></tr>')
    foreach ($b in $blind) { [void]$sb.AppendLine('<tr><td>' + (Enc $b.Role) + '</td><td class="blind">' + (Enc $b.Host) + '</td><td>' + (Enc $b.Site) + '</td><td>' + (Enc $b.OS) + '</td><td>' + (Enc $b.Issue) + '</td></tr>') }
    [void]$sb.AppendLine('</table>')
} else { [void]$sb.AppendLine('<p>No un-sensored servers detected. (Confirm the sensor list was reconciled against the AD inventory — Testing Gate 4 — and that sensor data was not merely a &ldquo;verify&rdquo; placeholder.)</p>') }

# Findings
[void]$sb.AppendLine('<h2>Findings — risk-ranked (High &rarr; Low)</h2><table><tr><th>Severity</th><th>Check</th><th>Area</th><th>Finding</th><th>Result</th><th>Evidence</th><th>Remediation pointer</th></tr>')
foreach ($f in $findings) { [void]$sb.AppendLine('<tr><td class="' + (Enc $f.Severity) + '">' + (Enc $f.Severity) + '</td><td>' + (Enc $f.CheckId) + '</td><td>' + (Enc $f.Area) + '</td><td>' + (Enc $f.Description) + '</td><td class="' + (Enc $f.Result) + '">' + (Enc $f.Result) + '</td><td>' + (Enc $f.Evidence) + '</td><td>' + (Enc $f.Remediation) + '</td></tr>') }
[void]$sb.AppendLine('</table>')

# Coverage
[void]$sb.AppendLine('<h2>Coverage summary</h2><table><tr><th>Area</th><th>Covered</th><th>Total</th><th>Coverage</th></tr>')
foreach ($c in $coverage) { [void]$sb.AppendLine('<tr><td>' + (Enc $c.Area) + '</td><td>' + (Enc $c.Covered) + '</td><td>' + (Enc $c.Total) + '</td><td>' + (Enc $c.CoveragePct) + '</td></tr>') }
[void]$sb.AppendLine('</table>')

# All checks
[void]$sb.AppendLine('<h2>All checks</h2><table><tr><th>Check</th><th>Area</th><th>Description</th><th>Result</th></tr>')
foreach ($c in $checks) { [void]$sb.AppendLine('<tr><td>' + (Enc $c.CheckId) + '</td><td>' + (Enc $c.Area) + '</td><td>' + (Enc $c.Description) + '</td><td class="' + (Enc $c.Result) + '">' + (Enc $c.Result) + '</td></tr>') }
[void]$sb.AppendLine('</table><p class="muted">Generated read-only by SOAMDI-Report.ps1. Handle as confidential.</p></body></html>')

Set-Content -Path $OutputHtml -Value $sb.ToString() -Encoding UTF8
$findings | Select-Object Severity, CheckId, Area, Description, Result, Evidence, Remediation | Export-Csv (Join-Path $InputDir 'findings-tracking.csv') -NoTypeInformation -Encoding UTF8

Write-Host "Report written: $OutputHtml" -ForegroundColor Green
Write-Host "Posture score: $posture%  |  Findings: $($findings.Count)  |  Blind servers: $($blind.Count)  |  Store securely." -ForegroundColor Green
Write-Host "Confirm 'verify' items and reconcile top findings against the portal before delivery (Testing Gate 6)." -ForegroundColor Yellow
