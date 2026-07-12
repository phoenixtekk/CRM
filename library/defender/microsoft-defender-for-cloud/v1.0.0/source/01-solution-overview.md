# 1. Solution Overview — Microsoft Defender for Cloud

## What Microsoft Defender for Cloud is
Microsoft Defender for Cloud (MDC) is Azure's cloud security service, managed from the **Azure portal**
(`portal.azure.com → Microsoft Defender for Cloud`), with alerts surfacing into the unified Defender
portal at `security.microsoft.com`. It has two layers:

- **CSPM (Cloud Security Posture Management)** — continuously assesses cloud resource configuration
  against a security baseline and expresses the result as a single **Secure Score**, a prioritized list
  of **recommendations**, an **asset inventory**, and a **regulatory-compliance** view. **Foundational
  CSPM** is free and on by default for Azure subscriptions; the paid **Defender CSPM** plan adds
  agentless scanning, attack-path analysis, and cloud-security-graph risk hunting. *Verify current
  availability in your tenant.*
- **CWPP (Cloud Workload Protection Platform)** — the **paid, per-resource** workload protection plans
  (Defender for Servers, Containers, Databases, Storage, Key Vault, App Service, Resource Manager, and
  more) that actively detect threats against running workloads and raise **security alerts**.

MDC also connects **AWS accounts and GCP projects** via **multicloud connectors**, so one Secure Score,
one recommendation list, and one compliance view can span clouds. Its data flows into Defender XDR
incidents and can be **continuously exported** to a Log Analytics workspace / Microsoft Sentinel.

## What this solution is (and how it is structured)
This is the **complete Defender for Cloud solution** — it delivers the whole lifecycle as four
integrated phases, each building on the last:

- **Phase A — Architect.** A reference **design** for MDC across a large, multi-subscription, multicloud
  estate: the **management-group onboarding model** (enable at MG scope so every current and future
  subscription inherits protection), the **plan-enablement strategy** and rollout **waves**, the
  **multicloud connector design**, the **RBAC and governance model**, the **continuous-export / SIEM
  integration**, a **cost model**, and a deployable reference **`main.bicep`** skeleton.
- **Phase B — Protect (workload protection plans / CWPP).** Turn on and **tune** the workload plans on a
  pilot subscription, wire the **Defender for Endpoint** integration for Servers, configure
  **continuous export**, tune alerts with scoped suppression and notifications, and add a **notify-first
  response workflow**.
- **Phase C — Enable the team.** Five hands-on **labs**, a take-home runbook, and a knowledge-check that
  make admins and SOC/cloud engineers confident operators — reading Secure Score and recommendations,
  triaging workload alerts, reading compliance, understanding connectors, and running a preview-first
  cadence.
- **Phase D — Prove value.** A guided, **benign, reversible proof-of-concept** on one pilot subscription
  that demonstrates MDC surfacing your misconfigurations and threats, scored against your criteria, and
  torn down cleanly (disabling paid plans to stop billing).

**Posture remediation is cross-referenced, not duplicated.** Working Secure Score, the recommendation
backlog, agentless scanning, and the CSPM remediation program at scale are the catalog's **Microsoft
Defender for Cloud — CSPM & Secure Score Remediation** solution. This solution *architects the platform*
that CSPM runs on, *protects the workloads*, *trains the team*, and *proves the value* — and references
CSPM wherever posture is read.

## How the technology works (the levers you design and pull)
- **Management-group scope + inheritance.** Defender plans can be set at a **management group**, and
  descendant subscriptions **inherit** the setting — the way to get consistent coverage without touching
  every subscription and to protect new subscriptions the day they are created. **Azure Policy** (the
  Microsoft cloud security benchmark initiative and the plan-configuration initiative) is the
  enforcement mechanism; the reference Bicep drives it.
- **Plans, enabled independently.** Foundational CSPM (free) plus **Defender CSPM** and each **workload
  plan** (paid) are enabled per scope and per wave — the strategy decides which, where, and when.
