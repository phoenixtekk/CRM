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
