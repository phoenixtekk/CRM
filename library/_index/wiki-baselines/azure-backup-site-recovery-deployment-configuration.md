# Azure Backup & Site Recovery — Deployment & Configuration

> **Version 1.0.0** · Category: Backup & DR Solutions · Solution code: BCKDR

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Azure Backup & Site Recovery — Deployment & Configuration

## The problem

Hoping your VMs are backed up is not a disaster-recovery strategy. Many Azure estates run
with no Recovery Services vault at all, with backup enabled on some VMs but not others, with
policies that were set once and never revisited, and with **no** cross-region replication for
the workloads that would actually take the business down if a region or a resource group were
lost. When an accidental deletion, a ransomware event, or a regional outage happens, the team
discovers — during the incident — that the data was never protected, that a "backup" was really
just a mutable snapshot an attacker could delete, or that there is no tested way to bring the
application back up somewhere else.

Two failure modes are especially common:

- **Backup exists but is not immutable or soft-delete-protected.** A backup an administrator (or
  an attacker with administrator rights) can silently delete is not a ransomware control. Soft
  delete and immutability turn a backup vault into a last line of defense that survives credential
  compromise.
- **There is backup but no *recovery*.** Restoring a single file is not the same as failing an
  application tier over to another region in sequence, with the database up before the app servers,
  DNS repointed, and post-failover scripts run. Without **Azure Site Recovery** replication and a
  tested **recovery plan**, "DR" is an aspiration, not a capability.

## The solution

This solution **deploys and configures** Azure Backup and Azure Site Recovery end to end:

- **Recovery Services and Backup vaults** hardened with **soft delete** and **immutability**.
- **Backup policies** for **Azure VMs, Azure Files, SQL Server running in Azure VMs, and Azure
  Blob storage**, assigned to the in-scope estate.
- **Azure Site Recovery** replication — **Azure-to-Azure** (region to region) and
  **on-premises-to-Azure** — with a replication policy meeting the target RPO.
- **Recovery plans** with tiered sequencing, pre/post scripts, and a **non-disruptive test
  failover**, plus **alerting** and a written **restore/failover runbook**.

It follows a consistent deployment model — **Assess → Configure → Pilot → Validate → Expand** —
so that protection is proven on a pilot before it is rolled out across the estate, and every
object created is named to a convention and reused verbatim in the scripts and runbook.

> **Scope boundary.** This solution *deploys and configures* Azure Backup and ASR. The ongoing
> discipline of *scheduling and evidencing test restores* across the estate is a separate program —
> see **Backup Validation & Recoverability Assurance** in this catalog. This solution proves the
> deployment works once (via test failover and a first restore); that program keeps proving it.

## What you get

- A hardened vault design with **soft delete + immutability** for Recovery Services and Backup
  vaults.
- **Backup policies** for VMs, Files, SQL-in-VM, and blobs, applied pilot-first then estate-wide.
- **ASR replication** (Azure-to-Azure and on-prem-to-Azure) with a policy meeting the agreed RPO.
- **Recovery plans** with sequencing, scripts, and a proven **test failover**.
- **Alerting** on backup/replication health and a **restore/failover runbook**.
- **Five automation artifacts** — a read-only discovery script, a Bicep template that provisions
  the hardened vaults and policies, a gated protection-enablement script, a read-only validation
  script (with an optional non-disruptive test failover), and a read-only reporting script.

## Business outcomes

- **Provable protection** — workloads are backed up under policy, in immutable, soft-delete
  vaults, with defined RPO/RTO rather than assumed coverage.
- **Real recoverability** — replication plus a tested recovery plan means an application tier can
  actually be brought up in another region, in order, on demand.
- **Ransomware resilience** — immutability and soft delete keep recovery points intact even if an
  administrator account is compromised.
- **Operational readiness** — alerting and a written runbook mean the team executes a rehearsed
  procedure during an incident, not an improvised one.

> **Your decision, not ours.** RPO/RTO targets are a business decision the customer owns — this
> solution implements the technical controls to *meet* the targets you set, and flags where a
> desired RPO/RTO is or is not achievable with the chosen configuration.

## Effort

A typical engagement is a **1–3 week** deployment: assessment and vault design in week 1, pilot
configuration and a first test failover in week 2, and estate-wide expansion plus alerting and
runbook handover in week 3. Delivered as a **Complete Solution Package** (PDF + Word + scripts).


---


# 1. Solution Overview — Azure Backup & Site Recovery — Deployment & Configuration

## Description

This solution **deploys and configures** the two Azure services that together make workloads
provably recoverable:

- **Azure Backup** — periodic, application-consistent recovery points for **Azure VMs**, **Azure
  Files**, **SQL Server running inside Azure VMs**, and **Azure Blob storage**, stored in a
  **Recovery Services vault** (VM/Files/SQL) and a **Backup vault** (blobs and newer workloads),
  hardened with **soft delete** and **immutability**.
- **Azure Site Recovery (ASR)** — continuous **replication** of running workloads to a secondary
  region (**Azure-to-Azure**) or from on-premises into Azure (**on-premises-to-Azure**), organized
  into **recovery plans** that fail workloads over in a defined **sequence**, run **pre/post
  scripts**, and can be exercised with a **non-disruptive test failover**.

The result is a backup and DR platform where every in-scope workload is protected under a named
policy, recovery points cannot be silently destroyed, and a full application tier can be brought
up in another region on demand — with the RPO/RTO the business agreed to.

## How the technology works

- **Recovery Services vault** is the classic Azure Backup / ASR vault. It holds backup items for
  Azure VMs, Azure Files, and SQL-in-VM, and it is also the vault type that ASR uses for
  replication. **Soft delete** retains deleted backup data for a recovery window (default 14 days,
  configurable up to 180) so deletions can be reversed; **immutability** (a vault-level setting,
  optionally **locked**) prevents recovery points from being deleted or shortened before their
  retention expires.
- **Backup vault** is the newer vault type used for **Azure Blob** backup, Azure Disks, and
  PostgreSQL flexible server. It supports its own **soft delete** and **immutability** settings.
  Blob backup comes in two shapes: **operational** (continuous, local, point-in-time restore) and
  **vaulted** (periodic copies retained in the vault).
- **Backup policy** defines schedule (frequency), retention (daily/weekly/monthly/yearly points),
  and — for SQL-in-VM — **log backup** frequency that sets the effective RPO. A policy is authored
  once and assigned to many items.
