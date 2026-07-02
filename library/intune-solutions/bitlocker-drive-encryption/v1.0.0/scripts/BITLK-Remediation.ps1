<#
.SYNOPSIS
    BITLK-Remediation.ps1 — safe BitLocker remediation: ensure a recovery protector, escrow it, resume protection.
.DESCRIPTION
    PURPOSE
        Adds a RecoveryPassword protector if missing, backs it up to Microsoft Entra ID, resumes
        protection if suspended, and (optionally) starts encryption on an unencrypted OS drive.
        It does NOT decrypt or remove protectors.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\BITLK-Remediation.ps1 [-StartEncryption]
    EXPECTED RESULTS
        A recovery protector exists and is escrowed to Entra; protection resumed. Re-run BITLK-Validation.ps1.
.NOTES
    White-label — Intune Solutions.
#>
[CmdletBinding(SupportsShouldProcess=$true)] param([switch]$StartEncryption)
$mp = $env:SystemDrive
Write-Host "=== BitLocker Remediation — $($env:COMPUTERNAME) ($mp) ===" -ForegroundColor Cyan
$bv = Get-BitLockerVolume -MountPoint $mp
if ($bv.VolumeStatus -eq 'FullyDecrypted' -and $StartEncryption) {
    if ($PSCmdlet.ShouldProcess($mp,'Enable BitLocker (TpmProtector + RecoveryPassword, XTS-AES256)')) {
        Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -TpmProtector -SkipHardwareTest -ErrorAction SilentlyContinue
        Add-BitLockerKeyProtector -MountPoint $mp -RecoveryPasswordProtector -ErrorAction SilentlyContinue
        Write-Host "  Encryption started." -ForegroundColor Green
        $bv = Get-BitLockerVolume -MountPoint $mp
    }
}
# ensure recovery protector
$rp = $bv.KeyProtector | Where-Object KeyProtectorType -eq 'RecoveryPassword'
if (-not $rp) {
    Add-BitLockerKeyProtector -MountPoint $mp -RecoveryPasswordProtector | Out-Null
    $bv = Get-BitLockerVolume -MountPoint $mp
    $rp = $bv.KeyProtector | Where-Object KeyProtectorType -eq 'RecoveryPassword'
    Write-Host "  Added recovery protector." -ForegroundColor Green
}
# escrow to Entra
foreach ($k in $rp) {
    try { BackupToAAD-BitLockerKeyProtector -MountPoint $mp -KeyProtectorId $k.KeyProtectorId -ErrorAction Stop; Write-Host "  Recovery key escrowed to Entra ID." -ForegroundColor Green }
    catch { Write-Host "  Escrow failed (device must be Entra joined): $($_.Exception.Message)" -ForegroundColor Yellow }
}
# resume if suspended
if ($bv.ProtectionStatus -eq 'Off' -and $bv.VolumeStatus -ne 'FullyDecrypted') { Resume-BitLocker -MountPoint $mp; Write-Host "  Protection resumed." -ForegroundColor Green }
Write-Host "`nRe-run BITLK-Validation.ps1 to confirm." -ForegroundColor Green
