# 1. Solution Overview — Architecture Service: Microsoft Defender for Cloud

## What this solution is
This is an **Architecture Service** — a reference **design** for running **Microsoft Defender for Cloud** across a large, multi-subscription, multicloud estate. It is distinct from the single-subscription CSPM enablement solution: that turns Defender for Cloud on for *one* subscription and works Secure Score; this defines *how the whole estate is structured* — the management-group model, the plan-enablement strategy, RBAC and governance, multicloud, export/SIEM, and cost — so the rollout is **consistent, governed, and predictable** instead of ad-hoc. It **complements** the Defender for Cloud CSPM/Secure-Score and the workload-protection-plans solutions rather than duplicating them: use those to *operate* posture; use this to *design the platform* they run on.

It delivers six design components, each with a corresponding artifact:

1. **Management-group / subscription onboarding model** — enable Defender for Cloud at **management-group** scope so every current and future subscription inherits protection, rather than per-subscription drift.
2. **Plan-enablement strategy** — which plans (foundational CSPM free, **Defender CSPM** paid, and the **workload plans** — Servers, Storage, Containers, Key Vault, App Service, SQL, etc.) are enabled where, and in what rollout waves.
3. **Multicloud (AWS/GCP) connector design** — how AWS accounts and GCP projects are connected for one posture view across clouds.
4. **RBAC and governance model** — who can read posture, enable plans, and manage governance rules/exemptions; least-privilege by scope.
5. **Continuous export / SIEM integration** — how recommendations, Secure Score, and alerts flow to a Log Analytics workspace and the SIEM.
6. **Cost model** — the drivers of paid-plan spend and a predictable estimate before rollout.

## How the technology works (the design levers)
- **Management-group scope** — Defender for Cloud plans can be set at a **management group**, and subscriptions **inherit** the setting. Enabling at the right MG node is how you get *consistent* coverage without touching every subscription, and how new subscriptions are protected the day they're created. **Azure Policy** (the *Microsoft cloud security benchmark* initiative and the Defender-for-Cloud auto-provisioning policies) is the enforcement mechanism behind this.
- **Plans** — Defender for Cloud is a **CSPM** service (posture: Secure Score, recommendations, attack paths) plus a set of **CWPP workload plans** (threat protection for Servers, Storage, Containers, databases, etc.), each **paid** and enabled independently. The strategy decides which plans, at which scope, in which wave.
- **Connectors** — AWS accounts and GCP projects join through **security connectors**, giving one posture/recommendation view spanning clouds.
- **RBAC** — built-in roles **Security Reader** (read posture), **Security Admin** (manage plans/policies within Defender for Cloud), and Azure **Owner/Contributor** at scope (enable plans that incur cost) map to who does what; the design keeps this least-privilege.
- **Continuous export** streams recommendations/score/alerts to a workspace and onward to the SIEM (e.g. via the workspace or a data connector).

## The standard deployment model
> **Assess (map the MG hierarchy, current plan state, and cost inputs) → Configure (design the MG onboarding model, plan waves, RBAC, connectors, export, cost model, and the Bicep) → Pilot (deploy to a pilot management group / subscription with `what-if`) → Validate (confirm inheritance, coverage, RBAC, export) → Expand (wave by wave across the hierarchy and to AWS/GCP).** Every deployment is **`what-if` / plan first** and approval-gated.

## Scope (what this solution produces)
- A **reference architecture** and **decision/design record** for Defender for Cloud at scale.
- A **management-group onboarding model** with plan-enablement **waves**.
- A **multicloud connector design** (AWS/GCP).
- An **RBAC and governance model** (roles, scopes, exemption policy structure).
- A **continuous-export / SIEM integration** design.
- A **cost model** and a **reference Bicep skeleton** that enables plans at scale, deployed what-if first.

## Out of scope
- **Day-to-day posture operations** — working Secure Score and remediating recommendations is the CSPM/Secure-Score solution's job; running the workload plans is the workload-protection-plans solution's.
- **Full Azure landing-zone / platform design** — this designs the Defender-for-Cloud layer, not the whole cloud-adoption-framework landing zone.
- **Deep per-cloud workload security** in AWS/GCP beyond connecting them for posture and enabling the available plans.
- **Regulatory, risk-appetite, exemption-acceptability, and cost-acceptability determinations** — deferred to the customer's compliance, security, and finance functions.

## Connections and authentication used
- The **Azure portal** → **Microsoft Defender for Cloud** (Environment settings, Defender plans, Governance, Continuous export) and **Management groups**.
- **Az PowerShell** (`Az.Accounts`, `Az.Security`, `Az.Resources`, `Az.ResourceGraph`, `Az.OperationalInsights`) for read-only discovery, validation, and the coverage/cost report.
- **Bicep** (`main.bicep`) deployed via `az deployment mg what-if` / `New-AzManagementGroupDeployment -WhatIf` to enable plans at management-group scope — **what-if first**.
- **AWS/GCP security connectors** for multicloud.
- A **Log Analytics workspace** and the **SIEM** as continuous-export destinations.
- Least-privilege roles: **Security Reader** for read-only; **Security Admin** + **Owner/Contributor** at the target scope for enabling paid plans; **Management Group Contributor** for MG-scope deployment.

## Limitations (be honest with buyers)
- **Defender CSPM and every workload plan are paid** and priced per resource/node/transaction; foundational CSPM is free but posture-only. *Verify current plan pricing and availability in your tenant* — the cost model is an estimate, not a quote.
- **Inheritance is powerful but blunt** — enabling a plan at a high MG node protects *all* descendant subscriptions and bills for them; the design uses waves and scoping to control blast radius and spend.
- Multicloud connectors provide **posture and the available plans** for AWS/GCP; they are not a full replacement for each cloud's native deep controls.
- The Bicep skeleton is a **reference** to adapt to your naming/policy standards — it is deployed **what-if first** and reviewed, never blind-applied.
