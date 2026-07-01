# Entra ID & Intune Audit Telemetry to Microsoft Sentinel

> **Version 1.0.0** · Category: Sentinel Solutions · Solution code: SENTLOG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

**Sentinel Solutions**

Your identity and device platforms already generate exactly the audit signal a security operations team needs — sign-ins, directory changes, device compliance and enrollment events. By default that signal is siloed inside Entra ID and Intune, short-retained, and invisible to your SIEM, so nothing can alert on it and an auditor cannot see it. This solution wires that telemetry into Microsoft Sentinel: diagnostic settings and a data connector route the logs into a Log Analytics workspace, retention is set for compliance, and baseline analytics rules turn the raw stream into actionable alerts.

This is a complete, deploy-it-today package for streaming Entra ID and Intune audit telemetry into Microsoft Sentinel, written for an administrator with no prior SIEM experience.

## What you get

- A plain-language Solution Overview of the pipeline — Entra ID and Intune diagnostic logs to a Log Analytics workspace to Microsoft Sentinel — and the log categories, retention, and baseline analytics that make it useful.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click portal steps in the required order.
- Five PowerShell scripts for telemetry-readiness discovery, ingestion/connector validation, a log-coverage and retention report, safe remediation of missing diagnostic settings, and a workspace/RBAC scoping helper.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers

A working telemetry pipeline — Entra ID diagnostic settings and the Entra ID data connector feeding a Log Analytics workspace, Intune audit telemetry routed in, the relevant log categories (sign-in, audit, device/compliance) flowing, retention set to a compliance-appropriate window, and baseline analytics rules enabled — validated on a pilot before you scale.

## The standard deployment model

`Assess -> Configure -> Pilot -> Validate -> Expand`, with a pilot gate that validates ingestion before expansion.

## Outcome

Identity and device audit telemetry centralized in Microsoft Sentinel — retained for compliance and ready to alert on — so nothing in Entra ID or Intune happens unseen, proven on a pilot before you scale.


---


# 1. Solution Overview — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

## What this solution is

Microsoft Sentinel is Microsoft's cloud-native SIEM. It runs on top of a Log Analytics workspace, ingests log data from many sources, retains it, and runs analytics rules that turn that data into alerts and incidents. This solution builds the specific pipeline that brings your identity and device audit telemetry into Sentinel: Entra ID and Intune audit logs are routed into a Log Analytics workspace, retention is set, and baseline analytics rules are enabled so the signal is centralized, retained, and alert-ready.

## How the pipeline works

1. A source generates audit telemetry — Entra ID produces sign-in and directory-change logs; Intune produces device, compliance, and enrollment audit events.
2. A diagnostic setting (for Entra ID) or a data connector routes the source's chosen log categories into the Log Analytics workspace. Routing the source is the switch that turns the pipeline on.
3. The Log Analytics workspace stores the data in tables (for example `SigninLogs`, `AuditLogs`) that you can query with KQL and retain for a defined period.
4. Microsoft Sentinel, enabled on that workspace, layers SIEM features on top: data connectors, analytics rules, hunting, and incidents.
5. Baseline analytics rules evaluate the incoming data and raise alerts/incidents on suspicious identity or device activity.
6. Retention keeps the data available for investigation and compliance for the window you choose.

## The log categories this pipeline routes

- Entra ID `SignInLogs` — interactive and non-interactive user sign-ins (the core identity signal).
- Entra ID `AuditLogs` — directory changes (role assignments, group and app changes, policy edits).
- Entra ID non-interactive / service-principal / managed-identity sign-in categories — for service and app activity (optional, higher volume).
- Intune device, compliance, and enrollment audit telemetry — device actions, compliance state changes, and enrollment events.

## What you can control

- Which log categories each source forwards (scope volume and cost by choosing only what you need).
- The destination Log Analytics workspace and its region (data residency).
- Retention per table or per workspace (interactive retention plus optional long-term/archive).
- Which baseline analytics rules are enabled and at what severity.
- The RBAC scope of who can read the workspace and manage Sentinel.

## Why this matters (the business case)

