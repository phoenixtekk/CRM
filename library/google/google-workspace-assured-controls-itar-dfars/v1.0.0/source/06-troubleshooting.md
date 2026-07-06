# 6. Troubleshooting — Regulated Google Workspace: Assured Controls, ITAR & DFARS

Symptom → likely cause → fix for the common issues configuring controlled-data controls in Google
Workspace. Where a cause is edition-/contract-dependent, the fix is to **verify in your tenant** and
confirm entitlement — never assume a feature that Google's documentation does not confirm.

## Access Management / Access Approvals

**Symptom: "Access Management" / "Access Approvals" not visible under Data → Compliance.**
- Cause: The **Assured Controls / Assured Controls Plus** add-on is not licensed, or you are not a
  **super administrator** (Access Management requires super-admin).
- Fix: Confirm the add-on in **Billing → Subscriptions** (requirement 2.1) and sign in as super-admin.
  Access Management specifically requires **Assured Controls Plus** (or the legacy Assured Controls SKU
  Google documents) — **verify which SKU carries it for your contract.**

**Symptom: Access-Management policy was saved but appears to have no effect for some users.**
- Cause: Policies apply **only to users in OUs that hold the Assured Controls license**; those users'
  OU is unlicensed, or they are in a child OU that inherited **No preference**.
- Fix: Confirm the OU is licensed; check the OU/child-OU policy (use **Override** on the child OU to set
  the required policy). Re-run `GWREG-Validation.ps1`.

**Symptom: The required policy option (e.g. CJIS / IRS 1075) is not listed.**
- Cause: Policy availability is edition-/contract-dependent and evolves.
- Fix: **Verify in your tenant** and confirm entitlement with Google/your reseller — do not substitute a
  different policy without legal/compliance approval (requirement 2.2).

## Data regions / residency

**Symptom: Data region set to United States but reporting still shows out-of-region data.**
- Cause: Residency migration is on **Google's schedule**, not instantaneous; or the setting was applied
  to the wrong OU.
- Fix: Confirm the correct OU is set (Data → Compliance → Data regions), allow Google's migration
  window, and re-check **data-regions advanced reporting**. Escalate to Google support if it does not
  converge.

**Symptom: "Advanced settings" for data regions is unavailable.**
- Cause: Advanced (per-OU cross-region-processing) settings require **Frontline Plus / Enterprise Plus
  or the Data Regions add-on**.
- Fix: Confirm the qualifying edition/add-on (requirement 2.4); **verify in your tenant.**

**Symptom: Users lost functionality after disabling cross-region processing.**
- Cause: Google warns that disabling features that may process data across regions can remove familiar
  functionality.
- Fix: Re-evaluate with the stakeholders which services truly require strict in-region processing;
  narrow the disablement to the required services and re-test (Testing Test 7).

## Client-Side Encryption (CSE)

**Symptom: CSE cannot be enabled / content not encrypting.**
- Cause: The external **key service / IdP** is not connected, or CSE is not enabled for the service/OU.
- Fix: Confirm the key service under **Data → Compliance → Client-side encryption** (stand up per
  Google's CSE docs — deferred to vendor), then enable CSE for the required services/OU.

**Symptom: Some features can't open CSE-protected content.**
- Cause: Expected — CSE content is indecipherable to Google, so features that must read content are
  limited.
- Fix: This is a known tradeoff; scope CSE deliberately and document the impact. Do not treat CSE as the
  only control — it complements residency and access controls.

## Evidence / Access Transparency

**Symptom: No Access Transparency log events appear.**
- Cause: Access Transparency not active for the account, entitlement not present, or simply no
  Google-staff access has occurred yet.
- Fix: Confirm **Access Transparency log events** is selectable in reporting; confirm the add-on
  entitlement (**verify in your tenant**). Absence of events can also mean no access occurred — not a
  failure.

**Symptom: Compliance exports / policy-compliance log events missing.**
- Cause: The bundled evidence feature is not enabled, or entitlement is absent.
- Fix: Enable the feature (it ships with the add-on) and confirm entitlement; route output to the
  evidence destination (requirement 2.8).

## Scripts

**Symptom: Script returns "Set GOOGLE_OAUTH_TOKEN…" and exits.**
- Cause: No OAuth access token in the environment.
- Fix: Set `GOOGLE_OAUTH_TOKEN` to a super-admin token (`gcloud auth print-access-token` or your OAuth
  flow) with the required scopes named in each script's header.

**Symptom: `GWREG-Remediation.ps1` / `GWREG-Set-ScopeTargeting.ps1` "did nothing."**
- Cause: Both **default to `-WhatIf`** — they only preview.
- Fix: Review the preview, get change approval, then re-run with `-Execute` inside the approved window.

**Symptom: API 403 / insufficient permission.**
- Cause: The token lacks the scope/role for the surface being read or set.
- Fix: Grant the least-privilege scope/role named in the script header; reserve super-admin for
  Access-Management operations.

**Symptom: `GWREG-Validation.ps1` reports FAIL but the Admin console looks correct.**
- Cause: The validation compares against the **required posture** you supplied; the console value may
  differ from what legal/compliance approved, or the wrong scope was validated.
- Fix: Confirm the required-posture inputs and the target OU; reconcile with the console value and, if
  the console is wrong, remediate (Implementation Step 7).
