# Architecture Service — Microsoft Defender for Cloud

> **Version 1.0.0** · Category: Defender · Solution code: ARCMDC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Architecture Service: Microsoft Defender for Cloud

**White-label · Defender**

Rolling **Microsoft Defender for Cloud** across many subscriptions and clouds **without a design** produces exactly the problems it is meant to prevent: **inconsistent coverage** (some subscriptions protected, others not), **RBAC sprawl** (nobody sure who can change what), **no multicloud plan** (AWS/GCP posture as an afterthought), and **cost surprises** (paid plans switched on ad-hoc). This solution is an **architecture / design service**, not a single-subscription deployment: it delivers a **reference design** for Defender for Cloud at scale — a **management-group/subscription onboarding model**, a **plan-enablement strategy**, **multicloud (AWS/GCP) connectors**, an **RBAC and governance model**, **continuous-export/SIEM integration**, and a **cost model** — plus a **reference Bicep skeleton** you deploy **what-if first**.

This is a complete, **design-it-right-the-first-time** package. It gives an administrator or architect the blueprint and the infrastructure-as-code skeleton to enable Defender for Cloud **consistently** through the management-group hierarchy so new subscriptions inherit protection automatically — every deployment **plan/what-if first** and approval-gated.

## What you get
- A plain-language **Solution Overview** of Defender for Cloud at scale — the MG/subscription model, CSPM vs workload plans, multicloud connectors, RBAC, continuous export, and the cost drivers.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite (a management-group hierarchy, deployment identity, cost inputs).
- A **Design & Implementation Guide** that produces the reference architecture and rolls it out in waves — enable plans at management-group scope, wire RBAC and governance, connect AWS/GCP, and stand up continuous export/SIEM — deployed with the included Bicep, **what-if first**.
- A **reference Bicep skeleton** (`main.bicep`) that enables Defender plans at scale, plus PowerShell for read-only discovery, validation, and a **coverage + cost** report — the IaC artifacts, not just prose.
- A **decision/design record** so the architecture and its tradeoffs are documented.
- **Testing** and **Troubleshooting** guides for a confident, staged rollout.

## What this delivers
A **scalable, documented Defender for Cloud architecture**: plans enabled **consistently** at management-group scope so coverage is uniform and new subscriptions inherit it; a **clean RBAC model** (who reads posture, who enables plans, who governs exemptions); **AWS/GCP connectors** for multicloud coverage; **continuous export** to a Log Analytics workspace and the SIEM; and a **cost model** that makes the paid-plan spend predictable **before** you roll out — all captured as a design record and a Bicep skeleton.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — design the reference, validate it on a pilot management group / subscription with `what-if`, then expand in waves across the hierarchy and to AWS/GCP.

## Boundary
This solution delivers the **reference architecture, the IaC skeleton, and the cost model** — the *design*. Which regulatory standards apply, what the organization's risk appetite and exemption policy are, and whether a given cost is acceptable are the **customer's compliance, security, and finance functions'** determinations. Automated response and any production apply stay **what-if/approval-gated**. Plan pricing, plan availability, and multicloud connector requirements are **version-dependent** and flagged **verify current availability in your tenant**.

## Effort
An architect or administrator can produce the reference design and validate it on a pilot management group in a focused engagement, then expand wave by wave. The Bicep skeleton makes each subsequent wave a reviewed, what-if-first deployment rather than portal clicking. Multicloud connectors and workload plans scale the effort with estate size.


---


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


---


# 2. Requirements Guide — Architecture Service: Microsoft Defender for Cloud

Verify **every** requirement before designing and deploying. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, network access, pilot scope, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to designing Defender for Cloud at scale**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and IaC parameter.

