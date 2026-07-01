<#
.SYNOPSIS
    ESB-Validation.ps1 — confirm representative security baseline settings are applied.
.DESCRIPTION
    PURPOSE
        Checks a sample of settings the Windows security baseline hardens (firewall on, PUA
        protection, network protection, SMBv1 removed, UAC on) against their expected hardened values.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\ESB-Validation.ps1
    EXPECTED RESULTS
        "BASELINE APPLIED (sample)" when the sampled settings match hardened expectations.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only. Authoritative status is in Intune per-setting report.
#>
[CmdletBinding()] param()
Write-Host "=== Baseline Validation (sample) — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$pass = $true
function Check($n,$ok,$d){ $script:pass = $script:pass -and $ok; Write-Host ("{0,-34}: {1}  {2}" -f $n, ($(if($ok){'PASS'}else{'FAIL'})), $d) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'})) }
try { $mp = Get-MpPreference } catch { $mp = $null }
Check 'Firewall all profiles on' (((Get-NetFirewallProfile).Enabled -notcontains $false)) ''
Check 'Defender PUA protection on' ($mp -and $mp.PUAProtection -ge 1) "($($mp.PUAProtection))"
Check 'Network protection on' ($mp -and $mp.EnableNetworkProtection -ge 1) "($($mp.EnableNetworkProtection))"
Check 'SMBv1 disabled' (((Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -EA SilentlyContinue).State) -ne 'Enabled') ''
Check 'UAC enabled' (((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -EA SilentlyContinue).EnableLUA) -eq 1) ''
if ($pass) { Write-Host "`nResult: BASELINE APPLIED (sample)" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: SOME SAMPLED SETTINGS NOT HARDENED — check baseline assignment / conflicts / sync" -ForegroundColor Yellow; exit 1 }
