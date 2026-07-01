# 5. Testing Guide — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

Run these after the pilot scope is built (Implementation Step 7) and again each governance cadence
cycle. Use `MSLICGOV-Discovery.ps1` and `MSLICGOV-Validation.ps1` for tenant reads and
`MSLICGOV-Report.ps1` for the position/cost report.

## Test 1 — Entitlements captured (owned side)
Do: Open the `License Position Register – EA+CSP – Steady-State`.
Expected: Every pilot product has an owned quantity, a channel (EA or CSP), and a
renewal/anniversary date sourced from the agreement (no blank or assumed terms).

## Test 2 — Deployment read (assigned side)
Do: Run `MSLICGOV-Discovery.ps1` and compare its assigned/consumed counts to Billing then Licenses
in `https://admin.microsoft.com`.
Expected: Script counts match the admin center for the pilot products; assigned column in the
register is populated from these.

## Test 3 — Position reconciles
Do: For each pilot product confirm position equals owned minus assigned in the register.
Expected: Position is correct and signed (positive is headroom, negative is exposure); no product is
left unreconciled.

## Test 4 — True-up exposure forecast (EA)
Do: Run `MSLICGOV-Validation.ps1` with the EA baselines supplied; compare to the
`True-Up Worksheet – Enterprise Agreement – Annual`.
Expected: Per EA SKU, assigned-minus-baseline delta matches the worksheet; the forecast true-up
quantity is stated. CSP products correctly show no true-up.

## Test 5 — Utilization and reharvest candidates
Do: Run `MSLICGOV-Report.ps1`; review assigned-but-unused seats.
Expected: A list of reharvest candidates with a utilization signal; at least one is validated as
genuinely unused before remediation.

## Test 6 — Safe remediation preview
Do: Run `MSLICGOV-Remediation.ps1` (default `-WhatIf`) against the pilot scope.
Expected: It prints the planned changes only and makes no change; re-running with `-Confirm` applies
exactly those changes on the pilot scope.

## Test 7 — Scope targeting
Do: Run `MSLICGOV-Set-ScopeTargeting.ps1` and confirm in `https://entra.microsoft.com` then Groups.
Expected: `License Governance – Pilot Scope – Stage1` and `License Governance – Estate Scope –
Stage2` exist with the intended membership.

## Test 8 — Position/cost report
Do: Run `MSLICGOV-Report.ps1` scoped to the pilot.
Expected: A per-product report (owned, assigned, position, utilization) that agrees with the
register and the worksheet.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 4 and Test 8 pass for the pilot scope; at least one reharvest/right-size action validated (Tests 5 to 6) without disruption |
| Estate pass | Tests 1 to 4, 7, 8 pass estate-wide before the next renewal/true-up window |
