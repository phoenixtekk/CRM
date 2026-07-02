<#
.SYNOPSIS
    DCP-Discovery.ps1 — local device health facts for compliance readiness.
.DESCRIPTION
    PURPOSE
        Reports the facets a Windows compliance policy typically checks: BitLocker, Secure Boot,
        Defender Antivirus + real-time protection, Windows Firewall, and OS version.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\DCP-Discovery.ps1
    EXPECTED RESULTS
        PASS/FAIL per facet and an overall readiness verdict.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
function R($n,$p,$d){ [pscustomobject]@{Check=$n;Result=if($p){'PASS'}else{'FAIL'};Detail=$d} }
$res = New-Object System.Collections.Generic.List[object]
$os = Get-CimInstance Win32_OperatingSystem
$res.Add( (R 'OS version' ([version]$os.Version -ge [version]'10.0.19044') "$($os.Caption) $($os.Version)") )
try { $bde = (manage-bde -status $env:SystemDrive 2>$null | Select-String 'Protection Status').ToString(); $res.Add((R 'BitLocker (system drive)' ($bde -match 'On') $bde.Trim())) } catch { $res.Add((R 'BitLocker (system drive)' $false 'unknown')) }
try { $sb = Confirm-SecureBootUEFI; $res.Add((R 'Secure Boot' $sb "Enabled=$sb")) } catch { $res.Add((R 'Secure Boot' $false 'not UEFI / unknown')) }
try { $mp = Get-MpComputerStatus; $res.Add((R 'Defender real-time protection' ($mp.RealTimeProtectionEnabled) "AMRunning=$($mp.AMServiceEnabled)")) } catch { $res.Add((R 'Defender real-time protection' $false 'unknown')) }
$fw = (Get-NetFirewallProfile -ErrorAction SilentlyContinue | Where-Object Enabled -eq $true).Count
$res.Add( (R 'Windows Firewall profiles on' ($fw -ge 1) "$fw/3 enabled") )
Write-Host "`n=== Compliance Health ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$res | Format-Table -AutoSize
$overall = if ($res | Where-Object Result -eq 'FAIL') { 'NEEDS REMEDIATION' } else { 'COMPLIANT-READY' }
Write-Host "Overall: $overall" -ForegroundColor ($(if($overall -eq 'COMPLIANT-READY'){'Green'}else{'Yellow'}))
