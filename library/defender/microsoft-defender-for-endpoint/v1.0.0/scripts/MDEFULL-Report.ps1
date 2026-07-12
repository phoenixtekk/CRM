<#
.SYNOPSIS
    MDEFULL-Report.ps1 — coverage + ASR-audit + noise + TVM exposure report for Defender for Endpoint,
    with the optimization before/after baseline and drift.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the comprehensive "Microsoft Defender for Endpoint" solution. Summarizes
        what ASR rules WOULD block (from audit events), the noisiest repeating detections, onboarding/
        sensor-health coverage, and the top software vulnerabilities (TVM exposure). With -SaveBaseline
        it records a "before" snapshot (alert volume, false-positive proxy, ASR block coverage,
        onboarding coverage, top-vuln count) so later runs show the before/after delta that makes the
        optimization measurable. Also reminds you to keep AIR approval-gated.
    HOW TO RUN
        # Capture the "before" baseline (Optimize Step B1):
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-Report.ps1 -Section All -SaveBaseline
        # Later, show the delta vs a saved baseline:
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-Report.ps1 -BaselinePath .\MDEFULL-baseline.json
        -Section accepts: ASR | Exposure | Noise | Coverage | Enablement | All (default All).
        Uses Microsoft.Graph.Authentication + Graph Security advanced hunting. Government cloud: -Environment.
    EXPECTED RESULTS
        An ASR audit summary (what block WOULD stop — review before promoting), the noisiest detections,
        coverage, the top TVM vulnerabilities, and drift versus the saved baseline. Downward
        noise/exposure and upward coverage = a healthy optimization trend.
.NOTES
    White-label. Read-only. Use the ASR audit summary to add exclusions BEFORE moving to block.
    AIR automation must remain approval-gated until the SOC decides otherwise.