- **ASR replication** installs the **Mobility service** on each protected machine, continuously
  ships changes to the target region/vault, and maintains recovery points per the **replication
  policy** (RPO target, recovery-point retention, app-consistent snapshot frequency).
- **Recovery plan** groups replicated items into ordered **groups** (e.g. Group 1 = database,
  Group 2 = app, Group 3 = web) with **pre/post-action scripts or manual steps**, so a failover
  reconstitutes an application in the correct order. **Test failover** runs the plan into an
  isolated network **without** affecting the running production workload.

## Deployment model — Assess → Configure → Pilot → Validate → Expand

Every solution in this catalog follows the same five-stage model so repeat buyers recognize the
pattern:

1. **Assess** — inventory the estate (VMs, Files, SQL-in-VM, storage/blobs, on-prem servers),
   determine what is protected today, and design the vault topology and target regions.
2. **Configure** — deploy the hardened vaults (soft delete + immutability) and the backup and
   replication policies via Bicep, plan/what-if first.
3. **Pilot** — enable backup and replication on a small representative set, and run a **test
   failover** of a pilot recovery plan.
4. **Validate** — confirm vault hardening, policy coverage, replication health, first successful
   restore, and that the test failover met RTO; measure achieved RPO against target.
5. **Expand** — roll protection out across the estate, wire up alerting, and hand over the
   restore/failover runbook.

## Named objects

This solution creates a defined set of objects. Each name is used **verbatim** in the
implementation steps, the scripts, and the runbook. Adjust the placeholder region/scope tokens to
your environment but keep the convention `<Purpose> – <Scope> – <Stage>`.

| Object | Azure resource name (placeholder) | Purpose |
|---|---|---|
| **Recovery Services Vault – Core – Configure** | `rsv-backup-core-prod` | VM/Files/SQL backup + ASR |
| **Backup Vault – Object – Configure** | `bvault-backup-object-prod` | Blob (and disk) backup |
| **VM Backup Policy – Daily-30d – Configure** | `bkpol-vm-daily-30d` | Azure VM backup schedule/retention |
| **Files Backup Policy – Daily-30d – Configure** | `bkpol-files-daily-30d` | Azure Files backup |
| **SQL Backup Policy – Log-15m – Configure** | `bkpol-sql-log15m` | SQL-in-VM full/diff/log backup |
| **Blob Backup Policy – Vaulted-30d – Configure** | `bkpol-blob-vaulted-30d` | Vaulted blob backup |
| **ASR Replication Policy – A2A-RPO – Configure** | `asrpol-a2a-core` | Azure-to-Azure replication policy |
| **Recovery Plan – Tier1 App – Pilot** | `rp-tier1-app` | Ordered failover plan for the pilot app |
| **DR Test Sandbox – Isolated – Validate** | `rg-dr-test-sandbox` | Isolated RG/VNet for test failover & test restore |
| **Backup & DR Alert Rule – Health – Expand** | `alert-backupdr-health` | Alerts on backup/replication failures |
| **Restore/Failover Runbook – Estate – Expand** | *(document)* | The operational recovery procedure |

## Scope

**In scope:**

- Recovery Services vault and Backup vault deployment with soft delete + immutability.
- Backup policies and protection enablement for **Azure VMs, Azure Files, SQL-in-VM, and blobs**.
- ASR replication for **Azure-to-Azure** and **on-premises-to-Azure** (Hyper-V/VMware/physical via
  the ASR configuration/process server or the modern appliance).
- Recovery plans with sequencing, scripts, and non-disruptive test failover.
- Backup/replication health **alerting** and a **restore/failover runbook**.
- One proving **test failover** and one proving **restore** to confirm the deployment works.

**Out of scope (deferred or covered elsewhere):**

- **Ongoing, scheduled test-restore evidence across the estate** — that is the
  **Backup Validation & Recoverability Assurance** program in this catalog. This solution proves
  recoverability *once* at deployment; that program proves it *continuously*.
- **The RPO/RTO targets themselves** — those are a business decision the customer owns
  (Requirement R1). This solution implements controls to meet them and flags feasibility.
- Microsoft 365 (Exchange/SharePoint/OneDrive/Teams) SaaS backup — that requires a third-party SaaS
  backup product, not Azure Backup.
- Backup of workloads Azure Backup does not natively cover (e.g. some PaaS databases) beyond those
  listed above — assess separately.

## Authentication and connections used

- **Azure portal** (`portal.azure.com`) for interactive configuration.
- **Az PowerShell** (`Az.Accounts`, `Az.RecoveryServices`, `Az.DataProtection`, `Az.Compute`,
  `Az.Storage`) for discovery, enablement, validation, and reporting.
- **Bicep / Azure Resource Manager** for declarative vault and policy deployment.
- **Azure RBAC** roles: **Backup Contributor** (configure backup), **Site Recovery Contributor**
  (configure ASR), **Reader** (discovery/validation), and **Owner/Contributor** on the target
  subscription for the initial Bicep deployment. Grant the least role that completes each task.


---


# 2. Requirements — Azure Backup & Site Recovery — Deployment & Configuration

The category-level prerequisites are defined once in
**`global-requirements-backup-dr-solutions.md`** (GR1–GR6: an administered subscription with
backup tooling, a non-production restore target, documented RPO/RTO, secure evidence storage,
change control, and a tooling host with connectivity). **Do not assume any of them are in place —
verify each before starting.** The requirements below are the **solution-specific** prerequisites
that layer on top of the global set for deploying Azure Backup and Azure Site Recovery.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing.**

---

## R1 — Agreed RPO/RTO targets per workload class (business decision)

**Description:** Written, stakeholder-agreed **Recovery Point Objective** and **Recovery Time
Objective** per workload class (e.g. Tier-1 app VMs, file servers, SQL databases, blob data).

**Why required:** Backup frequency, log-backup interval, replication policy, and recovery-plan
design are all derived from RPO/RTO. These targets are a **business decision the customer owns** —
this solution implements controls to meet them, it does not set them.

**How to verify:** Locate an approved document stating RPO and RTO per workload class (this is
GR3 applied to the specific workloads in scope here).

