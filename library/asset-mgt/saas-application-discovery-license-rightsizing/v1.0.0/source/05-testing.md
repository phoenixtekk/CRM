# 5. Testing Guide — SaaS Application Discovery & License Right-Sizing

Run after the pilot register is built and reclaim candidates are flagged (Implementation Steps 5 to 7),
and after each recurring review cycle.

## Test 1 — Inventory is complete
Do: Compare `App Inventory – SaaS – Discovered` (from `SAASLIC-Discovery.ps1`) against the Enterprise
applications list at `entra.microsoft.com` then Identity then Applications then Enterprise applications.
Expected: Every SSO-integrated SaaS app appears; known non-SSO apps were added manually.

## Test 2 — Usage telemetry is reading correctly
Do: For a sample app, compare the script's sign-in count to Usage and insights for the same window.
Expected: The counts agree (within the report's reporting lag).

## Test 3 — Owner and spend map is filled
Do: Open `Owner Map – SaaS – Mapped`.
Expected: Every in-scope app has a named owner and an annual cost; the map sorts by spend.

## Test 4 — Right-sizing register identifies real candidates
Do: Run `SAASLIC-Report.ps1` for the pilot scope.
Expected: Each app shows entitled seats, active users, wasted seats, and an estimated saving; the
register's reclaim/consolidate/downgrade choices follow the data.

## Test 5 — Remediation is safe by default
Do: Run `SAASLIC-Remediation.ps1` with no switches.
Expected: It runs in `-WhatIf` mode, lists reclaim candidates, writes the candidate file, and changes
nothing.

## Test 6 — No wrongful reclaim on the pilot
Do: After the pilot reclaim actions, check for access requests or complaints from reclaimed users.
Expected: No genuinely-active user lost a needed seat.

## Test 7 — Savings realized
Do: Re-run `SAASLIC-Report.ps1` after the pilot reclaim and compare to the baseline.
Expected: Entitled-seat counts and estimated spend for the pilot apps dropped as planned.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 6 pass; no wrongful reclaim on the pilot scope |
| Expand pass | Tests 1, 4, 7 pass for the expanded scope; savings confirmed against baseline |
