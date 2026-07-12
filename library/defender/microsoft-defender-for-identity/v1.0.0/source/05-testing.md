# 5. Testing Guide — Microsoft Defender for Identity

Validate each phase before moving to the next. Every test has a **pass/fail gate**; do not expand to the remaining domain controllers until the pilot passes all phases. Objects are referenced by the exact names from the Implementation Guide.

## Part A — Deploy validation (Phase A)

### A1 — DSA configured
**Procedure:** Run `MDIFULL-Validate.ps1 -Check DSA`. In **Settings → Identities → Directory Service accounts**, confirm `MDI Directory Service Account – Tenant – Prod` is present.
**Pass:** The DSA (gMSA) is registered and the sensor can retrieve its password.
**Fail:** DSA missing or password-retrieval fails — see Troubleshooting *DSA not working*.

### A2 — Pilot sensor healthy
**Procedure:** Run `MDIFULL-Validate.ps1 -Check Sensor`. In **Settings → Identities → Sensors**, confirm `MDI Sensor Host – Pilot DC – Pilot` is **Running / Healthy**.
**Pass:** The pilot sensor is healthy and reporting; no health alerts against it.
**Fail:** Sensor "Unhealthy / Not configured / Stopped" — see Troubleshooting *Sensor unhealthy*.

### A3 — Sensitive entities tagged
**Procedure:** Run `MDIFULL-Validate.ps1 -Check Sensitive`. In **Entity tags → Sensitive**, confirm the `MDI Sensitive Entities – Tier0 – Prod` accounts/groups/servers are tagged.
**Pass:** All planned Tier-0 entities are tagged sensitive.
**Fail:** Tier-0 entities missing — re-apply per Implementation Step 4.

### A4 — Honeytokens tagged
**Procedure:** Run `MDIFULL-Validate.ps1 -Check Honeytoken`. In **Entity tags → Honeytoken**, confirm `MDI Honeytoken – Decoy Identity – Pilot` is tagged.
**Pass:** The decoy account(s) are tagged and remain unused.
**Fail:** Not tagged, or the account shows real usage — re-apply per Implementation Step 5 and confirm nothing legitimate uses the account.

### A5 — Identity signal streaming
**Procedure:** Run `MDIFULL-Validate.ps1 -Check Signal` to execute `MDI Detection Validation – Tenant – Validate`. Confirm `IdentityInfo`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, and `IdentityQueryEvents` return recent rows.
**Pass:** All four identity tables stream from the pilot sensor.
**Fail:** A table is empty — see Troubleshooting *No identity signal*.

### A6 — A detection actually fires
**Procedure:** Trigger a benign, controlled detection (honeytoken touch or Microsoft-documented safe simulation). In **Incidents & alerts**, confirm the resulting alert appears.
**Pass:** The controlled test produces a visible MDI alert within the expected window.
**Fail:** No alert — see Troubleshooting *Detection does not fire*.

### A7 — ISPM recommendations present
**Procedure:** Run `MDIFULL-Report.ps1 -SaveBaseline`. In **Secure Score → Recommended actions** (Identity), confirm MDI ISPM recommendations are listed and the `MDI ISPM Shortlist – Tier0 – Prod` is captured.
**Pass:** ISPM recommendations appear and a posture baseline is recorded.
**Fail:** No recommendations — allow warm-up, confirm sensor health (A2), re-run; see Troubleshooting *No ISPM recommendations*.

### A8 — Response actions approval-gated
**Procedure:** Run `MDIFULL-Report.ps1` and confirm response actions are approval-gated (not automatic) per Implementation Step 7.
**Pass:** No response action auto-executes; actions require approval.
**Fail:** Automation is higher than agreed — reset per Implementation Step 7 and confirm with the SOC.

**Phase A exit gate:** A1–A8 pass on the pilot DC before enabling the team.

## Part B — Team enablement (Phase B knowledge-check)

Score each attendee; passing = correct on at least **8 of 10**.

