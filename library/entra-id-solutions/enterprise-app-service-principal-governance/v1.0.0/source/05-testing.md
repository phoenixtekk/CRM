# 5. Testing Guide — Enterprise App & Service Principal Governance

Run after the pilot configuration applies (Implementation Step 8) and on the recurring governance
cadence.

## Test 1 — Inventory is complete
Do: Run `APPGOV-Discovery.ps1`.
Expected: Every enterprise app and service principal is listed with its app-role assignments, OAuth2
delegated grants, owners, and credential expiry — a usable baseline.

## Test 2 — Over-permission report is accurate
Do: Run `APPGOV-Report.ps1` and spot-check one flagged app in the portal
(`Enterprise applications ->` app `-> Permissions`).
Expected: The high-privilege application permissions and broad delegated grants the report flags
match what the portal shows.

## Test 3 — User-consent policy is set
Do: Run `APPGOV-Validation.ps1`, or check `Consent and permissions -> User consent settings`.
Expected: User consent is `Allow user consent for apps from verified publishers, for selected
permissions` — not `Allow user consent for all apps`.

## Test 4 — Consent-phishing is blocked
Do: As a pilot user, attempt to consent to a high-risk / unverified test app requesting broad
delegated scopes.
Expected: The self-consent is blocked and the user is offered an admin-consent request instead.

## Test 5 — Admin-consent workflow works
Do: The pilot user submits the request from Test 4.
Expected: A reviewer in `App Governance Consent Reviewers - Tenant - Steady` receives the request and
can approve or deny it.

## Test 6 — Risky grant remediation (preview then apply)
Do: Run `APPGOV-Remediation.ps1` (default `-WhatIf`) against a confirmed over-permissioned app, then
re-run with `-WhatIf:$false`.
Expected: The preview lists exactly the grant it will revoke; after applying, `APPGOV-Validation.ps1`
confirms the grant is gone and the app no longer holds it.

## Test 7 — Credential expiry surfaced
Do: Run `APPGOV-Report.ps1` (expiring-secret section).
Expected: Secrets and certificates expiring soon, and any with no expiry or an excessive lifetime,
are listed with their app and days-to-expiry.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-5 pass; a first over-permissioned app is remediated (Test 6) and validated |
| Expand pass | Tests 1-3, 7 pass tenant-wide; the risky-app shortlist is worked and credential expiry is on a schedule |
