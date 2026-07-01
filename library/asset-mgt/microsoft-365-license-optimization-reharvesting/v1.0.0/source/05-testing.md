# 5. Testing Guide — Microsoft 365 License Optimization & Reharvesting

Run after building the baseline and after each reclamation stage. Every test is safe; the reclamation
dry-run is the gate before any change.

## Test 1 — Inventory is complete and authoritative
**Do:** Run `M365LIC-Discovery.ps1`; compare its subscription totals against `Billing → Licenses` in the admin center.
**Expected:** Each in-scope SKU's purchased and assigned counts match the admin center; group-assigned seats are flagged.

## Test 2 — Usage data is identifiable and within window
**Do:** Run `M365LIC-Report.ps1`; spot-check a few users against `Reports → Usage`.
**Expected:** Users appear by name (not anonymized), with last-activity dates inside the available window — confirming Requirement 2.4.

## Test 3 — Candidates classify correctly
**Do:** Run `M365LIC-Validation.ps1`; inspect `Reclaim Candidates – M365 – Validation`.
**Expected:** Each candidate is correctly labeled unused / duplicate / over-tier, and no shared mailbox, room/resource, or service account is present (exclusions applied).

## Test 4 — Dry-run makes no changes
**Do:** Run `M365LIC-Remediation.ps1 -WhatIf -TargetGroup "Reclaim Targets – Pilot – Stage1"`; afterward re-run `M365LIC-Discovery.ps1`.
**Expected:** The dry-run lists intended actions; assigned counts are unchanged — `-WhatIf` truly changed nothing.

## Test 5 — Pilot reclamation lands
**Do:** Run `M365LIC-Remediation.ps1 -Execute` on the pilot group, then `M365LIC-Validation.ps1`.
**Expected:** Reclaimed pilot users no longer appear as candidates; the targeted licenses are removed or right-sized.

## Test 6 — Savings are quantified
**Do:** Run `M365LIC-Report.ps1` to produce `Savings Report – M365 – Report`.
**Expected:** Assigned count dropped by the pilot amount and the recovered monthly cost is shown.

## Test 7 — No user impact
**Do:** Observe the agreed waiting period after the pilot; check for access tickets from reclaimed users.
**Expected:** No reclaimed user reports a lost capability they actually needed (validates the inactivity window and exclusions).

## Test 8 — Recurring run refreshes candidates
**Do:** Re-run the read-only chain (`Discovery → Report → Validation`) in a later cycle.
**Expected:** Newly inactive/over-tier seats appear; previously reclaimed users do not — the campaign self-refreshes.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–7 pass; pilot savings landed with zero genuine user impact |
| **Broad pass** | Tests 4–6 pass for `Reclaim Targets – Broad – Stage2`; `Savings Report – M365 – Report` reflects the full recovered amount before the entitlement record / true-up is updated |