1. **Sensors:** Which servers host MDI sensors and what does each observe? *(DCs, AD CS, AD FS/Entra Connect — authentication and directory traffic/behavior.)*
2. **Attack path:** On an entity page, where are lateral-movement paths and the investigation-priority score, and what do they mean?
3. **Detection families:** Name the four families with one detection each *(recon, compromised credentials, lateral movement, domain dominance)*.
4. **MITRE:** Map Pass-the-Ticket and DCSync to their MITRE tactics *(Lateral Movement; Credential Access)*.
5. **Honeytoken:** What makes a good honeytoken and why is any activity on it high-fidelity?
6. **Hunting:** Which advanced-hunting tables hold identity telemetry? *(IdentityLogonEvents, IdentityQueryEvents, IdentityDirectoryEvents, IdentityInfo.)*
7. **ISPM:** Give two recommendations and the risk each addresses.
8. **Investigation:** Outline the steps to investigate a suspicious identity from entity page to advanced hunting.
9. **Response & governance:** What are the MDI response actions and **who** must approve them?
10. **Boundary:** Which decisions in an identity incident belong to the SOC/security team rather than the tool operator?

**Capstone (per attendee, unaided, on a second entity/alert):** open the entity page and read the timeline + lateral-movement path; run one saved hunting query and interpret a result; state the recommended response action and the required approval.

**Phase B exit gate:** every attendee meets ≥8/10 and completes the capstone; the take-home artefacts exist (the saved queries `Recon/LateralMovement/Honeytoken/Investigation – Identity – Hunt`, the honeytoken tag, the `MDI ISPM Shortlist – Tier0 – Prod`, and the `MDI Investigation – Identity – Validate` doc).

## Part C — PoC validation (Phase C)

### C1 — Benign recon signal generated
**Procedure:** From the test workstation/account, run `MDIFULL-TestSignal.ps1`; confirm the enumeration commands and the honeytoken touch completed.
**Pass:** The benign read-only enumeration ran and the honeytoken was touched. No attack tooling used.
**Fail:** Commands blocked — confirm the test account can query AD; see Troubleshooting *Recon signal not generated*.

### C2 — Reconnaissance alert reached the portal
**Procedure:** Run `MDIFULL-Validate.ps1 -Check Signal`. In **Incidents & alerts**, confirm a reconnaissance-type alert from the pilot activity.
**Pass:** A real reconnaissance alert appears within your agreed latency window.
**Fail:** No alert — see Troubleshooting *No reconnaissance alert*.

### C3 — Honeytoken activity flagged
**Procedure:** Confirm the honeytoken touch raised an alert / is highlighted; `MDIFULL-Validate.ps1 -Check Signal` checks `AlertInfo` and identity events.
**Pass:** Activity against `MDI Honeytoken – Decoy Identity – Pilot` is flagged as high-fidelity.
**Fail:** Not flagged — see Troubleshooting *Honeytoken not flagged*.

### C4 — Identity timeline & hunting visibility
**Procedure:** Open the identity page → **Timeline**; `MDIFULL-Validate.ps1 -Check Signal` runs KQL over the identity tables.
**Pass:** The timeline shows the test activity and hunting tables return recent rows.
**Fail:** Timeline/tables empty — allow warm-up; see Troubleshooting *No identity signal*.

### C5 — Scorecard produced
**Procedure:** Run `MDIFULL-Report.ps1 -Scorecard` and confirm `MDI PoC Scorecard – Pilot DC – Validate.json` is written with a pass/fail per criterion.
**Pass:** A complete scorecard maps every observation to your criteria.
**Fail:** Missing observations — re-run the relevant validate step first.

### C6 — Clean PoC teardown
**Procedure:** Run `MDIFULL-Deploy.ps1 -Rollback -WhatIf`, then for real; re-run `MDIFULL-Validate.ps1`.
**Pass:** PoC-only decoys untagged, `MDI-TESTSIGNAL` alerts resolved, no PoC-only residue; production sensor and retained artefacts intact.
**Fail:** Residue remains — see Troubleshooting *Teardown left residue*.

**Phase C exit gate:** C1–C5 pass to call the PoC conclusive; C6 passes to close it out cleanly. Keep the scorecard file as the decision record.

---
### Overall exit gate
All Phase A tests, the Phase B knowledge-check, and Phase C tests pass on the pilot **before** expanding to the remaining domain controllers (Implementation Step 11). Re-run A2, A5, A6, and A7 after each sensor-expansion wave and compare against the saved posture baseline.
