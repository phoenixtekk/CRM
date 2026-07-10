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