- **Servers + Defender for Endpoint.** Defender for Servers detection uses the **MDE** sensor and the
  monitoring agent, auto-provisioned; non-Azure servers join via **Azure Arc**. *Verify current
  agent/extension requirements.*
- **Continuous export** streams recommendations, Secure Score, and alerts to a workspace and onward to
  the SIEM for trending, hunting, and correlation.
- **Alert tuning and response** — scoped suppression rules and notification thresholds make the alert
  queue signal, not noise; a **workflow automation** (Logic App) routes high-severity alerts, kept
  **notify/approval-gated**, not auto-remediating.

## The standard deployment model
> **Assess** (map the MG hierarchy, current plan state, agents, workspaces, and cost inputs) →
> **Configure** (design the architecture + Bicep; enable and tune workload plans; set up export and the
> response workflow; build the lab objects) → **Pilot** (deploy plans on a pilot MG/subscription
> `what-if` first, run the labs, and run the benign PoC) → **Validate** (each phase has explicit
> pass/fail gates — inheritance, coverage, agents, export, alerts, knowledge-check, PoC scorecard) →
> **Expand** (roll out plans wave by wave across the hierarchy and to AWS/GCP; extend export, RBAC, and
> the response workflow). Every deployment is **`what-if` / plan first**, paid plans are **cost-gated**,
> and automated response stays **approval-gated**.

## Scope (what this solution produces)
- A **reference architecture** and decision record for MDC at scale, plus a deployable reference Bicep.
- **Workload protection plans** enabled and tuned on a pilot, with MDE integration, continuous export, a
  suppression rule, notifications, and a notify-first response workflow.
- A **management-group / multicloud rollout** in waves (AWS/GCP connectors) with RBAC and governance.
- **Team enablement** — five labs, a runbook, saved queries, and a knowledge-check.
- A **guided proof-of-concept** with benign signal, a scorecard, and a clean teardown.
- **Read-only** discovery, validation, and reporting scripts (PowerShell/Az + KQL), one preview-gated
  deploy/enable script, and the reference Bicep.

## What is out of scope (and where it lives)
- **Day-to-day posture operations** — driving Secure Score, working the recommendation backlog,
  agentless scanning, attack-path remediation, and the CSPM cadence at scale — the **Defender for
  Cloud — CSPM & Secure Score Remediation** solution.
- **Full Azure landing-zone / cloud-adoption-framework design** — this designs the MDC layer, not the
  whole platform landing zone.
- **Deep per-cloud workload security in AWS/GCP** beyond connecting them for posture and enabling the
  available plans.
- **Building the SIEM/SOC on Sentinel** and cross-pillar hunting — the **Sentinel** and **Threat
  Hunting** solutions.
- **Regulatory-standard selection, remediation/exemption approval, cost acceptance, and
  incident-response decisions** — the customer's compliance / finance / security / operations functions.

## Connections and authentication used
- The **Azure portal → Microsoft Defender for Cloud** (Environment settings, Defender plans, Governance,
  Continuous export, Security alerts, Recommendations, Regulatory compliance, Workflow automation) and
  **Management groups**.
- The **unified Defender portal** (`security.microsoft.com`) where workload alerts also surface and
  advanced hunting runs.
- **Az PowerShell** (`Az.Accounts`, `Az.Security`, `Az.Resources`, `Az.ResourceGraph`,
  `Az.OperationalInsights`, `Az.Storage`) for read-only discovery, validation, reporting, the
  preview-gated deploy/enable, and PoC signal/teardown; **KQL / Azure Resource Graph** for hunting and
  the labs.
- **Bicep** (`main.bicep`) deployed via `az deployment mg what-if` / `New-AzManagementGroupDeployment
  -WhatIf` — **what-if first**.
- **AWS/GCP security connectors** for multicloud; a **Log Analytics workspace** and the **SIEM** as
  export destinations.
- Least-privilege roles: **Security Reader** (read-only), **Security Admin** (manage plans/policies),
  **Owner/Contributor** at scope (enable paid plans), **Management Group Contributor** (MG-scope deploy);
  **Global/Security Administrator** only for one-time tenant-level activations.
