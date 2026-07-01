# 7. Best Practices — BitLocker Drive Encryption

- **Escrow the key before enabling.** Always set "Store recovery information before enabling" — a device that encrypts without an escrowed key is a recovery disaster waiting to happen.
- **Pilot first.** Confirm silent enablement and key escrow on a small group before fleet rollout.
- **Require XTS-AES 256.** The modern, strong method for fixed internal drives.
- **Prefer silent enablement on TPM devices.** No user friction; reserve startup PINs for high-security scopes or non-TPM hardware.
- **Enable client-driven key rotation** for Entra-joined devices so recovery passwords refresh after use.
- **Pair with compliance.** Use a "require encryption" compliance rule so unencrypted devices are flagged (and blocked via Conditional Access).
- **Mind the TPM before clearing it.** Clearing/resetting a TPM can invalidate keys — always have the recovery key first.
- **Encrypt fixed data drives too**, with auto-unlock, for full coverage.
- **Report continuously.** Track encryption coverage and escrow with `BITLK-TenantReport.ps1`.
- **Document recovery procedure.** Make sure the help desk knows how to retrieve a recovery key (`BITLK-Get-RecoveryKey.ps1` / Intune device → Recovery keys).