**How to implement if missing:** Facilitate a short workshop to agree targets per workload class,
record them in the solution baseline, and note where a desired target is not achievable with the
chosen tier of Azure Backup/ASR (flagged during the Configure stage).

---

## R2 — A secondary (target) Azure region for ASR

**Description:** A chosen **target region** to replicate to (Azure-to-Azure), or a target region
and landing resources for on-premises-to-Azure replication. The region must be a supported ASR
pair for the source region and must have sufficient quota for the failed-over compute.

**Why required:** ASR replicates to a *different* region; failover has nowhere to go without target
capacity. Insufficient vCPU/family quota in the target region causes failover to fail at the worst
possible time.

**How to verify:** In the portal, check **Subscriptions > Usage + quotas** in the target region for
the VM families you will fail over; confirm the source/target regions are a supported ASR pair
(*verify current region-pair support in your tenant — pairings change*).

**How to implement if missing:** Select a supported target region, request quota increases for the
required VM families, and confirm any required networking (target VNet/subnets) is planned.

---

## R3 — Vault soft-delete and immutability policy decision

**Description:** A decision on the **soft-delete retention window** (14–180 days) and whether
vault **immutability** is **enabled** or **enabled-and-locked** for each vault.

**Why required:** Soft delete and immutability are the ransomware controls that keep recovery
points intact even under a compromised admin account. **Locked immutability is irreversible** — it
cannot be disabled once locked, so the decision must be deliberate. This is a security/ops decision
the customer's security function should own (defer per house rules).

**How to verify:** Confirm a documented decision exists specifying soft-delete days and
immutability state (enabled vs. locked) per vault.

**How to implement if missing:** Present the tradeoff (stronger protection vs. irreversibility),
obtain a signed decision, and apply it in the Bicep template (Section 3). Default recommendation:
soft delete = 14 days (or longer per policy), immutability **enabled** (not locked) until the
configuration has been validated, then locked deliberately.

---

## R4 — RBAC roles for backup and Site Recovery

**Description:** The operating identity holds **Backup Contributor**, **Site Recovery Contributor**,
and **Reader** as appropriate, and an identity with **Owner/Contributor** exists for the initial
Bicep deployment.

**Why required:** Configuring backup, enabling replication, and creating vaults require distinct
built-in roles. Using an over-privileged account for day-to-day operation violates least privilege;
using an under-privileged one blocks the work.

**How to verify:** In **Subscriptions/Resource groups > Access control (IAM) > Role assignments**,
confirm the operating identity's roles; run `Get-AzRoleAssignment` for the identity.

**How to implement if missing:** Assign **Backup Contributor** and **Site Recovery Contributor** at
the appropriate scope for operations, and reserve an Owner/Contributor identity for the one-time
infrastructure deployment.

---

## R5 — Network line of sight for replication and (if applicable) the on-prem ASR appliance

**Description:** Outbound connectivity from source workloads/appliance to Azure ASR endpoints, and
— for on-premises-to-Azure — a deployed **ASR replication appliance** (modern appliance) or the
legacy configuration/process server, sized for the workload.

**Why required:** ASR ships change data continuously; blocked endpoints or an undersized appliance
cause replication to fall behind RPO or fail to initialize.

**How to verify:** For Azure-to-Azure, confirm the Mobility service can reach ASR endpoints
(no NSG/firewall block on required outbound). For on-prem, confirm the appliance is registered and
healthy in the vault (**Site Recovery infrastructure**).

**How to implement if missing:** Allow the required ASR outbound URLs/service tags, and deploy and
register the replication appliance per the target region and source hypervisor (Hyper-V / VMware /
physical). *Verify current appliance requirements and supported source versions in your tenant.*

---

## R6 — Application-consistency prerequisites for SQL-in-VM and app VMs

**Description:** The **SQL VSS writer** and the Azure VM **Guest Agent** are healthy on machines
that need application-consistent recovery points; SQL-in-VM backup requires the workload registered
via the vault's SQL backup extension.

**Why required:** Crash-consistent recovery points may not cleanly recover a transactional database.
Application-consistent snapshots (VSS on Windows, pre/post scripts on Linux) are required for
reliable SQL and app recovery.

**How to verify:** Confirm the VM Guest Agent shows **Ready**; for SQL-in-VM, confirm the databases
are discoverable in the vault under **Backup > SQL Server in Azure VM**.

**How to implement if missing:** Install/repair the VM Guest Agent, ensure the VSS writer is
healthy (`vssadmin list writers`), and register SQL-in-VM discovery in the vault before assigning
the SQL backup policy.

---

## R7 — An isolated DR test network and restore target (ties to GR2)

**Description:** An isolated resource group and virtual network — **DR Test Sandbox – Isolated –
Validate** (`rg-dr-test-sandbox`) — with no routing to production, used for **test failover** and
the proving **test restore**.

**Why required:** A test failover and a test restore must not collide with running production
(duplicate IPs, name conflicts, or accidental data overwrite). Isolation is what makes proving safe.

**How to verify:** Confirm the isolated RG/VNet exists and is documented, and that it has no peering
or routing to production networks.

**How to implement if missing:** Create the isolated RG and VNet (non-overlapping address space, no
production peering) and record it as the standing test target.

---

## R8 — Az PowerShell modules and Bicep tooling on the management host

**Description:** The tooling host (GR6) has current **Az** modules — `Az.Accounts`,
`Az.RecoveryServices`, `Az.DataProtection`, `Az.Compute`, `Az.Storage` — and the **Bicep** CLI
(via `az bicep` or the Azure CLI) installed.

**Why required:** The discovery, enablement, validation, and reporting scripts depend on these
modules; the Bicep template requires the Bicep toolchain to deploy.

**How to verify:** Run `Get-Module Az.RecoveryServices,Az.DataProtection -ListAvailable` and
`az bicep version`.

**How to implement if missing:** `Install-Module Az -Scope CurrentUser` (and the specific
sub-modules above) and `az bicep install`. Confirm sign-in with `Connect-AzAccount`.


---


# Global Requirements — Backup & DR Solutions

These requirements apply across **every** solution in the **Backup & DR Solutions** category. They are intentionally generic: any individual solution layers its specific prerequisites on top of these. **Do not assume any prerequisite is already in place** — for each, confirm **Description / Why / Verify / Implement if missing** before proceeding.

---

## GR1 — A tenant/subscription with backup tooling and administrative access

