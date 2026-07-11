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