#>
[CmdletBinding()]
param(
    [ValidateSet('ASR','Exposure','Noise','Coverage','Enablement','All')] [string]$Section = 'All',
    [switch]$SaveBaseline,
    [string]$BaselinePath = ".\MDEFULL-baseline.json",
    [int]$LookbackDays = 7,
    [ValidateSet('Global','USGov','USGovDoD')] [string]$Environment = 'Global'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','SecurityEvents.Read.All' -Environment $Environment -NoWelcome | Out-Null }
Write-Host "`n=== Defender for Endpoint — coverage / noise / exposure report ($Section) ===" -ForegroundColor Cyan

function Invoke-Hunt([string]$Query) {
    try { return (Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $Query } | ConvertTo-Json) -ContentType 'application/json') }
    catch { Write-Host ("   Hunt unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; return $null }
}
$metrics = [ordered]@{ Timestamp = (Get-Date).ToString('s') }

if ($Section -in 'ASR','All') {
    Write-Host "`n-- ASR audit summary (what BLOCK would stop — review before promoting) --" -ForegroundColor Cyan
    $r = Invoke-Hunt "DeviceEvents | where Timestamp > ago(${LookbackDays}d) | where ActionType startswith 'Asr' | extend Mode=iff(ActionType endswith 'Blocked','Block','Audit') | summarize Count=count() by ActionType, Mode | order by Count desc | take 30"
    if ($r.results) { $r.results | ForEach-Object { Write-Host ("   [{0}] {1}  x{2}" -f $_.Mode, $_.ActionType, $_.Count) }; $metrics.AsrBlockCoverage = (@($r.results | Where-Object { $_.Mode -eq 'Block' })).Count }
    else { Write-Host "   No ASR events (rules in audit yet? allow warm-up)." -ForegroundColor Yellow }
    Write-Host "   Add exclusions for legitimate hits, THEN promote to block (MDEFULL-PromoteASR.ps1)." -ForegroundColor DarkGray
}

if ($Section -in 'Noise','All') {
    Write-Host "`n-- Noisiest repeating detections (tune/suppress candidates) --" -ForegroundColor Cyan
    $r = Invoke-Hunt "AlertInfo | where Timestamp > ago(${LookbackDays}d) | summarize Alerts=count(), Days=dcount(bin(Timestamp,1d)) by Title, Severity | where Alerts > 5 | sort by Alerts desc | take 25"
    if ($r.results) { $r.results | ForEach-Object { Write-Host ("   [{0}] {1} — {2} alert(s) over {3} day(s)" -f $_.Severity, $_.Title, $_.Alerts, $_.Days) }; $metrics.AlertVolume = ($r.results | Measure-Object -Property Alerts -Sum).Sum }
    else { Write-Host "   No repeating detections above threshold (allow warm-up)." -ForegroundColor Yellow; $metrics.AlertVolume = 0 }
}

if ($Section -in 'Coverage','All') {
    Write-Host "`n-- Onboarding + sensor-health coverage --" -ForegroundColor Cyan
    $r = Invoke-Hunt "DeviceInfo | summarize LastSeen=max(Timestamp) by DeviceName, OnboardingStatus | summarize Active=countif(OnboardingStatus=='Onboarded' and LastSeen > ago(1d)), Onboarded=countif(OnboardingStatus=='Onboarded'), Total=count()"
    if ($r.results) { $r.results | ForEach-Object { Write-Host ("   Active {0} / Onboarded {1} / Total seen {2}" -f $_.Active, $_.Onboarded, $_.Total) -ForegroundColor Green; $metrics.ActiveCoverage = [int]$_.Active } }
    else { Write-Host "   No DeviceInfo rows yet — allow warm-up." -ForegroundColor Yellow }
}

if ($Section -in 'Exposure','All') {
    Write-Host "`n-- TVM exposure — top software vulnerabilities --" -ForegroundColor Cyan
    $r = Invoke-Hunt "DeviceTvmSoftwareVulnerabilities | summarize Devices=dcount(DeviceId) by CveId, SoftwareName, VulnerabilitySeverityLevel | order by Devices desc | take 25"
    if ($r.results) { $metrics.TopVulnCount = $r.results.Count; $r.results | ForEach-Object { Write-Host ("   [{0}] {1} — {2} device(s) — {3}" -f $_.VulnerabilitySeverityLevel, $_.CveId, $_.Devices, $_.SoftwareName) } }
    else { Write-Host "   No TVM rows yet — allow warm-up." -ForegroundColor Yellow; $metrics.TopVulnCount = 0 }
}

if ($Section -in 'Enablement','All') {
    Write-Host "`n-- Enablement cohort signal (lab activity) --" -ForegroundColor Cyan
    $r = Invoke-Hunt "DeviceEvents | where Timestamp > ago(${LookbackDays}d) | where ActionType startswith 'Asr' and ActionType endswith 'Audited' | summarize LabAsrAuditEvents=count(), Devices=dcount(DeviceName)"
    if ($r.results) { $r.results | ForEach-Object { Write-Host ("   Lab ASR audit events: {0} across {1} device(s)" -f $_.LabAsrAuditEvents, $_.Devices) } }
    Write-Host "   Confirm 'MDE Lab Detection - Team - Pilot' is alert-only and the knowledge-check is scored per learner." -ForegroundColor DarkGray
}

Write-Host "`n-- Automated response --" -ForegroundColor Cyan
Write-Host "   Confirm the pilot device group AIR automation level = 'Semi - require approval' (approval-gated)." -ForegroundColor DarkGray

if ($SaveBaseline) {
    $metrics | ConvertTo-Json | Set-Content -Path $BaselinePath -Encoding UTF8
    Write-Host ("`nBefore-state baseline saved: {0}" -f $BaselinePath) -ForegroundColor Green
} elseif (Test-Path $BaselinePath) {
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    Write-Host ("`n-- Drift vs baseline ({0}) --" -f $base.Timestamp) -ForegroundColor Cyan
    foreach ($k in 'AlertVolume','ActiveCoverage','TopVulnCount','AsrBlockCoverage') {
        if ($null -ne $metrics.$k -and $null -ne $base.$k) { Write-Host ("   {0}: {1} -> {2}  (delta {3})" -f $k, $base.$k, $metrics.$k, ($metrics.$k - $base.$k)) }
    }
    Write-Host "   Healthy: AlertVolume down, TopVulnCount down, ActiveCoverage up, AsrBlockCoverage up." -ForegroundColor DarkGray
} else { Write-Host "`n(no baseline yet — run with -SaveBaseline to create one)" -ForegroundColor DarkGray }
Write-Host "Report complete (read-only)." -ForegroundColor Green
