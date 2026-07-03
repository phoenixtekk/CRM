# Entra ID & Intune Audit Telemetry to Microsoft Sentinel — Government (GCC High)

> **Version 1.0.0** · Category: Sentinel Solutions · Solution code: SENTLOGG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

**Sentinel Solutions · US Sovereign Cloud (GCC High)**

Your identity and device platforms already generate exactly the audit signal a security operations team needs — sign-ins, directory changes, device compliance and enrollment events. By default that signal is siloed inside Entra ID and Intune, short-retained, and invisible to your SIEM, so nothing can alert on it and an auditor cannot see it. This solution wires that telemetry into Microsoft Sentinel — but for the **US sovereign cloud**: diagnostic settings and a data connector route the logs into a Log Analytics workspace **in Azure Government**, retention is set for compliance, and baseline analytics rules turn the raw stream into actionable alerts.

This is the **Government (GCC High) edition**. It is not the Commercial guide with a different sign-in — the sovereign admin URLs differ (`portal.azure.us`, `entra.microsoft.us`, `intune.microsoft.us`, `security.microsoft.us`), the endpoints differ (`login.microsoftonline.us`, `graph.microsoft.us`, `-Environment USGov`/`AzureUSGovernment`), and some Sentinel capabilities lag or are absent versus Commercial. Those differences are called out throughout so a GCC High tenant is configured correctly — not with Commercial steps that silently fail.

## What you get

- A plain-language Solution Overview of the pipeline — Entra ID and Intune diagnostic logs to a Log Analytics workspace to Microsoft Sentinel in Azure Government — with an explicit **Commercial vs GCC High — what's different** section.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, using the `.us` sovereign portals.
- An Implementation Guide of precise, click-by-click Gov-portal steps in the required order, with GCC-High caveats inline at the step where they matter.
- A cited **GCC High parity reference** so no Commercial-only feature is promised on a Gov tenant.
- Five PowerShell scripts (all targeting US Gov endpoints) for telemetry-readiness discovery, ingestion/connector validation, a log-coverage and retention report, safe remediation of missing diagnostic settings, and a workspace/RBAC scoping helper.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers

A working telemetry pipeline inside Azure Government — Entra ID diagnostic settings and the Entra ID data connector feeding a Log Analytics workspace, Intune audit telemetry routed in from `intune.microsoft.us`, the relevant log categories (sign-in, audit, device/compliance) flowing, retention set to a compliance-appropriate window (CMMC / DFARS / FedRAMP), and baseline analytics rules enabled — validated on a pilot before you scale.

## The standard deployment model

`Assess -> Configure -> Pilot -> Validate -> Expand`, with a pilot gate that validates ingestion before expansion.

## Outcome

Identity and device audit telemetry centralized in Microsoft Sentinel inside the US sovereign boundary — retained for compliance and ready to alert on — so nothing in Entra ID or Intune happens unseen, proven on a pilot before you scale.


---


# 1. Solution Overview — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

## What this solution is

Microsoft Sentinel is Microsoft's cloud-native SIEM. It runs on top of a Log Analytics workspace, ingests log data from many sources, retains it, and runs analytics rules that turn that data into alerts and incidents. This solution builds the specific pipeline that brings your identity and device audit telemetry into Sentinel — but authored for the **US sovereign cloud (GCC High)**: Entra ID and Intune audit logs are routed into a Log Analytics workspace **in Azure Government**, retention is set, and baseline analytics rules are enabled so the signal is centralized, retained, and alert-ready.

This is the **Government (GCC High) edition**. In GCC High the admin portals, service endpoints, and some Sentinel capabilities differ from Commercial. A GCC High tenant is paired with **Microsoft Entra ID in Azure Government**, so Entra ID and Intune logs stay inside the sovereign boundary and land in a Sentinel workspace that also runs in Azure Government — there is no cross-cloud egress to Commercial Azure. This edition uses the `.us` portals and US Gov endpoints throughout, and calls out where a Commercial step would silently fail on a Gov tenant.

## Commercial vs GCC High — what's different