## 2.1 A management-group hierarchy
**Description:** An Entra/Azure **management-group** hierarchy (at least a root and one intermediate node) that subscriptions sit under: the target node for scaled enablement is **`MDC Scope – Platform MG – Prod`**.
**Why:** Consistent, inheriting enablement is done at **management-group** scope; without an MG hierarchy every subscription drifts independently.
**Verify:** `portal.azure.com` → **Management groups**; run `ARCMDC-Discovery.ps1` to map the hierarchy and where subscriptions live.
**Implement-if-missing:** Design a minimal MG hierarchy (root → platform/landing-zone → workload groups) before enabling plans at scale.

## 2.2 A pilot management group or subscription
**Description:** A pilot scope to validate the design first: **`MDC Scope – Pilot MG – Pilot`** (a small management group) or a single pilot subscription.
**Why:** Enabling paid plans at a high MG node bills every descendant; the pilot limits blast radius and cost while the design is validated (per `global-requirements-defender.md` G6).
**Verify:** The pilot MG/subscription exists and contains representative workloads; `ARCMDC-Discovery.ps1` lists it.
**Implement-if-missing:** Create/choose the pilot scope before any `what-if`→apply.

## 2.3 A deployment identity with management-group rights
**Description:** An identity (user or service principal) with **Owner** or **Contributor + Security Admin** at the target management-group scope, for the Bicep deployment and plan enablement.
**Why:** Enabling paid plans and deploying at MG scope requires write access at that scope; a service principal is preferred for pipeline deployment.
**Verify:** Azure → **Access control (IAM)** at `MDC Scope – Platform MG – Prod`; `ARCMDC-Discovery.ps1` reports the running account's effective scope.
**Implement-if-missing:** Grant the minimum role at the narrowest MG node; prefer PIM eligible activation or a scoped deployment service principal.

## 2.4 Plan-enablement decision (which plans, which waves)
**Description:** A decision on which plans to enable — foundational CSPM (free), **Defender CSPM** (paid), and which **workload plans** (Servers, Storage, Containers, Key Vault, App Service, SQL, etc.) — and in what rollout **waves**.
**Why:** Every paid plan has cost and operational impact; the strategy sequences them so coverage and spend are deliberate.
**Verify:** `portal.azure.com` → **Microsoft Defender for Cloud → Environment settings → Defender plans**; `ARCMDC-Discovery.ps1` reports current plan tiers per subscription. *Verify current plan pricing/availability in your tenant.*
**Implement-if-missing:** Draft the plan-per-wave matrix in the design record (Implementation Step 2) before deploying.

## 2.5 Resource providers registered
**Description:** The **Microsoft.Security** resource provider (and **Microsoft.PolicyInsights**) registered on the subscriptions in scope.
**Why:** Defender for Cloud assessments, plans, and the auto-provisioning policies require the providers registered.
**Verify:** Azure → **Subscriptions → Resource providers** shows **Microsoft.Security** as Registered; `ARCMDC-Validate.ps1` checks this.
**Implement-if-missing:** Register the provider (`Register-AzResourceProvider -ProviderNamespace Microsoft.Security`) — the Bicep/MG policy can also drive this at scale.

## 2.6 Log Analytics workspace and SIEM target
**Description:** A Log Analytics workspace for **continuous export** and the **SIEM** destination it feeds: export named **`MDC Continuous Export – Platform MG – Prod`**.
**Why:** Recommendations, Secure Score, and alerts land in a workspace and flow to the SIEM for trending, hunting, and correlation (per `global-requirements-defender.md` G7).
**Verify:** `portal.azure.com` → **Log Analytics workspaces** and the SIEM connector; `ARCMDC-Discovery.ps1` reports workspaces.
**Implement-if-missing:** Provision (or reuse) a central workspace and confirm the SIEM ingestion path before wiring continuous export.

## 2.7 Multicloud inputs (AWS/GCP, if in scope)
**Description:** The AWS accounts / GCP projects to connect and the roles/service accounts the connector requires.
**Why:** Multicloud posture needs a connector and a trust relationship into the target cloud; it is optional and scoped separately.
**Verify:** `portal.azure.com` → **Environment settings → Add environment (AWS/GCP)** requirements; `ARCMDC-Discovery.ps1` lists existing connectors.
**Implement-if-missing:** Gather the AWS/GCP account inventory and required roles; connect only after the Azure pilot is validated. *Verify current connector requirements.*

