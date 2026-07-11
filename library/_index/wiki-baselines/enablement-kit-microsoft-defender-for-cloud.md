# Enablement Kit — Microsoft Defender for Cloud

> **Version 1.0.0** · Category: Defender · Solution code: WSMDC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Enablement Kit: Microsoft Defender for Cloud

**White-label · Defender · Enablement / Training deliverable**

A licensed tool only pays off when the team can drive it. Many organizations enable **Microsoft Defender for Cloud (MDC)** — Azure's cloud-security-posture-management (CSPM) and cloud-workload-protection (CWPP) service — then leave most of its value on the table because no one is confident reading Secure Score, working recommendations, triaging workload-protection alerts, or connecting a second cloud. This is a **structured enablement enablement kit** that takes your admins and SOC/cloud engineers from "we have it" to "we operate it" — through concepts, **guided hands-on labs**, a **take-home runbook**, and a **knowledge-check**.

This is a training deliverable, not a deployment project. It assumes Defender for Cloud is (or is being) enabled on a pilot subscription — the *turn-it-on-and-remediate-at-scale* program lives in the catalog's **Defender for Cloud CSPM / Secure Score** solution — and focuses on the **operating skills**: reading **Secure Score & recommendations** and driving them up, triaging **workload-protection alerts**, using the **regulatory-compliance** dashboard, and understanding **multicloud connectors** (AWS/GCP). Every lab is **read-only or preview-first / `-WhatIf`**, so a team can learn safely on a pilot subscription without changing production posture.

## What you get
- A plain-language **Solution Overview** of Defender for Cloud — CSPM vs CWPP, Secure Score, recommendations, workload-protection plans, compliance, and connectors — and the console/workflows an operator uses daily.
- A **Requirements Guide** covering the enablement-kit-specific prerequisites (a pilot subscription, at least one Defender plan on, Secure Score data, reader access) with verify / implement-if-missing for each.
- An **Implementation Guide** that is the **facilitator + student runbook** — five guided labs, each with named objects, exact portal navigation, and explicit pass/fail checks.
- Five **lab-helper assets**: read-only PowerShell discovery/validation/report scripts (Az modules) plus an **Azure Resource Graph / KQL query pack** for posture and alert hunting.
- A **Testing / knowledge-check** guide and a **Troubleshooting** guide.
- A **Best-Practices + where-to-go-next** guide pointing to the adjacent catalog areas (CSPM/Secure Score program, Sentinel, threat hunting).

## What this delivers
A team that can **confidently operate Microsoft Defender for Cloud**: they can read Secure Score and prioritize recommendations by real risk, triage a workload-protection alert, read the regulatory-compliance dashboard, and explain how a multicloud connector extends posture — with a **runbook they keep** and reuse.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — delivered against a **pilot subscription**, each skill validated with a pass/fail gate, then the team expands the practices across the estate through the customer's change process.

## Boundary
This enablement kit delivers the **technical enablement and the operating runbook**. Which regulatory standards apply, which recommendations to remediate, and whether an exemption is acceptable are the customer's **compliance / security / cloud-ops** functions' determinations — the enablement kit teaches the controls and the reading, not the decision. Any change (enabling a plan, applying a Fix) is taught **preview / `-WhatIf` first** and is approval-gated. Several MDC plans/features are **paid** and version-dependent; those facts are flagged **verify current availability in your tenant**.

## Effort
A competent facilitator can run the full enablement kit in a focused one- to two-day engagement against a pilot subscription; the labs and runbook are then reusable to onboard new cloud/SOC engineers. No production posture change is required to complete the enablement kit — the labs are read-only / preview-first.


---


# 1. Solution Overview — Enablement Kit: Microsoft Defender for Cloud

## What this enablement kit is
This is an **enablement / training** deliverable, not a deployment project. It teaches your admins and SOC/cloud engineers to **operate Microsoft Defender for Cloud (MDC)** confidently — through concept sessions, **five guided hands-on labs**, a **take-home runbook**, and a **knowledge-check**. The output is a skilled team and a reusable runbook. The labs run against a **pilot subscription** and are **read-only or preview-first / `-WhatIf`**, so learning never changes production posture.

