<#
.SYNOPSIS
    PURVASSESS-Validate.ps1 — re-read the remediated capabilities and confirm each fix took effect (read-only).
.DESCRIPTION
    PURPOSE
        Validation counterpart to PURVASSESS-Remediate.ps1. For each fix applied in Step 5 it re-reads the
        capability and confirms the target state: a DLP policy now in TestWithNotifications, an auto-labeling
        policy in simulation, a retention policy Enabled=True, and unified audit ingestion True. Read-only —
        it makes no changes; it only reports PASS/FAIL per fix so a finding can be marked cleared.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVASSESS-Validate.ps1 -DlpPolicy "Global PII" -RetentionPolicy "Legal Hold Baseline" -CheckAudit
        Pass the names of the policies you remediated. Requires ExchangeOnlineManagement
        (Connect-IPPSSession / Connect-ExchangeOnline). Interactive modern-auth / MFA; no secrets in code.
    EXPECTED RESULTS
        A PASS/FAIL line per checked fix. All PASS = the remediated findings validate green for the pilot
        scope (Gate 9). Any FAIL = the change did not take; re-check the fix / pilot scope before expanding.
.NOTES
    Purview category — Tenant Assessment. Read-only. Confirms the fix took effect, NOT that the resulting
    configuration satisfies a regulation (that is a compliance/records/legal determination).
#>
[CmdletBinding()]
param(
    [string]$DlpPolicy,                  # DLP policy expected in TestWithNotifications
    [string]$AutoLabelPolicy,            # auto-labeling policy expected in simulation (TestWithoutNotifications)
    [string]$RetentionPolicy,            # retention policy expected Enabled=True
    [switch]$CheckAudit,                 # verify UnifiedAuditLogIngestionEnabled=True
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Pass($m){ Write-Host "  [PASS] $m" -ForegroundColor Green }
function Fail($m){ Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Info($m){ Write-Host "  $m" -ForegroundColor White }

$connectParams = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession @connectParams | Out-Null } catch { Info "Connect-IPPSSession: $($_.Exception.Message)" }
if ($CheckAudit) { try { Connect-ExchangeOnline @connectParams } catch { Info "Connect-ExchangeOnline: $($_.Exception.Message)" } }

$results = New-Object System.Collections.Generic.List[object]
function Check($name, $expected, $actual){
    $ok = ("$actual" -eq "$expected")
    if ($ok) { Pass "$name : $actual (expected $expected)" } else { Fail "$name : $actual (expected $expected)" }
    $results.Add([pscustomobject]@{ Check=$name; Expected=$expected; Actual=$actual; Result=($ok ? 'PASS' : 'FAIL') })
}

Write-Section "Validate remediated findings"

if ($DlpPolicy) {
    try { $p = Get-DlpCompliancePolicy -Identity $DlpPolicy -ErrorAction Stop; Check "DLP '$DlpPolicy' mode" 'TestWithNotifications' $p.Mode }
    catch { Fail "DLP '$DlpPolicy' read failed — $($_.Exception.Message)"; $results.Add([pscustomobject]@{ Check="DLP $DlpPolicy"; Expected='TestWithNotifications'; Actual='READ-FAILED'; Result='FAIL' }) }
}
if ($AutoLabelPolicy) {
    try { $p = Get-AutoSensitivityLabelPolicy -Identity $AutoLabelPolicy -ErrorAction Stop; Check "Auto-label '$AutoLabelPolicy' mode" 'TestWithoutNotifications' $p.Mode }
    catch { Fail "Auto-label '$AutoLabelPolicy' read failed — $($_.Exception.Message)"; $results.Add([pscustomobject]@{ Check="AutoLabel $AutoLabelPolicy"; Expected='TestWithoutNotifications'; Actual='READ-FAILED'; Result='FAIL' }) }
}
if ($RetentionPolicy) {
    try { $p = Get-RetentionCompliancePolicy -Identity $RetentionPolicy -ErrorAction Stop; Check "Retention '$RetentionPolicy' Enabled" 'True' $p.Enabled }
    catch { Fail "Retention '$RetentionPolicy' read failed — $($_.Exception.Message)"; $results.Add([pscustomobject]@{ Check="Retention $RetentionPolicy"; Expected='True'; Actual='READ-FAILED'; Result='FAIL' }) }
}
if ($CheckAudit) {
    try { $a = Get-AdminAuditLogConfig; Check "Unified audit ingestion" 'True' $a.UnifiedAuditLogIngestionEnabled }
    catch { Fail "Audit config read failed — $($_.Exception.Message)"; $results.Add([pscustomobject]@{ Check="UnifiedAudit"; Expected='True'; Actual='READ-FAILED'; Result='FAIL' }) }
}

Write-Section "Validation summary"
if ($results.Count -eq 0) { Info "No checks requested — pass -DlpPolicy / -AutoLabelPolicy / -RetentionPolicy / -CheckAudit for the fixes you applied." }
else {
    $results | Format-Table -AutoSize
    $failed = @($results | Where-Object Result -eq 'FAIL').Count
    if ($failed -eq 0) { Pass "All $($results.Count) checks passed — remediated findings validate green (Gate 9)." }
    else { Fail "$failed of $($results.Count) checks FAILED — do not expand; re-check the fix / pilot scope, revert if needed (PURVASSESS-Remediate.ps1 -Revert -Commit)." }
}
