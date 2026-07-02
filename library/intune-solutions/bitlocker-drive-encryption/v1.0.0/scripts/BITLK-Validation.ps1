<#
.SYNOPSIS
    BITLK-Validation.ps1 — confirm the OS drive is properly encrypted and has a recovery protector.
.DESCRIPTION
    PURPOSE
        Verifies BitLocker protection is On for the OS drive, the encryption method is XTS-AES 256,
        encryption is complete, and a RecoveryPassword protector exists (for escrow).
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\BITLK-Validation.ps1
    EXPECTED RESULTS
        "BITLOCKER OK" when protected, 100% encrypted, XTS-AES 256, with a recovery protector.
.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "=== BitLocker Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
try { $bv = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop } catch { Write-Host "Cannot read BitLocker volume (run elevated)." -ForegroundColor Red; exit 1 }
$on   = $bv.ProtectionStatus -eq 'On'
$full = $bv.EncryptionPercentage -eq 100
$xts  = $bv.EncryptionMethod -match 'XtsAes256'
$rec  = ($bv.KeyProtector | Where-Object KeyProtectorType -eq 'RecoveryPassword').Count -ge 1
$tpm  = ($bv.KeyProtector | Where-Object KeyProtectorType -eq 'Tpm').Count -ge 1
Write-Host ("Protection On      : {0}" -f $bv.ProtectionStatus) -ForegroundColor ($(if($on){'Green'}else{'Yellow'}))
Write-Host ("Encrypted          : {0}%" -f $bv.EncryptionPercentage) -ForegroundColor ($(if($full){'Green'}else{'Yellow'}))
Write-Host ("Method             : {0}" -f $bv.EncryptionMethod) -ForegroundColor ($(if($xts){'Green'}else{'Yellow'}))
Write-Host ("Recovery protector : {0}" -f ($(if($rec){'present'}else{'MISSING'}))) -ForegroundColor ($(if($rec){'Green'}else{'Red'}))
Write-Host ("TPM protector      : {0}" -f ($(if($tpm){'present'}else{'none'})))
if ($on -and $full -and $rec) { Write-Host "`nResult: BITLOCKER OK" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT FULLY PROTECTED — run BITLK-Remediation.ps1 / check policy" -ForegroundColor Yellow; exit 1 }