| Area | Commercial | GCC High (this edition) |
|---|---|---|
| Azure / Sentinel portal | `portal.azure.com` | `portal.azure.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Microsoft Defender portal (unified SecOps) | `security.microsoft.com` | `security.microsoft.us` |
| Sign-in / auth endpoint | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft Graph endpoint | `graph.microsoft.com` | `graph.microsoft.us` |
| Graph PowerShell environment | `-Environment Global` (default) | `-Environment USGov` |
| Az PowerShell environment | `AzureCloud` (default) | `AzureUSGovernment` |
| Underlying identity plane | Entra ID in Commercial Azure | Entra ID in **Azure Government** |

Sources: Microsoft Graph national cloud deployments (learn.microsoft.com/graph/deployments); Microsoft Defender portal service support for US Government customers (learn.microsoft.com/unified-secops/gov-support); Connect-MgGraph reference.

**Feature-parity gaps that matter for this pipeline (verified against Microsoft's "Microsoft Sentinel feature support for Azure commercial/other clouds", learn.microsoft.com/azure/sentinel/feature-availability, dated 2026-05-14):**

- **Microsoft Entra ID connector is GA in Azure Government** — the core of this solution is supported. The Entra ID Protection connector and Office 365 connector are also GA in Gov.
- **Microsoft Defender XDR connector and Defender XDR incident integration are GA in Azure Government.** (In *China 21Vianet* they are not — that is a different national cloud, out of scope here.)
- **Repositories (CI/CD), Codeless Connectors Platform, SIEM migration experience, Summary rules, and SOC optimizations are NOT available in Azure Government.** If your Commercial runbook uses any of these to deploy or manage the pipeline, they will not be present on a GCC High tenant — deploy analytics and content from Content hub / Analytics templates directly instead.
- **Some threat-intelligence enrichments are not in Gov:** GeoLocation/WhoIs enrichment, URL detonation, and MDTI matching analytics are Commercial-only. TAXII and flat-file TI import are available.
- **`Hunts` (the newer hunting experience) is not in Azure Government;** classic Bookmarks, Queries, Livestream, Search, and Restore are.
- All of the above are point-in-time; **treat any capability not confirmed present in your tenant as "verify for GCC High"** before you promise it.

## How the pipeline works

1. A source generates audit telemetry — Entra ID (in Azure Government) produces sign-in and directory-change logs; Intune produces device, compliance, and enrollment audit events.
2. A diagnostic setting (for Entra ID) or a data connector routes the source's chosen log categories into the Log Analytics workspace **in Azure Government**. Routing the source is the switch that turns the pipeline on.
3. The Log Analytics workspace stores the data in tables (for example `SigninLogs`, `AuditLogs`, `IntuneAuditLogs`) that you can query with KQL and retain for a defined period.
4. Microsoft Sentinel, enabled on that workspace, layers SIEM features on top: data connectors, analytics rules, hunting, and incidents.
5. Baseline analytics rules evaluate the incoming data and raise alerts/incidents on suspicious identity or device activity.
6. Retention keeps the data available for investigation and compliance for the window you choose.

## The log categories this pipeline routes

- Entra ID `SignInLogs` — interactive and non-interactive user sign-ins (the core identity signal). *In Azure Government the Entra ID connector supports sign-in logs and audit logs.*
- Entra ID `AuditLogs` — directory changes (role assignments, group and app changes, policy edits).
- Entra ID non-interactive / service-principal / managed-identity sign-in categories — for service and app activity (optional, higher volume; confirm each category is exposed by your Gov tenant's Entra plan).
- Intune audit telemetry — `IntuneAuditLogs` (every change: create, update, delete, assign, remote actions) and `IntuneOperationalLogs` (enrollment success/failure), routed via Intune **Reports → Diagnostics settings** in `intune.microsoft.us`.

## What you can control

- Which log categories each source forwards (scope volume and cost by choosing only what you need).
- The destination Log Analytics workspace and its **Azure Government region** (data residency — Gov data stays on US soil).
- Retention per table or per workspace (interactive retention plus optional long-term/archive).
- Which baseline analytics rules are enabled and at what severity.
- The RBAC scope of who can read the workspace and manage Sentinel.

## Why this matters (the business case)

- Centralized signal — identity and device activity sits in one searchable place inside the sovereign boundary instead of two siloed portals.
- Retention for compliance — Entra ID and Intune keep audit data only for a short default window; routing it to the workspace lets you retain it for as long as policy (and CMMC / DFARS / FedRAMP obligations) require.
- Alerting — baseline analytics rules turn raw logs into incidents, so risky sign-ins and directory changes are caught instead of buried.
- Investigation — when something happens, the full history is queryable with KQL rather than gone.
- Sovereignty — the entire pipeline runs in Azure Government; nothing leaves the US Gov cloud.

## Limitations (be honest with buyers)

- Sentinel and Log Analytics bill primarily on data ingested and retained; identity sign-in logs (especially non-interactive) can be high-volume, so scope and retention must be planned (see requirements).
- This solution routes the audit telemetry and enables baseline analytics; it is not a full detection-engineering or threat-hunting program (those build on this foundation).
- **Some Commercial Sentinel features are absent in Azure Government** (see the parity table above); do not design the pipeline around a feature that is Commercial-only.
- Diagnostic settings and connector availability depend on the source's licensing (for example some Entra ID log categories require a premium Entra plan — G3/G5 Gov SKUs where applicable). Confirm the Gov SKU exposes each category.
- Data already routed to another destination should not be duplicated to the workspace without intent, or you pay to ingest it twice.

## The standard deployment model

> Stand up the workspace and Sentinel in Azure Government, enable Entra ID diagnostic settings and the data connector, route Intune audit telemetry from `intune.microsoft.us`, set retention, enable baseline analytics, validate ingestion on a pilot, then expand. Standard pattern: `Assess -> Configure -> Pilot -> Validate -> Expand`.


---


# 2. Requirements Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (Azure subscription, Log Analytics workspace, Microsoft Sentinel enabled, RBAC, ingestion/retention cost plan, diagnostic-settings capability, change control) are in `global-requirements-sentinel-solutions.md`; do not repeat them — confirm them there first, **using the Azure Government portal (`portal.azure.us`) rather than `portal.azure.com`.**

> GCC High note: every portal below is the `.us` sovereign portal. PowerShell must target US Gov endpoints — `Connect-MgGraph -Environment USGov` and `Connect-AzAccount -Environment AzureUSGovernment`. A Commercial sign-in will fail against a Gov tenant (it points at `login.microsoftonline.com`, the wrong cloud).

## 2.0 GCC High tenant and Azure Government subscription

- **Description:** The workload is a Microsoft 365 GCC High tenant paired with Microsoft Entra ID in Azure Government, and the Log Analytics workspace / Sentinel live in an **Azure Government** subscription.
- **Why:** Data residency and the sovereign boundary depend on everything staying in Azure Government; a Commercial Azure subscription would put the SIEM outside the Gov boundary.
- **Verify:** Sign in at `portal.azure.us` (not `.com`) and confirm the subscription resolves; the URL bar stays on `.us`. `Connect-AzAccount -Environment AzureUSGovernment` succeeds and lists the Gov subscription.
- **Implement:** Provision an Azure Government subscription for the workspace/Sentinel; confirm the tenant is GCC High (sign-in at `login.microsoftonline.us`).

## 2.1 Entra ID (Government) licensing for the sign-in categories in scope

- **Description:** An Entra ID Government plan that exposes the sign-in log categories you intend to route. Basic sign-in/audit logs are broadly available; some categories (for example risky-sign-in detail from Identity Protection) require a premium Entra plan (the Gov equivalent of P1/P2, commonly delivered via G5).
- **Why:** A diagnostic setting can only forward categories the tenant's license exposes; missing license means missing data. The **Microsoft Entra ID connector in Azure Government supports sign-in logs and audit logs** (per Microsoft's Sentinel feature-availability doc); confirm your Gov SKU exposes the specific categories you want beyond those.
- **Verify:** `entra.microsoft.us` → `Identity` → `Overview` (license shown), or the M365 Gov admin center (`portal.office365.us`) → `Billing` → `Licenses`.
- **Implement:** Assign the required Entra ID Government plan (G3/G5 Gov as applicable) for the categories you need.

## 2.2 Entra ID diagnostic-settings access (Government)

- **Description:** A role that can create an Entra ID diagnostic setting that forwards logs to the workspace.
- **Why:** Routing Entra ID `SignInLogs` and `AuditLogs` is done through `Monitoring & health` → `Diagnostic settings` in `entra.microsoft.us`; editing it requires the right role.
- **Verify:** `entra.microsoft.us` → `Monitoring & health` → `Diagnostic settings` loads and `Add diagnostic setting` is available; run `SENTLOGG-Discovery.ps1` (which connects with `-Environment AzureUSGovernment`).
- **Implement:** Hold a role that can edit Entra ID diagnostic settings (for example Security Administrator or Global Administrator), scoped per least privilege.

## 2.3 Microsoft Intune (Government) in the tenant

- **Description:** Microsoft Intune licensed and in use on the Gov tenant, generating device/compliance/enrollment audit telemetry.
- **Why:** This solution routes Intune audit telemetry; there must be Intune activity to route. Intune audit logs are routed via **Reports → Diagnostics settings** to Log Analytics (per Microsoft's "Route logs to Azure Monitor using Microsoft Intune").
- **Verify:** `intune.microsoft.us` loads with managed devices present; `Tenant administration` → `Audit logs` shows events.
- **Implement:** License Intune (Gov M365 G3/G5) and confirm devices are enrolled. Routing requires the **Intune Service Administrator** Entra role plus **Log Analytics Contributor** on the workspace.

## 2.4 The Entra ID data connector available in Sentinel (Azure Government)

- **Description:** The Microsoft Entra ID data connector present in the Sentinel content/connectors gallery on the in-scope Azure Government workspace.
- **Why:** The connector is the supported, point-and-click way to bring Entra ID logs into Sentinel and surface the matching baseline analytics rule templates. It is **GA in Azure Government.**
- **Verify:** `portal.azure.us` → `Microsoft Sentinel` → (workspace) → `Configuration` → `Data connectors` → search `Microsoft Entra ID`; run `SENTLOGG-Validation.ps1`.
- **Implement:** Install the Microsoft Entra ID connector/solution from `Content hub` if it is not already present. (Note: `Repositories`/CI-CD deployment is **not** available in Gov — install from Content hub directly.)

## 2.5 A retention and ingestion budget decision

- **Description:** An agreed retention period (and any long-term/archive tier) and a daily-ingestion estimate for the categories in scope.
- **Why:** Identity sign-in logs can be high-volume; retention drives a large share of cost. This must be decided before connectors are enabled, and retention often maps to a compliance mandate (CMMC / DFARS 7012 / FedRAMP audit-log retention).
- **Verify:** A written estimate and retention decision exist; run `SENTLOGG-Report.ps1` after pilot to confirm actual volume against the estimate.
- **Implement:** Estimate GB/day from the source categories, choose a pricing/commitment tier, and set workspace/table retention.

## 2.6 A pilot scope defined

- **Description:** A named, limited pilot scope — typically Entra ID `SignInLogs` and `AuditLogs` plus Intune `IntuneAuditLogs` into the Azure Government workspace — with success criteria (data is arriving and at least one baseline rule is live).
- **Why:** The standard model validates ingestion on a pilot before enabling higher-volume categories or a wider rule set.
- **Verify:** The pilot categories and pass criteria are written down; run `SENTLOGG-Validation.ps1` to confirm the pilot tables are receiving data.
- **Implement:** Choose the minimum useful category set as the pilot; record the gate (ingestion confirmed) before expanding.

---

## Checklist

- [ ] GCC High tenant + **Azure Government** subscription (`portal.azure.us`) — Requirement 2.0
- [ ] Azure subscription, Log Analytics workspace, and Microsoft Sentinel enabled — see global requirements (verified in the `.us` portal)
- [ ] RBAC on the workspace and Entra ID diagnostic-settings access — `SENTLOGG-Discovery.ps1`
- [ ] Entra ID Government plan exposes the sign-in categories in scope
- [ ] Intune (Gov) in use and generating audit telemetry (`intune.microsoft.us`)
- [ ] Microsoft Entra ID data connector available in Sentinel (Azure Government) — `SENTLOGG-Validation.ps1`
- [ ] Retention period and ingestion budget agreed (mapped to the compliance mandate)
- [ ] Pilot scope and ingestion-confirmed gate defined
- [ ] All tooling targets US Gov endpoints (`-Environment USGov` / `AzureUSGovernment`)


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


# 3. Implementation Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

Follow these steps **in order**. They use three sovereign portals: the **Azure Government portal** (`https://portal.azure.us`) for the workspace, Microsoft Sentinel, and analytics; the **Entra admin center for Gov** (`https://entra.microsoft.us`) for the Entra ID diagnostic setting; and the **Intune admin center for Gov** (`https://intune.microsoft.us`) for the Intune diagnostic setting.

