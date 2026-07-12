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
