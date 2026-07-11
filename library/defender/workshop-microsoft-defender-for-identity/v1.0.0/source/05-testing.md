# 5. Testing & Knowledge-Check — Workshop: Microsoft Defender for Identity

Testing a workshop means two things: (1) confirming each lab's **pass gate** was met, and (2) a **knowledge-check** that each attendee can operate MDI unaided. Use the lab-helper scripts by name to validate the environment; use the check-questions to validate the people.

## Part A — Environment / lab validation (scripts)

### A1. Readiness (before the workshop)
Run **`WSMDI-Validate.ps1`**. Expected: sensor health **Healthy**, ISPM/posture data present, advanced-hunting access confirmed, read scopes consented. All green = ready to teach.

### A2. Discovery sanity
Run **`WSMDI-Discovery.ps1`**. Expected: at least one healthy sensor listed, recent identity alert count reported, and a list of **candidate honeytoken accounts**. Confirms the tenant has real telemetry to investigate.

### A3. Honeytoken configured (after Lab 3)
In **Settings → Identities → Entity tags → Honeytoken**, confirm **`svc-legacy-backup`** is present. Run the saved query **`Honeytoken – Identity Lab – Pilot`** in advanced hunting and confirm it returns the account.

### A4. Saved queries present (after Lab 2)
In **Advanced hunting → Queries**, confirm **`Recon – Identity Lab – Pilot`** and **`LateralMovement – Identity Lab – Pilot`** exist and run without syntax error.

### A5. Posture report (after Lab 4)
Run **`WSMDI-Report.ps1`**; confirm it produces a posture summary and that the **`ISPM-Shortlist – Identity Lab – Pilot`** was captured.

## Part B — Knowledge-check (per attendee)

Score each attendee; passing = correct on at least 8 of 10.

1. **Sensors:** Which servers host MDI sensors, and what does each observe? *(DCs, AD CS, AD FS/Entra Connect — authentication and directory traffic/behavior.)*
2. **Attack path:** On an entity page, where do you find lateral-movement paths and the investigation-priority score, and what do they mean?
3. **Detection families:** Name the four families and give one detection each *(recon, compromised credentials, lateral movement, domain dominance)*.
4. **MITRE:** Map Pass-the-Ticket and DCSync to their MITRE tactics *(Lateral Movement; Credential Access)*.
5. **Honeytoken:** What makes an account a good honeytoken, and why is any activity on it high-fidelity?
6. **Hunting:** Which advanced-hunting tables hold identity telemetry? *(IdentityLogonEvents, IdentityQueryEvents, IdentityDirectoryEvents, IdentityInfo.)*
7. **ISPM:** Give two ISPM recommendations and explain the risk each addresses.
8. **Investigation:** Outline the steps to investigate a suspicious identity from entity page to advanced hunting.
9. **Response & governance:** What are the MDI response actions, and **who** must approve them before execution?
10. **Boundary:** Which decisions in an identity incident belong to the SOC/security team rather than to the tool operator?

## Part C — Live demonstration (capstone)
Each attendee, unaided, does the following on a **second** entity or alert:
- Opens the entity page and reads the timeline + lateral-movement path.
- Runs one saved hunting query and interprets a result.
- States the recommended response action and the approval required.

**Overall pass criteria:** every attendee meets Part B (≥8/10) and completes Part C. Environment checks A1–A5 all pass. Record results against the roster; anyone below threshold repeats the relevant lab.
