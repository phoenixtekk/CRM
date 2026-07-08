# Troubleshooting — Trainable Classifiers

The failures you will actually hit, with the most likely cause and the fix. Work top-down: **most
"the classifier isn't working" reports trace back to seed quality, the classifier not being wired into
a control, accuracy tuning, or simulation-vs-enforce confusion — not a portal bug.** Where a portal
path or cmdlet parameter is named, **verify it against your tenant** — trainable classifiers and
auto-labeling evolve.

---

## 1. "I published the classifier but nothing happens"

**Symptoms:** The classifier is published, yet no content is being labeled/protected.

**Fix — this is the #1 cause.**
- **A published classifier does nothing on its own.** It must be **wired into a control** —
  auto-labeling, DLP, or retention — to have any effect. Build the wiring (Phase 3):
  `CLSTRAIN-Configure.ps1` creates the auto-labeling policy in simulation.
- **Confirm the classifier is actually referenced** as the rule's condition (`CLSTRAIN-Validate.ps1`
  B6 reminds you to verify this in the portal — PowerShell does not always expose the classifier
  condition).
- **Check the wired policy's mode.** In **simulation**, it records what it *would* label but applies
  nothing — that is expected until you enforce (Phase 5). `CLSTRAIN-Validate.ps1` gate **B2** shows the
  mode.

---

## 2. The classifier won't train / stays "training"

**Symptoms:** Training does not complete, or takes a very long time.

**Likely causes & fixes**
- **Too few seed samples.** A trainable classifier needs a meaningful minimum of positive examples —
  **verify the current minimum/recommended counts for your tenant** (R3). Too few samples stalls or
  weakens training. Add more representative samples to the seed site and retrain.
- **Seed content not readable/mixed.** The seed SharePoint site must be reachable and contain
  documents of a **single** category. Remove off-category items.
- **Processing time.** Training is **not** instant — allow the time Microsoft indicates before
  concluding it failed.

---

## 3. Low accuracy at the Test stage

**Symptoms:** In the **Test** stage the classifier's accuracy is below your R7 threshold.

**Likely causes & fixes**
- **Weak or unrepresentative seed set.** Add more, cleaner, more varied positive examples that reflect
  the real estate; retrain. Quality of seed = quality of classifier.
- **Test set not truly independent / mislabeled ground truth.** The test items must be **separate**
  from the seed set and correctly pre-categorized (R4). A wrong ground truth makes a good classifier
  look bad (or vice-versa).
- **Category too broad or overlapping.** If the category blends with others, the model can't
  discriminate — narrow the definition or split into multiple classifiers.
- **Do not publish below threshold.** Retrain and retest — never lower the R7 bar to force a publish
  (Gate A). The tolerance should match impact (audit-only can tolerate more error than an encrypting
  auto-label).

---

## 4. The classifier matches the wrong content in the real world (false positives)

**Symptoms:** Test-stage accuracy looked fine, but the **simulation** over the real estate matches
documents that are not the target category.

**Likely causes & fixes**
- **Test set didn't reflect production variety.** The real estate has content the test set lacked. Add
  representative real-world negatives/positives to the seed and retrain.
- **Threshold/impact mismatch.** If the classifier feeds an **encrypting** auto-label, even modest
  false positives are costly — hold in **simulation**, retrain, and only enforce when real-world
  precision meets R7 (Gate A4).
- **Tune in simulation** — never by loosening an already-enforcing control.

---

## 5. A built-in classifier isn't available / behaves differently than expected

**Symptoms:** The built-in classifier you wanted isn't in the list, or matches differently.

**Likely causes & fixes**
- **Catalog varies and evolves.** The set of built-in classifiers depends on licensing and changes
  over time — **verify the current catalog for your tenant** (R6). If a needed category has no
  built-in, build a **custom** classifier.
- **Built-in classifiers can't be edited.** You cannot retrain a Microsoft built-in classifier; if its
  behaviour doesn't fit, build a custom one for that category.