> **GCC High caveat — read first.** Every portal below is the `.us` sovereign portal, not `.com`. If you land on a `.com` portal you are in the wrong cloud and the steps will not find your Gov tenant. Sign-in is `login.microsoftonline.us`. All scripts connect with `-Environment USGov` (Graph) / `-Environment AzureUSGovernment` (Az). Do **not** rely on `Repositories`/CI-CD or the `SIEM migration experience` to deploy content here — neither is available in Azure Government; install from **Content hub** and create rules from templates directly.

> Model: stand up the destination, route each source, set retention, enable baseline analytics, then validate ingestion on a pilot before expanding. Every object created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim.

Objects this guide creates (name them exactly):
- Workspace: `Security Telemetry - Tenant - Workspace`
- Entra ID diagnostic setting: `Audit Telemetry - Entra ID - Pilot`
- Intune diagnostic setting: `Audit Telemetry - Intune - Pilot`
- Sentinel analytics rules (from templates): `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot`
- RBAC scope: `Microsoft Sentinel Contributor - Workspace - Pilot`

## Step 1 — Confirm the workspace and Sentinel (Azure Government)

1. `portal.azure.us` → search `Log Analytics workspaces` → confirm `Security Telemetry - Tenant - Workspace` exists (create it if not; see global requirements G2). Confirm its **region is an Azure Government region** and note its resource group.
2. `portal.azure.us` → search `Microsoft Sentinel` → confirm the workspace is listed. If not: `Create` → select the workspace → `Add`.
3. Caveat: confirm the URL stays on `portal.azure.us` throughout — a redirect to `.com` means you authenticated against Commercial.

