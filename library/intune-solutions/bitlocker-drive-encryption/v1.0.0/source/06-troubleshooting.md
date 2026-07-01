# 6. Troubleshooting Guide — BitLocker Drive Encryption

Use **`BITLK-Validation.ps1`** / **`BITLK-Discovery.ps1`** for device state and
**`BITLK-Remediation.ps1`** for safe fixes.

## A. Encryption doesn't start
| Symptom | Cause | Remediation |
|---|---|---|
| Policy "Succeeded" but not encrypting | No TPM, or TPM not ready | Run `BITLK-Discovery.ps1`; enable TPM in UEFI; for non-TPM, configure a startup PIN |
| "Encryptable volume" error | Secure Boot/UEFI or pre-provisioning state | Ensure UEFI + Secure Boot; reboot; re-sync policy |
| Standard user can't enable | "Allow standard users to enable during Autopilot" not set | Enable that base setting |

## B. Recovery key not escrowed (critical)
| Symptom | Cause | Remediation |
|---|---|---|
| Encrypted but no key in Entra | "Store recovery info before enabling" off, or device not Entra joined | Set escrow-before-enable; confirm `AzureAdJoined : YES`; run `BITLK-Remediation.ps1` to back up the key |
| Key missing for older devices | Encrypted before policy | `BITLK-Remediation.ps1` backs up the existing recovery password to Entra |

## C. Wrong encryption method
- Device shows AES-128 / different method → it was encrypted before the policy. Decrypt and re-encrypt with XTS-AES 256, or accept per risk; new devices follow the policy.

## D. TPM problems
- `Get-Tpm` shows not ready → enable/clear TPM in UEFI (coordinate: clearing TPM affects existing keys — have the recovery key first).
- TPM "reduced functionality" → clear via `tpm.msc` (with recovery key in hand).

## E. Diagnostics quick reference
```powershell
manage-bde -status                       # encryption %, method, protection state
(Get-BitLockerVolume -MountPoint C:).KeyProtector   # protectors (TPM, RecoveryPassword)
Get-Tpm                                  # TPM readiness
manage-bde -protectors -get C:           # view recovery password ID
```
Back up an existing key to Entra: `BackupToAAD-BitLockerKeyProtector -MountPoint C: -KeyProtectorId <id>`.

## F. When to escalate
If a device has a TPM ready, is Entra joined, the policy shows Succeeded, and encryption still
won't start or the key won't escrow after remediation, collect `manage-bde -status` output and the
BitLocker event logs and open a Microsoft support case.
