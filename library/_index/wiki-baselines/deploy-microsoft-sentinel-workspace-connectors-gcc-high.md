# Deploy Microsoft Sentinel — Workspace, Data Connectors & Ingestion — Government (GCC High)

> **Version 1.0.0** · Category: Sentinel Solutions · Solution code: SENTDEPG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion — Government (GCC High)

> **Government (GCC High) edition.** This is the US Government national-cloud edition for public-sector
> and defense-industrial-base tenants — the same disciplined method as the commercial version, adapted
> for **Microsoft Sentinel on Azure Government** (`portal.azure.us`, `security.microsoft.us`,
> `login.microsoftonline.us`, `graph.microsoft.us`) and the FedRAMP High / DoD IL4–IL5 / CMMC context.
> Connector and feature availability in GCC High/DoD can lag or differ from commercial; every such point
> is flagged **"verify against current Microsoft Government documentation"** (see
> `gcc-high-parity-notes.md`).

## The problem

Most Microsoft Sentinel deployments start the same way: someone clicks **Enable**, connects every data
source on the list, and turns on every rule template. Within a month the workspace is ingesting
hundreds of gigabytes a day, the monthly bill is a surprise, half the connected sources feed
detections nobody wrote, and no one can say whether a critical log is actually arriving. The result is
a SIEM that is simultaneously **too expensive** and **not trustworthy** — the two things a SIEM must
never be.

The failure is not the tool; it is the order of operations. Sentinel is built on a Log Analytics
workspace, and once telemetry lands in that workspace it costs money to ingest and to retain. Decisions
about **which workspace, which region, which sources, which tier, and how long to keep the data** are
cheap to make up front and expensive to unwind later.

## The solution

This solution stands Sentinel up **in the right order**. It builds a properly sized, governed Log
Analytics workspace with least-privilege access, connects the **high-value** data sources a real
detection program needs — **Microsoft Entra ID, Microsoft Defender XDR, Office 365, Azure Activity, and
syslog/CEF via the Azure Monitor Agent (AMA) and Data Collection Rules (DCRs)** — and shapes ingestion
so you collect **what detections actually consume**, not everything a connector can emit.

Concretely, it delivers:

- A **workspace and RBAC design** — one right-sized workspace (`Security Telemetry - Tenant -
  Workspace`) with reader/responder/contributor access split across named security groups.
- A **connector plan** — the five high-value sources above, each with a named diagnostic setting or DCR
  so you know exactly what is flowing and can turn it off cleanly.
- **Data Collection Rules that filter noise before it is billed** — dropping the informational syslog
  and verbose CEF that inflate cost without improving detection.
- A **table plan** — which tables belong on the **Analytics** tier (queryable, detection-driving) and
  which belong on **Basic/Auxiliary** logs (cheap, search-only) — plus a **retention and archive**
  decision per table.
- **Connector health monitoring** — so you can prove data is still arriving and catch ingestion drift
  before a detection silently goes blind.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure → Pilot
→ Validate → Expand**. We confirm the workspace design and cost plan first, connect one high-value
source and prove it end to end, add the noisy AMA/syslog/CEF path behind a **filtering DCR**, validate
that the right data is arriving at a controlled volume, and only then expand to the full source list.
Every object is named and reused; every ingestion change is reversible.

The solution ships as **self-guided, click-by-click documentation plus five PowerShell tools** (Az /
Microsoft.Graph modules, with KQL for the reporting) that discover the current workspace and connector
state, preview and apply diagnostic settings and retention with **`-WhatIf` by default**, validate the
build against pass/fail gates, and report ingestion volume and connector health — all **read-only or
preview-first**, with **no credentials in code**.

## Why it matters

- **The right data, not all data** — detections are fed by the sources that matter, at a volume you
  chose deliberately.
- **Cost under control from day one** — DCR filtering and a deliberate Analytics-vs-Basic table plan
  stop the runaway bill before it starts.
- **Governed access** — least-privilege RBAC on the workspace, not blanket contributor for everyone.
- **Provable and reversible** — you can show what is arriving and how much it costs, and unwind any
  change cleanly.
- **A fraction of consulting cost** — the same disciplined method a specialist would use, delivered as
  a repeatable, tested runbook you reuse on every rollout.

## Important boundaries

This solution builds the **foundation** — a governed workspace collecting the right data at a controlled
cost. It **does not** author the analytics rules or MITRE ATT&CK coverage that turn this data into
detections; that is the companion **Sentinel Analytics Rules & MITRE ATT&CK Coverage** solution, which
this foundation is designed to feed. Sentinel and Log Analytics pricing, tier availability (Basic vs
Auxiliary logs), and some connector capabilities **change over time and differ by cloud (Commercial vs
Government)** — capability and cost should be **verified against your tenant, region, and current
Microsoft pricing** before you commit. Data-residency, retention-duration, and log-category decisions
that carry regulatory weight are **determinations for your organization's compliance and security
functions**; this solution provides the technical controls, not the decision.


---


# Solution Overview — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion — Government (GCC High)

> **Government (GCC High) edition.** This is the US Government national-cloud edition for public-sector
> and defense-industrial-base (DIB) tenants running in **Microsoft Sentinel on Azure Government**
> (`portal.azure.us`), the **Microsoft Defender portal for US Gov** (`security.microsoft.us`), and the
> **US Gov identity/token endpoints** (`login.microsoftonline.us`, `graph.microsoft.us`). It mirrors the
> commercial method exactly, adapted for the sovereign cloud. Feature, connector, and preview
> availability in GCC High (and DoD/IL5) can **lag or differ from commercial** — every such point is
> flagged **"verify against current Microsoft Government documentation."** See
> `gcc-high-parity-notes.md` for the national-cloud endpoint table and parity considerations.

## What this is

A complete, self-guided method for standing up **Microsoft Sentinel** on a **governed, right-sized Log
Analytics workspace**, connecting the **high-value data sources** a detection program depends on, and
**controlling ingestion** so you collect what your detections need at a cost you chose deliberately.

It is the **foundation** layer of a Sentinel program. It produces a workspace that is connected,
governed, cost-aware, and health-monitored — ready for the analytics rules, hunting, and automation
that come next.

## How the technology works (the mental model)

- **Log Analytics workspace.** The container that stores all ingested telemetry. It has a **region**
  (chosen once, fixed for the life of the workspace — it drives data residency), a **pricing/commitment
  tier**, and **retention** settings. Everything Sentinel does runs against this workspace.
- **Microsoft Sentinel.** The SIEM/SOAR layer **enabled on** the workspace. It adds data connectors,
  analytics rules, hunting, watchlists, workbooks, incidents, and automation on top of the raw logs.
- **Data connectors.** The mechanisms that route a source's telemetry into the workspace. Modern
  connectors take one of three shapes:
  - **Diagnostic-settings connectors** (e.g. **Azure Activity**, **Microsoft Entra ID**) — a
    diagnostic setting on the source forwards selected **log categories** to the workspace.
  - **First-party API connectors** (e.g. **Microsoft Defender XDR**, **Office 365 / Microsoft 365**) —
    Microsoft services stream their own audit/alert data via a native integration you enable in the
    Content hub.
  - **Agent-based connectors** (**syslog** and **Common Event Format / CEF**) — the **Azure Monitor
    Agent (AMA)** on a Linux collector VM, driven by a **Data Collection Rule (DCR)**, receives
    syslog/CEF from network appliances and servers and forwards it to the workspace.
  - **GCC High note:** which specific connectors and connector shapes are available, and whether a given
    connector is generally available vs preview, **can differ in GCC High/DoD from commercial** — do not
    assume a commercial connector exists in the sovereign cloud. **Verify each in-scope connector against
    current Microsoft Government documentation** before you plan on it (see `gcc-high-parity-notes.md`).
