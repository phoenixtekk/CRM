# Testing & Validation — Trainable Classifiers

This is the pass/fail gate set. Trainable classifiers have **two** things to validate: the
**classifier's accuracy** (does it recognize the right content?) and the **wiring** (does the control
that acts on it exist, in simulation, correctly scoped?). Run the wiring gates in two passes: **once
in simulation** (Phase 4 — content is *classified* and the control *would* act, nothing changes) and
**again after enforce** (Phase 5 — the label/action *actually* applies). Use **benign test content**
with a known ground truth — **never** real regulated data as your only test material.

> **Determination boundary.** These tests prove the **classifier and control work as configured** and
> measure accuracy. Whether the accuracy is *acceptable* for a given use, and whether content is in
> scope, are **compliance / data-owner** determinations — not test outcomes (see
> `global-requirements-purview.md` §5).

Run `.\CLSTRAIN-Validate.ps1` for the wiring configuration gates and `.\CLSTRAIN-Report.ps1` for the
policy-mode/activity rollup.

---

## A. Classifier accuracy gates (manual — in the portal Test stage + simulation)

| # | Check | PASS signal |
|---|---|---|
| A1 | Test-stage accuracy | In the classifier's **Test** stage, accuracy meets the **R7** threshold against the pre-categorized test set (R4). |
| A2 | True positives | Known-match test items are predicted **match**. |
| A3 | True negatives | Known non-match test items are predicted **non-match** (precision, not just recall). |
| A4 | Real-world precision | In the **simulation** pass over the pilot estate, spot-checked matches are genuinely the target category (not just the curated test set). |
| A5 | Published only if passed | The classifier was **published only after** A1–A4 met the R7 threshold, signed off by the data owner. |

**Gate A:** A1–A5 PASS at the R7 threshold. Any FAIL → retrain (add/clean seed samples) and retest;
**do not publish or enforce** a classifier that fails accuracy.

---

## B. Wiring configuration gates (automated — `CLSTRAIN-Validate.ps1`, read-only)

| # | Check | PASS signal |
|---|---|---|
| B1 | Wiring policy exists | `AL-Classifier-Pilot` (auto-labeling) is present. |
| B2 | Simulation first | In the pilot pass, the policy **Mode** is a **Test/simulation** mode (not `Enable`). |
| B3 | Pilot scope | The policy is scoped to `SG-Classifier-Pilot`, **not** all users/sites. |
| B4 | Rule present | `AL-Rule-Contracts` exists and is enabled. |
| B5 | Target label set | The policy applies the intended sensitivity label (e.g. `Confidential`). |
| B6 | Classifier referenced | The rule references the trainable/built-in classifier as a condition (best-effort; **confirm in the portal where PowerShell does not expose the classifier condition**). |

**Gate B:** All applicable rows PASS. Any FAIL → fix in `03-implementation.md` before the behavioural
pass.

---

## C. Behavioural tests — does the wired control act on classified content? (both passes)

For each, place/identify a **matching** test document and a **non-matching** one in the pilot scope and
record the result. Simulation PASS = *"item shown in simulation results as would-be-labeled; nothing
applied."* Enforce PASS = *"the label is actually applied."*

| # | Test | Simulation PASS | Enforce PASS |
|---|---|---|---|
| C1 | A **matching** document (target category) in the pilot scope | Appears in simulation results as *would apply* the label | The target label is **applied** to it |
| C2 | A **non-matching** document in the pilot scope | **Not** matched; would not be labeled | **Not** labeled |
| C3 | A matching document **outside** the pilot scope | Not processed by this policy | Not labeled by this policy |

**Gate C (simulation pass):** C1 matches and C2 does not — the classifier + wiring discriminate
correctly. **Gate C (enforce pass):** C1's label is applied and C2 is untouched. Any deviation → roll
back to simulation and retrain/tune.

---

## D. Evidence to capture (for the defensibility pack)

Capture and retain:

- The classifier **Test-stage accuracy** results and the **R7 sign-off** (accuracy threshold + named
  approver).
- `CLSTRAIN-Validate.ps1` output (wiring configuration gates).
- `CLSTRAIN-Report.ps1` output (policy modes + classification activity export where available) and the
  **auto-labeling simulation results** (which items would be / were labeled).
- Screenshots of the classifier's published status, the simulation results, and an applied label in
  the enforce pass.
- The **classifier map** (built-in vs custom, target label/action) and the pilot-scope confirmation.

> This evidence set is what makes the classifier **defensible** — it shows *what* accuracy was
> measured, *that* the classifier was published only after passing R7, *that* the wiring was validated
> in simulation before enforcement, and *that* the label/action applies only to the right content.
> Store it with the change record.
