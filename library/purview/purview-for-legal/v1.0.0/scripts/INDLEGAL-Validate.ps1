<#
.SYNOPSIS
    INDLEGAL-Validate.ps1 — Legal control-program readiness scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Scores the Legal-tailored program across the four control domains with no changes: sensitivity
        labels present (privileged label encrypted), DLP policy present and IN SIMULATION/TEST (blocks
        nothing until validated), matter-records retention present and scoped, and unified audit on with the
        evidence-retention policy present. Emits a PASS/FAIL per gate mirroring the Testing Guide. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INDLEGAL-Validate.ps1
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin;
        no secrets. For audit ingestion state it also uses Connect-ExchangeOnline where available.
    EXPECTED RESULTS
        A scorecard: each gate GREEN (pass) or RED (fail) with the remediation pointer. PASS overall =
        every in-scope gate green for the pilot scope (DLP GREEN while still in simulation is expected
        pre-enforcement). Determination-level adequacy (privilege, matter mapping, retention fit, legal
        hold) is NOT scored here — that is legal/records'.
.NOTES
    Purview category — Microsoft Purview for Legal (industry bundle). Read-only. Proves the technical
    control works and is present; does not certify legal adequacy. Legal holds/eDiscovery are legal's and
    are not scored here. Verify cmdlet/plan names for your tenant.
#>
[CmdletBinding()]
param(
    [string]$PrivilegedLabel = 'Protect – Legal Privileged – Restricted',
    [string]$MatterLabel     = 'Protect – Legal Matter Confidential – Confidential',
    [string]$DlpPolicy       = 'DLP – Legal Privileged – Simulate',
    [string]$RetentionPolicy = 'Retention – Legal Matter Records – Publish',
    [string]$AuditPolicy     = 'Audit Retention – Legal Evidence – LongTerm',
    [switch]$RequireEnforced # if set, DLP must be in Enable (post-expand) to pass; default accepts simulation/test
)

$ErrorActionPreference = 'Stop'
$results = @()
function Gate($name,$pass,$detail){ $script:results += [pscustomobject]@{ Gate=$name; Status = if($pass){'GREEN'}else{'RED'}; Detail=$detail } }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Warn "ExchangeOnlineManagement not installed."; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# Gate: sensitivity labels present + privileged encrypted
try {
    $labels = Get-Label -ErrorAction Stop
    $priv = $labels | Where-Object { $_.DisplayName -eq $PrivilegedLabel }
    $matt = $labels | Where-Object { $_.DisplayName -eq $MatterLabel }
    $privEnc = $priv -and ($priv.EncryptionEnabled -or $priv.EncryptionProtectionType)
    if ($priv -and $matt -and $privEnc) { Gate 'Labels: both present, privileged ENCRYPTED' $true "'$PrivilegedLabel' (encrypted) and '$MatterLabel' present." }
    elseif ($priv -and $matt) { Gate 'Labels: both present, privileged ENCRYPTED' $false "Both labels present but privileged label is NOT encrypted — confirm encryption (Step 3)." }
    else { Gate 'Labels: both present, privileged ENCRYPTED' $false "One or both legal labels missing — Implementation Step 3." }
} catch { Gate 'Labels: both present, privileged ENCRYPTED' $false "Get-Label failed: $($_.Exception.Message) — verify feature/cmdlet for your tenant." }

# Gate: DLP policy present and IN SIMULATION (or Enable if -RequireEnforced)
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $DlpPolicy }
    if (-not $dlp) { Gate 'DLP: policy present (simulation pre-enforcement)' $false "'$DlpPolicy' not found — Implementation Step 4 (create in SIMULATION)." }
    else {
        $mode = "$($dlp.Mode)"
        if ($RequireEnforced) {
            if ($mode -match 'Enable') { Gate 'DLP: policy ENFORCED (post-expand)' $true "'$DlpPolicy' is in Enable on the approved scope." }
            else { Gate 'DLP: policy ENFORCED (post-expand)' $false "'$DlpPolicy' present but still in '$mode' — move to Enable in-portal after sign-off." }
        } else {
            if ($mode -match 'Test|Simulat') { Gate 'DLP: policy present, IN SIMULATION' $true "'$DlpPolicy' present in '$mode' (blocks nothing — correct pre-enforcement)." }
            elseif ($mode -match 'Enable') { Gate 'DLP: policy present, IN SIMULATION' $true "'$DlpPolicy' is ENFORCED (Enable) — confirm this was intended and legal signed off." }
            else { Gate 'DLP: policy present, IN SIMULATION' $false "'$DlpPolicy' present but mode '$mode' unrecognized — verify." }
        }
    }
} catch { Gate 'DLP: policy present' $false "Get-DlpCompliancePolicy failed: $($_.Exception.Message)" }

# Gate: matter-records retention scoped
try {
    $pol = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $RetentionPolicy }
    if ($pol -and $pol.Enabled) { Gate 'Retention: matter-records policy scoped' $true "'$RetentionPolicy' present and enabled." }
    elseif ($pol) { Gate 'Retention: matter-records policy scoped' $false "'$RetentionPolicy' present but DISABLED." }
    else { Gate 'Retention: matter-records policy scoped' $false "'$RetentionPolicy' not found — Implementation Step 5." }
} catch { Gate 'Retention: matter-records policy scoped' $false "Get-RetentionCompliancePolicy failed: $($_.Exception.Message)" }

# Gate: unified audit on
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
    else { Gate 'Audit: evidence retention policy present' $false "'$AuditPolicy' not found — Implementation Step 6." }
} catch { Gate 'Audit: evidence retention policy present' $false "Get-UnifiedAuditLogRetentionPolicy failed: $($_.Exception.Message)" }

Write-Host "`n=== Legal Program Scorecard ===" -ForegroundColor Cyan
$results | ForEach-Object {
    $c = if ($_.Status -eq 'GREEN') { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $_.Status, $_.Gate) -ForegroundColor $c
    Write-Host ("         {0}" -f $_.Detail) -ForegroundColor DarkGray
}
$red = @($results | Where-Object { $_.Status -eq 'RED' }).Count
if ($red -eq 0) { Write-Host "`nAll in-scope gates GREEN for this scope. Technical controls present — proceed per Testing Guide (DLP stays in simulation until match review + legal sign-off)." -ForegroundColor Green }
else { Write-Host "`n$red gate(s) RED — remediate before enforcing anything on production scope." -ForegroundColor Yellow }
Write-Host "NOTE: adequacy of privilege/matter mapping, retention fit, and legal-hold scope are legal/records determinations, not scored here." -ForegroundColor White
