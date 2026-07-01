<#
.SYNOPSIS
    STIG-Discovery.ps1 — tenant/device DISA STIG readiness for Windows 10/11.
.DESCRIPTION
    PURPOSE
        Reports whether this device is ready to receive a DISA STIG baseline: Windows edition and
        build, Intune/MDM enrollment, BitLocker, Secure Boot, Defender state, and any conflicting
        local Group Policy authority that would fight Intune-delivered hardening. Read-only.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\STIG-Discovery.ps1
    EXPECTED RESULTS
        Edition/build, enrollment state, BitLocker/Secure Boot/Defender posture, and a warning if a
        conflicting local GPO management authority is present.
.NOTES
    Intune Solutions — DISA STIG Win10/11. Read-only.
#>
[CmdletBinding()] param()
Write-Host "`n=== DISA STIG Win10/11 — readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS            : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)
$edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).EditionID
Write-Host ("Edition       : {0}" -f $edition)
if ($edition -match 'Core|Home') { Write-Host "  WARNING: Home/Core edition — many STIG rules require Pro/Enterprise/Education." -ForegroundColor Yellow }

# MDM / Intune enrollment
$enroll = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue |
    Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).EnrollmentState -eq 1 }
Write-Host ("Intune/MDM    : {0}" -f ($(if($enroll){'enrolled'}else{'NOT enrolled'}))) -ForegroundColor ($(if($enroll){'Green'}else{'Yellow'}))

# BitLocker (STIG disk-encryption rules)
try {
    $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue
    Write-Host ("BitLocker     : {0}" -f ($(if($bl){$bl.ProtectionStatus}else{'unknown'})))
} catch { Write-Host "BitLocker     : not available" }

# Secure Boot (STIG boot-integrity rules)
try {
    $sb = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
    Write-Host ("Secure Boot   : {0}" -f ($(if($null -ne $sb){$sb}else{'unknown'})))
} catch { Write-Host "Secure Boot   : not available (legacy BIOS or no access)" }

# Defender
try {
    $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
    Write-Host ("Defender RTP  : {0}" -f ($(if($mp){$mp.RealTimeProtectionEnabled}else{'unknown'})))
} catch { Write-Host "Defender RTP  : not available" }

# Conflicting local GPO authority (hardening fights)
$gpoPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
$wsus = (Get-ItemProperty $gpoPath -ErrorAction SilentlyContinue).UseWUServer
if ($wsus -eq 1) { Write-Host "CONFLICT: local WSUS/GPO authority present — may conflict with Intune-managed STIG controls." -ForegroundColor Yellow }
else { Write-Host "No local WSUS/GPO update-authority conflict detected." -ForegroundColor Green }

Write-Host "`nReadiness scan complete. Reconcile detailed rule state with a STIG Viewer / SCAP scan." -ForegroundColor Cyan