## What Microsoft Defender for Cloud is (the concept)
Microsoft Defender for Cloud is Azure's cloud security service with two sides:

- **CSPM (Cloud Security Posture Management)** — continuously assesses cloud resources against a security baseline and expresses the result as a single **Secure Score**, a prioritized list of **recommendations**, an **asset inventory**, and a **regulatory-compliance** view. **Foundational CSPM** is free and on by default for Azure subscriptions; the paid **Defender CSPM** plan adds **agentless scanning**, **attack-path analysis**, and the cloud-security-graph risk hunting.
- **CWPP (Cloud Workload Protection)** — per-resource-type **Defender plans** (for Servers, Storage, SQL, Containers/AKS, Key Vault, App Service, Resource Manager, DNS, APIs, etc.) that generate **security alerts** on active threats to those workloads.

Defender for Cloud also connects to **AWS and GCP** via **multicloud connectors**, so one Secure Score, one recommendation list, and one compliance view can span a multicloud estate. Its data flows into Defender XDR incidents and can be exported to a **Log Analytics workspace** / Microsoft Sentinel.

## Why this matters (for the operator)
Most cloud breaches trace to a **misconfiguration**, not a zero-day — a public storage account, an over-permissive rule, an unencrypted disk, a missing MFA requirement. Defender for Cloud turns that into a live, **scored, prioritized** picture and adds **workload alerts** when something is actively attacked. The operating skill this enablement kit builds is: read the score and recommendations, judge real risk (an **attack path** chaining an exposed VM → a privileged identity → sensitive data is worse than an isolated low-severity finding), triage the workload alerts, and read compliance — all on a pilot before applying anywhere.

## How the operator uses it (the console and workflows)
1. **The Azure portal → Microsoft Defender for Cloud.** Overview, Secure Score, Recommendations, Alerts, Regulatory compliance, Inventory, Environment settings (plans & connectors), Workflow automation.
2. **Secure Score & Recommendations** — the posture surface; recommendations carry an impact and an in-portal **Fix** where available.
3. **Security alerts** — the CWPP surface; workload-protection alerts with severity, affected resource, and MITRE mapping. (Alerts also surface in Defender XDR / Sentinel.)
4. **Regulatory compliance** — controls mapped to standards; the *choice* of standard is the compliance team's.
5. **Environment settings** — where Defender plans are toggled per subscription and where **AWS/GCP connectors** are added.
6. **Advanced hunting / Azure Resource Graph** — posture and alert data queryable for reporting and drift.

## The standard deployment model (how the enablement kit is run)
- **Assess** — confirm the pilot subscription, which Defender plans are on, and that Secure Score data has populated (Lab 0 readiness).
- **Configure** — set up the enablement kit objects: a saved recommendation shortlist, saved ARG/hunting queries, and (optionally, `-WhatIf`) a plan-enable rehearsal.
- **Pilot** — run the five labs against the pilot subscription.
- **Validate** — each lab has a **pass/fail gate**; the enablement kit ends with a **knowledge-check**.
- **Expand** — apply the runbook and remediation cadence across the estate through the customer's change process.

## The five labs (scope of the hands-on)
- **Lab 1 — Secure Score & recommendations.** Read the score, sort recommendations by impact, and interpret a Fix.
- **Lab 2 — Workload-protection alerts.** Understand the Defender plans, triage a security alert, map it to MITRE.
- **Lab 3 — Regulatory compliance.** Read the compliance dashboard; map controls to a standard; export evidence (read-only).
- **Lab 4 — Multicloud connectors.** Understand how AWS/GCP connectors extend posture; review a connector's recommendations (or the concept, if no connector exists).
- **Lab 5 — Remediation cadence & reporting (preview-first).** Build a prioritized remediation shortlist, rehearse an enable/Fix in `-WhatIf`, and produce a Secure-Score report for trending.

## What is in scope
- Concept enablement, five guided labs, the take-home runbook, and the knowledge-check for **operating** MDC.
- Read-only discovery/validation/reporting helpers and an ARG/KQL hunting pack for the labs.

