# 5. Testing Guide — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

Run after the pilot is configured (Implementation Step 8) and again after expanding to production.
Artifacts referenced verbatim: `Netskope SSO - Corp - Prod`, `Netskope SCIM Provisioning - Corp - Prod`,
`Netskope Identity - Pilot - Stage`, `Netskope Identity - Corp - Prod`, `Identity Steering Policy - Corp - Prod`.

## Test 1 — SAML SSO configured
**Do:** Entra → Enterprise applications → `Netskope SSO - Corp - Prod` → Single sign-on; run `NSSSO-Validation.ps1`.
**Expected:** SSO mode is SAML with the identifier, reply URL, claims, and signing certificate set.

## Test 2 — Pilot user can sign in via SSO
**Do:** As a member of `Netskope Identity - Pilot - Stage`, sign in to Netskope through Entra ID.
**Expected:** Sign-in succeeds and is recorded in the app's Entra sign-in logs; the Entra identity is recognized in Netskope.

## Test 3 — SCIM provisioning enabled and healthy
**Do:** Entra → `Netskope SSO - Corp - Prod` → Provisioning (status On); review Provisioning logs; run `NSSSO-Validation.ps1`.
**Expected:** Provisioning is On (`Netskope SCIM Provisioning - Corp - Prod`), the last cycle succeeded, and scope is "assigned users and groups."

## Test 4 — Pilot users/groups present in Netskope
**Do:** Confirm members of `Netskope Identity - Pilot - Stage` and the group appear in Netskope; run `NSSSO-Report.ps1`.
**Expected:** The pilot users and group are provisioned in Netskope, mirroring Entra ID.

## Test 5 — Identity-based policy targets by group
**Do:** Confirm `Identity Steering Policy - Corp - Prod` matches by the provisioned group and a pilot user's traffic is governed by it (Netskope policy/logs, deferred).
**Expected:** The control applies to the group's members by identity, not by IP/subnet.

## Test 6 — De-provisioning (leaver) reflected
**Do:** Remove a test user from `Netskope Identity - Pilot - Stage`; after a provisioning cycle, run `NSSSO-Report.ps1`.
**Expected:** The user is de-provisioned/disabled in Netskope, so policy no longer applies to them.

## Test 7 — Coverage report
**Do:** Run `NSSSO-Report.ps1`.
**Expected:** A clear view of the enterprise app's SSO mode, provisioning status, and assigned/target groups.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass on `Netskope Identity - Pilot - Stage` and a leaver de-provisions (Test 6) |
| **Production pass** | Tests 1, 3, 4, 7 pass for `Netskope Identity - Corp - Prod` after expansion |
