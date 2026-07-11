# Microsoft Defender for Cloud — Workload Protection Plans (CWPP)

> **Version 1.0.0** · Category: Defender · Solution code: MDCWP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

**White-label · Defender**

Cloud security posture management (CSPM) tells you what is **misconfigured**; it does not catch what is **actively attacking** a running workload. That is the job of Microsoft Defender for Cloud's **workload protection plans** — the cloud workload protection platform (**CWPP**) layer. Many tenants have turned on the free CSPM/Secure Score capabilities but left the workload plans **off**, so a brute-forced SQL server, a crypto-miner in an AKS pod, a malware upload to a storage account, or an anomalous Key Vault access goes undetected. This solution enables and tunes Defender for Cloud's **workload plans** — **Servers** (P1/P2, with Defender for Endpoint integration), **Containers** (AKS + registry scanning + runtime), **Databases** (Azure SQL, open-source, Cosmos DB), **Storage**, **Key Vault**, **App Service**, and **Resource Manager** — with **alert tuning**, suppression rules, and a **workload response workflow** — enabled first on a pilot subscription, validated, then expanded.

This is a complete, **deploy-it-today** package written for an administrator with no prior Defender for Cloud CWPP experience. It enables plans on a **pilot subscription first**, keeps any automated response **approval-gated**, and treats **cost** as a first-class consideration (workload plans are billed per protected resource).

## What you get
- A plain-language **Solution Overview** of the CSPM-vs-CWPP distinction and each workload plan.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite.
- An **Implementation Guide** of exact, ordered steps — enable plans on the pilot subscription, wire MDE integration and export, tune alerts, add a response workflow — pilot-first.
- Five **PowerShell scripts** (Az / Microsoft.Graph Security) plus **KQL** for readiness discovery, plan/coverage validation, alert & cost reporting, a `-WhatIf`-gated plan-enablement helper, and a workload-alert hunt.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
Active workload threat protection across **servers, containers, databases, storage, Key Vault, and App Service** — the CWPP layer on top of your CSPM posture — with alerts tuned to signal, a response workflow ready, and cost understood, enabled on a pilot subscription and expanded with confidence.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — enable plans on a pilot subscription, wire integration and export, tune alerts, validate a benign alert fires, then expand across subscriptions.

## Boundary
This solution is the **CWPP / workload-protection** layer of Defender for Cloud. It **complements**, and cross-references rather than duplicates, the catalog's **Defender for Cloud — CSPM & Secure Score** solution (posture management). Regulatory/records/legal determinations, production change approval, and incident-response decisions remain the customer's compliance, operations, and security functions; this guide provides the technical configuration.

## Effort
A competent administrator can enable and validate the pilot-subscription plans in a focused engagement, then expand across subscriptions on a controlled cadence. Rollout — and cost — scale with the number of protected resources (servers, databases, storage accounts, clusters).


---


# 1. Solution Overview — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

## What Defender for Cloud workload protection is
Microsoft Defender for Cloud has two layers. **CSPM** (cloud security posture management) is the free, always-on layer that scores your configuration against benchmarks and surfaces misconfigurations. **CWPP** (cloud workload protection platform) is the **paid, per-resource** layer — the **workload protection plans** — that actively detects threats *against running workloads* and raises security **alerts**. This solution turns on and tunes the CWPP plans:

- **Defender for Servers (P1 / P2)** — threat detection for Windows/Linux VMs (Azure, and Arc-connected on-prem/multicloud), integrated with **Defender for Endpoint**; P2 adds features like vulnerability assessment, file integrity monitoring, and just-in-time VM access. *P1 vs P2 features differ — verify current availability.*
- **Defender for Containers** — Kubernetes/AKS runtime threat detection, registry image **vulnerability scanning**, and hardening.
- **Defender for Databases** — Azure SQL, SQL on VMs, **open-source relational** (MySQL/PostgreSQL/MariaDB), and **Cosmos DB** — detecting SQL injection, brute force, and anomalous access.
- **Defender for Storage** — malware scanning and anomalous-access detection for blob storage.
- **Defender for Key Vault** — detection of unusual secret/key access.
- **Defender for App Service** and **Defender for Resource Manager** — detection for web apps and control-plane operations.