## What is out of scope (and where it lives)
- **Turning on Defender CSPM at scale and running the full remediation program** — see the catalog's **Defender for Cloud CSPM / Secure Score** solution.
- **Building a SIEM / SOC on Sentinel** and cross-pillar hunting — see the **Sentinel** and **Threat Hunting** solutions.
- **Regulatory-standard selection, remediation approval, and exemption acceptance** — the customer's compliance/security/cloud-ops functions'; the enablement kit teaches the technical workflow only.

## Connections and authentication used
- The **Azure portal → Microsoft Defender for Cloud** for score, recommendations, alerts, compliance, plans, and connectors.
- **Az PowerShell modules** (`Az.Accounts`, `Az.Security`, `Az.ResourceGraph`) via the lab helpers, using the signed-in user's **reader** access for read-only discovery, validation, and reporting.
- No lab changes posture; any enable/Fix is **`-WhatIf` / approval-gated**.


---


# 2. Requirements — Enablement Kit: Microsoft Defender for Cloud

The **category-level prerequisites** (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, Log Analytics, response governance) are covered once in **`global-requirements-defender.md`** — read that first. This section lists only the **enablement-kit-specific** prerequisites. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. A pilot Azure subscription with Defender for Cloud reachable
**Description:** An Azure subscription designated as the **pilot** for the enablement kit, with **Microsoft Defender for Cloud** visible in the Azure portal.
**Why required:** Every lab reads posture and alerts for a subscription. The enablement kit is delivered pilot-first so nothing production is changed.
**How to verify:** In the Azure portal, open **Microsoft Defender for Cloud → Overview** for the pilot subscription; confirm it loads. `WSMDC-Discovery.ps1` reports the subscription and its plan tiers.
**How to implement if missing:** Nominate a non-production subscription as the pilot (see the global pilot-ring requirement). Foundational CSPM is on by default for Azure subscriptions.

## R2. Secure Score data populated
**Description:** Secure Score and recommendations have populated for the pilot subscription.
**Why required:** Labs 1 and 5 read Secure Score and recommendations. Assessments take time to populate after a subscription is onboarded.
**How to verify:** Open **Defender for Cloud → Secure Score** / **Recommendations**; confirm a score and recommendation list appear. `WSMDC-Validate.ps1` reports whether Secure Score data is present.
**How to implement if missing:** Allow a warm-up window after the subscription is assessed (*timing varies — verify in your tenant*). Ensure `Microsoft.Security` is registered on the subscription.

## R3. At least one Defender (CWPP) plan enabled — for the alerts lab
**Description:** At least one **Defender plan** (e.g. Defender for Servers, Storage, or Resource Manager) is enabled on the pilot subscription, ideally with some sample alerts.
**Why required:** Lab 2 triages workload-protection alerts. With no plan on, no CWPP alerts are generated.
**How to verify:** **Defender for Cloud → Environment settings → [subscription] → Defender plans**; confirm at least one plan is **On**. Check **Security alerts** for existing alerts. `WSMDC-Discovery.ps1` lists plan tiers.
**How to implement if missing:** Enable an inexpensive plan on the pilot (e.g. **Defender for Resource Manager** or **Storage**) — *several plans are paid; verify current pricing/availability*. Microsoft provides a **sample-alerts** action in the portal to generate benign alerts for training. Keep plan changes on the **pilot** subscription only.

## R4. Reader access to the pilot subscription (attendees) / contributor for the facilitator
**Description:** Attendees hold **Security Reader** or **Reader** on the pilot; the facilitator holds a role that can toggle a plan (e.g. **Security Admin** / **Owner** on the pilot) for the `-WhatIf` rehearsal.
**Why required:** Least privilege — attendees learn read-only; only the facilitator demonstrates a change, and only in `-WhatIf` / with approval.
**How to verify:** Azure portal → subscription → **Access control (IAM)**; confirm role assignments.
**How to implement if missing:** Assign **Reader/Security Reader** to attendees and the change-capable role to the facilitator on the **pilot** subscription only.

