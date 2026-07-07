# Testing & Validation

Run these procedures at the pilot gate (Gate 3) for every app, and again on any change to an
integration. Each test states the **expected pass/fail signal**. These map to the validation gates:
**SSO works · provisioning correct · assignment is group-driven**. Use the included tools where noted;
they are read-only / reporting and safe to run anytime.

---

## Test 1 — SP-initiated SSO

- **Procedure:** As a pilot user in `Assignment Group – <App> – Users`, open the app's own login page
  and choose "Sign in with Google / SSO". Complete the Google sign-in.
- **Pass:** the user lands authenticated in the app, mapped to the correct account (NameID = primary
  email per `Attribute Map – <App> – v1`).
- **Fail:** SAML/OIDC error, "no account found", or wrong identity — check ACS/Entity ID, NameID format,
  and attribute mapping.

## Test 2 — IdP-initiated SSO

- **Procedure:** As the same pilot user, open the Google apps launcher (or
  `https://myaccount.google.com/` → the app tile) and click the app.
- **Pass:** the app opens authenticated without a second login (where the app supports IdP-initiated).
- **Fail:** the app rejects the assertion (some apps are SP-init only — record that in the catalog, not
  a defect) or errors on audience/Entity ID mismatch.

## Test 3 — Group-driven access (assignment lever)

- **Procedure:** Confirm the app is turned **ON only for** `Assignment Group – <App> – Users` (Apps →
  Web and mobile apps → <app> → User access). Then take a pilot user who is **not** in that group and
  attempt SSO.
- **Pass:** in-group user gets access; out-of-group user is **denied** by Google before reaching the app.
- **Fail:** an out-of-group user reaches the app → assignment is not group-scoped (likely ON for an OU or
  All users). Remediate and re-run Tool 4.
- **Automated check:** `python assignment_guardrail_check.py --catalog catalog.csv` — **pass** = no
  findings; **fail** = any app flagged as All-users/OU-assigned, no-group, or over-broad.

## Test 4 — Provisioning: create

- **Procedure (apps with auto-provisioning/SCIM only):** Add a **test user** to
  `Assignment Group – <App> – Users`. Wait for the provisioning cycle.
- **Pass:** the user account is **created/activated in the app** with the mapped attributes; the app
  owner can see the new account.
- **Fail:** no account appears within the expected window → check the provisioning connection, scope
  (must be the assignment group), and attribute mapping.

## Test 5 — Provisioning: deactivate (leaver)

- **Procedure:** Remove the same test user from `Assignment Group – <App> – Users`.
- **Pass:** the app account is **deactivated/suspended** (or deleted, per your policy) on the next cycle;
  the user can no longer sign in.
- **Fail:** the account remains active → orphaned-account risk. Verify deprovisioning is enabled and
  scoped to the group. This is the highest-value offboarding test — do not skip it.

## Test 6 — Attribute & NameID correctness

- **Procedure:** Inspect the assertion/token the app received (app-side SSO logs, or a SAML tracer/JWT
  decode of a test login) and compare to `Attribute Map – <App> – v1`.
- **Pass:** NameID and each mapped attribute (email, name, groups where used) match the standard.
- **Fail:** missing/mis-mapped attribute → fix the mapping in Google and re-test.

## Test 7 — Catalog & governance completeness

- **Procedure:** `python sso_validation_report.py --catalog catalog.csv --out validation.html` and open
  the report.
- **Pass:** every app row has a type, an assignment group, an owner, a provisioning method, and an
  IdP-cert expiry that is **not** within the warning window; no app is missing from the catalog.
- **Fail:** any red row (missing owner/group/method, or cert expiring soon) → remediate before that app
  is considered "done".

## Test 8 — Certificate-rotation dry run

- **Procedure:** From the catalog's cert-expiry column, pick an app and rehearse rotation: rotate/stage a
  new Google IdP signing certificate and update the app's SP config in a **test** window; sign in.
- **Pass:** SSO succeeds on the new certificate; the app trusts the rotated cert.
- **Fail:** SSO breaks on rotation → the app pinned the old cert; schedule a maintenance window and
  update the SP before the live cert expires.

---

## Pilot exit criteria (Gate 3 summary)

An app **passes the pilot** only when Tests 1–7 pass (Test 8 rehearsed at least once for the estate):
SP- and IdP-initiated SSO succeed, access is denied outside the group, provisioning creates **and**
deactivates correctly (where enabled), attributes match the standard, and the validation report and
guardrail check are both clean. Only then is the app turned on for its full audience (Stage 4).
