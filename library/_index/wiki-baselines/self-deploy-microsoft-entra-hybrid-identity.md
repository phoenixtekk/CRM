# Self-Deploy — Microsoft Entra: Hybrid Identity

> **Version 1.0.0** · Category: Entra · Solution code: EKHYBID

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Self-Deploy: Microsoft Entra Hybrid Identity

Entra ID Solutions · Self-Deploy (self-guided training)

Hybrid identity — the bridge between on-premises Active Directory and Microsoft Entra ID — breaks in
subtle, expensive ways: the wrong sync scope, a mismatched source anchor, a poorly chosen
authentication method, or a hybrid join that never completes. Most of those failures trace back to a
team that never internalized how the pieces fit. This Self-Deploy teaches hybrid identity on
Microsoft Entra as a self-guided training deliverable — concepts, guided hands-on labs, a health-check
lab, a take-home runbook, and a knowledge-check — so a competent admin team can run hybrid identity
confidently and diagnose it when it drifts.

## How this differs from the implementation product (important)
There is a separate, deeper **implementation** solution — *Hybrid Identity with Active Directory &
Microsoft Entra Connect* (HYBID) — that installs and configures production hybrid identity end to end.
**This kit is the team-enablement / labs companion to it, not a replacement.** It teaches the *why*
and rehearses the moving parts (sync engine choice, source anchor, UPN hygiene, PHS/PTA/federation
trade-offs, hybrid join, hybrid Conditional Access, health checks) in a safe, read-only / preview-first
way. When the team is ready to build for real, hand off to HYBID. The two are cross-referenced
throughout.

## What you get
- A plain-language **Solution Overview** of hybrid identity: Entra Connect vs Cloud Sync, sync scope,
  source anchor, UPN hygiene, and the three authentication methods, mapped to the standard deployment
  model (Assess → Configure → Pilot → Validate → Expand).
- A **Requirements** guide of the enablement-specific prerequisites (a read-only lab vantage point, the
  right modules) — the category-level prerequisites live in the separate global requirements file.
- A guided **Implementation** guide: ordered, hands-on labs on engine selection, sync scope / source
  anchor / UPN inspection, authentication-method trade-offs and staged-rollout patterns, hybrid join,
  hybrid Conditional Access, and a **health-check lab**.
- **Testing** (a knowledge-check and lab-validation procedures) and **Troubleshooting** guides.
- Five lab helpers: read-only hybrid discovery, prerequisite validation, a hybrid-health scorecard
  report, a read-only hybrid health-check, and a KQL signal pack for hybrid sign-in analysis.
- A take-home **hybrid-identity runbook** distilled from the labs.

## The outcome
A team fluent in hybrid identity on Entra — sync, source anchor, authentication method, hybrid join,
and hybrid Zero Trust understood and rehearsed — holding a runbook and a health-check routine, with a
clear path into the HYBID implementation solution for production work.

## Effort
Self-paced. Plan roughly two to three focused days for a small admin team to work through the concepts
and all guided labs. The labs are read-only / inspection-first and do not require changing a
production sync configuration.


---


# 1. Solution Overview — Self-Deploy: Microsoft Entra Hybrid Identity

## What this kit is
This is a self-guided **self-deploy**: a training deliverable that teaches an admin team how hybrid
identity works on Microsoft Entra and lets them rehearse each part hands-on. It is the team-enablement
companion to the **implementation** solution *Hybrid Identity with AD & Entra Connect* (HYBID) — it
builds understanding and diagnostic skill, and points to HYBID for production build-out. It is not
itself a production implementation project.

## What hybrid identity is
Most organizations keep user accounts in on-premises **Active Directory (AD)** while their apps,
devices, and security controls live in **Microsoft Entra ID** (the cloud directory). Hybrid identity
is the bridge: a **synchronization engine** copies AD users, groups, and contacts into Entra ID, and
an **authentication method** decides where the password is actually validated. Done well, a user has
one identity and one password that works on-premises and in the cloud. Done badly, you get duplicate
accounts, broken sign-in, and devices that will not join.

## How it works (the moving parts the team must master)
1. **Synchronization engine** — either **Entra Connect Sync** (full-featured, runs on a dedicated
   server) or **Entra Cloud Sync** (lightweight agent, cloud-driven). It copies AD objects to Entra
   ID on a schedule.
2. **Sync scope** — domain and organizational-unit (OU) filters decide which AD objects are in scope,
   keeping test/service objects out of the cloud.
3. **Source anchor** — the immutable attribute that ties an AD object to its Entra object (modern
   default: `ms-DS-ConsistencyGuid`). Choosing/mismatching it wrong causes duplicate or orphaned
   objects and painful re-joins.
4. **UPN / domain hygiene** — user principal names must use a public, verified, routable domain (not
   `.local`) or sign-in breaks and falls back to `onmicrosoft.com`.
5. **Authentication method** — **Password Hash Sync (PHS)**, **Pass-through Authentication (PTA)**, or
   **Federation (AD FS)**. Seamless SSO can accompany PHS/PTA.
6. **Hybrid Entra join** — registers domain-joined Windows devices into Entra ID so they satisfy
   Conditional Access and cloud management.