## R5. Az PowerShell modules for the lab helpers
**Description:** The Az modules `Az.Accounts`, `Az.Security`, `Az.ResourceGraph` are available on the facilitator/attendee workstations.
**Why required:** `WSMDC-Discovery.ps1`, `WSMDC-Validate.ps1`, `WSMDC-Report.ps1`, and `WSMDC-SecureScore-Lab.ps1` use them for read-only posture/alert queries.
**How to verify:** `Get-Module -ListAvailable Az.Security, Az.ResourceGraph`. The scripts auto-offer to install Az if missing.
**How to implement if missing:** `Install-Module Az -Scope CurrentUser`. Run `Connect-AzAccount` before the labs.

## R6. Advanced hunting / Azure Resource Graph access
**Description:** Attendees can run **Azure Resource Graph** queries (Azure portal → Resource Graph Explorer) and/or **Advanced hunting** in Defender XDR for posture/alert data.
**Why required:** Labs 1, 2, and 5 use the ARG/KQL pack (`WSMDC-LabQueries.kql`) against the `securityresources` ARG tables and Defender alert tables.
**How to verify:** In **Resource Graph Explorer**, run `securityresources | take 5`; confirm rows return.
**How to implement if missing:** Grant **Reader** on the subscription (ARG honors resource RBAC) and, for Defender XDR hunting, an advanced-hunting-read role. *Confirm role mapping in your tenant.*

## R7. (Optional) A multicloud connector for Lab 4
**Description:** An existing **AWS or GCP connector** in Defender for Cloud, if the customer wants a live multicloud lab.
**Why required:** Lab 4 is richer with a real connector; without one it is taught as a concept walk-through.
**How to verify:** **Defender for Cloud → Environment settings**; look for AWS/GCP accounts. `WSMDC-Discovery.ps1` lists connectors.
**How to implement if missing:** Not required — Lab 4 can run as a concept lab. Standing up a connector is part of the CSPM/Secure-Score program solution, not this enablement kit.


---


# Global Requirements — Defender (category-level)

These requirements apply to every solution in the Defender category (Microsoft Defender XDR and Defender
for Cloud). Published once at the category level so listings stay small. Confirm before deploying any
Defender solution. Each entry: Description / Why / Verify / Implement-if-missing.

> Defender changes touch detection and response for the whole tenant. Onboard in a ring (pilot devices/
> users first), keep automated response in an approval/simulate posture until trusted, and never disable
> an existing control to "test."

## G1. Microsoft 365 / Entra tenant
Description: An active Microsoft 365 tenant with Entra ID.
Why: Defender XDR services and the unified portal (security.microsoft.com) are tenant workloads.
Verify: Sign in to `https://security.microsoft.com` as an administrator.
Implement: Provision a Microsoft 365 tenant and confirm Entra ID identities exist.

## G2. Defender licensing
Description: The Defender plans for the pillars in scope — e.g. Defender for Endpoint P1/P2, Defender for Identity, Defender for Office 365 P1/P2, Defender for Cloud Apps, and Defender for Cloud plans.
Why: Each pillar/feature is license-gated; onboarding without the plan fails or silently limits features.
Verify: Admin center -> `Billing -> Licenses` (or the Defender portal). *Confirm the exact plan each feature needs — verify current availability in your tenant.*
Implement: Assign the required plans (often bundled in M365 E5 / E5 Security) before onboarding.

## G3. Administrative roles (least privilege)
Description: Security Administrator (and Global Administrator for first-time service activation).
Why: Onboarding, RBAC, and policy changes in the Defender portal require these roles.
Verify: Entra -> `Roles and administrators`; confirm Security Administrator.
Implement: Assign Security Administrator; reserve Global Administrator for one-time activations.

## G4. Onboarding reach to endpoints / identity / workloads
Description: A management channel to onboard the pillars — Intune/Configuration Manager/GPO/script for endpoints, domain controllers/AD FS for Identity sensors, and cloud connectors for Defender for Cloud.
Why: Each pillar collects signal from a source that must be reachable and instrumented.
Verify: Endpoints are managed (Intune/CM); DCs are reachable; cloud subscriptions are connected. Run the solution's discovery script.
Implement: Establish the onboarding channel per pillar (see the relevant catalog endpoint/identity solutions).

