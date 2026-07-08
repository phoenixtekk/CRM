# 5. Testing & Validation — Sensitive Information Types Implementation (Microsoft Purview)

Validate the built-in SIT selection against explicit **pass/fail gates**. The three headline gates are:
**(A) true positives are detected**, **(B) look-alike negatives are rejected and the false-positive rate is
low**, and **(C) the selection is consistent and handed off correctly**. Run every test with **non-real,
clearly-fake sample data** (e.g. the Microsoft-documented test credit-card number `4111 1111 1111 1111`) —
never real customer/employee data — and record the evidence.

> All tests use the `SIT Test Corpus – <Category>` (Req 2.4) and, for real-traffic measurement, the
> `SIT Measure – <Category> – Simulation` policy — always in **simulation**, never enforced. This solution
> introduces no enforcement.

---

## Test A — True-positive detection (the SIT finds what it should)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Portal Test — positive | In **Sensitive info types → [SIT] → Test**, upload a **positive** corpus file (contains valid fake instances). | SIT matches at the **target confidence** (ideally High). |
| A2 | Scripted corpus — positives | Run `CLSSIT-Test.ps1 -SensitiveType '<SIT>' -Path .\corpus\<category>\positives\`. | Every positive sample is matched; confidence recorded per file. |
| A3 | Instance-count boundary | Provide a file with **exactly** the minimum instance count, and one **just below** it. | At-threshold file matches; below-threshold file correctly does **not** — confirms the instance dial. |
| A4 | Confidence boundary | Provide a positive with strong corroborating evidence and one with weak evidence. | Strong-evidence sample matches at High; weak-evidence sample matches only at lower confidence (or not) — confirms the confidence dial behaves as expected. |

**Gate A (pass):** every category's positive corpus is detected by its selected SIT at the target
confidence, and the instance/confidence boundaries behave as configured.

---

## Test B — Negative rejection & false-positive rate (the adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Portal Test — look-alike negative | Upload a **negative / look-alike** corpus file (internal reference numbers, order IDs that resemble the pattern). | SIT does **not** match — no false positive on look-alikes. |
| B2 | Scripted corpus — negatives | Run `CLSSIT-Test.ps1` against the negatives folder. | Zero (or below-threshold-only) matches on the negative corpus. |
| B3 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`CLSSIT-Report.ps1 -Days <n>`), inspect them in **Content explorer**, and classify each TP/FP. | **False-positive rate ≤ the agreed threshold** (define with compliance — a common target is ≤10% of matches, or an absolute FP count the team can absorb). |
| B4 | Post-tuning re-measure | After each tuning change (confidence↑, instance count↑, or a tuned SIT copy), re-run the portal/scripted test and re-simulate. | FP rate trends **down** while Test A true positives still fire. |

**Gate B (pass):** the negative corpus is rejected and the measured false-positive rate is at/under the
threshold on the simulation sample, with true positives intact.

---

## Test C — Consistency & hand-off (the selection is usable downstream)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Selection register complete | Review the `SIT Selection Register`. | Every in-scope data category maps to a named built-in SIT (or is explicitly flagged as a gap for another solution). |
| C2 | Threshold register complete | Review the `SIT Threshold Register`. | Every selected SIT has a recorded confidence level and instance count matching what was validated. |
| C3 | Tuned copy traceable (if used) | If any `<Built-in> – Tuned Copy – Classification` was created, review its documented pattern/keyword/confidence changes and corpus test result. | The copy is documented, tested, and the original built-in SIT is confirmed **unmodified**. |
| C4 | Downstream reference | Point a downstream control (e.g. a DLP rule, still in simulation) at the validated SIT at the registered settings. | The downstream policy resolves the SIT and applies the registered confidence/instance count without error. |

**Gate C (pass):** both registers are complete and consistent, any tuned copy is traceable, and a downstream
control consumes the validated selection cleanly.

---

## Safety & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | No enforcement introduced | The `SIT Measure – … – Simulation` policy is confirmed in a **Test\*** mode; no user is ever blocked by this solution's artifacts. |
| S2 | Built-in SIT unmodified | The original built-in SITs are unchanged (only editable **copies** were tuned) — confirm in the SIT library. |
| S3 | Scripts are safe-by-default | `CLSSIT-BuildSimPolicy.ps1` and `CLSSIT-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); Discovery/Test/Report scripts are read-only. |
| S4 | Clean teardown | Deleting a `SIT Measure – … – Simulation` policy removes the measurement scaffolding with no residual effect. |

---

## Evidence to capture (for the deliverable record)
- The built-in SIT inventory CSV (Phase 0) and the completed `SIT Selection Register` + `SIT Threshold
  Register`.
- Portal Test + scripted corpus results showing positives detected and negatives rejected (Gate A/B).
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Documentation of any tuned SIT copy and confirmation the built-in original is unmodified (S2/C3).
- Confirmation that no enforcement was introduced (S1) and the measurement policy tore down cleanly (S4).

> **Determination boundary.** These tests prove the **detector is accurate**. Whether a given category's
> SIT selection *legally satisfies* a regulation, and whether its false-positive threshold is *acceptable*,
> are compliance/privacy/legal sign-offs, captured alongside the evidence above.