**Description:** A cloud tenant and/or subscription (for example a Microsoft 365 tenant and/or an Azure subscription) with backup tooling provisioned, plus administrative access sufficient to view, configure, and restore protected data.

**Why:** Backup and DR work — coverage assessment, restore testing, remediation — is impossible without administrative reach into the platform that holds the data and the tooling that protects it.

**Verify:** Sign in to the relevant admin console/portal and confirm an account with the required administrative or backup-operator role, and that backup tooling is present and licensed.

**Implement if missing:** Provision the tenant/subscription, license and configure the backup tooling, and obtain an appropriately scoped administrative/operator role before continuing.

---

## GR2 — A non-production restore target

**Description:** An isolated, non-production destination for performing test restores — a sandbox location, alternate path, or restore-test resource group/network — kept separate from live data and systems.

**Why:** Recovery testing must prove restorability **without** risking production. Restoring into production can overwrite live data or cause resource collisions and outages.

**Verify:** Confirm a documented, isolated restore target exists for each in-scope workload type and that it cannot affect production data or networks.

**Implement if missing:** Provision a dedicated non-production restore target (sandbox location / alternate path / restore-test resource group with an isolated network) and document it.

---

## GR3 — Documented RPO/RTO objectives

**Description:** Written, agreed **Recovery Point Objective** and **Recovery Time Objective** targets per workload class.

**Why:** Backup and recovery outcomes can only be judged PASS/FAIL against defined objectives. Without them, "recoverable" and "timely" are subjective and unauditable.

**Verify:** Locate an approved document stating RPO and RTO per workload class.

**Implement if missing:** Propose objectives per workload class, agree them with the stakeholder/client, and record them in the solution's baseline.

---

## GR4 — Secure evidence storage

**Description:** A controlled, retained store for recovery-test evidence and reporting outputs, with access control and a defined retention period.

**Why:** Audits, insurers, and clients require durable proof of tested recovery. Evidence that is ad hoc, mutable, or short-lived is not defensible.

**Verify:** Confirm a designated store exists with access control and retention, holding prior evidence/reports.

**Implement if missing:** Designate a secure, access-controlled store with a documented retention period and restrict write access to program operators.

---

## GR5 — Change control

**Description:** A change-management process under which backup/restore/DR activities (test restores, on-demand backups, configuration changes) are authorized and logged.

**Why:** These activities consume resources, create artifacts, and touch protected data; they must be authorized and traceable, especially in shared or regulated environments.

**Verify:** Confirm a change record or standing change covers the recurring backup/DR activities.

**Implement if missing:** Establish a standing/recurring change authorizing the activity and require a change reference on each execution.

---

## GR6 — Network connectivity and a tooling host

**Description:** A management host with the required administrative modules/CLIs installed (for example Az PowerShell and the Microsoft Graph PowerShell SDK) and network access to the relevant portals, APIs, and backup consoles.

**Why:** Discovery, validation, reporting, and remediation tooling — and the restores themselves — require reliable connectivity and the right client tools.

**Verify:** From the host, confirm the required modules/CLIs are installed and the relevant endpoints are reachable.

**Implement if missing:** Install the required tooling and ensure outbound connectivity to the platform and backup console from the host.


---


# 3. Implementation — Azure Backup & Site Recovery — Deployment & Configuration

This section deploys the platform in five stages: **Assess → Configure → Pilot → Validate →
Expand**. Steps are imperative and ordered. Portal navigation paths are given in full. Every
object created uses its verbatim name from the **Named objects** table in Section 1 (e.g.
**Recovery Services Vault – Core – Configure** = `rsv-backup-core-prod`). Placeholder values
(`contoso`, region names, subscription IDs) are examples — substitute your own.

> Complete the requirements (Section 2 and the global requirements) first. Do not assume any
> prerequisite; verify each before starting. Anything disruptive is done **pilot-first** and, for
> scripts, **`-WhatIf` / plan first**.

---

## Stage 1 — Assess

Goal: know what exists, what is protected, and what the target topology will be.

1. Sign in to the management host and connect: `Connect-AzAccount`, then
   `Set-AzContext -SubscriptionId <sub-id>`.

2. Run **`BCKDR-Discovery.ps1`** (read-only). It enumerates VMs, Azure Files shares, SQL-in-VM
   candidates, storage accounts/blob containers, existing Recovery Services and Backup vaults, and
   any existing ASR replication, and flags each in-scope resource as **protected** or
   **unprotected**. Save its CSV as the assessment baseline.

3. From the CSV, build the protection plan: for each workload class record the source region,
   intended vault, intended policy, and (for DR-tier workloads) whether it needs **ASR replication**
   to the target region (R2).

4. Confirm the design decisions from Section 2 are recorded: RPO/RTO per class (R1), target region
   (R2), soft-delete window and immutability state (R3), and the isolated **DR Test Sandbox –
   Isolated – Validate** (`rg-dr-test-sandbox`, R7).

---

## Stage 2 — Configure (deploy hardened vaults + policies)

Goal: deploy the vaults and policies declaratively, hardened with soft delete and immutability.

1. Review **`BCKDR-Deploy.bicep`**. It creates, in the primary region:
   - **Recovery Services Vault – Core – Configure** (`rsv-backup-core-prod`) with **soft delete
     enabled** and **immutability** set per R3.
   - **Backup Vault – Object – Configure** (`bvault-backup-object-prod`) with its own soft delete
     and immutability.
   - Backup policies: **VM Backup Policy – Daily-30d – Configure** (`bkpol-vm-daily-30d`),
     **Files Backup Policy – Daily-30d – Configure** (`bkpol-files-daily-30d`),
     **SQL Backup Policy – Log-15m – Configure** (`bkpol-sql-log15m`), and
     **Blob Backup Policy – Vaulted-30d – Configure** (`bkpol-blob-vaulted-30d`).

2. Set parameters (region, soft-delete days, immutability state, retention) in a
   `BCKDR-Deploy.parameters.json` or inline, matching the R1/R3 decisions.

3. **Preview before applying** — run a what-if:
   ```
   az deployment group what-if --resource-group rg-backup-core-prod \
     --template-file BCKDR-Deploy.bicep --parameters @BCKDR-Deploy.parameters.json
   ```
   Review the planned changes. Only then deploy:
   ```
   az deployment group create --resource-group rg-backup-core-prod \
     --template-file BCKDR-Deploy.bicep --parameters @BCKDR-Deploy.parameters.json
   ```

