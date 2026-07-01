# 5. Testing Guide — Secure Mobile Access to SharePoint Online under MAM

Run after the pilot policies apply (Implementation Steps 6–8) and again before each expansion wave.

## Test 1 — App Protection Policies assigned
**Do:** Intune → **Apps → App protection policies →** open `SPO Mobile – App Protection – iOS` and
`SPO Mobile – App Protection – Android` → **Assignments**; or run `SPMAM-Discovery.ps1`.
**Expected:** Both policies target the SharePoint app and Edge and are assigned to
`SPO Mobile – Users – Pilot`.

## Test 2 — App Protection applied on the device
**Do:** On a pilot device, open the SharePoint app / Edge with the work account; you are prompted for
the App PIN. Run `SPMAM-Validation.ps1` for that user.
**Expected:** The App PIN is enforced and `SPMAM-Validation.ps1` reports the App Protection Policy is
applied for the SharePoint/Edge apps.

## Test 3 — Conditional Access grant effective
**Do:** Entra → **Monitoring → Sign-in logs →** open the pilot user's mobile SharePoint sign-in →
**Conditional Access** (or **Report-only**) tab.
**Expected:** `CA – SPO Mobile – Require APP` applies to the Office 365 / SharePoint Online sign-in
and the app-protection grant is **satisfied** (not failed).

## Test 4 — Supported path loads the intranet
**Do:** On a pilot device, open the SharePoint Online intranet in the **SharePoint mobile app**, then
in **Microsoft Edge** signed in with the work account.
**Expected:** The intranet loads reliably in both.

## Test 5 — Unsupported path is blocked (by design)
**Do:** Open the same intranet URL in **unmanaged Safari / unmanaged Chrome** (CA enforced).
**Expected:** Access is **blocked** with an approved-app / app-protection message — confirming CA is
steering users to the supported path, not that the site is down.

## Test 6 — Routing confirmed (no Tunnel for SharePoint Online)
**Do:** From a pilot device **off** the corporate network, open the intranet on the supported path.
**Expected:** It loads over the public internet — confirming SharePoint Online is cloud-reachable
and no Microsoft Tunnel is required.

## Test 7 — Coverage report
**Do:** Run `SPMAM-Report.ps1`.
**Expected:** A clear report of which target users have the App Protection Policy and are in scope of
the CA policy, with any gaps flagged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; Test 5 shows the expected block; Test 6 confirms cloud reachability |
| **Expand pass** | Tests 1–4 and 7 pass for each production wave before adding the next |
