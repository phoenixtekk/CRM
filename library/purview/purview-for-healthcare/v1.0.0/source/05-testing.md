# 5. Testing Guide — Microsoft Purview for Healthcare (HIPAA/PHI)

Run after publishing to `Purview - PHI Pilot Users` (Implementation Step 3 onward), before the DLP
audit gate (Step 6), and again after each expansion. Use **fake / synthetic PHI** for all tests —
never real patient data.

## Test 1 — PHI labels published and visible
**Do:** In Outlook / Word (web or desktop) as a pilot user, open the **Sensitivity** button. Or run
`PHI-Validation.ps1`.
**Expected:** All four taxonomy labels appear (`Sensitivity Label - Public - All Users` through
`Sensitivity Label - Highly Confidential - PHI Restricted - All Users`) via
`Label Policy - Healthcare PHI Taxonomy - All Users`.

## Test 2 — PHI label protection applies (and clinical apps still work)
**Do:** Apply `Sensitivity Label - Confidential - PHI - All Users` to a test document and try to open
it as an out-of-scope external user. Also open a labeled file in the **clinical apps inventoried in
Requirement 2.6**.
**Expected:** The document is encrypted/marked; the external user is denied per the label's
permissions; and the inventoried clinical apps open it (or the incompatibility is documented for the
emergency-access plan **before** enforcement).

## Test 3 — PHI auto-labeling simulation matches
**Do:** Purview → **Information Protection → Auto-labeling →** open `Auto-Label - PHI Health Records -
Pilot` → **Simulation**.
**Expected:** The simulation lists items that match the PHI rule (for example files containing the
HIPAA / ICD sensitive information types) — and does not flag routine, non-PHI content. The policy is
still in simulation (nothing applied yet).

## Test 4 — DLP is auditing PHI (before the gate)
**Do:** As a pilot user, email a test message containing **synthetic** PHI (for example a fake health
identifier / ICD code) to an external address; check Purview → **Data Loss Prevention → Alerts** and
**Activity explorer**. Or run `PHI-Report.ps1`.
**Expected:** `DLP Policy - PHI HIPAA - Audit` records the match (policy tip shown, no block) — the
audit gate has data to review.

## Test 5 — DLP enforces PHI (after the gate)
**Do:** After Step 7, repeat Test 4 against `DLP Policy - PHI HIPAA - Enforce`.
**Expected:** The action now blocks (or blocks-with-override) per the enforce rule; the event is
logged. A clinician can proceed via justification if block-with-override was chosen.

## Test 6 — Retention label applied and honored
**Do:** Apply `Retention Label - HIPAA Documentation - 6 Year` (and, separately,
`Retention Label - Medical Records - Schedule-Defined`) to a test item and attempt to delete it.
**Expected:** The item is retained for the schedule-defined period (or declared a record and blocked
from deletion) per the label; records route to disposition review rather than auto-deleting.

## Test 7 — Retention policy scoped
**Do:** Confirm `Retention Policy - Healthcare Baseline - Schedule-Defined` is applied to the pilot
locations (Purview → **Data Lifecycle Management → Retention policies →** open the policy). Or run
`PHI-Validation.ps1`.
**Expected:** The policy shows **On** and scoped to the pilot mailboxes/sites/OneDrive/Teams.

## Test 8 — PHI coverage report
**Do:** Run `PHI-Report.ps1`.
**Expected:** A summary of PHI classification (labeled items) and DLP events across the enabled
services, so coverage and gaps are visible for the HIPAA evidence record.

## Test 9 — (Optional, E5) PHI exposure to AI reviewed
**Do:** If licensed, Purview → **DSPM for AI** → review PHI-labeled content exposed to Copilot/AI.
**Expected:** Restricted PHI is protected by the `Highly Confidential - PHI Restricted` label and its
permissions; exposure is understood before broad AI enablement. **Verify your licensing/tenant.**

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4, 6–7 pass on `Purview - PHI Pilot Users`; the DLP audit shows real PHI matches and acceptable noise; clinical-app/encryption compatibility (Test 2) is confirmed or documented |
| **Audit gate** | DLP audit reviewed and tuned; only then is Test 5 (enforce) run |
| **Expand pass** | Tests 1, 4/5, 7, 8 pass after widening scope beyond the pilot |
