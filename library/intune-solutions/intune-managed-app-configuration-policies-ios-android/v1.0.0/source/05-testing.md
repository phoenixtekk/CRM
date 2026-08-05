# 5. Testing & Validation

Validate on a **pilot device** before expanding. Each test states the action and an explicit
**PASS/FAIL** gate. Reuse the object names from Implementation
(`APPCFG - Ariba - iOS - Pilot`, `APPCFG - Ariba - Android - Pilot`, `APPCFG - Ariba - Pilot` group,
`APPCFG - iOS - Enterprise SSO`).

## The end-to-end acceptance test (the one that matters)
**Scenario:** a pilot user picks up an enrolled device, opens SAP Ariba Procurement for the first
time, and lands **pre-configured** on the **Entra ID / Conditional Access** sign-in — with no manual
data entry.

## Test 1 — Policy targets the device/user
- **Action (iOS):** Intune → **Apps → App configuration policies → `APPCFG - Ariba - iOS - Pilot` →
  Device install status** (or **Assignments**), or run `APPCFG-Validate-Assignment.ps1` for the pilot
  device.
- **PASS:** the pilot device appears as targeted/received.
- **FAIL:** device not listed → device not in `APPCFG - Ariba - Pilot`, or not enrolled → fix
  membership/enrollment and re-sync.

## Test 2 — App opens pre-configured (the zero-touch gate)
- **Action:** On the pilot device, install (or reinstall) and **open SAP Ariba Procurement**.
- **PASS:** the app opens with the **site host / realm / environment / role** already populated — the
  user is **not** asked to type a server or realm.
- **FAIL:** the app asks for server/realm → config not applied (see Test 4) or a key name is wrong
  (see Troubleshooting "config not applying / key typos").

## Test 3 — Sign-in routes to Entra ID and Conditional Access applies
- **Action:** Proceed to sign in from the pre-configured app.
- **PASS:** the sign-in screen is your **Entra ID** tenant; Conditional Access controls fire as
  expected (e.g. MFA prompt, or compliant-device requirement); access is granted only when controls
  are satisfied.
- **FAIL — lands on a non-Entra/local login:** the `authMode`/SSO key or Enterprise SSO extension is
  missing/misconfigured (Troubleshooting "not routing to Entra ID").
- **FAIL — blocked unexpectedly:** the Conditional Access policy (owned by the CA solution) is
  mis-scoped — review it there, ideally in **Report-only** first.

## Test 4 — Confirm the delivered values on the device
- **Action (iOS):** on the device, **Settings → General → VPN & Device Management → (your MDM
  profile)** shows the app configuration is present; or in Intune the policy's status shows
  **Succeeded** for the device. Optionally check the app's in-app "About/Diagnostics" screen for the
  active host/realm.
- **PASS:** the values match what you authored (hostname has **no** `https://` or path).
- **FAIL:** a value shows a URL/path in a host field → correct it to a **hostname only** and re-test.

## Test 5 — Android managed configuration (if used)
- **Action:** On an Android Enterprise pilot device, open the target app; in Intune check
  **`APPCFG - Ariba - Android - Pilot` → status**.
- **PASS:** status **Succeeded**; the app reads the schema values.
- **FAIL — keys greyed/absent:** the app did not publish that schema key → only set keys the schema
  exposes (Android keys are schema-authoritative).

## Test 6 — Managed-app (MAM) channel (if used)
- **Action:** On an unenrolled/BYOD device, sign in to the MAM app (e.g. Outlook) with the work
  account; confirm the managed-app configuration applied.
- **PASS:** the app reflects the pushed settings for the work identity.
- **FAIL:** verify the policy is **Managed apps** (not Managed devices) and assigned to a **user**
  group, and the app is App SDK-enabled.

## Test 7 — App Protection coexistence (if both are assigned)
- **Action:** With an App Protection Policy also assigned, open the app.
- **PASS:** the app is both **configured** (host/realm/role) **and** protected (PIN/copy-paste
  controls) — the two policies coexist without conflict.
- **FAIL:** if protection blocks launch, that is an App Protection issue, not app config — review the
  APP conditional-launch settings in the App Protection solution.

## Test 8 — Reporting coverage
- **Action:** Run `APPCFG-Report-AppConfig.ps1`.
- **PASS:** every intended app shows an attached App Configuration Policy; apps that should be
  configured but are not are listed for follow-up.
- **FAIL:** an intended app shows no config → create/assign its policy.

## Exit criteria to expand from pilot to production
- Tests 1–4 PASS on at least two pilot devices (and Test 5/6 for the channels you use).
- The app opens pre-configured with **no** manual server/realm entry (Test 2).
- Sign-in lands on **Entra ID** and Conditional Access behaves as designed (Test 3).
- Reporting (Test 8) shows the intended coverage with no unexpected gaps.
