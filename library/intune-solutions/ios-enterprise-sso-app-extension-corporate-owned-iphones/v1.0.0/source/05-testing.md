# 5. Testing & Validation — iOS/iPadOS Enterprise SSO App Extension

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps
for the user experience.

> **What "pass" means here:** apps and browsers on the corporate iPhone get **silent** Entra SSO after
> one priming sign-in. This solution does **not** enroll the device or change shared-device identity.

## Test 1 — Tenant readiness
**Procedure:** Run `IOSSSOEXT-Discovery.ps1`.
**Pass:** An **SSO app extension** configuration profile exists with Extension Identifier
`com.microsoft.azureauthenticator.ssoextension` (redirect / Microsoft Entra ID type); Microsoft
Authenticator (iOS) is added/assigned.
**Fail:** Missing profile, wrong identifier, or missing Authenticator → resolve before piloting.

## Test 2 — Profile assignment
**Procedure:** Run `IOSSSOEXT-Validation.ps1` (or check **Devices → Configuration → (profile) →
Assignments**).
**Pass:** The profile is assigned to the intended **pilot group** and to no unintended broad group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment (Implement
Step 7 / `IOSSSOEXT-Set-ScopeTargeting.ps1`).

## Test 3 — Profile applied on the device
**Procedure:** On the pilot device, **Settings → General → VPN & Device Management → (MDM profile)**
(or Intune → profile → **Device status**).
**Pass:** The **iOS SSO App Extension – Pilot** profile is installed and Intune shows **Succeeded**;
Microsoft Authenticator is present.
**Fail:** Not installed / error → force a sync and confirm Microsoft Authenticator is installed (R3).

## Test 4 — Broker primed (first sign-in)
**Procedure:** Open Microsoft Authenticator once, then in Safari sign in to
`https://outlook.office.com` with the pilot user's Entra credentials (complete MFA if prompted).
**Pass:** Interactive sign-in succeeds and completes cleanly.
**Fail:** Sign-in loops or errors → verify the Entra URLs in the profile (Step 5) and network access
to the login endpoints (R8).

## Test 5 — Silent SSO in apps and browsers
**Procedure:** Without re-entering credentials, open a **second** Entra-secured target: a native
Microsoft app (e.g. the **Outlook** app) and each supported browser (**Safari** first).
**Pass:** Sign-in is **silent** (no password prompt, no repeat MFA) using the same identity in Safari
and in MSAL/broker-aware apps.
**Fail (Safari/native):** Still prompting → verify Extension Identifier/Team ID and that the app is
covered by `Enable_SSO_On_All_ManagedApps` or the `AppPrefixAllowList` (Step 6).
**Expected variance (other browsers):** Chrome/Firefox without SSO-extension support fall back to
interactive sign-in — record this as expected, not a failure (R7).

## Test 6 — Managed-app coverage behaves
**Procedure:** Confirm the coverage lever: with `Enable_SSO_On_All_ManagedApps = 1`, open two
different Intune-managed Microsoft apps and confirm both are silent; if you used `AppPrefixAllowList`
instead, confirm an app outside the prefix is not brokered while one inside it is.
**Pass:** The intended apps get silent SSO; apps you did not scope do not.
**Fail:** Unexpected apps brokered or intended apps skipped → adjust the scoping keys (Step 6) and
re-sync.

## Test 7 — Coverage report
**Procedure:** Run `IOSSSOEXT-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **profile applied**; counts match the assigned
group.
**Fail:** Devices missing from the report → run `IOSSSOEXT-Remediation.ps1` (`-WhatIf` first) to fix
assignment/scoping.

## Test 8 — No enrollment/identity change (negative test)
**Procedure:** Confirm the device is still enrolled and assigned to the same single user; sign out of
one app.
**Pass:** The device enrollment and its single-user assignment are **unchanged**; this solution only
adds the SSO extension profile and does not alter enrollment or introduce a shared session.
**Fail:** If device ownership/affinity changed, an unintended enrollment or shared-device policy is
also present — confirm this solution deployed the **SSO extension profile** only.

## Acceptance gate
Proceed to **Expand** only when Tests 1–7 pass on at least one pilot device, Test 8 confirms
enrollment/identity is unchanged, and a real pilot user confirms silent SSO across the intended apps
and Safari.