4. Confirm hardening in the portal: **portal.azure.com > Recovery Services vaults >
   `rsv-backup-core-prod` > Properties**. Under **Security Settings / Soft Delete** confirm soft
   delete is **Enabled**; under **Immutable vault** confirm the chosen state. Do the same for
   **Backup vaults > `bvault-backup-object-prod` > Properties**.

   > Leave immutability **enabled but not locked** until after Validate (Stage 4). Locking is
   > **irreversible** — lock deliberately in Stage 5 once the configuration is proven.

5. Create the **ASR Replication Policy – A2A-RPO – Configure** (`asrpol-a2a-core`): in
   **`rsv-backup-core-prod` > Site Recovery infrastructure > Replication policies > + Replication
   policy**, set the **RPO threshold**, **recovery-point retention**, and **app-consistent snapshot
   frequency** to meet the agreed RPO (R1). (The scripts reference this policy by name.)

---

## Stage 3 — Pilot

Goal: protect a small, representative set and prove failover before touching the whole estate.
Pick 1–2 VMs per workload class (a file server, a SQL-in-VM, a Tier-1 app VM) as the pilot.

### 3a — Enable Azure Backup on pilot workloads

1. Preview enablement with **`BCKDR-EnableProtection.ps1`** — it defaults to **`-WhatIf`** and only
   *reports* what it would protect:
   ```
   .\BCKDR-EnableProtection.ps1 -Vault rsv-backup-core-prod -Scope Pilot -WhatIf
   ```
2. Apply to the pilot only, gated behind change control (GR5):
   ```
   .\BCKDR-EnableProtection.ps1 -Vault rsv-backup-core-prod -Scope Pilot -Apply -ChangeRef <CR>
   ```
   This assigns **VM Backup Policy – Daily-30d – Configure** to pilot VMs, **Files Backup Policy –
   Daily-30d – Configure** to the pilot file share, and registers the pilot SQL-in-VM databases
   under **SQL Backup Policy – Log-15m – Configure**.
3. Alternatively, enable manually in the portal: **`rsv-backup-core-prod` > Backup > + Backup >**
   choose the datasource type, select the policy by name, and select the pilot items.
4. Trigger a first backup: on each pilot item, **Backup items > (item) > Backup now**. Wait for the
   first recovery point to complete.

### 3b — Enable ASR replication on a pilot app (Azure-to-Azure)

1. In **`rsv-backup-core-prod` > Site Recovery > Enable Site Recovery > Azure virtual machines**,
   choose the source region, the pilot VM(s), the **target region** (R2), the target resource group
   and VNet, and the **ASR Replication Policy – A2A-RPO – Configure** (`asrpol-a2a-core`).
2. Start replication and wait until the pilot VM(s) reach **Protected** with an initial recovery
   point (initial replication can take time proportional to disk size).

   > For **on-premises-to-Azure**, first register the ASR replication appliance (R5) under **Site
   > Recovery infrastructure**, then **Enable replication** selecting the on-prem source machines,
   > target region, and policy. *Verify current appliance and source-OS support in your tenant.*

### 3c — Build the pilot recovery plan

1. In **`rsv-backup-core-prod` > Site Recovery > Recovery Plans (Site Recovery) > + Recovery
   plan**, create **Recovery Plan – Tier1 App – Pilot** (`rp-tier1-app`). Add the replicated pilot
   items.
2. **Customize** the plan into ordered **groups** to reflect dependency order — e.g. **Group 1** =
   database VM, **Group 2** = application VM, **Group 3** = web VM.
3. Add **pre/post actions** where needed: a post-Group-1 step to confirm the database is accepting
   connections, and a post-failover manual/scripted step to repoint DNS. Keep scripts idempotent.

---

## Stage 4 — Validate (prove the deployment works)

Goal: prove — once — that backup restores and the recovery plan fails over within target. (Ongoing
scheduled restore-testing across the estate is the separate **Backup Validation & Recoverability
Assurance** program; this stage is the one-time deployment proof.)

1. Run **`BCKDR-Validate.ps1`** (read-only). It confirms: soft delete + immutability are set on both
   vaults, the four policies exist and are assigned to the pilot items, pilot items have a recent
   successful recovery point, and ASR pilot items are **Protected** with an RPO within target.
   Save its PASS/FAIL output as deployment evidence.

2. **Prove restore** — perform one file-level restore from a pilot VM recovery point into the
   **DR Test Sandbox – Isolated – Validate** (`rg-dr-test-sandbox`): **Backup items > (pilot VM) >
   File Recovery**, mount the recovery point, and confirm a known file is present and readable.
   Do **not** restore over production.

3. **Prove failover** — run a **non-disruptive test failover** of **Recovery Plan – Tier1 App –
   Pilot** into the isolated network. Either:
   - Portal: **Recovery Plans > `rp-tier1-app` > Test Failover**, select the latest recovery point
     and the **`rg-dr-test-sandbox`** VNet; or
   - Script (gated): `.\BCKDR-Validate.ps1 -RunTestFailover -RecoveryPlan rp-tier1-app
     -TestNetworkResourceGroup rg-dr-test-sandbox -ChangeRef <CR>`.

   Test failover does **not** affect the running production workload. Confirm the failed-over VMs
   boot in order in the isolated network and the app responds. Record the elapsed time and compare
   it to the **RTO** target (R1).

4. **Clean up the test failover** — always run **Cleanup test failover** on the recovery plan
   afterward (portal: **Recovery Plans > `rp-tier1-app` > Cleanup test failover**) to delete the
   test VMs and release resources. Delete any test-restore artifacts from `rg-dr-test-sandbox`.

5. If restore, test failover, or RPO/RTO checks fail, resolve before expanding (see Section 6).

---

## Stage 5 — Expand

Goal: roll protection across the estate, add alerting, lock hardening, and hand over the runbook.

1. **Expand backup** — re-run **`BCKDR-EnableProtection.ps1`** with `-Scope Estate` in `-WhatIf`
   first, review, then `-Apply -ChangeRef <CR>` to assign the named policies across all remaining
   in-scope VMs, file shares, SQL-in-VM databases, and blob accounts.

