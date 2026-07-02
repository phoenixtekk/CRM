<#
.SYNOPSIS
    MDE-Validation.ps1 — confirm Defender for Endpoint onboarding and sensor health.
.DESCRIPTION
    PURPOSE
        Verifies the device is onboarded to MDE (OnboardingState=1), the Sense service is running,
        and the org/device identifiers are present.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\MDE-Validation.ps1
    EXPECTED RESULTS
        "MDE ONBOARDED" with Sense Running and OnboardingState=1.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "=== MDE Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$status = 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status'
$ob = (Get-ItemProperty $status -ErrorAction SilentlyContinue).OnboardingState
$org = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection' -ErrorAction SilentlyContinue).OrgId
$sense = Get-Service Sense -ErrorAction SilentlyContinue
Write-Host ("Sense service     : {0}" -f ($(if($sense){$sense.Status}else{'NOT FOUND'}))) -ForegroundColor ($(if($sense.Status -eq 'Running'){'Green'}else{'Yellow'}))
Write-Host ("OnboardingState   : {0}" -f $ob) -ForegroundColor ($(if($ob -eq 1){'Green'}else{'Yellow'}))
Write-Host ("OrgId             : {0}" -f ($(if($org){$org}else{'not set'})))
if ($ob -eq 1 -and $sense.Status -eq 'Running') { Write-Host "`nResult: MDE ONBOARDED" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT ONBOARDED — sync policy / run MDE-Remediation.ps1" -ForegroundColor Yellow; exit 1 }