## 2.8 Cost inputs and a budget owner
**Description:** The estate size inputs that drive plan cost (server/VM count, storage accounts, container nodes, SQL/Key Vault counts) and a named **finance/budget owner** who accepts the cost.
**Why:** Paid plans bill per resource; the cost model needs the counts, and someone must own the spend decision.
**Verify:** `ARCMDC-Report.ps1 -Mode Cost` produces an indicative estimate from discovered resource counts. *Pricing is version-dependent — verify current.*
**Implement-if-missing:** Collect the resource counts (the report helps) and confirm the budget owner before enabling paid plans. **Whether a cost is acceptable is finance's decision.**

## 2.9 Change control, pilot scope, and rollback
**Description:** An approved change record, the named pilot scope, and a documented rollback before enabling paid plans at MG scope.
**Why:** MG-scope enablement affects many subscriptions and incurs cost; the what-if-first, pilot-first approach and a written back-out are the safety net.
**Verify:** An approved change record, the pilot scope, and a written rollback (set plans back to Free / remove the MG assignment) exist.
**Implement-if-missing:** Capture the baseline (`ARCMDC-Report.ps1 -Mode Coverage -SaveBaseline`), define the pilot scope, and write the rollback before Step 3.

---
## Checklist
- [ ] Management-group hierarchy mapped — `ARCMDC-Discovery.ps1`
- [ ] Pilot MG / subscription `MDC Scope – Pilot MG – Pilot` chosen
- [ ] Deployment identity with MG-scope rights (Owner / Contributor + Security Admin)
- [ ] Plan-per-wave decision drafted (CSPM + workload plans)
- [ ] Microsoft.Security provider registered — `ARCMDC-Validate.ps1`
- [ ] Central Log Analytics workspace + SIEM target confirmed
- [ ] Multicloud (AWS/GCP) inputs gathered (if in scope)
- [ ] Cost inputs collected + budget owner named — `ARCMDC-Report.ps1 -Mode Cost`
- [ ] Change window, pilot scope, and rollback documented


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


# 3. Design & Implementation Guide — Architecture Service: Microsoft Defender for Cloud

Follow these steps **in order**. Steps 1–2 produce the **reference design** (the decision/design record); Steps 3–7 **deploy it in waves** with the included Bicep, **what-if first**, in the **Azure portal** (`https://portal.azure.com`) and the Azure CLI/PowerShell. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and IaC parameter.

> **Model:** Design the reference, validate it on the **pilot scope** `MDC Scope – Pilot MG – Pilot` with `what-if`, confirm inheritance and coverage, then expand wave by wave across the management-group hierarchy and to AWS/GCP. Every deployment is **`what-if` / plan first** and approval-gated. **Which standards, exemptions, and costs are acceptable are the compliance / security / finance teams' decisions.**

## Naming (set once, reuse verbatim)
- Platform (target) management group: `MDC Scope – Platform MG – Prod`
- Pilot management group / subscription: `MDC Scope – Pilot MG – Pilot`
- Continuous export: `MDC Continuous Export – Platform MG – Prod`
- Governance rule (recommendation ownership): `MDC Governance – Platform MG – Prod`
- Multicloud connectors: `MDC Connector – AWS Prod – Prod`, `MDC Connector – GCP Prod – Prod`
- Design/decision record: `MDC Architecture Decision Record – Platform – Prod`

## Step 1 — Assess: map the estate, current state, and cost inputs
1. `portal.azure.com` → **Management groups**. Map the hierarchy and where subscriptions sit; identify the target node `MDC Scope – Platform MG – Prod` and the pilot `MDC Scope – Pilot MG – Pilot`.
2. Run `ARCMDC-Discovery.ps1` to capture, read-only: the MG hierarchy, per-subscription Defender-for-Cloud plan tiers, registered providers, Log Analytics workspaces, existing connectors, and resource counts by type (the cost drivers).
3. Run `ARCMDC-Report.ps1 -Mode Coverage -SaveBaseline` to record the current coverage baseline, and `ARCMDC-Report.ps1 -Mode Cost` for an indicative paid-plan estimate from the discovered counts.

