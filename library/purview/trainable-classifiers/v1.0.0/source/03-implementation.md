# Implementation Guide — Trainable Classifiers in Microsoft Purview

This is the ordered, do-it-in-this-sequence guide. It follows the standard model —
**Assess → Design → Configure (seed/train/test/publish + wire) → Pilot (simulation) → Validate →
Expand (enforce)** — with every object **named**, an explicit **pass/fail gate** at each phase, and a
**rollback** for each change. Do **not** skip the accuracy-test or the simulation phase; auto-labeling
and DLP acting on a classifier are high-impact.

**Named objects used throughout (rename to your convention, but be consistent):**

| Object | Name used here |
|---|---|
| Custom trainable classifier | `TC-Contracts` |
| Built-in classifier(s) referenced | e.g. `Resumes`, `Source Code` (verify catalog) |
| Seed SharePoint site | `Seed-Contracts` (positive examples of contracts) |
| Target sensitivity label | `Confidential` (or a sub-label, per your taxonomy) |
| Auto-labeling policy (the wiring) | `AL-Classifier-Pilot` |
| Auto-labeling rule | `AL-Rule-Contracts` |
| Pilot scope (users/sites) | `SG-Classifier-Pilot` |

> **Tooling note.** **Creating, seeding, training, testing, and publishing a trainable classifier are
> done in the Purview portal** — there is **no** supported Security & Compliance PowerShell cmdlet to
> create/publish a classifier, so those steps are portal actions here. The **wiring** (auto-labeling /
> DLP / retention) can be authored in the portal **or** with `New-/Set-AutoSensitivityLabelPolicy` and
> `New-/Set-AutoSensitivityLabelRule` (and the equivalent DLP / retention cmdlets); the provided
> `CLSTRAIN-Configure.ps1` builds the auto-labeling wiring in **simulation** with `-WhatIf` by default.
> **Verify every portal path and cmdlet parameter — especially how a trainable classifier is
> referenced as a condition — against your tenant** (this evolves).

---

## Phase 0 — Assess (confirm you are ready)

1. **Confirm requirements.** Walk `02-requirements.md` R1–R8. Do **not** proceed until licensing,
   roles, seed content, test content, the target control + label, the built-in catalog review, the
   accuracy-acceptance decision, and a pilot scope are all confirmed.
2. **Run Discovery.** `Connect-IPPSSession`, then `.\CLSTRAIN-Discovery.ps1` to inventory existing
   auto-labeling / DLP / retention policies, sensitivity labels, and where a classifier could be
   wired. Keep the CSV as your baseline.
3. **Confirm seed readiness.** `.\CLSTRAIN-ScopeHealth.ps1` prompts you to confirm the seed site and
   reports pilot-scope signals.

**Gate 0 (pass/fail):** All of R1–R8 satisfied, Discovery baseline captured, seed + test content
ready, pilot scope defined. **Fail → stop** and close the gap; do not configure.

---

## Phase 1 — Design (built-in vs custom, target label/action)

1. **Map categories to classifiers** (R6): for each category you need, decide **built-in** (use as-is)
   vs **custom** (`TC-Contracts`). Only build custom where no built-in covers it.
2. **Decide the target control + label** (R5): e.g. auto-apply the **`Confidential`** label to content
   matching `TC-Contracts`; or feed a **DLP** rule / **retention** policy.
3. **Name every object** per the table above and set the **pilot scope**.

**Gate 1:** The classifier map, target control/label, and named objects are documented and approved.
**Fail → stop**; the accuracy tolerance (R7) and label choice are determination-owner calls.

---

## Phase 2 — Build the classifier (portal): seed → train → test → publish

For each **custom** classifier (built-in classifiers skip straight to Phase 3):

1. In **Purview portal → Data classification → Classifiers → Trainable classifiers** (verify path),
   **create** `TC-Contracts` and point its **seed** at the `Seed-Contracts` SharePoint site (R3).
2. Let it **train**. Training is not instant — allow the processing time Microsoft indicates.
3. **Test** the trained classifier against your **separate, pre-categorized test set** (R4). Review the
   predictions and the accuracy against the **R7 acceptance threshold**.
   - If accuracy is **below** threshold: add/clean seed samples, retrain, retest. Do **not** publish a
     classifier that fails R7.
4. **Publish** the classifier **only when the R7 threshold is met** and the data owner has signed off.

**Gate 2:** `TC-Contracts` is **published** with test-stage accuracy at/above the **R7** threshold,
signed off in writing. Built-in classifiers are confirmed available. **Fail → do not publish**; keep
tuning the seed set. (Rollback: an unpublished classifier acts on nothing; delete/retrain it.)

---

## Phase 3 — Wire the classifier into a control, in SIMULATION

Create the wiring that **acts** on the classifier — here an **auto-labeling** policy (DLP / retention
follow the same simulate-first pattern). Author in the portal or run `.\CLSTRAIN-Configure.ps1 -WhatIf`
first, then `.\CLSTRAIN-Configure.ps1 -Commit` (still simulation).

