# 5. Testing Guide — SSO & Provisioning Conformance Gates

Run after the pilot (Implementation Step 4) and on the recurring cadence during and after expansion.
Each test checks whether the **identity foundation** works the standard way — not just that one user
can sign in, but that federation, provisioning, and de-provisioning are all correct and that
break-glass is intact.

## Test 1 — Entra-side identity state is inventoried
**Do:** Run `GWSSO-Discovery.ps1`.
**Expected:** The "Google Cloud / G Suite Connector by Microsoft" app is listed with its SSO mode
(SAML), whether a SCIM provisioning job exists, the count of assigned users/groups, and the tenant's
verified custom domains — a usable baseline. No changes made.

## Test 2 — Custom domain matches on both sides
**Do:** Confirm the in-scope custom domain is verified in **Entra** and in **Google** (Admin console →
**Account → Domains → Manage domains**); confirm no in-scope user has a `*.onmicrosoft.com` UPN.
**Expected:** The domain is verified in both clouds; every in-scope user's UPN is on the custom domain.
A `*.onmicrosoft.com` UPN is a fail — Google rejects it for provisioning and SSO.

## Test 3 — SSO federation works (pilot sign-in)
**Do:** A **pilot-OU** user signs in via Entra SSO (Entra **Test this application**, or the Google
sign-on URL). Run `GWSSO-Validation.ps1` for the Entra-side signal.
**Expected:** The user is redirected to Entra, authenticates, and lands in Google with **no second
password**. Entra SSO mode is **SAML**; the **NameID = user.mail** and matches the Google domain.

## Test 4 — Provisioning creates users AND groups
**Do:** Add a test user to a source group in scope; run `GWSSO-Validation.ps1` (provisioning section);
confirm in the Google Admin console.
**Expected:** The user **and the group + membership** appear in Google via the chosen mechanism (SCIM
push or GCDS pull). `primaryEmail` matches the SSO NameID. Attributes populate per the mapping.

## Test 5 — One source of truth (no dual mastering)
**Do:** Run `GWSSO-Validation.ps1` and confirm the design.
**Expected:** Each object type has exactly **one** master — SCIM push (Entra) **or** GCDS pull (AD),
never both for the same users. No object is written by two mechanisms. JIT is not being used as the
lifecycle source.

## Test 6 — De-provisioning removes access (leaver path)
**Do:** Remove the test user from the source group (or disable them in Entra/AD); wait for the next
cycle/run.
**Expected:** The user is **de-provisioned (suspended)** in Google — access is removed, not orphaned.
(SCIM removal from scope suspends rather than hard-deletes; GCDS suspends on the next run.) This is the
test that proves lifecycle actually closes.

## Test 7 — Break-glass path is intact
**Do:** Sign in as the cloud-only **Google super-admin** whose SSO profile is set to **none**; confirm
the two **Entra** cloud-only emergency admins are excluded from broad CA policies.
**Expected:** The Google super-admin signs in **outside** SSO; an SSO or provisioning change cannot
lock admins out.

## Test 8 — Scope is limited during pilot
**Do:** Confirm the **Google SSO profile** is assigned only to the pilot OU/group (everyone else and
break-glass = **none**) and provisioning scope (SCIM assignment/filter or GCDS OU rules) covers only
the pilot.
**Expected:** Only the pilot federates and provisions until the gate passes — the rest of the org is
untouched.

## Test 9 — Coverage across the estate (expansion)
**Do:** Run `GWSSO-Report.ps1`.
**Expected:** A per-user/coverage view — federated vs not, provisioned vs not — with the exception list
containing only **deliberate, documented** exceptions (e.g. service accounts intentionally not
federated). No silent gaps.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–8 pass on the pilot OU/group — sign-in works (Test 3), provisioning creates users+groups (Test 4), one source of truth (Test 5), de-provisioning removes access (Test 6), break-glass intact (Test 7), scope limited to pilot (Test 8) |
| Expand pass | Tests 1–7 and 9 pass across each batch; the exception list is reviewed and every item is deliberate; discovery / validation / report run on a schedule |
