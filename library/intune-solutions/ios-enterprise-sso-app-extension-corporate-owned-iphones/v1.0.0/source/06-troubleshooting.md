# 6. Troubleshooting — iOS/iPadOS Enterprise SSO App Extension

Work top-down: confirm the **profile is applied**, then **Microsoft Authenticator is present and the
broker is primed**, then **scoping**. Most "still prompting" cases are a missing Authenticator app, a
mis-typed identifier, or an app outside the coverage keys. Each symptom below gives the **likely
cause** and the **fix**.

> **Before you start:** verify this is the app/browser extension problem you think it is. If the
> device is *shared between people* and users see each other's sessions, that is a shared-device
> identity problem (**Shared Device Mode**, separate solution), not this per-user app extension.

## Symptom: The SSO profile never appears on the device
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in the **pilot group** and the profile is **assigned**
   (`IOSSSOEXT-Validation.ps1`).
2. Force sync from Company Portal (**Check status**) or **Settings → General → VPN & Device
   Management**.
3. Check **Devices → Configuration → (profile) → Device status** for an error.
4. Confirm **Microsoft Authenticator** is installed (R3) — the extension identifier is invalid
   without it.

## Symptom: Profile shows "Error" / "Conflict" in Device status
**Likely cause:** A second SSO app-extension profile conflicts, or a duplicate profile targets the
same device.
**Fix:**
1. Run `IOSSSOEXT-Discovery.ps1` to list SSO extension profiles.
2. Ensure only **one** SSO app-extension (redirect / Microsoft Entra ID) profile targets the device.
3. Remove or re-scope the duplicate.

## Symptom: Apps/browsers still prompt for a password (no silent SSO)
**Likely cause:** Authenticator missing, broker not primed, wrong identifiers, or app not covered.
**Fix:**
1. Confirm **Microsoft Authenticator** is installed, then open it once to activate the extension.
2. Complete **one interactive sign-in** in Safari to prime the broker (Implementation Step 9).
3. Verify **Extension Identifier** `com.microsoft.azureauthenticator.ssoextension` and **Team
   Identifier** `UBF8T346G9` exactly (Step 5).
4. Confirm the app is covered by `Enable_SSO_On_All_ManagedApps = 1` or by your `AppPrefixAllowList`
   (Step 6), and that the app authenticates against a URL in the profile's list.

## Symptom: Silent SSO works in Safari but not in Chrome/Edge/Firefox
**Likely cause:** Expected — those browsers may not support the iOS SSO extension.
**Fix:**
1. Set `browser_sso_interaction_enabled = 1` (Step 6) to enable interactive broker sign-in where
   supported.
2. Where a browser has no extension support, document the fallback and steer web SSO to **Safari**.
3. This is a browser limitation, not a profile error — set expectations with users (R7).

## Symptom: One specific app is not brokered
**Likely cause:** App not managed (so `Enable_SSO_On_All_ManagedApps` doesn't cover it), bundle ID
outside the allow-list, or the app uses a non-MSAL/embedded webview auth stack.
**Fix:**
1. If you rely on `Enable_SSO_On_All_ManagedApps`, confirm the app is actually deployed as a
   **managed** app.
2. Otherwise add the exact bundle ID (or its prefix) to `AppPrefixAllowList` (Step 6).
3. If the app uses a legacy embedded webview (not the broker/MSAL or Safari), silent SSO may not be
   possible — note it as a known limitation.

## Symptom: Repeated MFA prompts even after priming
**Likely cause:** Broker session not established, or Conditional Access re-challenging.
**Fix:**
1. Confirm Authenticator registered the device (open Authenticator; the work account is present).
2. Set `disable_explicit_app_prompt = 1` (Step 6).
3. Review Conditional Access sign-in frequency / device-compliance policies gating the app; confirm
   the device reports **compliant** (R9) so CA is satisfied by the device rather than re-prompting.

## Symptom: Sign-in loops or fails after the profile applies
**Likely cause:** Missing Entra URL, blocked login endpoint, or TLS inspection.
**Fix:**
1. Confirm the correct **Entra URLs** for your cloud are present (Step 5) — commercial vs US Gov vs
   21Vianet differ.
2. From the device network, reach `https://login.microsoftonline.com` (or sovereign equivalent) (R8).
3. **Exempt Microsoft login endpoints from TLS inspection** — inspection breaks token exchange.

## Symptom: Works for some users, not others
**Likely cause:** Group membership, licensing, or Authenticator not installed on those devices.
**Fix:**
1. Confirm affected users/devices are in the assigned group (`IOSSSOEXT-Report.ps1`).
2. Confirm each user has a licensed Entra identity (R10) and each device has Microsoft Authenticator
   (R3).
3. Have the affected user open Authenticator and complete the one-time interactive sign-in to prime
   the broker.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or missing Authenticator.
**Fix:**
1. Run `IOSSSOEXT-Report.ps1` to list which devices lack the applied profile.
2. Run `IOSSSOEXT-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R1) and Authenticator (R3).

## Escalation checklist
Before opening a Microsoft support case, collect: the `IOSSSOEXT-Discovery.ps1` output, the profile's
Device status export, the exact Extension/Team identifiers and URL list, the affected app bundle IDs,
iOS/iPadOS version, whether Authenticator is installed and registered, and whether Safari brokers
silently (isolates the extension from browser-specific issues).
