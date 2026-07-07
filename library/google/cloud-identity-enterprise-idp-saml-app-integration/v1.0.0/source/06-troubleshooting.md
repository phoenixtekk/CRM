# Troubleshooting

Common failure modes when running the SAML app-integration factory, and how to resolve them. Google
Admin labels occasionally move — where a path differs, **verify the equivalent in your tenant**.
Third-party app (SP) console specifics are deferred to each vendor's documentation.

---

## SSO fails: "invalid assertion" / audience or Entity ID mismatch

- **Symptom:** the app rejects Google's SAML assertion; error mentions audience, Entity ID, or issuer.
- **Cause:** the SP **Entity ID / audience** entered in Google doesn't exactly match what the app
  expects, or Google's **Entity ID** wasn't entered on the app side.
- **Resolve:** in **Apps → Web and mobile apps → <app> → Service provider details**, confirm the app's
  ACS URL and Entity ID are exact (no trailing slash, correct scheme). Re-copy Google's SSO URL / Entity
  ID / metadata into the app. Re-run **Test 1**.

## SSO fails: wrong user / "no account found" (NameID mismatch)

- **Symptom:** SSO completes at Google but the app can't match the user, or logs in the wrong account.
- **Cause:** the **NameID** doesn't match the identifier the app keys on (often the app wants email but
  received something else), or the NameID **format** is wrong.
- **Resolve:** set **Name ID = Basic Information > Primary email**, format **EMAIL**, per
  `Attribute Map – <App> – v1` — unless the app documents a different NameID. Confirm the user's app
  account uses the same email. Re-run **Test 6**, then **Test 1**.

## Signature validation error after a certificate change

- **Symptom:** every user of an app suddenly fails SSO; app logs a signature/cert error.
- **Cause:** Google's **IdP signing certificate rotated or expired** and the app pinned the old cert.
- **Resolve:** download Google's current certificate/metadata (**<app> → Google Identity Provider
  details**) and update the app's SP config. Then **prevent recurrence:** record the new expiry in
  `App Catalog – Federated SaaS – v1` and schedule rotation before expiry (Test 8). Prefer metadata-URL
  exchange where the app supports it so rotation propagates automatically.

## An out-of-group user can still reach the app

- **Symptom:** someone not in `Assignment Group – <App> – Users` gets into the app.
- **Cause:** the app is turned **ON for an OU or All users**, not scoped to the group — or the app also
  allows **local login** that bypasses SSO.
- **Resolve:** in **<app> → User access**, set ON **only** for `Assignment Group – <App> – Users`; turn
  off inheritance from broader OUs. If the app allows non-SSO login, enforce SSO-only in the app (vendor
  docs). Re-run **Test 3** and the guardrail check
  (`python assignment_guardrail_check.py --catalog catalog.csv`).

## Guardrail check reports "assigned to ALL USERS" / "assigned to an OU"

- **Symptom:** `assignment_guardrail_check.py` exits non-zero with an assignment violation.
- **Cause:** the catalog's `assignment_target` is `all-users` or `ou`, violating the group-only standard.
- **Resolve:** create/confirm `Assignment Group – <App> – Users`, re-scope the app's **User access** to
  that group in Google Admin, update the catalog row (`assignment_target=group`, set
  `assignment_group`), and re-run the check until clean.

## Auto-provisioning doesn't create accounts

- **Symptom:** a user added to the assignment group never gets an account in the app.
- **Cause:** auto-provisioning/SCIM not enabled, **not scoped to the assignment group**, an expired SCIM
  token, or the app doesn't support Google auto-provisioning on your tier.
- **Resolve:** in **<app> → Auto-provisioning**, confirm it's enabled and **scoped to
  `Assignment Group – <App> – Users`**; re-authorize the connection / regenerate the app's SCIM token if
  needed; verify attribute mapping. If the app has no provisioning connector, record method **manual**
  in the catalog and handle onboarding manually. Re-run **Test 4**.

## Removed user still has an active account (deprovisioning gap)

- **Symptom:** a user removed from the assignment group can still sign in to the app.
- **Cause:** **deprovisioning disabled**, provisioning scoped to the wrong group, or the app is
  **manual/JIT** with no automated leaver action.
- **Resolve:** enable deactivation/suspension in the provisioning connection scoped to the assignment
  group; for manual/JIT apps, ensure the app is on the **leaver offboarding checklist**. Re-run
  **Test 5** — this is the highest-value offboarding control; do not leave it failing.

## Group changes don't take effect

- **Symptom:** membership changes in your source of truth aren't reflected in access or provisioning.
- **Cause:** the group is **hand-edited** rather than governed by the sync/IGA, or the sync (GCDS/SCIM)
  hasn't run.
- **Resolve:** confirm the group is populated by the source of truth (Requirement 2), not manually;
  verify the sync cycle completed. Re-run `sso_readiness_assessment.py --check-groups` to confirm the
  group exists and is populated.

## Tool error: "Directory API unavailable" / import error

- **Symptom:** a tool prints that the Admin SDK client or credentials are unavailable.
- **Cause:** `google-api-python-client` / `google-auth` not installed, ADC not set, or the **Admin SDK
  API** not enabled / insufficient scope.
- **Resolve:** `pip install google-api-python-client google-auth`; run
  `gcloud auth application-default login`; enable the **Admin SDK API** on the automation project; ensure
  the account has the read-only Directory scopes (or a service account with **domain-wide delegation**
  limited to those read-only scopes). The tools run their file/inventory logic without the API, and only
  the `--check-groups` / `--check-membership` steps need it.

## IdP-initiated SSO fails but SP-initiated works

- **Symptom:** the app works from its own login page but errors from the Google apps launcher.
- **Cause:** the app is **SP-initiated only** (a legitimate app design), or the IdP-init relay/audience
  is misconfigured.
- **Resolve:** confirm whether the app supports IdP-initiated SSO (vendor docs). If it doesn't, record
  "SP-init only" in the catalog — this is a documented characteristic, not a defect (**Test 2**).