## Step 2 — Design: produce the reference architecture and decision record
1. Write the **decision/design record** `MDC Architecture Decision Record – Platform – Prod` capturing:
   - **Onboarding model** — which MG node plans are enabled at, and how inheritance covers current + future subscriptions.
   - **Plan-per-wave matrix** — foundational CSPM (all), Defender CSPM, and each workload plan (Servers, Storage, Containers, Key Vault, App Service, SQL, …) mapped to a rollout **wave**. *Verify current plan availability/pricing.*
   - **RBAC model** — Security Reader (read posture) / Security Admin (manage plans+policies) / Owner or Contributor at scope (enable paid plans) / Management Group Contributor (deploy) — least privilege by scope.
   - **Multicloud** — which AWS accounts / GCP projects connect, and in which wave.
   - **Continuous export / SIEM** — what is exported (recommendations, Secure Score, alerts) to which workspace and onward to the SIEM.
   - **Cost model** — the drivers and the indicative estimate, with the named budget owner.
2. Parameterize the included **`main.bicep`** to match the design (target MG, plans per wave, workspace, export). This is the deployable form of the design.

## Step 3 — Pilot deploy: enable plans on the pilot scope (what-if first)
1. **Preview** the Bicep against the pilot scope — run `ARCMDC-Deploy.ps1 -Scope 'MDC Scope – Pilot MG – Pilot'` (defaults to **`-WhatIf`**, i.e. `az deployment mg what-if`). Review exactly which plans would be set.
2. When the what-if is understood and approved, re-run with **`-Apply`** to enable the wave-1 plans on the pilot scope only.
3. Confirm the **Microsoft.Security** provider is registered on pilot subscriptions (the deployment/policy can drive this) — `ARCMDC-Validate.ps1`.

## Step 4 — Wire RBAC and governance on the pilot
1. Assign the **least-privilege roles** from the design at the pilot scope (Security Reader / Security Admin / Owner-Contributor).
2. **Microsoft Defender for Cloud → Governance rules → Create** → `MDC Governance – Platform MG – Prod` at the pilot scope: assign owners and due dates so recommendations are accountable. Structure the **exemption** policy (justified, time-bound) — *whether an exemption is acceptable is the security/compliance team's decision.*

## Step 5 — Stand up continuous export / SIEM on the pilot
1. **Microsoft Defender for Cloud → Environment settings → (pilot scope) → Continuous export** → create `MDC Continuous Export – Platform MG – Prod` exporting **recommendations, Secure Score, and alerts** to the central Log Analytics workspace.
2. Confirm the workspace feeds the **SIEM** (data connector / workspace ingestion). Run `ARCMDC-Validate.ps1` → confirms export configured and data path present.

## Step 6 — Validate the pilot (inheritance, coverage, RBAC, export)
1. Run `ARCMDC-Validate.ps1` → confirms plans enabled at the pilot scope, **inheritance** working (a subscription under the pilot MG shows the inherited plan), providers registered, governance rule present, and continuous export configured.
2. Run `ARCMDC-Report.ps1 -Mode Coverage -BaselinePath .\arcmdc-baseline.json` → confirms coverage rose on the pilot scope, and `-Mode Cost` to compare actual-vs-estimated drivers. Complete the **Testing Guide** before expanding.

