<#
.SYNOPSIS
    OPSMANAGED-Validation.ps1 — pass/fail health check for the managed service cadence (read-only).
.DESCRIPTION
    PURPOSE
        Emits one PASS/FAIL line per operational health criterion so the service can validate the pilot and
        re-check each cycle: the unified audit log is on (the estate is evidenced), no intended DLP/
        retention/label policy is missing/disabled/stuck in test, and the compliance role review is clean.
        Read-only — changes nothing. Use it at Implementation Step 5 and on the ongoing cadence.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSMANAGED-Validation.ps1
        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline), MFA-capable read
        admin. Verify capability availability against your licensing/tenant.
    EXPECTED RESULTS
        A list of PASS/FAIL lines and an overall pass count. Exit code 0 when all pass, 1 when any fail.
        Every FAIL is a triage item routed to its owning capability.
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
    Write-Host 'Connected.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect: {0}" -f $_.Exception.Message); exit 1 }

Write-Section 'Audit log (foundational)'
try {
    if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }
    $ual = (Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled
    Test-Line 'Unified audit log is ON' ([bool]$ual) 'audit log OFF — the estate is un-evidenced; route to the Audit owner'
}
catch { Test-Line 'Unified audit log status readable' $false ('unreadable: ' + $_.Exception.Message) }

Write-Section 'Policy health (no drift)'
try {
    $dlp = @(Get-DlpCompliancePolicy -ErrorAction Stop)
    $stuck = @($dlp | Where-Object { $_.Mode -like 'Test*' })
    Test-Line 'No DLP policy stuck in simulation/test past pilot' ($stuck.Count -eq 0) ("{0} DLP policy(ies) in test mode — confirm fresh pilots or triage as drift" -f $stuck.Count)
    $disabled = @($dlp | Where-Object { $_.Enabled -eq $false })
    Test-Line 'No DLP policy unexpectedly disabled' ($disabled.Count -eq 0) ("{0} DLP policy(ies) disabled — check intent" -f $disabled.Count)
}
catch { Test-Line 'DLP policies readable' $false ('unreadable: ' + $_.Exception.Message) }

try {
    $ret = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
    $retDisabled = @($ret | Where-Object { $_.Enabled -eq $false })
    Test-Line 'No retention policy unexpectedly disabled' ($retDisabled.Count -eq 0) ("{0} retention policy(ies) disabled — check intent" -f $retDisabled.Count)
}
catch { Test-Line 'Retention policies readable' $false ('unreadable: ' + $_.Exception.Message) }

try {
    $lp = @(Get-LabelPolicy -ErrorAction Stop)
    Test-Line 'At least one label policy publishes labels' ($lp.Count -ge 1) 'no label policy found — labels unpublished (check intent)'
}
catch { Test-Line 'Label policies readable' $false ('unreadable: ' + $_.Exception.Message) }

Write-Section 'Roles'
try {
    $rg = @(Get-RoleGroup -ErrorAction Stop)
    $bad = 0
    foreach ($g in $rg) { $m = @(Get-RoleGroupMember -Identity $g.Name -ErrorAction SilentlyContinue); if ($m.Count -le 1) { $bad++ } }
    Test-Line 'No empty or single-member (SPOF) compliance role groups' ($bad -eq 0) ("{0} role group(s) empty or single-member" -f $bad)
}
catch { Test-Line 'Role groups readable' $false ('unreadable: ' + $_.Exception.Message) }

Write-Section 'Validation summary'
Write-Host ("  PASS: {0}   FAIL: {1}" -f $pass, $fail) -ForegroundColor $(if($fail -eq 0){'Green'}else{'Yellow'})
Write-Host 'Every FAIL is a triage item routed to its owning capability (piloted there). Determinations go to governance.'
if ($fail -eq 0) { exit 0 } else { exit 1 }
