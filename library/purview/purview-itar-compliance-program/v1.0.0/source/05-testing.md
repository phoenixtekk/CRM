# 5. Testing Guide — Microsoft Purview ITAR Compliance Program

Run after the pilot assessment and controls are configured on `ITAR - Authorized Persons Pilot`
(Implementation Steps 3–5), **before** the audit gate (Step 6), and again after each expansion. Each test
states what to **do** and the **expected** result; the pass/fail gate is at the end. Use synthetic test
markings — **never** real USML technical data in a test that could reach an unauthorized person.

## Test 1 — Export-control assessment created and scored
**Do:** Purview → **Compliance Manager → Assessments →** open `ITAR Assessment – Export Control – Pilot`.
**Expected:** The assessment exists against the export-control / NIST SP 800-171 template, shows a
**Compliance Score**, and lists improvement actions with owner / implementation status / test status /
evidence slots.

## Test 2 — Roles separated; access held by authorized U.S. persons
**Do:** Purview → **Settings → Roles and scopes → Role groups**, or run `ITAR-Discovery.ps1` (role
report).
**Expected:** Roles are least-privilege; roles that can access technical data are held by **authorized
U.S. persons**; HR/privacy-sensitive roles are separated — captured as `ITAR Roles – Separation
Evidence`. (The U.S.-person determination itself is export-control/HR's.)

## Test 3 — Scope, authorized-person list, and control map complete
**Do:** Review `ITAR Scope – Record`, `ITAR Control Map – Export Controls`, and `ITAR Evidence –
Register`.
**Expected:** The controlled-data scope and authorized-U.S.-person list are recorded; every in-scope
obligation maps to a named Purview control with an owner and evidence location; no in-scope obligation is
unmapped.

## Test 4 — Label encrypts and restricts to authorized U.S. persons
**Do:** Apply `Sensitivity Label - ITAR Technical Data - Authorized US Persons` to a test document, then
attempt to open it as (a) an authorized pilot user and (b) an out-of-scope/unauthorized user. Or run
`ITAR-Validation.ps1`.
**Expected:** The item is encrypted and shows the export-control marking; the authorized user opens it per
the label's permissions; the unauthorized user is **denied**.

## Test 5 — Custom SIT detects an ITAR/USML marking
**Do:** Purview → **Data classification → Sensitive info types →** open `SIT - ITAR/USML Markers` →
**Test**, using sample content with a real-format marking and decoy text.
**Expected:** The SIT matches the marking at the configured confidence and does **not** match the decoys.

## Test 6 — Auto-labeling simulation matches technical data
**Do:** Purview → **Information Protection → Auto-labeling →** open `Auto-Label - ITAR Technical Data -
Pilot` → **Simulation**.
**Expected:** The simulation lists items containing ITAR/USML markings and proposes the label — and does
not flag routine, non-controlled content.

## Test 7 — DLP is auditing (before the gate)
**Do:** As a pilot user, email a test message containing a labelled/marked test item to an **unauthorized/
external** address; check Purview → **Data Loss Prevention → Alerts** / **Activity explorer**. Or run
`ITAR-EvidenceReport.ps1`.
**Expected:** `DLP Policy - ITAR Export-Controlled - Audit` records the match (policy tip shown, no block)
— the audit gate has data to review.

## Test 8 — DLP hard-blocks unauthorized recipients (after the gate)
**Do:** After Implementation Step 7, repeat Test 7 against `DLP Policy - ITAR Export-Controlled -
Enforce`; also (endpoint) attempt to copy a labelled item to a USB drive.
**Expected:** The send to the unauthorized recipient is **hard-blocked**; the USB copy is blocked/audited
per the endpoint rule; each event is logged. Sends to **authorized** recipients still succeed.

## Test 9 — Export-record retention applied
**Do:** Apply `Retention Label - Export Records - Retention` to a test item and attempt to delete it
before the period. Or run `ITAR-Validation.ps1`.
**Expected:** The item is retained/dispositioned per the schedule; disposition review holds deletion for
review rather than auto-deleting.

## Test 10 — Audit and coverage evidence
**Do:** Run `ITAR-EvidenceReport.ps1`.
**Expected:** A label inventory, a DLP service/mode matrix, a per-workload DLP-event count, and an
audit-log sample — the cross-control evidence for the register.

## Test 11 — Posture report produced
**Do:** Produce `ITAR Posture – Report` (Compliance Manager score + `ITAR-EvidenceReport.ps1` output).
**Expected:** A score, per-action status, and evidence summary suitable for export-control/compliance
review.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Design pass** | Tests 1–3 pass — assessment scored, roles separated with authorized U.S. persons, scope/authorized-person list and control map complete |
| **Pilot pass** | Tests 4–7, 9 pass on the pilot; DLP audit correctly flags unauthorized recipients without blocking authorized work |
| **Audit gate** | DLP audit reviewed and tuned; only then is Test 8 (enforce/hard-block) run |
| **Expand pass** | Tests 4, 7/8, 9, 10, 11 pass after widening to the full authorized-person scope; evidence refreshed in `ITAR Evidence – Register`; scope never widened beyond authorized U.S. persons |