## G5. Network access to Defender service endpoints
Description: Outbound HTTPS to the Microsoft Defender / Microsoft 365 service URLs from onboarded assets.
Why: Sensors and agents report to the cloud service; blocked endpoints break onboarding and detections.
Verify: Confirm the documented Defender endpoint URLs/IP ranges are allowed. *Verify current endpoint list.*
Implement: Allow the Defender/M365 endpoints through proxy/firewall.

## G6. A pilot ring
Description: A defined set of pilot devices/users/subscriptions to onboard first.
Why: XDR onboarding and automated response are validated on a ring before tenant-wide rollout.
Verify: A pilot group exists in Entra/Intune.
Implement: Create the pilot ring before enabling anything that acts automatically.

## G7. Log Analytics workspace (where required)
Description: A Log Analytics workspace for Defender for Cloud / advanced hunting export where used.
Why: Some Defender data and continuous export land in a workspace.
Verify: A workspace exists and is access-controlled. Run the discovery script.
Implement: Provision a workspace (or reuse the SIEM/observability one) with least-privilege access.

## G8. Response governance
Description: An agreed position on automated response (auto-remediation levels, approval requirements).
Why: XDR/AIR can take disruptive actions (isolate, delete, disable); the organization must decide the guardrails.
Verify: A documented response policy exists; automation is in an approval/simulate posture until trusted.
Implement: Define response guardrails; keep AIR/automation approval-gated at first. *Incident-response decisions are the SOC/security team's; this guide covers the technical configuration.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


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


---


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


---


# 6. Troubleshooting — Enablement Kit: Microsoft Defender for Cloud

Symptom → cause → fix for the common issues when running the enablement kit and its lab helpers. For category-level prerequisites (licensing, roles, network) see `global-requirements-defender.md`.

## Defender for Cloud shows no data for the pilot subscription
- **Symptom:** The Overview/Secure Score is blank for the pilot subscription.
- **Cause:** `Microsoft.Security` provider not registered, the subscription only just added, or you are scoped to the wrong subscription.
- **Fix:** Confirm the subscription scope (top of the portal). Register the provider (**Subscriptions → Resource providers → Microsoft.Security → Register**). Allow a warm-up window for assessments (R2). Re-run `WSMDC-Validate.ps1`.

## Secure Score / recommendations are empty (Lab 1)
- **Symptom:** No score or recommendations appear.
- **Cause:** Assessments have not populated yet, or no resources exist to assess.
- **Fix:** Allow the warm-up window after onboarding (*timing varies — verify*). Ensure the pilot subscription has at least a few resources. Confirm `Microsoft.Security` is registered.

## No security alerts to triage (Lab 2)
- **Symptom:** **Security alerts** is empty.
- **Cause:** No Defender (CWPP) plan is On, a quiet environment, or the plan just enabled.
- **Fix:** Enable at least one plan on the **pilot** (R3) — *several are paid; verify cost*. Use the portal **sample alerts** action to generate benign alerts for the lab. Never simulate a real attack against production.

## `Get-AzSecurityPricing` / `Set-AzSecurityPricing` errors
- **Symptom:** The discovery/validate/lab scripts error reading or setting a plan.
- **Cause:** Missing Az.Security module, insufficient role, or a plan-name mismatch between Az versions.
- **Fix:** `Install-Module Az` and `Connect-AzAccount` (R5). Confirm the facilitator holds a change-capable role on the pilot (R4). Valid plan names include `VirtualMachines`, `StorageAccounts`, `Arm`, `KeyVaults`, `SqlServers`, `Containers`, `AppServices`, `Dns`, `Api` — *verify names for your Az version*.

## `WSMDC-SecureScore-Lab.ps1` didn't change anything
- **Symptom:** You expected a plan to be enabled; nothing changed.
- **Cause:** **By design** — the script is preview-first. Without `-Apply` (and a confirmation) it only reports what *would* change.
- **Fix:** This is correct for the enablement kit. Only the facilitator, on the **pilot**, with cost verified and approval, re-runs with `-Apply`. For training, the `-WhatIf`/preview output is the intended result.

