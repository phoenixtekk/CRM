<#
.SYNOPSIS
    W11HC-Discovery.ps1 - Windows 11 baseline readiness and current posture.
.DESCRIPTION
    PURPOSE
        Reports the OS build and edition, TPM 2.0 and Secure Boot state, Entra/MDM enrollment,
        Defender status, and flags a conflicting configuration authority (legacy WSUS/GPO) - the
        readiness facts you need before assigning the Windows 11 healthcare endpoint baseline.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\W11HC-Discovery.ps1
    EXPECTED RESULTS
        OS build/edition, TPM and Secure Boot YES/NO, enrollment state, Defender state, and a
        conflict warning if a legacy update authority is present.
.NOTES
    Healthcare Solutions - Windows 11 endpoint baseline. Read-only.
#>
[CmdletBinding()] param()
Write-Host "`n=== Windows 11 Baseline - readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion,OsArchitecture -ErrorAction SilentlyContinue
Write-Host ("OS            : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)
# TPM
try { $tpm = Get-Tpm -ErrorAction Stop; Write-Host ("TPM present   : {0}  (ready: {1})" -f $tpm.TpmPresent, $tpm.TpmReady) }
catch { Write-Host "TPM present   : unknown (Get-Tpm unavailable)" -ForegroundColor Yellow }
# Secure Boot
try { $sb = Confirm-SecureBootUEFI -ErrorAction Stop; Write-Host ("Secure Boot   : {0}" -f $sb) }
catch { Write-Host "Secure Boot   : unknown (legacy BIOS or no access)" -ForegroundColor Yellow }
# Defender
$mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
Write-Host ("Defender RTP  : {0}" -f ($(if($mp){$mp.RealTimeProtectionEnabled}else{'unknown'})))
# Enrollment
$dsreg = (dsregcmd /status) 2>$null
$aad = ($dsreg | Select-String 'AzureAdJoined').ToString().Trim()
Write-Host ("Entra join    : {0}" -f ($(if($aad){$aad}else{'unknown'})))
# Conflicting authority
$wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$server = (Get-ItemProperty $wu -ErrorAction SilentlyContinue).WUServer
$useWsus = (Get-ItemProperty "$wu\AU" -ErrorAction SilentlyContinue).UseWUServer
if ($server -or $useWsus -eq 1) { Write-Host ("CONFLICT: legacy update authority (WUServer={0}) - remove for cloud baseline." -f $server) -ForegroundColor Yellow }
else { Write-Host "No legacy update authority detected." -ForegroundColor Green }
