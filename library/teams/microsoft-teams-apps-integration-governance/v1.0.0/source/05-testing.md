# 5. Testing Guide — Microsoft Teams Apps & Integration Governance

Run after building the baseline and after each configuration stage. Every test is safe; the policy
dry-run (`-WhatIf`) is the gate before any change, and the pilot is the gate before org-wide rollout.

## Test 1 — Posture baseline is complete
**Do:** Run `TEAMSAPPS-Discovery.ps1`; compare its policy and catalog counts against the Teams admin center (`Manage apps`, `Permission policies`, `Setup policies`).
**Expected:** All permission/setup policies are listed; every catalog app is captured with its distribution method (`store` / `organization` / `sideloaded`), and sideloaded/LOB apps are flagged.

## Test 2 — Consent report flags risky permissions
**Do:** Run `TEAMSAPPS-ConsentReport.ps1`; inspect `Consent Review – Teams Apps – Report`.
**Expected:** Each app's delegated and application Graph permissions are listed, and apps holding high-risk scopes (Requirement 2.6) are flagged for review.

## Test 3 — Triage is complete and objective
**Do:** Review `App Vetting Register – Apps – AllStages` against the vetting criteria.
**Expected:** Every in-use/requested app is classified vetted / blocked / needs-review, and the allow and block lists (`App Allow List – Vetted – Prod`, `App Block List – Blocked – Prod`) match the register.

## Test 4 — Org-wide allow/block takes effect
**Do:** In the Teams admin center confirm the apps on the allow list are **Allowed** and those on the block list are **Blocked**; as a test user, search for a blocked app in the Teams client.
**Expected:** Allowed apps are installable; a blocked app does not appear as available to install.

## Test 5 — Policy build makes no changes in dry-run
**Do:** Run `TEAMSAPPS-Configure.ps1 -WhatIf`; afterward re-run `TEAMSAPPS-Discovery.ps1`.
**Expected:** The dry-run prints the policy bodies it *would* create/update; no new or changed policy appears — `-WhatIf` truly changed nothing.

## Test 6 — Pilot assignment lands
**Do:** Run `TEAMSAPPS-Set-ScopeTargeting.ps1 -Commit -PolicyGroup "App Governance Pilot – Users – Pilot"`, then `TEAMSAPPS-Validation.ps1 -PolicyGroup "App Governance Pilot – Users – Pilot"`.
**Expected:** Every pilot user is assigned `App Permission Policy – Pilot – Pilot` and `App Setup Policy – Standard – Prod`; the Global policy is unchanged for everyone else.

## Test 7 — Pilot user experience is correct
**Do:** As a pilot user in the Teams client, try to install a vetted app and a blocked app, and check the pinned app bar.
**Expected:** The vetted app installs; the blocked app is unavailable; the configured apps are pinned in the set order.

## Test 8 — Custom/LOB upload is governed
**Do:** As a non-privileged pilot user, attempt to upload a custom app; confirm the org-wide custom-apps setting and the permission policy's custom-app class.
**Expected:** Upload is allowed only where you permitted it; where disallowed, the user cannot sideload a custom app.

## Test 9 — Rollback works
**Do:** On a single test pilot user, reset assignment back to the Global policies via `TEAMSAPPS-Set-ScopeTargeting.ps1` (reset mode), then re-run `TEAMSAPPS-Validation.ps1`.
**Expected:** The user reverts to the Global (Org-wide default) app policies cleanly — the documented rollback path is proven before org-wide expansion.

## Test 10 — Recurring run refreshes the catalog
**Do:** Re-run the read-only chain (`Discovery → ConsentReport → Validation`) in a later cycle.
**Expected:** New store/sideloaded/LOB apps and new consent grants appear for triage; previously governed apps remain correctly allowed/blocked — the review self-refreshes.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–9 pass; pilot users get only vetted apps, blocked apps are unavailable, pinning is correct, and rollback is proven — with zero genuine loss of a needed app |
| **Org-wide pass** | Tests 4–7 pass against the Global policies after expansion; `Consent Review – Teams Apps – Report` shows no un-triaged high-risk app before the review is declared operational |
