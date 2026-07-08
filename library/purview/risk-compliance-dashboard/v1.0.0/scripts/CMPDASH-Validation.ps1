<#
.SYNOPSIS
    CMPDASH-Validation.ps1 — reconcile the rendered dashboard against live Purview reads + flag stale owner-captured figures (read-only).
.DESCRIPTION
    PURPOSE
        The pilot gate for the Risk & Compliance Dashboard. Re-reads each live signal (DLP / sensitivity-
        label / retention policy counts and the unified audit-ingestion state) and reconciles it against
        the values persisted in RiskComplianceDashboard.data.json, and flags any owner-captured figure whose
        capturedOn date is older than the config's ownerCaptureMaxAgeDays. Read-only — makes no changes and
        reads no HR-sensitive case content; it only reports PASS/FAIL/STALE per tile.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPDASH-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\CMPDASH-Validation.ps1 -DataPath .\RiskComplianceDashboard.data.json -ConfigPath .\RiskComplianceDashboard.config.json
        Connect first: Connect-IPPSSession as the least-privilege reader. Run CMPDASH-Report.ps1 first so the
        dataset exists. PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        A PASS/FAIL line per live tile (live re-read matches the dataset) and PASS/STALE per owner-captured
        tile. All PASS = the dashboard reconciles to source (pilot gate met). Any FAIL/STALE = refresh the
        report or re-capture the owner figure before scheduling/distributing.
.NOTES
    Purview category — Risk & Compliance Dashboard. Read-only. Confirms the dashboard read source correctly,
    NOT whether the underlying posture satisfies a regulation (a compliance/records/legal determination).
#>
[CmdletBinding()]
param(
    [string]$DataPath   = "./RiskComplianceDashboard.data.json",
    [string]$ConfigPath = "./RiskComplianceDashboard.config.json"
)

$ErrorActionPreference = 'Stop'
function Pass($m){ Write-Host "  [PASS]  $m" -ForegroundColor Green }
function Fail($m){ Write-Host "  [FAIL]  $m" -ForegroundColor Red }
function Stale($m){ Write-Host "  [STALE] $m" -ForegroundColor Yellow }
function Info($m){ Write-Host "  $m" -ForegroundColor White }

if (-not (Test-Path $DataPath))  { Write-Error "Dataset not found at $DataPath — run CMPDASH-Report.ps1 first."; return }
$data = @(Get-Content $DataPath -Raw | ConvertFrom-Json)
$config = if (Test-Path $ConfigPath) { Get-Content $ConfigPath -Raw | ConvertFrom-Json } else { $null }
$maxAge = if ($config -and $config.cadence.ownerCaptureMaxAgeDays) { [int]$config.cadence.ownerCaptureMaxAgeDays } else { 30 }

$results = New-Object System.Collections.Generic.List[object]
function Record($tile,$result,$detail){ $results.Add([pscustomobject]@{ Tile=$tile; Result=$result; Detail=$detail }) }
function Get-Tile($key){ $data | Where-Object { $_.key -eq $key } | Select-Object -First 1 }

Write-Host "=== CMPDASH-Validation — reconcile dashboard to source (read-only) ===" -ForegroundColor Cyan

# --- LIVE: DLP policy count present in the tile value string ---
$t = Get-Tile 'dlp'
if ($t) {
    try {
        $live = @(Get-DlpCompliancePolicy -ErrorAction Stop).Count
        if ("$($t.value)" -match "policies\s+$live\b") { Pass "DLP: live policy count $live matches dataset."; Record 'dlp' 'PASS' "count=$live" }
        else { Fail "DLP: live count $live not reflected in dataset value '$($t.value)' — re-run CMPDASH-Report.ps1."; Record 'dlp' 'FAIL' "live=$live" }
    } catch { Fail "DLP: live re-read failed — $($_.Exception.Message)"; Record 'dlp' 'FAIL' 'read-failed' }
}

