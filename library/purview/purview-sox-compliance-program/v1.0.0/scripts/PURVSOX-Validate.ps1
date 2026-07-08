<#
.SYNOPSIS
    PURVSOX-Validate.ps1 — confirm each SOX Purview control exists and is in its expected state (read-only).
.DESCRIPTION
    PURPOSE
        Validates the program's controls without changing anything: unified audit on; the financial-data
        label published; the DLP policy present and in a TEST/SIMULATION mode (not enforcing) during the
        pilot; the SOX retention policy scoped and enabled; and the financial-access audit retention
        policy present. Prints a PASS/FAIL line per control. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVSOX-Validate.ps1
        # Once the pilot is signed off and DLP has been moved to enforce, assert that instead:
        .\PURVSOX-Validate.ps1 -ExpectDlpEnforced
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline). Interactive
        modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A PASS/FAIL summary across the five controls. During the pilot, DLP PASSES when in a Test mode
        and FAILS if already Enable; with -ExpectDlpEnforced the logic inverts (Enable = PASS).
.NOTES
    Purview category — SOX Compliance Program. Read-only. Proves the configuration operates, NOT that
    the SOX control design or retention schedule is adequate (those are management/internal-audit/
    records/legal determinations).
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$LabelName          = 'Financial – SOX Reporting – Confidential',
    [string]$DlpName            = 'DLP – SOX Financial Data – Simulation',
    [string]$RetentionName      = 'Retention – SOX Financial Records – Governed',
    [string]$AuditRetentionName = 'Audit Retention – Financial Data Access – SOX',
    [switch]$ExpectDlpEnforced                       # after pilot sign-off, expect DLP Mode = Enable
)

$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0
function Pass($m){ $script:pass++; Write-Host "  PASS  $m" -ForegroundColor Green }
function Failx($m){ $script:fail++; Write-Host "  FAIL  $m" -ForegroundColor Red }
function Info($m){ Write-Host $m -ForegroundColor Cyan }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

Info "`n=== Gate 1: unified audit logging on ==="
try {
    Connect-ExchangeOnline @cp -ErrorAction Stop | Out-Null
    if ((Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled) { Pass "UnifiedAuditLogIngestionEnabled = True" }
    else { Failx "UnifiedAuditLogIngestionEnabled = False — enable via PURVSOX-ConfigureControls.ps1 -EnableUnifiedAudit -Commit" }
} catch { Failx "Could not read AdminAuditLogConfig: $($_.Exception.Message)" }

try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null }
catch { Write-Host "Connect-IPPSSession failed — cannot validate labels/DLP/retention: $($_.Exception.Message)" -ForegroundColor Red; return }

Info "`n=== Gate 3: financial-data label published ==="
try {
    $lbl = Get-Label -Identity $LabelName -ErrorAction SilentlyContinue
    if ($lbl) {
        $published = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Settings -match [regex]::Escape($LabelName) -or $_.Labels -contains $lbl.Guid -or $_.Labels -contains $LabelName }
        if ($published) { Pass "Label '$LabelName' exists and is published via a label policy" }
        else { Failx "Label '$LabelName' exists but no label policy publishes it — run -Control LabelPolicy" }
    } else { Failx "Label '$LabelName' not found — run -Control Label" }
} catch { Failx "Label check failed: $($_.Exception.Message)" }

Info "`n=== Gate 4/5: DLP policy present and in expected mode ==="
try {
    $dlp = Get-DlpCompliancePolicy -Identity $DlpName -ErrorAction SilentlyContinue
    if (-not $dlp) { Failx "DLP policy '$DlpName' not found — run -Control Dlp (simulation)" }
    else {
        $isTest = $dlp.Mode -like 'Test*'
        if ($ExpectDlpEnforced) {
            if ($dlp.Mode -eq 'Enable') { Pass "DLP '$DlpName' Mode = Enable (enforcing, as expected post-pilot)" }
            else { Failx "DLP '$DlpName' Mode = $($dlp.Mode) — expected Enable after pilot sign-off" }
        } else {
            if ($isTest) { Pass "DLP '$DlpName' Mode = $($dlp.Mode) (SIMULATION, correct during pilot)" }
            elseif ($dlp.Mode -eq 'Enable') { Failx "DLP '$DlpName' Mode = Enable but pilot not signed off — set back to TestWithNotifications until validated" }
            else { Failx "DLP '$DlpName' Mode = $($dlp.Mode) (disabled?) — expected a Test/simulation mode during pilot" }
        }
    }
} catch { Failx "DLP check failed: $($_.Exception.Message)" }

Info "`n=== Gate 6: SOX records retention policy scoped ==="
try {
    $rp = Get-RetentionCompliancePolicy -Identity $RetentionName -ErrorAction SilentlyContinue
    if ($rp) { if ($rp.Enabled) { Pass "Retention '$RetentionName' exists and is enabled" } else { Failx "Retention '$RetentionName' exists but is disabled" } }
    else { Failx "Retention policy '$RetentionName' not found — run -Control Retention (period from your records schedule)" }
} catch { Failx "Retention check failed: $($_.Exception.Message)" }

Info "`n=== Gate 7: financial-access audit retention policy ==="
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -Identity $AuditRetentionName -ErrorAction SilentlyContinue
    if ($arp) { Pass "Audit retention '$AuditRetentionName' exists (duration $($arp.RetentionDuration), priority $($arp.Priority))" }
    else { Failx "Audit retention policy '$AuditRetentionName' not found — run -Control AuditRetention" }
} catch { Failx "Audit retention check failed: $($_.Exception.Message)" }

Info "`n=== Summary ==="
Write-Host ("  {0} PASS / {1} FAIL" -f $pass, $fail) -ForegroundColor $(if($fail){'Red'}else{'Green'})
if ($fail) { Write-Host "  Address each FAIL per the Implementation guide, then re-run. Do not expand to enforcement until the pilot is green." -ForegroundColor Yellow }
else { Write-Host "  All controls in expected state. Validation proves configuration, not SOX control adequacy (deferred to management/internal audit)." -ForegroundColor White }
