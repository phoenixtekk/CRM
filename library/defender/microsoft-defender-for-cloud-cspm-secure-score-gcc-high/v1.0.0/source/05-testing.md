# 5. Testing Guide — Microsoft Defender for Cloud: CSPM & Secure Score Remediation

Run these checks after enabling CSPM and completing a first remediation batch on the pilot subscription (Implementation Steps 2–8), and again after each expansion wave. Each test has a **pass/fail gate**; do not expand across the estate until the pilot passes. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Defender CSPM enabled
**Procedure:** Run `DEFCSPMG-Validate.ps1`. In **Environment settings → `CSPM Scope – Pilot Sub – Pilot` → Defender plans**, confirm **Defender CSPM = On** (and foundational CSPM on).
**Pass:** Defender CSPM is on for the pilot subscription.
**Fail:** Plan shows Off/Free — re-run Implementation Step 2; see Troubleshooting *Defender CSPM not enabling*.

## Test 2 — Agentless scanning on
**Procedure:** Run `DEFCSPMG-Validate.ps1` and confirm agentless scanning is enabled under Defender CSPM settings.
**Pass:** Agentless scanning is enabled and (allowing warm-up) machine assessments appear.
**Fail:** Disabled or no assessments — see Troubleshooting *No agentless scan results*.

## Test 3 — Regulatory-compliance dashboard renders
**Procedure:** `portal.azure.us` → **Regulatory compliance**. Confirm the assigned standard(s) render control pass/fail for the pilot subscription.
**Pass:** The dashboard shows the assigned standard with control status.
**Fail:** Empty or no standard assigned — confirm Step 4; see Troubleshooting *Compliance dashboard empty*.

## Test 4 — Secure Score moved after remediation
**Procedure:** Run `DEFCSPMG-Report.ps1 -BaselinePath .\defcspm-baseline.json`. Compare the current Secure Score to the Step 1 baseline after your first remediation batch.
**Pass:** Secure Score is **higher** than the baseline (or the remaining recommendations are demonstrably lower risk).
**Fail:** No movement — confirm the fixes applied and allow re-assessment time; see Troubleshooting *Secure Score not moving*.

## Test 5 — Attack paths queryable
**Procedure:** Run `DEFCSPMG-Hunt.ps1 -Mode AttackPaths`. Confirm attack-path / risk data returns via Azure Resource Graph.
**Pass:** Attack-path or high-risk recommendation data is returned (Defender CSPM active).
**Fail:** No data — confirm Defender CSPM is on and allow warm-up; see Troubleshooting *No attack-path data*.

## Test 6 — Governance rule and exemptions in place
**Procedure:** Run `DEFCSPMG-Validate.ps1`. In **Governance rules**, confirm `Secure Score Remediation – Pilot Sub – Prod` exists; in **Recommendations → Exemptions**, confirm any exemption is named `CSPM Exemption – <recommendation> – Prod` with a justification and **expiry**.
**Pass:** The governance rule assigns owners/due dates and every exemption is time-bound and justified.
**Fail:** No governance rule, or a permanent/unjustified exemption — see Troubleshooting *Exemption without expiry*.

## Test 7 — Continuous export flowing
**Procedure:** Run `DEFCSPMG-Validate.ps1`. In the Log Analytics workspace, confirm `SecurityRecommendation` / Secure Score data is arriving from `CSPM Continuous Export – Pilot Sub – Prod`.
**Pass:** Recommendation and Secure Score data land in the workspace.
**Fail:** No data — confirm the export config and workspace permissions; see Troubleshooting *Continuous export no data*.

## Test 8 — Posture baseline saved for trending
**Procedure:** Run `DEFCSPMG-Report.ps1 -SaveBaseline`. Confirm the current Secure Score and recommendation counts are written to the baseline file.
**Pass:** A posture baseline exists to trend against each cycle.
**Fail:** No score returned — allow assessment warm-up, then re-run; see Troubleshooting *Secure Score empty*.

---
### Exit gate
All eight tests pass on the pilot subscription **before** any estate-wide or multicloud expansion (Implementation Step 9). Re-run Tests 1–4, 7, and 8 after each expansion wave and compare against the saved baseline.