## Step 7 — Expand: roll out waves across the hierarchy (and multicloud)
1. Re-target `main.bicep` at `MDC Scope – Platform MG – Prod` and deploy **wave by wave** — always `ARCMDC-Deploy.ps1` (`-WhatIf`) first, then `-Apply` — so new and existing subscriptions inherit each wave's plans.
2. Add **AWS/GCP connectors** (`MDC Connector – AWS Prod – Prod`, `MDC Connector – GCP Prod – Prod`) in their designed wave, after the Azure pilot is validated. *Verify current connector requirements.*
3. Roll the RBAC model, governance rule, and continuous export out to the expanded scope.
4. Re-baseline with `ARCMDC-Report.ps1 -Mode Coverage -SaveBaseline` after each wave and track coverage/cost drift. Update the decision record as the architecture evolves.

---
### Order of operations
`Assess estate + cost → design (decision record + Bicep) → pilot deploy plans (what-if→apply) → RBAC + governance → continuous export/SIEM → validate inheritance/coverage → expand waves across the MG hierarchy (+ AWS/GCP)`


---


# 5. Testing Guide — Architecture Service: Microsoft Defender for Cloud

Run these checks after the pilot deployment (Implementation Steps 3–6), and again after each expansion wave. Each test has a **pass/fail gate**; do not expand across the hierarchy until the pilot passes. Objects are referenced by the exact names from the Design & Implementation Guide.

## Test 1 — Design record and Bicep parameterized
**Procedure:** Confirm `MDC Architecture Decision Record – Platform – Prod` exists with the onboarding model, plan-per-wave matrix, RBAC model, multicloud plan, export design, and cost model; and that `main.bicep` parameters match it.
**Pass:** The design record is complete and the Bicep reflects it.
**Fail:** Missing sections or Bicep drift — complete Implementation Step 2 before deploying.

## Test 2 — Bicep what-if is clean before apply
**Procedure:** Run `ARCMDC-Deploy.ps1 -Scope 'MDC Scope – Pilot MG – Pilot'` (default `-WhatIf`). Review the predicted changes.
**Pass:** The what-if shows **only** the intended plan enablements at the pilot scope — no unexpected changes.
**Fail:** Unexpected or out-of-scope changes — fix the Bicep/parameters; do **not** `-Apply`. See Troubleshooting *What-if shows unexpected changes*.

## Test 3 — Plans enabled at the pilot scope
**Procedure:** Run `ARCMDC-Validate.ps1`. In **Environment settings → `MDC Scope – Pilot MG – Pilot` → Defender plans**, confirm the wave-1 plans (CSPM + the designed workload plans) are **On**.
**Pass:** The designed plans are enabled at the pilot scope.
**Fail:** Plans Off/Free — re-run Implementation Step 3 (`-Apply`); see Troubleshooting *Plan not enabling at MG scope*.

## Test 4 — Inheritance working (a child subscription inherits the plan)
**Procedure:** Run `ARCMDC-Validate.ps1`. Pick a subscription **under** `MDC Scope – Pilot MG – Pilot` and confirm it shows the **inherited** plan state (not configured per-subscription).
**Pass:** A child subscription inherits the plan from the management-group scope.
**Fail:** The child shows Free / no inheritance — confirm the plan was set at MG (not subscription) scope and the provider is registered; see Troubleshooting *Inheritance not applying*.

## Test 5 — Providers registered
**Procedure:** Run `ARCMDC-Validate.ps1`. Confirm **Microsoft.Security** is Registered on the pilot subscriptions.
**Pass:** The provider is registered wherever plans are enabled.
**Fail:** Not registered — register it (Implementation Step 3 / policy); see Troubleshooting *Provider not registered*.

## Test 6 — RBAC least-privilege and governance rule present
**Procedure:** Run `ARCMDC-Validate.ps1`. Confirm the designed roles are assigned at the pilot scope and `MDC Governance – Platform MG – Prod` exists with owners/due dates; exemptions are time-bound.
**Pass:** RBAC matches the design (least privilege) and the governance rule is in place.
**Fail:** Over-broad role or missing governance rule — align to the design; see Troubleshooting *RBAC sprawl / missing governance*.