## Step 2 — Route Entra ID logs via Diagnostic settings (entra.microsoft.us)

1. Go to `entra.microsoft.us` → `Monitoring & health` → `Diagnostic settings`.
2. Click `Add diagnostic setting`.
3. `Diagnostic setting name`: `Audit Telemetry - Entra ID - Pilot`.
4. Under `Logs`, select the categories in scope for the pilot: `SignInLogs` and `AuditLogs`. (Leave higher-volume categories such as non-interactive and service-principal sign-ins for the Expand step.)
   - Caveat: in Azure Government the Entra ID Sentinel connector supports **sign-in logs and audit logs**; confirm any additional category you select is actually exposed by your Gov Entra SKU before you rely on it.
5. Under `Destination details`, tick `Send to Log Analytics workspace`, then choose the **Azure Government** subscription and `Security Telemetry - Tenant - Workspace`.
6. Click `Save`. Data typically begins arriving within about 15 minutes (first events can take longer).

## Step 3 — Enable the Microsoft Entra ID data connector in Sentinel

1. `portal.azure.us` → `Microsoft Sentinel` → select `Security Telemetry - Tenant - Workspace`.
2. `Configuration` → `Data connectors` → search `Microsoft Entra ID` → `Open connector page`. If the connector is not present, install the **Microsoft Entra ID** solution from `Content hub` first (Content hub is GA in Azure Government).
3. On the connector page, select the same log types you routed in Step 2 (`Sign-in logs`, `Audit logs`) and `Apply Changes` / `Connect`. (The connector and the diagnostic setting are complementary: the diagnostic setting routes the data; the connector registers the source in Sentinel and unlocks the matching analytics rule templates.)

