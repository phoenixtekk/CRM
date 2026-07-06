# 6. Troubleshooting — macOS Enterprise SSO App Extension

Work top-down: confirm the **profile is applied**, then the **broker is primed**, then **scoping**.
Most "still prompting" cases are a missing Company Portal, a mis-typed identifier, or an app outside
the allow-list. Each symptom below gives the **likely cause** and the **fix**.

> **Before you start:** verify this is the app/browser extension problem you think it is. If the
> *macOS login window* changed or the account password is involved, you are looking at **Platform
> SSO** (separate solution), not this app extension.

## Symptom: The SSO profile never appears on the Mac
**Likely cause:** Device not synced, not assigned, or restriction blocking macOS.
**Fix:**
1. Confirm the device is in the **pilot group** and the profile is **assigned** (`MACSSOEXT-Validation.ps1`).
2. Force sync: **Company Portal → (device) → Check settings**.
3. Check **Devices → Configuration → (profile) → Device status** for an error.
4. Confirm **Company Portal** is installed (R3) — the extension identifier is invalid without it.

## Symptom: Profile shows "Error" / "Conflict" in Device status
**Likely cause:** A second SSO extension profile conflicts (e.g. a Platform SSO/Credential profile
targeting the same device), or duplicate SSO app-extension profiles.
**Fix:**
1. Run `MACSSOEXT-Discovery.ps1` to list SSO extension profiles.
2. Ensure only **one** SSO **app** extension (Redirect) profile targets the device.
3. A Platform SSO (Credential) profile can coexist but must be a **separate, intentional** policy — if
   unintended, unassign it.

## Symptom: Apps/browsers still prompt for a password (no silent SSO)
**Likely cause:** Broker not primed, wrong identifiers, or app not in the allow-list.
**Fix:**
1. Complete **one interactive sign-in** in Safari to prime the broker (Implementation Step 9).
2. Verify **Extension Identifier** `com.microsoft.CompanyPortalMac.ssoextension` and **Team Identifier**
   `UBF8T346G9` exactly (Step 5).
3. Confirm the app's **bundle ID** is covered by `AppPrefixAllowList` and not in `AppBlockList` (Step 6).
4. Confirm the app authenticates against a URL in the profile's **URL list**.

## Symptom: Silent SSO works in Safari but not in Chrome/Firefox
**Likely cause:** Expected — those browsers may not support the macOS SSO extension.
**Fix:**
1. Set `browser_sso_interaction_enabled = 1` (Step 6) to enable interactive broker sign-in where
   supported.
2. Where a browser has no extension support, document the fallback and steer web SSO to **Safari**.
3. This is a browser limitation, not a profile error — set expectations with users (R8).

## Symptom: One specific app is not brokered
**Likely cause:** Bundle ID excluded by scoping, uses an embedded webview, or a non-MSAL auth stack.
**Fix:**
1. Confirm the app's bundle ID matches your `AppPrefixAllowList` prefix.
2. Add the exact bundle ID if it falls outside the prefix.
3. If the app uses a legacy embedded webview (not the broker/MSAL or Safari), silent SSO may not be
   possible — note it as a known limitation.

## Symptom: Sign-in loops or fails after the profile applies
**Likely cause:** Missing Entra URL, blocked login endpoint, or TLS inspection.
**Fix:**
1. Confirm the correct **Entra URLs** for your cloud are present (Step 5) — commercial vs US Gov vs
   21Vianet differ.
2. From the device network, reach `https://login.microsoftonline.com` (or sovereign equivalent) (R9).
3. **Exempt Microsoft login endpoints from TLS inspection** — inspection breaks token exchange.

## Symptom: Works for some users, not others
**Likely cause:** Group membership, licensing, or Company Portal not installed on those devices.
**Fix:**
1. Confirm affected users/devices are in the assigned group (`MACSSOEXT-Report.ps1`).
2. Confirm each user has a licensed Entra identity (R10) and each device has Company Portal (R3).
3. Have the affected user complete the one-time interactive sign-in to prime the broker.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or missing Company Portal.
**Fix:**
1. Run `MACSSOEXT-Report.ps1` to list which devices lack the applied profile.
2. Run `MACSSOEXT-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R1) and Company Portal (R3).

## Escalation checklist
Before opening a Microsoft support case, collect: the `MACSSOEXT-Discovery.ps1` output, the profile's
Device status export, the exact Extension/Team identifiers and URL list, the affected app bundle IDs,
macOS version, and whether Safari brokers silently (isolates the extension from browser-specific
issues).
