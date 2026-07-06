# 6. Troubleshooting Guide — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

Use **`MACFV-Validation.ps1`** / **`MACFV-Discovery.ps1`** for state and
**`MACFV-Remediation.ps1`** for safe fixes (it defaults to `-WhatIf`).

## A. FileVault won't enable
| Symptom | Cause | Remediation |
|---|---|---|
| Policy "Succeeded" but FileVault stays Off | No SecureToken-enabled user on the Mac | Check `sysadminctl -secureTokenStatus <username>`; grant SecureToken from an existing SecureToken admin (`sysadminctl -secureTokenOn`), or use the bootstrap token on ADE Macs |
| ADE Mac has no SecureToken user | Bootstrap token not escrowed | Confirm `profiles status -type bootstraptoken`; install with `sudo profiles install -type bootstraptoken`; re-enroll via ADE if needed |
| User never prompted to enable | Deferral bypass count exhausted or not reached | Confirm the FileVault policy's bypass/deferral count; have the user log out/in |

## B. Recovery key not escrowed (critical)
| Symptom | Cause | Remediation |
|---|---|---|
| FileVault On but no key in Intune → Recovery keys | Escrow/hide-key not configured, or the Mac encrypted before the policy | Confirm the policy sets **Hide recovery key from user = Yes**; run `MACFV-Remediation.ps1` to re-apply the policy (device sync) so Intune escrows a fresh key |
| Key missing for pre-existing FileVault Macs | Encrypted before Intune managed it | Re-apply the FileVault policy so a new personal recovery key is generated and escrowed (rotation); verify with `MACFV-Report.ps1` |

## C. SecureToken / bootstrap-token problems
- `sysadminctl -secureTokenStatus <user>` shows **DISABLED** → grant from a SecureToken admin
  (`sysadminctl -secureTokenOn <user> -password - -adminUser <admin> -adminPassword -`).
- `profiles status -type bootstraptoken` shows not escrowed → run `sudo profiles install -type bootstraptoken`
  from a SecureToken-enabled account (ADE Macs generate this at setup).
- Mobile/Entra account can't be FileVault-enabled → it lacks SecureToken; grant it via the bootstrap
  token or from an existing SecureToken admin.

## D. Recovery key won't unlock / rotation issues
- Escrowed key does not unlock at the login screen → confirm you retrieved the **current** key
  (rotation may have replaced it); re-check Intune → **Recovery keys** or `MACFV-Report.ps1`.
- Key not rotating after use → confirm **Personal recovery key rotation** is enabled in the policy;
  force a device sync so the policy re-evaluates.

## E. Diagnostics quick reference (run on the Mac)
```bash
fdesetup status                              # FileVault On/Off, deferral state
fdesetup list                                # users enabled for FileVault
sysadminctl -secureTokenStatus <username>    # SecureToken ENABLED/DISABLED for a user
profiles status -type bootstraptoken         # bootstrap token escrowed to server?
diskutil apfs list                           # volume encryption state
```
From the management side, `MACFV-Report.ps1` retrieves the escrowed personal recovery key and
reports fleet encryption + escrow coverage.

## F. When to escalate
If a Mac is Apple Silicon/T2, is enrolled, has a SecureToken-enabled user and an escrowed bootstrap
token, the FileVault policy shows **Succeeded**, and FileVault still won't enable or the key won't
escrow after remediation, collect `fdesetup status`, `sysadminctl -secureTokenStatus`, and
`profiles status -type bootstraptoken` output and open a Microsoft support case.
