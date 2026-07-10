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