- Centralized signal — identity and device activity sits in one searchable place instead of two siloed portals.
- Retention for compliance — Entra ID and Intune keep audit data only for a short default window; routing it to the workspace lets you retain it for as long as policy requires.
- Alerting — baseline analytics rules turn raw logs into incidents, so risky sign-ins and directory changes are caught instead of buried.
- Investigation — when something happens, the full history is queryable with KQL rather than gone.
- Auditability — every object created is named to a convention, so the pipeline is documented and repeatable.

## Limitations (be honest with buyers)

- Sentinel and Log Analytics bill primarily on data ingested and retained; identity sign-in logs (especially non-interactive) can be high-volume, so scope and retention must be planned (see requirements).
- This solution routes the audit telemetry and enables baseline analytics; it is not a full detection-engineering or threat-hunting program (those build on this foundation).
- Diagnostic settings and connector availability depend on the source's licensing (for example some Entra ID log categories require a premium Entra plan).
- Data already routed to another destination should not be duplicated to the workspace without intent, or you pay to ingest it twice.

## The standard deployment model

> Stand up the workspace and Sentinel, enable Entra ID diagnostic settings and the data connector, route Intune audit telemetry, set retention, enable baseline analytics, validate ingestion on a pilot, then expand. Standard pattern: `Assess -> Configure -> Pilot -> Validate -> Expand`.


---


# 2. Requirements Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (Azure subscription, Log Analytics workspace, Microsoft Sentinel enabled, RBAC, ingestion/retention cost plan, diagnostic-settings capability, change control) are in `global-requirements-sentinel-solutions.md`; do not repeat them — confirm them there first.

## 2.1 Entra ID licensing for the sign-in categories in scope

- **Description:** An Entra ID plan that exposes the sign-in log categories you intend to route. Basic sign-in/audit logs are broadly available; some categories (for example risky-sign-in detail) require Entra ID P1/P2.
- **Why:** A diagnostic setting can only forward categories the tenant's license exposes; missing license means missing data.
- **Verify:** `entra.microsoft.com` → `Identity` → `Overview` (license shown), or M365 admin center → `Billing` → `Licenses`.
- **Implement:** Assign the required Entra ID plan (often included in M365 E3/E5) for the categories you need.

## 2.2 Entra ID diagnostic-settings access

- **Description:** A role that can create an Entra ID diagnostic setting that forwards logs to the workspace.
- **Why:** Routing Entra ID `SignInLogs` and `AuditLogs` is done through `Monitoring & health` → `Diagnostic settings`; editing it requires the right role.
- **Verify:** `entra.microsoft.com` → `Monitoring & health` → `Diagnostic settings` loads and `Add diagnostic setting` is available; run `SENTLOG-Discovery.ps1`.
- **Implement:** Hold a role that can edit Entra ID diagnostic settings (for example Security Administrator or Global Administrator), scoped per least privilege.

## 2.3 Microsoft Intune in the tenant

- **Description:** Microsoft Intune licensed and in use, generating device/compliance/enrollment audit telemetry.
- **Why:** This solution routes Intune audit telemetry; there must be Intune activity to route.
- **Verify:** `intune.microsoft.com` loads with managed devices present; `Tenant administration` → `Audit logs` shows events.
- **Implement:** License Intune (M365 E3/E5 or Business Premium) and confirm devices are enrolled.

## 2.4 The Entra ID data connector available in Sentinel

- **Description:** The Microsoft Entra ID data connector present in the Sentinel content/connectors gallery on the in-scope workspace.
- **Why:** The connector is the supported, point-and-click way to bring Entra ID logs into Sentinel and surface the matching baseline analytics rule templates.
- **Verify:** `portal.azure.com` → `Microsoft Sentinel` → (workspace) → `Configuration` → `Data connectors` → search `Microsoft Entra ID`; run `SENTLOG-Validation.ps1`.
- **Implement:** Install the Microsoft Entra ID connector/solution from `Content hub` if it is not already present.

## 2.5 A retention and ingestion budget decision

- **Description:** An agreed retention period (and any long-term/archive tier) and a daily-ingestion estimate for the categories in scope.
- **Why:** Identity sign-in logs can be high-volume; retention drives a large share of cost. This must be decided before connectors are enabled.
- **Verify:** A written estimate and retention decision exist; run `SENTLOG-Report.ps1` after pilot to confirm actual volume against the estimate.
- **Implement:** Estimate GB/day from the source categories, choose a pricing/commitment tier, and set workspace/table retention.

