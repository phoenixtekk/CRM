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
