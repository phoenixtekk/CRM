# 5. Testing Guide — Data-Owner & Steward Framework (Microsoft Purview)

Run after building the ownership inventory and after each configuration step. Every test is safe
(read-only or a `-WhatIf` preview). Validate on the `Stewardship Pilot Domain – Stage1` before rolling
the framework across the estate.

## Test 1 — Ownership inventory is complete
**Do:** Run `DGSTEWARD-Assess-Ownership.ps1 -CsvPath .\OwnershipInventory.csv`; compare its control count
against what you see in the Purview portal (labels, DLP policies, retention policies, governance domains).
**Expected:** Every in-scope control/asset appears in the inventory; each is marked *owned* / *steward-
assigned* / *unowned* correctly, and the coverage number matches a manual spot-check.

## Test 2 — RACI is well-formed
**Do:** Open `Data-Owner/Steward RACI – Design`; for each activity row count the A/R/C/I entries.
**Expected:** Exactly **one Accountable** party per activity, at least one Responsible party per activity,
and every named party resolves to a real person or group (no placeholders). No activity is orphaned.

## Test 3 — Assignment dry-run makes no changes
**Do:** Run `DGSTEWARD-Set-Stewardship.ps1 -MatrixPath .\Purview-Stewardship-Matrix.csv -WhatIf`; afterward
re-run `DGSTEWARD-Assess-Ownership.ps1`.
**Expected:** The dry-run lists the intended owner/steward assignments and prints the reverse command for
each; the inventory is unchanged — `-WhatIf` truly changed nothing.

## Test 4 — Every pilot control/asset has an owner and a steward
**Do:** After `-Commit` on the pilot domain, run `DGSTEWARD-Test-Framework.ps1`.
**Expected:** Every in-scope control/asset in `Stewardship Pilot Domain – Stage1` reports a recorded
**Data Owner** and **Data Steward**; there are zero unowned in-scope items, or every remaining gap is a
named, owned action.

## Test 5 — Named roles resolve to real identities
**Do:** Run `DGSTEWARD-Report-Accountability.ps1`; it resolves each named owner/steward against Graph.
**Expected:** Every name in the RACI and the assignment matrix resolves to a valid user or group; no
assignment points at a departed or non-existent identity.

## Test 6 — Separation of duties holds
**Do:** Review the sensitive-role rows (Insider Risk, Communication Compliance, eDiscovery) in the RACI and
the corresponding role-group membership.
**Expected:** These roles are named, minimal, and **separate** from general stewardship; the same person
does not both steward general data and hold a sensitive role beyond the HR/legal-approved list.

## Test 7 — Review cadence produces a correct due/overdue list
**Do:** Run `DGSTEWARD-Check-Cadence.ps1 -CadenceDays 90` (or your agreed interval).
**Expected:** The script returns each control/asset's last-reviewed and review-by dates and correctly
flags **due** and **overdue** items; an item just re-certified drops off the overdue list; an item past
its review-by date appears on it.

## Test 8 — Accountability report reflects reality
**Do:** Run `DGSTEWARD-Report-Accountability.ps1 -CsvPath .\Accountability.csv`; open the Purview portal
and spot-check three controls.
**Expected:** `Accountability Coverage – Report` shows the coverage percentage and gap list that match the
portal; the three spot-checked controls' owner/steward match what the report claims.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Framework pass (pilot)** | Tests 1–8 pass on `Stewardship Pilot Domain – Stage1`: inventory complete, RACI well-formed (one A per activity), assignments applied, every pilot item owned + steward-assigned, roles resolve, separation holds, cadence correct, report accurate |
| **Expand pass** | Tests 1, 3–5, 7–8 pass again after broadening from the pilot domain to the full estate, with coverage meeting the agreed target and the cadence scheduled and owned |