## Test 7 — Continuous export and SIEM path working
**Procedure:** Run `ARCMDC-Validate.ps1`. In the central Log Analytics workspace, confirm recommendation/Secure-Score/alert data from `MDC Continuous Export – Platform MG – Prod` is arriving and reaching the SIEM.
**Pass:** Export data lands in the workspace and flows to the SIEM.
**Fail:** No data — confirm the export config, workspace, and SIEM connector; see Troubleshooting *Continuous export no data*.

## Test 8 — Coverage rose and cost matches the model
**Procedure:** Run `ARCMDC-Report.ps1 -Mode Coverage -BaselinePath .\arcmdc-baseline.json` and `-Mode Cost`.
**Pass:** Coverage on the pilot scope is **higher** than baseline and the actual plan/resource drivers are within the cost model's estimate.
**Fail:** Coverage unchanged or cost drivers far exceed the estimate — reconcile before expanding; see Troubleshooting *Cost exceeds the model*.

---
### Exit gate
All eight tests pass on the pilot scope **before** any hierarchy-wide or multicloud expansion (Implementation Step 7). Re-run Tests 2–8 after each wave and compare against the re-saved coverage baseline; keep every deployment **what-if first**.


---


# 6. Troubleshooting Guide — Architecture Service: Microsoft Defender for Cloud

Common field issues, in **symptom → cause → fix** form. Run `ARCMDC-Discovery.ps1` and `ARCMDC-Validate.ps1` first — most causes surface there.

## What-if shows unexpected changes
**Symptom:** `ARCMDC-Deploy.ps1 -WhatIf` predicts changes beyond the intended plan enablements (or on the wrong scope).
**Cause:** The Bicep parameters target the wrong management group, include plans not in the current wave, or drift from the design record.
**Fix:** Re-parameterize `main.bicep` to the pilot scope and wave-1 plans only; reconcile against `MDC Architecture Decision Record – Platform – Prod`; re-run the what-if until it shows **only** the intended changes. Do **not** `-Apply` until it is clean.

## Plan not enabling at MG scope
**Symptom:** After `-Apply`, plans still show Off/Free at `MDC Scope – Pilot MG – Pilot`.
**Cause:** The deployment identity lacks **Owner / Contributor + Security Admin** at the MG scope, the **Microsoft.Security** provider isn't registered, or the plan isn't available in the region/tenant.
**Fix:** Confirm the identity's role at the MG node (Requirements 2.3); register the provider; *verify the plan's availability/pricing in your tenant*. Re-run `ARCMDC-Deploy.ps1 -Apply` and `ARCMDC-Validate.ps1`.

## Inheritance not applying
**Symptom:** A subscription under the pilot MG shows Free / no inherited plan.
**Cause:** The plan was set at **subscription** scope (or a lower MG) instead of the intended MG node, the subscription overrides inheritance with its own setting, or the provider isn't registered on it.
**Fix:** Confirm the plan is set at the **management-group** scope; remove any conflicting per-subscription override; register **Microsoft.Security** on the subscription. Re-check with `ARCMDC-Validate.ps1` (Test 4).

## Provider not registered
**Symptom:** `ARCMDC-Validate.ps1` reports **Microsoft.Security** not registered on a subscription.
**Cause:** The provider was never registered, or a new subscription joined without it.
**Fix:** `Register-AzResourceProvider -ProviderNamespace Microsoft.Security` on the subscription, or let the MG-scope Azure Policy auto-register it. Allow a few minutes and re-validate.

## RBAC sprawl / missing governance
**Symptom:** Over-broad roles (e.g. Owner where Security Reader suffices) or no governance rule at scope.
**Cause:** Roles granted ad-hoc during rollout, or Step 4 skipped.
**Fix:** Re-align role assignments to the least-privilege model in the design record; grant at the narrowest MG node; create `MDC Governance – Platform MG – Prod` with owners/due dates and time-bound exemptions. Re-run `ARCMDC-Validate.ps1`. *Exemption acceptability is the security/compliance team's decision.*

