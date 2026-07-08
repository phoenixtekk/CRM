<#
.SYNOPSIS
    OPSHEALTH-Validate.ps1 — pass/fail validation checker aligned to 05-testing.md (read-only).
.DESCRIPTION
    PURPOSE
        Emits one PASS/FAIL line per health-check criterion so the estate can be scored and, after
        remediation, re-scored. It checks: at least one intended DLP/retention/label policy is enabled
        and not stuck in test; the unified audit log is on; and the compliance role review is clean
        (no empty/SPOF role groups). Read-only — changes nothing. Use it for the initial score and for
        the Gate 10 post-remediation re-score.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSHEALTH-Validate.ps1
        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline), MFA-capable
        read admin. Verify capability availability against your licensing/tenant.
    EXPECTED RESULTS
        A list of PASS/FAIL lines and an overall pass count. PASS overall = no intended policy missing/
        disabled/stuck, audit log on, role review clean. Any FAIL is a Remediation-Register row. Exit
        code 0 when all pass, 1 when any fail (for pipeline use).
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Exchange Online. No credentials in code.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }
$pass = 0; $fail = 0
function Test-Line([string] $Name, [bool] $Ok, [string] $Detail) {
    if ($Ok) { Write-Host ("  PASS  {0}" -f $Name) -ForegroundColor Green; $script:pass++ }
    else     { Write-Host ("  FAIL  {0} — {1}" -f $Name, $Detail) -ForegroundColor Red; $script:fail++ }
}

try {
    Write-Section 'Connecting'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) { Connect-IPPSSession | Out-Null }
    Write-Host 'Connected to Security & Compliance PowerShell.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect: {0}" -f $_.Exception.Message); exit 1 }

# --- Policy health (P) ------------------------------------------------------------------------------
Write-Section 'Policy health (P)'
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    $enabledDlp = @($dlp | Where-Object { $_.Enabled -ne $false -and $_.Mode -notlike 'Test*' -and $_.Mode -ne 'Disable' })
    Test-Line 'At least one DLP policy is enabled and not stuck in test' ($enabledDlp.Count -ge 1) 'no enabled/enforcing DLP policy found (check intent — R4)'
    $stuck = @($dlp | Where-Object { $_.Mode -like 'Test*' })
    Test-Line 'No DLP policy is stuck in simulation/test past pilot' ($stuck.Count -eq 0) ("{0} DLP policy(ies) in test mode — confirm they are fresh pilots" -f $stuck.Count)
}
catch { Test-Line 'DLP policies readable' $false ('unreadable: ' + $_.Exception.Message) }

try {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
    $retOn = @($ret | Where-Object { $_.Enabled -ne $false })
    Test-Line 'At least one retention policy is enabled' ($retOn.Count -ge 1) 'no enabled retention policy found (check intent — R4)'
}
catch { Test-Line 'Retention policies readable' $false ('unreadable: ' + $_.Exception.Message) }

try {
    $labelPolicies = @(Get-LabelPolicy -ErrorAction Stop)
    Test-Line 'At least one label policy publishes labels' ($labelPolicies.Count -ge 1) 'no label policy found — labels unpublished (check intent — R4)'
}
catch { Test-Line 'Label policies readable' $false ('unreadable: ' + $_.Exception.Message) }

# --- Audit log (foundational) ----------------------------------------------------------------------
Write-Section 'Unified audit log'
try {
    if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }
    $ual = (Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled
    Test-Line 'Unified audit log is ON' ([bool]$ual) 'audit log is OFF — High-severity Gap (OPSHEALTH-Remediate.ps1 -EnableUnifiedAuditLog -Commit)'
}
catch { Test-Line 'Unified audit log status readable' $false ('unreadable: ' + $_.Exception.Message + ' — verify Exchange Online read access') }

# --- Roles (R) --------------------------------------------------------------------------------------
Write-Section 'Roles (R)'
try {
    $rg = @(Get-RoleGroup -ErrorAction Stop)
    $bad = 0
    foreach ($g in $rg) {
        $members = @(Get-RoleGroupMember -Identity $g.Name -ErrorAction SilentlyContinue)
        if ($members.Count -le 1) { $bad++ }
    }
    Test-Line 'No empty or single-member (SPOF) compliance role groups' ($bad -eq 0) ("{0} role group(s) empty or single-member — see OPSHEALTH-ScopeCheck.ps1" -f $bad)
}
catch { Test-Line 'Role groups readable' $false ('unreadable: ' + $_.Exception.Message) }

# --- Summary ----------------------------------------------------------------------------------------
Write-Section 'Validation summary'
Write-Host ("  PASS: {0}   FAIL: {1}" -f $pass, $fail) -ForegroundColor $(if($fail -eq 0){'Green'}else{'Yellow'})
Write-Host 'Every FAIL is a Remediation-Register row. Determinations (records/legal) are routed to governance, not fixed here.'
if ($fail -eq 0) { exit 0 } else { exit 1 }
