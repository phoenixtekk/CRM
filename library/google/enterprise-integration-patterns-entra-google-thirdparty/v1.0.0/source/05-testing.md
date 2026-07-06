# 5. Testing Guide — Pattern-Conformance Gates

Run after piloting the target patterns (Implementation Step N) and on the recurring governance
cadence. Each test checks whether the estate conforms to the catalog — not just that a single app
works, but that it works **the standard way**.

## Test 1 — Estate inventory is complete
**Do:** Run `GWINTEG-Discovery.ps1`.
**Expected:** Every Entra-side SSO/federation app, provisioning (SCIM) job, service principal,
app-role assignment, delegated grant, and credential is listed — a usable baseline. Google-side SSO
profiles and third-party apps are recorded in the capability matrix.

## Test 2 — Every integration maps to a pattern (no snowflakes)
**Do:** Run `GWINTEG-Report.ps1` (coverage/exception section).
**Expected:** Each integration is classified against a catalog pattern (P1–P7); the exception list
contains only **deliberate, documented** exceptions — unclassified snowflakes are flagged.

## Test 3 — Entra↔Google federation conforms (P1)
**Do:** Run `GWINTEG-Validation.ps1`; a pilot-OU user signs in to Google.
**Expected:** SSO is via Entra (SAML), the NameID matches the Google domain, and the user
authenticates. A break-glass Google super-admin can still sign in outside SSO.

## Test 4 — Provisioning has one source of truth (P2/P3)
**Do:** Run `GWINTEG-Validation.ps1` (provisioning section).
**Expected:** Each provisioned object type has exactly **one** master — SCIM push (P2) **or** GCDS
pull (P3), never both; de-provisioning is in place (a disabled/removed source user is de-provisioned,
not orphaned).

## Test 5 — Third-party app SSO is federated (P5)
**Do:** For a pilot third-party app, a pilot user signs in via the IdP.
**Expected:** The user authenticates through the chosen IdP over SAML/OIDC with **no local app
password**, and app roles are driven by group/claim — not per-user local admin.

## Test 6 — Third-party app provisioning + de-provisioning (P6)
**Do:** Add and then remove a test user from the source group for a pilot app.
**Expected:** The user is provisioned into the app on add and **de-provisioned on remove**, via the
app's verified mechanism (SCIM or supported connector). No manual account creation.

## Test 7 — API/data access uses scoped, short-lived credentials (P7)
**Do:** Run `GWINTEG-Report.ps1` (credential/scope section) for the pilot data path.
**Expected:** Service-to-service and data access use OAuth client-credentials / workload identity
federation with **least-privilege scopes**; no long-lived shared secrets or over-broad
(`*.ReadWrite.All`) scopes on the integration.

## Test 8 — Coexistence cutover is defined (P4)
**Do:** Review the coexistence cutover plan against the live state.
**Expected:** Each workload has a named IdP owner and a documented cutover order; identity stays
consistent across M365 and Google during overlap.

## Test 9 — Remediation preview is accurate
**Do:** Run `GWINTEG-Remediation.ps1` (default `-WhatIf`) against a flagged snowflake, then re-run with
`-WhatIf:$false`.
**Expected:** The preview lists exactly the change it will make; after applying, `GWINTEG-Validation.ps1`
confirms the integration now conforms.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–5 pass on the pilot app set; one third-party app conforms (Tests 5–6); the pilot data path conforms (Test 7) |
| Expand pass | Tests 1–4, 7–8 pass across the estate; the exception list is reviewed and every item is deliberate; discovery + report run on a schedule |