2. **Expand replication** — enable ASR on the remaining DR-tier workloads against
   `asrpol-a2a-core`, and extend or add recovery plans (following the `rp-<tier>-<app>` naming) with
   correct sequencing per application.

3. **Configure alerting** — create **Backup & DR Alert Rule – Health – Expand**
   (`alert-backupdr-health`): in **`rsv-backup-core-prod` > Monitoring > Backup Alerts** (and Azure
   Monitor alert rules) enable alerts for **backup failures**, **restore failures**, and **ASR
   replication health / RPO breaches**, routed to an action group (email/Teams/ITSM). Confirm at
   least one test alert reaches the destination.

4. **Lock immutability (deliberate, irreversible)** — now that the configuration is validated, if
   R3 calls for locked immutability, set both vaults' immutability to **Locked** in **Vault >
   Properties > Immutable vault**. Understand this cannot be undone.

5. **Hand over the runbook** — finalize the **Restore/Failover Runbook – Estate – Expand**
   document: how to run a real failover of each recovery plan (and **failback**), how to restore
   each workload type, the alert-response steps, the RPO/RTO targets, and who authorizes a failover.
   Cross-reference the **Backup Validation & Recoverability Assurance** program for the ongoing
   restore-testing cadence.

6. Run **`BCKDR-Report.ps1`** (read-only) to produce the estate-wide posture report (protected vs.
   unprotected, policy coverage, replication health, last recovery point per item) for the handover
   pack.


---


# 5. Testing & Validation — Azure Backup & Site Recovery — Deployment & Configuration

Testing confirms three things: the **vaults are hardened**, the **backup policies actually protect
the estate**, and **recovery works** (restore + failover) within target. Use the scripts by name;
each is read-only unless explicitly gated. Record results as deployment evidence in the secure
store (GR4).

> **Boundary.** This section validates the *deployment* (does it work, once). The ongoing,
> scheduled discipline of proving restores across the estate over time is the separate **Backup
> Validation & Recoverability Assurance** program — do not duplicate that cadence here.

---

## Test 1 — Vault hardening

**Procedure:** Run **`BCKDR-Validate.ps1`** and check the portal (**Recovery Services vaults >
`rsv-backup-core-prod` > Properties**, and **Backup vaults > `bvault-backup-object-prod` >
Properties**).

**Pass criteria:**
- **Soft delete** is **Enabled** on both vaults, with the retention window from R3.
- **Immutability** is in the state agreed in R3 (enabled during pilot; locked only after Stage 4).
- Vaults exist in the intended region and resource group.

---

## Test 2 — Policy existence and assignment

**Procedure:** Run **`BCKDR-Validate.ps1`**; cross-check **`rsv-backup-core-prod` > Backup items**.

**Pass criteria:**
- All four policies exist: **VM Backup Policy – Daily-30d – Configure**, **Files Backup Policy –
  Daily-30d – Configure**, **SQL Backup Policy – Log-15m – Configure**, **Blob Backup Policy –
  Vaulted-30d – Configure**.
- Every in-scope pilot (then, post-Expand, estate) item is assigned to the correct policy —
  **no in-scope item is unprotected**.
- Schedule/retention on each policy matches the RPO/RTO decisions (R1). For SQL-in-VM, the **log
  backup interval** (e.g. 15 min) matches the SQL RPO.

---

## Test 3 — First successful recovery point

**Procedure:** For each pilot item, **Backup items > (item) > Last backup status**; or read
`BCKDR-Validate.ps1` output.

**Pass criteria:**
- Each pilot item shows a **successful** recent recovery point (data age within the RPO).
- No item is stuck in **Warning** / initial-backup-never-completed.

---

## Test 4 — Restore proof (into the isolated sandbox)

**Procedure:** Perform one **File Recovery** restore from a pilot VM recovery point into
**DR Test Sandbox – Isolated – Validate** (`rg-dr-test-sandbox`). Confirm a known file is present
and readable. **Never restore over production.**

**Pass criteria:**
- The restore completes within the workload's **RTO**.
- The restored file is present and its content is intact.
- Nothing in production was modified.

---

## Test 5 — ASR replication health and RPO

**Procedure:** Run **`BCKDR-Validate.ps1`**; check **`rsv-backup-core-prod` > Site Recovery >
Replicated items**.

**Pass criteria:**
- Pilot (then estate) DR-tier items are **Protected** with a healthy replication status.
- Current **RPO** is at or below the target set in **ASR Replication Policy – A2A-RPO – Configure**.
- No replication errors or "RPO exceeded" alerts are open.

---

## Test 6 — Recovery-plan test failover

**Procedure:** Run a **non-disruptive test failover** of **Recovery Plan – Tier1 App – Pilot**
(`rp-tier1-app`) into `rg-dr-test-sandbox` (portal **Test Failover**, or
`BCKDR-Validate.ps1 -RunTestFailover`). **Always run Cleanup test failover afterward.**

**Pass criteria:**
- Groups fail over in the defined order (e.g. DB → app → web); pre/post actions run successfully.
- Failed-over VMs boot in the isolated network and the application responds.
- Total elapsed time is within the application's **RTO**.
- Production is unaffected throughout; **Cleanup test failover** removes all test resources.

---

## Test 7 — Alerting

**Procedure:** Confirm **Backup & DR Alert Rule – Health – Expand** (`alert-backupdr-health`) is
configured and fires. Trigger a benign test (e.g. an alert-rule test notification or a controlled
failed-job condition in a lab).

**Pass criteria:**
- Backup-failure, restore-failure, and ASR-health/RPO-breach alerts are enabled.
- At least one test alert reaches the action group destination (email/Teams/ITSM).

---

## Evidence to capture

For each test, record: date/time, operator, the object name(s) involved, the recovery point used,
elapsed time vs. RTO, data age vs. RPO, PASS/FAIL, and the change reference (GR5). Store in the
secure evidence store (GR4). Run **`BCKDR-Report.ps1`** to compile the estate-wide posture summary
for the handover pack. Any FAIL routes to Section 6 (Troubleshooting) before go-live.


---


# 6. Troubleshooting — Azure Backup & Site Recovery — Deployment & Configuration

Common failures, in **symptom → cause → fix** form. Most map back to a requirement (Section 2) or
a stage in the implementation (Section 3).

---

## Backup — enablement and jobs

