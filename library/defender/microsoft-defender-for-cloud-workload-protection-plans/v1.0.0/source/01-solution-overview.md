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
