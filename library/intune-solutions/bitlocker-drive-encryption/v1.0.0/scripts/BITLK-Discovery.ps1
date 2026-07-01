<#
.SYNOPSIS
    BITLK-Discovery.ps1 — BitLocker readiness check.
.DESCRIPTION
    PURPOSE
        Reports whether a device can silently encrypt with BitLocker: Windows edition, TPM state,
        UEFI/Secure Boot, and the current OS-drive encryption status.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\BITLK-Discovery.ps1
    EXPECTED RESULTS
        PASS/FAIL per facet and a readiness verdict (silent vs PIN required).
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
function R($n,$p,$d){ [pscustomobject]@{Check=$n;Result=if($p){'PASS'}else{'FAIL'};Detail=$d} }
$res = New-Object System.Collections.Generic.List[object]
$ed = (Get-CimInstance Win32_OperatingSystem).Caption
$res.Add( (R 'Windows edition supports BitLocker' ($ed -notmatch 'Home') $ed) )
try { $tpm = Get-Tpm; $res.Add( (R 'TPM present and ready' ($tpm.TpmPresent -and $tpm.TpmReady) "Present=$($tpm.TpmPresent) Ready=$($tpm.TpmReady)") ) } catch { $res.Add((R 'TPM present and ready' $false 'Get-Tpm failed')) }
try { $res.Add( (R 'Secure Boot' (Confirm-SecureBootUEFI) 'UEFI Secure Boot') ) } catch { $res.Add((R 'Secure Boot' $false 'not UEFI / unknown')) }
try { $bv = Get-BitLockerVolume -MountPoint $env:SystemDrive; $res.Add( (R 'OS drive encryption' ($bv.ProtectionStatus -eq 'On') "Status=$($bv.ProtectionStatus) $($bv.EncryptionPercentage)% $($bv.EncryptionMethod)") ) } catch { $res.Add((R 'OS drive encryption' $false 'unknown')) }
Write-Host "`n=== BitLocker Readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$res | Format-Table -AutoSize
$tpmReady = ($res | Where-Object Check -match 'TPM').Result -eq 'PASS'
Write-Host ("Silent enablement: {0}" -f ($(if($tpmReady){'SUPPORTED (TPM ready)'}else{'NOT silent — startup PIN/USB required'}))) -ForegroundColor ($(if($tpmReady){'Green'}else{'Yellow'}))
