<#
.SYNOPSIS
    NSCLIENT-Discovery.ps1 — Netskope client deployment readiness for this device.
.DESCRIPTION
    PURPOSE
        Read-only. Reports the OS build, whether the device is enrolled in Intune/MDM, and whether a
        prior or partial Netskope client is already present (service and/or install path). Use before
        a ringed rollout to spot devices that are not ready or that carry a leftover agent.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\NSCLIENT-Discovery.ps1
    EXPECTED RESULTS
        OS build, Intune/MDM enrollment state, and a flag if an existing Netskope client is detected.
.NOTES
    Network Solutions — read-only. Netskope client specifics (exact service/install path) are
    vendor-version-dependent and deferred to the official Netskope documentation; the names probed
    below are common defaults and should be confirmed against your tenant's client build.
#>
[CmdletBinding()] param()

Write-Host "`n=== Netskope client readiness — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# OS
$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS                : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)

# Intune / MDM enrollment (presence of an MDM enrollment with a UPN)
$enrollKey = 'HKLM:\SOFTWARE\Microsoft\Enrollments'
$mdm = $false
if (Test-Path $enrollKey) {
    $mdm = (Get-ChildItem $enrollKey -ErrorAction SilentlyContinue | ForEach-Object {
        (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).UPN }) -ne $null
}
Write-Host ("Intune/MDM enrolled: {0}" -f ($(if($mdm){'YES'}else{'NO (enroll before deploying)'}))) -ForegroundColor ($(if($mdm){'Green'}else{'Yellow'}))

# Existing Netskope client — service probe (common service-name defaults; confirm per Netskope docs)
$svcNames = @('stagentsvc','nsclientservice','netskope')
$svc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $svcNames -contains $_.Name.ToLower() -or $_.DisplayName -match 'Netskope' }

# Existing Netskope client — install path probe (common default; confirm per Netskope docs)
$pathProbe = @("$env:ProgramFiles\Netskope","${env:ProgramFiles(x86)}\Netskope")
$installed = $pathProbe | Where-Object { Test-Path $_ }

if ($svc -or $installed) {
    Write-Host "Existing Netskope client: DETECTED" -ForegroundColor Yellow
    if ($svc)       { $svc | ForEach-Object { Write-Host ("  service : {0} ({1})" -f $_.Name, $_.Status) } }
    if ($installed) { $installed | ForEach-Object { Write-Host ("  path    : {0}" -f $_) } }
    Write-Host "  Confirm whether this is a healthy current client or a leftover to remove before deploy." -ForegroundColor Yellow
} else {
    Write-Host "Existing Netskope client: none detected" -ForegroundColor Green
}

Write-Host "`nNote: client service/path names are vendor-version-dependent — confirm against Netskope docs." -ForegroundColor DarkGray