- **Data Collection Rules (DCRs).** The rules that tell the Azure Monitor Agent **what to collect and
  what to drop** (which syslog facilities/severities, which CEF streams). A DCR is where you **filter
  noise before it is ingested and billed** — the single most effective cost control in the whole
  pipeline.
- **Table plan & log tiers.** Each source lands in one or more **tables** (e.g. `SigninLogs`,
  `AzureActivity`, `CommonSecurityLog`, `Syslog`). Every table can sit on a **log tier**:
  - **Analytics logs** — full query, drives analytics rules, higher per-GB cost. Use for detection-
    driving data.
  - **Basic / Auxiliary logs** — cheap ingestion, limited/search-only query, not for scheduled rules.
    Use for high-volume, low-signal data you keep for hunting/forensics. *(Basic vs Auxiliary tier
    availability differs by table and evolves — verify current availability in your tenant.)*
- **Retention & archive.** Data is kept in **interactive retention** (fully queryable) for a chosen
  period, then can move to **long-term/archive** (cheaper, restore-to-query). Retention is set per
  workspace and can be overridden **per table**.
- **Connector / ingestion health.** Sentinel's **health monitoring** surfaces the `SentinelHealth`
  table and data-connector status so you can prove data is still arriving and detect **ingestion
  drift** (a source that quietly stopped sending).

## The standard deployment model

Every solution in this program follows the same five stages so each rollout feels familiar and
low-risk:

1. **Assess.** Confirm subscription, region/residency decision, roles, and a written ingestion/cost
   plan. Discover any existing workspace and connectors (run `SENTDEPG-Discovery.ps1`).
2. **Configure.** Create/confirm the workspace `Security Telemetry - Tenant - Workspace`, enable
   Sentinel, set up least-privilege RBAC groups, and stage the table plan and retention.
3. **Pilot.** Connect **one** high-value source end to end (Azure Activity), then stand up the
   **AMA/DCR syslog+CEF** path behind a **filtering DCR** on a single pilot forwarder — proving the
   noisy path is controlled before it scales.
4. **Validate.** Confirm data is arriving in the expected tables at the expected volume, RBAC is
   least-privilege, DCR filtering is working, and health monitoring reports the connectors as healthy
   (run `SENTDEPG-Validate.ps1`, review `SENTDEPG-Report.ps1`).
5. **Expand.** Roll the remaining connectors (Entra ID, Defender XDR, Office 365) and additional
   forwarders/appliances into the same named pattern, re-checking volume and cost at each step.

## Scope — what this solution covers

- Workspace **design and sizing** decisions (region/residency, tier, resource group placement).
- **RBAC** on the workspace using least-privilege Sentinel roles mapped to named security groups.
- Enabling and configuring the **five high-value connectors**: Entra ID, Defender XDR, Office 365,
  Azure Activity, and syslog/CEF via AMA + DCR.
- **Data Collection Rules** that filter noise at ingestion.
- A **table plan** (Analytics vs Basic/Auxiliary) and a **retention/archive** strategy per table.
- **Connector and ingestion health** monitoring, drift detection, and gap reporting.

## Out of scope (handled elsewhere)

- **Analytics rules, detections, and MITRE ATT&CK coverage** — the companion *Sentinel Analytics Rules
  & MITRE ATT&CK Coverage* solution (this foundation feeds it).
- **SOAR playbooks / automation rules** beyond enabling the platform to support them.
- **Third-party / non-Microsoft cloud connectors** beyond the generic syslog/CEF path (AWS, GCP, and
  specific appliance connectors follow the same pattern but are per-vendor — deferred to Microsoft's
  connector docs; *verify current availability in your tenant*).
- **The regulatory determination** of how long data must be retained or where it must reside — that is
  your compliance function's decision; this solution implements the control you choose.

## Authentication and connections used (Government / GCC High endpoints)

- **Azure Government portal** (`portal.azure.us`) and the **Microsoft Defender portal for US Gov**
  (`security.microsoft.us`) for configuration. The Entra admin center is reached at `entra.microsoft.us`
  (*verify the current GCC High portal URL*).
- **PowerShell** with the **Az** modules (`Az.Accounts`, `Az.OperationalInsights`, `Az.Monitor`,
  `Az.SecurityInsights`) for workspace, DCR, diagnostic-setting, retention, and reporting operations,
  and **Microsoft.Graph** (`Connect-MgGraph`) for the Entra ID diagnostic-setting and group checks.
  In GCC High the delivered scripts default to `Connect-AzAccount -Environment AzureUSGovernment` and
  Graph should use `Connect-MgGraph -Environment USGov` (Graph host `graph.microsoft.us`; **DoD/IL5 uses
  `dod-graph.microsoft.us` — verify your cloud**).
- **KQL** run against the workspace (via `Invoke-AzOperationalInsightsQuery`) for ingestion-volume and
  connector-health reporting.
- All tools authenticate **interactively** with an MFA-capable admin against the **US Gov token host
  `login.microsoftonline.us`**; **no credentials are stored in code**. Endpoints differ between GCC High
  and DoD — *verify the correct endpoints for your cloud against current Microsoft Government
  documentation* (see `gcc-high-parity-notes.md`).


---


# Requirements — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion

These are the **solution-specific** prerequisites for this deployment. The **platform baseline** —
an Azure subscription, a Log Analytics workspace, Sentinel enabled, least-privilege roles, an
ingestion/retention cost plan, diagnostic-settings capability, and change control — is covered once in
**`global-requirements-sentinel-solutions.md`** (requirements **G1–G7**). Read that first; the items
below layer on top of it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. A deliberate workspace region and residency decision

- **Description:** A chosen Azure region for the Log Analytics workspace `Security Telemetry - Tenant -
  Workspace`, made **before** any ingestion starts.
- **Why required:** The workspace region fixes **data residency** and cannot be changed later — moving
  data means building a new workspace and re-connecting every source. It also affects cross-region
  egress and which features/tiers are available.
- **How to verify:** `portal.azure.us` → **Log Analytics workspaces** → open the workspace →
  **Overview** shows its region. Confirm the region matches your residency requirement.
- **How to implement if missing:** Agree the region with your compliance/security function (this is a
  determination for them, not a technical default), then create the workspace in that region. If a
  workspace already exists in the wrong region, plan a rebuild — do not try to relocate it.

## R2. Least-privilege Sentinel RBAC groups

- **Description:** Three Entra ID security groups mapped to Sentinel's built-in roles:
  `SG-Sentinel-Reader-Tenant` (**Microsoft Sentinel Reader**), `SG-Sentinel-Responder-Tenant`
  (**Microsoft Sentinel Responder**), and `SG-Sentinel-Contributor-Tenant` (**Microsoft Sentinel
  Contributor**).
