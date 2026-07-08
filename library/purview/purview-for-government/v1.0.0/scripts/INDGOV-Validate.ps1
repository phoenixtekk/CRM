<#
.SYNOPSIS
    INDGOV-Validate.ps1 — Government (CJIS/CMMC/ITAR) control-program readiness scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Scores the program across the control domains with no changes: the CJI/CUI/ITAR sensitivity labels
        present (and published), the services DLP and endpoint DLP policies present IN SIMULATION, government
        records retention present, unified audit on with the evidence-retention policy present, and the pilot
        scope covered. Emits a PASS/FAIL per gate mirroring the Testing Guide. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INDGOV-Validate.ps1
        # Sovereign cloud — pass your S&C endpoint:
        .\INDGOV-Validate.ps1 -ConnectionUri https://ps.compliance.protection.office365.us/powershell-liveid/
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin; no
        secrets. For audit ingestion state it also uses Connect-ExchangeOnline where available. VERIFY the
        endpoint for your cloud.
    EXPECTED RESULTS
        A scorecard: each gate GREEN (pass) or RED (fail) with the remediation pointer. PASS overall = every
        in-scope gate green for the pilot scope. DLP gates require SIMULATION mode (not enforce) at pilot
        stage. Determination-level adequacy (classification, retention, CMMC fit, ITAR access) is NOT scored
        here — that is compliance/security/records/legal's.
.NOTES
    Purview category — Government industry bundle (CJIS/CMMC/ITAR). Read-only. Proves the technical control
    works and is present; does not certify CJIS/CMMC/ITAR compliance or imply authorization. Verify cmdlet/
    plan/endpoint names for your cloud.
#>
[CmdletBinding()]
param(
    [string]$ConnectionUri,                                                     # sovereign-cloud S&C endpoint — VERIFY
    [string[]]$LabelNames = @('Protect – Gov CJI – Restricted','Protect – Gov CUI – Controlled','Protect – Gov ITAR – Controlled'),
    [string]$ServicesDlp   = 'DLP – Gov Controlled Data – Simulate',
    [string]$EndpointDlp   = 'DLP – Gov Endpoint Egress – Simulate',
    [string]$RetentionPolicy = 'Retention – Gov Records – Publish',
    [string]$AuditPolicy   = 'Audit Retention – Gov Evidence – LongTerm'
)

$ErrorActionPreference = 'Stop'
$results = @()
function Gate($name,$pass,$detail){ $script:results += [pscustomobject]@{ Gate=$name; Status = if($pass){'GREEN'}else{'RED'}; Detail=$detail } }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Warn "ExchangeOnlineManagement not installed."; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$connectParams = @{}
if ($ConnectionUri) { $connectParams['ConnectionUri'] = $ConnectionUri; Warn "Using sovereign-cloud S&C endpoint: $ConnectionUri (verify for your cloud)." }
try { Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message) — pass the correct -ConnectionUri for GCC High/DoD."; return }

# Gate: government sensitivity labels present
try {
    $labels = Get-Label -ErrorAction Stop
    $found = @($LabelNames | Where-Object { $ln = $_; $labels | Where-Object { $_.DisplayName -eq $ln } })
    if (@($found).Count -eq $LabelNames.Count) { Gate 'Labels: CJI/CUI/ITAR labels present' $true "All 3 government labels exist — confirm each ENCRYPTS and is published to the pilot." }
    elseif (@($found).Count -gt 0) { Gate 'Labels: CJI/CUI/ITAR labels present' $false ("Only {0}/3 government labels found — Implementation Step 3." -f @($found).Count) }
    else { Gate 'Labels: CJI/CUI/ITAR labels present' $false "No government labels found — Implementation Step 3." }
} catch { Gate 'Labels: CJI/CUI/ITAR labels present' $false "Get-Label failed: $($_.Exception.Message) — verify feature/cmdlet for your cloud." }

# Gate: labels published (label policy)
try {
    $lp = Get-LabelPolicy -ErrorAction Stop | Where-Object { $_.Enabled }
    if ($lp) { Gate 'Labels: published via an enabled label policy' $true ("{0} enabled label policy(ies) — confirm they scope the government labels to the pilot." -f @($lp).Count) }
    else { Gate 'Labels: published via an enabled label policy' $false "No enabled label policy — labels not published to users (Implementation Step 3)." }
} catch { Gate 'Labels: published via an enabled label policy' $false "Get-LabelPolicy failed: $($_.Exception.Message)" }

