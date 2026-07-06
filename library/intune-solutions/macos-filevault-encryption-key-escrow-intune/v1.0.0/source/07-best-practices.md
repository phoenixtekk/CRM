# 7. Best Practices — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

- **Confirm SecureToken before you enable FileVault.** FileVault cannot turn on for a user without
  a SecureToken. On ADE Macs, make sure the **bootstrap token** is escrowed so Intune can grant it.
- **Enroll corporate Macs via Automated Device Enrollment.** ADE generates and escrows the
  bootstrap token automatically, which is the cleanest path to SecureToken and FileVault.
- **Escrow the personal recovery key — always.** Set **Hide recovery key from user = Yes** so the
  key is escrowed to Intune, not left on screen. A Mac that encrypts without an escrowed key is a
  recovery disaster waiting to happen.
- **Use the personal recovery key model, not institutional.** A per-device key escrowed to Intune
  limits blast radius; an institutional key is one key that unlocks the entire fleet — avoid it.
- **Turn on key rotation.** Enable **personal recovery key rotation** so a key that has been used
  (e.g. during a recovery) is retired and a fresh one is escrowed. Rotate on a schedule too.
- **Pilot first.** Confirm enablement, escrow, and the recovery-key unlock on a small group before
  fleet rollout — enablement touches user login and the first encryption takes time.
- **Plan enablement timing.** FileVault enables at login on the personal-key model; set a small
  deferral/bypass count so it is enforced after a few sign-ins rather than deferred forever.
- **Pair with compliance.** Use a macOS "require encryption / FileVault" compliance rule so
  unencrypted Macs are flagged (and blocked via Conditional Access).
- **Document the recovery procedure.** Make sure the help desk knows how to retrieve a personal
  recovery key (Intune device → **Recovery keys**, or `MACFV-Report.ps1`) and how the login-screen
  recovery flow works.
- **Report continuously.** Track encryption + escrow coverage with `MACFV-Report.ps1`; investigate
  any Mac that is encrypted but not escrowed.
- **Mind SecureToken on account changes.** Deleting or migrating the SecureToken-enabled account can
  strand FileVault — have a recovery key in hand before making account changes.