Configuration is in the **Azure portal → Microsoft Defender for Cloud → Environment settings**, per subscription; alerts surface both there and in the unified Defender portal at `security.microsoft.com`.

## Why this matters
CSPM shows a misconfigured storage account; CWPP catches the malware someone just uploaded to it. CSPM shows a SQL server exposed; CWPP catches the brute-force attack hitting it right now. Posture and protection are complementary — posture reduces the attack surface, workload protection detects the attack that gets through. A tenant running only CSPM has no runtime detection on its most valuable assets. Because the plans are **billed per protected resource**, they are often left off "to save money" — but the right approach is to enable them deliberately, tune the alerts so they are actionable, and understand the cost, not to leave the workloads blind. This solution does exactly that, pilot-first.

## How it works
1. **Plans are enabled** on a **pilot subscription** (`MDC Workload Plans – Pilot Subscription – Pilot`) under **Environment settings** — Servers, Containers, Databases, Storage, Key Vault, App Service, Resource Manager, at the appropriate plan tier.
2. **Defender for Servers** integrates with **Defender for Endpoint** (auto-provisioned) so server threat detection uses the MDE sensor; the Log Analytics agent / Azure Monitor Agent is provisioned as required. *Verify current agent/extension requirements.*
3. **Containers** enables registry scanning and the AKS runtime defensive components; **Databases** and **Storage** enable at the resource/subscription level.
4. **Continuous export** streams alerts/recommendations to a Log Analytics workspace (and optionally to the SIEM) for hunting and retention.
5. **Alert tuning** — noisy or benign alerts get **suppression rules**; severities and email notifications are set so the SOC gets signal, not noise.
6. **A response workflow** (workflow automation → Logic App) is created to route high-severity workload alerts to the right channel — kept **notify/approval-gated**, not auto-remediating, during the pilot.
7. **Validation** confirms plans are on, coverage is complete, and a benign, controlled alert (e.g. an EICAR-style storage test or a Microsoft sample alert) fires.

## What you can control
- **Which plans** are enabled and at **which tier** (e.g. Servers P1 vs P2) per subscription.
- **Scope** — which subscriptions/resources are protected (pilot first).
- **Alert tuning** — suppression rules, severities, notification recipients.
- **Continuous export** destination — workspace and/or SIEM.
- **Response workflow** — how high-severity alerts are routed, kept notify/approval-gated.
- **Cost posture** — plans are per-resource; you control coverage vs spend.

## Limitations (be honest with buyers)
- Workload plans are **paid, per protected resource** — enabling broadly has a cost; enable deliberately and monitor spend. *Verify current pricing and plan tiers.*
- **Plan features differ by tier** (Servers P1 vs P2) and by resource type — *verify current availability in your subscription.*
- Some detections depend on **agents/extensions** (MDE, Azure Monitor Agent) being provisioned and healthy — coverage is only as good as the provisioning.
- **Alerts and hunting data populate over time** — allow warm-up after enabling.
- CWPP detects threats to workloads; it does not replace CSPM posture remediation, patching, backup, network controls, or the SOC's incident-response decisions.

## Connections and authentication used
- The **Azure portal** → **Microsoft Defender for Cloud → Environment settings** (per subscription) for plan enablement, agents, continuous export, and workflow automation.
- The **unified Defender portal** (`security.microsoft.com`) where workload alerts also surface.
- **Az PowerShell** (`Az.Security`, `Az.Accounts`, `Az.Resources`) for read-only discovery, validation, plan enablement (approval-gated helper), and reporting; **Microsoft Graph Security** / **KQL** for alert hunting.
- Least-privilege roles: **Security Reader** for read-only; **Security Admin** (Defender for Cloud) or **Owner/Contributor** on the subscription for plan changes; **Global/Security Administrator** only where tenant-level activation applies.

