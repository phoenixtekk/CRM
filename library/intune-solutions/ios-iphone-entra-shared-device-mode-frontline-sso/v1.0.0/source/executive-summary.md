# Executive Summary — iOS iPhone Entra ID Shared Device Mode (Frontline SSO)

Frontline teams share iPhones — a pool of shift phones any authorized worker can pick up — but a
shared phone with a single shared account, or a kiosk lockdown, gives **no one a private session**:
the previous worker's cached mail, chats, and tokens survive the next sign-in. This solution
configures **Microsoft Entra ID Shared Device Mode (SDM)** on those shared iPhones so each worker gets
a **real per-user identity session**: **sign in once** as yourself, and **sign out once** to **clear
your identity and app data from every supporting app** for the next person — **global sign-in and
single sign-out** across **Microsoft Teams** and MSAL-based line-of-business apps.

**The Microsoft-native answer for shared *iPhones*.** Apple's own multi-user technology, Shared iPad,
runs **only on iPad hardware** — it cannot help an iPhone fleet. Entra Shared Device Mode is the way to
give pooled iPhones a genuine per-user sign-in/sign-out experience within the Microsoft identity
stack.

**A distinct, honest scope.** This is per-user shared identity — not single-user SSO, not single-app
kiosk lockdown, not Apple Shared iPad. The package is explicit about what SDM isolates: it clears the
**Entra session and the data inside SDM-aware apps** on global sign-out; it does **not** partition the
whole OS, so app scope becomes the security boundary — only SDM-aware apps belong on a shared iPhone.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **No-affinity foundation, done right.** Shared iPhones enroll **without user affinity** via ABM/ADE
  into an **Assigned** device group whose owner is the **Intune Provisioning Client** — the specific
  detail that makes enrollment-time grouping actually populate (a common, silent failure when missed).
- **Shared-mode registration.** Each device is registered into Shared Device Mode through **Microsoft
  Authenticator** by a least-privilege **Cloud Device Administrator** account.
- **Proven hand-off.** The acceptance test is unambiguous: user A signs out, user B signs in **clean**,
  with no trace of A — validated on a real device with two real users.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click Intune/Entra steps, a requirements guide that tells you how to
verify *and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and
testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** pooled iPhones your frontline can share safely — each worker signed in as themselves,
each sign-out a clean hand-off — deployed and proven on a pilot before you scale, without a consulting
engagement.
