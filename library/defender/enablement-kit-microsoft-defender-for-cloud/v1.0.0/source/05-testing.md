# 5. Testing & Knowledge-Check — Enablement Kit: Microsoft Defender for Cloud

Testing a enablement kit means (1) confirming each lab's **pass gate** and (2) a **knowledge-check** that each attendee can operate MDC unaided. Use the lab-helper scripts by name to validate the environment; use the check-questions to validate the people.

## Part A — Environment / lab validation (scripts)

### A1. Readiness (before the enablement kit)
Run **`WSMDC-Validate.ps1 -SubscriptionId '<pilot sub id>'`**. Expected: Az connectivity, `Microsoft.Security` registered, Secure Score data present, at least one Defender plan on, ARG access confirmed. All green = ready to teach.

### A2. Discovery sanity
Run **`WSMDC-Discovery.ps1 -SubscriptionId '<pilot sub id>'`**. Expected: plan tiers, current Secure Score, provider state, workspaces, and any AWS/GCP connectors. Confirms real posture to teach against.

### A3. Preview-first rehearsal (after Lab 5)
Run **`WSMDC-SecureScore-Lab.ps1 -SubscriptionId '<pilot sub id>' -WhatIf`**; confirm it reports what a change *would* do and makes **no** change (no plan toggled).

### A4. Report produced (after Lab 5)
Run **`WSMDC-Report.ps1 -SubscriptionId '<pilot sub id>'`**; confirm a Secure-Score + recommendations report is produced and the **`SecureScore-Shortlist – Cloud Lab – Pilot`** was captured.

### A5. Saved queries present (after Labs 1/2/5)
In Resource Graph Explorer / Advanced hunting, confirm **`Recommendations – Cloud Lab – Pilot`**, **`Alerts-Triage – Cloud Lab – Pilot`**, and **`SecureScore-Trend – Cloud Lab – Pilot`** exist and run without error.

## Part B — Knowledge-check (per attendee)

Score each attendee; passing = correct on at least 8 of 10.

1. **CSPM vs CWPP:** What is the difference, and which surface does each map to (Secure Score/Recommendations vs Security alerts)?
2. **Secure Score:** What does the score represent, and how do you find the highest-impact recommendations?
3. **Foundational vs Defender CSPM:** What does the free tier give you, and what does the paid Defender CSPM plan add? *(agentless scanning, attack paths, risk hunting.)*
4. **Attack paths:** Why can an attack-path-linked finding outrank a higher-raw-severity isolated one?
5. **Defender plans:** Name three CWPP plans and what each protects.
6. **Alert triage:** Given a security alert, what four things do you read first? *(severity, resource, MITRE, activity.)*
7. **Compliance:** How do you drill from a standard to the resources causing a failing control, and who chooses the standard?
8. **Connectors:** What does an AWS/GCP connector do, and what is the limit of multicloud coverage here?
9. **Reporting/drift:** How do you catch posture drift over time? *(continuous export / the trend query / cadence.)*
10. **Boundary & governance:** Which decisions (standard selection, remediation approval, exemption acceptance) belong to the customer's compliance/security/ops functions?

## Part C — Live demonstration (capstone)
Each attendee, unaided, on the pilot subscription:
- Opens Secure Score, sorts recommendations, and states the top item's impact.
- Triages one security alert (severity, resource, MITRE, first step).
- Runs one saved ARG/hunting query and interprets a result.

**Overall pass criteria:** every attendee meets Part B (≥8/10) and completes Part C; environment checks A1–A5 pass. Record results; anyone below threshold repeats the relevant lab.
