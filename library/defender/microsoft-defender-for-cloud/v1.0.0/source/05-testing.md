# 5. Testing Guide — Microsoft Defender for Cloud

Validate each phase against its **pass/fail gate** before moving on. Do not expand across the hierarchy
until the pilot passes every gate. Objects are referenced by the exact names from the Implementation
Guide. Keep every deployment **what-if first** and all PoC signal **benign**.

---

## Part A — Architect (Phase A)

### A1 — Design record and Bicep parameterized
**Procedure:** Confirm `MDC Architecture Decision Record – Platform – Prod` exists with the onboarding
model, plan-per-wave matrix, RBAC model, multicloud plan, export design, and cost model; and that
`main.bicep` parameters match it.
**Pass:** The design record is complete and the Bicep reflects it. **Fail:** Missing sections or Bicep
drift — complete Implementation Step A2.

### A2 — Bicep what-if is clean before apply
**Procedure:** Run `MDCFULL-Deploy.ps1 -ManagementGroupId '<pilotMgId>' -Wave 1` (default `-WhatIf`).
**Pass:** The what-if shows **only** the intended plan enablements at the pilot scope — no unexpected
changes. **Fail:** Unexpected/out-of-scope changes — fix the Bicep/parameters; do **not** `-Apply`. See
Troubleshooting *What-if shows unexpected changes*.

### A3 — Plans enabled + inheritance working at the pilot scope
**Procedure:** Run `MDCFULL-Validate.ps1`. Confirm wave-1 plans are **On** at `MDC Scope – Pilot MG –
Pilot`, and pick a subscription **under** the pilot MG to confirm it shows the **inherited** plan.
**Pass:** Designed plans enabled at MG scope and a child subscription inherits. **Fail:** Off/Free or no
inheritance — see Troubleshooting *Plan not enabling at MG scope* / *Inheritance not applying*.

### A4 — Providers registered + RBAC/governance in place
**Procedure:** Run `MDCFULL-Validate.ps1`. Confirm **Microsoft.Security** is Registered, the designed
least-privilege roles are assigned at the pilot scope, and `MDC Governance – Platform MG – Prod` exists
with owners/due dates and time-bound exemptions.
**Pass:** Provider registered; RBAC matches the design; governance rule present. **Fail:** Over-broad
role or missing governance/provider — see Troubleshooting *RBAC sprawl / missing governance* /
*Provider not registered*.

---

## Part B — Protect (Phase B)

### B1 — Workload plans enabled on the pilot subscription
**Procedure:** Run `MDCFULL-Validate.ps1 -Plan All`; confirm the in-scope plans (Servers/Containers/
Databases/Storage/Key Vault/App Service/Resource Manager) are **On** for `MDC Workload Plans – Pilot
Subscription – Pilot`.
**Pass:** Every in-scope plan On at the agreed tier. **Fail:** A plan Off/wrong tier — re-apply
Implementation Step B1.

### B2 — Defender for Servers coverage (MDE + agent)
**Procedure:** Run `MDCFULL-Validate.ps1 -Plan Servers`; confirm MDE and the monitoring agent are
provisioned and healthy on the pilot servers (Arc for non-Azure).
**Pass:** Pilot servers report MDE/agent healthy; server detection active. **Fail:** Not provisioned —
see Troubleshooting *Server agent not provisioned*.

### B3 — Continuous export flowing
**Procedure:** Run `MDCFULL-Validate.ps1 -Plan Export`; confirm alerts/recommendations/Secure Score land
in `MDC Continuous Export – Platform MG – Prod` (the `SecurityAlert` table) and reach the SIEM.
**Pass:** Export active and data landing; SIEM path present. **Fail:** No data — see Troubleshooting
*Continuous export no data*.

### B4 — Alert tuning in place
**Procedure:** Run `MDCFULL-Report.ps1 -Mode Alerts`; confirm `MDC Alert Suppression – Benign FP – Prod`
exists (scoped/documented) and email notifications are set with a sensible severity threshold.
**Pass:** Suppression rule + notifications configured; the queue is signal, not noise. **Fail:** No
tuning or over-broad suppression — re-apply Implementation Step B4.

### B5 — Response workflow is notify-only
**Procedure:** Run `MDCFULL-Validate.ps1 -Plan Workflow`; confirm `MDC Workload Response – Tenant – Prod`
triggers on high-severity alerts and **only notifies / creates a ticket**.
**Pass:** The workflow notifies and does not remediate during the pilot. **Fail:** Auto-remediation
configured before agreed — reset to notify-only and confirm with the SOC.

### B6 — Coverage rose and cost matches the model
**Procedure:** Run `MDCFULL-Report.ps1 -Mode Coverage -BaselinePath .\mdcfull-baseline.json` and
`-Mode Cost`.
**Pass:** Coverage on the pilot is **higher** than baseline and drivers are within the cost model's
estimate. **Fail:** Unchanged or cost far exceeds estimate — reconcile before expanding; *verify current
pricing.* See Troubleshooting *Cost exceeds the model*.

