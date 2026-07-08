# 5. Testing Guide — Microsoft Purview GDPR Compliance Program

Run after the pilot assessment and controls are configured on `GDPR - Pilot Scope` (Implementation
Steps 3–7), **before** the audit gate (Step 6), and again after each expansion. Each test states what
to **do** and the **expected** result; the pass/fail gate is at the end.

## Test 1 — GDPR assessment created and scored
**Do:** Purview → **Compliance Manager → Assessments →** open `GDPR Assessment – Regulation – Pilot`.
**Expected:** The assessment exists against the **GDPR** template, shows a **Compliance Score**, and
lists improvement actions with owner / implementation status / test status / evidence slots.

## Test 2 — Roles separated (least privilege)
**Do:** Purview → **Settings → Roles and scopes → Role groups**, or run `GDPR-Discovery.ps1` (role
report).
**Expected:** The mapped roles are assigned least-privilege and HR/privacy-sensitive roles (Insider
Risk, Communication Compliance) are held by **separate** owners — captured as `GDPR Roles –
Separation Evidence`.

## Test 3 — Article-to-control map complete
**Do:** Review `GDPR Control Map – Articles` and `GDPR Evidence – Register`.
**Expected:** Every in-scope obligation maps to a named Purview control with an owner and an evidence
location; no in-scope obligation is unmapped.

## Test 4 — Personal-data label published and applies
**Do:** As a pilot user in Word/Outlook, open the **Sensitivity** button; apply
`Sensitivity Label - Personal Data (GDPR) - All Users` to a test document. Or run
`GDPR-Validation.ps1`.
**Expected:** The label appears via its label policy and (if encryption is configured) protects the
document per its permissions.

## Test 5 — Auto-labeling simulation matches EU personal data
**Do:** Purview → **Information Protection → Auto-labeling →** open `Auto-Label - EU Personal Data -
Pilot` → **Simulation**.
**Expected:** The simulation lists items containing **EU personal-data sensitive-information types**
(e.g. EU National Identification / Passport / Tax ID numbers) and does not flag routine, non-personal
content.

## Test 6 — DLP is auditing (before the gate)
**Do:** As a pilot user, email a test message containing a fake **EU personal-data identifier** to an
external address; check Purview → **Data Loss Prevention → Alerts** / **Activity explorer**. Or run
`GDPR-EvidenceReport.ps1`.
**Expected:** `DLP Policy - EU Personal Data - Audit` records the match (policy tip shown, no block) —
the audit gate has data to review.

## Test 7 — DLP enforces (after the gate)
**Do:** After Implementation Step 8, repeat Test 6 against `DLP Policy - EU Personal Data - Enforce`.
**Expected:** The action now blocks (or blocks-with-override) per the enforce rule; the event is
logged.

## Test 8 — Retention (storage limitation) applied
**Do:** Apply `Retention Label - Personal Data - Storage Limitation` to a test item and attempt to
delete it before the period. Or run `GDPR-Validation.ps1`.
**Expected:** The item is retained/dispositioned per the schedule; disposition review holds deletion
for review rather than auto-deleting.

## Test 9 — DSR method locates a data subject's data
**Do:** Run the DSR method from Implementation Step 7 — a Priva **Subject Rights Request**, or the
content search `DSR - Data Subject Access - Search` keyed on a test subject's identifiers.
**Expected:** The request/search returns the test subject's personal data across the in-scope
workloads; the run is recorded in `GDPR Evidence – Register`. (The produce/erase **decision** is
privacy/legal, not part of this test.)

## Test 10 — Audit and coverage evidence
**Do:** Run `GDPR-EvidenceReport.ps1`.
**Expected:** A label inventory, a DLP service/mode matrix, a per-workload DLP-event count, and an
audit-log sample — the cross-control evidence for the register.

## Test 11 — Posture report produced
**Do:** Produce `GDPR Posture – Report` (Compliance Manager score + `GDPR-EvidenceReport.ps1` output).
**Expected:** A score, per-action status, and evidence summary suitable for compliance/privacy review.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Design pass** | Tests 1–3 pass — assessment scored, roles separated, article map complete |
| **Pilot pass** | Tests 4–6, 8, 9 pass on `GDPR - Pilot Scope`; DLP audit shows real EU-personal-data matches with acceptable noise |
| **Audit gate** | DLP audit reviewed and tuned; only then is Test 7 (enforce) run |
| **Expand pass** | Tests 4, 6/7, 8, 10, 11 pass after widening scope beyond the pilot; evidence refreshed in `GDPR Evidence – Register` |