## 2.6 A pilot scope defined

- **Description:** A named, limited pilot scope — typically Entra ID `SignInLogs` and `AuditLogs` plus Intune audit telemetry into the workspace — with success criteria (data is arriving and at least one baseline rule is live).
- **Why:** The standard model validates ingestion on a pilot before enabling higher-volume categories or a wider rule set.
- **Verify:** The pilot categories and pass criteria are written down; run `SENTLOG-Validation.ps1` to confirm the pilot tables are receiving data.
- **Implement:** Choose the minimum useful category set as the pilot; record the gate (ingestion confirmed) before expanding.

---

## Checklist

- [ ] Azure subscription, Log Analytics workspace, and Microsoft Sentinel enabled — see global requirements
- [ ] RBAC on the workspace and Entra ID diagnostic-settings access — `SENTLOG-Discovery.ps1`
- [ ] Entra ID plan exposes the sign-in categories in scope
- [ ] Intune in use and generating audit telemetry
- [ ] Microsoft Entra ID data connector available in Sentinel — `SENTLOG-Validation.ps1`
- [ ] Retention period and ingestion budget agreed
- [ ] Pilot scope and ingestion-confirmed gate defined


---


# Global Requirements — Sentinel Solutions

These requirements are common to **every** Sentinel Solutions solution in the standard program model. They are the baseline Azure Monitor / Microsoft Sentinel platform prerequisites that any telemetry, detection, or SIEM engagement assumes. Each is structured **Description / Why / Verify / Implement-if-missing**. Solution-specific requirements (see `02-requirements.md`) are layered on top of these.

> Naming convention: every created object is named `<Purpose> - <Scope> - <Stage>` and reused verbatim throughout the engagement (for example `Audit Telemetry - Tenant - Pilot`).

---

## G1. An Azure subscription

- **Description:** An active Azure subscription in the tenant in scope, with billing enabled.
- **Why:** A Log Analytics workspace and Microsoft Sentinel are Azure resources billed against a subscription; nothing can be provisioned without one.
- **Verify:** Sign in to `https://portal.azure.com`, open `Subscriptions`, and confirm an active subscription resolves and shows status `Active`.
- **Implement-if-missing:** Create or associate an Azure subscription (Enterprise Agreement, CSP, or pay-as-you-go) and confirm billing is in place.

## G2. A Log Analytics workspace

- **Description:** A Log Analytics workspace to receive and store ingested telemetry, sized to the data volume and retention in scope.
- **Why:** Microsoft Sentinel runs on top of a Log Analytics workspace; all log data lands here and all queries/analytics run against it.
- **Why region matters:** the workspace region determines data residency and affects egress; pick one deliberately before ingestion starts (it cannot be moved later).
- **Verify:** `portal.azure.com` → `Log Analytics workspaces` → confirm the target workspace exists, note its region and resource group.
- **Implement-if-missing:** Create a workspace named `Security Telemetry - Tenant - Workspace`; choose the region for residency; select the pricing tier that fits expected daily ingestion.

## G3. Microsoft Sentinel enabled on the workspace

- **Description:** Microsoft Sentinel added to (enabled on) the Log Analytics workspace in scope.
- **Why:** Connectors, analytics rules, hunting, and incidents are Sentinel features layered on the workspace; without Sentinel enabled you have logs but no SIEM.
- **Verify:** `portal.azure.com` → `Microsoft Sentinel` → confirm the workspace is listed.
- **Implement-if-missing:** `Microsoft Sentinel` → `Create` → select the workspace → `Add`.

## G4. Administrative roles (least privilege)

- **Description:** Appropriately scoped roles for the work — Microsoft Sentinel Contributor (or Log Analytics Contributor) on the workspace for configuration, plus the tenant roles needed to set diagnostic settings on the sources (for example a role that can edit Entra ID diagnostic settings).
- **Why:** Each configuration action requires sufficient privilege; least-privilege scoping limits blast radius and satisfies audit requirements.
- **Verify:** On the workspace/resource group, `Access control (IAM)` → confirm the operating accounts hold the required roles. In Entra → `Roles & admins`, confirm the role that can edit diagnostic settings.
- **Implement-if-missing:** Assign the minimum roles needed at the resource-group or workspace scope; prefer eligible (PIM) activation over standing access where available.

