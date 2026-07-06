# 5. Testing & Validation — macOS Enterprise SSO App Extension

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps
for the user experience.

> **What "pass" means here:** apps and browsers get **silent** Entra SSO. This solution does **not**
> change the macOS login window — do not test for login-window SSO; that is Platform SSO (separate
> product).

## Test 1 — Tenant readiness
**Procedure:** Run `MACSSOEXT-Discovery.ps1`.
**Pass:** An **SSO app extension** (redirect) configuration profile exists with Extension Identifier
`com.microsoft.CompanyPortalMac.ssoextension` and Team Identifier `UBF8T346G9`; Company Portal (macOS)
is added/assigned.
**Fail:** Missing profile, wrong type (Credential/Platform SSO instead of Redirect), or missing
Company Portal → resolve before piloting.

## Test 2 — Profile assignment
**Procedure:** Run `MACSSOEXT-Validation.ps1` (or check **Devices → Configuration → (profile) →
Assignments**).
**Pass:** The profile is assigned to the intended **pilot group** and to no unintended broad group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment (Implement
Step 7 / `MACSSOEXT-Set-ScopeTargeting.ps1`).

## Test 3 — Profile applied on the device
**Procedure:** On the pilot Mac, **System Settings → General → Device Management** (or Intune →
profile → **Device status**).
**Pass:** The **macOS SSO App Extension – Pilot** profile is installed and Intune shows **Succeeded**.
**Fail:** Not installed / error → force a sync (Company Portal → Check settings) and confirm Company
Portal is present (R3).

## Test 4 — Broker primed (first sign-in)
**Procedure:** In Safari, sign in once to `https://outlook.office.com` with the pilot user's Entra
credentials (complete MFA if prompted).
**Pass:** Interactive sign-in succeeds and completes cleanly.
**Fail:** Sign-in loops or errors → verify the Entra URLs in the profile (Step 5) and network access
to the login endpoints (R9).

## Test 5 — Silent SSO in apps and browsers
**Procedure:** Without re-entering credentials, open a **second** Entra-secured target: a native
Microsoft app (e.g. Outlook) and each supported browser (**Safari** first).
**Pass:** Sign-in is **silent** (no password prompt) using the same identity in Safari and in
MSAL/broker-aware apps.
**Fail (Safari/native):** Still prompting → verify Extension Identifier/Team ID and that the app's
bundle ID is not excluded by `AppPrefixAllowList`/`AppBlockList` (Step 6).
**Expected variance (other browsers):** Chrome/Firefox without SSO-extension support fall back to
interactive sign-in — record this as expected, not a failure (R8).

## Test 6 — App/URL scoping behaves
**Procedure:** Confirm scoping keys take effect: an app **outside** the `AppPrefixAllowList` should
not be brokered; an app inside it should be.
**Pass:** Only the intended app bundle IDs get silent SSO; URLs outside the profile's list are not
brokered.
**Fail:** Unexpected apps brokered or intended apps skipped → adjust `AppPrefixAllowList` / URL list
(Step 6) and re-sync.

## Test 7 — Coverage report
**Procedure:** Run `MACSSOEXT-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **profile applied**; counts match the assigned
group.
**Fail:** Devices missing from the report → run `MACSSOEXT-Remediation.ps1` (`-WhatIf` first) to fix
assignment/scoping.

## Test 8 — No login-window change (negative test)
**Procedure:** Log the pilot user out and back in to macOS.
**Pass:** The **macOS login experience is unchanged** — the local account password still logs in; this
solution intentionally does not touch device login.
**Fail:** If login-window behavior changed, a Platform SSO (credential) profile is also present —
confirm this solution deployed **Redirect** only (Step 5).

## Acceptance gate
Proceed to **Expand** only when Tests 1–7 pass on at least one pilot Mac, Test 8 confirms device login
is unchanged, and a real pilot user confirms silent SSO across the intended apps and Safari.
