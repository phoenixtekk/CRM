# 2. Requirements — Backup Validation & Recoverability Assurance Program

This section lists every prerequisite for the program. **Do not assume any prerequisite is already in place.** Each requirement follows the same structure: **Description**, **Why**, **Verify**, and **Implement if missing**. Confirm each one before proceeding to implementation.

---

## R1 — A Microsoft 365 backup product with protection enabled

**Description:** A third-party SaaS backup product that protects Exchange Online, SharePoint Online, OneDrive for Business, and Teams — for example **Veeam Backup for Microsoft 365**, **Datto SaaS Protection**, **Afi.ai**, or **AvePoint Cloud Backup**.

**Why:** Microsoft 365 has **no native point-in-time backup**; retention and holds are not backup. Without a third-party backup product, M365 data is not independently recoverable and there is nothing to test-restore.

**Verify:** Open the backup product's console and confirm at least one protection job/policy exists, is licensed for the in-scope users/sites, and shows a recent successful backup point.

**Implement if missing:** Procure and license a M365 backup product, grant it the required tenant app registration / delegated permissions, and create protection jobs covering all in-scope Exchange, SharePoint, OneDrive, and Teams objects. Do not proceed until at least one successful backup point exists.

---

## R2 — Microsoft 365 backup-console administrative access

**Description:** Administrative access to the M365 backup product's console sufficient to view jobs, browse restore points, and perform test restores.

**Why:** Test restores and evidence capture require the ability to initiate and inspect restores, not merely view job status.

**Verify:** Sign in to the backup console and confirm you can open a restore wizard / browse recoverable items for an in-scope workload.

**Implement if missing:** Request a backup-console administrator (or restore-operator) role from the product owner. Record the role granted.

---

## R3 — Azure Backup configured in a Recovery Services vault

**Description:** An Azure **Recovery Services vault** with **Azure Backup** protecting in-scope Azure VMs and/or Azure Files shares.

**Why:** Azure VM and file recoverability is validated against recovery points held in a Recovery Services vault. Without it, there are no Azure restore points to test.

**Verify:** In the Azure portal, go to **Recovery Services vault > Backup items** and confirm in-scope items are listed with a recent recovery point. (Portal path: *portal.azure.com > Recovery Services vaults > (select vault) > Backup items*.)

**Implement if missing:** Create a Recovery Services vault (*portal.azure.com > Recovery Services vaults > Create*), then enable backup for the in-scope VMs/file shares (*vault > Backup > configure backup*) and wait for the first successful recovery point.

---

## R4 — Documented and agreed RPO/RTO targets

**Description:** Written **Recovery Point Objective** (maximum tolerable data loss) and **Recovery Time Objective** (maximum tolerable restore duration) targets, agreed with the client, per workload class.

**Why:** A test restore can only PASS or FAIL against a target. Without documented RPO/RTO, "recoverable" is undefined and unauditable.

**Verify:** Locate a signed/approved document recording RPO and RTO per workload class (e.g. Exchange, SharePoint/OneDrive, Teams, Azure VM, Azure Files).

**Implement if missing:** Run the **Define RPO/RTO** phase (Implementation, Phase 2): propose targets per workload class, agree them with the client, and record them. Capture them in the **Coverage Baseline – Backup Estate – Assessment**.

---

## R5 — A safe, non-production restore target / sandbox

**Description:** An isolated restore destination — a separate mailbox/folder, a non-production SharePoint/OneDrive location, a restore-test resource group / subnet for Azure VMs, or an alternate file path — used **only** for test restores.

**Why:** Test restores must never overwrite or contaminate production data, and restored VMs must not join the production network or collide with live resources. A dedicated sandbox makes test restores safe and repeatable.

**Verify:** Confirm a documented restore target exists for each workload type and that it is isolated from production (separate location/resource group, no production network exposure).

