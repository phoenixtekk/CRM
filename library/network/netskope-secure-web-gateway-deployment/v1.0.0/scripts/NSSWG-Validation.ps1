<#
.SYNOPSIS
    NSSWG-Validation.ps1 — confirm SWG steering is active on THIS device.
.DESCRIPTION
    PURPOSE
        Verifies the Netskope client/service is running, traffic steering is active, and the
        decryption (root) certificate is trusted in the machine store — the three device-side
        prerequisites for the gateway to filter this device's web traffic.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\NSSWG-Validation.ps1
    EXPECTED RESULTS
        "STEERING ACTIVE" when the client is running and the decryption certificate is trusted;
        otherwise a list of what is missing and the next step.
.NOTES
    Workplace Marketplace — Network Solutions. Read-only.
    Service/process names below are matched generically; confirm the exact client identity for your
    Netskope client build in Netskope's documentation if the match is empty.
#>
[CmdletBinding()] param(
    [string]$CertSubjectMatch = 'Netskope'
)
Write-Host "=== Netskope SWG Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# 1) Client service/process present and running (generic match for the Netskope steering client)
$svc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*Netskope*' -or $_.Name -like '*stagent*' }
$svcRunning = [bool]($svc | Where-Object { $_.Status -eq 'Running' })
Write-Host ("Client service running : {0}" -f ($(if($svcRunning){'YES'}else{'NO'}))) -ForegroundColor ($(if($svcRunning){'Green'}else{'Yellow'}))

$proc = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*stagent*' -or $_.Description -like '*Netskope*' }
$procUp = [bool]$proc
Write-Host ("Client process up      : {0}" -f ($(if($procUp){'YES'}else{'NO'}))) -ForegroundColor ($(if($procUp){'Green'}else{'Yellow'}))

# 2) Decryption (root) certificate trusted in LocalMachine\Root
$cert = Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue | Where-Object { $_.Subject -like "*$CertSubjectMatch*" }
$certOk = [bool]$cert
Write-Host ("Decryption cert trusted: {0}" -f ($(if($certOk){'YES'}else{'NO'}))) -ForegroundColor ($(if($certOk){'Green'}else{'Yellow'}))

# 3) Steering active (client running implies steering; report the indicator we have)
$steering = $svcRunning -and $procUp
Write-Host ("Steering active        : {0}" -f ($(if($steering){'YES'}else{'NO'}))) -ForegroundColor ($(if($steering){'Green'}else{'Yellow'}))

if ($steering -and $certOk) {
    Write-Host "`nResult: STEERING ACTIVE" -ForegroundColor Green; exit 0
} else {
    Write-Host "`nResult: NOT FULLY STEERED" -ForegroundColor Yellow
    if (-not $steering) { Write-Host "  - Client not running/steering: re-deploy 'SWG Client Deployment - Managed Devices - Production' and re-sync (NSSWG-Remediation.ps1)." }
    if (-not $certOk)   { Write-Host "  - Decryption certificate not trusted: re-deploy 'Decryption Certificate - Managed Devices - Production'." }
    exit 1
}