## Azure Resource Graph queries return nothing (Labs 1/2/5)
- **Symptom:** `securityresources | take 5` returns no rows.
- **Cause:** The account lacks **Reader** on the subscription (ARG honors resource RBAC), or the scope filter excludes the pilot.
- **Fix:** Grant **Reader/Security Reader** on the pilot subscription (R6). Confirm the Resource Graph Explorer scope includes the pilot subscription. Some `securityresources` types populate only after assessments run.

## Regulatory compliance dashboard is empty (Lab 3)
- **Symptom:** No standards or controls appear.
- **Cause:** No standard assigned, or Defender CSPM (which enriches compliance) is not on.
- **Fix:** Confirm a standard is assigned (the default may need enabling), and that the relevant plan is on. *The choice of standard is the compliance team's* — for the lab, use whatever is assigned. Some standards require Defender CSPM — *verify availability*.

## Multicloud connector lab has nothing to show (Lab 4)
- **Symptom:** No AWS/GCP connector exists.
- **Cause:** No connector configured (expected — connectors are the CSPM-program solution's job).
- **Fix:** Run Lab 4 as the **concept** walk-through (R7). Standing up a real connector is out of scope for this enablement kit.

## `Connect-AzAccount` prompts repeatedly / wrong tenant
- **Symptom:** The scripts keep prompting or land in the wrong tenant/subscription.
- **Cause:** Multiple tenants/subscriptions in context.
- **Fix:** Run `Connect-AzAccount -Tenant '<tenant id>'` then `Set-AzContext -SubscriptionId '<pilot sub id>'`, and pass `-SubscriptionId` to every lab script.

## Portal blade paths don't match
- **Symptom:** A navigation path in the runbook doesn't exist.
- **Cause:** Microsoft periodically relocates Defender for Cloud blades.
- **Fix:** Use portal search for the feature name (e.g. "Secure Score", "Environment settings", "Regulatory compliance"). *Verify current navigation in your tenant* and update your copy of the runbook.


---


# 7. Best Practices & Where to Go Next — Enablement Kit: Microsoft Defender for Cloud

## Running the enablement kit well
- **Teach against a pilot subscription, preview-first.** Every enable/Fix is rehearsed in `-WhatIf`; nothing changes production posture during training. Expand across the estate only through the customer's change process.
- **Read-only by default.** Attendees learn read-only; only the facilitator demonstrates a change, and only in `-WhatIf` / with approval on the pilot.
- **Use the sample-alerts action, not a real attack.** If the pilot is quiet, generate benign sample alerts in the portal for Lab 2 — never simulate a real attack against production.
- **Use consistent object names.** The `<Purpose> – <Scope> – <Stage>` convention keeps the take-home artifacts findable and reusable. Keep it.
- **Save the artifacts.** The three saved queries, the shortlist, the compliance export, and the ops-notes doc are the take-home runbook.

## Operating MDC well (the habits to instill)
- **Prioritize by real risk, not raw count.** Attack-path-linked and internet-exposed findings first; a long list of low-severity items is not an emergency. Secure Score is a trend to move, not a number to obsess over.
- **Make remediation a cadence, not a one-off.** Posture drifts as resources are created; review the score and recommendations on a schedule and track a shortlist you actually work.
- **Catch drift with continuous export.** Stream Secure Score/recommendations to a Log Analytics workspace/workbook (or Sentinel) so trend and regressions are visible.
- **Triage alerts with context.** Read severity + resource + MITRE + activity before escalating; hand the incident to the SOC with evidence.
- **Respect the approval gate.** Enabling paid plans, applying Fixes at scale, and accepting exemptions are cloud-ops/security/compliance decisions — the operator surfaces the data and the recommendation.
- **Mind cost, licensing, and preview.** Several Defender plans and Defender CSPM are **paid** per resource/subscription and version-dependent; *verify current pricing/availability in your tenant* before enabling at scale.

## Common anti-patterns to avoid
- Turning the enablement kit into a full CSPM rollout (that is the CSPM/Secure-Score program solution).
- Applying a **Fix** or enabling a paid plan across production "to show it works."
- Chasing Secure Score to 100% instead of prioritizing real risk and business context.
- Treating a compliance dashboard as a certification decision — that is the compliance team's call.

## Where to go next (adjacent catalog areas)
- **Defender for Cloud CSPM / Secure Score** — the full program: enable Defender CSPM, agentless scanning, governance rules, continuous export, and the remediation cadence at scale.
- **Microsoft Sentinel** — SIEM/SOAR to ingest MDC alerts and Secure Score for correlation, hunting, and automation.
- **Threat Hunting** — deeper cross-pillar KQL beyond the posture tables.
- **Identity / Zero Trust** — identity hardening that many top recommendations depend on.
- **Sibling Defender enablement kits** — Identity, Endpoint, Office 365, and Cloud Apps enablement enablement kits to round out the team's operating skills across the Defender suite.

The bottom line: a team that operates MDC with confidence — reading Secure Score and prioritizing by real risk, triaging workload alerts, reading compliance, and running a preview-first remediation cadence — using a runbook they keep and reuse.


---


# 8. Deliverables Summary — Enablement Kit: Microsoft Defender for Cloud

This enablement kit is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation set below plus five lab-helper assets, yours to keep and reuse to train new cloud/SOC engineers.

## Documentation (source/)
- **executive-summary.md** — what the enablement kit is, the outcome, the boundary, and the effort.
- **01-solution-overview.md** — what MDC is (CSPM vs CWPP), how Secure Score, recommendations, workload plans, compliance, and connectors work, the operator console/workflows, the five labs, and what is in/out of scope.
- **02-requirements.md** — enablement-kit-specific prerequisites (pilot subscription, Secure Score data, a Defender plan on, reader access, Az modules, ARG access, optional connector), each with verify / implement-if-missing. Category-level prerequisites are in `global-requirements-defender.md`.
- **03-implementation.md** — the facilitator + student runbook: Lab 0 readiness plus the five guided labs, with named objects and pass/fail gates.
- **05-testing.md** — environment validation, the per-attendee knowledge-check, and the capstone demonstration.
- **06-troubleshooting.md** — symptom → cause → fix for the common enablement kit and MDC issues.
- **07-best-practices.md** — how to run the enablement kit and operate MDC well, plus where to go next in the catalog.
- **08-deliverables-summary.md** — this file.
- **global-requirements-defender.md** — the category-level prerequisites (shared across all Defender solutions).

## Lab-helper assets (scripts/)
- **WSMDC-Discovery.ps1** — read-only discovery (Az.Security): Defender plan tiers, current Secure Score, `Microsoft.Security` provider state, Log Analytics workspaces, and AWS/GCP connectors for Lab 0. Makes no changes.
- **WSMDC-Validate.ps1** — read-only readiness validation: Az connectivity, provider registration, Secure Score data present, a Defender plan on, and ARG access. Green = ready to teach.
- **WSMDC-Report.ps1** — read-only Secure-Score + recommendations report (HTML) with a shortlist template for Labs 1/5, for trending and the take-home runbook.
- **WSMDC-LabQueries.kql** — Azure Resource Graph / KQL pack for Labs 1, 2, and 5: recommendations, Secure Score by control, security-alert triage, and unhealthy-resource queries over the `securityresources` tables (plus Defender alert tables).
- **WSMDC-SecureScore-Lab.ps1** — preview-first (`-WhatIf`) Lab 5 helper: shows what enabling a Defender plan / applying a posture step *would* do on the pilot subscription. Defaults to **preview — changes nothing** unless explicitly confirmed and approval-gated.

## Take-home runbook artifacts (produced during the labs)
- Saved queries: `Recommendations – Cloud Lab – Pilot`, `Alerts-Triage – Cloud Lab – Pilot`, `SecureScore-Trend – Cloud Lab – Pilot`.
- The `SecureScore-Shortlist – Cloud Lab – Pilot` remediation shortlist.
- The `Compliance-Evidence – Cloud Lab – Pilot` export.
- The `Investigation – Cloud Lab – Pilot` ops-notes / cadence document.

*Delivered as a Word document and PDF, plus all five lab-helper scripts in a single ZIP — yours to keep and reuse.*
