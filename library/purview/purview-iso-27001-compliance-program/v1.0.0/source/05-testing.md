# 5. Testing & Validation — Microsoft Purview ISO 27001 Compliance Program

Validate the program against explicit **pass/fail gates**. The three headline gates for this solution are:
**(A) every in-scope Annex A control maps to a configured Purview control**, **(B) each mapped control
carries collected evidence (owner, date, test status)**, and **(C) the high-impact controls behave as
designed and were piloted in simulation/test first**. Run every functional test with **non-real,
clearly-fake sample data** (e.g. the Microsoft-documented test credit-card number `4111 1111 1111 1111`)
— never real customer/employee data — and record the evidence.

> These tests prove the **technical controls work and are evidenced**. They do **not** determine
> certification, applicability, or adequacy — those are ISMS / risk / compliance / certification-body
> sign-offs, captured alongside the evidence below.

---

## Test A — Control mapping & coverage (nothing in-scope is unmapped)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Every SoA control mapped | Cross-check `ISO27001 Control Map – AnnexA-to-Purview` against the in-scope controls in the SoA. | Every applicable Annex A control is mapped to a Purview capability **or** explicitly marked out-of-Purview with a reason. |
| A2 | Mapping is real, not asserted | For each mapped control, confirm the named Purview object exists (`ISO27001-Discovery.ps1` / `ISO27001-ControlEvidence.ps1`). | Each mapped capability resolves to an actual configured object (label, DLP policy, retention policy, audit state). |
| A3 | Partial-evidence controls flagged | Review controls where Purview provides only partial evidence. | Partial coverage is labelled "partial" in the map — never claimed as fully met. |
| A4 | Out-of-scope controls excluded cleanly | Confirm organizational/people/physical Annex A controls are marked out-of-Purview. | No out-of-Purview control is falsely mapped to a Purview capability. |

**Gate A (pass):** the control map accounts for every in-scope Annex A control — mapped, partial, or
out-of-Purview — with each mapped capability confirmed to exist.

---

## Test B — Evidence collection (each control is defensible)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Evidence register complete | Run `ISO27001-ControlEvidence.ps1 -ControlMap ... -CsvPath ...` and review the register. | Every mapped control has a row with technical state, owner, date, and test status; **evidence gaps are listed**. |
| B2 | Audit/logging evidence present | Confirm unified audit is on and capturing label/DLP/retention activity (A.8.15/8.16). | Audit ingestion enabled; `ISO27001-Report.ps1` returns relevant activity events. |
| B3 | Improvement-action evidence attached | In Compliance Manager, spot-check improvement actions tied to configured controls. | The action carries implementation status, test status/date, and attached evidence. |
| B4 | Coverage roll-up | Run `ISO27001-Report.ps1 -ControlMap ... -CsvPath ...`. | The coverage report shows mapped-control coverage and flags any control with no collected evidence. |

**Gate B (pass):** the evidence register and coverage report show every in-scope mapped control with
collected evidence and no unexplained gap.

---

## Test C — Technical control behaviour & simulate-first discipline

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Classification/labelling works (A.5.12/5.13) | In the pilot ring, apply the label scheme to a test document; where the label applies encryption, confirm it. | Label applies and (if configured) protection/encryption is enforced on the item. |
| C2 | Data leakage prevented (A.8.12) | With DLP enforced for the ring, attempt to send/share fake-SIT content externally. | Action is blocked/tipped per policy; a DLP event is logged. Below-threshold content is correctly **not** matched. |
| C3 | Retention/deletion behaves (A.8.10/5.33) | Apply the pilot retention/label to test content; verify retention holds and disposition/deletion behaves as specified (disposition review where required). | Content is retained for the configured period and disposition/deletion follows the specified rule. |
| C4 | Cryptography evidence (A.8.24/5.14) | Confirm label-applied encryption / message encryption on a test transfer. | Protected content is encrypted in transit/at rest per configuration. |
| C5 | Simulate/test first | Confirm each high-impact control (DLP, labels, retention) ran in **simulation/test/pilot** before enforcement. | Evidence shows a simulation/test stage preceded enforcement for every high-impact control. |

**Gate C (pass):** each configured technical control behaves as designed for the pilot ring, and each was
piloted in simulation/test before enforcement.

---

## Simulate-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `ISO27001 Pilot Ring – Stage1` experience no blocking/mandatory labelling during pilot. |
| S2 | Instant rollback | Setting any enforced DLP/retention policy back to **simulation/test** (and the label policy to non-mandatory) immediately removes enforcement with no data change. |
| S3 | Scripts are safe-by-default | `ISO27001-Config.ps1` / `ISO27001-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); Discovery / ControlEvidence / Report are read-only. |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0), licensing confirmation, and the current Compliance Score.
- The signed-off `ISO27001 Control Map – AnnexA-to-Purview` (Gate A).
- The `ISO27001 Evidence – Register` and the coverage report, with gaps listed (Gate B).
- Screenshots/logs of the technical-control tests (C1–C4) and confirmation each was piloted in
  simulation/test (C5/S1/S2).
- The `ISO27001 Roles – Separation Evidence` snapshot (segregation of duties, A.5.3).

> **Determination boundary.** These tests prove the **controls are configured, working, and evidenced**.
> Whether the ISMS scope, the SoA, the risk treatment, and the evidence **satisfy ISO 27001 for
> certification** is an ISMS / risk / compliance / certification-body determination, captured alongside the
> evidence above.