## G5. Ingestion and retention cost plan

- **Description:** A documented estimate of daily ingestion (GB/day) and a retention decision (interactive retention vs long-term/archive), with a budget owner.
- **Why:** Sentinel and Log Analytics are billed primarily on data ingested and data retained; identity and device audit logs can be high-volume, so cost must be planned before connectors are switched on.
- **Verify:** Confirm a written estimate exists (sources × expected GB/day) and that retention periods are agreed per table or workspace.
- **Implement-if-missing:** Estimate volume from the source log categories in scope; choose pay-as-you-go or a commitment tier; set workspace/table retention; record the budget and owner.

## G6. Diagnostic settings capability on each source

- **Description:** The ability to create diagnostic settings (or enable the relevant data connector) on every source whose telemetry is in scope.
- **Why:** Telemetry only flows to the workspace when a diagnostic setting (or connector) routes the source's log categories to it; this is the switch that turns the pipeline on.
- **Verify:** For each source, confirm a diagnostic setting can be created and that no existing setting already routes the same categories elsewhere (to avoid duplicate ingestion and double billing).
- **Implement-if-missing:** Plan one named diagnostic setting per source that forwards the in-scope categories to the workspace (named per G's convention).

## G7. Change control & rollback posture

- **Description:** An approved change process with a scheduled window, plus a documented rollback (which diagnostic settings/connectors/analytics rules were added) before any change.
- **Why:** Enabling connectors and analytics rules changes ingestion volume (and therefore cost) and can generate incidents; controlled changes and a recorded back-out keep the pipeline safe and auditable.
- **Verify:** Confirm an approved change record and a written list of objects to be created (so they can be removed cleanly).
- **Implement-if-missing:** Stand up a lightweight change/approval process; capture the pre-change configuration; document the rollback (delete the named diagnostic setting / disable the connector / disable the rule).


---


# 3. Implementation Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

Follow these steps **in order**. They use two portals: the Azure portal (`https://portal.azure.com`) for the workspace, Microsoft Sentinel, and analytics, and the Entra admin center (`https://entra.microsoft.com`) for the Entra ID diagnostic setting. Intune audit telemetry is routed in through Sentinel's connectors.

> Model: stand up the destination, route each source, set retention, enable baseline analytics, then validate ingestion on a pilot before expanding. Every object created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim.

Objects this guide creates (name them exactly):
- Workspace: `Security Telemetry - Tenant - Workspace`
- Entra ID diagnostic setting: `Audit Telemetry - Entra ID - Pilot`
- Sentinel analytics rules (from templates): `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot`
- RBAC scope: `Microsoft Sentinel Contributor - Workspace - Pilot`

## Step 1 — Confirm the workspace and Sentinel

1. `portal.azure.com` → search `Log Analytics workspaces` → confirm `Security Telemetry - Tenant - Workspace` exists (create it if not; see global requirements G2). Note its region and resource group.
2. `portal.azure.com` → search `Microsoft Sentinel` → confirm the workspace is listed. If not: `Create` → select the workspace → `Add`.

## Step 2 — Route Entra ID logs via Diagnostic settings

1. Go to `entra.microsoft.com` → `Monitoring & health` → `Diagnostic settings`.
2. Click `Add diagnostic setting`.
3. `Diagnostic setting name`: `Audit Telemetry - Entra ID - Pilot`.
4. Under `Logs`, select the categories in scope for the pilot: `SignInLogs` and `AuditLogs`. (Leave higher-volume categories such as non-interactive and service-principal sign-ins for the Expand step.)
5. Under `Destination details`, tick `Send to Log Analytics workspace`, then choose the subscription and `Security Telemetry - Tenant - Workspace`.
6. Click `Save`. Data typically begins arriving within about 15 minutes (first events can take longer).

## Step 3 — Enable the Microsoft Entra ID data connector in Sentinel

1. `portal.azure.com` → `Microsoft Sentinel` → select `Security Telemetry - Tenant - Workspace`.
2. `Configuration` → `Data connectors` → search `Microsoft Entra ID` → `Open connector page`.
3. On the connector page, select the same log types you routed in Step 2 (`Sign-in logs`, `Audit logs`) and `Apply Changes` / `Connect`. (The connector and the diagnostic setting are complementary: the diagnostic setting routes the data; the connector registers the source in Sentinel and unlocks the matching analytics rule templates.)

## Step 4 — Route Intune audit telemetry

1. Still in `Microsoft Sentinel` → `Data connectors`, this telemetry arrives with the Entra ID / Microsoft 365 connectors and the Intune audit stream that Entra-integrated device events flow through; confirm the device, compliance, and enrollment audit events are present in the workspace.
2. Verify in `Logs`: run a query against the device/compliance/audit tables (for example check `AuditLogs` for Intune-originated entries and any device-management table available in your tenant) and confirm rows are returning.
3. If a dedicated Intune/endpoint connector solution is offered in `Content hub` for your tenant, install it from there to add its tables and rule templates.

## Step 5 — Set retention

1. `portal.azure.com` → `Log Analytics workspaces` → `Security Telemetry - Tenant - Workspace` → `Settings` → `Usage and estimated costs` → `Data Retention` for the workspace default.
2. For per-table control, open `Tables`, select a table (for example `SigninLogs`), and set its interactive retention and any long-term/archive period to the value your retention decision specifies (Requirement 2.5).

## Step 6 — Enable baseline analytics rules

1. `Microsoft Sentinel` → (workspace) → `Configuration` → `Analytics` → `Rule templates`.
2. Filter by the `Microsoft Entra ID` data source. Select a sign-in baseline template (for example a rule for multiple failed sign-ins / sign-in from a risky source) → `Create rule`. Name it `Baseline - Entra Sign-in - Pilot`, accept the default logic for the pilot, set severity, `Next` through to `Create`.
3. Repeat for a directory-audit template (for example privileged role assignment changes) → name it `Baseline - Entra Audit - Pilot` → `Create`.
4. Confirm both appear under `Analytics` → `Active rules` as `Enabled`.

## Step 7 — Scope RBAC

1. `portal.azure.com` → `Log Analytics workspaces` → `Security Telemetry - Tenant - Workspace` → `Access control (IAM)` → `Add role assignment`.
2. Assign `Microsoft Sentinel Contributor` (manage Sentinel) or `Microsoft Sentinel Reader` (read-only analysts) to the appropriate group; record the assignment as `Microsoft Sentinel Contributor - Workspace - Pilot`.
3. The helper script `SENTLOG-Set-WorkspaceScopeTargeting.ps1` reports current assignments and can apply the scoped role.

## Step 8 — Validate the pilot (the gate)

1. Run `SENTLOG-Validation.ps1` → confirms the connector is connected and the pilot tables (`SigninLogs`, `AuditLogs`) are receiving data.
2. Run `SENTLOG-Report.ps1` → confirms log coverage and the retention set per table, and reports ingestion volume against the estimate.
3. In `Microsoft Sentinel` → `Analytics` → `Active rules`, confirm `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot` are enabled and have run. Complete the Testing Guide.
4. Pilot gate: do not proceed until data is confirmed arriving and at least one baseline rule is live.

## Step 9 — Expand

1. Once the gate passes, edit `Audit Telemetry - Entra ID - Pilot` (or create `Audit Telemetry - Entra ID - Production`) to add the higher-volume categories you deferred (non-interactive, service-principal, managed-identity sign-ins) as budget allows.
2. Enable additional baseline analytics rules from the templates, renaming to the `... - Production` stage.
3. Re-run `SENTLOG-Report.ps1` each cycle to track coverage, retention, and ingestion volume/cost.

---

### Order of operations

`Workspace + Sentinel -> Entra ID diagnostic setting -> Entra ID connector -> Intune audit telemetry -> retention -> baseline analytics -> RBAC -> validate ingestion (gate) -> expand`


---


# 5. Testing Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

Run after the pilot is configured (Implementation Step 8) and after each expansion.

## Test 1 — Diagnostic setting present

**Do:** `entra.microsoft.com` → `Monitoring & health` → `Diagnostic settings` → confirm `Audit Telemetry - Entra ID - Pilot` exists and lists `SignInLogs` and `AuditLogs` to `Security Telemetry - Tenant - Workspace`.
**Expected:** The named setting is present with the in-scope categories routed to the correct workspace.

## Test 2 — Connector connected

**Do:** `portal.azure.com` → `Microsoft Sentinel` → (workspace) → `Data connectors` → `Microsoft Entra ID`, or run `SENTLOG-Validation.ps1`.
**Expected:** Connector status is `Connected`; the data-received indicator is recent.

## Test 3 — Data is arriving (sign-in)

**Do:** `Microsoft Sentinel` → `Logs` → run `SigninLogs | where TimeGenerated > ago(1h) | take 10`.
**Expected:** Rows return — interactive sign-ins are landing in the workspace.

## Test 4 — Data is arriving (directory audit)

**Do:** `Logs` → run `AuditLogs | where TimeGenerated > ago(24h) | take 10`.
**Expected:** Rows return — directory changes (including Intune-originated audit entries) are landing.

## Test 5 — Retention set

**Do:** `Log Analytics workspaces` → workspace → `Tables` → check `SigninLogs` and `AuditLogs`, or run `SENTLOG-Report.ps1`.
**Expected:** Interactive (and any long-term) retention matches the retention decision in Requirement 2.5.

## Test 6 — Baseline analytics rules live

**Do:** `Microsoft Sentinel` → `Analytics` → `Active rules` → confirm `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot` are `Enabled`.
**Expected:** Both rules are enabled and show a recent run; a deliberate test event (for example a failed sign-in pattern) produces an alert/incident.

## Test 7 — Coverage and volume report

**Do:** Run `SENTLOG-Report.ps1`.
**Expected:** A clear table-by-table view of which categories have data, their retention, and ingestion volume against the estimate.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 pass: data is confirmed arriving in `SigninLogs` and `AuditLogs`, retention is set, and at least one baseline rule is live |
| Expand pass | Tests 3, 4, 7 pass for the added categories, and volume/cost is within budget, before enabling more rules or sources |


---


# 6. Troubleshooting Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

Use `SENTLOG-Discovery.ps1` for readiness, `SENTLOG-Validation.ps1` for ingestion state, `SENTLOG-Report.ps1` for coverage/retention, and `SENTLOG-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. No data arriving in the workspace

| Symptom | Cause | Remediation |
|---|---|---|
| `SigninLogs` empty after setup | Diagnostic setting missing or pointing at the wrong workspace | Confirm `Audit Telemetry - Entra ID - Pilot` exists and targets `Security Telemetry - Tenant - Workspace`; run `SENTLOG-Remediation.ps1` to add it |
| Connector shows `Not connected` | Connector page never applied | `Microsoft Sentinel` → `Data connectors` → `Microsoft Entra ID` → select log types → `Apply Changes` |
| Data delayed | First events can lag | Wait ~15-30 minutes after enabling; re-run `SENTLOG-Validation.ps1` |

## B. Missing log categories

| Symptom | Cause | Remediation |
|---|---|---|
| Risky/non-interactive sign-ins absent | Category not selected, or license does not expose it | Add the category to the diagnostic setting; confirm the Entra ID plan exposes it (Requirement 2.1) |
| Intune device/compliance events absent | Source not routed, or dedicated solution not installed | Confirm Intune audit telemetry routing (Implementation Step 4); install the endpoint/Intune solution from `Content hub` if offered |

## C. Unexpectedly high ingestion / cost

- High-volume categories (non-interactive, service-principal sign-ins) were enabled before the pilot gate — disable them or move them to a planned Expand phase.
- The same categories are routed by more than one diagnostic setting (double ingestion) — remove the duplicate.
- Retention set higher than needed — adjust per-table retention to the compliance requirement (Implementation Step 5).

## D. Analytics rules not firing

| Symptom | Cause | Remediation |
|---|---|---|
| Rule enabled but no incidents | The source table has no data, or the rule query window has no matching events | Confirm data is arriving (Test 3/4); generate a deliberate test event; check the rule's query period |
| Rule errored | Query references a table not present in this tenant | Edit the rule to the tables you ingest, or install the connector that provides them |

## E. Permission errors

- Cannot edit the Entra ID diagnostic setting → the account lacks the Entra role (Requirement 2.2).
- Cannot manage Sentinel/analytics → assign `Microsoft Sentinel Contributor` on the workspace (Implementation Step 7); use `SENTLOG-Set-WorkspaceScopeTargeting.ps1`.

## F. Diagnostics quick reference (KQL in Microsoft Sentinel → Logs)

```kql
SigninLogs | where TimeGenerated > ago(1h) | take 10
AuditLogs  | where TimeGenerated > ago(24h) | summarize count() by Category
Usage | where TimeGenerated > ago(24h) | summarize GB=sum(Quantity)/1000 by DataType | order by GB desc
```

## G. When to escalate

If the diagnostic setting and connector are confirmed correct, RBAC is sufficient, and no data arrives after 30+ minutes and a re-validation, capture the output of `SENTLOG-Validation.ps1` and `SENTLOG-Report.ps1` and open a Microsoft support case for the workspace/connector.


---


# 7. Best Practices — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

- **Pilot the ingestion first.** Route a minimal category set (`SignInLogs`, `AuditLogs`) to the workspace and confirm data is arriving before enabling high-volume categories — the single most important practice for controlling cost and avoiding surprises.
- **Scope categories deliberately.** Non-interactive, service-principal, and managed-identity sign-in logs are valuable but high-volume; add them only when the budget and the use case justify them.
- **Plan retention before you connect.** Retention drives a large share of cost; set interactive vs long-term/archive per table to your compliance requirement, not by default.
- **Name every object to the convention.** Use `<Purpose> - <Scope> - <Stage>` for the workspace, diagnostic setting, analytics rules, and RBAC scope, and reuse the names verbatim — it makes the pipeline auditable and repeatable.
- **Avoid double ingestion.** Before adding a diagnostic setting, check the source is not already routing the same categories elsewhere; you pay to ingest data twice if it is.
- **Use the connector and the diagnostic setting together.** The diagnostic setting routes the data; the connector registers the source and unlocks the matching baseline rule templates — enable both.
- **Start analytics from templates.** Enable baseline rule templates first, tune severity, and watch for noise before authoring custom rules.
- **Right-size RBAC.** Give analysts `Microsoft Sentinel Reader` and operators `Microsoft Sentinel Contributor`; avoid broad standing access and prefer eligible (PIM) activation.
- **Watch the volume report.** Re-run the coverage/volume report each cycle (`SENTLOG-Report.ps1`) so ingestion stays within budget and gaps in coverage are caught.
- **Document the pipeline.** Record which categories are routed, the retention per table, and the enabled rules for audits and repeatability.


---


# 8. Deliverables Summary — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The telemetry pipeline (Entra ID/Intune logs -> Log Analytics -> Sentinel), log categories, retention, baseline analytics, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Sentinel Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal steps (diagnostic setting, connector, Intune routing, retention, analytics, RBAC) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts

| Script | What it does |
|---|---|
| `SENTLOG-Discovery.ps1` | Reports telemetry readiness — workspace, Sentinel, existing Entra ID diagnostic settings, and Intune presence (read-only) |
| `SENTLOG-Validation.ps1` | Confirms ingestion: the Entra ID connector is connected and the pilot tables are receiving data (read-only) |
| `SENTLOG-Report.ps1` | Log-coverage and retention report across the workspace tables, with ingestion volume (read-only) |
| `SENTLOG-Remediation.ps1` | Safe remediation (default `-WhatIf`); adds a missing Entra ID diagnostic setting routing logs to the workspace |
| `SENTLOG-Set-WorkspaceScopeTargeting.ps1` | Workspace/RBAC scoping helper — reports and applies scoped Sentinel roles |

## What the buyer receives

- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the standard model: `Assess -> Configure -> Pilot -> Validate -> Expand`.

## Outcome

Identity and device audit telemetry centralized in Microsoft Sentinel — routed, retained, and alert-ready — validated on a pilot before fleet-wide expansion.
