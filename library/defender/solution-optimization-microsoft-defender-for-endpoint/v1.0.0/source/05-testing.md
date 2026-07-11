# 5. Testing Guide — Solution Optimization: Microsoft Defender for Endpoint

Run these checks after tuning the pilot ring (Implementation Steps 2–6), and again after each expansion wave. Each test has a **pass/fail gate**; do not expand across the estate until the pilot passes. Objects are referenced by the exact names from the Implementation Guide, and the headline gates are **before/after deltas** against the saved baseline.

## Test 1 — Before-state baseline captured
**Procedure:** Confirm `sopmde-baseline.json` exists from `SOPMDE-Report.ps1 -SaveBaseline` (Implementation Step 1).
**Pass:** A baseline with alert volume, false-positive proportion, ASR block coverage, and onboarding/sensor-health coverage exists.
**Fail:** No baseline — re-run Step 1; without a "before" there is no measurable improvement. See Troubleshooting *No baseline / report empty*.

## Test 2 — ASR rules blocking on the pilot ring
**Procedure:** Run `SOPMDE-Validate.ps1`. In **Intune → Endpoint security → Attack surface reduction → `ASR Hardening – Pilot Ring – Pilot`** (or the Defender-portal policy), confirm the vetted rules show **Block**.
**Pass:** The intended ASR rules are in **Block** on the pilot ring and the policy is assigned to `MDE Optimize – Pilot Ring – Pilot`.
**Fail:** Rules still show Audit/Not configured, or unassigned — re-run Implementation Step 2; see Troubleshooting *ASR rule not blocking*.

## Test 3 — No legitimate app broke under ASR block
**Procedure:** Run `SOPMDE-Hunt.ps1 -Mode ASRAudit -BlockedOnly`. Review ASR **block** events on the pilot ring for any business application.
**Pass:** Only intended (malicious/unwanted) behaviour is blocked; no business-critical app is broken.
**Fail:** A legitimate app is blocked — add a scoped exclusion or revert that rule to audit (rollback); see Troubleshooting *ASR blocking a legitimate app*.

## Test 4 — Alert noise / false positives reduced
**Procedure:** Run `SOPMDE-Report.ps1 -BaselinePath .\sopmde-baseline.json`. Compare current alert volume and false-positive proportion to the Test 1 baseline after the tuning pass.
**Pass:** Alert volume and/or false-positive proportion is **measurably lower** than baseline, with no new blind spot from over-suppression.
**Fail:** No reduction — confirm suppressions/indicators applied and are scoped correctly; see Troubleshooting *Noise not dropping*.

## Test 5 — Suppressions are scoped and time-bound
**Procedure:** Run `SOPMDE-Validate.ps1`. In **Incidents & alerts → suppression rules** and **Settings → Endpoints → Indicators**, confirm each is named `FP Suppression – <detection> – Prod` / `Allow Indicator – <object> – Prod` with a justification and review date.
**Pass:** Every suppression/indicator is narrowly scoped, justified, and has a review date.
**Fail:** A broad or permanent suppression exists — tighten or add an expiry; see Troubleshooting *Over-broad suppression*.

## Test 6 — Coverage expanded (onboarding + sensor health)
**Procedure:** Run `SOPMDE-Validate.ps1` and `SOPMDE-Hunt.ps1 -Mode Coverage`. Compare onboarded/active device count to the baseline.
**Pass:** Onboarding and **sensor health = Active** coverage is **higher** than baseline; previously missing devices now report.
**Fail:** Coverage unchanged or devices still Inactive/Misconfigured — see Troubleshooting *Device not onboarding / sensor unhealthy*.

## Test 7 — Tamper protection, EDR block mode, and web filtering on
**Procedure:** Run `SOPMDE-Validate.ps1`. Confirm **Tamper Protection = On**, **EDR in block mode = On**, and `Web Filtering – All Devices – Prod` is active for the pilot ring.
**Pass:** All three hardening controls are enabled and applied to the pilot ring.
**Fail:** One is off/unapplied — re-run Implementation Step 5; see Troubleshooting *Hardening not applying*.

## Test 8 — Device tags and groups resolve correctly
**Procedure:** Run `SOPMDE-Validate.ps1`. In **Assets → Devices**, filter by the applied tag and confirm the pilot devices resolve into the intended device group.
**Pass:** Tags/groups target the right devices, so policy and RBAC scope correctly.
**Fail:** Tags missing or group empty — confirm the tag scheme/dynamic rule (Implementation Step 4); see Troubleshooting *Tags/groups not resolving*.

---
### Exit gate
All eight tests pass on the pilot ring — with a **measurable before/after improvement** in Test 4 and Test 6 — **before** any estate-wide expansion (Implementation Step 7). Re-run Tests 2–7 after each expansion wave and compare against the re-saved baseline.