**Implement if missing:** Provision a restore-test location per workload: a test recovery mailbox/folder, a non-production site/library, and an Azure **restore-test resource group** with an isolated virtual network/subnet. Document each in the **Coverage Baseline – Backup Estate – Assessment**.

---

## R6 — Administrative roles for restore operations

**Description:** The identity roles required to perform restores: M365 backup-console restore role (R2), and Azure RBAC roles such as **Backup Operator** (or **Contributor**) on the vault and **Virtual Machine Contributor** on the restore-target resource group.

**Why:** Azure restores fail without sufficient RBAC on both the vault and the target resource group; M365 restores fail without a restore-capable console role.

**Verify:** In the Azure portal, check **Recovery Services vault > Access control (IAM)** and the restore-target resource group's IAM for the operator identity. Confirm the M365 backup console role from R2.

**Implement if missing:** Assign **Backup Operator** on the vault and **Virtual Machine Contributor** on the restore-target resource group to the operator identity (*IAM > Add role assignment*). Record the assignments.

---

## R7 — A secure evidence and report store

**Description:** A controlled location to retain **Test-Restore Record – Per-Workload – Evidence** entries and **Recoverability Assurance Report – Backup Estate – Reporting** outputs (e.g. a managed document library or evidence repository with access control and retention).

**Why:** Audit and insurer requirements demand durable, tamper-evident records of tested restores. Evidence stored ad hoc is not defensible.

**Verify:** Confirm a designated store exists with access control, and that prior evidence/reports are retained there.

**Implement if missing:** Designate a secure store (e.g. an access-controlled SharePoint/document library or evidence repository), define a retention period, and restrict write access to the program operators.

---

## R8 — Change control for restore activities

**Description:** A change-control process under which scheduled test restores (and any on-demand backups triggered during remediation) are logged and authorized.

**Why:** Test restores create resources and consume capacity; they must be authorized and traceable, especially in regulated or shared environments.

**Verify:** Confirm a change record or standing change exists covering the restore-test cadence.

**Implement if missing:** Raise a standing/recurring change authorizing the **Restore-Test Schedule – Backup Estate – Cadence**, and require a change reference on each test restore.

---

## R9 — Network connectivity and tooling host

**Description:** A management host (or jump environment) with the **Az PowerShell module** and the **Microsoft Graph PowerShell SDK** installed, and network access to the Azure portal/APIs and the M365 backup console.

**Why:** The program's discovery, validation, reporting, and remediation scripts require Az/Graph connectivity. Restores initiated from the console require reliable network access.

**Verify:** From the host, run `Get-Module Az -ListAvailable` and `Get-Module Microsoft.Graph -ListAvailable`; confirm both return versions, and confirm portal/console reachability.

**Implement if missing:** Install the modules (`Install-Module Az`, `Install-Module Microsoft.Graph`) and ensure outbound connectivity to Azure and the backup console from the host.

---

## R10 — Defined workload scope and owners

**Description:** An explicit list of which Exchange, SharePoint, OneDrive, Teams, Azure VM, and Azure Files objects are in scope, with a named owner for each workload class.

**Why:** Coverage percentage and the restore-test rotation are meaningless without a defined denominator and an accountable owner per workload.

**Verify:** Confirm the in-scope object list and named owners are recorded in the **Coverage Baseline – Backup Estate – Assessment**.

**Implement if missing:** Work with the client to enumerate in-scope objects and assign owners; record both in the **Coverage Baseline – Backup Estate – Assessment**.

---

## R11 — Retention windows aligned to the test cadence

**Description:** Backup retention periods long enough that a recovery point always exists for each scheduled test restore, and that test-restore evidence is retained per the audit requirement.

**Why:** A test restore cannot run if no recovery point survives to its scheduled date; evidence is worthless if it expires before the next audit.

**Verify:** Compare each workload's configured retention against the **Restore-Test Schedule – Backup Estate – Cadence** and the evidence retention period.

**Implement if missing:** Increase backup retention and/or align the test cadence so a valid recovery point always exists; set evidence retention to meet the audit window.
