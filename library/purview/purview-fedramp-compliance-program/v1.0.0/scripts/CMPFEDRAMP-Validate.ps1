<#
.SYNOPSIS
    CMPFEDRAMP-Validate.ps1 — FedRAMP control-program readiness scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Scores the program across the three control domains with no changes: sensitivity label present
        (and encryption state), DLP policy present and IN TEST/simulation mode (not enforcing before
        sign-off), unified audit on with the evidence-retention policy present, and the controlled-records
        retention policy scoped. Emits a PASS/FAIL per gate mirroring the Testing Guide. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFEDRAMP-Validate.ps1
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin;
        no secrets. For audit ingestion state it also uses Connect-ExchangeOnline where available.
    EXPECTED RESULTS
        A scorecard: each gate GREEN (pass) or RED (fail) with the remediation pointer. PASS overall =
        every in-scope gate green for the pilot scope (DLP in TEST until sign-off, then Enable on expand).
        Determination-level adequacy (baseline, NIST 800-53 fit, ATO) is NOT scored here — that is
        security/compliance/legal's.
.NOTES
    Purview category — FedRAMP Compliance Program. Read-only. Proves the technical control works and is
    present; asserts no certification/ATO. Verify cmdlet/plan names for your tenant.
#>
[CmdletBinding()]
param(
    [string]$LabelName         = 'Protect – FedRAMP Controlled – Confidential',
    [string]$DlpPolicy         = 'DLP – FedRAMP Controlled – Simulate',
    [string]$AuditPolicy       = 'Audit Retention – FedRAMP Evidence – LongTerm',
    [string]$RetentionPolicy   = 'Retention – FedRAMP Records – Publish',
    [switch]$ExpectEnforced    # on expand: expect the DLP policy to be in Enable (enforce) mode
)

$ErrorActionPreference = 'Stop'
$results = @()
function Gate($name,$pass,$detail){ $script:results += [pscustomobject]@{ Gate=$name; Status = if($pass){'GREEN'}else{'RED'}; Detail=$detail } }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Warn "ExchangeOnlineManagement not installed."; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# Gate: information-protection label present
try {
    $lbl = Get-Label -ErrorAction Stop | Where-Object { $_.DisplayName -eq $LabelName }
    if ($lbl) {
        $enc = if ($lbl.EncryptionEnabled) { 'with encryption' } else { 'no encryption (add per design)' }
        Gate 'Info protection: label present' $true "'$LabelName' exists ($enc)."
    } else { Gate 'Info protection: label present' $false "'$LabelName' not found — Implementation Step 3." }
} catch { Gate 'Info protection: label present' $false "Get-Label failed: $($_.Exception.Message) — verify feature/licensing." }

# Gate: DLP policy present and in TEST/simulation (or Enable on expand)
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $DlpPolicy }
    if (-not $dlp) { Gate 'DLP: policy present' $false "'$DlpPolicy' not found — Implementation Step 4 (create in TEST/simulation)." }
    else {
        $isEnforced = "$($dlp.Mode)" -match 'Enable'
        if ($ExpectEnforced) {
            if ($isEnforced) { Gate 'DLP: policy enforcing (Enable) on expand' $true "'$DlpPolicy' mode=$($dlp.Mode)." }
            else { Gate 'DLP: policy enforcing (Enable) on expand' $false "'$DlpPolicy' is '$($dlp.Mode)', not Enable — enforce only after sign-off." }
        } else {
            if (-not $isEnforced) { Gate 'DLP: policy present IN TEST/simulation' $true "'$DlpPolicy' mode=$($dlp.Mode) (no blocking)." }
            else { Gate 'DLP: policy present IN TEST/simulation' $false "'$DlpPolicy' is ENFORCING ('$($dlp.Mode)') before pilot sign-off — expected test/simulation." }
        }
    }
} catch { Gate 'DLP: policy present' $false "Get-DlpCompliancePolicy failed: $($_.Exception.Message)" }

# Gate: unified audit on (NIST AU)
try {
    $cfg = $null
    try { $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {
        Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
        try { Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null; $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {}
    }
    if ($cfg -and $cfg.UnifiedAuditLogIngestionEnabled) { Gate 'Audit: unified audit ingestion ON' $true "UnifiedAuditLogIngestionEnabled = True." }
    elseif ($cfg) { Gate 'Audit: unified audit ingestion ON' $false "Ingestion OFF — no evidence captured (not retroactive)." }
    else { Gate 'Audit: unified audit ingestion ON' $false "Could not read AdminAuditLogConfig (run Connect-ExchangeOnline)." }
} catch { Gate 'Audit: unified audit ingestion ON' $false $_.Exception.Message }

# Gate: audit evidence retention policy
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $AuditPolicy }
    if ($arp) { Gate 'Audit: evidence retention policy present' $true "'$AuditPolicy' present (duration $($arp.RetentionDuration), priority $($arp.Priority))." }
    else { Gate 'Audit: evidence retention policy present' $false "'$AuditPolicy' not found — Implementation Step 5." }
} catch { Gate 'Audit: evidence retention policy present' $false "Get-UnifiedAuditLogRetentionPolicy failed: $($_.Exception.Message)" }

# Gate: controlled-records retention scoped
try {
    $pol = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $RetentionPolicy }
    if ($pol -and $pol.Enabled) { Gate 'Retention: controlled-records policy scoped' $true "'$RetentionPolicy' present and enabled." }
    elseif ($pol) { Gate 'Retention: controlled-records policy scoped' $false "'$RetentionPolicy' present but DISABLED." }
    else { Gate 'Retention: controlled-records policy scoped' $false "'$RetentionPolicy' not found — Implementation Step 5." }
} catch { Gate 'Retention: controlled-records policy scoped' $false "Get-RetentionCompliancePolicy failed: $($_.Exception.Message)" }

Write-Host "`n=== FedRAMP Program Scorecard ===" -ForegroundColor Cyan
$results | ForEach-Object {
    $c = if ($_.Status -eq 'GREEN') { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $_.Status, $_.Gate) -ForegroundColor $c
    Write-Host ("         {0}" -f $_.Detail) -ForegroundColor DarkGray
}
$red = @($results | Where-Object { $_.Status -eq 'RED' }).Count
if ($red -eq 0) { Write-Host "`nAll in-scope gates GREEN for this scope. Technical controls present — proceed per Testing Guide." -ForegroundColor Green }
else { Write-Host "`n$red gate(s) RED — remediate before enforcing tenant-wide." -ForegroundColor Yellow }
Write-Host "NOTE: baseline selection, NIST 800-53 control fit, and any ATO decision are security/compliance/legal determinations, not scored here (no certification/ATO asserted)." -ForegroundColor White