## The standard deployment model
> **Assess readiness (subscriptions, current plan state, agents, workspace) → enable the workload plans on a pilot subscription and wire MDE/export → tune alerts and add a notify-first response workflow → validate coverage and a benign alert on the pilot → expand across subscriptions.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with automated response kept approval-gated and cost monitored throughout.


---


# 2. Requirements Guide — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to enabling Defender for Cloud's workload protection plans**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Azure subscription(s) with Defender for Cloud onboarded
**Description:** One or more Azure subscriptions with Microsoft Defender for Cloud registered, and a chosen **pilot subscription**.
**Why:** Workload plans are enabled per subscription under Environment settings; the pilot is validated before the rest.
**Verify:** Azure portal → **Microsoft Defender for Cloud → Environment settings** lists the subscriptions. Run `MDCWP-Discovery.ps1`.
**Implement-if-missing:** Register the `Microsoft.Security` resource provider and pick the pilot subscription `MDC Workload Plans – Pilot Subscription – Pilot`.

## 2.2 Subscription roles for plan changes
**Description:** **Security Admin** (Defender for Cloud) or **Owner/Contributor** on the pilot subscription to enable plans; **Security Reader** for read-only work.
**Why:** Enabling paid workload plans changes billing and configuration and requires elevated rights.
**Verify:** Azure portal → **Subscription → Access control (IAM)**; `MDCWP-Discovery.ps1` reports the running account's rights. 
**Implement-if-missing:** Assign least-privilege roles; reserve plan changes for an approved change window (they incur cost).

## 2.3 Cost approval for paid plans
**Description:** Business approval to enable the paid workload plans on the scoped resources, with an understanding of the per-resource pricing.
**Why:** Plans are billed per protected server/database/storage account/etc.; enabling broadly has a real cost.
**Verify:** A cost estimate exists for the pilot scope; `MDCWP-Report.ps1 -Section Cost` lists protected-resource counts per plan. *Verify current pricing and plan tiers.*
**Implement-if-missing:** Estimate the pilot cost, get approval, and enable on the pilot subscription only first.

## 2.4 Agents/extensions provisioning for Servers
**Description:** The **Defender for Endpoint** integration and the required agent/extension (Azure Monitor Agent, and Azure Arc for non-Azure servers) auto-provisioned for Defender for Servers.
**Why:** Server threat detection depends on the MDE sensor and monitoring agent being provisioned and healthy.
**Verify:** **Environment settings → Defender plans → Servers → Settings** shows auto-provisioning; `MDCWP-Validate.ps1 -Plan Servers` reports agent coverage. *Verify current agent/extension requirements.*
**Implement-if-missing:** Enable auto-provisioning of the MDE integration and monitoring agent; connect non-Azure servers via **Azure Arc**.

## 2.5 Log Analytics workspace for continuous export
**Description:** A Log Analytics workspace to receive Defender for Cloud **continuous export** of alerts/recommendations (reuse the SIEM/observability workspace where appropriate — see `global-requirements-defender.md` G7).
**Why:** Export enables hunting, retention, and SIEM integration of workload alerts.
**Verify:** A workspace exists and `MDCWP-Discovery.ps1` reports it; export target is chosen.
**Implement-if-missing:** Provision/select the workspace `MDC Continuous Export – Workspace – Prod` and configure export (Step 4).

## 2.6 Alert-tuning and suppression plan
**Description:** A plan for **alert tuning** — which known-benign alerts get suppression rules, alert severities, and notification recipients.
**Why:** Untuned workload alerts create noise that buries real detections; tuning is what makes the SOC trust them.
**Verify:** `MDCWP-Report.ps1 -Section Alerts` lists current alerts and any suppression rules. 
**Implement-if-missing:** Draft the suppression rule `MDC Alert Suppression – Benign FP – Prod` and set email notifications (Step 5).

