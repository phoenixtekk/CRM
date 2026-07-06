# 1. Solution Overview — macOS Identity-Threat & Account-Lockout Hardening

## What this solution is
This solution hardens the **identity posture of the Mac fleet** so macOS clients stop generating
failed sign-ins against Microsoft Entra ID — the failed sign-ins that feed **password-spray**
detections and trigger **account lockouts** that block legitimate users. It does three things in one
program: it **identifies** which lockouts and spray-detection noise actually originate from Macs
(read from Entra sign-in logs), it **hardens** the tenant with Entra **Smart Lockout** and enforced
**MFA** so a burst of Mac-driven failures no longer locks a real user out, and it **remediates** the
Mac-side credential and keychain state that causes the same account to keep failing — all under
Zero-Trust and least-privilege.

The object being hardened here is the **identity surface as the Mac fleet touches it**: Entra sign-in
behavior, the lockout/MFA policy that governs it, and the stale macOS credential state that keeps
re-submitting a wrong or expired password. It is deliberately distinct from certificate or VPN
authentication work (a separate solution) — here the problem is *bad repeated sign-ins from Macs*
and the lockout/spray fallout they cause.

## How a Mac ends up attacking your identity (the mechanics)
A Mac rarely "attacks" on purpose. The failed-sign-in storm almost always comes from **saved or
stale credentials** that macOS keeps re-presenting on the user's behalf:

- **Keychain-stored passwords.** macOS Keychain stores the passwords for Wi-Fi/802.1X, mail
  (Exchange/Outlook profiles), calendar, and app accounts. When the user's **Entra password
  changes** (or expires) but the keychain still holds the **old** password, macOS — and the apps
  that read from it — keep retrying the old password automatically, in the background, on a schedule.
  Each retry is a **failed sign-in** in Entra. Enough of them, fast enough, and Entra's protection
  logic reads it as a **password-spray / brute-force pattern** and/or **locks the account**.
- **Cached / saved sign-ins in mail and browser profiles.** A macOS Mail account, an Outlook profile,
  or a browser-saved credential that still holds the pre-change password behaves the same way:
  silent, repeated, automatic failed sign-ins.
- **Stale device or WPJ (Workplace Join) state.** A Mac whose registered/joined identity state is
  stale can repeatedly present old tokens or trigger repeated interactive-auth failures.
- **SecureToken / local-account divergence.** On macOS, the local account password and its
  **SecureToken** (the FileVault/secure-enclave credential grant) can drift out of sync with the
  cloud (Entra) password after a reset. When they diverge, the user is prompted repeatedly, keychain
  items become invalid, and the resulting re-auth attempts add to the failed-sign-in count. (This is
  the "tangled with SecureToken/keychain" case — the local secure state is a *contributor* to the
  cloud failed-sign-ins, and cleaning it up is part of remediation.)

The result is the same regardless of the exact source: **one or more Macs quietly generate a stream
of failed sign-ins for a user**, and Entra — doing its job — either flags the user in password-spray
/ risk detections or locks the account, so a legitimate person can't sign in.

## The hardening model
1. **Identify the sources.** Read Entra **sign-in logs** (interactive and non-interactive) and filter
   for **failures** whose **operating system is macOS** (and the failure/error codes that map to bad
   password, account locked, and MFA-required). This tells you *which users, which Macs, and which
   apps* are producing the failures — recorded in the findings object.
2. **Harden the tenant.** Turn on / tune Entra **Smart Lockout** (lockout threshold and duration) so
   a burst of bad-password attempts locks *the attacker's view*, not the legitimate user, and enforce
   **MFA** (via Conditional Access) so a correct-password-only attempt is never sufficient. This
   raises the cost of spray and shrinks the lockout blast radius on real users.
3. **Remediate the Mac side.** Clear the stale keychain items, re-sync the saved credential in mail /
   Wi-Fi / app profiles, and resolve any SecureToken / local-account divergence so the Mac stops
   re-submitting the wrong password. This removes the *cause*, not just the symptom.
4. **Validate the reduction.** Re-read the sign-in logs after remediation and confirm the
   Mac-originated failures (and the lockouts/spray detections they drove) have dropped for the pilot
   population — then expand across the fleet.

## What you can control
- **Visibility:** which Mac-originated failures, users, apps, and error codes are happening (from
  Entra sign-in logs / Identity Protection).
- **Smart Lockout:** the lockout threshold and duration in the Entra authentication-methods /
  password-protection settings.
- **MFA enforcement:** a Conditional Access policy that requires MFA for the scoped population.
- **Mac credential state:** keychain hygiene, saved-credential re-sync, and SecureToken / local-account
  alignment on the endpoint (guided; the endpoint fixes are performed on the Mac, and Intune is used
  to scope and deliver the guidance/scripts).
- **Scope and cadence:** pilot group first, then broad; re-validate on a schedule.

## Limitations (be honest with buyers)
- This reduces **Mac-originated** failed sign-ins, lockouts, and spray noise. Failures from other
  platforms, real external attackers, or misconfigured line-of-business apps are out of scope (though
  the same sign-in-log method surfaces them).
- **Smart Lockout is tenant-level** for the cloud-only lockout behavior; some thresholds and the
  on-premises lockout interplay depend on your environment (hybrid vs cloud-only). Confirm your model
  before tuning — flagged in Requirements.
- **Identity Protection risk detections** (the password-spray / risk signals) and risk-based
  Conditional Access depend on your Entra ID licensing (P2 for the full risk-detection surface);
  Smart Lockout and MFA via Conditional Access are broadly available — verify per Requirements.
- macOS credential/keychain and **SecureToken** remediation is performed **on the endpoint**; the
  scripts in this package read Entra sign-in data via Microsoft Graph and scope the work — they do
  **not** silently rewrite a user's keychain or SecureToken remotely. Endpoint steps are guided and
  gated by change control.
- This does not replace a broader identity-protection program; it targets the specific Mac-driven
  lockout/spray problem.

## The standard deployment model
> Assess the Mac-originated failures from the sign-in logs, configure Smart Lockout + MFA and prepare
> the Mac-side remediation, pilot against a Mac scope group, validate the reduction, then expand —
> re-validating on a cadence. Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
