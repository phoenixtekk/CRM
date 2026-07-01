<#
.SYNOPSIS
    WDACMIG-Validation.ps1 — confirm the migrated WDAC policy is applied and report its mode.
.DESCRIPTION
    PURPOSE
        Verifies that a WDAC (App Control for Business) code-integrity policy is active on the device
        and whether it is in Audit or Enforced mode, and confirms the Code Integrity Operational log
        is present so audit events are being recorded. Use after Implementation Steps 5, 7, and 8.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WDACMIG-Validation.ps1
    EXPECTED RESULTS
        "WDAC ACTIVE (Audit)" during the audit phase, "WDAC ACTIVE (Enforced)" after enforcement,
        or "NO ACTIVE POLICY" if none applied (check assignment / sync). Read-only.
.NOTES
    Read-only. Run on a device in the ring being migrated.
#>
[CmdletBinding()] param()
Write-Host "=== AppLocker to WDAC Migration — Validation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

$state = 0
try {
    $dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction Stop
    $state = [int]$dg.CodeIntegrityPolicyEnforcementStatus
} catch {}

# audit log presence (so we know would-block events are being recorded)
try {
    $log = Get-WinEvent -ListLog 'Microsoft-Windows-CodeIntegrity/Operational' -ErrorAction Stop
    Write-Host ("Code Integrity Operational log: present (enabled={0})" -f $log.IsEnabled) -ForegroundColor Gray
} catch { Write-Host "Code Integrity Operational log not accessible." -ForegroundColor Yellow }

$citool = "$env:WINDIR\System32\citool.exe"
$policyCount = 0
if (Test-Path $citool) { $policyCount = (& $citool --list-policies 2>$null | Select-String 'PolicyID').Count }

switch ($state) {
    2 { Write-Host "Result: WDAC ACTIVE (Enforced)" -ForegroundColor Green; exit 0 }
    1 { Write-Host "Result: WDAC ACTIVE (Audit)" -ForegroundColor Green; exit 0 }
    default {
        if ($policyCount -gt 0) { Write-Host "Result: App Control policies present ($policyCount) — enforcement status reported Off; verify mode in policy/citool." -ForegroundColor Yellow; exit 0 }
        Write-Host "Result: NO ACTIVE POLICY — check assignment of 'App Control - Fleet - Audit' / sync (WDACMIG-Remediation.ps1)" -ForegroundColor Yellow; exit 1
    }
}
