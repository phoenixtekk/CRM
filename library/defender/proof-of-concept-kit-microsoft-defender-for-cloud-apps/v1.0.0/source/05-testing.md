# 5. Testing Guide — Proof-of-Concept Kit: Microsoft Defender for Cloud Apps

Run these checks during the PoC (Steps 2–6 of the Implementation Guide). Each test has a **pass/fail gate**. All signal is **benign** (Microsoft sample discovery log + benign policy-matching activity), and everything runs in **audit mode**. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Audit policy scoped
**Procedure:** Run `POCMDCA-Enable.ps1 -WhatIf`, then confirm `MDCA PoC Activity Policy – Pilot Users – Audit` exists, is scoped to the pilot group, and has **no governance action** (audit only).
**Pass:** The policy targets the pilot users only and takes no action.
**Fail:** Scope/action wrong — see Troubleshooting *Policy scope or action wrong*.

## Test 2 — Benign signal generated
**Procedure:** Run `POCMDCA-TestSignal.ps1`; confirm the sample discovery log uploaded and the benign policy-matching activity was performed.
**Pass:** Both benign signals were generated; no real data exfiltration used.
**Fail:** A signal did not generate — see Troubleshooting *Signal not generated*.

## Test 3 — Cloud Discovery report populated
**Procedure:** `Cloud apps → Cloud discovery → Dashboard` shows `MDCA PoC Discovery – Pilot – Report`; `POCMDCA-Validate.ps1` confirms discovery data.
**Pass:** The Shadow IT report populated from the sample log with app risk scores.
**Fail:** Empty report — see Troubleshooting *Discovery report empty*.

## Test 4 — Activity policy matched
**Procedure:** Confirm the audit policy matched the benign activity (`Cloud apps → Alerts` or the policy's matches); `POCMDCA-Validate.ps1` checks `AlertInfo`.
**Pass:** The policy matched and recorded the benign activity in audit mode.
**Fail:** No match — see Troubleshooting *Policy did not match*.

## Test 5 — Activity-log / hunting visibility
**Procedure:** `Cloud apps → Activity log` shows the benign activity; `POCMDCA-Validate.ps1` runs KQL over `CloudAppEvents`.
**Pass:** The activity is visible in the log and hunting returns recent rows.
**Fail:** Nothing visible — allow warm-up; see Troubleshooting *No activity visibility*.

## Test 6 — Alert surfaced
**Procedure:** Confirm an alert/anomaly surfaced for the policy match in **Incidents & alerts** / **Cloud apps → Alerts**.
**Pass:** An alert is raised (audit mode still alerts; it just does not govern).
**Fail:** No alert — see Troubleshooting *No alert surfaced*.

## Test 7 — Scorecard produced
**Procedure:** Run `POCMDCA-Scorecard.ps1` and confirm `MDCA PoC Scorecard – Pilot Users – Validate.json` is written with a pass/fail per criterion.
**Pass:** A complete scorecard maps every observation to your criteria.
**Fail:** Missing observations — re-run the relevant validate step first.

## Test 8 — Clean teardown
**Procedure:** Run `POCMDCA-Teardown.ps1 -WhatIf`, then for real; re-run `POCMDCA-Validate.ps1`.
**Pass:** The policy, discovery report, and connector are removed and test alerts resolved.
**Fail:** Residue remains — see Troubleshooting *Teardown left residue*.

---
### Exit gate
Tests 1–7 pass to call the PoC conclusive; Test 8 passes to close it out cleanly. Keep the scorecard file as the decision record.
