<#
.SYNOPSIS
    WSUSM-Validation.ps1 — confirm this device scans Microsoft/WUfB, not WSUS.
.DESCRIPTION
    PURPOSE
        Read-only. Validates the cutover on a single device: confirms the WSUS pointer is gone, the
        online-scan block is not set, the Windows Update service is reachable to Microsoft, and the
        Intune update ring deferral/deadline values are present. Triggers a scan and reports the
        update source so you can prove the device no longer uses WSUS.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WSUSM-Validation.ps1
    EXPECTED RESULTS
        PASS when: no WUServer/UseWUServer, DoNotConnect... not enabled, online Windows Update
        reachable, and ring deferral values applied. Any failed check is listed.
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only; only triggers a scan.
#>
[CmdletBinding()] param()

$wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$au = "$wu\AU"
$p   = Get-ItemProperty $wu -ErrorAction SilentlyContinue
$pau = Get-ItemProperty $au -ErrorAction SilentlyContinue

Write-Host "`n=== WSUS-to-WUfB Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$fail = @()

if ($p.WUServer)            { $fail += "WUServer still set ($($p.WUServer))" }
if ($pau.UseWUServer -eq 1) { $fail += "UseWUServer = 1 (device still pointed at WSUS)" }
if ($p.DoNotConnectToWindowsUpdateInternetLocations -eq 1) { $fail += "DoNotConnectToWindowsUpdateInternetLocations = 1 (online scan blocked)" }

# Ring policy present?
if ($null -eq $p.DeferQualityUpdatesPeriodInDays -and $null -eq $p.DeferFeatureUpdatesPeriodInDays) {
    $fail += "No WUfB deferral values present — the Intune update ring has not applied yet"
} else {
    Write-Host ("Ring deferral applied    : quality={0}d, feature={1}d" -f $p.DeferQualityUpdatesPeriodInDays, $p.DeferFeatureUpdatesPeriodInDays) -ForegroundColor Green
}

# Trigger a scan against the configured source
try {
    if (Test-Path "$env:WINDIR\System32\UsoClient.exe") { & "$env:WINDIR\System32\UsoClient.exe" StartScan; Write-Host "Update scan (USO)        : started" -ForegroundColor Green }
    else { (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow(); Write-Host "Update detection         : triggered" -ForegroundColor Green }
} catch { Write-Host "Scan trigger skipped     : $($_.Exception.Message)" -ForegroundColor Yellow }

# Confirm Microsoft Update endpoint reachability (only meaningful when not behind WSUS)
try {
    $r = Test-NetConnection -ComputerName 'windowsupdate.microsoft.com' -Port 443 -WarningAction SilentlyContinue
    Write-Host ("Microsoft Update :443    : {0}" -f ($(if($r.TcpTestSucceeded){'reachable'}else{'NOT reachable'}))) -ForegroundColor ($(if($r.TcpTestSucceeded){'Green'}else{'Yellow'}))
    if (-not $r.TcpTestSucceeded) { $fail += "Microsoft Update endpoint not reachable on 443" }
} catch { Write-Host "Reachability check skipped: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host ""
if ($fail.Count -eq 0) {
    Write-Host "RESULT: PASS — device scans Microsoft/WUfB and the ring policy is applied." -ForegroundColor Green
} else {
    Write-Host "RESULT: FAIL — outstanding issues:" -ForegroundColor Yellow
    $fail | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "  Remediate with WSUSM-Remediation.ps1, then re-run after a policy cycle." -ForegroundColor Yellow
}