- **Why required:** Sentinel access should be **role-scoped**, not blanket subscription Contributor.
  Analysts need to read and triage; only a small team should change configuration. Groups make access
  reviewable and revocable.
- **How to verify:** `entra.microsoft.us` → **Groups** — confirm the three groups exist. On the
  workspace, **Access control (IAM) → Role assignments** — confirm each group holds the matching
  Sentinel role at the **workspace/resource-group** scope (not subscription-wide).
- **How to implement if missing:** Create the three groups; assign the Sentinel roles at the resource
  group `RG-Security-Sentinel` (or workspace) scope. Prefer **PIM-eligible** activation for the
  Contributor group where Entra ID P2 is available (*verify licensing*).

## R3. A resource group for the security telemetry resources

- **Description:** A dedicated resource group, `RG-Security-Sentinel`, holding the workspace, DCRs, and
  the log-forwarder VM.
- **Why required:** Grouping the Sentinel resources makes RBAC scoping, cost tracking, and clean
  teardown/rollback straightforward, and keeps security telemetry separate from application resources.
- **How to verify:** `portal.azure.us` → **Resource groups** → confirm `RG-Security-Sentinel` exists
  and contains the workspace.
- **How to implement if missing:** Create the resource group in the same subscription and region family
  as the workspace; place the workspace and all subsequent DCRs/forwarders in it.

## R4. The Content hub connectors installed for the in-scope sources

- **Description:** The Microsoft Sentinel **Content hub** solution packages for **Microsoft Entra ID**,
  **Microsoft Defender XDR**, **Microsoft 365 (Office 365)**, **Azure Activity**, and the **Syslog /
  Common Event Format (CEF) via AMA** connectors.
- **Why required:** Modern Sentinel connectors are delivered as Content hub solutions; the connector
  page and its parsers/workbooks only appear once the solution is installed.
- **How to verify:** Sentinel → **Content hub** — confirm each solution shows **Installed**. Sentinel →
  **Data connectors** — the corresponding connectors are listed.
- **How to implement if missing:** Content hub → search each solution → **Install**. Installation only
  adds the connector definitions; it does **not** start ingestion (that happens in
  `03-implementation.md`).
- **GCC High parity check:** Content hub catalog contents and connector availability **can lag or differ
  in GCC High/DoD** — a solution or connector present in commercial may be delayed, in preview, or
  absent in the sovereign cloud. **Confirm each of the five in-scope connectors is available in your
  Government cloud, and whether it is GA or preview, against current Microsoft Government documentation**
  before committing the plan. Do not assume commercial parity (see `gcc-high-parity-notes.md`).

## R5. Source-side rights to enable each connector

- **Description:** The specific rights each connector needs on **its own source**, beyond workspace
  access:
  - **Entra ID:** a role that can edit **Entra ID → Diagnostic settings** (e.g. Security Administrator
    / Global Administrator for the tenant diagnostic setting).
  - **Defender XDR & Office 365:** appropriate Defender/Security roles to enable the connector.
  - **Azure Activity:** Owner/Contributor (or a role with `Microsoft.Insights` diagnostic-setting
    rights) on each **subscription** being connected.
- **Why required:** Each connector switches on telemetry at the source; without source-side rights the
  connector page will show as connectable but the data will never flow.
- **How to verify:** For each source, confirm the operating account can open that source's diagnostic
  settings / connector enablement page **without an access error**.
- **How to implement if missing:** Assign the minimum source-side role (prefer PIM-eligible), or hand
  the specific step to whoever holds it. Record who enabled each source in the change record (G7).

## R6. A Linux log-forwarder for syslog/CEF (AMA path)

- **Description:** A supported Linux VM, `Log Forwarder - Perimeter - Pilot`, reachable from the
  appliances/servers that emit **syslog** and **CEF**, onto which the **Azure Monitor Agent (AMA)** is
  installed and driven by DCRs.
- **Why required:** Network appliances and many servers cannot talk to Sentinel directly; they send
  syslog/CEF to a collector, and the AMA on that collector forwards it to the workspace under a DCR.
- **How to verify:** Confirm a Linux VM exists (or is planned), is network-reachable from the log
  sources (typically UDP/TCP 514), and can host the AMA extension. `portal.azure.us` → the VM →
  **Extensions** shows whether **AzureMonitorLinuxAgent** is present.
