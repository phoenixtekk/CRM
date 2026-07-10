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