7. **Hybrid Conditional Access** — CA policies that require hybrid-joined / compliant devices, tying
   the on-premises device estate to cloud access decisions (requires Entra ID P1 — *verify*).
8. **Health monitoring** — sync status, last-sync time, sync errors, and agent health, so a stalled
   sync or auth-method fault is caught before users feel it.

## Connect Sync vs Cloud Sync (which engine)
- **Entra Connect Sync** — the full engine: complex filtering, device writeback, password writeback,
  and large or multi-forest environments. Runs on a dedicated server. Required for hybrid join +
  writeback scenarios.
- **Entra Cloud Sync** — a lightweight agent; the cloud does the heavy lifting. Suits simpler or
  disconnected-forest scenarios and multiple small domains, with fewer advanced options.
- The kit teaches how to choose, and inspects whichever is present in your environment.

## Authentication methods (choose one primary; PHS as backup)
- **Password Hash Sync (PHS)** — a hashed representation of the password syncs to Entra ID, which then
  validates sign-in itself. Simplest and most resilient; cloud sign-in survives an on-premises outage.
  Recommended default and recommended backup even when PTA/federation is primary.
- **Pass-through Authentication (PTA)** — lightweight agents validate the password against AD in real
  time; no password representation leaves the network. Requires the agents (and AD) to be available.
- **Federation (AD FS)** — hands authentication to an on-premises federation farm. Most complex and
  highest-maintenance; choose only for a specific requirement, and plan to migrate to cloud auth.

## The standard deployment model
Every solution in this catalog follows the same shape; the kit teaches the team to apply it to hybrid
identity work:

> **Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — run the read-only discovery and health check; capture engine, source anchor, auth
  method, UPN hygiene, and sync health.
- **Configure** — plan the change (engine, scope, auth method, hybrid join) — in the kit this is
  rehearsed/inspected, not applied to production.
- **Pilot** — apply to a small pilot / staged-rollout group first (in HYBID for real work).
- **Validate** — confirm sync, sign-in, and hybrid join with the health check and What-If.
- **Expand** — widen scope in staged rings only after validation.

## Scope of this kit
- **In scope:** teaching hybrid identity concepts; guided, read-only / inspection-first labs on engine
  choice, sync scope, source anchor, UPN hygiene, PHS/PTA/federation trade-offs and the staged-rollout
  move, hybrid join, hybrid Conditional Access, and a health-check lab; a take-home runbook and a
  knowledge-check; read-only discovery, validation, reporting, health-check, and KQL analysis helpers.
- **Out of scope (by design — use the HYBID implementation solution):** installing/configuring Entra
  Connect, converting a domain's authentication method, changing production sync scope, or enabling
  hybrid join for the real fleet. This kit deliberately does **not** duplicate the HYBID build steps.
  Cross-reference:
  - **Hybrid Identity with AD & Entra Connect** (HYBID) — the production implementation.
  - **Entra Connect source-anchor / ConsistencyGuid / domain consolidation** — deep source-anchor work.
  - **Entra Cloud Sync provisioning troubleshooting** — Cloud Sync join/provisioning issues.
  - **Zero Trust Conditional Access baseline** (ENTZTCA) — for the CA side of hybrid CA.
  - **Self-Deploy — Identity Modernization** (EKIDMOD) — the broader modernization journey this fits into.
- **Not covered / deferred to the customer:** regulatory, records, legal, and data-classification
  determinations, and production change-approval sign-off. The kit provides technical understanding and
  read-only tooling, not those decisions.

## Authentication and connections used
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) for portal labs.
- **On-premises tools** where a hybrid environment exists: the AD PowerShell module (RSAT) and, if
  present, the Entra Connect host (for read-only inspection of sync status).
- **Microsoft Graph PowerShell SDK** (`Microsoft.Graph`) for read-only discovery, validation, reporting,
  and health checks — using delegated, least-privilege read scopes.
- **Log Analytics / Microsoft Sentinel** (optional) for the KQL signal pack against `SigninLogs` —
  *requires diagnostic settings to export Entra logs; verify in your tenant.*


---


# 2. Requirements — Self-Deploy: Microsoft Entra Hybrid Identity

The **category-level** prerequisites (an Entra ID tenant, P1/P2 licensing, administrative roles,
break-glass accounts, healthy on-premises AD, an Entra Connect host, UPN/domain hygiene, and network
access to Microsoft cloud endpoints) are documented once in
**`global-requirements-entra-id-solutions.md`** — confirm those first; they are not repeated here.

Below are the prerequisites specific to running this **self-deploy** and its labs. Because this is
training, the labs are **read-only / inspection-first**: you inspect and rehearse against whatever
hybrid environment you have (or a lab environment) without changing a production sync configuration.

Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. A read-only vantage point into the identity estate
Description: The ability to sign in to the Entra admin center and run read-only Graph queries with at
least a **Global Reader** (or Security Reader) role.
Why required: Every lab inspects real configuration — domains, sync status, source anchor, auth method,
hybrid-join state — without changing it.
How to verify: Entra → **Roles and administrators**; confirm the operator has Global Reader (or higher
read). `EKHYBID-Discovery.ps1` confirms it can read directory/sync data.
How to implement if missing: Assign **Global Reader** to the training operator. Elevated write roles are
**not** needed for this kit (they are needed in the HYBID implementation solution).

