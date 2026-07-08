# 5. Testing Guide — Microsoft Purview: DLP, Sensitivity Labels & Retention

Run after publishing to `Purview - Pilot Users` (Implementation Step 3 onward), before the DLP audit
gate (Step 6), and again after each expansion.

## Test 1 — Labels published and visible
**Do:** In Outlook / Word (web or desktop) as a pilot user, open the **Sensitivity** button. Or run
`PURVIEW-Validation.ps1`.
**Expected:** All four taxonomy labels appear (`Sensitivity Label - Public - All Users` through
`Sensitivity Label - Highly Confidential - All Users`) via
`Label Policy - Sensitivity Taxonomy - All Users`.

## Test 2 — Label protection applies
**Do:** Apply `Sensitivity Label - Confidential - All Users` to a test document and try to open it as
an out-of-scope external user.
**Expected:** The document is encrypted/marked; the external user is denied per the label's
permissions.

## Test 3 — Auto-labeling simulation matches
**Do:** Purview → **Information Protection → Auto-labeling →** open
`Auto-Label - Confidential Financial - Pilot` → **Simulation**.
**Expected:** The simulation lists items that match the rule (for example files containing card
numbers) — and does not flag routine, non-sensitive content.

## Test 4 — DLP is auditing (before the gate)
**Do:** As a pilot user, email a test message containing a fake credit-card number to an external
address; check Purview → **Data Loss Prevention → Alerts** and **Activity explorer**. Or run
`PURVIEW-Report.ps1`.
**Expected:** `DLP Policy - Financial and PII - Audit` records the match (policy tip shown, no block)
— the audit gate has data to review.

## Test 5 — DLP enforces (after the gate)
**Do:** After Step 7, repeat Test 4 against `DLP Policy - Financial and PII - Enforce`.
**Expected:** The action now blocks (or blocks-with-override) per the enforce rule; the event is
logged.

## Test 6 — Retention label applied and honored
**Do:** Apply `Retention Label - Financial Records - 7 Year` to a test item and attempt to delete it.
**Expected:** The item is retained for the period (or declared a record and blocked from deletion) per
the label.

## Test 7 — Retention policy scoped
**Do:** Confirm `Retention Policy - M365 Baseline - 5 Year` is applied to the pilot locations
(Purview → **Data Lifecycle Management → Retention policies →** open the policy). Or run
`PURVIEW-Validation.ps1`.
**Expected:** The policy shows **On** and scoped to the pilot mailboxes/sites/OneDrive/Teams.

## Test 8 — Coverage report
**Do:** Run `PURVIEW-Report.ps1`.
**Expected:** A summary of classification (labeled items) and DLP events across the enabled services,
so coverage and gaps are visible.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4, 6–7 pass on `Purview - Pilot Users`; the DLP audit shows real matches and acceptable noise |
| **Audit gate** | DLP audit reviewed and tuned; only then is Test 5 (enforce) run |
| **Expand pass** | Tests 1, 4/5, 7, 8 pass after widening scope beyond the pilot |
