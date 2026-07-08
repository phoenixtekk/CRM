<#
.SYNOPSIS
    CMPFERPA-Validate.ps1 — FERPA control-program readiness scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Scores the program across the control domains with no changes: the education-record sensitivity
        label present and published, the DLP policy present IN SIMULATION (not enforcing) with a rule,
        retention scoped, and unified audit on with the evidence-retention policy present. Emits a
        PASS/FAIL per gate mirroring the Testing Guide. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFERPA-Validate.ps1
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin;
        no secrets. For audit ingestion state it also uses Connect-ExchangeOnline where available.
    EXPECTED RESULTS
        A scorecard: each gate GREEN (pass) or RED (fail) with the remediation pointer. PASS overall =
        every in-scope gate green for the pilot scope (DLP in SIMULATION until sign-off). Determination-
        level adequacy (education-record scope, DLP match/exceptions, retention fit) is NOT scored here —
        that is compliance/registrar/records/legal's.
.NOTES
    Purview category — FERPA Compliance Program. Read-only. Proves the technical control works and is
    present; does not certify FERPA compliance. Verify cmdlet/plan names for your tenant.
#>
[CmdletBinding()]
param(
    [string]$LabelName       = 'Protect – FERPA Education Records – Confidential',
    [string]$LabelPolicy     = 'Protect – FERPA Education Records – Publish',
    [string]$DlpPolicy       = 'DLP – FERPA Education Records – Simulate',
    [string]$RetentionPolicy = 'Retention – FERPA Records – Publish',
    [string]$AuditPolicy     = 'Audit Retention – FERPA Evidence – LongTerm'
)

$ErrorActionPreference = 'Stop'
$results = @()
function Gate($name,$pass,$detail){ $script:results += [pscustomobject]@{ Gate=$name; Status = if($pass){'GREEN'}else{'RED'}; Detail=$detail } }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Warn "ExchangeOnlineManagement not installed."; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# Gate: education-record sensitivity label present
try {
    $labels = Get-Label -ErrorAction Stop
    $lbl = $labels | Where-Object { $_.DisplayName -eq $LabelName -or $_.Name -match 'FERPA' }
    if ($lbl) { Gate 'Classify: education-record label present' $true "'$LabelName' (or a FERPA label) exists." }
    else { Gate 'Classify: education-record label present' $false "No FERPA education-record label found — Implementation Step 3." }
} catch { Gate 'Classify: education-record label present' $false "Get-Label failed: $($_.Exception.Message) — verify feature/cmdlet for your tenant." }

# Gate: label published
try {
    $lp = Get-LabelPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $LabelPolicy }
    if ($lp -and $lp.Enabled) { Gate 'Classify: label published' $true "'$LabelPolicy' present and enabled (confirm PILOT scope)." }
    elseif ($lp) { Gate 'Classify: label published' $false "'$LabelPolicy' present but DISABLED." }
    else { Gate 'Classify: label published' $false "'$LabelPolicy' not found — Implementation Step 3." }
} catch { Gate 'Classify: label published' $false "Get-LabelPolicy failed: $($_.Exception.Message)" }

# Gate: DLP policy present IN SIMULATION (not enforcing)
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $DlpPolicy }
    if ($dlp) {
        $mode = "$($dlp.Mode)"
        $isSim = ($mode -match 'Test|Simulat') -or ($mode -notmatch 'Enforce')
        if ($isSim) { Gate 'Prevent: DLP policy present in SIMULATION' $true "'$DlpPolicy' present (mode=$mode) — validate matches/exceptions before enforcing." }
        else { Gate 'Prevent: DLP policy present in SIMULATION' $false "'$DlpPolicy' present but mode=$mode (ENFORCING) — confirm this was signed off; the pilot should stay in simulation." }
    } else { Gate 'Prevent: DLP policy present in SIMULATION' $false "'$DlpPolicy' not found — Implementation Step 4 (create in SIMULATION)." }
} catch { Gate 'Prevent: DLP policy present in SIMULATION' $false "Get-DlpCompliancePolicy failed: $($_.Exception.Message)" }

# Gate: retention policy scoped
try {
    $rp = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $RetentionPolicy }
    if ($rp -and $rp.Enabled) { Gate 'Lifecycle: retention policy scoped' $true "'$RetentionPolicy' present and enabled." }
    elseif ($rp) { Gate 'Lifecycle: retention policy scoped' $false "'$RetentionPolicy' present but DISABLED." }
    else { Gate 'Lifecycle: retention policy scoped' $false "'$RetentionPolicy' not found — Implementation Step 5." }
} catch { Gate 'Lifecycle: retention policy scoped' $false "Get-RetentionCompliancePolicy failed: $($_.Exception.Message)" }

# Gate: unified audit on
try {
    $cfg = $null
    try { $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {
        Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
        try { Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null; $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {}
    }
    if ($cfg -and $cfg.UnifiedAuditLogIngestionEnabled) { Gate 'Evidence: unified audit ingestion ON' $true "UnifiedAuditLogIngestionEnabled = True." }
    elseif ($cfg) { Gate 'Evidence: unified audit ingestion ON' $false "Ingestion OFF — no access evidence captured (not retroactive)." }
    else { Gate 'Evidence: unified audit ingestion ON' $false "Could not read AdminAuditLogConfig (run Connect-ExchangeOnline)." }
} catch { Gate 'Evidence: unified audit ingestion ON' $false $_.Exception.Message }

# Gate: audit evidence retention policy
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $AuditPolicy }
    if ($arp) { Gate 'Evidence: audit retention policy present' $true "'$AuditPolicy' present (duration $($arp.RetentionDuration), priority $($arp.Priority))." }
    else { Gate 'Evidence: audit retention policy present' $false "'$AuditPolicy' not found — Implementation Step 5." }
} catch { Gate 'Evidence: audit retention policy present' $false "Get-UnifiedAuditLogRetentionPolicy failed: $($_.Exception.Message)" }

Write-Host "`n=== FERPA Program Scorecard ===" -ForegroundColor Cyan
$results | ForEach-Object {
    $c = if ($_.Status -eq 'GREEN') { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $_.Status, $_.Gate) -ForegroundColor $c
    Write-Host ("         {0}" -f $_.Detail) -ForegroundColor DarkGray
}
$red = @($results | Where-Object { $_.Status -eq 'RED' }).Count
if ($red -eq 0) { Write-Host "`nAll in-scope gates GREEN for this scope. Technical controls present — proceed per Testing Guide (keep DLP in SIMULATION until sign-off)." -ForegroundColor Green }
else { Write-Host "`n$red gate(s) RED — remediate before enforcing anything." -ForegroundColor Yellow }
Write-Host "NOTE: education-record scope, DLP match/exception adequacy, and retention fit are compliance/registrar/records/legal determinations, not scored here." -ForegroundColor White
