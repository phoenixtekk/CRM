<#
.SYNOPSIS
    WSUSM-Discovery.ps1 — detect the WSUS server pointer and conflicting GPO/registry update policy.
.DESCRIPTION
    PURPOSE
        Read-only. Inventories the WSUS-era update configuration on this device so you know exactly
        what must be removed before it will scan Microsoft for Windows Update for Business. Reports
        the WSUS server pointers (WUServer / WUStatusServer), UseWUServer, the
        DoNotConnectToWindowsUpdateInternetLocations block, current deferral/target settings, and
        the OS build.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WSUSM-Discovery.ps1
    EXPECTED RESULTS
        OS build, WSUS server pointers, UseWUServer, DoNotConnect... flag, current deferral values,
        and a clear "WSUS authority present — remove before cutover" warning if applicable.
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only; changes nothing.
#>
[CmdletBinding()] param()

$wu  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$au  = "$wu\AU"

Write-Host "`n=== WSUS-to-WUfB Discovery — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS                       : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)

$p   = Get-ItemProperty $wu -ErrorAction SilentlyContinue
$pau = Get-ItemProperty $au -ErrorAction SilentlyContinue

$server     = $p.WUServer
$statusSrv  = $p.WUStatusServer
$useWUSrv   = $pau.UseWUServer
$doNotConn  = $p.DoNotConnectToWindowsUpdateInternetLocations

Write-Host ("WUServer                 : {0}" -f ($(if($server){$server}else{'not set'})))
Write-Host ("WUStatusServer           : {0}" -f ($(if($statusSrv){$statusSrv}else{'not set'})))
Write-Host ("UseWUServer (AU)         : {0}" -f ($(if($null -ne $useWUSrv){$useWUSrv}else{'not set'})))
Write-Host ("DoNotConnectToWU         : {0}" -f ($(if($null -ne $doNotConn){$doNotConn}else{'not set'})))
Write-Host ("Quality deferral         : {0} days" -f ($(if($null -ne $p.DeferQualityUpdatesPeriodInDays){$p.DeferQualityUpdatesPeriodInDays}else{'not set'})))
Write-Host ("Feature deferral         : {0} days" -f ($(if($null -ne $p.DeferFeatureUpdatesPeriodInDays){$p.DeferFeatureUpdatesPeriodInDays}else{'not set'})))
Write-Host ("Target version pinned    : {0}" -f ($(if($p.TargetReleaseVersionInfo){$p.TargetReleaseVersionInfo}else{'not pinned'})))

$conflict = ($useWUSrv -eq 1) -or $server -or $statusSrv
Write-Host ""
if ($conflict) {
    Write-Host "RESULT: WSUS authority PRESENT — this device still scans WSUS." -ForegroundColor Yellow
    Write-Host "        Remove the 'Specify intranet Microsoft update service location' GPO and clear" -ForegroundColor Yellow
    Write-Host "        the residual pointers (run WSUSM-Remediation.ps1) before it will use WUfB." -ForegroundColor Yellow
} else {
    Write-Host "RESULT: No WSUS pointer detected — device is eligible to scan Microsoft/WUfB." -ForegroundColor Green
}
if ($doNotConn -eq 1) {
    Write-Host "WARNING: DoNotConnectToWindowsUpdateInternetLocations is ENABLED — the online scan is" -ForegroundColor Yellow
    Write-Host "         blocked even after WSUS is removed. Remove the 'Do not connect...' GPO." -ForegroundColor Yellow
}

$last = Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 1
if ($last) { Write-Host ("Last hotfix              : {0} on {1}" -f $last.HotFixID, $last.InstalledOn) }
