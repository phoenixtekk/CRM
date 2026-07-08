<#
.SYNOPSIS
    CMPFINRA-Validate.ps1 — FINRA/SEC control-program readiness scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Scores the program across the three control domains with no changes: records/regulatory-records
        label present and correctly typed, comms-store retention scoped, unified audit on with the
        evidence-retention policy present, and a supervision policy present IN TEST. Emits a PASS/FAIL
        per gate mirroring the Testing Guide. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFINRA-Validate.ps1
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin;
        no secrets. For audit ingestion state it also uses Connect-ExchangeOnline where available.
    EXPECTED RESULTS
        A scorecard: each gate GREEN (pass) or RED (fail) with the remediation pointer. PASS overall =
        every in-scope gate green for the pilot scope. Determination-level adequacy (retention, scope,
        rule fit) is NOT scored here — that is compliance/records/legal's.
.NOTES
    Purview category — FINRA/SEC Compliance Program. Read-only. Proves the technical control works and is
    present; does not certify regulatory compliance. Verify cmdlet/plan names for your tenant.
#>
[CmdletBinding()]
param(
    [string]$RegulatoryLabel   = 'Records – FINRA/SEC Regulated – Regulatory',
    [string]$CommsRetention    = 'Retention – FINRA/SEC Comms Store – Immutable',
    [string]$AuditPolicy       = 'Audit Retention – FINRA/SEC Evidence – LongTerm',
    [string]$SupervisionPolicy = 'Supervision – Registered Persons Comms – Test',
    [switch]$AllowPilotLabel   # accept a non-regulatory pilot records label as a pass for the records gate (pre sign-off)
)

$ErrorActionPreference = 'Stop'
$results = @()
function Gate($name,$pass,$detail){ $script:results += [pscustomobject]@{ Gate=$name; Status = if($pass){'GREEN'}else{'RED'}; Detail=$detail } }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Warn "ExchangeOnlineManagement not installed."; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# Gate: records-preservation label
try {
    $tags = Get-ComplianceTag -ErrorAction Stop
    $reg  = $tags | Where-Object { $_.Name -eq $RegulatoryLabel -and $_.RegulatoryRecord }
    $pilot= $tags | Where-Object { $_.IsRecordLabel -and $_.Name -match 'FINRA/SEC' }
    if ($reg) { Gate 'Records: regulatory-records label present' $true "'$RegulatoryLabel' exists and is a regulatory record." }
    elseif ($AllowPilotLabel -and $pilot) { Gate 'Records: pilot records label present (pre sign-off)' $true "Non-regulatory pilot label present; regulatory label pending compliance sign-off." }
    else { Gate 'Records: preservation label present' $false "No FINRA/SEC records label found — Implementation Step 3." }
} catch { Gate 'Records: preservation label present' $false "Get-ComplianceTag failed: $($_.Exception.Message)" }

# Gate: comms-store retention scoped
try {
    $pol = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $CommsRetention }
    if ($pol -and $pol.Enabled) { Gate 'Records: comms-store retention scoped' $true "'$CommsRetention' present and enabled." }
    elseif ($pol) { Gate 'Records: comms-store retention scoped' $false "'$CommsRetention' present but DISABLED." }
    else { Gate 'Records: comms-store retention scoped' $false "'$CommsRetention' not found — Implementation Step 3." }
} catch { Gate 'Records: comms-store retention scoped' $false "Get-RetentionCompliancePolicy failed: $($_.Exception.Message)" }

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
    else { Gate 'Audit: evidence retention policy present' $false "'$AuditPolicy' not found — Implementation Step 4." }
} catch { Gate 'Audit: evidence retention policy present' $false "Get-UnifiedAuditLogRetentionPolicy failed: $($_.Exception.Message)" }

# Gate: supervision policy present (test)
try {
    $sup = Get-SupervisoryReviewPolicyV2 -ErrorAction Stop | Where-Object { $_.Name -eq $SupervisionPolicy }
    if ($sup) { Gate 'Supervision: policy present (build/verify in TEST)' $true "'$SupervisionPolicy' present — confirm test scope + reviewer separation + pseudonymization." }
    else { Gate 'Supervision: policy present (build/verify in TEST)' $false "'$SupervisionPolicy' not found — Implementation Step 5 (create in TEST)." }
} catch { Gate 'Supervision: policy present (build/verify in TEST)' $false "Get-SupervisoryReviewPolicyV2 failed: $($_.Exception.Message) — verify feature/cmdlet for your tenant." }

Write-Host "`n=== FINRA/SEC Program Scorecard ===" -ForegroundColor Cyan
$results | ForEach-Object {
    $c = if ($_.Status -eq 'GREEN') { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $_.Status, $_.Gate) -ForegroundColor $c
    Write-Host ("         {0}" -f $_.Detail) -ForegroundColor DarkGray
}
$red = @($results | Where-Object { $_.Status -eq 'RED' }).Count
if ($red -eq 0) { Write-Host "`nAll in-scope gates GREEN for this scope. Technical controls present — proceed per Testing Guide." -ForegroundColor Green }
else { Write-Host "`n$red gate(s) RED — remediate before enforcing tenant-wide." -ForegroundColor Yellow }
Write-Host "NOTE: adequacy of retention/supervisory scope and rule fit are compliance/records/legal determinations, not scored here." -ForegroundColor White