---

## 6. `New-AutoSensitivityLabelPolicy` / label errors

**Symptoms:** Creating the wiring policy errors on the label, mode, or location.

**Likely causes & fixes**
- **Label not published.** `-ApplySensitivityLabel` must reference a **published** sensitivity label.
  Confirm the label exists and is published (`CLSTRAIN-Discovery.ps1` inventories labels).
- **Mode/location parameter names evolve.** **Verify the simulation Mode value and the location
  parameters against `Get-Help New-AutoSensitivityLabelPolicy -Full` for your tenant.** The
  `CLSTRAIN-Configure.ps1` script prints the plan so you can verify before `-Commit`.
- **Prefer the portal for the first build** if parameter names are uncertain, then read it back with
  `CLSTRAIN-Discovery.ps1`.

---

## 7. Can't reference the classifier as a rule condition in PowerShell

**Symptoms:** The rule is created but you can't attach the trainable-classifier condition via cmdlet.

**Fix**
- **The classifier-condition parameter shape evolves and isn't always cleanly scriptable.** Attach the
  **trainable-classifier condition in the portal** on `AL-Rule-Contracts`, then read it back with
  `CLSTRAIN-Discovery.ps1`. `CLSTRAIN-Configure.ps1` deliberately creates the rule **shell** and flags
  that the classifier condition must be attached/verified — it does **not** invent a parameter.
- Run `Get-Help New-AutoSensitivityLabelRule -Full` to check the current condition parameters for your
  tenant.

---

## 8. Simulation looks fine but enforcement doesn't label

**Symptoms:** In simulation the classifier matches; after "turning it on," content isn't labeled.

**Likely causes & fixes**
- **Policy still in a Test mode.** Move it out of simulation: portal → turn **On**; PowerShell →
  `Set-AutoSensitivityLabelPolicy -Identity AL-Classifier-Pilot -Mode Enable`. `CLSTRAIN-Validate.ps1`
  gate **B2** shows the mode.
- **Processing time.** Auto-labeling at enforce processes content over time — it is **not** instant.
  Wait, then re-check.
- **Out of scope.** Enforcement applies only to the policy's scope; confirm with
  `CLSTRAIN-ScopeHealth.ps1`.

---

## 9. Wrongly-applied labels need reversing

**Symptoms:** Enforcement applied labels to content that shouldn't have them.

**Fix**
- **Disabling the policy does NOT remove already-applied labels.** `Set-AutoSensitivityLabelPolicy
  -Mode Disable` stops *new* labeling but existing labels remain. Plan a controlled **re-label / label
  change** under change control to reverse them.
- Then fix the root cause (retrain the classifier / tighten the rule) **in simulation** before
  re-enforcing — this is exactly why the accuracy gate (R7) and simulation pass exist.

---

## 10. Activity report is empty or export fails

**Symptoms:** `CLSTRAIN-Report.ps1` returns no activity, or the Activity Explorer export warns/skips.

**Likely causes & fixes**
- **Licensing/permission.** `Export-ActivityExplorerData` is licensing-dependent; the script **warns
  and degrades to policy-modes only.** Fall back to **Purview → Activity explorer**, and review the
  **auto-labeling simulation results** in the portal (that is where would-be-labeled items are shown).
- **Quiet/early window.** Simulation results take time to populate; allow processing time or widen
  `-Days`.

---

## When to escalate to the determination owners (not a technical fix)

Some questions are **not** troubleshooting — they are **determinations** that belong to compliance /
records / data owners (see `global-requirements-purview.md` §5):

- Is *this accuracy* good enough to enforce? → the **R7** data owner / approver.
- *Which* label should this category receive? → **compliance / information-protection owners**.
- Is *this content* in scope for classification? → **data owners**.

Provide them the **evidence** (Test-stage accuracy, simulation results, `CLSTRAIN-Report.ps1`, the
validation output) — not a verdict.
