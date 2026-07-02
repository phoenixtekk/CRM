<#
.SYNOPSIS
    RHELP-Validation.ps1 — confirm the Remote Help app is installed and ready on this device.
.DESCRIPTION
    PURPOSE
        Verifies the Remote Help executable is present and reports its version, so you can confirm
        the Intune app deployment landed before expecting sessions to work.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELP-Validation.ps1
    EXPECTED RESULTS
        "REMOTE HELP READY" when the app is installed.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "=== Remote Help Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$paths = @("$env:ProgramFiles\Remote help\remotehelp.exe", "${env:ProgramFiles(x86)}\Remote help\remotehelp.exe")
$app = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($app) {
    $ver = (Get-Item $app).VersionInfo.ProductVersion
    Write-Host ("Remote Help app : installed (v{0})" -f $ver) -ForegroundColor Green
    Write-Host ("Path            : {0}" -f $app)
    Write-Host "`nResult: REMOTE HELP READY" -ForegroundColor Green; exit 0
} else {
    Write-Host "Remote Help app : NOT installed" -ForegroundColor Yellow
    Write-Host "`nResult: NOT READY — confirm the Intune app assignment / run RHELP-Remediation.ps1" -ForegroundColor Yellow; exit 1
}
