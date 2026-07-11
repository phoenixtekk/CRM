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
