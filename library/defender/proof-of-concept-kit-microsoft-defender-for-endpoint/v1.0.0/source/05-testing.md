# 5. Testing Guide — Proof-of-Concept Kit: Microsoft Defender for Endpoint

Run these checks during the PoC (Steps 2–6 of the Implementation Guide). Each test has a **pass/fail gate**. All signal is **benign** (EICAR / Microsoft built-in simulation). Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Pilot onboarding
**Procedure:** Run `POCMDE-Enable.ps1 -WhatIf`, then after enabling, in `security.microsoft.com` → **Assets → Devices**, confirm each device in `MDE PoC – Pilot Ring – Pilot` shows **Onboarded**.
**Pass:** Every pilot device is onboarded and reporting.
**Fail:** A device stays "Can be onboarded" — see Troubleshooting *Pilot device not onboarding*.

## Test 2 — Benign signal generated
**Procedure:** Run `POCMDE-TestSignal.ps1` on a pilot device; confirm the EICAR file was written and quarantined, and that a built-in simulation was launched.
**Pass:** Microsoft Defender Antivirus detects/quarantines EICAR; the simulation runs. Only benign signal was used.
**Fail:** No AV reaction — see Troubleshooting *EICAR not detected*.

## Test 3 — Detection reached the portal
**Procedure:** Run `POCMDE-Validate.ps1`. In **Incidents & alerts**, confirm an alert from the pilot device (tagged/annotated `MDE-PoC-TESTSIGNAL`).
**Pass:** A real alert appears for the benign signal within your agreed latency window.
**Fail:** No alert — see Troubleshooting *No alert from test signal*.

## Test 4 — Device timeline richness
**Procedure:** Open the pilot **device page → Timeline** and confirm the EICAR/simulation activity is visible with process and file detail.
**Pass:** The timeline shows the test activity with context (process tree, file, user).
**Fail:** Timeline empty or sparse — see Troubleshooting *Timeline empty*.

## Test 5 — Advanced-hunting visibility
**Procedure:** `POCMDE-Validate.ps1` runs KQL over `DeviceEvents`, `AlertInfo`, and `AlertEvidence` for the pilot device.
**Pass:** Recent rows return for the pilot device covering the test signal.
**Fail:** Tables empty — allow warm-up time; see Troubleshooting *Hunting tables empty*.

## Test 6 — Automated investigation started (approval-gated)
**Procedure:** Open **Incidents → the test incident → Automated investigations**; `POCMDE-Validate.ps1` reports AIR status and automation level.
**Pass:** An automated investigation started and the pilot group's level is **Semi — require approval** (no unattended action taken).
**Fail:** No AIR, or automation acted unattended — see Troubleshooting *AIR did not start* / reset per Implementation Step 2.

## Test 7 — Scorecard produced
**Procedure:** Run `POCMDE-Scorecard.ps1` and confirm `MDE PoC Scorecard – Pilot Ring – Validate.json` is written with a pass/fail per criterion.
**Pass:** A complete scorecard maps every observation to your criteria.
**Fail:** Missing observations — re-run the relevant validate step first.

## Test 8 — Clean teardown
**Procedure:** Run `POCMDE-Teardown.ps1 -WhatIf`, then for real; re-run `POCMDE-Validate.ps1`.
**Pass:** Pilot devices are offboarded, the Intune policy removed, EICAR deleted, test alerts resolved — validate reports nothing left onboarded.
**Fail:** Residue remains — see Troubleshooting *Teardown left residue*.

---
### Exit gate
Tests 1–7 pass to call the PoC conclusive; Test 8 passes to close it out cleanly. Keep the scorecard file as the decision record.