## Step 4 — Route Intune audit telemetry (intune.microsoft.us)

1. Go to `intune.microsoft.us` → `Reports` → `Diagnostics settings` → `Add diagnostic setting` (turn the feature on the first time).
2. `Diagnostic setting name`: `Audit Telemetry - Intune - Pilot`.
3. Under `Logs`, select `AuditLogs` (and `OperationalLogs` if you want enrollment success/failure). These land in the workspace as `IntuneAuditLogs` and `IntuneOperationalLogs`.
   - Caveat: routing Intune logs requires the **Intune Service Administrator** Entra role plus **Log Analytics Contributor** on the workspace (Requirement 2.3). `DeviceComplianceOrg` / `IntuneDevices` exports can take up to 48 hours to appear (audit/operational logs arrive within ~30 minutes); expect the export pipeline to occasionally duplicate data — downstream queries should tolerate duplicates.
4. Under `Destination details`, tick `Send to Log Analytics workspace`, choose the Azure Government subscription and `Security Telemetry - Tenant - Workspace`, then `Save`.
5. Verify in `Logs` (in Sentinel): run `IntuneAuditLogs | where TimeGenerated > ago(1h) | take 10` and confirm rows return.

## Step 5 — Set retention

1. `portal.azure.us` → `Log Analytics workspaces` → `Security Telemetry - Tenant - Workspace` → `Settings` → `Usage and estimated costs` → `Data Retention` for the workspace default.
2. For per-table control, open `Tables`, select a table (for example `SigninLogs` or `IntuneAuditLogs`), and set its interactive retention and any long-term/archive period to the value your retention decision specifies (Requirement 2.5) — usually the value your compliance mandate (CMMC / DFARS / FedRAMP) requires.

## Step 6 — Enable baseline analytics rules

1. `Microsoft Sentinel` → (workspace) → `Configuration` → `Analytics` → `Rule templates`.
2. Filter by the `Microsoft Entra ID` data source. Select a sign-in baseline template (for example a rule for multiple failed sign-ins / sign-in from a risky source) → `Create rule`. Name it `Baseline - Entra Sign-in - Pilot`, accept the default logic for the pilot, set severity, `Next` through to `Create`.
3. Repeat for a directory-audit template (for example privileged role assignment changes) → name it `Baseline - Entra Audit - Pilot` → `Create`.
4. Confirm both appear under `Analytics` → `Active rules` as `Enabled`.
   - Caveat: scheduled and Microsoft rules, NRT rules, and Fusion are GA in Azure Government, so baseline analytics work as expected. `SOC optimizations` and `Summary rules` are **not** available in Gov — do not build the pipeline around them.

## Step 7 — Scope RBAC

1. `portal.azure.us` → `Log Analytics workspaces` → `Security Telemetry - Tenant - Workspace` → `Access control (IAM)` → `Add role assignment`.
2. Assign `Microsoft Sentinel Contributor` (manage Sentinel) or `Microsoft Sentinel Reader` (read-only analysts) to the appropriate group; record the assignment as `Microsoft Sentinel Contributor - Workspace - Pilot`.
3. The helper script `SENTLOGG-Set-ScopeTargeting.ps1` (connecting with `-Environment AzureUSGovernment`) reports current assignments and can apply the scoped role.

## Step 8 — Validate the pilot (the gate)

1. Run `SENTLOGG-Validation.ps1` → confirms the connector is connected and the pilot tables (`SigninLogs`, `AuditLogs`, `IntuneAuditLogs`) are receiving data.
2. Run `SENTLOGG-Report.ps1` → confirms log coverage and the retention set per table, and reports ingestion volume against the estimate.
3. In `Microsoft Sentinel` → `Analytics` → `Active rules`, confirm `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot` are enabled and have run. Complete the Testing Guide.
4. Pilot gate: do not proceed until data is confirmed arriving and at least one baseline rule is live.

## Step 9 — Expand

1. Once the gate passes, edit `Audit Telemetry - Entra ID - Pilot` (or create `Audit Telemetry - Entra ID - Production`) to add the higher-volume categories you deferred (non-interactive, service-principal, managed-identity sign-ins) as budget allows — confirming each is exposed by your Gov SKU.
2. Enable additional baseline analytics rules from the templates, renaming to the `... - Production` stage.
3. Re-run `SENTLOGG-Report.ps1` each cycle to track coverage, retention, and ingestion volume/cost.

---

### Order of operations

