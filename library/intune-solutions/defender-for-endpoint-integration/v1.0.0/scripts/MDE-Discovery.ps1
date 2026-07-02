<#
.SYNOPSIS
    MDE-Discovery.ps1 — Defender for Endpoint onboarding readiness check.
.DESCRIPTION
    PURPOSE
        Reports whether a device is ready to onboard to MDE: OS, the Sense service presence,
        current onboarding state, and Defender AV health.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\MDE-Discovery.ps1
    EXPECTED RESULTS
        PASS/FAIL per facet and an onboarding-readiness verdict.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
function R($n,$p,$d){ [pscustomobject]@{Check=$n;Result=if($p){'PASS'}else{'FAIL'};Detail=$d} }
$res = New-Object System.Collections.Generic.List[object]
$os = Get-CimInstance Win32_OperatingSystem
$res.Add( (R 'OS supported (Win10/11)' ([version]$os.Version -ge [version]'10.0.18363') "$($os.Caption) $($os.Version)") )
$sense = Get-Service Sense -ErrorAction SilentlyContinue
$res.Add( (R 'Sense service present' ([bool]$sense) ($(if($sense){"Status=$($sense.Status)"}else{'not found'}))) )
$ob = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status' -ErrorAction SilentlyContinue).OnboardingState
$res.Add( (R 'Already onboarded' ($ob -eq 1) "OnboardingState=$ob") )
try { $mp = Get-MpComputerStatus; $res.Add( (R 'Defender AV healthy' ($mp.AMServiceEnabled) "RTP=$($mp.RealTimeProtectionEnabled)") ) } catch { $res.Add((R 'Defender AV healthy' $false 'unknown')) }
Write-Host "`n=== MDE Onboarding Readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$res | Format-Table -AutoSize
$blk = $res | Where-Object { $_.Result -eq 'FAIL' -and $_.Check -notmatch 'onboarded' }
Write-Host ("Overall: {0}" -f ($(if($blk){'NOT READY'}else{'READY'}))) -ForegroundColor ($(if($blk){'Yellow'}else{'Green'}))
