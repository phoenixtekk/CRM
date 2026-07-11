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
