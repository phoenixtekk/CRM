# 5. Testing Guide — Enterprise App & Service Principal Governance (Government / GCC High)

Run after the pilot configuration applies (Implementation Step 8) and on the recurring governance
cadence. All scripts connect to US Gov Microsoft Graph (`-Environment USGov`); all portal checks are
at `https://entra.microsoft.us`.

## Test 0 — You are in the sovereign cloud
Do: Run `Connect-MgGraph -Environment USGov -NoWelcome`, then `(Get-MgContext).Environment`.
Expected: Returns `USGov` (not `Global`). If `Global`, you are on the Commercial cloud — reconnect
before trusting any other test.

## Test 1 — Inventory is complete
Do: Run `APPGOVG-Discovery.ps1`.
Expected: Every enterprise app and service principal is listed with its app-role assignments, OAuth2
delegated grants, owners, and credential expiry — a usable baseline.

## Test 2 — Over-permission report is accurate
Do: Run `APPGOVG-Report.ps1` and spot-check one flagged app in the portal
(`entra.microsoft.us -> Enterprise apps ->` app `-> Permissions`).
Expected: The high-privilege application permissions and broad delegated grants the report flags
match what the portal shows.

## Test 3 — User-consent policy is set
Do: Run `APPGOVG-Validation.ps1`, or check `Consent and permissions -> User consent settings`.
Expected: User consent is `Allow user consent for apps from verified publishers, for selected
permissions` — not `Allow user consent for all apps`.

## Test 4 — Consent-phishing is blocked
Do: As a pilot user, attempt to consent to a high-risk / unverified test app requesting broad
delegated scopes.
Expected: The self-consent is blocked and the user is offered an admin-consent request instead.

## Test 5 — Admin-consent workflow works
Do: The pilot user submits the request from Test 4.
Expected: A reviewer in `App Governance Consent Reviewers - Tenant - Steady` receives the request and
can approve or deny it (approval of Microsoft Graph application permissions requires a role that can
grant tenant-wide consent).

## Test 6 — Risky grant remediation (preview then apply)
Do: Run `APPGOVG-Remediation.ps1 -AppId your-app-id` (default `-WhatIf`) against a confirmed
over-permissioned app, then re-run with `-WhatIf:$false`.
Expected: The preview lists exactly the grant it will revoke; after applying,
`APPGOVG-Validation.ps1 -CheckAppId your-app-id` confirms the grant is gone and the app no longer
holds it.

## Test 7 — Credential expiry surfaced
Do: Run `APPGOVG-Report.ps1` (expiring-secret section).
Expected: Secrets and certificates expiring soon, and any with no expiry or an excessive lifetime,
are listed with their app and days-to-expiry.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Test 0 confirms USGov; Tests 1-5 pass; a first over-permissioned app is remediated (Test 6) and validated |
| Expand pass | Tests 1-3, 7 pass tenant-wide; the risky-app shortlist is worked and credential expiry is on a schedule |
