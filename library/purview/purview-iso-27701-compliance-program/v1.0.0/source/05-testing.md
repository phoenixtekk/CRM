# 5. Testing Guide — Microsoft Purview ISO 27701 Compliance Program

Run after the pilot assessment and controls are configured on `ISO 27701 - Pilot Scope` (Implementation
Steps 3–7), **before** the audit gate (Step 6), and again after each expansion. Each test states what to
**do** and the **expected** result; the pass/fail gate is at the end.

## Test 1 — ISO 27701 assessment created and scored
**Do:** Purview → **Compliance Manager → Assessments →** open `ISO 27701 Assessment – PIMS – Pilot`.
**Expected:** The assessment exists against the **ISO 27701** template (layered on ISO 27001 where
present), shows a **Compliance Score**, and lists improvement actions with owner / implementation status
/ test status / evidence slots.

## Test 2 — Roles separated (least privilege)
**Do:** Purview → **Settings → Roles and scopes → Role groups**, or run `ISO27701-Discovery.ps1` (role
report).
**Expected:** The mapped roles are least-privilege and HR/privacy-sensitive roles (Insider Risk,
Communication Compliance, Priva) are held by **separate** owners — captured as `ISO 27701 Roles –
Separation Evidence`.

## Test 3 — Clause-to-control map complete (controller/processor)
**Do:** Review `ISO 27701 Control Map – Clauses`, `ISO 27701 Scope – Record`, and `ISO 27701 Evidence –
Register`.
**Expected:** Every in-scope PIMS requirement maps to a named Purview control with an owner and an
evidence location; the **controller/processor role** is recorded per activity; no in-scope requirement
is unmapped.

## Test 4 — PII label published and applies
**Do:** As a pilot user in Word/Outlook, open the **Sensitivity** button; apply `Sensitivity Label - PII
(PIMS) - All Users` to a test document. Or run `ISO27701-Validation.ps1`.
**Expected:** The label appears via its label policy and (if encryption is configured) protects the
document per its permissions.

## Test 5 — Auto-labeling simulation matches PII
**Do:** Purview → **Information Protection → Auto-labeling →** open `Auto-Label - PII - Pilot` →
**Simulation**.
**Expected:** The simulation lists items containing **PII sensitive-information types** and does not flag
routine, non-personal content.

## Test 6 — DLP is auditing (before the gate)
**Do:** As a pilot user, email a test message containing a fake **PII identifier** to an external
address; check Purview → **Data Loss Prevention → Alerts** / **Activity explorer**. Or run
`ISO27701-EvidenceReport.ps1`.
**Expected:** `DLP Policy - PII (PIMS) - Audit` records the match (policy tip shown, no block) — the
audit gate has data to review.

## Test 7 — DLP enforces (after the gate)
**Do:** After Implementation Step 8, repeat Test 6 against `DLP Policy - PII (PIMS) - Enforce`.
**Expected:** The action now blocks (or blocks-with-override) per the enforce rule; the event is logged.

## Test 8 — Retention (retention limitation) applied
**Do:** Apply `Retention Label - PII - Retention Limitation` to a test item and attempt to delete it
before the period. Or run `ISO27701-Validation.ps1`.
**Expected:** The item is retained/dispositioned per the schedule; disposition review holds deletion for
review rather than auto-deleting.

## Test 9 — DSR method locates a principal's data
**Do:** Run the DSR method from Implementation Step 7 — a Priva **Subject Rights Request**, or the
content search `DSR - PII Principal Access - Search` keyed on a test principal's identifiers.
**Expected:** The request/search returns the test principal's PII across the in-scope workloads; the run
is recorded in `ISO 27701 Evidence – Register`. (The produce/correct/erase **decision** is
privacy/legal, not part of this test.)

## Test 10 — Audit and coverage evidence
**Do:** Run `ISO27701-EvidenceReport.ps1`.
**Expected:** A label inventory, a DLP service/mode matrix, a per-workload DLP-event count, and an
audit-log sample — the cross-control evidence for the register.

## Test 11 — Posture report produced
**Do:** Produce `ISO 27701 Posture – Report` (Compliance Manager score + `ISO27701-EvidenceReport.ps1`
output).
**Expected:** A score, per-action status, and evidence summary suitable for management review / an
external auditor.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Design pass** | Tests 1–3 pass — assessment scored, roles separated, clause map complete with controller/processor role |
| **Pilot pass** | Tests 4–6, 8, 9 pass on `ISO 27701 - Pilot Scope`; DLP audit shows real PII matches with acceptable noise |
| **Audit gate** | DLP audit reviewed and tuned; only then is Test 7 (enforce) run |
| **Expand pass** | Tests 4, 6/7, 8, 10, 11 pass after widening scope beyond the pilot; evidence refreshed in `ISO 27701 Evidence – Register` |
