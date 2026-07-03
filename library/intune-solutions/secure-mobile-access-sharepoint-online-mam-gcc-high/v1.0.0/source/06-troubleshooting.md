# 6. Troubleshooting Guide — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

Field issues, lockout recovery, and **GCC-High-specific gotchas**. Work top-down. All portals are
`*.us`; all scripts connect to **US Gov Graph** (`-Environment USGov`).

## First, rule out the wrong-cloud mistake
**Symptom:** Portal blades look different, a policy "disappears," or PowerShell shows no policies.
**Cause:** You're in the Commercial cloud (`.com`) instead of GCC High.
**Fix:** Confirm you signed in at `login.microsoftonline.us`; use `intune.microsoft.us` /
`entra.microsoft.us`; ensure scripts print **`graph.microsoft.us`**. Re-run `SPMAMG-Discovery.ps1`
and check the endpoint line.

## Lockout / access-blocked recovery (do this before anything drastic)
**Symptom:** Users (or admins) can't sign in to SharePoint on mobile after enforcing CA.
**Fix:**
1. Sign in with a **break-glass** account (excluded from all CA — R4).
2. `entra.microsoft.us` → **Conditional Access** → **`CA-SPO-Mobile-Require-App-Protection`** → set
   to **Report-only** (or **Off**).
3. Run `SPMAMG-Remediation.ps1` (defaults to **`-WhatIf`**) to re-assert break-glass exclusion and
   revert the policy to Report-only; re-run with `-Confirm` to apply.
4. Diagnose with **Sign-in logs** before re-enforcing.

## App PIN never prompts / App Protection Policy not applied
**Symptom:** SharePoint app opens with no PIN, no encryption.
**Checks:**
- User is in **`SG-SPMAMG-Pilot`** and has an **Intune** license (R2).
- The app is the **government-cloud** instance signed in with the GCC High account (personal accounts
  are blocked in GCC High).
- `intune.microsoft.us` → **Apps → Monitor → App protection status** shows the user as targeted.
- Allow time / force an app check-in; App Protection Policy applies on next app launch after sign-in.

## Conditional Access not applying to mobile
**Symptom:** Report-only shows the policy **not applied** for mobile SharePoint sign-ins.
**Checks:**
- **Target resources** includes **Office 365** (or SharePoint Online specifically).
- **Conditions → Device platforms** includes **iOS** and **Android**.
- **Conditions → Client apps** includes **Mobile apps and desktop clients** (and **Browser** if you
  intend to gate the browser).
- **Grant** has **Require app protection policy** checked.
- The user is in **Include** and not accidentally in **Exclude**.

## "Require approved client app" behaving oddly / deprecation
**Symptom:** A legacy policy using **Require approved client app** blocks or is flagged as deprecated.
**Cause:** That grant is **retiring early March 2026**.
**Fix:** Rebuild on **Require app protection policy** (this solution's default).
[Migrate approved client app](https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app)

## Data still leaks to unmanaged apps
**Symptom:** Copy/paste or "Save As" out of SharePoint content succeeds.
**Checks (App Protection Policy → Data protection):**
- **Send org data to other apps:** **Policy managed apps**.
- **Save copies of org data:** **Block** (allow only OneDrive/SharePoint if intended).
- **Restrict cut/copy/paste:** **Policy managed apps with paste in**.
- Confirm the target app is **not** itself a policy-managed app you inadvertently allowed.

## Broker app / registration failures
**Symptom:** The app can't satisfy the CA control; sign-in loops.
**Checks:** **Microsoft Authenticator** (iOS) or **Intune Company Portal** (Android) is installed and
signed in with the GCC High account (R7). Reinstall the broker app and retry.
[App-based Conditional Access with Intune](https://learn.microsoft.com/en-us/intune/device-security/conditional-access-integration/app-based-policies)

## GCC-High-specific gotchas
- **SharePoint mobile feature missing entirely.** If a rollup, activity notification, stock-images
  tab, or Internet-service web part doesn't work, that is **expected** — Graph-dependent SharePoint
  features are **disabled in GCC High**. Don't chase it as a policy bug; redesign the site per
  **GCC High Parity Notes**.
  ([SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint))
- **User tries to add a personal account.** Blocked by design in GCC High — communicate this; it is
  not a fault.
  ([Outlook for iOS/Android in the government cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud))
- **Site or sign-in unreachable from mobile.** Confirm the **GCC High endpoint ranges** (`*.us`
  SharePoint/Entra/Intune) are allowed through your MDM/proxy/firewall — Commercial ranges won't
  cover them.
  ([GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints))
- **A capability from a Commercial article is absent.** GCC High lags Commercial. **Verify for GCC
  High** in `intune.microsoft.us` / `entra.microsoft.us`; if the option isn't there, it isn't
  released yet.

## When to escalate
- Break-glass access itself fails → this is a tenant-level identity incident; engage Microsoft
  support for GCC High immediately.
- App Protection status shows the user targeted but the app never enforces after repeated check-ins →
  collect app logs (Settings → Help → Share Diagnostic Logs) and open a support case.

---
**Golden rule:** if enforcement misbehaves, **fall back to Report-only, sign in with break-glass,
diagnose with sign-in logs, then re-enforce.** Never leave a broken enforcing policy live.