## 2.7 Response workflow and governance
**Description:** A **workflow automation** (Logic App) to route high-severity workload alerts, kept **notify/approval-gated** — not auto-remediating — during the pilot, with an agreed response-governance position.
**Why:** Automated remediation on cloud workloads can disrupt production; the organization decides the guardrails (per `global-requirements-defender.md` G8).
**Verify:** A documented response policy exists; the workflow only notifies/creates tickets during the pilot. `MDCWP-Validate.ps1 -Plan Workflow` reports it. 
**Implement-if-missing:** Create `MDC Workload Response – Tenant – Prod` in notify-only mode; *incident-response and auto-remediation decisions are the SOC/security team's — this guide covers the technical configuration.*

---
## Checklist
- [ ] Azure subscription(s) onboarded + pilot chosen (`MDC Workload Plans – Pilot Subscription – Pilot`) — `MDCWP-Discovery.ps1`
- [ ] Subscription roles for plan changes (Security Admin / Owner)
- [ ] Cost approval for paid plans — `MDCWP-Report.ps1 -Section Cost`
- [ ] Agents/extensions provisioning for Servers (MDE + monitoring agent + Arc)
- [ ] Log Analytics workspace for continuous export (`MDC Continuous Export – Workspace – Prod`)
- [ ] Alert-tuning / suppression plan (`MDC Alert Suppression – Benign FP – Prod`)
- [ ] Response workflow (notify-only) + governance (`MDC Workload Response – Tenant – Prod`)


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


# 3. Implementation Guide — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

