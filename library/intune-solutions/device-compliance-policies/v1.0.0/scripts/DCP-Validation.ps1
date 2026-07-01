<#
.SYNOPSIS
    DCP-Validation.ps1 — confirm this device meets the compliance baseline and is reporting in.
.DESCRIPTION
    PURPOSE
        Checks the local facets a compliance policy enforces and confirms the device is
        MDM-enrolled (so Intune can evaluate it). A quick pre-check of "would this pass?".
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\DCP-Validation.ps1
    EXPECTED RESULTS
        "LIKELY COMPLIANT" when all enforced facets pass and the device is MDM-enrolled.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only. Authoritative status is in Intune.
#>
[CmdletBinding()] param()
Write-Host "=== Compliance Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$dsreg = (dsregcmd /status) 2>$null
$mdm = ($dsreg | Select-String 'MdmUrl\s*:\s*http') -ne $null
$pass = $true
function Check($n,$ok,$d){ $script:pass = $script:pass -and $ok; Write-Host ("{0,-32}: {1}  {2}" -f $n, ($(if($ok){'PASS'}else{'FAIL'})), $d) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'})) }
$os = Get-CimInstance Win32_OperatingSystem
Check 'OS >= 10.0.19044' ([version]$os.Version -ge [version]'10.0.19044') $os.Version
try { Check 'BitLocker on (C:)' (((manage-bde -status $env:SystemDrive) -match 'Protection On')) '' } catch { Check 'BitLocker on (C:)' $false 'err' }
try { Check 'Secure Boot' (Confirm-SecureBootUEFI) '' } catch { Check 'Secure Boot' $false 'err' }
try { $mp=Get-MpComputerStatus; Check 'Defender real-time' ($mp.RealTimeProtectionEnabled) '' } catch { Check 'Defender real-time' $false 'err' }
Check 'Firewall on' (((Get-NetFirewallProfile).Enabled -contains $true)) ''
Check 'MDM enrolled' $mdm ''
if ($pass -and $mdm) { Write-Host "`nResult: LIKELY COMPLIANT" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: WOULD FAIL — run DCP-Discovery.ps1 / DCP-Remediation.ps1" -ForegroundColor Yellow; exit 1 }
