# 5. Testing Guide — Microsoft Purview for Retail

Run after publishing to `Purview - Retail Pilot` (Implementation Step 3 onward), before the DLP audit
gate (Step 7), and again after each expansion. Use **synthetic/test data only** — never a real PAN or
real customer record. Microsoft publishes test card numbers (for example the Luhn-valid test PAN
`4111 1111 1111 1111`) safe to use for DLP validation.

## Test 1 — Labels published and visible
**Do:** In Outlook / Word (web or desktop) as a pilot user, open the **Sensitivity** button. Or run
`RETAIL-Validation.ps1`.
**Expected:** All four taxonomy labels appear (`Sensitivity Label - Retail Public` through
`Sensitivity Label - Cardholder Data - Restricted`) via
`Label Policy - Retail Data Classification - Pilot`.

## Test 2 — Label protection applies
**Do:** Apply `Sensitivity Label - Customer PII - Confidential` to a test document and try to open it
as an out-of-scope external user.
**Expected:** The document is encrypted/marked; the external user is denied per the label's
permissions.

## Test 3 — Auto-labeling simulation finds PAN
**Do:** Purview → **Information Protection → Auto-labeling →** open
`Auto-Label - PCI Cardholder Data - Simulation` → **Simulation**.
**Expected:** The simulation lists items containing card-number patterns (your seeded test files) and
does not flag routine, non-sensitive content — this is your map of where PAN sits in M365.

## Test 4 — PCI DLP is auditing (before the gate)
**Do:** As a pilot user, email a message containing a **test** card number to an external address;
check Purview → **Data Loss Prevention → Alerts** and **Activity explorer**. Or run
`RETAIL-Report.ps1`.
**Expected:** `DLP Policy - Retail PCI Cardholder Data - Test` records the match (policy tip shown, no
block) — the audit gate has data to review.

## Test 5 — Customer-PII DLP is auditing (before the gate)
**Do:** As a pilot user, share a test file containing seeded customer PII (test names/IDs) to an
external recipient; check Alerts / Activity explorer. Or run `RETAIL-Report.ps1`.
**Expected:** `DLP Policy - Retail Customer PII - Test` records the match without blocking.

## Test 6 — PCI DLP blocks (after the gate)
**Do:** After Step 8, repeat Test 4 against `DLP Policy - Retail PCI Cardholder Data - Enforce`.
**Expected:** The action **blocks** the message/share containing the test PAN; the event is logged.
PAN cannot move through the enabled M365 locations.

## Test 7 — Customer-PII DLP enforces (after the gate)
**Do:** After Step 8, repeat Test 5 against `DLP Policy - Retail Customer PII - Enforce`.
**Expected:** The action blocks (or blocks-with-override) per the enforce rule; the event is logged.

## Test 8 — Endpoint DLP fires (endpoint DLP only)
**Do:** On an onboarded pilot device, attempt to copy a test file containing a test PAN to a USB drive
or upload it to a personal-cloud domain.
**Expected:** The endpoint DLP rule audits (before the gate) or blocks (after), per policy mode.

## Test 9 — Retention label applied and honored
**Do:** Apply `Retention Label - Customer Transaction Records - 7 Year` to a test item and attempt to
delete it.
**Expected:** The item is retained for the period (or declared a record and blocked from deletion) per
the label.

## Test 10 — Retention policy scoped
**Do:** Confirm `Retention Policy - Retail Baseline - 5 Year` is applied to the pilot locations
(Purview → **Data Lifecycle Management → Retention policies →** open the policy). Or run
`RETAIL-Validation.ps1`.
**Expected:** The policy shows **On** and scoped to the pilot mailboxes/sites/OneDrive/Teams.

## Test 11 — PCI compliance evidence present
**Do:** Purview → **Compliance Manager →** open `Assessment - PCI-DSS - Retail Baseline`.
**Expected:** The assessment exists, improvement actions map to the configured Purview controls, and
evidence can be recorded. (Requires the licensing in Requirement 2.1 — **verify your tenant**.)

## Test 12 — Coverage report
**Do:** Run `RETAIL-Report.ps1`.
**Expected:** A summary of classification (labeled items), DLP location/mode coverage, and DLP events
by workload — so PAN/PII coverage and gaps are visible.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5, 9–10 pass on `Purview - Retail Pilot`; the DLP audit shows real PAN/PII matches and acceptable noise |
| **Audit gate** | Both DLP policies' audits reviewed and tuned; only then are Tests 6–8 (enforce/block) run |
| **Expand pass** | Tests 1, 4/6, 5/7, 10, 12 pass after widening scope beyond the pilot |