`Workspace + Sentinel (Azure Gov) -> Entra ID diagnostic setting (entra.microsoft.us) -> Entra ID connector -> Intune diagnostic setting (intune.microsoft.us) -> retention -> baseline analytics -> RBAC -> validate ingestion (gate) -> expand`


---


# 5. Testing Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

Run after the pilot is configured (Implementation Step 8) and after each expansion. **Every portal below is the `.us` sovereign portal.**

## Test 0 — You are in the sovereign cloud

**Do:** Confirm the portal URL bar reads `portal.azure.us` / `entra.microsoft.us` / `intune.microsoft.us` (not `.com`), and that scripts connected with `-Environment AzureUSGovernment` (Az) / `-Environment USGov` (Graph).
**Expected:** All surfaces resolve on `.us`. A `.com` redirect or a Graph "AADSTS / redirect" error means you authenticated against Commercial — fix before continuing.

## Test 1 — Entra ID diagnostic setting present

**Do:** `entra.microsoft.us` → `Monitoring & health` → `Diagnostic settings` → confirm `Audit Telemetry - Entra ID - Pilot` exists and lists `SignInLogs` and `AuditLogs` to `Security Telemetry - Tenant - Workspace`.
**Expected:** The named setting is present with the in-scope categories routed to the correct Azure Government workspace.

## Test 2 — Intune diagnostic setting present

**Do:** `intune.microsoft.us` → `Reports` → `Diagnostics settings` → confirm `Audit Telemetry - Intune - Pilot` routes `AuditLogs` (and optionally `OperationalLogs`) to the workspace.
**Expected:** The named setting is present and targets the correct workspace.

## Test 3 — Connector connected

**Do:** `portal.azure.us` → `Microsoft Sentinel` → (workspace) → `Data connectors` → `Microsoft Entra ID`, or run `SENTLOGG-Validation.ps1`.
**Expected:** Connector status is `Connected`; the data-received indicator is recent.

## Test 4 — Data is arriving (sign-in)

**Do:** `Microsoft Sentinel` → `Logs` → run `SigninLogs | where TimeGenerated > ago(1h) | take 10`.
**Expected:** Rows return — interactive sign-ins are landing in the workspace.

## Test 5 — Data is arriving (directory + Intune audit)

**Do:** `Logs` → run `AuditLogs | where TimeGenerated > ago(24h) | take 10` and `IntuneAuditLogs | where TimeGenerated > ago(24h) | take 10`.
**Expected:** Rows return from both — directory changes and Intune audit events are landing. (Intune `DeviceComplianceOrg` / `IntuneDevices` can take up to 48h; audit/operational logs arrive within ~30 min.)

## Test 6 — Retention set

**Do:** `Log Analytics workspaces` → workspace → `Tables` → check `SigninLogs`, `AuditLogs`, `IntuneAuditLogs`, or run `SENTLOGG-Report.ps1`.
**Expected:** Interactive (and any long-term) retention matches the retention decision in Requirement 2.5 / the compliance mandate.

## Test 7 — Baseline analytics rules live

**Do:** `Microsoft Sentinel` → `Analytics` → `Active rules` → confirm `Baseline - Entra Sign-in - Pilot` and `Baseline - Entra Audit - Pilot` are `Enabled`.
**Expected:** Both rules are enabled and show a recent run; a deliberate test event (for example a failed sign-in pattern) produces an alert/incident.

## Test 8 — Coverage and volume report

**Do:** Run `SENTLOGG-Report.ps1`.
**Expected:** A clear table-by-table view of which categories have data, their retention, and ingestion volume against the estimate.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Sovereign-cloud check | Test 0 passes: all surfaces on `.us`, scripts on US Gov endpoints |
| Pilot pass | Tests 1-7 pass: data is confirmed arriving in `SigninLogs`, `AuditLogs`, and `IntuneAuditLogs`, retention is set, and at least one baseline rule is live |
| Expand pass | Tests 4, 5, 8 pass for the added categories, and volume/cost is within budget, before enabling more rules or sources |


---


# 6. Troubleshooting Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

Use `SENTLOGG-Discovery.ps1` for readiness, `SENTLOGG-Validation.ps1` for ingestion state, `SENTLOGG-Report.ps1` for coverage/retention, and `SENTLOGG-Remediation.ps1` (default `-WhatIf`) for safe fixes. **All scripts connect to US Gov endpoints** — `-Environment AzureUSGovernment` (Az) / `-Environment USGov` (Graph).

## A. Wrong-cloud / sign-in failures (the #1 GCC High gotcha)

| Symptom | Cause | Remediation |
|---|---|---|
| Portal shows no subscriptions / can't find the tenant | You are on a Commercial `.com` portal | Use `portal.azure.us`, `entra.microsoft.us`, `intune.microsoft.us` — not `.com` |
| `Connect-MgGraph` redirect / AADSTS auth error | Graph module defaulted to the Commercial endpoint | Run `Connect-MgGraph -Environment USGov`; or set `$PSDefaultParameterValues['Connect-MgGraph:Environment']='USGov'` |
| `Connect-AzAccount` cannot see the Gov subscription | Az defaulted to `AzureCloud` | Run `Connect-AzAccount -Environment AzureUSGovernment` |
| Script "works" but returns nothing | Authenticated against the wrong cloud | Re-run the script (it forces the US Gov environment); confirm the account is a GCC High account |

