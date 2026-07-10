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
