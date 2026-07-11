# 5. Testing Guide — Proof-of-Concept Kit: Microsoft Defender for Cloud

Run these checks during the PoC (Steps 2–6 of the Implementation Guide). Each test has a **pass/fail gate**. All signal is **benign** (sample alerts + a benign misconfigured test resource + EICAR). Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Defender plan enabled on the pilot subscription
**Procedure:** Run `POCMDC-Enable.ps1 -WhatIf`, then confirm CSPM + the chosen workload plan show **On** for the pilot subscription only.
**Pass:** The plans are on for the pilot subscription and no other.
**Fail:** Plan off or wrong scope — see Troubleshooting *Plan not enabling*.

## Test 2 — Benign signal generated
**Procedure:** Run `POCMDC-TestSignal.ps1`; confirm sample alerts were created, the benign test resource deployed, and (optionally) EICAR dropped on a pilot VM.
**Pass:** All benign signals were generated; no real attack/malware used.
**Fail:** A signal did not generate — see Troubleshooting *Signal not generated*.

## Test 3 — Recommendation raised (CSPM)
**Procedure:** **Microsoft Defender for Cloud → Recommendations**; `POCMDC-Validate.ps1` confirms an assessment for the misconfigured `MDC PoC Test Resource – Pilot RG – Pilot`.
**Pass:** A recommendation is raised for the benign misconfiguration.
**Fail:** No recommendation — allow warm-up; see Troubleshooting *No recommendation*.

## Test 4 — Secure Score reflects posture
**Procedure:** **Microsoft Defender for Cloud → Secure Score**; `POCMDC-Validate.ps1` returns the score.
**Pass:** A Secure Score is present and reflects the pilot posture.
**Fail:** No score — allow warm-up; see Troubleshooting *No Secure Score*.

## Test 5 — Security alert fired
**Procedure:** **Microsoft Defender for Cloud → Security alerts**; `POCMDC-Validate.ps1` checks `Get-AzSecurityAlert` for the sample + EICAR alerts.
**Pass:** The sample alert(s) and (if used) the EICAR alert appear.
**Fail:** No alert — see Troubleshooting *No security alert*.

## Test 6 — Regulatory-compliance data populated
**Procedure:** **Microsoft Defender for Cloud → Regulatory compliance**; confirm the default benchmark shows control status for the pilot subscription.
**Pass:** Compliance data is visible for the pilot subscription.
**Fail:** Empty — allow warm-up; see Troubleshooting *No compliance data*.

## Test 7 — Scorecard produced
**Procedure:** Run `POCMDC-Scorecard.ps1` and confirm `MDC PoC Scorecard – Pilot Sub – Validate.json` is written with a pass/fail per criterion.
**Pass:** A complete scorecard maps every observation to your criteria.
**Fail:** Missing observations — re-run the relevant validate step first.

## Test 8 — Clean teardown (and billing stopped)
**Procedure:** Run `POCMDC-Teardown.ps1 -WhatIf`, then for real; re-run `POCMDC-Validate.ps1`.
**Pass:** The test resource is deleted, the Defender plan is **Off** (billing stopped), and sample alerts resolved.
**Fail:** Residue or plan still on — see Troubleshooting *Teardown left residue*.

---
### Exit gate
Tests 1–7 pass to call the PoC conclusive; Test 8 passes to close it out cleanly **and stop billing**. Keep the scorecard file as the decision record.
