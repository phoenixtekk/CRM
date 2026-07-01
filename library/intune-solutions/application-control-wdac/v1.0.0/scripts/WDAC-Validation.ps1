<#
.SYNOPSIS
    WDAC-Validation.ps1 — confirm an App Control (WDAC) policy is active and report its mode.
.DESCRIPTION
    PURPOSE
        Verifies a code-integrity policy is active and whether it is in Audit or Enforced mode,
        using the DeviceGuard WMI status (and citool on Windows 11).
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WDAC-Validation.ps1
    EXPECTED RESULTS
        "WDAC ACTIVE (Audit)" or "WDAC ACTIVE (Enforced)"; "NO ACTIVE POLICY" if none.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "=== WDAC Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$state = 0
try { $dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction Stop; $state = [int]$dg.CodeIntegrityPolicyEnforcementStatus } catch {}
$citool = "$env:WINDIR\System32\citool.exe"
$policyCount = 0
if (Test-Path $citool) { $policyCount = (& $citool --list-policies 2>$null | Select-String 'PolicyID').Count }
switch ($state) {
    2 { Write-Host "Result: WDAC ACTIVE (Enforced)" -ForegroundColor Green; exit 0 }
    1 { Write-Host "Result: WDAC ACTIVE (Audit)" -ForegroundColor Green; exit 0 }
    default {
        if ($policyCount -gt 0) { Write-Host "Result: App Control policies present ($policyCount) — enforcement status reported Off; verify mode in policy/citool." -ForegroundColor Yellow; exit 0 }
        Write-Host "Result: NO ACTIVE POLICY — check assignment / sync (WDAC-Remediation.ps1)" -ForegroundColor Yellow; exit 1
    }
}
