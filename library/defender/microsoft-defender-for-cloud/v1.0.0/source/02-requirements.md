# 2. Requirements Guide — Microsoft Defender for Cloud

Verify **every** requirement before designing, enabling, training, or proving. Each entry:
**Description · Why · Verify · Implement-if-missing.** The category-wide prerequisites (Microsoft 365 /
Entra tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, Log
Analytics workspace, response governance) are in **`global-requirements-defender.md`** — read that first;
the items below are **specific to this complete Defender for Cloud solution**. Objects are named
`<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and IaC parameter.

## 2.1 A management-group hierarchy and a pilot scope
**Description:** An Azure **management-group** hierarchy (at least a root and one intermediate node) with
subscriptions under it — the target node for scaled enablement is **`MDC Scope – Platform MG – Prod`** —
plus a **pilot** scope **`MDC Scope – Pilot MG – Pilot`** (a small MG or single subscription) to validate
first.
**Why:** Consistent, inheriting enablement is done at MG scope; the pilot limits blast radius and cost
while the design is validated (per `global-requirements-defender.md` G6).
**Verify:** `portal.azure.com → Management groups`; run `MDCFULL-Discovery.ps1` to map the hierarchy and
where subscriptions sit.
**Implement-if-missing:** Design a minimal hierarchy (root → platform/landing-zone → workload groups)
and choose the pilot scope before enabling plans at scale.

## 2.2 A deployment identity with management-group rights
**Description:** An identity (user or service principal) with **Owner** or **Contributor + Security
Admin** at the target MG scope, for the Bicep deployment and plan enablement; **Security Reader** for
read-only work.
**Why:** Enabling paid plans and deploying at MG scope requires write access at that scope; a service
principal is preferred for pipeline deployment.
**Verify:** Azure → **Access control (IAM)** at `MDC Scope – Platform MG – Prod`; `MDCFULL-Discovery.ps1`
reports the running account's effective scope.
**Implement-if-missing:** Grant the minimum role at the narrowest MG node; prefer PIM eligible
activation or a scoped deployment service principal.

## 2.3 Resource providers registered
**Description:** The **Microsoft.Security** resource provider (and **Microsoft.PolicyInsights**)
registered on the subscriptions in scope.
**Why:** MDC assessments, plans, and the auto-provisioning policies require the providers registered.
**Verify:** Azure → **Subscriptions → Resource providers** shows **Microsoft.Security** as Registered;
`MDCFULL-Validate.ps1` checks this.
**Implement-if-missing:** `Register-AzResourceProvider -ProviderNamespace Microsoft.Security` — the
Bicep/MG policy can also drive this at scale.

## 2.4 Plan-enablement decision (which plans, which waves) and cost approval
**Description:** A decision on which plans to enable — foundational CSPM (free), **Defender CSPM**
(paid), and which **workload plans** (Servers, Containers, Databases, Storage, Key Vault, App Service,
Resource Manager) — in what rollout **waves**, with **business cost approval** and a named **budget
owner** for the paid plans.
**Why:** Every paid plan is billed per protected resource/node/transaction; the strategy sequences them
so coverage and spend are deliberate, and someone must own the spend.
**Verify:** `portal.azure.com → Microsoft Defender for Cloud → Environment settings → Defender plans`;
`MDCFULL-Discovery.ps1` reports current plan tiers per subscription and `MDCFULL-Report.ps1 -Mode Cost`
produces an indicative estimate from discovered resource counts. *Verify current plan pricing/availability
in your tenant — the model is an estimate, not a quote.*
**Implement-if-missing:** Draft the plan-per-wave matrix in the design record, collect the resource
counts, and confirm the budget owner before enabling paid plans. **Whether a cost is acceptable is
finance's decision.**

## 2.5 Agents/extensions provisioning for Servers
**Description:** The **Defender for Endpoint** integration and the required agent/extension (Azure
Monitor Agent, and **Azure Arc** for non-Azure servers) auto-provisioned for Defender for Servers.
**Why:** Server threat detection depends on the MDE sensor and monitoring agent being provisioned and
healthy.
**Verify:** **Environment settings → Defender plans → Servers → Settings** shows auto-provisioning;
`MDCFULL-Validate.ps1 -Plan Servers` reports agent coverage. *Verify current agent/extension
requirements.*
**Implement-if-missing:** Enable auto-provisioning of the MDE integration and monitoring agent; connect
non-Azure servers via **Azure Arc**.

## 2.6 Log Analytics workspace and SIEM target for continuous export
**Description:** A central Log Analytics workspace for **continuous export** and the **SIEM** it feeds:
export named **`MDC Continuous Export – Platform MG – Prod`** (reuse the SIEM/observability workspace
where appropriate — see `global-requirements-defender.md` G7).
**Why:** Recommendations, Secure Score, and alerts land in a workspace and flow to the SIEM for trending,
hunting, and correlation.
**Verify:** `portal.azure.com → Log Analytics workspaces` and the SIEM connector; `MDCFULL-Discovery.ps1`
reports workspaces.
**Implement-if-missing:** Provision/select a central workspace and confirm the SIEM ingestion path
before wiring continuous export.

## 2.7 Alert-tuning plan and a notify-first response workflow
**Description:** A plan for **alert tuning** (which known-benign alerts get the suppression rule
**`MDC Alert Suppression – Benign FP – Prod`**, severities, and notification recipients) and a
**workflow automation** (Logic App) **`MDC Workload Response – Tenant – Prod`** kept **notify/approval-
gated** — not auto-remediating — during the pilot.
**Why:** Untuned workload alerts create noise that buries real detections; automated remediation on
cloud workloads can disrupt production, so the organization decides the guardrails (per
`global-requirements-defender.md` G8).
**Verify:** `MDCFULL-Report.ps1 -Mode Alerts` lists current alerts/suppression; `MDCFULL-Validate.ps1
-Plan Workflow` reports the workflow is notify-only.
**Implement-if-missing:** Draft the suppression rule, set email notifications, and create the workflow in
notify-only mode. *Incident-response and auto-remediation decisions are the SOC/security team's.*

## 2.8 A pilot subscription with Secure Score populated (for enablement labs)
**Description:** A pilot subscription with MDC reachable, **Secure Score and recommendations populated**,
and at least one Defender plan on (for the alerts lab).
**Why:** The Phase C labs read live posture and alerts; assessments take time to populate after a
subscription is onboarded.
**Verify:** **Defender for Cloud → Overview / Secure Score / Environment settings** for the pilot;
`MDCFULL-Validate.ps1` reports whether Secure Score data is present and a plan is on.
**Implement-if-missing:** Nominate a non-production pilot subscription; allow an assessment warm-up
window (*timing varies — verify in your tenant*); enable an inexpensive plan (e.g. Resource Manager or
Storage) for the alerts lab.

## 2.9 Attendee/facilitator access and workstation tooling (for the labs)
**Description:** Attendees hold **Security Reader / Reader** on the pilot; the facilitator holds a
change-capable role (**Security Admin / Owner**) for the `-WhatIf` rehearsal. The Az modules
(`Az.Accounts`, `Az.Security`, `Az.ResourceGraph`) and **Azure Resource Graph / Advanced hunting** access
are available.
**Why:** Least privilege — attendees learn read-only; only the facilitator demonstrates a change, and
only in `-WhatIf`. The lab helpers and KQL pack query posture/alert data.
**Verify:** Azure → subscription → **Access control (IAM)**; `Get-Module -ListAvailable Az.Security,
Az.ResourceGraph`; in **Resource Graph Explorer** run `securityresources | take 5`.
**Implement-if-missing:** Assign the roles on the **pilot only**; `Install-Module Az -Scope CurrentUser`;
grant Reader (ARG honors resource RBAC) and an advanced-hunting-read role for Defender XDR hunting.

## 2.10 Multicloud inputs (AWS/GCP, if in scope)
**Description:** The AWS accounts / GCP projects to connect and the roles/service accounts the connector
requires — connectors **`MDC Connector – AWS Prod – Prod`**, **`MDC Connector – GCP Prod – Prod`**.
**Why:** Multicloud posture needs a connector and a trust relationship into the target cloud; it is
optional and scoped to a later wave.
**Verify:** `portal.azure.com → Environment settings → Add environment (AWS/GCP)` requirements;
`MDCFULL-Discovery.ps1` lists existing connectors.
**Implement-if-missing:** Gather the AWS/GCP account inventory and required roles; connect only after the
Azure pilot is validated. *Verify current connector requirements.*

## 2.11 A pilot resource group and evaluation criteria (for the PoC)
**Description:** A pilot resource group **`MDC PoC – Pilot RG – Pilot`** for the benign PoC test resource,
and written **evaluation criteria** the scorecard is measured against.
**Why:** The Phase D PoC runs on one subscription with a disposable, benign test resource; an objective
verdict needs the criteria agreed up front.
**Verify:** The RG exists (or one is chosen); a `criteria.json` of pass/fail bars exists.
**Implement-if-missing:** Create the RG and draft the criteria (recommendation raised, Secure Score
present, alert fired, compliance populated, latency acceptable) before Phase D.

## 2.12 Change control, pilot scope, and rollback
**Description:** An approved change record, the named pilot scope, and a documented rollback before
enabling paid plans at MG scope.
**Why:** MG-scope enablement affects many subscriptions and incurs cost; the what-if-first, pilot-first
approach and a written back-out are the safety net.
**Verify:** An approved change record, the pilot scope, and a written rollback (set plans back to Free /
remove the MG assignment / delete the PoC test resource) exist.
**Implement-if-missing:** Capture the baseline (`MDCFULL-Report.ps1 -Mode Coverage -SaveBaseline`),
define the pilot scope, and write the rollback before any `-Apply`.

---
## Checklist
- [ ] Management-group hierarchy mapped + pilot scope chosen — `MDCFULL-Discovery.ps1`
- [ ] Deployment identity with MG-scope rights (Owner / Contributor + Security Admin)
- [ ] Microsoft.Security provider registered — `MDCFULL-Validate.ps1`
- [ ] Plan-per-wave decision drafted + cost approval + budget owner — `MDCFULL-Report.ps1 -Mode Cost`
- [ ] Agents/extensions provisioning for Servers (MDE + monitoring agent + Arc)
- [ ] Central Log Analytics workspace + SIEM target (`MDC Continuous Export – Platform MG – Prod`)
- [ ] Alert-tuning plan + notify-only response workflow (`MDC Alert Suppression – Benign FP – Prod`, `MDC Workload Response – Tenant – Prod`)
- [ ] Pilot subscription with Secure Score populated + a plan on (labs)
- [ ] Attendee/facilitator access + Az modules + ARG access (labs)
- [ ] Multicloud (AWS/GCP) inputs gathered (if in scope)
- [ ] PoC pilot RG (`MDC PoC – Pilot RG – Pilot`) + written evaluation criteria
- [ ] Change window, pilot scope, and rollback documented
