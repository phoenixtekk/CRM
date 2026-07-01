# 5. Testing Guide — MDM Migration Readiness Assessment & Wave Planning

Run these tests as you produce each artifact. The whole point is that the plan is **validated against
a pilot wave** before it scales (Tests 6–7), so no artifact is "done" until its gate passes.

## Test 1 — Inventory completeness
**Do:** Run `MDMRDY-Validation.ps1` against the `Estate Inventory – MDM Migration – Assess`.
**Expected:** No blank required fields (`DeviceName`, `Platform`, `OSVersion`, `EnrollmentType`,
`Owner`); no unknown platforms; stale check-ins flagged for review. Completeness at or above the
agreed threshold.

## Test 2 — Inventory matches the source
**Do:** Compare the inventory device count and platform mix against the source MDM console totals.
**Expected:** Counts reconcile within the agreed tolerance; any difference is explained by the scope
boundary (excluded/retired devices).

## Test 3 — Readiness scorecard is populated and sane
**Do:** Open the `Readiness Scorecard – MDM Migration – Assess`.
**Expected:** Every in-scope device has a readiness score 0–100; devices on unsupported OS or with
unknown app/profile coverage score low; recent, supported, enrolled devices score high.

## Test 4 — Risk register flags the real risks
**Do:** Open the `Risk Register – MDM Migration – Assess`.
**Expected:** Executive/critical, shared/kiosk, certificate/VPN-dependent, non-compliant, and stale
devices carry elevated risk with the contributing factors named; standard devices score low.

## Test 5 — Dependencies and waves are coherent
**Do:** Cross-check the `Dependency Map – MDM Migration – Assess` against the
`Wave Plan – MDM Migration – Configure` and `Wave Cohorts – MDM Migration – Configure`.
**Expected:** Devices that must move together share a wave; high-risk/low-readiness devices land in
later waves; the `Pilot Wave – MDM Migration – Pilot` is low-risk, high-readiness, and representative;
every device appears in exactly one wave.

## Test 6 — Cohort groups built correctly
**Do:** Run `MDMRDY-Set-WaveCohortTargeting.ps1`; inspect the per-wave membership output (and, if
created, the Entra security groups).
**Expected:** Each `Cohort Group – Per Wave – Configure` contains exactly its cohort's devices; no
device is in two groups; group names match the wave labels.

## Test 7 — Plan validated against the pilot wave (the gate)
**Do:** After the pilot migrates, re-run `MDMRDY-Discovery.ps1` and `MDMRDY-Report.ps1` over the
post-pilot estate and check the pilot's `Entry/Exit Criteria – Per Wave – Pilot`.
**Expected:** Pilot devices migrated, enrolled in the target, and compliant; predicted readiness/risk
matched the actual outcome; no open severity-1 issue. Scoring weights tuned if prediction missed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Assess pass** | Tests 1–4 pass; inventory reconciles to source; readiness and risk scored for every in-scope device |
| **Configure pass** | Test 5–6 pass; every device in exactly one wave; pilot wave is low-risk/high-readiness/representative; entry/exit criteria written per wave |
| **Pilot/Validate pass** | Test 7 passes; pilot wave meets its exit criteria and the readiness/risk model is confirmed before any expansion |
