# 1. Solution Overview — Azure Monitor & Log Analytics: Foundation, Alerts & Dashboards

## What this solution is
**Azure Monitor** is Azure's built-in observability platform; **Log Analytics** is the workspace where
its log and metric telemetry is stored and queried. This solution builds the **ops/platform
observability foundation** on top of them: one designed workspace, diagnostic collection applied at
scale by policy, alert rules that route to the right team, guest/container insight, and the workbooks
and dashboards that make the data usable.

This is **operational (platform) monitoring** — is the estate healthy, are resources performing, did
something break — and is deliberately **distinct from a security SIEM** (Microsoft Sentinel). Sentinel
answers "are we under attack"; Azure Monitor answers "is it up and healthy." They can share a workspace,
but this solution builds the **ops** layer.

## How the technology works
- **Telemetry sources.** Azure resources emit **platform metrics** (numeric, near-real-time) and
  **resource logs** (structured events — the categories differ per resource type). VMs and containers
  additionally emit **guest OS performance** and **container** telemetry via an agent.
- **Diagnostic settings.** A **diagnostic setting** on a resource is the switch that says "send these
  log categories and metrics to *this* Log Analytics workspace." Setting these one-by-one does not
  scale, so this solution assigns them by **Azure Policy** — the `DeployIfNotExists` policy effect
  creates the diagnostic setting automatically on every in-scope resource (existing and new).
- **Log Analytics workspace.** A workspace stores the telemetry in **tables** you query with **KQL**
  (Kusto Query Language). Each table has a **plan/tier** (Analytics / Basic / Auxiliary — *verify
  current tiers*) and the workspace has a **retention** setting and **RBAC** — these are the
  cost/access levers.
- **Alerts.** **Metric alerts** evaluate a platform-metric condition continuously and cheaply; **log
  (scheduled query) alerts** run a KQL query on a schedule and fire when the result crosses a threshold.
  Both fire into an **action group** — the reusable bundle of who/what to notify (email, SMS,
  Teams/Slack via webhook, PagerDuty, an Azure Function/Logic App/runbook).
- **Insights.** **VM insights** and **container insights** are curated collection + workbook experiences
  driven by the **Azure Monitor Agent (AMA)** and **Data Collection Rules (DCRs)** — the modern
  replacement for the retired Log Analytics agent (*verify agent status in your tenant*).
- **Workbooks & dashboards.** **Workbooks** are interactive, parameterized reports built on KQL and
  metrics; **Azure dashboards** are pinned tiles for at-a-glance views.

## What this solution builds (the components)
1. **Log Analytics workspace foundation**
   - One workspace `log-obsazmon-platform` in `rg-obsazmon-monitor`, with a decided **retention**,
     **daily cap** (optional cost guard), and **RBAC** (Log Analytics Reader / Contributor to the right
     groups). *Table tiers and retention are cost decisions — flagged verify.*
2. **Diagnostics at scale via Azure Policy**
   - A **built-in policy initiative** (or per-type policies) assigned at the subscription/management-group
     scope — `OBSAZMON-Policy-Diagnostics-Subscription` — with **`DeployIfNotExists`** so resource logs
     and platform metrics flow to the workspace automatically, plus the **remediation** task for
     existing resources.
3. **Alerts + action groups**
   - An action group `OBSAZMON-AG-Platform-Ops` (email + Teams/Slack webhook + optional PagerDuty).
   - A **metric alert** `OBSAZMON-Alert-VMCPUHigh-Pilot` and a **log alert**
     `OBSAZMON-Alert-HeartbeatMissing-Pilot` — starting scoped to the **pilot**.
4. **VM insights / container insights**
   - A **Data Collection Rule** `dcr-obsazmon-vminsights` (and the AKS container-insights add-on where
     applicable) associating pilot VMs/clusters with the workspace.
5. **Workbooks & dashboards**
   - An ops workbook `OBSAZMON-Workbook-OpsOverview` and an executive dashboard
     `OBSAZMON-Dashboard-Exec`, driven by the curated `OBSAZMON-Queries.kql` pack.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand** — inventory resources and existing diagnostics and
> decide retention/scope (Assess); deploy the workspace, action group, DCR, and the first alert rules,
> and stage the diagnostics policy in **audit/DoNotEnforce** (Configure); apply diagnostics + alerts to a
> **pilot resource group** first (Pilot); prove logs land, alerts fire, and dashboards render (Validate);
> then **remediate the policy estate-wide** and expand alerts in waves (Expand). Nothing disruptive is
> enforced fleet-wide before the pilot passes.

## Scope
- Design and deploy **one Log Analytics workspace** as the platform telemetry destination.
- Apply **diagnostic settings at scale** via Azure Policy to route resource logs + metrics.
- Stand up **action groups** and an initial set of **metric + log alert rules**.
- Enable **VM insights / container insights** on the pilot scope.
- Deliver **workbooks + dashboards** and a curated **KQL** pack.

## What is out of scope
- **Security monitoring / SIEM** (Microsoft Sentinel analytics rules, UEBA, threat hunting) — that is
  the **Sentinel** category; this is the ops/platform layer.
- **Application Performance Monitoring internals** (deep Application Insights instrumentation of your
  app code) — the workspace can host App Insights (workspace-based), but instrumenting application code
  is a separate development effort.
- The **decisions** of alert thresholds, on-call rotation, retention duration, and which telemetry is
  worth its ingestion cost — the guide encodes your choices; the choices are yours (and your service
  owners').
- **Third-party/multicloud** monitoring — for a hybrid/multicloud single pane, see the **Datadog**
  solution in this category.

## Authentication and connections used
- **Az PowerShell / Azure CLI** (Contributor + monitoring rights at the target scope) for discovery,
  validation, and deployment.
- **Azure Policy managed identity** — the `DeployIfNotExists` assignment uses a **system-assigned
  managed identity** granted the roles needed to create diagnostic settings (Monitoring Contributor /
  Log Analytics Contributor) at the assignment scope. No stored secret.
- **Action group channels** — email/SMS need no secret; Teams/Slack use an incoming **webhook URL**;
  PagerDuty uses an integration key — all treated as secrets (Key Vault / secure input), never in code.

## Limitations (be honest with buyers)
- **Ingestion & retention cost money.** Azure Monitor bills on data **ingested** and **retained**;
  turning on "everything everywhere" is expensive. Collect what you will act on; use table tiers and a
  daily cap deliberately. *Verify current pricing/tiers in your tenant.*
- **Feature/agent drift.** The Azure Monitor Agent, DCRs, table plans, and some insight experiences
  evolve and vary by region/SKU; all such points are flagged **"verify."**
- **Policy `DeployIfNotExists` acts on real resources.** It creates diagnostic settings automatically;
  it is staged **DoNotEnforce/audit first** and remediated deliberately, not fired blind estate-wide.