**Symptom:** `Enable-AzRecoveryServicesBackupProtection` or portal enablement fails with
authorization error.
**Cause:** The operating identity lacks **Backup Contributor** at the vault scope (R4).
**Fix:** Assign **Backup Contributor** on the vault/resource group, sign out/in, and retry.
`BCKDR-EnableProtection.ps1` will preview first in `-WhatIf` — confirm the plan, then `-Apply`.

**Symptom:** First VM backup stays in **Warning** or never completes.
**Cause:** VM **Guest Agent** not ready, or an extension/snapshot failure (R6).
**Fix:** Confirm the VM Guest Agent shows **Ready**; restart the VM Agent; check the VM's
**Backup > Backup jobs** for the sub-error. For Windows, confirm the VSS writers are healthy
(`vssadmin list writers`). Re-run **Backup now**.

**Symptom:** SQL-in-VM databases don't appear to protect.
**Cause:** The SQL workload isn't **registered/discovered** in the vault, or the AzureWLBackup
extension is unhealthy (R6).
**Fix:** In **`rsv-backup-core-prod` > Backup > SQL Server in Azure VM**, run **Discover DBs**,
confirm the VM registers, then assign **SQL Backup Policy – Log-15m – Configure**. Verify the log
backup interval matches your SQL RPO.

**Symptom:** Azure Files backup enablement fails or the share is not listed.
**Cause:** The storage account isn't reachable by the vault, or the share is in an unsupported
account/redundancy tier.
**Fix:** Confirm the storage account is in a supported configuration and region; register the
storage account under **Backup > Azure Files**, then assign **Files Backup Policy – Daily-30d –
Configure**.

---

## Vault hardening

**Symptom:** Bicep deployment fails on `securitySettings` / `immutabilitySettings`.
**Cause:** The API version in `BCKDR-Deploy.bicep` doesn't match the property shape your tenant
expects — these paths drift between API versions.
**Fix:** Run `az deployment group what-if` to see the rejected property, and adjust the
`@2024-04-01` API version / property path to the current one. *Verify current property support in
your tenant.*

**Symptom:** You cannot disable immutability or shorten retention.
**Cause:** Immutability was set to **Locked** — this is **irreversible** by design (R3).
**Fix:** There is no fix — locked immutability cannot be reversed. This is why the implementation
keeps immutability **Unlocked** until Stage 4 (Validate) and only locks in Stage 5. If you need a
different configuration, it must be a new vault.

**Symptom:** A recovery point you deleted is gone sooner than expected.
**Cause:** Soft delete disabled, or its window shorter than assumed.
**Fix:** Confirm **soft delete Enabled** with the intended retention (R3) on both vaults; recover
in-window items from **soft-deleted** state; extend the window going forward.

---

## Site Recovery — replication

**Symptom:** ASR replicated item stuck in initial replication or **Critical** health.
**Cause:** Blocked outbound to ASR endpoints, or an unhealthy Mobility service / appliance (R5).
**Fix:** Allow the required ASR outbound URLs/service tags on NSGs/firewall; for on-prem, confirm
the replication appliance is **registered and healthy** under **Site Recovery infrastructure**;
reinstall/repair the Mobility service on the source machine.

**Symptom:** Current **RPO exceeds** the target.
**Cause:** Insufficient bandwidth, high change rate, or an undersized appliance/policy (R5).
**Fix:** Check replication health and the churn rate; increase bandwidth or scale the appliance;
re-evaluate whether the target RPO is achievable and, if not, surface it — RPO is a business
decision (R1) that must match reality.

**Symptom:** `Enable replication` cannot select a target because of quota.
**Cause:** The target region lacks vCPU/family quota for the failed-over compute (R2).
**Fix:** Request a quota increase for the required VM families in the target region before enabling
replication or failing over.

---

## Recovery plans & test failover

**Symptom:** Test failover boots VMs but the application doesn't come up.
**Cause:** Recovery-plan groups are not sequenced by dependency (app started before its database).
**Fix:** Edit **Recovery Plan – Tier1 App – Pilot** so **Group 1** = database, **Group 2** = app,
**Group 3** = web, and add a post-Group-1 check that the DB is accepting connections before later
groups start.

**Symptom:** Test failover succeeds but leaves resources/cost behind.
**Cause:** **Cleanup test failover** was not run.
**Fix:** Always run **Recovery Plans > `rp-tier1-app` > Cleanup test failover** after validating.
Delete any leftover artifacts in **DR Test Sandbox – Isolated – Validate** (`rg-dr-test-sandbox`).

**Symptom:** Test failover VMs land on a production network / cause IP conflicts.
**Cause:** The wrong target network was selected.
**Fix:** Always run test failover into the isolated **`rg-dr-test-sandbox`** VNet (R7). Never point
a test failover at a production network.

**Symptom:** `BCKDR-Validate.ps1 -RunTestFailover` throws before starting.
**Cause:** The gate — it requires `-RecoveryPlan`, `-TestNetworkResourceGroup`, and `-ChangeRef`.
**Fix:** Supply all three; the gate is intentional so a test failover is never triggered casually.

---

## Alerting & reporting

**Symptom:** Backups fail silently; nobody is notified.
**Cause:** **Backup & DR Alert Rule – Health – Expand** (`alert-backupdr-health`) not configured or
not routed to a monitored action group.
**Fix:** Enable backup-failure, restore-failure, and ASR RPO-breach alerts and route them to an
action group; send a test notification and confirm it arrives.

**Symptom:** `BCKDR-Discovery.ps1` / `BCKDR-Report.ps1` returns nothing.
**Cause:** Wrong subscription context or missing **Reader** access.
**Fix:** `Set-AzContext -SubscriptionId <id>`; confirm Reader on the subscription and vaults; re-run.
Newly created resources may not appear until the first run after they exist — re-baseline on a
cadence.


---


# 7. Best Practices — Azure Backup & Site Recovery — Deployment & Configuration

Keep the platform clean, defensible, and cheap to run.

## Vault hardening

- **Enable soft delete on every vault, always.** It is the free undo button for accidental or
  malicious deletion. Set the retention window per your data-protection policy (14–180 days).
- **Enable immutability, and lock it only after validation.** Locked immutability is
  **irreversible** — prove the whole configuration first (Stage 4), then lock deliberately. Locking
  before validation can trap a mistake you cannot undo.