# --- LIVE: sensitivity labels ---
$t = Get-Tile 'sensitivityLabels'
if ($t) {
    try {
        $live = @(Get-Label -ErrorAction Stop).Count
        if ("$($t.value)" -match "published labels\s+$live\b") { Pass "Labels: live published-label count $live matches dataset."; Record 'sensitivityLabels' 'PASS' "count=$live" }
        else { Fail "Labels: live count $live not reflected in dataset value '$($t.value)' — refresh the report."; Record 'sensitivityLabels' 'FAIL' "live=$live" }
    } catch { Fail "Labels: live re-read failed — $($_.Exception.Message)"; Record 'sensitivityLabels' 'FAIL' 'read-failed' }
}

# --- LIVE: retention ---
$t = Get-Tile 'retention'
if ($t) {
    try {
        $live = @(Get-RetentionCompliancePolicy -ErrorAction Stop).Count
        if ("$($t.value)" -match "retention policies\s+$live\b") { Pass "Retention: live policy count $live matches dataset."; Record 'retention' 'PASS' "count=$live" }
        else { Fail "Retention: live count $live not reflected in dataset value '$($t.value)' — refresh the report."; Record 'retention' 'FAIL' "live=$live" }
    } catch { Fail "Retention: live re-read failed — $($_.Exception.Message)"; Record 'retention' 'FAIL' 'read-failed' }
}

# --- LIVE: audit ingestion state ---
$t = Get-Tile 'audit'
if ($t) {
    try {
        $on = (Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled
        $expected = if ($on) { 'ENABLED' } else { 'DISABLED' }
        if ("$($t.value)" -match $expected) { Pass "Audit: live ingestion state $expected matches dataset."; Record 'audit' 'PASS' $expected }
        else { Fail "Audit: live state $expected not reflected in dataset value '$($t.value)' — refresh the report."; Record 'audit' 'FAIL' $expected }
    } catch { Fail "Audit: live re-read failed — $($_.Exception.Message)"; Record 'audit' 'FAIL' 'read-failed' }
}

# --- OWNER-CAPTURED: staleness ---
Write-Host "`n-- Owner-captured freshness (max age ${maxAge}d) --" -ForegroundColor Cyan
foreach ($t in ($data | Where-Object { $_.source -eq 'owner-captured' })) {
    $capturedOn = $null
    if ($config) {
        $sig = $config.signals | Where-Object { $_.key -eq $t.key } | Select-Object -First 1
        if ($sig -and $sig.capturedOn) { $capturedOn = $sig.capturedOn }
    }
    if (-not $capturedOn -and "$($t.value)" -match 'captured on (\S+)') { if ($Matches[1] -ne 'never') { $capturedOn = $Matches[1] } }
    if (-not $capturedOn) { Stale "$($t.title): never captured — the program owner must record it before publishing."; Record $t.key 'STALE' 'never'; continue }
    try {
        $age = ((Get-Date) - [datetime]$capturedOn).TotalDays
        if ($age -le $maxAge) { Pass ("{0}: captured {1:N0}d ago — fresh." -f $t.title, $age); Record $t.key 'PASS' ("age={0:N0}d" -f $age) }
        else { Stale ("{0}: captured {1:N0}d ago — older than {2}d; re-capture." -f $t.title, $age, $maxAge); Record $t.key 'STALE' ("age={0:N0}d" -f $age) }
    } catch { Stale "$($t.title): capturedOn '$capturedOn' unparseable — re-record."; Record $t.key 'STALE' 'bad-date' }
}

# --- Summary ---
Write-Host "`n=== Reconciliation summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$fail  = @($results | Where-Object Result -eq 'FAIL').Count
$stale = @($results | Where-Object Result -eq 'STALE').Count
if ($fail -eq 0 -and $stale -eq 0) { Pass "All tiles reconcile and owner-captured figures are fresh — pilot gate met." }
else { Fail "$fail live mismatch(es), $stale stale owner-captured figure(s) — refresh the report / re-capture before scheduling or distributing." }
Info "Reconciliation confirms the dashboard read source correctly — NOT whether the posture satisfies a regulation (deferred to compliance/records/legal)."