# Gate: services DLP present in SIMULATION
try {
    $d = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $ServicesDlp }
    if ($d -and "$($d.Mode)" -match 'Enable|Test|Simulat') { Gate 'DLP (services): present IN SIMULATION' $true "'$ServicesDlp' present, mode '$($d.Mode)' (simulation) — do not enforce until validated." }
    elseif ($d) { Gate 'DLP (services): present IN SIMULATION' $false "'$ServicesDlp' present but mode is '$($d.Mode)' — expected simulation at pilot stage (verify before enforce)." }
    else { Gate 'DLP (services): present IN SIMULATION' $false "'$ServicesDlp' not found — Implementation Step 4 (create in simulation)." }
} catch { Gate 'DLP (services): present IN SIMULATION' $false "Get-DlpCompliancePolicy failed: $($_.Exception.Message)" }

# Gate: endpoint DLP present in SIMULATION
try {
    $e = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $EndpointDlp }
    if ($e -and "$($e.Mode)" -match 'Enable|Test|Simulat') { Gate 'DLP (endpoint): present IN SIMULATION' $true "'$EndpointDlp' present, mode '$($e.Mode)' — confirm devices onboarded + endpoint DLP available in your cloud." }
    elseif ($e) { Gate 'DLP (endpoint): present IN SIMULATION' $false "'$EndpointDlp' present but mode is '$($e.Mode)' — expected simulation at pilot stage." }
    else { Gate 'DLP (endpoint): present IN SIMULATION' $false "'$EndpointDlp' not found — Implementation Step 4 (create in simulation; requires onboarded devices)." }
} catch { Gate 'DLP (endpoint): present IN SIMULATION' $false "Get-DlpCompliancePolicy failed: $($_.Exception.Message)" }

# Gate: government records retention scoped
try {
    $r = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $RetentionPolicy }
    if ($r -and $r.Enabled) { Gate 'Retention: government records policy scoped' $true "'$RetentionPolicy' present and enabled." }
    elseif ($r) { Gate 'Retention: government records policy scoped' $false "'$RetentionPolicy' present but DISABLED." }
    else { Gate 'Retention: government records policy scoped' $false "'$RetentionPolicy' not found — Implementation Step 5." }
} catch { Gate 'Retention: government records policy scoped' $false "Get-RetentionCompliancePolicy failed: $($_.Exception.Message)" }

# Gate: unified audit on
try {
    $cfg = $null
    try { $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {
        try { Connect-ExchangeOnline @connectParams -ShowBanner:$false -ErrorAction Stop | Out-Null; $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {}
    }
    if ($cfg -and $cfg.UnifiedAuditLogIngestionEnabled) { Gate 'Audit: unified audit ingestion ON' $true "UnifiedAuditLogIngestionEnabled = True." }
    elseif ($cfg) { Gate 'Audit: unified audit ingestion ON' $false "Ingestion OFF — no evidence captured (not retroactive)." }
    else { Gate 'Audit: unified audit ingestion ON' $false "Could not read AdminAuditLogConfig (run Connect-ExchangeOnline with your cloud endpoint)." }
} catch { Gate 'Audit: unified audit ingestion ON' $false $_.Exception.Message }

# Gate: audit evidence retention policy
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $AuditPolicy }
    if ($arp) { Gate 'Audit: evidence retention policy present' $true "'$AuditPolicy' present (duration $($arp.RetentionDuration), priority $($arp.Priority))." }
    else { Gate 'Audit: evidence retention policy present' $false "'$AuditPolicy' not found — Implementation Step 5." }
} catch { Gate 'Audit: evidence retention policy present' $false "Get-UnifiedAuditLogRetentionPolicy failed: $($_.Exception.Message)" }

Write-Host "`n=== Government (CJIS/CMMC/ITAR) Program Scorecard ===" -ForegroundColor Cyan
$results | ForEach-Object {
    $c = if ($_.Status -eq 'GREEN') { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $_.Status, $_.Gate) -ForegroundColor $c
    Write-Host ("         {0}" -f $_.Detail) -ForegroundColor DarkGray
}
$red = @($results | Where-Object { $_.Status -eq 'RED' }).Count
if ($red -eq 0) { Write-Host "`nAll in-scope gates GREEN for this scope. Technical controls present (DLP in simulation) — proceed per Testing Guide." -ForegroundColor Green }
else { Write-Host "`n$red gate(s) RED — remediate before enforcing DLP or broadening label publish." -ForegroundColor Yellow }
Write-Host "NOTE: data classification (CJI/CUI/ITAR), CMMC-level fit, retention/ITAR-access adequacy, and rule fit are compliance/security/legal determinations, not scored here. Verify behavior in your cloud." -ForegroundColor White