- **Use multi-user authorization (MUA) for critical vault operations** where available, so a single
  compromised admin cannot weaken protection. *Verify current MUA availability in your tenant.*
- **Separate the backup blast radius.** Keep vaults in a dedicated, tightly-RBAC'd resource group;
  restrict **Backup Contributor** / **Site Recovery Contributor** to the people who operate them.

## Policy design

- **Author policies once, assign many.** Reuse the named policies (`bkpol-vm-daily-30d`, etc.)
  rather than creating per-VM policies — it keeps RPO/RTO consistent and auditable.
- **Match policy to RPO/RTO, not to habit.** For SQL-in-VM, the **log-backup interval** *is* your
  RPO — set it to the agreed target (R1), not a default. Retention (daily/weekly/monthly/yearly)
  should reflect real recovery and compliance needs, not "keep everything forever" (cost) or "keep
  7 days" (too little).
- **Right-size retention for cost.** Long-term retention points accrue storage cost; use tiered
  retention (short daily + longer monthly/yearly) instead of long daily retention.

## Site Recovery & recovery plans

- **Sequence recovery plans by dependency.** Database group first, then app, then web. A plan that
  boots everything at once often fails app health checks.
- **Keep pre/post scripts idempotent and version-controlled.** They run under stress during a real
  failover; they must be safe to re-run.
- **Test failover regularly and always clean up.** A test failover proves the plan; leaving test
  resources behind wastes money and clutters the target region. Automate the cleanup step.
- **Plan and rehearse failback.** Failover is half the story — document and test the return to the
  primary region so DR is not a one-way trip.
- **Watch target-region quota.** Failover fails if the target region lacks vCPU/family quota
  (R2) — recheck quota as the estate grows.

## Operations

- **Alert on failure, not just success.** Route backup-failure, restore-failure, and ASR RPO-breach
  alerts to a monitored destination (`alert-backupdr-health`); a silent backup failure is the
  gap you find during an incident.
- **Keep the runbook current.** Update **Restore/Failover Runbook – Estate – Expand** whenever the
  estate, RPO/RTO, or recovery plans change.
- **Re-baseline coverage as the estate grows.** New VMs, shares, and databases drift out of
  protection unless re-assessed — re-run **`BCKDR-Discovery.ps1`** on a cadence.
- **Never hand-edit production during a test.** All proving happens in `rg-dr-test-sandbox`.

## Deferred decisions (customer-owned)

- **RPO/RTO targets** are a business decision (R1) — this solution meets them, it does not set them.
- **Immutability lock and soft-delete window** are security/ops decisions (R3) — obtain sign-off.
- **Retention beyond operational need** may be driven by legal/records requirements — route those
  to the customer's compliance function, not the backup admin.

## Where to go next (adjacent catalog areas)

- **Backup Validation & Recoverability Assurance** — the essential companion: a scheduled,
  evidence-producing discipline that proves restores across the estate *continuously* (this solution
  proves recoverability once, at deployment).
- **Backup & DR Solutions** category — broader resilience patterns (immutable/offsite copies,
  ransomware recovery runbooks) that build on this deployment.
- **Azure governance / cost management** — policy-as-code to *enforce* that every new VM lands under
  a backup policy, and cost controls for backup/replication storage.


---


# 8. Deliverables Summary — Azure Backup & Site Recovery — Deployment & Configuration

## Documentation

| Document | Purpose |
|---|---|
| `executive-summary.md` | The problem, the solution, outcomes, scope boundary, and effort. |
| `01-solution-overview.md` | What it is, how Azure Backup + ASR work, the Assess→Configure→Pilot→Validate→Expand model, named objects, scope, and connections. |
| `02-requirements.md` | Solution-specific prerequisites (R1–R8) layered on the category global requirements. |
| `03-implementation.md` | Ordered, click-by-click deployment across the five stages, naming every object. |
| `05-testing.md` | Seven validation tests (vault hardening, policy coverage, restore proof, replication/RPO, test failover, alerting) with pass criteria. |
| `06-troubleshooting.md` | Symptom → cause → fix for the common Azure Backup and ASR failures. |
| `07-best-practices.md` | Hardening, policy, ASR, and operations guidance, plus where to go next. |
| `08-deliverables-summary.md` | This summary. |
| `global-requirements-backup-dr-solutions.md` | Category-wide prerequisites (GR1–GR6). |

## Automation scripts

| Script | Purpose |
|---|---|
| `BCKDR-Discovery.ps1` | **Read-only.** Inventories VMs, Azure Files, SQL-in-VM, storage/blobs, existing vaults, and ASR; flags each in-scope resource as protected or unprotected to build the assessment baseline. |
| `BCKDR-Deploy.bicep` | **Plan/what-if first.** Declarative deployment of the Recovery Services vault and Backup vault (soft delete + immutability) and the four backup policies. |
| `BCKDR-EnableProtection.ps1` | **`-WhatIf` by default, `-Apply` gated.** Assigns the named backup policies and enables protection on pilot then estate VMs/Files/SQL-in-VM/blobs under change control. |
| `BCKDR-Validate.ps1` | **Read-only** (optional gated `-RunTestFailover`). Verifies vault hardening, policy assignment, recovery-point recency, and ASR replication health/RPO; can trigger a non-disruptive test failover of a recovery plan. |
| `BCKDR-Report.ps1` | **Read-only.** Compiles estate-wide backup/DR posture (protected vs. unprotected, policy coverage, replication health, last recovery point) into a CSV for the handover pack. |

## Named objects created (reference)

`rsv-backup-core-prod` · `bvault-backup-object-prod` · `bkpol-vm-daily-30d` ·
`bkpol-files-daily-30d` · `bkpol-sql-log15m` · `bkpol-blob-vaulted-30d` · `asrpol-a2a-core` ·
`rp-tier1-app` · `rg-dr-test-sandbox` · `alert-backupdr-health` · Restore/Failover Runbook.

## Format

This solution is delivered as a **Complete Solution Package (PDF + Word + scripts)**: the eight
documentation files compiled to PDF and Word, plus the five automation artifacts, ready to execute
against an Azure subscription with the roles in Section 2.

> **Companion solution.** Pair this deployment with **Backup Validation & Recoverability Assurance**
> for the ongoing, scheduled restore-testing and evidence discipline. This solution *builds and
> proves* the platform; that program *keeps proving* it.