## Continuous export no data
**Symptom:** The central Log Analytics workspace (or the SIEM) receives no recommendation/score/alert data.
**Cause:** `MDC Continuous Export – Platform MG – Prod` is misconfigured, points at the wrong workspace, the exported data types are wrong, or the SIEM connector isn't wired.
**Fix:** Confirm the export config, workspace, and exported types (recommendations + Secure Score + alerts); confirm the SIEM ingestion path; allow ingestion time. Re-run `ARCMDC-Validate.ps1` and query the workspace.

## Cost exceeds the model
**Symptom:** Actual Defender for Cloud spend is well above `ARCMDC-Report.ps1 -Mode Cost`'s estimate.
**Cause:** A plan was enabled at a higher MG node than intended (billing more descendant resources), resource counts grew, or a costly workload plan landed in an early wave.
**Fix:** Check where each plan is enabled in the MG hierarchy; move expensive plans to later waves or a narrower scope; re-run the cost report with current counts; confirm with the budget owner. *Whether the cost is acceptable is finance's decision.* Rollback: set the plan back to Free or remove the MG-scope assignment.

## Multicloud connector not reporting
**Symptom:** An AWS/GCP connector is added but no posture/recommendations appear.
**Cause:** The connector's role/service account in the target cloud is missing permissions, the connection is still initializing, or the plan for that connector isn't enabled.
**Fix:** *Verify current connector requirements*; confirm the AWS role / GCP service account permissions; allow initialization time; confirm the connector's plans are on. Re-check with `ARCMDC-Discovery.ps1`.

## Script or deployment cannot authenticate
**Symptom:** `ARCMDC-*.ps1` fails on connect, or the MG deployment errors on auth/scope.
**Cause:** The Az modules (`Az.Accounts`, `Az.Security`, `Az.Resources`) are missing, the account isn't signed in, or it lacks rights at the MG scope.
**Fix:** Let the script install the modules; `Connect-AzAccount`; confirm the identity has the required MG-scope role; for pipeline runs use a scoped deployment service principal. Re-run.


---


# 7. Best Practices — Architecture Service: Microsoft Defender for Cloud

Field-proven guidance for designing Defender for Cloud so it scales consistently, stays governed, and doesn't surprise you on cost.

## Enable at management-group scope, not subscription by subscription
- The whole point of the design is **inheritance**: enable plans at `MDC Scope – Platform MG – Prod` so every current and future subscription is protected automatically. Per-subscription enablement is exactly the drift this solution exists to prevent.
- Use the MG hierarchy and rollout **waves** to control blast radius — a plan enabled at a high node protects *and bills* every descendant.

## Design before you deploy — and keep the decision record
- Write `MDC Architecture Decision Record – Platform – Prod` first: the onboarding model, plan-per-wave matrix, RBAC, multicloud, export, and cost model. A rollout without a design record is how RBAC sprawl and cost surprises happen.
- Keep the record current as the architecture evolves — it is the map the next engineer (and the next audit) relies on.

## Deploy what-if first, always
- Every Bicep deployment runs `ARCMDC-Deploy.ps1 -WhatIf` (`az deployment mg what-if`) first; review the predicted changes; only then `-Apply`. Never blind-apply infrastructure that enables paid plans across an estate.
- Treat `main.bicep` as a **reference to adapt** to your naming/policy standards, source-controlled and peer-reviewed, not a one-off.

## Keep RBAC least-privilege by scope
- Map roles to jobs: **Security Reader** (read posture), **Security Admin** (manage plans/policies), **Owner/Contributor** at scope (enable paid plans), **Management Group Contributor** (deploy). Grant at the **narrowest** MG node and prefer PIM eligible activation over standing access.

## Make governance and exemptions explicit
- Use `MDC Governance – Platform MG – Prod` to assign owners and due dates so recommendations are accountable at scale. Every exemption is **justified and time-bound** — never a silent, permanent suppression. *Whether an exemption is acceptable is the security/compliance team's decision.*

## Export once, centrally, to the SIEM
- Stream recommendations, Secure Score, and alerts to a **central** Log Analytics workspace and onward to the SIEM (`MDC Continuous Export – Platform MG – Prod`). One central export beats per-subscription exports for trending, hunting, and correlation.

