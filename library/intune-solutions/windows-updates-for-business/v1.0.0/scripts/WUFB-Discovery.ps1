<#
.SYNOPSIS
    WUFB-Discovery.ps1 — Windows Update for Business readiness and current update posture.
.DESCRIPTION
    PURPOSE
        Reports the OS build, the device's current Windows Update deferral/branch settings, the
        last install time, and flags a conflicting WSUS authority (the #1 cause of stalled updates).
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WUFB-Discovery.ps1
    EXPECTED RESULTS
        OS build, deferral values, last update time, and a WSUS-conflict warning if present.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "`n=== Windows Update for Business — posture ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS               : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)
$wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$p = Get-ItemProperty $wu -ErrorAction SilentlyContinue
Write-Host ("Quality deferral : {0} days" -f ($(if($p){$p.DeferQualityUpdatesPeriodInDays}else{'not set'})))
Write-Host ("Feature deferral : {0} days" -f ($(if($p){$p.DeferFeatureUpdatesPeriodInDays}else{'not set'})))
Write-Host ("Target version   : {0}" -f ($(if($p -and $p.TargetReleaseVersionInfo){$p.TargetReleaseVersionInfo}else{'not pinned'})))
# WSUS conflict
$wsus = (Get-ItemProperty "$wu\AU" -ErrorAction SilentlyContinue).UseWUServer
$server = (Get-ItemProperty $wu -ErrorAction SilentlyContinue).WUServer
if ($wsus -eq 1 -or $server) { Write-Host ("CONFLICT: WSUS authority detected (WUServer={0}) — remove for cloud WUfB." -f $server) -ForegroundColor Yellow }
else { Write-Host "No WSUS conflict detected." -ForegroundColor Green }
# last installed update
$last = (Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1)
Write-Host ("Last hotfix      : {0} on {1}" -f $last.HotFixID, $last.InstalledOn)