## R2. (Where available) Read access to an existing hybrid configuration
Description: A tenant that already has (or a lab that can host) Entra Connect Sync or Cloud Sync and,
ideally, at least one synchronized user and one hybrid-joined device to inspect.
Why required: The health-check and inspection labs are richest against a real hybrid setup; you learn to
read source anchor, sync errors, and hybrid-join state from live data.
How to verify: Entra → **Identity → Hybrid management → Microsoft Entra Connect** shows sync status and
last sync time; Entra → **Devices** shows any *Microsoft Entra hybrid joined* devices.
How to implement if missing: If no hybrid environment exists, complete the inspection labs
conceptually using the provided sample output, then use HYBID to stand one up. A disposable lab forest
+ Entra Connect is ideal for full hands-on practice.

## R3. Microsoft Graph PowerShell SDK
Description: The `Microsoft.Graph` PowerShell module (v2+) on the operator workstation.
Why required: The discovery, validation, report, and health-check helpers use Graph cmdlets.
How to verify: `Get-Module Microsoft.Graph -ListAvailable` returns v2+; `EKHYBID-Validate.ps1` reports it.
How to implement if missing: `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to the
least-privilege read scopes (e.g. `Directory.Read.All`, `Domain.Read.All`, `AuditLog.Read.All`,
`Organization.Read.All`).

## R4. (For full hands-on) The on-premises AD PowerShell module (RSAT)
Description: RSAT Active Directory PowerShell tools on a domain-joined workstation or the Connect host.
Why required: The source-anchor, sync-scope, and UPN-hygiene inspection labs read AD attributes
(`ms-DS-ConsistencyGuid`, UPN suffixes, OU structure) directly.
How to verify: `Get-Module ActiveDirectory -ListAvailable` returns a module; `Get-ADForest` succeeds.
How to implement if missing: Install RSAT AD tools (**Optional Features** on Windows client, or
`Install-WindowsFeature RSAT-AD-PowerShell` on Server). Skip the AD-side labs if no AD is available and
complete them conceptually.

## R5. Licensing awareness (P1 / P2 / Governance / GSA)
Description: Awareness of which lab needs which license before you run it.
Why required: **Hybrid Conditional Access** requires **Entra ID P1**; risk-based CA and PIM require
**P2**; governance features require **Entra ID Governance**. Some capabilities are preview. *Do not
assume availability — verify current licensing and preview status in your own tenant.*
How to verify: M365 admin center → **Billing → Licenses**; `EKHYBID-Validate.ps1` reports detected
service plans.
How to implement if missing: Assign the needed license to lab users, or complete that lab as
concept-only. Trial licenses are acceptable for training — *verify eligibility in your tenant.*

## R6. (Optional) Log Analytics / Microsoft Sentinel with Entra diagnostic settings
Description: An Entra **Diagnostic setting** streaming `SignInLogs` / `AuditLogs` to a Log Analytics
workspace (optionally onboarded to Sentinel).
Why required: Only for the **KQL analysis lab** and `EKHYBID-Signals.kql`. The rest of the kit works
without it.
How to verify: Entra → **Monitoring → Diagnostic settings** shows a setting sending logs to a workspace
with recent `SigninLogs`.
How to implement if missing: Entra → **Diagnostic settings → Add** → select `SignInLogs`, `AuditLogs`
→ send to a workspace. *A workspace and retention may incur Azure cost — verify in your subscription.*
If unavailable, read the KQL lab as concept only.


---


# Global Requirements — Entra ID Solutions (category-level)

These requirements apply to every solution in the Entra ID Solutions category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying any identity solution. Each entry: Description / Why / Verify / Implement-if-missing.

> The identity plane is high risk. A mistake here breaks sign-in for everyone, so every change is
> staged and a break-glass account is kept ready before you touch anything.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID tenant.
Why: It is the cloud identity backbone every other identity service builds on.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 or Azure subscription, which provisions a tenant.

## G2. Entra ID licensing (P1, P2 where noted)
Description: Microsoft Entra ID P1 (or P2 for risk-based and PIM features).
Why: Hybrid features such as seamless sign-in, password writeback, and Conditional Access require P1+.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2 (often bundled in M365 E3/E5 or EMS).
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## G3. Administrative roles
Description: Hybrid Identity Administrator and Global Administrator for the operator.
Why: Configuring directory synchronization and authentication methods needs these elevated roles.
Verify: Entra -> `Roles and administrators`; confirm `Hybrid Identity Administrator` (and a Global Administrator for the one-time first-sync consent).
Implement: Assign `Hybrid Identity Administrator`; reserve `Global Administrator` for tenant-wide and first-sync changes.

## G4. Break-glass (emergency access) accounts
Description: At least two cloud-only emergency access accounts, excluded from Conditional Access and MFA-broad policies.
Why: If sync, federation, or an auth-method change locks out admins, break-glass accounts get you back in.
Verify: Entra -> `Users`; confirm two cloud-only accounts (`@onmicrosoft.com`) with strong stored credentials and documented use.
Implement: Create two cloud-only Global Administrator accounts; exclude them from policies; store credentials securely and monitor sign-ins.

## G5. Healthy on-premises Active Directory
Description: A functional AD forest/domain with healthy replication and DNS.
Why: Synchronization reads from AD; replication or DNS faults corrupt or stall the sync.
Verify: Run `dcdiag` and `repadmin /replsummary` on a domain controller with no errors; run `HYBID-Discovery.ps1`.
Implement: Resolve AD replication, DNS, and time-sync issues before synchronizing.

## G6. An Entra Connect host server
Description: A domain-joined Windows Server (2016+), patched, for Microsoft Entra Connect Sync (or a lightweight host with the Cloud Sync agent).
Why: Connect Sync runs as a service on this host and must reach both AD and Entra ID.
Verify: A supported, domain-joined server with TLS 1.2, .NET, and PowerShell available; run `HYBID-Discovery.ps1`.
Implement: Provision a dedicated server (not a domain controller for production), patch it, and enable TLS 1.2.

## G7. UPN / domain hygiene
Description: User principal names use a public, verified, routable domain (not `.local`).
Why: A non-routable UPN suffix produces sign-in problems and `onmicrosoft.com` fallbacks in the cloud.
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; AD UPN suffixes match it; run `HYBID-Discovery.ps1`.
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD and update user UPNs.

## G8. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS (443) from the Connect host to Entra ID, plus required Microsoft 365 service URLs.
Why: Synchronization, authentication-agent traffic, and tokens depend on these endpoints.
Verify: From the Connect host, reach `https://login.microsoftonline.com` and the Microsoft 365 published URL/IP ranges.
Implement: Allow the Microsoft 365 / Entra service URLs and IP ranges through the proxy/firewall.

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation (Guided Labs) — Self-Deploy: Microsoft Entra Hybrid Identity

