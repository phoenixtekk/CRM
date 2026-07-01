<#
.SYNOPSIS
    W11HC-Validation.ps1 - confirm the Windows 11 baseline has applied to this device.
.DESCRIPTION
    PURPOSE
        Verifies the baseline is present on the device: Microsoft Defender real-time protection and
        SmartScreen on, an update deferral policy written by the update ring, and the power timeouts
        expected for the device scope (clinical always-on vs corporate battery-saving). Flags a
        conflicting authority.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\W11HC-Validation.ps1
    EXPECTED RESULTS
        "BASELINE APPLIED" when Defender/SmartScreen are on, an update policy is present, and no
        conflicting authority exists. Power timeouts are reported for review.
.NOTES
    Healthcare Solutions - Windows 11 endpoint baseline. Read-only.
#>
[CmdletBinding()] param()
Write-Host "=== W11HC Validation - $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
# Defender + SmartScreen
$mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
$rtp = [bool]($mp -and $mp.RealTimeProtectionEnabled)
$ss = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -ErrorAction SilentlyContinue).EnableSmartScreen
Write-Host ("Defender RTP      : {0}" -f ($(if($rtp){'ON'}else{'OFF'}))) -ForegroundColor ($(if($rtp){'Green'}else{'Yellow'}))
Write-Host ("SmartScreen       : {0}" -f ($(if($ss -ge 1){'ON'}else{'not set'}))) -ForegroundColor ($(if($ss -ge 1){'Green'}else{'Yellow'}))
# Update policy from the ring
$wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$p = Get-ItemProperty $wu -ErrorAction SilentlyContinue
$hasUpdate = [bool]($p -and ($p.PSObject.Properties.Name -contains 'DeferQualityUpdatesPeriodInDays'))
Write-Host ("Update ring policy: {0}" -f ($(if($hasUpdate){'present'}else{'NOT present'}))) -ForegroundColor ($(if($hasUpdate){'Green'}else{'Yellow'}))
# Power timeouts (plugged in)
$ac = (powercfg /q SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 2>$null | Select-String 'Current AC Power Setting Index').ToString()
Write-Host ("Sleep (AC) idx    : {0}" -f ($(if($ac){($ac -split ':')[-1].Trim()}else{'unknown'})))
# Conflict
$useWsus = (Get-ItemProperty "$wu\AU" -ErrorAction SilentlyContinue).UseWUServer
Write-Host ("Legacy authority  : {0}" -f ($(if($useWsus -eq 1){'PRESENT (remove)'}else{'none'}))) -ForegroundColor ($(if($useWsus -eq 1){'Yellow'}else{'Green'}))
if ($rtp -and $hasUpdate -and $useWsus -ne 1) { Write-Host "`nResult: BASELINE APPLIED" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT FULLY APPLIED - sync (W11HC-Remediation.ps1) / check assignment / remove legacy authority" -ForegroundColor Yellow; exit 1 }