- **How to implement if missing:** Provision a small supported Linux VM in `RG-Security-Sentinel`;
  ensure the sources can route syslog/CEF to it; the AMA and DCRs are installed in
  `03-implementation.md`. *(Confirm current supported distributions in Microsoft's AMA documentation.)*

## R7. A written table plan and retention decision per table

- **Description:** A short table listing each expected table (`SigninLogs`, `AuditLogs`,
  `AzureActivity`, `OfficeActivity`, `CommonSecurityLog`, `Syslog`, Defender tables, etc.), its
  intended **log tier** (Analytics vs Basic/Auxiliary), and its **interactive retention** and
  **archive** duration.
- **Why required:** Tier and retention are the two biggest cost levers and are set per table. Deciding
  them up front prevents both overspend (everything on Analytics forever) and blind spots (detection
  data on a search-only tier).
- **How to verify:** Confirm a written plan exists and that each in-scope table has an assigned tier and
  retention. Sentinel/Log Analytics → **Tables** shows current tier and retention per table.
- **How to implement if missing:** Draft the plan from the source categories in scope (put detection-
  driving tables on Analytics; high-volume, low-signal tables on Basic/Auxiliary where supported);
  agree retention with compliance (R1 owner). The plan is applied via `SENTDEPG-Set-Retention.ps1`
  (`-WhatIf` first). *(Basic/Auxiliary eligibility varies by table — verify in your tenant.)*

## R8. The PowerShell toolchain

- **Description:** A workstation with the **Az** modules (`Az.Accounts`, `Az.OperationalInsights`,
  `Az.Monitor`, `Az.SecurityInsights`) and **Microsoft.Graph**, signed in with an MFA-capable admin.
- **Why required:** The five delivered tools use these modules to discover state, preview/apply
  diagnostic settings and retention, validate the build, and report ingestion/health.
- **How to verify:** In PowerShell 7+: `Get-Module Az.OperationalInsights,Az.Monitor,Az.SecurityInsights
  -ListAvailable` returns versions; in GCC High, `Connect-AzAccount -Environment AzureUSGovernment` and
  `Connect-MgGraph -Environment USGov` succeed against the US Gov endpoints.
- **How to implement if missing:** `Install-Module Az -Scope CurrentUser` and `Install-Module
  Microsoft.Graph -Scope CurrentUser`; sign in. For this Government (GCC High) edition, connect with
  `-Environment AzureUSGovernment` (Az) and `-Environment USGov` (Graph, host `graph.microsoft.us`); the
  delivered scripts already default their `-Environment` parameter to **`AzureUSGovernment`**. **DoD/IL5
  uses `dod-graph.microsoft.us` — verify the correct endpoints for your cloud against current Microsoft
  Government documentation.**


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


# Implementation — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion — Government (GCC High)

This is the ordered, do-this-then-that guide for the **US Government (GCC High)** edition. It follows the
standard model (**Assess → Configure → Pilot → Validate → Expand**) and is **pilot-first**: you connect
and prove one source, stand up the **noisy syslog/CEF path behind a filtering DCR** on a single
forwarder, validate volume and cost, and only then expand. Every object is named verbatim so the
scripts, testing, and troubleshooting line up. Replace `contoso.com` / `contoso.onmicrosoft.com` and the
sample subscription names with your own.

> **National-cloud endpoints.** This edition runs in **Azure Government**. Use the US Gov hosts
> throughout: Azure/Sentinel portal `portal.azure.us`, Defender portal `security.microsoft.us`, Entra
> admin `entra.microsoft.us`, token host `login.microsoftonline.us`, Graph `graph.microsoft.us` (**DoD/IL5
> `dod-graph.microsoft.us`**). PowerShell uses `-Environment AzureUSGovernment` (Az) / `-Environment
> USGov` (Graph). If a portal path or URL differs, **verify against current Microsoft Government
> documentation.**

> **Portal note.** Portal navigation evolves. Microsoft Sentinel is reached either from
> `portal.azure.us` → **Microsoft Sentinel**, or from the unified **Defender portal for US Gov**
> (`security.microsoft.us`) once onboarded. Paths below use the Azure Government portal; if your tenant
> uses the Defender portal, the same pages appear under **Microsoft Sentinel** there. Where a tier,
> connector, or capability may differ by tenant/region/cloud (GCC High vs DoD vs commercial), **verify
> against current Microsoft Government documentation.**

> **Cost gate.** Every step in this guide adds ingestion, and ingestion is billed. Do **not** connect a
> source or remove a DCR filter until the ingestion/cost plan (global requirement **G5** + **R7**) is
> agreed and has a budget owner. Connect one source, read the volume with `SENTDEPG-Report.ps1`, then
> proceed.

## Object naming (used verbatim throughout)

| Object | Name |
| --- | --- |
| Resource group | `RG-Security-Sentinel` |
| Log Analytics workspace | `Security Telemetry - Tenant - Workspace` |
| Reader access group | `SG-Sentinel-Reader-Tenant` (Microsoft Sentinel Reader) |
| Responder access group | `SG-Sentinel-Responder-Tenant` (Microsoft Sentinel Responder) |
| Contributor access group | `SG-Sentinel-Contributor-Tenant` (Microsoft Sentinel Contributor) |
| Entra ID diagnostic setting | `Diag-EntraID-SignInAudit-Pilot` |
| Azure Activity DCR | `DCR-AzureActivity-Subscription-Pilot` |
| Linux log forwarder VM | `Log Forwarder - Perimeter - Pilot` |
| Syslog DCR (filtered) | `DCR-Syslog-Linux-Pilot` |
| CEF DCR (filtered) | `DCR-CEF-Appliances-Pilot` |
| Ingestion-health workbook | `Workbook-IngestionHealth-Tenant` |

---

## Phase 0 — Assess (confirm you can build safely)

1. **Confirm the platform baseline (G1–G7).** Active subscription, the region/residency decision
   (**R1**), roles, the ingestion/cost plan (**G5**/**R7**), and a change record (**G7**).
2. **Discover the current state.** Run **`SENTDEPG-Discovery.ps1`** (read-only). It reports whether a
   workspace exists, whether Sentinel is enabled, which connectors and DCRs are already present, table
   tiers, and retention — so you build on reality, not assumption.
   - **Gate 0:** you know the current workspace/connector state and have a written cost plan → continue.
3. **Confirm the toolchain (R8).** `Connect-AzAccount` and `Connect-MgGraph` both succeed with an
   MFA-capable admin.

## Phase 1 — Configure the workspace, Sentinel, and RBAC

### Step 1 — Create the resource group and workspace

1. `portal.azure.us` → **Resource groups** → **Create** → name **`RG-Security-Sentinel`**, choose your
   subscription and the region from **R1** → **Review + create** → **Create**.
2. **Log Analytics workspaces** → **Create** → resource group `RG-Security-Sentinel`, name **`Security
   Telemetry - Tenant - Workspace`**, region per **R1** → **Review + create** → **Create**.
3. Open the workspace → **Usage and estimated costs** → set the **pricing tier**. Start on
   **Pay-as-you-go** unless your estimated daily volume (G5) already justifies a **commitment tier** —
   you can move up later once `SENTDEPG-Report.ps1` shows real volume.

### Step 2 — Enable Microsoft Sentinel on the workspace

1. `portal.azure.us` → **Microsoft Sentinel** → **Create** → select **`Security Telemetry - Tenant -
   Workspace`** → **Add**.
2. Wait for Sentinel to finish onboarding; the workspace now appears in the Sentinel list.

### Step 3 — Set least-privilege RBAC (R2)

1. `entra.microsoft.us` → **Groups** → create the three security groups if they do not exist:
   **`SG-Sentinel-Reader-Tenant`**, **`SG-Sentinel-Responder-Tenant`**,
   **`SG-Sentinel-Contributor-Tenant`**.
2. `portal.azure.us` → **Resource groups** → `RG-Security-Sentinel` → **Access control (IAM)** → **Add
   role assignment**:
   - **Microsoft Sentinel Reader** → `SG-Sentinel-Reader-Tenant`.
   - **Microsoft Sentinel Responder** → `SG-Sentinel-Responder-Tenant`.
   - **Microsoft Sentinel Contributor** → `SG-Sentinel-Contributor-Tenant`.
3. Do **not** grant subscription-wide Contributor for day-to-day SOC work. Keep the Contributor group
   small; where **Entra ID P2** is available, make it **PIM-eligible** (*verify licensing*).

### Step 4 — Stage the table plan and retention (R7) — plan now, apply after pilot

1. Draft the table plan: for each expected table, decide **Analytics** (detection-driving) vs
   **Basic/Auxiliary** (high-volume, low-signal — *verify eligibility per table*), plus interactive
   retention and archive months.
2. Preview it with **`SENTDEPG-Set-Retention.ps1`** (`-WhatIf` by default) — it prints the intended
   per-table tier/retention plan and changes nothing yet. You apply it in Phase 4 once real tables
   exist.

## Phase 2 — Pilot the low-risk connector (Azure Activity)

Azure Activity is the safest first source: it is a diagnostic-settings connector, it is high-value for
detections, and its volume is predictable.

1. Sentinel → **Content hub** → install the **Azure Activity** solution (**R4**) if not already
   installed.
2. Sentinel → **Data connectors** → **Azure Activity** → **Open connector page** → **Launch Azure Policy
   Assignment Wizard** (or **Add subscription**) → select the pilot subscription → this creates the
   Data Collection Rule **`DCR-AzureActivity-Subscription-Pilot`** that forwards Activity logs to the
   workspace.
3. Give it 15–30 minutes, then confirm data is arriving:
   - Sentinel → **Logs** → run `AzureActivity | take 10` → rows return.
   - Or run **`SENTDEPG-Report.ps1`** — `AzureActivity` shows a non-zero ingestion volume.
   - **Gate 1:** `AzureActivity` returns rows and reports a bounded volume → continue.

## Phase 3 — Pilot the NOISY path (syslog/CEF via AMA + filtering DCR)

This is the path that most often blows up ingestion cost, so it is piloted behind a **filtering DCR**
on a single forwarder before it scales.

### Step 1 — Stand up the forwarder and install the agent

1. Confirm the Linux collector VM **`Log Forwarder - Perimeter - Pilot`** exists in
   `RG-Security-Sentinel` and is reachable from the appliances/servers (typically UDP/TCP **514**)
   (**R6**).
2. Sentinel → **Content hub** → install **Syslog via AMA** and **Common Event Format (CEF) via AMA**
   (**R4**).

### Step 2 — Create the FILTERING syslog DCR

1. Sentinel → **Data connectors** → **Syslog via AMA** → **Open connector page** → **Create data
   collection rule** → name **`DCR-Syslog-Linux-Pilot`**, resource group `RG-Security-Sentinel`.
2. Add the forwarder VM **`Log Forwarder - Perimeter - Pilot`** as a resource (this installs the AMA on
   it automatically).
3. **Select only the facilities and minimum severity you actually need** — for example
   `auth`, `authpriv`, `cron`, and `security` at severity **`LOG_WARNING` and above**. **Do not** select
   all facilities at `LOG_DEBUG`/`LOG_INFO` — that is the classic cost-blowout. This selection **is**
   the noise filter.
4. Save. The syslog data lands in the **`Syslog`** table.

### Step 3 — Create the FILTERING CEF DCR

1. Sentinel → **Data connectors** → **Common Event Format (CEF) via AMA** → **Open connector page** →
   **Create data collection rule** → name **`DCR-CEF-Appliances-Pilot`**, add the same forwarder VM.
2. Constrain the CEF stream to the appliance log sources you need; CEF lands in the
   **`CommonSecurityLog`** table.
3. On the forwarder, run Microsoft's provided installer command (shown on the connector page) to
   configure the syslog daemon to hand CEF messages to the AMA. *(Use the exact command from the portal
   for your distribution — it changes; do not hand-copy an old one.)*

### Step 4 — Point ONE appliance/server at the forwarder

1. Configure a **single** pilot appliance/server to send syslog/CEF to `Log Forwarder - Perimeter -
   Pilot` on 514. Keep it to one source until volume is confirmed.
2. After ~30 minutes, confirm arrival and, critically, **volume**:
   - `Syslog | where TimeGenerated > ago(1h) | summarize count() by SeverityLevel` — confirm the
     filtered severities only.
   - `CommonSecurityLog | take 10` — CEF rows return.
   - Run **`SENTDEPG-Report.ps1`** — `Syslog` and `CommonSecurityLog` volumes are **bounded** and match
     the filter, not the full firehose.
   - **Gate 2:** filtered syslog/CEF arrives at a **controlled** volume → the DCR filter works.

## Phase 4 — Validate (prove the foundation before you scale)

1. Run **`SENTDEPG-Validate.ps1`** — it checks, as pass/fail lines aligned to `05-testing.md`: workspace
   exists in the right region; Sentinel enabled; the three RBAC groups assigned at resource-group scope
   and **no** subscription-wide Contributor for the SOC; Azure Activity DCR present and ingesting; the
   syslog/CEF DCRs present with **facility/severity filtering applied**; table tiers/retention set.
2. Run **`SENTDEPG-Report.ps1`** — review **ingestion GB/day per table**, project the monthly cost
   against the G5 budget, and confirm connector **health** (no source with zero rows in the last N
   hours).
3. **Apply the table plan/retention** now that tables exist: **`SENTDEPG-Set-Retention.ps1`** — review
   the `-WhatIf` output, then re-run with **`-Commit`** to move low-signal tables to Basic/Auxiliary
   (where eligible) and set per-table interactive retention + archive.
   - **Gate 3 (go/no-go to expand):** all validation lines PASS and projected cost is within budget →
     expand. Any FAIL → fix before adding more sources.

## Phase 5 — Expand (roll out the remaining high-value connectors)

Add the remaining sources one at a time, re-reading volume/cost after each.

> **GCC High connector parity.** Before enabling each source below, confirm the connector exists and is
> GA (not preview or unavailable) in your Government cloud — Entra ID, Defender XDR, and Office/Microsoft
> 365 connectors, and specific advanced-hunting event tables, **can lag or differ in GCC High/DoD from
> commercial**. Do not assume availability; **verify against current Microsoft Government documentation**
> (see `gcc-high-parity-notes.md`).

### Microsoft Entra ID (identity — highest-value)

1. Sentinel → **Content hub** → install **Microsoft Entra ID** (**R4**).
2. `entra.microsoft.us` → **Identity → Monitoring & health → Diagnostic settings** → **Add diagnostic
   setting** → name **`Diag-EntraID-SignInAudit-Pilot`** → select categories **`SignInLogs`**,
   **`AuditLogs`** (add `NonInteractiveUserSignInLogs`, `ManagedIdentitySignInLogs` only if your
   detections need them — they are high-volume) → **Send to Log Analytics workspace** → `Security
   Telemetry - Tenant - Workspace` → **Save** (**R5**).
3. Confirm: `SigninLogs | take 10` and `AuditLogs | take 10` return rows within ~30 minutes. Re-run
   `SENTDEPG-Report.ps1` and check the added volume.

### Microsoft Defender XDR

1. Sentinel → **Content hub** → install **Microsoft Defender XDR** (**R4**).
2. Sentinel → **Data connectors** → **Microsoft Defender XDR** → **Open connector page** → **Connect
   incidents & alerts**; enable the **advanced-hunting event tables** you need (be selective —
   `DeviceEvents`/`DeviceNetworkEvents` are high-volume) (**R5**).
3. Confirm `SecurityIncident` and any selected `Device*` tables populate; check volume.

### Office 365 / Microsoft 365

1. Sentinel → **Content hub** → install **Microsoft 365 (Office 365)** (**R4**).
2. Sentinel → **Data connectors** → **Office 365** → **Open connector page** → enable **Exchange**,
   **SharePoint**, **Teams** as needed (**R5**).
3. Confirm `OfficeActivity` populates; check volume.

### After each connector

- Re-run **`SENTDEPG-Report.ps1`** and confirm cumulative GB/day stays within the G5 budget.
- Add each new forwarder/appliance to the **existing** `DCR-Syslog-Linux-Pilot` / `DCR-CEF-Appliances-
  Pilot` pattern (rename the `-Pilot` DCRs to a production stage in a change window if you standardize
  on a `-Prod` suffix — keep the convention consistent).
- Set up ongoing health: Sentinel → **Settings → Settings → Health monitoring** (enable the
  `SentinelHealth` table) and deploy the **`Workbook-IngestionHealth-Tenant`** workbook (start from the
  Microsoft *Data collection health monitoring* workbook in Content hub) so ingestion drift is visible.

## Rollback (for any step)

- **A connector:** delete its diagnostic setting (`Diag-EntraID-SignInAudit-Pilot`) or DCR, or disable
  the connector on its page — ingestion for that source stops immediately.
- **The syslog/CEF path:** delete `DCR-Syslog-Linux-Pilot` / `DCR-CEF-Appliances-Pilot` (the AMA stops
  forwarding) and/or stop the source sending to the forwarder.
- **RBAC:** remove the role assignment from the security group.
- **The workspace/Sentinel:** removing Sentinel from the workspace stops SIEM features but **retains
  already-ingested data** until retention expires; deleting the workspace deletes the data. Treat
  workspace deletion as a change-controlled, last-resort action.


---


# Testing & Validation — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion

Work these gates **in order**. Each is **pass/fail**: do not advance a phase until its gate passes. The
delivered scripts automate most checks; the KQL queries can be run in Sentinel → **Logs**. Run
**`SENTDEPG-Validate.ps1`** for a consolidated pass/fail summary and **`SENTDEPG-Report.ps1`** for
volume/cost/health.

---

## Gate 1 — Workspace exists in the correct region

- **Check:** `portal.azure.us` → **Log Analytics workspaces** → `Security Telemetry - Tenant -
  Workspace` exists, in the region agreed in **R1**, inside `RG-Security-Sentinel`.
- **Automated:** `SENTDEPG-Discovery.ps1` / `SENTDEPG-Validate.ps1` report the workspace name, region, and
  resource group.
- **Pass:** workspace present, correct region, correct resource group. **Fail:** missing or wrong region
  → rebuild in the correct region (region cannot be changed).

## Gate 2 — Microsoft Sentinel enabled

- **Check:** `portal.azure.us` → **Microsoft Sentinel** → the workspace is listed.
- **Automated:** `SENTDEPG-Validate.ps1` confirms the Sentinel `SecurityInsights` solution/onboarding
  state on the workspace.
- **Pass:** Sentinel enabled. **Fail:** enable it (implementation Phase 1, Step 2).

## Gate 3 — Least-privilege RBAC is correct

- **Check:** Workspace / `RG-Security-Sentinel` → **Access control (IAM) → Role assignments** — the
  three groups hold **Reader / Responder / Contributor** at resource-group scope; **no** broad
  subscription Contributor is used for routine SOC work.
- **Automated:** `SENTDEPG-Validate.ps1` lists the Sentinel role assignments and flags any subscription-
  scope Owner/Contributor granting Sentinel access.
- **Pass:** roles mapped to the named groups at RG/workspace scope; no over-broad grants. **Fail:**
  correct the assignments (implementation Phase 1, Step 3).

## Gate 4 — Azure Activity is ingesting (first source proven)

- **Check (KQL):** `AzureActivity | where TimeGenerated > ago(1h) | count` → non-zero.
- **Automated:** `SENTDEPG-Report.ps1` shows `AzureActivity` with a bounded GB/day figure; the DCR
  `DCR-AzureActivity-Subscription-Pilot` is present.
- **Pass:** rows arriving, volume bounded. **Fail:** re-check the connector/DCR and source-side rights
  (**R5**); see troubleshooting.

## Gate 5 — Syslog/CEF arrives AND the DCR filter is working

- **Check (KQL):**
  - `Syslog | where TimeGenerated > ago(1h) | summarize count() by SeverityLevel` — **only** the
    severities you allowed appear (no `Debug`/`Info` flood).
  - `CommonSecurityLog | where TimeGenerated > ago(1h) | count` — non-zero from the pilot appliance.
- **Automated:** `SENTDEPG-Validate.ps1` confirms `DCR-Syslog-Linux-Pilot` and `DCR-CEF-Appliances-Pilot`
  exist and that facility/severity filtering is configured (not "all facilities / all severities").
- **Pass:** filtered syslog/CEF arriving at a controlled volume. **Fail:** the filter is missing or the
  forwarder path is broken → see troubleshooting (this is the top cost risk).

## Gate 6 — Ingestion volume is within the cost budget

- **Check:** `SENTDEPG-Report.ps1` totals GB/day per table and projects the monthly cost; compare to the
  **G5** budget.
- **KQL cross-check:**
  `Usage | where TimeGenerated > ago(24h) | summarize GB=sum(Quantity)/1024 by DataType | sort by GB desc`
- **Pass:** projected cost ≤ budget (or an accepted, signed-off variance). **Fail:** move high-volume
  low-signal tables to Basic/Auxiliary, tighten DCR filters, or drop non-detection categories, then
  re-measure.

## Gate 7 — Table plan and retention applied

- **Check:** Sentinel/Log Analytics → **Tables** — each in-scope table shows the intended **tier**
  (Analytics vs Basic/Auxiliary) and **retention/archive** per the **R7** plan.
- **Automated:** `SENTDEPG-Set-Retention.ps1` `-WhatIf` shows no remaining drift between plan and live
  state after you have run it with `-Commit`.
- **Pass:** tiers and retention match the plan. **Fail:** apply with `SENTDEPG-Set-Retention.ps1
  -Commit`.

## Gate 8 — Connector / ingestion health is monitored

- **Check (KQL):**
  - `SentinelHealth | where TimeGenerated > ago(24h) | summarize by SentinelResourceName, Status` —
    connectors report healthy.
  - Drift probe: `union withsource=Tbl * | where TimeGenerated > ago(24h) | summarize LastSeen=max(TimeGenerated) by Tbl`
    — every expected table has a recent `LastSeen`.
- **Automated:** `SENTDEPG-Report.ps1` flags any expected source with **zero rows** in the last N hours
  (ingestion drift) and summarizes `SentinelHealth`.
- **Pass:** health monitoring enabled, no unexplained silent source. **Fail:** enable health monitoring
  and deploy `Workbook-IngestionHealth-Tenant`; investigate any silent source.

## Gate 9 — Rollback is documented and reversible

- **Check:** The change record (**G7**) lists every object created — the workspace, Sentinel, the three
  role assignments, `Diag-EntraID-SignInAudit-Pilot`, `DCR-AzureActivity-Subscription-Pilot`,
  `DCR-Syslog-Linux-Pilot`, `DCR-CEF-Appliances-Pilot` — so each can be removed cleanly.
- **Pass:** a named, complete rollback list exists. **Fail:** complete it before expanding further.

---

### Consolidated pass criteria

The foundation is **validated and ready for detections** when **Gates 1–9 pass**: a governed workspace
in the right region with least-privilege RBAC, high-value sources ingesting, the noisy syslog/CEF path
filtered at the DCR, total volume within budget, tiers/retention applied, health monitored, and a clean
rollback documented.


---


# Troubleshooting — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion

Common failures, each as **symptom → cause → fix**. Start with `SENTDEPG-Discovery.ps1` (state) and
`SENTDEPG-Report.ps1` (volume/health) — most issues here are visible in one of the two.

---

## A connector shows "Connected" but no data arrives

- **Symptom:** The connector page reads connected, but `TableName | take 10` returns nothing after 30+
  minutes.
- **Cause:** Source-side telemetry was never switched on, or the diagnostic setting routes categories to
  a **different** workspace. "Connected" reflects the Sentinel side, not that the source is emitting.
- **Fix:** Confirm the source-side switch (**R5**): for Entra ID, that `Diag-EntraID-SignInAudit-Pilot`
  exists and points at `Security Telemetry - Tenant - Workspace` with the right categories; for Azure
  Activity, that `DCR-AzureActivity-Subscription-Pilot` targets this workspace. Allow up to ~30 minutes
  for first data. Check for a competing diagnostic setting sending the same categories elsewhere.

## Ingestion volume (and cost) explodes after enabling syslog/CEF

- **Symptom:** GB/day jumps sharply right after the AMA path goes live; `Syslog`/`CommonSecurityLog`
  dominate `Usage`.
- **Cause:** The DCR was created **without** a facility/severity filter (all facilities at
  `Debug`/`Info`), so the full firehose is being ingested and billed.
- **Fix:** Edit `DCR-Syslog-Linux-Pilot` to select **only** the needed facilities at **`LOG_WARNING`+**;
  constrain `DCR-CEF-Appliances-Pilot` to the required streams. Re-check with
  `Syslog | summarize count() by SeverityLevel`. This filter is the single biggest cost control — treat
  a missing filter as a Sev-2.

## Syslog/CEF: nothing arrives at all

- **Symptom:** `Syslog`/`CommonSecurityLog` stay empty after configuring the forwarder.
- **Cause:** The AMA is not installed on `Log Forwarder - Perimeter - Pilot`, the source cannot reach it
  on 514, the local syslog daemon is not handing messages to AMA, or (CEF) the portal installer command
  was not run for the correct distribution.
- **Fix:** Confirm the VM shows the **AzureMonitorLinuxAgent** extension; confirm the appliance can
  reach the forwarder on UDP/TCP 514 (NSG/firewall); re-run the **exact** CEF installer command from the
  connector page for your distro; check the daemon (`rsyslog`/`syslog-ng`) is running and forwarding.

## Entra ID sign-in / audit logs missing despite a diagnostic setting

- **Symptom:** `SigninLogs` or `AuditLogs` empty though `Diag-EntraID-SignInAudit-Pilot` exists.
- **Cause:** The needed **categories were not selected** (e.g. `SignInLogs` unchecked), the setting
  targets the wrong workspace, or the operator lacked rights to save it so it silently reverted.
- **Fix:** `entra.microsoft.us` → **Diagnostic settings** → open `Diag-EntraID-SignInAudit-Pilot`,
  confirm `SignInLogs` + `AuditLogs` are checked and the destination is the correct workspace, saved by
  an account with the required Entra role (**R5**).

## Data lands in the workspace but not visible to analysts

- **Symptom:** An analyst cannot see logs/incidents others can.
- **Cause:** The analyst is not in `SG-Sentinel-Reader-Tenant`/`Responder`, or the role was assigned at
  the wrong scope, or **table-level / resource-context RBAC** is restricting the table.
- **Fix:** Add the analyst to the correct group; confirm the role is assigned at
  `RG-Security-Sentinel`/workspace scope (Gate 3); check for table-level RBAC that narrows access.

## Retention / tier change did not take effect

- **Symptom:** A table still shows the old retention or is still on Analytics after you meant to move it.
- **Cause:** The plan was previewed with `-WhatIf` but never committed, the table is not eligible for
  the target tier, or the change is still propagating.
- **Fix:** Re-run `SENTDEPG-Set-Retention.ps1 -Commit`; confirm the table supports Basic/Auxiliary
  (*eligibility varies — verify*); allow propagation, then confirm in **Tables**.

## PowerShell: "resource not found" / authentication or context errors

- **Symptom:** A script errors on connect, on the workspace, or with an access-denied.
- **Cause:** Wrong Azure subscription context, missing Az/Graph modules, insufficient role, or — the most
  common GCC High cause — connecting to the **commercial** cloud instead of US Gov (wrong environment
  endpoint), so the workspace/resources are "not found."
- **Fix (GCC High):** `Connect-AzAccount -Environment AzureUSGovernment` then `Set-AzContext
  -Subscription <id>`; for Graph use `Connect-MgGraph -Environment USGov` (host `graph.microsoft.us`;
  **DoD/IL5 `dod-graph.microsoft.us`**). `Install-Module Az, Microsoft.Graph`; confirm at least Sentinel
  Reader on the workspace. The delivered scripts default `-Environment` to `AzureUSGovernment`; if you
  override it, keep it on the US Gov value (**R8**) — *verify endpoints for your cloud against current
  Microsoft Government documentation*.

## A previously healthy source silently stopped (ingestion drift)

- **Symptom:** A table has no recent rows; a detection depending on it is now blind, with no error.
- **Cause:** A diagnostic setting/DCR was deleted or changed, the forwarder VM is down, source-side
  logging was disabled, or a credential/permission lapsed.
- **Fix:** `SENTDEPG-Report.ps1` flags any source with zero rows in the last N hours;
  `SentinelHealth | summarize by SentinelResourceName, Status` shows connector health. Restore the
  setting/DCR or the forwarder; enable health monitoring (Gate 8) so drift is caught proactively next
  time.

## Duplicate data / double billing for a source

- **Symptom:** A source's volume looks doubled; the same events appear twice.
- **Cause:** Two diagnostic settings/DCRs route the **same** categories to the workspace (e.g. a legacy
  connector plus the new AMA path), so everything is ingested (and billed) twice.
- **Fix:** Inventory settings/DCRs per source (`SENTDEPG-Discovery.ps1`); remove the redundant one so
  only one path per source per category remains (global requirement **G6**).


---


# Best Practices — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion

Keep-it-clean guidance for a Sentinel foundation that stays governed, cost-aware, and detection-ready
over time.

## Design the workspace once, deliberately

- **Region is forever.** The workspace region fixes data residency and cannot be changed — decide it
  with compliance **before** ingestion, not after (**R1**).
- **One security workspace, not many.** Prefer a single, well-governed workspace for security telemetry
  over a sprawl of per-team workspaces; cross-workspace queries and RBAC get complex fast. Consolidate
  unless residency or hard tenancy boundaries force a split.
- **Separate security telemetry from application/ops logs.** Mixing a chatty application's logs into the
  SIEM workspace inflates cost and clutters detections. Keep `RG-Security-Sentinel` for security data.

## Collect what detections consume — not everything

- **Every GB is a recurring bill.** Ingestion and retention are the dominant Sentinel costs. Connect a
  source because a **detection or investigation needs it**, not because the connector exists.
- **Filter at the DCR, not after.** The cheapest log is the one you never ingest. Constrain syslog
  facilities/severities and CEF streams in `DCR-Syslog-Linux-Pilot` / `DCR-CEF-Appliances-Pilot` — do
  not ingest `Debug`/`Info` firehoses and try to filter in queries later.
- **Be selective with high-volume Microsoft tables.** `NonInteractiveUserSignInLogs`, Defender
  `DeviceNetworkEvents`, and full Office activity can dwarf everything else. Enable them only when a
  detection or hunt genuinely needs them.

## Use the log tiers on purpose

- **Analytics** for detection-driving, frequently queried tables (sign-ins, audit, incidents, key CEF).
- **Basic / Auxiliary** for high-volume, low-signal data kept for hunting/forensics — cheaper to ingest,
  search-only. *(Tier eligibility varies by table and evolves — verify per table.)*
- **Match retention to purpose, not habit.** Interactive retention for what analysts query day to day;
  **archive** for what you keep for compliance/forensics but rarely touch. Set retention **per table**,
  not one blanket number.

## Govern access with least privilege

- **Role-scoped groups, not blanket Contributor.** `SG-Sentinel-Reader/Responder/Contributor-Tenant`
  mapped to Sentinel's built-in roles at the resource-group/workspace scope. Analysts read and triage;
  only a small team changes configuration.
- **Make Contributor just-in-time** where Entra ID P2 allows (PIM-eligible) so standing high privilege
  is minimized (*verify licensing*).
- **Review assignments regularly** — access that made sense at rollout drifts.

## Prove data is arriving — continuously

- **Enable health monitoring** (`SentinelHealth`) and deploy `Workbook-IngestionHealth-Tenant`. A source
  that silently stops sending is a **blind detection** — the most dangerous failure in a SIEM because it
  is invisible until an incident is missed.
- **Alert on ingestion drift**, not just spikes. A table going to **zero** matters as much as a table
  doubling.
- **Watch the cost trend, not just the day.** Re-run `SENTDEPG-Report.ps1` on a schedule and compare
  GB/day against the G5 budget; catch creep early.

## Change safely

- **Pilot the noisy path first.** Syslog/CEF via AMA is where cost blows up — one forwarder, one
  appliance, a filtering DCR, measured, before you scale.
- **Name everything and record rollback.** Every diagnostic setting and DCR is named per convention and
  listed in the change record so it can be removed cleanly.
- **Move to commitment tiers with evidence.** Only step up to a commitment tier once real measured
  volume (not a guess) justifies it.

## Where to go next

With the foundation collecting the right data at a controlled cost, the natural next steps in this
catalog are:

- **Sentinel Analytics Rules & MITRE ATT&CK Coverage** — turn this telemetry into tuned detections
  mapped to the ATT&CK matrix, with false-positive control and detection-as-code. *(The direct
  companion to this solution.)*
- **Sentinel SOAR / automation** — automation rules and playbooks to respond to the incidents those
  detections raise.
- **Microsoft Defender XDR** and **Microsoft Entra ID** hardening solutions — strengthen the sources
  feeding this workspace.
- **Microsoft Purview** solutions — for the data-governance and insider-risk signals that complement
  security telemetry.


---


# Deliverables Summary — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion — Government (GCC High)

Everything included in this **Government (GCC High)** edition, and what each piece is for. This edition
mirrors the commercial method, adapted for Microsoft Sentinel on Azure Government (national-cloud
endpoints, USGov PowerShell environment) and ships an added **GCC High parity-notes** document.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page business framing: the drown-in-noise-and-cost problem, the right-order foundation, and the boundary (foundation, not detections). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how the technology works (workspace, Sentinel, connector shapes, DCRs, table tiers, retention, health), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (region/residency, RBAC groups, resource group, Content hub connectors, source-side rights, Linux forwarder, table/retention plan, toolchain) — layered on the shared `global-requirements-sentinel-solutions.md` (G1–G7). |
| **Implementation** (`03-implementation.md`) | Exact, ordered, click-by-click build: workspace + Sentinel + RBAC, pilot Azure Activity, pilot the noisy syslog/CEF path behind a filtering DCR, validate, then expand Entra/Defender/O365 — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates from workspace/region and RBAC through source ingestion, DCR-filter proof, cost-within-budget, tier/retention, and health monitoring, referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (connector connected but no data, syslog/CEF cost blowout, missing Entra logs, RBAC visibility, retention not applied, PowerShell/context errors, ingestion drift, duplicate billing) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Design-once workspace, collect-what-detections-consume, use the tiers on purpose, least-privilege access, prove-data-is-arriving, change safely — plus where to go next in the catalog. |
| **GCC High Parity Notes** (`gcc-high-parity-notes.md`) | The national-cloud endpoint table for this solution, GCC High/DoD feature-parity considerations to verify (connectors, tiers, previews), and the FedRAMP High / IL4–IL5 / CMMC / ITAR data-residency compliance context — each parity/availability point flagged "verify against current Microsoft Government documentation." |

## PowerShell tools (5)

All tools are **read-only or `-WhatIf` by default**, authenticate **interactively** (no credentials in
code), and use the **Az** modules (`Az.Accounts`, `Az.OperationalInsights`, `Az.Monitor`,
`Az.SecurityInsights`), **Microsoft.Graph** where needed, and **KQL** (via
`Invoke-AzOperationalInsightsQuery`) for reporting. Government-cloud tenants pass the matching
environment — *verify endpoints for your cloud*.

| Script | Type | What it does |
| --- | --- | --- |
| **`SENTDEPG-Discovery.ps1`** | Read-only | Discovers the current state: whether `Security Telemetry - Tenant - Workspace` exists (name/region/RG), whether Sentinel is enabled, which data connectors and DCRs are present, per-table tier and retention, and existing diagnostic settings — so you build on reality and can spot duplicate-ingestion paths. Changes nothing. |
| **`SENTDEPG-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as pass/fail lines: workspace/region, Sentinel enabled, least-privilege RBAC (flags over-broad grants), Azure Activity DCR ingesting, syslog/CEF DCRs present **with filtering applied**, and table tiers/retention set. |
| **`SENTDEPG-Report.ps1`** | Read-only | Ingestion + health rollup via KQL: GB/day per table (`Usage`), projected monthly cost against the budget, `SentinelHealth` connector status, and an **ingestion-drift** flag for any expected source with zero rows in the last N hours. Exports to CSV. |
| **`SENTDEPG-Set-Diagnostics.ps1`** | `-WhatIf` default | Diagnostic-setting helper: previews (and, with `-Commit`, applies) the Entra ID diagnostic setting `Diag-EntraID-SignInAudit-Pilot` and the Azure Activity routing to the workspace with only the in-scope categories — preview-first, fully reversible. |
| **`SENTDEPG-Set-Retention.ps1`** | `-WhatIf` default | Table-plan / retention helper: prints the intended per-table **tier** (Analytics vs Basic/Auxiliary) and **interactive retention + archive** plan; its `-Commit` path applies it. Notes where Basic/Auxiliary eligibility must be verified per table. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Resource group:** `RG-Security-Sentinel`
- **Workspace:** `Security Telemetry - Tenant - Workspace`
- **RBAC groups:** `SG-Sentinel-Reader-Tenant` (Reader), `SG-Sentinel-Responder-Tenant` (Responder),
  `SG-Sentinel-Contributor-Tenant` (Contributor)
- **Entra ID diagnostic setting:** `Diag-EntraID-SignInAudit-Pilot`
- **Azure Activity DCR:** `DCR-AzureActivity-Subscription-Pilot`
- **Linux log forwarder VM:** `Log Forwarder - Perimeter - Pilot`
- **Syslog DCR (filtered):** `DCR-Syslog-Linux-Pilot`
- **CEF DCR (filtered):** `DCR-CEF-Appliances-Pilot`
- **Ingestion-health workbook:** `Workbook-IngestionHealth-Tenant`

## What this solution deliberately does NOT do

- It does **not** author analytics rules or MITRE ATT&CK coverage — that is the companion *Sentinel
  Analytics Rules & MITRE ATT&CK Coverage* solution, which this foundation feeds.
- It does **not** connect a source before the ingestion/cost plan (G5) is agreed, or remove a DCR filter
  without measuring the cost impact.
- It does **not** grant blanket subscription Contributor for SOC work — access is least-privilege and
  role-scoped.
- It does **not** decide **data residency or retention duration** — those are compliance determinations;
  the solution implements the control you choose.
- It does **not** invent pricing, tier, or connector-capability facts — where Basic/Auxiliary
  eligibility, pricing, or a capability may differ by tenant/region/cloud, it says **verify in your
  tenant**.

## How it is delivered

This solution is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation
as a formatted Word document and PDF, plus all five PowerShell scripts, in a single ZIP
(`SENTDEPG-Complete-Solution.zip`) — yours to keep and reuse on every rollout.