1. **Create the auto-labeling policy** `AL-Classifier-Pilot` in **simulation** (portal: auto-labeling
   *simulation mode*; PowerShell: `New-AutoSensitivityLabelPolicy` with a **Test** mode such as
   `TestWithoutNotifications` — **verify the exact mode value in your tenant**), scoped to the pilot,
   applying the **`Confidential`** label.
2. **Add the rule** `AL-Rule-Contracts` with a **condition that references the trainable classifier**
   (`TC-Contracts`, and/or a built-in classifier). **Verify how a trainable classifier is referenced
   as a condition in `Get-Help New-AutoSensitivityLabelRule -Full` for your tenant** — the parameter
   shape evolves; if uncertain, attach the classifier condition **in the portal** and read it back
   with Discovery.
3. **Save.** The policy now evaluates in simulation — it shows **what it *would* label** without
   applying anything.

**Gate 3:** `AL-Classifier-Pilot` exists, is in **simulation**, scoped to the pilot, applies the
target label, with `AL-Rule-Contracts` referencing the classifier. `CLSTRAIN-Validate.ps1` reports
**PASS** for policy-exists, mode-is-simulation, scope-is-pilot, rule-present, and
classifier/label-referenced (best-effort).
**Fail → rollback:** `Set-AutoSensitivityLabelPolicy -Identity AL-Classifier-Pilot -Mode Disable` (or
delete with `Remove-AutoSensitivityLabelPolicy`); simulation changes nothing.

---

## Phase 4 — Pilot & validate in simulation

1. Let the auto-labeling policy run in simulation over the pilot scope for the observation window
   (auto-labeling simulation processes existing content — allow time).
2. Review the **simulation results** (portal): which items the classifier matched and *would* have
   labeled. Run `.\CLSTRAIN-Report.ps1` to roll up policy modes and (where available) classification
   activity.
3. **Assess real-world accuracy:** spot-check the simulation matches against ground truth — does the
   classifier match the right documents in *your* estate (not just the test set)? Tune the seed/retrain
   (Phase 2) if the real-world precision disappoints.

**Gate 4 (pass/fail):** The classifier matched the intended content in simulation, real-world
precision meets the **R7** threshold, false positives triaged, and the target label/action confirmed
**in writing**. **Fail → do not enforce**; retrain/tune. Rollback unchanged from Phase 3.

---

## Phase 5 — Enforce, then expand

**Only after Gate 4 passes.**

1. **Move the auto-labeling policy out of simulation** to **enforce** (portal: turn the policy **On**;
   PowerShell: `Set-AutoSensitivityLabelPolicy -Identity AL-Classifier-Pilot -Mode Enable`), still
   scoped to the pilot first. (For a DLP/retention wiring, enforce that policy instead, per its own
   simulate-first pattern.)
2. **Confirm** the label is now actually applied to matching pilot content (allow processing time).
3. **Expand scope in rings.** Widen the auto-labeling scope (add the next users/sites), re-validate,
   and repeat. Consider renaming/cloning to a production policy (`AL-Classifier`) as you exit pilot.
4. **Reuse the classifier.** The same published classifier can now be referenced by **DLP** and
   **retention** — each wired **in simulation first** and validated before enforce.

**Gate 5:** On the pilot, matching content is labeled/acted-on as designed and non-matching content is
untouched; expansion rings each pass the same gate before widening.
**Fail → rollback:** return the policy to **simulation** (`Set-AutoSensitivityLabelPolicy -Mode
TestWithoutNotifications`) or **Disable** it — this stops auto-labeling at once — then diagnose per
`06-troubleshooting.md` before re-enforcing. (Note: labels already applied are not auto-removed —
plan re-labeling/label-change under change control if you must reverse applied labels.)

---

## Rollback summary (fast reference)

| Situation | Action |
|---|---|
| The classifier fails accuracy (R7) | Do **not** publish/enforce; add/clean seed samples, retrain, retest in the portal. |
| The wired policy labels the wrong content | Set `AL-Classifier-Pilot` to **simulation/test**, or **Disable** it; retrain the classifier or tighten the rule. |
| The whole wiring misbehaves | `Set-AutoSensitivityLabelPolicy -Identity AL-Classifier-Pilot -Mode Disable` (stops auto-labeling) or `-Mode TestWithoutNotifications` (back to simulation). |
| A user/site should not be in scope | Remove it from the policy scope (`SG-Classifier-Pilot`). |
| Labels wrongly applied need reversing | Plan a controlled re-label (labels applied are not auto-removed by disabling the policy) under change control. |
| Start over cleanly | `Remove-AutoSensitivityLabelRule` then `Remove-AutoSensitivityLabelPolicy`; delete/retrain the classifier in the portal. |

> Enforcement changes are **high-impact** — auto-labeling can apply **encrypting** labels. Make changes
> under change control, keep the pilot scope small, and never enforce a classifier that has not passed
> its accuracy gate (R7) in both the test set and the simulation pass.
