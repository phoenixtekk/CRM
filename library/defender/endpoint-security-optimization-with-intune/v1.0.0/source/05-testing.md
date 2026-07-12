# 5. Testing Guide — optimization: Endpoint Security with Microsoft Intune

Run these checks after tuning the pilot ring (Implementation Steps 2–6), and again after each expansion wave. Each test has a **pass/fail gate**; do not expand across the estate until the pilot passes. Objects are referenced by the exact names from the Implementation Guide, and the headline gates are **before/after deltas** against the saved baseline.

## Test 1 — Before-state baseline captured
**Procedure:** Confirm `sopeis-baseline.json` exists from `SOPEIS-Report.ps1 -SaveBaseline` (Implementation Step 1).
**Pass:** A baseline with conflict/error counts, non-compliant proportion, and coverage % exists.
**Fail:** No baseline — re-run Step 1; without a "before" there is no measurable improvement. See Troubleshooting *No baseline / report empty*.

## Test 2 — Latest security-baseline version applied on the pilot ring
**Procedure:** Run `SOPEIS-Validate.ps1`. In **Endpoint security → Security baselines**, confirm `Security Baseline – Pilot Ring – Pilot` is on the **latest** version and assigned to `Intune Optimize – Pilot Ring – Pilot`.
**Pass:** The pilot ring runs the latest baseline version and the old baseline no longer targets the ring.
**Fail:** Old version still applied, or both baselines target the ring — re-run Implementation Step 2; see Troubleshooting *Baseline migration not applying*.

## Test 3 — Conflicts/errors reduced on the pilot ring
**Procedure:** Run `SOPEIS-ConflictReport.ps1` scoped to the pilot ring and compare the conflict/error count to the Test 1 baseline.
**Pass:** Conflict/error count on the pilot ring is **measurably lower** (target: near zero) than baseline.
**Fail:** Conflicts unchanged or higher — a setting is still set by more than one policy; see Troubleshooting *Conflict persists after consolidation*.

## Test 4 — Compliance false-positives reduced, real gaps still caught
**Procedure:** Run `SOPEIS-Report.ps1 -BaselinePath .\sopeis-baseline.json`. Compare the non-compliant proportion to baseline, and spot-check that a genuinely non-compliant device (e.g. encryption off) still fails.
**Pass:** False non-compliant flags are **lower** than baseline, and a real gap still marks the device non-compliant.
**Fail:** No reduction, or a real gap now passes (over-loosened) — re-tune the compliance policy; see Troubleshooting *Compliance tuned too loose/tight*.

## Test 5 — Conditional Access impact modeled before enforce
**Procedure:** In **Entra → Conditional Access**, confirm `CA – Require Compliant Device – ReportOnly` is **Report-only** and review its results / What-If for the pilot ring.
**Pass:** The compliance grant is report-only and the modeled block list contains no unexpected users.
**Fail:** CA is already enforcing, or the model shows unexpected blocks — keep it report-only and re-tune; see Troubleshooting *Unexpected Conditional Access blocks*.

## Test 6 — Coverage expanded
**Procedure:** Run `SOPEIS-Validate.ps1` and review the coverage section. Compare devices receiving baseline/compliance/Defender policy to the baseline.
**Pass:** Coverage % per policy type is **higher** than baseline; previously unassigned devices now receive policy.
**Fail:** Coverage unchanged, or devices now double-targeted — confirm the assignment model; see Troubleshooting *Coverage gap / double assignment*.

## Test 7 — No new conflicts introduced by expansion
**Procedure:** Run `SOPEIS-ConflictReport.ps1` after the assignment changes.
**Pass:** Expanding coverage did **not** re-introduce conflicts (each setting still has one authoritative policy).
**Fail:** New conflicts appeared — an added assignment overlaps an existing policy; see Troubleshooting *Conflict persists after consolidation*.

## Test 8 — Policies propagate to pilot devices
**Procedure:** Run `SOPEIS-Validate.ps1` and, on a pilot device, force an Intune sync and confirm the baseline/compliance policy shows applied.
**Pass:** Pilot devices report the tuned policies as applied (allowing check-in time).
**Fail:** Devices stuck pending/not applied — see Troubleshooting *Policy stuck pending / not applying*.

---
### Exit gate
All eight tests pass on the pilot ring — with a **measurable before/after improvement** in Test 3, Test 4, and Test 6 — **before** any estate-wide expansion (Implementation Step 7). Conditional Access is moved from report-only to enforce **last**, only after the identity team accepts the modeled impact. Re-run Tests 2–8 after each expansion wave and compare against the re-saved baseline.