This is the hands-on core of the kit. Work the labs **in order**; each maps to a stage of the
deployment model (**Assess → Configure → Pilot → Validate → Expand**). The labs are **read-only /
inspection-first** — you inspect and rehearse against a real (or lab) hybrid environment without
changing a production sync configuration. Where a lab references a change (converting an auth method,
changing sync scope, enabling hybrid join), it is taught as a **pattern** to execute in the **HYBID
implementation solution**, not applied here.

Any object you *do* create for practice uses the naming convention **`<Purpose> – <Scope> – <Stage>`**
and is reused by name later. Portal paths are current at authoring time — *verify the current
navigation in your tenant.*

---

## Lab 0 — Baseline the hybrid estate (Assess)

**Goal:** capture the current hybrid configuration read-only.

1. Confirm the category prerequisites (global requirements) and that you have **Global Reader**.
2. Run the read-only discovery:
   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser   # if needed
   .\EKHYBID-Discovery.ps1
   ```
   Read the output: sync engine in use, directory-sync enabled, last sync time, federated vs managed
   domains, on-premises sync status, and UPN-hygiene flags.
3. Validate the lab prerequisites:
   ```powershell
   .\EKHYBID-Validate.ps1
   ```
   Confirm: Graph module OK, read role sufficient, AD module present (if doing AD-side labs), licensing
   detected. Resolve any FAIL before continuing.

**Gate:** a complete read-only baseline of the hybrid estate is captured.

---

## Lab 1 — Choose the engine: Entra Connect Sync vs Cloud Sync

**Goal:** understand and defend an engine choice for a given scenario.

1. Entra → **Identity → Hybrid management → Microsoft Entra Connect**. Note whether **Connect Sync** or
   **Cloud Sync** (or both) is present, and the last sync time.
2. Work the decision matrix (record answers in the runbook):
   - Do you need **device writeback / password writeback / hybrid join with writeback** or complex
     multi-forest filtering? → **Connect Sync**.
   - Simple, disconnected small forests / multiple small domains, minimal advanced options? → **Cloud
     Sync**.
3. Inspect Cloud Sync (if present): Entra → **Hybrid management → Microsoft Entra Connect → Cloud
   sync** → open the configuration and review scope and status (read-only).

**Gate:** the team can state, for their environment, which engine fits and why. Production change →
**HYBID** (Connect Sync) or the **Cloud Sync provisioning** solution.

---

## Lab 2 — Sync scope, source anchor, and UPN hygiene (the three quiet killers)

**Goal:** read the settings that cause most hybrid failures, and learn what "good" looks like.

1. **Sync scope:** in Connect Sync's configuration (or `EKHYBID-Discovery.ps1` output), identify the
   **OU / domain filters** — which AD objects are in scope. Confirm test/service OUs are excluded.
2. **Source anchor:** confirm the source anchor is **`ms-DS-ConsistencyGuid`** (the modern default),
   not `objectGUID`. On a domain-joined workstation with RSAT:
   ```powershell
   Get-ADUser -Filter * -Properties mS-DS-ConsistencyGuid |
     Select-Object -First 20 SamAccountName, mS-DS-ConsistencyGuid
   ```
   Understand why a wrong/mismatched anchor produces duplicate or orphaned cloud objects and hard
   re-joins. (Deep remediation → the **Entra Connect source-anchor / ConsistencyGuid** solution.)
3. **UPN hygiene:** Entra → **Identity → Settings → Domain names** — confirm the public domain is
   **Verified**. On-premises, confirm AD UPN suffixes match it (no `.local`):
   ```powershell
   (Get-ADForest).UPNSuffixes ; (Get-ADDomain).DNSRoot
   Get-ADUser -Filter 'UserPrincipalName -like "*.local"' | Measure-Object   # should be 0
   ```

**Gate:** the team can read sync scope, verify the source anchor, and spot a `.local`/mismatched UPN.

---

## Lab 3 — Authentication method trade-offs and the staged-rollout move

**Goal:** understand PHS / PTA / Federation and rehearse the safe way to change method.

1. Identify the **current** method: Entra → **Identity → Hybrid management → Microsoft Entra Connect**
   (or `EKHYBID-Discovery.ps1` reports federated domains; PTA agents show under **Connect → Pass-through
   authentication**).
2. Work the trade-offs (record in the runbook):
   - **PHS** — simplest, most resilient, cloud survives on-prem outage; recommended default + backup.
   - **PTA** — real-time validation against AD, no password hash leaves the network, but depends on
     agent/AD availability.
   - **Federation (AD FS)** — most complex/highest-maintenance; keep only for a hard requirement, plan
     to migrate away.
3. Rehearse the **safe change pattern** (do **not** execute against production in the kit):
   - Enable **PHS** as a backup first.
   - Use **staged rollout** to move a small pilot group from federation → cloud auth (PHS/PTA) and
     validate their sign-in *before* converting the domain.
   - Convert the domain **Federated → Managed** only after the staged group validates.
   - The rollback point is the staged group / unconverted domain. Execute for real in **HYBID**.

**Gate:** the team can choose a method and sequence a federation→cloud migration with its rollback point.

---

## Lab 4 — Hybrid Entra join (concept + inspection)

**Goal:** understand hybrid join and read the current device state.

1. Entra → **Devices → All devices**. Filter **Join type = Microsoft Entra hybrid joined**. Note counts
   and any *Pending* devices.
2. Understand the hybrid-join flow: Connect Sync (or the SCP configuration) advertises the tenant to
   domain-joined Windows devices → devices register into Entra ID → they can then satisfy Conditional
   Access and cloud device management.
3. On a domain-joined test device, inspect the join state read-only:
   ```cmd
   dsregcmd /status
   ```
   Read `AzureAdJoined`, `DomainJoined`, `AzureAdPrt`. (Enabling hybrid join for the fleet → **HYBID**.)

**Gate:** the team can read hybrid-join state per device and explain the registration flow.

---

## Lab 5 — Hybrid Conditional Access (report-only)

**Goal:** tie the on-premises device estate to cloud access decisions, safely. Requires Entra ID P1 —
*verify.*

1. Create a lab pilot group named **`Hybrid Identity – Pilot – Lab`** (Entra → **Groups → New group**,
   Security) containing only test users/devices.
2. Entra → **Protection → Conditional Access → + New policy** → name **`CA – Hybrid Pilot – Require
   Compliant/Hybrid Device (Report-only)`** → Users = the pilot group (exclude break-glass) → Target
   resources = All cloud apps → Grant = **Require device to be marked as compliant** *or* **Require
   Microsoft Entra hybrid joined device** → **Enable policy = Report-only** → **Create**.
3. Leave it **report-only**. You will read its impact in the Testing guide via the report-only workbook.

**Gate:** a report-only hybrid-device CA policy exists, scoped to the pilot group, break-glass excluded.
Production CA → **Zero Trust Conditional Access baseline (ENTZTCA)**.

---

## Lab 6 — Health-check lab

**Goal:** build the routine that catches a drifting hybrid setup before users do.

1. Run the read-only health check:
   ```powershell
   .\EKHYBID-HealthCheck.ps1
   ```
   Review: directory-sync enabled, **last sync time** within the expected window (default sync is every
   ~30 min), on-premises sync status, federated-domain count, PTA/Seamless SSO hints, and any UPN issues.
2. Interpret each signal (record thresholds in the runbook), for example:
   - Last sync older than ~2 hours → investigate the Connect host / Cloud Sync agent.
   - Federated domains present but a cloud-auth strategy intended → note the migration action.
   - `.local` UPNs > 0 → UPN hygiene remediation needed.
3. (Optional, if a Connect host is available and you have local read access) inspect Connect Sync
   status read-only in PowerShell on the host:
   ```powershell
   Import-Module ADSync ; Get-ADSyncScheduler ; (Get-ADSyncConnectorRunStatus)
   ```

**Gate:** the team can run and interpret the health check and knows the thresholds that trigger action.

---

## Lab 7 — Score and (optionally) analyze sign-in signals

**Goal:** produce a shareable hybrid-health scorecard and analyze hybrid sign-ins.

1. Generate the scorecard:
   ```powershell
   .\EKHYBID-Report.ps1 -OutputPath .\EKHYBID-Scorecard
   ```
   This writes CSV + HTML summarizing engine, sync health, auth method, federated domains, UPN hygiene,
   and hybrid-join coverage.
2. (Optional) If Log Analytics / Sentinel is available, run queries from **`EKHYBID-Signals.kql`** —
   sign-ins by authentication method (PHS/PTA/federation), hybrid-join device sign-ins, and sync-related
   sign-in errors.

**Gate:** a scorecard is produced and the team can prioritize the next real hybrid action.

---

## Wrap-up
- Complete the **knowledge-check** and finalize the **take-home runbook** (both in `05-testing.md`).
- Tear down any practice objects you created (the `Hybrid Identity – Pilot – Lab` group and its
  report-only policy) when finished.
- For production build-out of anything rehearsed here, proceed to **HYBID** (Hybrid Identity with AD &
  Entra Connect).


---


# 5. Testing, Knowledge-Check & Take-Home Runbook — Self-Deploy: Microsoft Entra Hybrid Identity

Because this is an self-deploy, "testing" means **validating the labs worked** and **confirming the
team learned** (a knowledge-check). This guide also assembles the **take-home hybrid-identity runbook**.
Reference the scripts by name throughout.

## Part A — Lab validation procedures

### V1. Baseline & prerequisites (Lab 0)
- Run `EKHYBID-Validate.ps1`. **Pass:** Graph module OK, read role sufficient, AD module present (if
  doing AD-side labs), licensing detected — no FAILs.
- Run `EKHYBID-Discovery.ps1`. **Pass:** a baseline prints (engine, sync enabled, last sync time,
  federated/managed domains, UPN flags) with no script errors.

### V2. Engine, anchor, UPN (Labs 1–2)
- The team can point to the sync engine in the portal and state the correct choice for the scenario.
- **Source anchor:** confirmed as `ms-DS-ConsistencyGuid` (or the gap is noted). **UPN hygiene:** the
  `.local` UPN count is **0** (or remediation is noted). **Pass:** all three inspected and recorded.

### V3. Authentication method (Lab 3)
- The team can name the current method and describe the staged-rollout federation→cloud sequence and
  its rollback point. **Pass:** the sequence is written into the runbook correctly.

### V4. Hybrid join + hybrid CA (Labs 4–5)
- Entra → **Devices** shows hybrid-joined device counts; `dsregcmd /status` on a test device is read
  correctly. **Pass:** join state interpreted.
- Entra → **Conditional Access → Policies**; confirm `CA – Hybrid Pilot – Require Compliant/Hybrid
  Device (Report-only)` is **Report-only**, scoped to `Hybrid Identity – Pilot – Lab`, break-glass
  excluded. Sign in as a pilot user, then check **Conditional Access → Insights and reporting
  (report-only workbook)**. **Pass:** the sign-in shows the report-only result *before* any enforcement.

### V5. Health check + scorecard (Labs 6–7)
- Run `EKHYBID-HealthCheck.ps1`. **Pass:** every signal is returned and the team can interpret each
  (last sync time within window, federated-domain count, UPN issues, PTA/SSO hints).
- Run `EKHYBID-Report.ps1 -OutputPath .\EKHYBID-Scorecard`. **Pass:** CSV + HTML produced and open
  cleanly.
- (Optional) Run two or three queries from `EKHYBID-Signals.kql`. **Pass:** queries run without syntax
  errors and return rows (or a clean empty result).

## Part B — Knowledge-check (the team should be able to answer)
1. When do you choose **Entra Connect Sync** over **Entra Cloud Sync**, and vice versa?
2. What is the **source anchor**, which attribute is the modern default, and what goes wrong if it is
   mismatched?
3. Why must UPNs use a **verified, routable** domain? What is the symptom of a `.local` UPN in the cloud?
4. Compare **PHS**, **PTA**, and **Federation** on resilience, security, and maintenance. Why is PHS
   recommended as a **backup** even when another method is primary?
5. Lay out the safe, staged sequence to move a **federated** domain to **cloud authentication**, and
   name the rollback point.
6. Explain **hybrid Entra join**: what advertises the tenant, how a device registers, and what
   `dsregcmd /status` fields you check.
7. What does a healthy hybrid setup look like on the **health check** (last sync time, sync errors,
   federated domains, UPN issues), and what thresholds trigger action?

*(Suggested pass mark: the team answers 6 of 7 without notes.)*

## Part C — Take-home hybrid-identity runbook (fill in during the kit)
Assemble a runbook the team keeps. Capture, for your environment:

- **Baseline** — the `EKHYBID-Discovery.ps1` and `EKHYBID-Report.ps1` output (dated).
- **Engine** — Connect Sync vs Cloud Sync, the host(s), and why.
- **Sync scope** — which OUs/domains are in scope; what is deliberately excluded.
- **Source anchor** — confirmed attribute and any consolidation action needed.
- **UPN hygiene** — verified domain(s), UPN suffix state, and any `.local` remediation.
- **Authentication method** — current method, target method, and the staged-rollout plan with rollback.
- **Hybrid join** — coverage, pending devices, and the enablement plan.
- **Hybrid Conditional Access** — the report-only policy and its ring plan to enforcement.
- **Health-check routine** — the signals, thresholds, and cadence (who runs `EKHYBID-HealthCheck.ps1`
  and how often).
- **Hand-offs** — HYBID for build-out; the source-anchor and Cloud Sync troubleshooting solutions for
  deep fixes; ENTZTCA for the CA baseline; EKIDMOD for the broader modernization journey.

A completed runbook + a passed knowledge-check = the kit's success criteria.


---


# 6. Troubleshooting — Self-Deploy: Microsoft Entra Hybrid Identity

Common failures while working the labs, as **symptom → cause → fix**. These are lab / inspection issues;
production hybrid troubleshooting lives in the **HYBID** implementation solution and the dedicated
source-anchor and Cloud Sync troubleshooting solutions.

## Scripts

### `Connect-MgGraph` fails or prompts endlessly
- **Symptom:** the discovery/validation/report/health-check scripts cannot connect to Graph.
- **Cause:** the `Microsoft.Graph` module is missing/old, or consent to the read scopes was declined.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and **accept** the requested read
  scopes (e.g. `Directory.Read.All`, `Domain.Read.All`, `Organization.Read.All`, `AuditLog.Read.All`).
  Confirm with `Get-MgContext`.

### "Insufficient privileges" on a read script
- **Symptom:** cmdlets return authorization errors.
- **Cause:** the operator lacks a directory-read role, or a scope needs admin consent.
- **Fix:** sign in as **Global Reader** (or higher read); have a Global Administrator consent once to
  any scope requiring admin consent.

### `EKHYBID-Discovery.ps1` shows no sync engine / last sync time
- **Symptom:** engine and last-sync fields are blank.
- **Cause:** the tenant has no hybrid sync configured, or `onPremisesSyncEnabled` is false, or the
  operator cannot read organization sync properties.
- **Fix:** this is expected in a cloud-only tenant — complete Labs 1–2 conceptually. If a hybrid setup
  exists, confirm the read role and that Entra → **Hybrid management → Microsoft Entra Connect** shows
  sync status.

### AD-side commands fail (`Get-ADUser`, `Get-ADForest`)
- **Symptom:** the source-anchor / UPN-hygiene inspection commands error.
- **Cause:** the RSAT ActiveDirectory module is not installed, or you are not on a domain-joined host.
- **Fix:** install RSAT AD tools and run from a domain-joined workstation or the Connect host; or skip
  the AD-side inspection and complete those labs conceptually.

## Sync / health-check labs

### Health check reports the last sync time is very old
- **Symptom:** `EKHYBID-HealthCheck.ps1` flags last sync older than the expected window.
- **Cause:** the Connect Sync scheduler is disabled/stopped, the Connect host is offline, or the Cloud
  Sync agent is unhealthy.
- **Fix (inspection):** on the Connect host, read status only — `Get-ADSyncScheduler`,
  `Get-ADSyncConnectorRunStatus`. For an actual restart/repair, follow **HYBID** (do not change
  production sync from the kit).

### Federated domains appear where cloud auth was expected
- **Symptom:** discovery lists a domain as **Federated**.
- **Cause:** the domain still uses AD FS.
- **Fix:** this is a finding, not an error — record the federation→cloud migration action in the runbook
  and execute it (staged rollout) in **HYBID**.

### UPN-hygiene flag: `.local` UPNs present
- **Symptom:** discovery/health check reports non-routable UPNs.
- **Cause:** AD UPN suffixes use a non-routable domain (e.g. `.local`).
- **Fix (plan):** add and verify a public domain in Entra, add the matching UPN suffix in AD, and update
  user UPNs — executed in **HYBID**; the kit only surfaces the finding.

## Hybrid join / Conditional Access labs

### `dsregcmd /status` shows the device is not hybrid joined
- **Symptom:** `AzureAdJoined : NO` on a domain-joined test device.
- **Cause:** hybrid join is not configured/advertised, the device has not completed registration, or the
  SCP is missing.
- **Fix (inspection):** read `DomainJoined`, `AzureAdPrt`, and any error in the output; understand the
  cause. Enabling hybrid join for the fleet is a **HYBID** task.

### The report-only hybrid-device CA policy shows no impact
- **Symptom:** the report-only workbook shows nothing for `CA – Hybrid Pilot – Require Compliant/Hybrid
  Device (Report-only)`.
- **Cause:** no pilot user has signed in since creation, or the pilot group scope is wrong.
- **Fix:** sign in as a pilot lab user, wait a few minutes, then re-check **Conditional Access →
  Insights and reporting**. Confirm `Hybrid Identity – Pilot – Lab` is included and break-glass excluded.

### CA blades / device conditions unavailable
- **Symptom:** Conditional Access or the device-grant options are greyed out.
- **Cause:** the tenant lacks **Entra ID P1**.
- **Fix:** assign P1 to lab users or complete Lab 5 as concept-only. *Verify current licensing in your
  tenant.*

## KQL lab

### KQL queries error on table not found or return nothing
- **Symptom:** `SigninLogs` is unknown or results are empty.
- **Cause:** Entra diagnostic settings are not exporting logs to the workspace, the time range predates
  collection, or you are querying the wrong workspace.
- **Fix:** configure Entra → **Diagnostic settings** to send `SignInLogs`/`AuditLogs` to the workspace;
  widen the time range; confirm the correct workspace. Column/table names evolve — *verify the current
  schema in your tenant.*


---


# 7. Best Practices & Where to Go Next — Self-Deploy: Microsoft Entra Hybrid Identity

## Running the kit cleanly
- **Inspect, don't change.** This kit is read-only / inspection-first. Do not alter a production sync
  scope, source anchor, or authentication method while training — rehearse the pattern and execute for
  real in the **HYBID** implementation solution.
- **Break-glass first.** Confirm two excluded emergency-access accounts before you build even a
  report-only policy, and confirm they are excluded from every lab policy.
- **Pilot-scope any practice object.** If you create the `Hybrid Identity – Pilot – Lab` group and its
  report-only CA policy, scope only test users/devices, and tear them down when done.
- **Least-privilege reads.** Use a **Global Reader** operator and consent only to the read scopes the
  scripts request.
- **Use a lab forest for full hands-on.** A disposable AD forest + Entra Connect lets the team practice
  the AD-side labs (source anchor, sync scope) without any production risk.

## Hybrid-identity principles the team should carry forward
- **PHS as the resilient default and backup.** Prefer Password Hash Sync; keep it enabled as a backup
  even when PTA or federation is primary, so cloud sign-in survives an on-premises outage.
- **Modern source anchor.** Standardize on `ms-DS-ConsistencyGuid` to survive domain migrations and
  avoid duplicate/orphaned objects.
- **UPN hygiene is a prerequisite, not an afterthought.** Verified, routable UPNs before you sync;
  never `.local`.
- **Scope deliberately.** Sync only the OUs/domains you mean to; keep test and service objects out of
  the cloud.
- **Change auth methods with staged rollout.** Move a pilot group first, validate sign-in, then convert
  the domain — with a clear rollback point.
- **One active sync server; a staging server for failover.** Rehearse with staging mode before any real
  cutover (in HYBID).
- **Monitor continuously.** Run the health check on a cadence; last-sync time, sync errors, federated
  domains, and UPN issues are the early-warning signals.
- **Defer the decisions that are not yours.** Regulatory, records, legal, and data-classification
  determinations, and production change-approval sign-off, belong to the customer's compliance /
  security / operations functions — the kit supplies technical understanding and read-only tooling, not
  those decisions.

## Where to go next (adjacent catalog areas)
- **Production hybrid build-out** → *Hybrid Identity with AD & Entra Connect* (HYBID) — the
  implementation companion to this kit.
- **Source-anchor / duplicate-object remediation** → *Entra Connect source-anchor / ConsistencyGuid /
  domain consolidation*.
- **Cloud Sync provisioning problems** → *Entra Cloud Sync users-not-provisioning troubleshooting*.
- **Conditional Access baseline** → *Zero Trust Conditional Access baseline* (ENTZTCA) — for the CA side
  of hybrid CA.
- **The broader modernization journey** → *Self-Deploy — Identity Modernization with Entra*
  (EKIDMOD).
- **Governance & privileged access** → *Entra ID Governance — PIM & Access Reviews* (ENTPIM / ENTIGA).

Continue the enablement track with the other Entra self-deploys (Identity Fundamentals, MFA &
Conditional Access, Identity Modernization) to round out the team's coverage.


---


# 8. Deliverables Summary — Self-Deploy: Microsoft Entra Hybrid Identity

## Documentation (source guides)
1. **executive-summary.md** — what the kit is, how it differs from the HYBID implementation product,
   the training outcome, and the effort.
2. **01-solution-overview.md** — concepts: hybrid identity, Connect Sync vs Cloud Sync, sync scope,
   source anchor, UPN hygiene, PHS/PTA/federation, hybrid join and hybrid CA, scope, out-of-scope, and
   the deployment model.
3. **02-requirements.md** — enablement-specific prerequisites (read-only vantage point, hybrid
   environment to inspect, Graph SDK, RSAT AD module, licensing awareness, optional Log Analytics) with
   verify / implement-if-missing. Category-level prerequisites are in
   `global-requirements-entra-id-solutions.md`.
4. **03-implementation.md** — the guided, read-only / inspection-first labs (0–7): engine choice; sync
   scope / source anchor / UPN hygiene; authentication-method trade-offs and the staged-rollout move;
   hybrid join; hybrid Conditional Access (report-only); the health-check lab; and scoring.
5. **05-testing.md** — lab-validation procedures, the knowledge-check, and the take-home runbook.
6. **06-troubleshooting.md** — symptom → cause → fix for the common lab failures.
7. **07-best-practices.md** — clean-lab guidance, hybrid-identity principles, and where to go next.
8. **08-deliverables-summary.md** — this file.

Plus the category file **global-requirements-entra-id-solutions.md** (shared prerequisites).

## Scripts / lab helpers (5)
1. **EKHYBID-Discovery.ps1** — read-only baseline of the hybrid estate (directory-sync state, last sync
   time, sync engine hint, federated vs managed domains, UPN-hygiene flags).
2. **EKHYBID-Validate.ps1** — read-only check that the lab prerequisites are met (Graph module, read
   role, AD module presence, detected licensing).
3. **EKHYBID-Report.ps1** — hybrid-health scorecard exported to CSV + HTML (engine, sync health, auth
   method, federated domains, UPN hygiene, hybrid-join coverage).
4. **EKHYBID-HealthCheck.ps1** — read-only hybrid health-check (sync enabled, last sync within window,
   federated-domain count, PTA/Seamless SSO hints, UPN issues) — the routine from the health-check lab.
5. **EKHYBID-Signals.kql** — KQL query pack for Log Analytics / Microsoft Sentinel (sign-ins by
   authentication method, hybrid-join device sign-ins, sync-related sign-in errors).

All scripts are white-label and **read-only**.

## How it is delivered
Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the guides as a Word document and
PDF, plus all five lab helpers, in a single ZIP the team keeps and reuses.
