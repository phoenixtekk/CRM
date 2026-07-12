# 5. Testing Guide — Entra External Identities (B2B) & Cross-Tenant Access

Run after the pilot scope is configured (Implementation Step 9) and after each expansion. Do portal
checks at `https://entra.microsoft.com`; every script connects to Microsoft Graph
(`graph.microsoft.com`).

## Test 0 — Baseline and connectivity confirmed
Do: Run `ENTB2B-Discovery.ps1`.
Expected: The script connects to Graph and prints the default cross-tenant settings, organizational settings, guest count, guest-scoped CA policies, and access packages/reviews. A connection error means the Graph SDK or consent is missing.

## Test 1 — Default cross-tenant settings are conservative
Do: Entra -> `External Identities -> Cross-tenant access settings -> Default settings`; or run `ENTB2B-Validate.ps1`.
Expected: Inbound/outbound B2B direct connect is blocked by default; MFA/device claims are **not** trusted from unknown tenants by default. Only named organizations relax this.

## Test 2 — Pilot partner is trusted deliberately
Do: `Cross-tenant access settings -> Organizational settings`; open `contoso.com`; or run `ENTB2B-Validate.ps1`.
Expected: The partner organization exists with the intended inbound B2B collaboration; trust settings (MFA/device) are enabled only for this vetted partner, not globally.

## Test 3 — Governed guest onboarding works
Do: The pilot partner contact requests `Partner Access – Project X – Pilot`; an approver in `Partner Approvers – B2B – Pilot` approves.
Expected: A `#EXT#` guest is created with exactly the package's access, an approver decision is recorded, and the grant carries the configured expiry. Ad-hoc guest access outside the package is not the path.

## Test 4 — Guest-scoped Conditional Access enforces MFA
Do: Sign in as the pilot guest to the target app. While the policy is report-only, check `Conditional Access -> Insights and reporting` / sign-in logs; after enforcement, attempt sign-in.
Expected: Report-only shows `Require MFA – Guest Users – Pilot` would apply; once enforced, the guest is required to complete MFA (or satisfies it via trusted partner MFA claims). Internal users and break-glass accounts are unaffected.

## Test 5 — Break-glass excluded
Do: Confirm the two break-glass accounts are excluded from `Require MFA – Guest Users – Pilot` and from broad policies; run `ENTB2B-Validate.ps1`.
Expected: Break-glass accounts are listed as excluded from the guest policy — flagged as intended, not a violation.

## Test 6 — Guest access review recertifies
Do: Open `Access Review – Guests – Pilot`; a reviewer records approve/deny decisions; let auto-apply run.
Expected: Denied guests lose access on apply; decisions are logged. With `Take recommendations`, non-response follows the recommendation rather than removing access blindly (first cycle).

## Test 7 — Guest lifecycle report and stale cleanup preview
Do: Run `ENTB2B-Report.ps1`, then `ENTB2B-CleanupStaleGuests.ps1 -WhatIf`.
Expected: The report lists guests by last sign-in / never-signed-in / inactive and flags stale candidates; the cleanup preview shows exactly which guests *would* be disabled, touching no break-glass or internal account and making no change in `-WhatIf`.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Test 0 confirms connectivity; Tests 1-5 pass; defaults are conservative, the partner is trusted deliberately, governed onboarding works, guest MFA applies, and break-glass is excluded |
| Expand pass | Test 6 (review recertifies) and Test 7 (report + safe cleanup) pass before enforcing the guest policy tenant-wide and adding more partners |
