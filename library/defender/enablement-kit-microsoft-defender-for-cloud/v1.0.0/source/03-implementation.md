# 3. Implementation — Enablement Kit Runbook: Microsoft Defender for Cloud

This is the **facilitator + student runbook**. Run the labs in order against the **pilot subscription** from R1. Every object uses the naming convention **`<Purpose> – <Scope> – <Stage>`** and is reused by name in later labs, testing, and the scripts. All steps are **read-only or preview-first / `-WhatIf`**; any plan-enable or Fix is **facilitator-driven, `-WhatIf` first, and approval-gated**.

**Naming convention used throughout**
- Remediation shortlist output: **`SecureScore-Shortlist – Cloud Lab – Pilot`**.
- Saved ARG/hunting queries: **`Recommendations – Cloud Lab – Pilot`**, **`Alerts-Triage – Cloud Lab – Pilot`**, **`SecureScore-Trend – Cloud Lab – Pilot`**.
- Compliance evidence export: **`Compliance-Evidence – Cloud Lab – Pilot`**.
- Investigation/notes doc: **`Investigation – Cloud Lab – Pilot`**.

> Navigation reflects the current **Azure portal → Microsoft Defender for Cloud**. Microsoft moves blades periodically — *verify current navigation in your tenant*; the troubleshooting guide lists fallbacks.

---

## Lab 0 — Readiness check (Assess)
1. Open **Azure portal → Microsoft Defender for Cloud → Overview** for the **pilot subscription**.
2. Confirm Secure Score shows a value (R2) and at least one **Defender plan** is On (R3).
3. Run `powershell -ExecutionPolicy Bypass -File .\WSMDC-Discovery.ps1 -SubscriptionId '<pilot sub id>'` — confirm it reports plan tiers, Secure Score, provider registration, and any connectors.
4. Run `powershell -ExecutionPolicy Bypass -File .\WSMDC-Validate.ps1 -SubscriptionId '<pilot sub id>'` — confirm readiness checks pass.
5. **Pass gate:** discovery + validate green; Secure Score and recommendations visible. Resolve via R1–R6 if not.

---

## Lab 1 — Secure Score & recommendations (Configure/learn)
**Goal:** read the score, prioritize recommendations by impact, and interpret a Fix.

1. Open **Defender for Cloud → Secure Score**. Discuss what the score represents (weighted control groups) and where the points are.
2. Open **Recommendations**. Sort by **Potential score increase / impact**. Walk 3–5 top recommendations: what is wrong, which resources, and the **Fix** action (where offered — *do not apply it yet*).
3. Discuss risk beyond the raw score: an **attack-path**-linked or internet-exposed finding outranks an isolated low-severity one.
4. In **Resource Graph Explorer** (or Advanced hunting), run the **Recommendations** section of `WSMDC-LabQueries.kql`; **Save as `Recommendations – Cloud Lab – Pilot`**.
5. Start the **`SecureScore-Shortlist – Cloud Lab – Pilot`** — the top recommendations ranked by impact and effort. **Remediation and change approval belong to the customer's cloud-ops/security functions.**
6. **Pass gate:** each attendee can read the score, explain one recommendation's impact, and describe what its Fix would change.

---

## Lab 2 — Workload-protection alerts (Pilot)
**Goal:** understand the Defender plans and triage a security alert.

1. Open **Defender for Cloud → Environment settings → [pilot sub] → Defender plans**. Review which CWPP plans exist (Servers, Storage, SQL, Containers, Key Vault, App Service, Resource Manager, DNS, APIs) and what each protects. *Several are paid — verify pricing/availability.*
2. Open **Security alerts**. If empty, the facilitator can use the portal **sample alerts** action (pilot only) to generate benign alerts for the lab.
3. Take one alert through triage: severity, affected resource, the **MITRE** tactic/technique shown, the described activity, and the suggested response steps.
4. In Advanced hunting / ARG, run the **Alerts triage** section of `WSMDC-LabQueries.kql`; **Save as `Alerts-Triage – Cloud Lab – Pilot`**.
5. Discuss the hand-off: MDC alerts flow to Defender XDR / Sentinel; the SOC owns the incident decision.
6. **Pass gate:** each attendee triages an alert — states severity, resource, MITRE mapping, and the first response step — and names who owns the incident decision.

---

## Lab 3 — Regulatory compliance (Validate posture)
**Goal:** read the compliance dashboard and export evidence — read-only.

1. Open **Defender for Cloud → Regulatory compliance**. Review the standards assigned and the pass/fail controls.
2. Pick one standard; drill into a failing control to see the mapped recommendations and affected resources.
3. Export the compliance report/evidence (PDF/CSV where offered) as **`Compliance-Evidence – Cloud Lab – Pilot`** — read-only.
4. **Boundary:** *which* standards apply and whether a gap/exemption is acceptable are the **compliance team's** determination — the enablement kit shows how to read and evidence, not what to certify.
5. **Pass gate:** each attendee can navigate a standard, drill to a failing control, and explain what evidence the export provides.

---

## Lab 4 — Multicloud connectors (Validate/Expand)
**Goal:** understand how AWS/GCP connectors extend posture.

1. Open **Defender for Cloud → Environment settings**. If an **AWS/GCP connector** exists (R7), open it; review the account, the enabled plans, and its recommendations in the unified list.
2. If no connector exists, walk the **concept**: a connector uses a cross-cloud role/identity to read the other cloud's config, mapping its findings into the same Secure Score/recommendation model at a high level.
3. Discuss scope honestly: multicloud here is **high-level posture**; deep per-cloud workload protection is a larger, separate effort (the CSPM program solution).
4. **Pass gate:** each attendee can explain what a connector does, what it reads, and the limit of multicloud coverage.

---

## Lab 5 — Remediation cadence & reporting, preview-first (Validate/Expand)
**Goal:** build a prioritized shortlist, rehearse an enable/Fix in `-WhatIf`, and produce a trend report.

1. Finalize the **`SecureScore-Shortlist – Cloud Lab – Pilot`** from Lab 1: top 3–5 items with owner candidates and effort.
2. **Rehearse a change in preview (facilitator):** run `powershell -ExecutionPolicy Bypass -File .\WSMDC-SecureScore-Lab.ps1 -SubscriptionId '<pilot sub id>' -WhatIf` to see what enabling a plan / applying a governance step *would* do — **it makes no change**. Discuss the real enable path and the rollback.
3. Run `powershell -ExecutionPolicy Bypass -File .\WSMDC-Report.ps1 -SubscriptionId '<pilot sub id>'` to produce a Secure-Score + recommendations report. Save the ARG trend query as **`SecureScore-Trend – Cloud Lab – Pilot`**.
4. Capture the operating cadence in **`Investigation – Cloud Lab – Pilot`** (here used as the ops-notes doc): how often to review score, who owns recommendations, and how drift is caught (continuous export / the trend query).
5. **Important boundary:** the enablement kit **does not enforce** posture changes. Enabling plans and applying Fixes at scale follow the customer's change process and the CSPM-program solution.
6. **Pass gate:** a written shortlist and cadence exist; the `-WhatIf` rehearsal ran without making a change; a Secure-Score report was produced.

---

## Wrap-up (Expand)
1. Confirm the take-home artifacts: the three saved queries, the shortlist, the compliance export, and the ops-notes doc.
2. Run the **knowledge-check** in `05-testing.md`.
3. Agree the **expand** plan: apply the remediation cadence across the estate through the customer's change process, and use the runbook to onboard new cloud/SOC engineers.