## B. No data arriving in the workspace

| Symptom | Cause | Remediation |
|---|---|---|
| `SigninLogs` empty after setup | Entra ID diagnostic setting missing or pointing at the wrong workspace | In `entra.microsoft.us` confirm `Audit Telemetry - Entra ID - Pilot` targets `Security Telemetry - Tenant - Workspace`; run `SENTLOGG-Remediation.ps1` to add it |
| `IntuneAuditLogs` empty | Intune diagnostic setting missing | In `intune.microsoft.us` → `Reports` → `Diagnostics settings` confirm `Audit Telemetry - Intune - Pilot` routes `AuditLogs` to the workspace |
| Connector shows `Not connected` | Connector page never applied | `portal.azure.us` → `Microsoft Sentinel` → `Data connectors` → `Microsoft Entra ID` → select log types → `Apply Changes` |
| Data delayed | First events can lag; Intune `DeviceComplianceOrg`/`IntuneDevices` up to 48h | Wait ~15-30 minutes (audit/operational) or up to 48h (compliance/devices); re-run `SENTLOGG-Validation.ps1` |

## C. Missing log categories

| Symptom | Cause | Remediation |
|---|---|---|
| Risky/non-interactive sign-ins absent | Category not selected, or Gov Entra SKU does not expose it | Add the category to the diagnostic setting; confirm the Entra ID Government plan exposes it (Requirement 2.1) and that the category is supported for Azure Government in the connector data-type matrix (**verify for GCC High** — see parity notes §3) |
| Intune compliance/device events absent | Only `AuditLogs` routed, or the 48h export window not elapsed | Add `OperationalLogs`/compliance categories to the Intune diagnostic setting; allow up to 48h |

## D. Unexpectedly high ingestion / cost

- High-volume categories (non-interactive, service-principal sign-ins) were enabled before the pilot gate — disable them or move them to a planned Expand phase.
- The same categories are routed by more than one diagnostic setting (double ingestion) — remove the duplicate.
- The Intune export pipeline duplicated data (documented behavior, up to 100% in a 24h window) — make downstream queries duplicate-tolerant; do not double-count.
- Retention set higher than needed — adjust per-table retention to the compliance requirement (Implementation Step 5).

## E. Analytics rules not firing

| Symptom | Cause | Remediation |
|---|---|---|
| Rule enabled but no incidents | The source table has no data, or the rule query window has no matching events | Confirm data is arriving (Test 4/5); generate a deliberate test event; check the rule's query period |
| Rule errored | Query references a table not present in this tenant | Edit the rule to the tables you ingest, or install the connector that provides them from Content hub |
| Expected a Commercial-only feature | `Summary rules` / `SOC optimizations` / `Hunts` are not in Azure Government | Use scheduled/NRT/Fusion rules and classic hunting instead (parity notes §2) |

## F. Content won't deploy the way the Commercial runbook says

- `Repositories` (CI/CD) and the `SIEM migration experience` are **not available in Azure Government**. Install solutions/connectors from **Content hub** and create analytics from **Analytics → Rule templates** directly.

## G. Permission errors

- Cannot edit the Entra ID diagnostic setting → the account lacks the Entra role (Requirement 2.2).
- Cannot route Intune logs → needs **Intune Service Administrator** + **Log Analytics Contributor** on the workspace (Requirement 2.3).
- Cannot manage Sentinel/analytics → assign `Microsoft Sentinel Contributor` on the workspace (Implementation Step 7); use `SENTLOGG-Set-ScopeTargeting.ps1`.

## H. Diagnostics quick reference (KQL in Microsoft Sentinel → Logs, in `portal.azure.us`)

```kql
SigninLogs      | where TimeGenerated > ago(1h)  | take 10
AuditLogs       | where TimeGenerated > ago(24h) | summarize count() by Category
IntuneAuditLogs | where TimeGenerated > ago(24h) | take 10
Usage           | where TimeGenerated > ago(24h) | summarize GB=sum(Quantity)/1000 by DataType | order by GB desc
```

## I. When to escalate

If the diagnostic settings and connector are confirmed correct in the `.us` portals, RBAC is sufficient, you have verified you are in the sovereign cloud (Section A), and no data arrives after 30+ minutes and a re-validation, capture the output of `SENTLOGG-Validation.ps1` and `SENTLOGG-Report.ps1` and open a Microsoft support case for the Azure Government workspace/connector.


---


# 7. Best Practices — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

