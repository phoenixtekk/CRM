# 7. Best Practices — Identity protection on Macs

- **Read the sign-in logs before you touch a setting.** The Entra sign-in logs (Status = Failure, OS
  = macOS) tell you exactly which users, Macs, apps, and error codes are producing the noise. Record
  them in `MACLOCK Sign-in Failure Findings - Mac-Originated - Sources` — fix the sources you can see,
  not the ones you assume.
- **Fix the cause on the Mac, not just the symptom in the cloud.** Smart Lockout and MFA protect the
  account, but the failed-sign-in storm keeps coming until the **stale keychain / saved credential /
  SecureToken** state on the Mac is cleaned up. Do both.
- **Tune Smart Lockout for real users, not attackers.** Set the threshold high enough to tolerate a
  brief burst of legitimate Mac retries but low enough to blunt a spray; record the values in
  `MACLOCK Lockout & Spray Register - Mac Fleet - Baseline` so the choice is deliberate and repeatable.
- **Know your lockout model before tuning.** Hybrid (AD-synced) accounts interact with an on-premises
  lockout policy; coordinate cloud Smart Lockout changes with the on-prem owner so they don't fight.
- **Enforce MFA so a lucky spray hit is worthless.** A correct-password-only attempt should never be
  enough. Pilot the Conditional Access MFA policy (`MACLOCK CA - Require MFA - Mac Pilot`) in
  report-only first to avoid locking anyone out.
- **Re-sync credentials at every password change.** The classic trigger is a password change where the
  Mac keychain / mail profile / Wi-Fi still holds the old password. Make credential re-sync a standard
  post-password-change step for Mac users.
- **Keep SecureToken aligned.** After any local-account or password reset, confirm the SecureToken and
  local password match the current Entra password so keychain items stay valid and the Mac stops
  re-prompting.
- **Pilot everything that touches sign-in.** Scope MFA and remediation to `MACLOCK Scope - Pilot -
  Macs` first; sign-in changes are easy to break fleet-wide.
- **Least privilege for operators.** Use Security Administrator plus Conditional Access Administrator
  as needed; reserve Global Administrator for genuinely tenant-wide changes. This is Zero-Trust,
  least-privilege by default.
- **Remediate safely.** Run `MACLOCK-Remediation.ps1` in its default `-WhatIf` mode, review the
  proposed changes, then apply — never blind-apply an authentication-impacting change.
- **Re-validate on a cadence.** New password changes create new stale-credential situations; re-run
  `MACLOCK-Discovery.ps1` / `MACLOCK-Validation.ps1` / `MACLOCK-Report.ps1` on a schedule so fresh
  Mac-originated failures are caught before they cause the next lockout.
