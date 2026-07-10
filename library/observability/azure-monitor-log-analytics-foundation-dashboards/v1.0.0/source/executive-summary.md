# Executive Summary — Azure Monitor & Log Analytics: Foundation, Alerts & Dashboards

## The problem
Azure resources emit rich telemetry — platform metrics, resource logs, guest OS performance, activity
records — but most estates never collect or act on it. Diagnostic settings are enabled on a handful of
resources by hand (or not at all), there is no central workspace, no alert rules that page the right
team, and no dashboards to look at. The result is predictable: problems surface as **outages and user
complaints** instead of as **alerts with context**. When something does break, no one can answer "when
did this start, what changed, and what else is affected?" because the logs were never gathered.

## The solution
This solution builds an **Azure Monitor observability foundation** — an ops/platform monitoring layer,
distinct from a security SIEM — in five parts:
1. **A designed Log Analytics workspace** — one governed telemetry destination with deliberate
   **retention**, **access (RBAC)**, and a **cost/tier** posture, rather than logs scattered across
   ad-hoc workspaces.
2. **Diagnostic settings at scale via Azure Policy** — a policy/initiative assignment that
   **automatically routes resource logs and platform metrics** from every in-scope resource to the
   workspace, so new resources are covered without anyone remembering to click.
3. **Metric and log alert rules with action groups** — alerts that fire on real conditions (a VM stops
   heart-beating, CPU/latency breaches threshold, a resource is unhealthy) and **route to the right
   responder** (email, Teams/Slack, PagerDuty) with context.
4. **VM insights and container insights** — guest-level performance and Kubernetes/container telemetry
   via the **Azure Monitor Agent** and **Data Collection Rules**, on the resources that need it.
5. **Workbooks and dashboards** — an **ops overview** workbook and an **executive** dashboard so the
   telemetry is actually looked at, not just stored.

Delivery follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model: discover what
exists and what emits telemetry, design the workspace and author the artifacts, apply everything to a
**pilot resource group** first, validate that logs land and alerts fire, then expand the diagnostics
policy and alerts across the estate.

## What's included
Full documentation (overview, requirements, ordered implementation, testing matrix, troubleshooting,
best practices) plus **five deployable artifacts**: a read-only **discovery** script, the core
**Bicep** foundation (`OBSAZMON-Foundation.bicep` — workspace, action group, alert rules, diagnostics
policy), a **validation** script, a curated **KQL query pack** (`OBSAZMON-Queries.kql`), and a
**coverage/ingestion report** script. Everything read-only or **what-if / pilot-first**; no secrets in
code.

## Business value
- **Fewer surprises** — problems page you with context instead of arriving as an outage.
- **Coverage that scales** — diagnostics apply by **policy**, so new resources are monitored by default.
- **Cost-aware** — deliberate retention, table tiers, and "collect only what you'll act on."
- **Auditable & visual** — one workspace, curated queries, and dashboards ops and execs can read.

## Effort and boundary
A competent admin comfortable with the Azure portal and PowerShell can stand up the pilot foundation
(workspace, action group, one metric alert, one log alert, diagnostics on a pilot resource group) in a
few focused sessions, then expand estate-wide. This guide provides the **technical foundation and the
automation**. Your organization's **alert thresholds, on-call routing, retention duration, and what
telemetry is worth collecting** are operational decisions the guide wires up but does not decide for you.

> **Version & pricing note:** Azure Monitor features, agent/DCR behavior, table plans (Analytics /
> Basic / Auxiliary), and **ingestion & retention pricing** change over time, and some capabilities are
> region- or SKU-dependent. Every such point in this solution is flagged **"verify"** — confirm current
> availability, tier, and pricing in **your** tenant before broad rollout. *Verify current availability
> in your tenant.*
