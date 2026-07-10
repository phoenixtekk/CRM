# 5. Testing Guide — Microsoft 365 Copilot Readiness Assessment & Deployment

Run after the pilot is configured (Implementation Step 7) and before advancing each wave. Scripts referenced: `CPLTREADY-Discovery.ps1`, `CPLTREADY-OversharingScan.ps1`, `CPLTREADY-Validate.ps1`, `CPLTREADY-AssignLicenses.ps1`, `CPLTREADY-Report.ps1`.

## Test 1 — Readiness scorecard exists and blockers ranked

**Do:** Confirm `Copilot Readiness - Tenant - Assess` was captured; re-run `CPLTREADY-Discovery.ps1`.
**Expected:** A baseline scorecard across licensing, identity, data hygiene, and info-protection, with blockers ranked.

## Test 2 — Blockers remediated for the pilot scope

**Do:** Re-run `CPLTREADY-OversharingScan.ps1` and `CPLTREADY-Validate.ps1`.
**Expected:** The ranked broad-access findings for the cohort scope are cleared; identity/MFA and label baseline pass.

## Test 3 — Groups correct

**Do:** `entra.microsoft.com` → `Groups`; or `CPLTREADY-Validate.ps1`.
**Expected:** `Copilot Enablement - Pilot Cohort - Pilot` and `Copilot License - Pilot Cohort - Pilot` exist with the pilot users as members.

## Test 4 — Licenses assigned

**Do:** `admin.microsoft.com` → `Billing` → `Licenses`; or `CPLTREADY-Validate.ps1`.
**Expected:** Each cohort member holds an active Microsoft 365 Copilot license on a qualifying base plan; seat count matches the roster.

## Test 5 — Copilot works for a cohort user

**Do:** As a licensed cohort user on a supported client, open Word or Microsoft 365 Chat and run a starter prompt.
**Expected:** Copilot responds and cites tenant content the user is permitted to see — and does **not** surface content the user should not have (a spot-check that remediation held).

## Test 6 — Audit captures Copilot interactions

**Do:** Purview → `Audit` → search for Copilot activity for a cohort user.
**Expected:** Copilot interactions are recorded and searchable (Requirement 2.8).

## Test 7 — Value dashboard and adoption

**Do:** Open the Microsoft Copilot Dashboard (Viva Insights) and `admin.microsoft.com` → `Reports` → `Usage` → `Microsoft 365 Copilot`; run `CPLTREADY-Report.ps1`.
**Expected:** Activation and active-usage figures for the cohort are visible and tracking toward the Requirement 2.7 thresholds.

## Test 8 — Wave remediate-then-license order (per wave)

**Do:** For a new wave group, confirm the oversharing scan and blocker remediation were completed **before** licenses were assigned.
**Expected:** No wave is licensed ahead of its data-hygiene remediation.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-7 pass: blockers cleared for the cohort, groups correct, licenses assigned, Copilot works and is audited, and adoption/value meets the agreed threshold |
| Wave pass | Tests 2, 4, 7, 8 pass for the wave — blockers remediated before licensing, licenses assigned, and adoption tracking — before advancing to the next wave |