- **Confirm the sovereign cloud before anything else.** Always work in the `.us` portals (`portal.azure.us`, `entra.microsoft.us`, `intune.microsoft.us`, `security.microsoft.us`) and connect PowerShell with `-Environment USGov` (Graph) / `-Environment AzureUSGovernment` (Az). A Commercial (`.com`) sign-in points at the wrong cloud and silently fails to find your Gov tenant — the single most common GCC High mistake.
- **Keep the whole pipeline in Azure Government.** Workspace, Sentinel, and the Entra/Intune sources must all be in the Gov boundary so data stays on US soil; never route Gov audit logs to a Commercial Azure workspace.
- **Design only around Gov-available features.** Do not build the pipeline on Commercial-only capabilities absent in Azure Government — `Repositories`/CI-CD deployment, `SIEM migration experience`, `Summary rules`, `SOC optimizations`, GeoLocation/WhoIs TI enrichment, URL detonation, and the newer `Hunts` experience are not present in Gov. Install content from **Content hub** and create rules from **Analytics templates** directly.
- **Treat any unconfirmed capability as "verify for GCC High."** Feature parity is a moving target; confirm a feature is present in your tenant before promising it.
- **Pilot the ingestion first.** Route a minimal category set (`SignInLogs`, `AuditLogs`, `IntuneAuditLogs`) and confirm data is arriving before enabling high-volume categories — the single most important practice for controlling cost.
- **Scope categories deliberately.** Non-interactive, service-principal, and managed-identity sign-in logs are valuable but high-volume; add them only when the budget and use case justify them, and confirm each is exposed by your Gov Entra SKU.
- **Plan retention against the mandate.** Retention drives a large share of cost and often maps to a compliance obligation (CMMC / DFARS 7012 / FedRAMP audit-log retention); set interactive vs long-term/archive per table to that requirement, not by default.
- **Name every object to the convention.** Use `<Purpose> - <Scope> - <Stage>` for the workspace, diagnostic settings, analytics rules, and RBAC scope, and reuse the names verbatim — it makes the pipeline auditable and repeatable.
- **Avoid double ingestion.** Before adding a diagnostic setting, check the source is not already routing the same categories elsewhere; you pay to ingest data twice if it is. Expect the Intune export pipeline to occasionally duplicate data — make downstream logic duplicate-tolerant.
- **Use the connector and the diagnostic setting together.** The diagnostic setting routes the data; the connector registers the source and unlocks the matching baseline rule templates — enable both.
- **Right-size RBAC.** Give analysts `Microsoft Sentinel Reader` and operators `Microsoft Sentinel Contributor`; avoid broad standing access and prefer eligible (PIM) activation.
- **Watch the volume report.** Re-run the coverage/volume report each cycle (`SENTLOGG-Report.ps1`) so ingestion stays within budget and coverage gaps are caught.
- **Document the pipeline.** Record which categories are routed, retention per table, and enabled rules for audits and repeatability — especially important under a Gov compliance regime.


---


# 8. Deliverables Summary — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box (GCC High edition) |
| 1. Solution Overview | The telemetry pipeline (Entra ID/Intune logs -> Log Analytics -> Sentinel) in Azure Government, plus a **Commercial vs GCC High — what's different** section, log categories, retention, baseline analytics, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, using the `.us` sovereign portals |
| Global Requirements (Sentinel Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal steps in the Gov portals (diagnostic settings, connector, Intune routing, retention, analytics, RBAC) with GCC-High caveats inline |
| gcc-high-parity-notes.md | Cited Commercial-vs-GCC-High feature parity reference for this pipeline |
| 5. Testing Guide | Validation procedures with pass/fail gates (including a sovereign-cloud check) |
| 6. Troubleshooting Guide | Field issues and remediation, including GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations for the sovereign cloud |

## PowerShell scripts (all target US Gov endpoints)

| Script | What it does |
|---|---|
| `SENTLOGG-Discovery.ps1` | Reports telemetry readiness — workspace, Sentinel, existing Entra ID diagnostic settings, and Intune presence (read-only; `-Environment AzureUSGovernment`) |
| `SENTLOGG-Validation.ps1` | Confirms ingestion: the Entra ID connector is connected and the pilot tables (incl. `IntuneAuditLogs`) are receiving data (read-only) |
| `SENTLOGG-Report.ps1` | Log-coverage and retention report across the workspace tables, with ingestion volume (read-only) |
| `SENTLOGG-Remediation.ps1` | Safe remediation (default `-WhatIf`); adds a missing Entra ID diagnostic setting routing logs to the Azure Government workspace |
| `SENTLOGG-Set-ScopeTargeting.ps1` | Workspace/RBAC scoping helper — reports and applies scoped Sentinel roles (default `-WhatIf`) |

## What the buyer receives

- This implementation guide as a Word document and PDF (Government / GCC High edition).
- All five PowerShell scripts in a single ZIP — each connecting to US Gov Graph / Azure US Gov endpoints.
- A repeatable process following the standard model: `Assess -> Configure -> Pilot -> Validate -> Expand`.
- A cited GCC High parity reference so no Commercial-only feature is promised on a Gov tenant.

## Outcome

Identity and device audit telemetry centralized in Microsoft Sentinel **inside Azure Government** — routed, retained, and alert-ready, with the sovereign portals/endpoints and Commercial-vs-GCC-High parity gaps handled — validated on a pilot before fleet-wide expansion.
