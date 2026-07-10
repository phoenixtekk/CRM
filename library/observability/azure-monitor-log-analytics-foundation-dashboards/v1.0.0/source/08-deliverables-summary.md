# 8. Deliverables Summary — Azure Monitor & Log Analytics: Foundation, Alerts & Dashboards

## What you receive
A complete, self-guided package to build an **Azure Monitor observability foundation** — a designed Log
Analytics workspace, diagnostic settings applied at scale by Azure Policy, metric and log alert rules
routed through action groups, VM/container insights, and workbooks + dashboards. Everything is
**read-only or what-if / pilot-first**, with **no secrets in code**.

### Documentation
- **Executive Summary** — the problem (uncollected telemetry, outage-driven ops), the five-part
  solution, the outcome, the boundary, and the version/pricing "verify" note.
- **Solution Overview** — how Azure Monitor, diagnostic settings, Log Analytics, alerts/action groups,
  and insights fit together; the components built; scope and out-of-scope (SIEM/APM/decisions).
- **Requirements Guide** — the Azure-Monitor-specific prerequisites (monitoring rights, workspace design
  decision, AMA/DCR readiness, policy managed-identity roles, notification channels, a pilot RG, and the
  Az/Bicep toolchain), each with Verify / Implement, on top of the category globals.
- **Implementation Guide** — ordered steps: assess → deploy the workspace/action group/pilot alerts
  (Bicep, what-if first) → stage the diagnostics policy (DoNotEnforce) → pilot the RG + insights → prove
  alerts → validate → build workbook/dashboard → expand estate-wide in waves, with **every object named**
  using the `<Purpose>-<Scope>-<Stage>` convention.
- **Testing & Validation** — the four gates (telemetry lands, diagnostics cover the pilot, alerts fire
  and notify, dashboards render) as a pass/fail matrix with the evidence to capture.
- **Troubleshooting** — symptom → root-cause → fix for the common failures (no telemetry, policy not
  remediating, alerts not firing, notifications not arriving, cost spikes, agent/DCR issues).
- **Best Practices** — collect-what-you-act-on, table tiers/retention, diagnostics-by-policy,
  alert-tuning, secrets hygiene, and where to go next.

### Deployable artifacts — read-only / what-if first, no secrets
| Artifact | Purpose | Default mode |
|----------|---------|--------------|
| **`OBSAZMON-Discovery.ps1`** | Inventory resources, existing workspaces, diagnostic-settings coverage, action groups, and alert rules; confirm rights and the coverage gap | Read-only |
| **`OBSAZMON-Foundation.bicep`** | The core foundation: Log Analytics workspace (retention/RBAC), action group, and the two pilot alert rules — parameterized, deploy **what-if first** | Declarative (what-if before apply) |
| **`OBSAZMON-Validate.ps1`** | Post-deploy checks: workspace + retention + RBAC, action-group channels, pilot alert rules enabled, DCR associated | Read-only |
| **`OBSAZMON-Queries.kql`** | Curated KQL pack used by the tests, workbook, and dashboard (heartbeat/health, resource logs, alert summary, top ingesters, VM performance) | Query (read-only) |
| **`OBSAZMON-Report.ps1`** | Coverage + cost report: % of resources with diagnostics → workspace, policy compliance, and estimated ingestion by table/resource | Read-only |

All PowerShell helpers are **read-only**; the Bicep is deployed **`--what-if` first** and piloted before
estate-wide remediation; notification secrets are supplied via **secure input / Key Vault** — **no
credentials or secrets live in the artifacts**.

## Outcomes
- One **governed Log Analytics workspace** as the platform telemetry destination.
- **Diagnostics coverage that scales** — applied by policy so new resources are monitored by default.
- **Actionable alerts** — metric + log rules that page the right team with context, not an inbox of noise.
- **Visibility** — an ops workbook and an executive dashboard driven by a curated KQL pack.
- A **pilot-first**, reversible rollout (DoNotEnforce ↔ Enforce, disable ↔ enable) with a documented
  rollback and a cost report.

## Assumptions & boundaries
- **Feature/agent/tier/pricing** points are flagged **"verify"** — confirm current availability and cost
  in your tenant before broad rollout.
- **Alert thresholds, on-call routing, retention duration, and what telemetry to collect** are the
  customer's/service-owner's decisions — the guide wires them up.
- **Security SIEM** (Sentinel) and **deep application instrumentation** (App Insights code work) are out
  of scope; **multicloud** single-pane is the Datadog solution.

> Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the full documentation set plus
> all five deployable artifacts (Bicep, KQL, and PowerShell helpers) in a single ZIP, yours to keep and
> reuse on every rollout.
