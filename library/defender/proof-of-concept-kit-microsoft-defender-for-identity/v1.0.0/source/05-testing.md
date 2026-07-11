# 5. Testing Guide — Proof-of-Concept Kit: Microsoft Defender for Identity

Run these checks during the PoC (Steps 2–6 of the Implementation Guide). Each test has a **pass/fail gate**. All signal is **benign** (read-only enumeration + a honeytoken decoy). Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Pilot sensor healthy
**Procedure:** Run `POCMDI-Enable.ps1 -WhatIf`; after install, in **Settings → Identities → Sensors**, confirm `MDI PoC Sensor – Pilot DC – Pilot` shows **Running / Healthy**.
**Pass:** The sensor is healthy and the DSA is configured.
**Fail:** Sensor "Not configured / Unhealthy" — see Troubleshooting *Sensor unhealthy*.

## Test 2 — Honeytoken tagged
**Procedure:** In **Settings → Identities → Entity tags → Honeytoken**, confirm `MDI PoC Honeytoken – Pilot` is tagged.
**Pass:** The decoy account is tagged as a honeytoken.
**Fail:** Not tagged — re-run Implementation Step 2.6; see Troubleshooting *Honeytoken not flagged*.

## Test 3 — Benign recon signal generated
**Procedure:** From the test workstation/account, run `POCMDI-TestSignal.ps1`; confirm the enumeration commands and the honeytoken touch completed.
**Pass:** The benign read-only enumeration ran and the honeytoken was touched. No attack tooling used.
**Fail:** Commands blocked — confirm the test account can query AD; see Troubleshooting *Recon signal not generated*.

## Test 4 — Reconnaissance alert reached the portal
**Procedure:** Run `POCMDI-Validate.ps1`. In **Incidents & alerts**, confirm a reconnaissance-type alert from the pilot activity.
**Pass:** A real reconnaissance alert appears within your agreed latency window.
**Fail:** No alert — see Troubleshooting *No reconnaissance alert*.

## Test 5 — Honeytoken activity flagged
**Procedure:** Confirm the honeytoken touch raised an alert / is highlighted; `POCMDI-Validate.ps1` checks `AlertInfo` and identity events.
**Pass:** Activity against `MDI PoC Honeytoken – Pilot` is flagged as high-fidelity.
**Fail:** Not flagged — see Troubleshooting *Honeytoken not flagged*.

## Test 6 — Identity timeline & hunting visibility
**Procedure:** Open the identity page → **Timeline**; `POCMDI-Validate.ps1` runs KQL over `IdentityQueryEvents`, `IdentityLogonEvents`, `IdentityDirectoryEvents`.
**Pass:** The timeline shows the test activity and hunting tables return recent rows.
**Fail:** Timeline/tables empty — allow warm-up; see Troubleshooting *Hunting tables empty*.

## Test 7 — Scorecard produced
**Procedure:** Run `POCMDI-Scorecard.ps1` and confirm `MDI PoC Scorecard – Pilot DC – Validate.json` is written with a pass/fail per criterion.
**Pass:** A complete scorecard maps every observation to your criteria.
**Fail:** Missing observations — re-run the relevant validate step first.

## Test 8 — Clean teardown
**Procedure:** Run `POCMDI-Teardown.ps1 -WhatIf`, then for real; re-run `POCMDI-Validate.ps1`.
**Pass:** The honeytoken is untagged, the sensor uninstalled, the DSA removed (if PoC-only), and test alerts resolved.
**Fail:** Residue remains — see Troubleshooting *Teardown left residue*.

---
### Exit gate
Tests 1–7 pass to call the PoC conclusive; Test 8 passes to close it out cleanly. Keep the scorecard file as the decision record.