Follow these steps **in order**. Most configuration is in the **Azure portal → Microsoft Defender for Cloud → Environment settings** (per subscription); alerts also surface in the unified Defender portal (`security.microsoft.com`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Enable the workload plans on **one pilot subscription** first, wire the MDE integration and continuous export, tune the alerts, add a **notify-only** response workflow, validate coverage and that a benign alert fires, and only then expand across subscriptions. Keep automated **response** notify/approval-gated throughout, and **monitor cost** — plans are billed per protected resource. Never auto-remediate a production workload to "test."

## Naming (set once, reuse verbatim)
- Pilot subscription scope: `MDC Workload Plans – Pilot Subscription – Pilot`
- Continuous-export workspace: `MDC Continuous Export – Workspace – Prod`
- Alert suppression rule: `MDC Alert Suppression – Benign FP – Prod`
- Response workflow (Logic App): `MDC Workload Response – Tenant – Prod`
- Advanced-hunting saved query: `MDC Workload Alert Validation – Tenant – Validate`

## Step 1 — Assess readiness
1. Sign in to the **Azure portal** with **Security Admin** (or Owner) on the pilot subscription.
2. Run `MDCWP-Discovery.ps1` to capture: subscriptions onboarded to Defender for Cloud, current plan state per subscription, the running account's rights, agent/extension coverage, and a workspace for export.
3. Confirm the pilot subscription and record it as `MDC Workload Plans – Pilot Subscription – Pilot`. Get **cost approval** for the pilot scope (`MDCWP-Report.ps1 -Section Cost`).

## Step 2 — Enable the workload plans on the pilot subscription
1. Azure portal → **Microsoft Defender for Cloud → Environment settings → [pilot subscription] → Defender plans**.
2. Turn **On** the plans in scope at the appropriate tier: **Servers** (P1 or P2), **Containers**, **Databases** (SQL / open-source / Cosmos DB), **Storage**, **Key Vault**, **App Service**, **Resource Manager**. *Verify current plan tiers and pricing.*
3. Preview and apply with the approval-gated helper: `MDCWP-EnablePlans.ps1 -SubscriptionId <pilot> -Plans Servers,Containers,StorageAccounts,SqlServers` (safe preview by default; `-Apply` to enable).
4. Run `MDCWP-Validate.ps1 -Plan All` to confirm the plans are **On** on the pilot subscription.

## Step 3 — Wire Defender for Servers (MDE + agents)
1. **Environment settings → [pilot] → Defender plans → Servers → Settings** — confirm the **Defender for Endpoint** integration and monitoring-agent auto-provisioning are **On**. Connect non-Azure servers via **Azure Arc**. *Verify current agent/extension requirements.*
2. Run `MDCWP-Validate.ps1 -Plan Servers` to confirm agent/MDE coverage across the pilot servers.

## Step 4 — Configure continuous export
1. **Environment settings → [pilot] → Continuous export** — export **Security alerts** (and recommendations) to `MDC Continuous Export – Workspace – Prod` (and optionally to the SIEM/Event Hub).
2. Confirm export is active and data begins landing in the workspace.
3. Run `MDCWP-Validate.ps1 -Plan Export` to confirm continuous export is configured.

## Step 5 — Tune alerts (suppression + notifications)
1. **Microsoft Defender for Cloud → Security alerts** — review the alerts appearing on the pilot; for known-benign patterns create the suppression rule `MDC Alert Suppression – Benign FP – Prod` (scoped, documented).
2. **Environment settings → [pilot] → Email notifications** — set the recipients and the severity threshold so the SOC gets high-severity alerts.
3. Run `MDCWP-Report.ps1 -Section Alerts` to capture the current alert inventory and suppression posture.

## Step 6 — Add a notify-only response workflow
1. **Microsoft Defender for Cloud → Workflow automation → Add workflow automation** — create `MDC Workload Response – Tenant – Prod` triggered on high-severity alerts, calling a Logic App that **notifies / creates a ticket** (Teams, email, ITSM). **No auto-remediation** during the pilot.
2. Run `MDCWP-Validate.ps1 -Plan Workflow` to confirm the workflow exists and is notify-only.
3. *The decision to add any auto-remediation is the SOC/security team's — this guide leaves the workflow notify/approval-gated.*

## Step 7 — Validate coverage and a benign alert on the pilot
1. Run `MDCWP-Hunt.ps1` to execute `MDC Workload Alert Validation – Tenant – Validate` — it confirms Defender for Cloud alerts stream (via the workspace `SecurityAlert` table or Graph Security).
2. Trigger a **benign, controlled** detection — e.g. the Microsoft-documented **sample alert** feature, or an EICAR-style test upload to a protected storage account (Defender for Storage). Confirm the alert appears in **Security alerts** and in the export.
3. Confirm the response workflow **notified** (and did not remediate).
4. Complete the **Testing Guide** before expanding.

## Step 8 — Expand across subscriptions
1. **Plans:** enable the validated plans on the remaining subscriptions (use **Environment settings** at the management-group level, or `MDCWP-EnablePlans.ps1` per subscription) in waves, watching cost.
2. **Agents/export:** confirm agent provisioning and continuous export on each new subscription.
3. **Alerts/workflow:** extend suppression rules and the response workflow tenant-wide; only after validation consider approval-gated auto-remediation with the SOC.
4. Re-baseline with `MDCWP-Report.ps1 -SaveBaseline` and track coverage/alert/cost drift each cycle.

---
### Order of operations
`Assess (+ cost approval) → enable plans on pilot subscription → wire Servers MDE/agents → configure continuous export → tune alerts (suppression + notifications) → add notify-only response workflow → validate coverage + benign alert → expand across subscriptions`


---


# 5. Testing Guide — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

Run these checks after enabling the plans on the pilot subscription (Steps 2–7) and again after each expansion wave. Each test has a **pass/fail gate**; do not expand to more subscriptions until the pilot passes. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Workload plans enabled on the pilot
**Procedure:** Run `MDCWP-Validate.ps1 -Plan All`. In Azure portal → **Defender for Cloud → Environment settings → [pilot] → Defender plans**, confirm the in-scope plans (Servers/Containers/Databases/Storage/Key Vault/App Service/Resource Manager) are **On** for `MDC Workload Plans – Pilot Subscription – Pilot`.
**Pass:** Every in-scope plan is On at the agreed tier on the pilot subscription.
**Fail:** A plan is Off or wrong tier — re-apply per Implementation Step 2.

## Test 2 — Defender for Servers coverage (MDE + agent)
**Procedure:** Run `MDCWP-Validate.ps1 -Plan Servers`. Confirm the MDE integration and monitoring agent are provisioned and healthy on the pilot servers (Arc for non-Azure).
**Pass:** Pilot servers report the MDE/agent as healthy; server detection is active.
**Fail:** Agent/MDE not provisioned — see Troubleshooting *Server agent not provisioned*.

## Test 3 — Continuous export flowing
**Procedure:** Run `MDCWP-Validate.ps1 -Plan Export`. Confirm alerts/recommendations land in `MDC Continuous Export – Workspace – Prod` (the `SecurityAlert` table).
**Pass:** Continuous export is active and data is landing in the workspace.
**Fail:** No data — see Troubleshooting *No export data*.

## Test 4 — Alert tuning in place
**Procedure:** Run `MDCWP-Report.ps1 -Section Alerts`. Confirm `MDC Alert Suppression – Benign FP – Prod` exists (scoped/documented) and email notifications are set to the SOC with a sensible severity threshold.
**Pass:** Suppression rule and notifications are configured; the alert queue is signal, not noise.
**Fail:** No tuning or over-broad suppression — re-apply per Implementation Step 5.

## Test 5 — Response workflow is notify-only
**Procedure:** Run `MDCWP-Validate.ps1 -Plan Workflow`. Confirm `MDC Workload Response – Tenant – Prod` exists, triggers on high-severity alerts, and **only notifies / creates a ticket** (no auto-remediation).
**Pass:** The workflow notifies and does not remediate during the pilot.
**Fail:** Auto-remediation is configured before agreed — reset to notify-only and confirm with the SOC.

## Test 6 — Workload alerts stream
**Procedure:** Run `MDCWP-Hunt.ps1` to execute `MDC Workload Alert Validation – Tenant – Validate`. Confirm Defender for Cloud alerts are queryable (via `SecurityAlert` / Graph Security).
**Pass:** Alerts are streaming and queryable.
**Fail:** Empty — see Troubleshooting *No workload alerts*.

## Test 7 — A benign alert actually fires
**Procedure:** Trigger a controlled detection — the Microsoft **sample alert** feature, or an EICAR-style test upload to a protected storage account (Defender for Storage). In **Security alerts**, confirm the alert appears and exported.
**Pass:** The controlled test produces a visible workload alert within the expected window.
**Fail:** No alert — see Troubleshooting *Benign alert does not fire*.

## Test 8 — Cost understood
**Procedure:** Run `MDCWP-Report.ps1 -Section Cost -SaveBaseline`. Confirm the protected-resource counts per plan are recorded so the pilot cost is understood before expansion.
**Pass:** Protected-resource counts/cost baseline captured; spend matches the approved estimate.
**Fail:** Coverage/cost is unexpected — reconcile scope before expanding; *verify current pricing.*

---
### Exit gate
All eight tests pass on the pilot subscription **before** you enable plans on more subscriptions (Implementation Step 8). Re-run Tests 1, 3, 6, 7, and 8 after each expansion wave and compare against the saved baseline.


---


# 6. Troubleshooting Guide — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

Common field issues, in **symptom → cause → fix** form. Run `MDCWP-Discovery.ps1` and `MDCWP-Validate.ps1` first — most causes surface there.

## Plan will not enable
**Symptom:** Test 1 fails — a workload plan stays **Off** or the enablement errors.
**Cause:** The running account lacks **Security Admin / Owner** on the subscription, the `Microsoft.Security` provider is not registered, or a policy blocks the change.
**Fix:** Confirm the role on the pilot subscription (IAM); register the `Microsoft.Security` resource provider; check for a blocking Azure Policy. Re-run the enablement (`MDCWP-EnablePlans.ps1 -Apply`) and `MDCWP-Validate.ps1 -Plan All`.

## Server agent not provisioned
**Symptom:** Test 2 fails — pilot servers show no MDE/monitoring agent, or detection is inactive.
**Cause:** Auto-provisioning is off, the monitoring agent/extension failed to deploy, or a non-Azure server is not Arc-connected.
**Fix:** In **Defender plans → Servers → Settings**, enable auto-provisioning of the MDE integration and monitoring agent; connect non-Azure servers via **Azure Arc**; check the extension deployment status on the VM. *Verify current agent/extension requirements.* Re-run `MDCWP-Validate.ps1 -Plan Servers`.

## No export data
**Symptom:** Test 3 fails — no alerts/recommendations land in `MDC Continuous Export – Workspace – Prod`.
**Cause:** Continuous export is not configured for the pilot subscription, the wrong workspace/target is selected, or no alerts have fired yet.
**Fix:** Confirm **Environment settings → Continuous export** targets the workspace and exports **Security alerts**; confirm workspace permissions; allow warm-up and generate a benign alert (Test 7). Re-run `MDCWP-Validate.ps1 -Plan Export`.

## No workload alerts
**Symptom:** Test 6 fails — `MDCWP-Hunt.ps1` returns no alerts.
**Cause:** Plans newly enabled and still warming up, no threats/tests have occurred, or export is not flowing.
**Fix:** Confirm plans are On (Test 1) and export flowing (Test 3); allow warm-up; trigger the sample alert (Test 7). Re-run `MDCWP-Hunt.ps1`.

## Benign alert does not fire
**Symptom:** Test 7 fails — the sample alert or EICAR-style storage test produces nothing.
**Cause:** The relevant plan is off (e.g. Defender for Storage for the storage test), the test targeted an unprotected resource, or not enough time has passed.
**Fix:** Confirm the specific plan for the tested resource type is On; run the Microsoft **sample alert** feature which does not depend on a real threat; ensure the storage test targets a protected account; allow the alert to surface in **Security alerts**. Re-check with `MDCWP-Hunt.ps1`.

## Alert noise / too many alerts
**Symptom:** The pilot alert queue is overwhelming.
**Cause:** No alert tuning yet, or a benign workload behavior repeatedly triggers a detection.
**Fix:** Create **scoped, documented** suppression rules (`MDC Alert Suppression – Benign FP – Prod`) only for genuinely benign patterns, set the notification severity threshold, and fix the underlying misconfiguration where possible (CSPM). Re-run `MDCWP-Report.ps1 -Section Alerts`.

## Unexpected cost
**Symptom:** Test 8 shows spend higher than the approved estimate.
**Cause:** Plans were enabled at the management-group level (covering more subscriptions/resources than intended), or a high-count resource type (e.g. many storage accounts) was included.
**Fix:** Scope enablement to `MDC Workload Plans – Pilot Subscription – Pilot` only; reconcile protected-resource counts (`MDCWP-Report.ps1 -Section Cost`); disable plans on out-of-scope resources. *Verify current pricing.* Expand deliberately.

## Response workflow auto-remediated
**Symptom:** A workload was changed automatically during the pilot.
**Cause:** `MDC Workload Response – Tenant – Prod` was configured to remediate rather than notify.
**Fix:** Reset the workflow/Logic App to **notify / ticket-only** (Implementation Step 6), confirm with the SOC, and re-validate (`MDCWP-Validate.ps1 -Plan Workflow`). *The auto-remediation decision is the security team's.*

## Script cannot authenticate
**Symptom:** `MDCWP-*.ps1` fails on connect or returns access-denied.
**Cause:** The Az / Microsoft.Graph modules are missing, the account is not signed in to the right subscription/tenant, or it lacks Security Reader.
**Fix:** Let the script install the modules (it checks on run); `Connect-AzAccount` and `Set-AzContext` to the pilot subscription; confirm Security Reader (or higher). Re-run the script.


---


# 7. Best Practices — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

Field-proven guidance for keeping the workload protection deployment protective, tuned, and cost-aware.

## Enable on a pilot subscription first
- Turn the plans on for `MDC Workload Plans – Pilot Subscription – Pilot` first, validate coverage and alerts, then expand subscription-by-subscription (or via a management-group policy) in waves. Enabling everywhere at once is a cost and noise shock.

## Treat cost as a first-class decision
- Workload plans are **billed per protected resource**. Get cost approval for the pilot, track protected-resource counts with `MDCWP-Report.ps1 -Section Cost`, and expand deliberately by resource value — not blanket-on. *Verify current pricing and plan tiers.*

## Pair CWPP with CSPM, don't substitute
- Workload protection **detects** attacks; CSPM **reduces** the attack surface. Keep both — cross-reference the catalog's **Defender for Cloud — CSPM & Secure Score** solution. Fixing posture lowers the alerts CWPP has to raise.

## Provision the Servers agents properly
- Defender for Servers detection is only as good as its **agents**. Confirm the MDE integration and monitoring agent auto-provision and stay healthy, and connect non-Azure servers via **Azure Arc** so multicloud/on-prem workloads are covered too.

## Tune alerts so the SOC trusts them
- Untuned CWPP alerts become noise. Create **scoped, documented** suppression rules (`MDC Alert Suppression – Benign FP – Prod`) only for genuinely benign patterns, set sensible severities, and route high-severity alerts to the SOC. Review the tuning on a cadence.

## Keep the response workflow notify-first
- Start `MDC Workload Response – Tenant – Prod` as **notify / ticket-only**. Auto-remediation of a production workload is disruptive and belongs to the SOC's decision, made only after the alerts are trusted.

## Export for hunting and retention
- Send alerts/recommendations to `MDC Continuous Export – Workspace – Prod` (and the SIEM) so you can hunt across time and integrate with the SOC. Validate the export is flowing before relying on it.

## Defer the compliance and change decisions to the owners
- Which regulatory controls apply, production change approval, and incident-response runbooks are **the customer's compliance/operations/security determinations**. This solution delivers the technical CWPP enablement and tuning; the governance decisions stay with the owners.

## Where to go next
Once the workload plans are enabled and validated, natural next steps in the catalog:
- The **Defender for Cloud — CSPM & Secure Score** solution to strengthen the posture layer that feeds CWPP.
- The **Microsoft Defender XDR — Unified Onboarding** accelerator to correlate cloud workload alerts with Endpoint/Identity/Office/Cloud-Apps.
- The **SOC onboarding — Sentinel + Defender XDR** and **advanced KQL threat-hunting** solutions to hunt workload alerts in a SIEM.
- The **Onboarding Accelerator — Microsoft Defender for Endpoint** — MDE powers Defender for Servers detection.


---


# 8. Deliverables Summary — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | CSPM vs CWPP, and each workload plan — Servers, Containers, Databases, Storage, Key Vault, App Service, Resource Manager; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — enable plans on the pilot subscription, wire Servers MDE/agents, continuous export, alert tuning, notify-only workflow, validate, expand |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Az / Microsoft Graph Security + KQL)
| Script | What it does |
|---|---|
| `MDCWP-Discovery.ps1` | Read-only readiness — subscriptions onboarded to Defender for Cloud, current plan state per subscription, the running account's rights, agent coverage, and workspace for export |
| `MDCWP-Validate.ps1` | Targeted validation (`-Plan Servers\|Containers\|Databases\|Storage\|Export\|Workflow\|All`) — confirms plan state, Servers agent/MDE coverage, export, and the notify-only response workflow |
| `MDCWP-Report.ps1` | Coverage report by section (`-Section Alerts\|Cost\|All`) — alert inventory/suppression posture and protected-resource counts (cost), with drift versus a saved baseline |
| `MDCWP-EnablePlans.ps1` | `-WhatIf`-gated helper that enables the named workload plans on a subscription (safe preview by default; `-Apply` to enable) |
| `MDCWP-Hunt.ps1` | Runs the KQL query `MDC Workload Alert Validation` (via the `SecurityAlert` workspace table / Graph Security) to confirm workload alerts stream (read-only) |

## What the buyer receives
- This solution as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot-subscription plan enablement with automated response kept notify/approval-gated and cost monitored throughout.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
Active workload threat protection across servers, containers, databases, storage, Key Vault, and App Service — the CWPP layer on top of your CSPM posture — with alerts tuned to signal, a notify-first response workflow, and cost understood, proven on a pilot subscription before you scale.