## Model cost before you roll out, and name a budget owner
- Paid plans bill per resource/node/transaction. Use `ARCMDC-Report.ps1 -Mode Cost` to estimate from real counts, sequence expensive plans into later waves, and get a **named finance owner** to accept the spend. **Whether a cost is acceptable is finance's decision** — the model informs it.
- **Verify current plan pricing and availability in your tenant** — the model is an estimate, not a quote.

## Add multicloud after the Azure pilot is solid
- Connect AWS/GCP (`MDC Connector – AWS Prod – Prod` / `– GCP Prod – Prod`) in their designed wave, once the Azure onboarding model, RBAC, and export are proven. Multicloud connectors give posture and the available plans — not a substitute for each cloud's deep native controls.

## Where to go next
Once the architecture is deployed and inheriting, natural next steps in the catalog:
- **Microsoft Defender for Cloud — CSPM & Secure Score Remediation** to *operate* posture and drive Secure Score on the platform this design stands up.
- **Microsoft Defender for Cloud — Workload Protection Plans** to deepen the CWPP (Servers/Storage/Containers/SQL) coverage the waves enable.
- **Azure Security Baseline & Governance** to enforce secure configuration with Azure Policy guardrails alongside Defender for Cloud.
- The **Sentinel** solutions to turn the continuous-export/SIEM feed into hunting and SOAR.


---


# 8. Deliverables Summary — Architecture Service: Microsoft Defender for Cloud

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box — a reference design, not a single-subscription deployment |
| 1. Solution Overview | Defender for Cloud at scale — MG/subscription onboarding model, CSPM vs workload plans, multicloud connectors, RBAC, continuous export, cost drivers; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites (MG hierarchy, deployment identity, cost inputs) with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Design & Implementation Guide | Produce the reference design + decision record, then deploy in waves with Bicep — what-if first, pilot MG first |
| 5. Testing Guide | Eight validation tests with pass/fail gates (inheritance, coverage, RBAC, export, cost) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## Infrastructure-as-code + PowerShell (Bicep + Az + KQL/Resource Graph)
| Artifact | What it does |
|---|---|
| `main.bicep` | **Reference architecture skeleton** — enables Defender for Cloud plans (CSPM + workload plans) at **management-group** scope so subscriptions inherit protection; parameterized per the design; deployed **what-if first** |
| `ARCMDC-Discovery.ps1` | Read-only discovery — management-group hierarchy, per-subscription plan tiers, registered providers, Log Analytics workspaces, existing AWS/GCP connectors, and resource counts (the cost drivers) |
| `ARCMDC-Deploy.ps1` | `-WhatIf`-gated deployment helper that runs the Bicep as an MG-scope `what-if` by default and applies only with `-Apply` (safe preview by default) |
| `ARCMDC-Validate.ps1` | Confirms plans enabled at scope, **inheritance** working, providers registered, governance rule present, RBAC least-privilege, and continuous export configured |
| `ARCMDC-Report.ps1` | Coverage report (with drift vs a saved baseline) and an indicative **cost model** (`-Mode Cost`) from discovered resource counts — the two numbers the design has to get right |

## What the buyer receives
- This solution as a branded **Word** document and **PDF**, including the reference architecture and decision-record structure.
- The **reference Bicep skeleton** (`main.bicep`) plus four **PowerShell scripts** (Az + KQL/Resource Graph) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot management group first, every deployment **what-if / plan first**, with a documented rollback and a cost model.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A scalable, documented Defender for Cloud architecture — plans enabled **consistently** at management-group scope so coverage is uniform and new subscriptions inherit it, a **clean least-privilege RBAC** and governance model, **AWS/GCP connectors** for multicloud, **continuous export** to a central workspace and the SIEM, and a **predictable cost model** — captured as a design record and a what-if-first Bicep skeleton, and validated on a pilot management group before it scales.