---

## Part C — Enable the team (Phase C)

### C1 — Environment / lab validation (scripts)
Run `MDCFULL-Validate.ps1 -SubscriptionId '<pilot sub id>'` (Az connectivity, `Microsoft.Security`
registered, Secure Score present, a plan on, ARG access) and `MDCFULL-Discovery.ps1 -SubscriptionId
'<pilot sub id>'`. Confirm the saved queries `Recommendations – Cloud Lab – Pilot`, `Alerts-Triage –
Cloud Lab – Pilot`, and `SecureScore-Trend – Cloud Lab – Pilot` exist and run without error, and that
the `-WhatIf` rehearsal (`MDCFULL-Deploy.ps1 -SubscriptionId '<pilot>' -Plans StorageAccounts`) made
**no** change.
**Pass:** All green; queries run; the rehearsal changed nothing. **Fail:** Resolve via Requirements
2.8–2.9.

### C2 — Knowledge-check (per attendee; pass = ≥8/10)
1. **CSPM vs CWPP:** the difference, and which surface each maps to (Secure Score/Recommendations vs
   Security alerts)?
2. **Secure Score:** what it represents, and how to find the highest-impact recommendations?
3. **Foundational vs Defender CSPM:** what the free tier gives vs what paid Defender CSPM adds
   (agentless scanning, attack paths, risk hunting)?
4. **Attack paths:** why an attack-path-linked finding can outrank a higher-raw-severity isolated one?
5. **Defender plans:** name three CWPP plans and what each protects.
6. **Alert triage:** the four things you read first (severity, resource, MITRE, activity)?
7. **Compliance:** how to drill from a standard to the resources causing a failing control, and who
   chooses the standard?
8. **Connectors:** what an AWS/GCP connector does, and the limit of multicloud coverage here?
9. **Reporting/drift:** how to catch posture drift over time (continuous export / trend query / cadence)?
10. **Boundary & governance:** which decisions (standard selection, remediation approval, exemption
    acceptance) belong to the customer's functions?

### C3 — Live demonstration (capstone)
Each attendee, unaided, on the pilot: opens Secure Score and states the top item's impact; triages one
alert (severity, resource, MITRE, first step); runs one saved query and interprets a result.
**Pass:** Every attendee meets C2 (≥8/10) and completes C3. Anyone below threshold repeats the relevant
lab.

---

## Part D — Prove value (Phase D PoC)

### D1 — Plan enabled on the pilot subscription only
**Procedure:** Run `MDCFULL-PoC.ps1 -Action Assess`; confirm CSPM + the chosen workload plan show **On**
for the pilot subscription and **no other**. **Pass/Fail:** On for the pilot only / see Troubleshooting
*Plan not enabling*.

### D2 — Benign signal generated
**Procedure:** Run `MDCFULL-PoC.ps1 -Action TestSignal`; confirm sample alerts created, the benign test
resource deployed, and (optionally) EICAR dropped. **Pass:** All benign signals generated, no real
attack/malware. **Fail:** see Troubleshooting *Signal not generated*.

### D3 — Recommendation, Secure Score, alert, and compliance populated
**Procedure:** Run `MDCFULL-Validate.ps1 -PoC`. Confirm a **recommendation** for the benign misconfig, a
**Secure Score**, the **security alerts** (sample + EICAR), and **regulatory-compliance** data.
**Pass:** All four observed (allow warm-up). **Fail:** see Troubleshooting *No recommendation / No Secure
Score / No security alert / No compliance data*.

### D4 — Scorecard produced
**Procedure:** Run `MDCFULL-PoC.ps1 -Action Scorecard`; confirm `MDC PoC Scorecard – Pilot Sub –
Validate.json` maps every observation to a pass/fail criterion. **Pass:** Complete scorecard. **Fail:**
re-run the relevant validate step first.

### D5 — Clean teardown (and billing stopped)
**Procedure:** Run `MDCFULL-PoC.ps1 -Action Teardown -WhatIf`, then without; re-run `MDCFULL-Validate.ps1
-PoC`. **Pass:** The test resource is deleted, the Defender plan is **Off** (billing stopped), and sample
alerts resolved. **Fail:** Residue or plan still on — see Troubleshooting *Teardown left residue*.

---
### Exit gates
- **Phase A/B:** A1–A4 and B1–B6 pass on the pilot **before** any hierarchy-wide or multicloud expansion.
  Re-run A2–A4 and B1, B3, B6 after each wave and compare against the re-saved baseline.
- **Phase C:** Every attendee meets C2/C3 and C1 is green.
- **Phase D:** D1–D4 pass to call the PoC conclusive; D5 passes to close it out cleanly **and stop
  billing**. Keep the scorecard as the decision record.
