# Backup Validation & Recoverability Assurance Program

> **Version 1.0.0** · Category: Backup & DR Solutions · Solution code: BACKUPVAL

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Backup Validation & Recoverability Assurance Program

## The problem

Most organizations *have* backups. Far fewer can *prove* those backups restore. A backup job that reports "success" only confirms data was copied — not that it can be read back into a usable state within an acceptable time. Silent corruption, incomplete coverage, expired credentials, and newly created resources that drift outside backup policy are routinely discovered only during an actual disaster, when recovery is attempted for the first time and fails.

Two common misconceptions make this worse:

- **"Microsoft 365 backs itself up."** It does not. Microsoft 365 has **no native point-in-time backup**. Retention policies, Recycle Bin, and Litigation Hold are *retention* controls with finite, mutable windows — they do not protect against ransomware-encrypted synced files, malicious deletion past the window, or tenant loss. Independent third-party backup is required.
- **"The backup job succeeded, so we're covered."** A successful copy is not a verified restore. Recoverability is proven only by actually restoring the data.

## The solution

The **Backup Validation & Recoverability Assurance Program** converts "we have backups" into "we have **proven, restorable** backups." It establishes a repeatable discipline that tests restores on a defined cadence, measures them against agreed recovery objectives, and captures audit-grade evidence.

The program covers:

- **Microsoft 365** — Exchange Online, SharePoint Online, OneDrive, and Teams, protected by a third-party SaaS backup product (e.g. Veeam, Datto, Afi, AvePoint).
- **Azure** — virtual machines and Azure Files protected by Azure Backup via Recovery Services vaults.

It runs in seven phases: **Assess coverage → Define RPO/RTO → Schedule restore tests → Execute test restores → Validate + capture evidence → Report → Operate.**

## What you get

- A **coverage baseline** measuring protected vs. unprotected workloads.
- Agreed **RPO/RTO** targets per workload class.
- A **restore-test schedule** that, over each cycle, restores every in-scope workload.
- **Per-workload test-restore procedures** with full console navigation for Azure Backup.
- **Success criteria, evidence capture, and exception handling** for each test.
- A periodic **recoverability assurance report** suitable for clients, auditors, and cyber-insurers.
- **Five PowerShell tools** (read-only by default) for discovery, validation, reporting, remediation, and schedule scaffolding.

## Business outcomes

- **Defensible recoverability** — dated, verified evidence that backups restore within target, not just that they ran.
- **Reduced disaster risk** — restore failures and coverage gaps are found and fixed during a controlled test, not during a real incident.
- **Audit and insurance readiness** — the evidence and reporting auditors and insurers increasingly require.
- **Continuous assurance** — coverage and recoverability are re-measured as the estate changes, so confidence stays current.

This is a premium, productized program designed for IT service providers and internal IT teams that need to demonstrate — credibly and repeatedly — that their backups actually work.


---


# 1. Solution Overview — Backup Validation & Recoverability Assurance Program

## Description

The **Backup Validation & Recoverability Assurance Program** turns "we have backups" into "we have **proven, restorable** backups." Backups that have never been restored are unverified assumptions, not recoverable data. This program establishes a repeatable discipline that **proves** every in-scope workload can actually be restored — within its target recovery time — and captures the **evidence** to demonstrate it to clients, auditors, and insurers.

The program covers two primary estates:

- **Microsoft 365** — Exchange Online mailboxes, SharePoint Online sites, OneDrive for Business, and Microsoft Teams — protected by a **third-party SaaS backup product** (for example **Veeam Backup for Microsoft 365**, **Datto SaaS Protection**, **Afi.ai**, or **AvePoint Cloud Backup**). Microsoft 365 has **no native point-in-time backup**: retention policies, Recycle Bin, and Litigation Hold are *retention*, not *backup*, and do not protect against malicious deletion past their windows, ransomware encryption of synced files, or a corrupted/abandoned tenant. A third-party backup product is therefore required to make M365 data independently recoverable.
- **Azure** — virtual machines, managed disks, and Azure Files protected by **Azure Backup** through **Recovery Services vaults**, restored via the Azure portal (vault → **Backup items** → **Restore**).

Rather than trusting backup-job "success" status, the program **schedules and executes test restores on a defined cadence**, measures them against documented **RPO/RTO** targets, records the outcome in a structured evidence trail, remediates gaps, and reports recoverability posture in a form suitable for client review and audit.

## Why this matters

- A backup job reporting "success" only confirms data was *copied*, not that it can be *read back into a usable state*. Silent corruption, incomplete item-level coverage, expired credentials, and unprotected new resources are routinely discovered only at restore time — during an actual disaster, when it is too late.
- **Microsoft 365 retention is not backup.** Once a retention or hold window lapses (or is administratively shortened), the data is unrecoverable from Microsoft. Organizations that conflate the two discover the gap during a deletion or ransomware incident.
- **New resources drift out of coverage.** A VM or mailbox created after the backup policy was set may never be protected. Coverage must be measured continuously, not assumed from a one-time setup.
- Auditors, cyber-insurers, and regulated clients increasingly require **evidence of tested restores** — not a backup-tool screenshot, but a dated record showing what was restored, by whom, how long it took, and that the restored data was verified correct.

## What this program delivers

- A **coverage baseline** that inventories every in-scope workload and flags protected vs. unprotected resources.
- Documented **RPO and RTO targets** per workload class, agreed with the client.
- A **restore-test schedule** that rotates test restores across all workloads on a defined cadence.
- **Per-workload test-restore procedures** for Exchange Online, SharePoint Online, OneDrive, Teams, Azure VMs, and Azure Files.
- **Success criteria and evidence capture** for each test restore.
- An **exception-handling** process for failed or out-of-RTO restores.
- A periodic **recoverability assurance report** for client and audit consumption.

## Named program objects

This program defines a small set of named artifacts, each referenced **verbatim** throughout the documentation, scripts, and deliverables:

- **Coverage Baseline – Backup Estate – Assessment** — the authoritative inventory of in-scope workloads and their protection status.
- **Restore-Test Schedule – Backup Estate – Cadence** — the rotation plan defining which workload is test-restored when.
- **Test-Restore Record – Per-Workload – Evidence** — the structured record completed for each individual test restore.
- **Recoverability Assurance Report – Backup Estate – Reporting** — the periodic client/audit-facing summary of recoverability posture.

## Phase model

The program follows seven phases, applied in order:

1. **Assess coverage** — inventory the estate; identify protected vs. unprotected workloads.
2. **Define RPO/RTO** — agree recovery objectives per workload class.
3. **Schedule restore tests** — build the rotation cadence across all in-scope workloads.
4. **Execute test restores** — perform the per-workload test-restore procedures.
5. **Validate + capture evidence** — confirm success criteria; record the evidence.
6. **Report** — produce the recoverability assurance report.
7. **Operate** — run the cadence continuously; remediate exceptions; re-baseline as the estate changes.

## Audience

IT service providers, managed service providers, and internal IT teams responsible for proving — not just performing — backup of Microsoft 365 and Azure workloads, to a standard that withstands client scrutiny and audit.


---


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


# 3. Implementation — Backup Validation & Recoverability Assurance Program

This section implements the program in seven phases: **Assess coverage → Define RPO/RTO → Schedule restore tests → Execute test restores → Validate + capture evidence → Report → Operate**. Steps are imperative and ordered. Where a concrete console is named, full navigation paths are given. The four named objects — **Coverage Baseline – Backup Estate – Assessment**, **Restore-Test Schedule – Backup Estate – Cadence**, **Test-Restore Record – Per-Workload – Evidence**, and **Recoverability Assurance Report – Backup Estate – Reporting** — are referenced verbatim throughout.

> Complete the requirements (Section 2) first. Do not assume any prerequisite; verify each before starting.

---

## Phase 1 — Assess coverage

Goal: produce the **Coverage Baseline – Backup Estate – Assessment** — the authoritative inventory of in-scope workloads and their protection status.

1. Create the **Coverage Baseline – Backup Estate – Assessment** as a single tracked document/spreadsheet. Give it columns: *Workload class, Object name/ID, In scope (Y/N), Owner, Protected (Y/N), Backup product/vault, Last successful backup, Retention, RPO target, RTO target, Restore target, Notes.*

2. Inventory **Microsoft 365** protection in the backup product console (e.g. **Veeam Backup for Microsoft 365**, **Datto SaaS Protection**, **Afi.ai**, **AvePoint Cloud Backup**):
   - Open the backup console and navigate to its **protected objects / jobs** view.
   - For each in-scope **Exchange Online** mailbox, **SharePoint Online** site, **OneDrive** account, and **Teams** team, record whether it is covered by a job and the time of its last successful backup point.
   - List any in-scope object **not** covered by any job as **Protected = N**.

3. Inventory **Azure** protection in the Azure portal:
   - Go to **portal.azure.com > Recovery Services vaults > (select the vault) > Backup items**.
   - Under **Azure Virtual Machine** and **Azure Storage (Azure Files)**, record each protected item, its **Last backup status**, and **Latest restore point**.
   - Then go to **portal.azure.com > Virtual machines** (and **Storage accounts > File shares**) and cross-check the live estate against the vault's protected items. Any in-scope VM or file share **not** listed in **Backup items** is **Protected = N**.

4. Run **`BACKUPVAL-Discovery.ps1`** (read-only) to enumerate Recovery Services vault backup items and identify protected vs. unprotected Azure resources, and reconcile its output against the manual inventory.

5. Compute **coverage %** = (in-scope objects with Protected = Y) ÷ (total in-scope objects), per workload class and overall. Record it in the baseline.

6. Flag every **Protected = N** object as a coverage gap and route it to remediation (Phase 7).

---

## Phase 2 — Define RPO/RTO

Goal: agree and record recovery objectives per workload class.

1. For each workload class (Exchange, SharePoint/OneDrive, Teams, Azure VM, Azure Files), propose an **RPO** (max tolerable data loss) and **RTO** (max tolerable restore duration) based on the workload's criticality.

2. Review the proposed targets with the client/owner and obtain agreement. Resolve any conflict between desired RPO and the backup product's achievable backup frequency (and between desired RTO and realistic restore times).

3. Record the agreed RPO and RTO per workload class in the **Coverage Baseline – Backup Estate – Assessment** (the *RPO target* / *RTO target* columns).

4. Confirm each workload's **retention** is long enough that a recovery point will always exist at the scheduled test date (Requirement R11). Adjust retention if not.

---

## Phase 3 — Schedule restore tests

Goal: build the **Restore-Test Schedule – Backup Estate – Cadence** — the rotation defining which workload is test-restored when.

1. Create the **Restore-Test Schedule – Backup Estate – Cadence** as a tracked plan with columns: *Workload class, Object to test, Cadence (e.g. monthly/quarterly), Next due, Last tested, Owner, Restore target, Change reference.*

2. Set a cadence per workload class proportional to criticality — for example: critical workloads **monthly**, standard workloads **quarterly**, lower-tier workloads **semi-annually**. Stagger objects so the workload is spread across the period.

3. Ensure every in-scope object appears at least once per cycle so that, over a full cycle, **every** workload has been test-restored.

4. Run **`BACKUPVAL-Set-RestoreTestSchedule.ps1` -WhatIf** to scaffold and validate the schedule rotation, then commit the schedule.

5. Raise/confirm the standing change (Requirement R8) authorizing the cadence and record the change reference in the schedule.

---

## Phase 4 — Execute test restores

Goal: perform the per-workload test-restore procedures into the safe restore target (Requirement R5). **Never restore into production.** Begin each test by creating a **Test-Restore Record – Per-Workload – Evidence** entry (start time, object, recovery point used, restore target, operator, change reference).

### 4a — Exchange Online mailbox (M365 backup product)

1. In the backup console, browse the recovery points for the target mailbox and select the most recent point that satisfies the RPO.
2. Choose **restore to an alternate location** — a dedicated **test recovery mailbox/folder** (the restore target), **not** the original mailbox.
3. Restore a representative set (e.g. a folder or a date range of items). Record the restore start/finish times.
4. Open the restore target and confirm the items are present and readable.

### 4b — SharePoint Online site / document library

1. In the backup console, browse the target site/library's recovery points; select one meeting the RPO.
2. Restore to a **non-production site/library** (the restore target), preserving versions where supported.
3. Confirm restored documents, libraries, and (where applicable) list items open correctly in the restore target.

### 4c — OneDrive for Business

1. Browse the target user's OneDrive recovery points; select one meeting the RPO.
2. Restore selected files/folders to a **non-production OneDrive location or alternate path** (the restore target).
3. Confirm files are present and open correctly.

### 4d — Microsoft Teams

1. Browse the target team's recovery points; select one meeting the RPO.
2. Restore in-scope Teams content (channel files/SharePoint backing, and chat/posts where the product supports it) to the restore target.
3. Confirm restored channel files and conversations are present per the product's restore capability.

### 4e — Azure Virtual Machine (Azure Backup)

1. In the Azure portal, go to **portal.azure.com > Recovery Services vaults > (select vault) > Backup items > Azure Virtual Machine > (select the VM)**.
2. Click **Restore VM**, select a recovery point that meets the RPO, and choose **Create new** (restore as a new VM) into the **restore-test resource group** with an **isolated virtual network** (the restore target). Do **not** **Replace existing**.
3. Provide a distinct VM name and staging storage account. Start the restore and record start/finish times.
4. After deployment, start the restored VM in the isolated network and confirm it boots and key data is intact. (Alternatively, use **File recovery** from the same recovery point to mount and validate individual files without a full VM build.)
5. **Delete the restored test VM and its disks** after validation to avoid cost and clutter.

### 4f — Azure Files share

1. In the Azure portal, go to **portal.azure.com > Recovery Services vaults > (select vault) > Backup items > Azure Storage (Azure Files) > (select the share)**.
2. Click **Restore**, select a recovery point meeting the RPO, and choose **Alternate location** — restore to a **non-production file share or alternate folder** (the restore target). Do **not** overwrite the original.
3. Confirm restored files are present and open correctly; record start/finish times.

---

## Phase 5 — Validate + capture evidence

Goal: confirm success criteria and complete the **Test-Restore Record – Per-Workload – Evidence**.

1. For each test restore, evaluate against success criteria:
   - The recovery point used satisfied the **RPO** (data age within target).
   - The restore completed within the **RTO** (elapsed time ≤ target).
   - The restored data was **verified correct** (items present, openable, content intact in the restore target).
2. Mark the **Test-Restore Record – Per-Workload – Evidence** as **PASS** or **FAIL** accordingly, and attach evidence: timestamps, the recovery point identifier, screenshots/logs of the restore, and a note confirming data verification.
3. Run **`BACKUPVAL-Validation.ps1`** to programmatically check last-backup recency vs. RPO and last successful restore-test recency vs. the cadence, and attach its PASS/FAIL output to the evidence.
4. Store the completed record in the secure evidence store (Requirement R7).
5. For any **FAIL** or out-of-RTO result, open an exception and route to remediation (Phase 7).

---

## Phase 6 — Report

Goal: produce the **Recoverability Assurance Report – Backup Estate – Reporting**.

1. Run **`BACKUPVAL-Report.ps1`** to compile **coverage %**, **RPO adherence**, and **last successful test-restore per workload** into a CSV.
2. Assemble the **Recoverability Assurance Report – Backup Estate – Reporting** from that data plus the period's **Test-Restore Record – Per-Workload – Evidence** entries. Include: overall and per-class coverage %, RPO/RTO adherence, the test-restore pass rate, open exceptions, and remediation status.
3. Format the report for client/audit consumption (executive summary + detail) and store it in the secure store (Requirement R7).

---

## Phase 7 — Operate

Goal: run the program continuously.

1. Execute the **Restore-Test Schedule – Backup Estate – Cadence** every period; update *Last tested* / *Next due* as tests complete.
2. Remediate coverage gaps and failed restores:
   - Run **`BACKUPVAL-Remediation.ps1`** (read-only / `-WhatIf` by default) to flag unprotected resources and preview an on-demand backup for a named item; re-run with **`-Apply`** to trigger the on-demand backup once authorized via change control.
   - Add newly protected resources back into the rotation.
3. **Re-baseline** the **Coverage Baseline – Backup Estate – Assessment** whenever the estate changes (new mailboxes, sites, VMs, file shares) so coverage % stays accurate.
4. Issue the **Recoverability Assurance Report – Backup Estate – Reporting** on its reporting cadence and review trends (coverage %, pass rate) with the client.


---


# 5. Testing & Validation — Backup Validation & Recoverability Assurance Program

This program *is* a testing discipline, so this section defines the **acceptance gates** that determine whether the program itself is operating correctly. The program is considered validated for a given cycle only when **all** gates below pass. Each gate states what to check, how to check it, and the pass criterion.

> Use the **Test-Restore Record – Per-Workload – Evidence** entries and the outputs of `BACKUPVAL-Validation.ps1` and `BACKUPVAL-Report.ps1` as the source evidence for these gates.

---

## Gate 1 — Every in-scope workload has a passing test restore within RTO

**Check:** For each in-scope object in the **Coverage Baseline – Backup Estate – Assessment**, confirm there is a **Test-Restore Record – Per-Workload – Evidence** within the current cycle marked **PASS**, where the restore elapsed time was **≤ the RTO target**.

**How:** Cross-reference the baseline against the evidence store and the `BACKUPVAL-Report.ps1` "last successful test-restore per workload" column.

**Pass criterion:** 100% of in-scope objects have a PASS within RTO in the current cycle. Any workload with no test, a FAIL, or an out-of-RTO result fails this gate.

---

## Gate 2 — RPO adherence

**Check:** For each test restore, the recovery point used was within the workload's **RPO target** (data age ≤ RPO), and each protected workload's most recent backup point is within RPO.

**How:** Review the recovery-point timestamps in each **Test-Restore Record – Per-Workload – Evidence** and the PASS/FAIL output of `BACKUPVAL-Validation.ps1` (last-backup recency vs. RPO).

**Pass criterion:** All in-scope workloads report RPO adherence = PASS.

---

## Gate 3 — Evidence captured and stored

**Check:** Each test restore has a complete **Test-Restore Record – Per-Workload – Evidence** entry — start/finish timestamps, recovery point identifier, restore target, operator, change reference, data-verification note, supporting screenshots/logs, and PASS/FAIL — held in the secure evidence store.

**How:** Audit the evidence store against the cycle's executed test restores; confirm no record is missing required fields.

**Pass criterion:** Every executed test restore has a complete, stored evidence record. Incomplete or missing records fail this gate.

---

## Gate 4 — Coverage completeness

**Check:** Coverage % per workload class and overall meets the agreed target (typically 100% of in-scope objects protected), and there are no unflagged **Protected = N** objects.

**How:** Review the coverage % in the **Coverage Baseline – Backup Estate – Assessment** and reconcile against `BACKUPVAL-Discovery.ps1` output.

**Pass criterion:** Coverage meets target with all gaps explicitly flagged and tracked.

---

## Gate 5 — Gaps and failures remediated

**Check:** Every coverage gap (Protected = N) and every failed/out-of-RTO test restore from the cycle has a remediation action recorded and either resolved or an accepted, time-bound exception.

**How:** Review open exceptions and the **Recoverability Assurance Report – Backup Estate – Reporting** remediation-status section; confirm `BACKUPVAL-Remediation.ps1` flagged items have been actioned.

**Pass criterion:** No unaddressed gaps or failures remain; any outstanding item has an authorized, dated exception with a remediation target.

---

## Gate 6 — Report produced and delivered

**Check:** The **Recoverability Assurance Report – Backup Estate – Reporting** for the cycle has been generated (from `BACKUPVAL-Report.ps1` data), formatted for client/audit, stored in the secure store, and delivered to the client.

**How:** Confirm the report exists for the period, contains coverage %, RPO/RTO adherence, pass rate, and remediation status, and is retained.

**Pass criterion:** Report produced, stored, and delivered for the cycle.

---

## Overall acceptance

The program passes a cycle only when **Gates 1–6 all pass**. Record the outcome and any exceptions in the **Recoverability Assurance Report – Backup Estate – Reporting**, and carry forward unresolved items as tracked exceptions into the next cycle's Operate phase.


---


# 6. Troubleshooting — Backup Validation & Recoverability Assurance Program

Common issues encountered across discovery, scheduling, restore execution, validation, and reporting, with likely causes and resolutions. Each entry is keyed to the phase where it typically surfaces.

---

## Discovery & coverage (Phase 1)

**`BACKUPVAL-Discovery.ps1` returns no backup items.**
- Cause: not connected to Azure, wrong subscription context, or no read access to the vault.
- Resolution: run `Connect-AzAccount`, confirm the correct subscription with `Get-AzContext` / `Set-AzContext`, and verify at least **Reader** on the Recovery Services vault. Re-check **portal.azure.com > Recovery Services vaults > (vault) > Backup items**.

**Live VMs/file shares exist but are not in the vault's Backup items.**
- Cause: those resources were created after the backup policy was set and were never added — a genuine coverage gap.
- Resolution: flag them **Protected = N** in the **Coverage Baseline – Backup Estate – Assessment** and remediate (enable backup) in Phase 7.

**M365 object count in the backup console differs from the tenant.**
- Cause: new mailboxes/sites not yet auto-added to a job, or licensing limits.
- Resolution: confirm the backup product's auto-add/processing rules and license count; add uncovered objects to a protection job.

---

## RPO/RTO (Phase 2)

**Desired RPO is shorter than the backup product can achieve.**
- Cause: the product's minimum backup interval exceeds the target.
- Resolution: either increase backup frequency (if supported/licensed) or renegotiate the RPO with the client and record the agreed, achievable value.

---

## Scheduling (Phase 3)

**A scheduled test has no available recovery point.**
- Cause: retention is shorter than the cadence, so the point expired before the test date (Requirement R11).
- Resolution: extend retention or shorten the cadence so a valid recovery point always exists at the scheduled date.

---

## Restore execution (Phase 4)

**Azure VM restore fails with an authorization error.**
- Cause: missing RBAC on the vault and/or restore-target resource group.
- Resolution: assign **Backup Operator** on the vault and **Virtual Machine Contributor** on the restore-target resource group (**IAM > Add role assignment**), then retry (Requirement R6).

**Restored Azure VM name/IP collides with a production resource.**
- Cause: restored into a shared resource group/network with **Replace existing** or a duplicate name.
- Resolution: always **Create new** into the isolated **restore-test resource group** and network with a distinct name (Phase 4e). Delete and re-run.

**Azure Files restore overwrote or threatened the source.**
- Cause: "Original location" selected instead of "Alternate location."
- Resolution: always choose **Alternate location** to a non-production share/folder (Phase 4f).

**M365 restore targets the original mailbox/site.**
- Cause: "restore in place" selected instead of restore to an alternate location.
- Resolution: re-run choosing the dedicated test recovery mailbox/site (the restore target); never restore in place during testing.

**Teams chat/posts did not restore.**
- Cause: the backup product may protect only channel files / SharePoint backing, not 1:1 chat or all post types.
- Resolution: confirm the product's documented Teams restore scope; record what is and isn't recoverable in the evidence and report; treat unsupported scope as a known limitation, not a test failure.

---

## Validation & evidence (Phase 5)

**`BACKUPVAL-Validation.ps1` reports FAIL on last-backup recency.**
- Cause: most recent recovery point is older than the RPO — a missed/failed backup.
- Resolution: investigate the backup job, trigger an on-demand backup (`BACKUPVAL-Remediation.ps1 -Apply`, with change authorization), and re-validate.

**Restore passed but exceeded RTO.**
- Cause: restore took longer than the target (large dataset, throttling, staging overhead).
- Resolution: mark the test **FAIL** for RTO, open an exception, and remediate (e.g. smaller restore granularity, faster restore method, or renegotiated RTO).

**Evidence record is incomplete.**
- Cause: missing timestamps, recovery-point ID, change reference, or verification note.
- Resolution: complete all required fields in the **Test-Restore Record – Per-Workload – Evidence** before storing; Gate 3 fails on incomplete records.

---

## Reporting (Phase 6)

**`BACKUPVAL-Report.ps1` shows coverage % below 100%.**
- Cause: unprotected in-scope objects remain.
- Resolution: confirm each gap in the baseline, remediate, and re-baseline; report open gaps with remediation status rather than hiding them.

**Report missing a workload's last test-restore date.**
- Cause: that workload has not been test-restored this cycle, or its evidence wasn't stored where the report reads it.
- Resolution: execute the missing test (Phase 4) and ensure evidence lands in the secure store the report draws from.

---

## Tooling (cross-cutting)

**Az or Microsoft Graph cmdlets not found.**
- Cause: modules not installed on the tooling host (Requirement R9).
- Resolution: `Install-Module Az` and `Install-Module Microsoft.Graph`, then re-run.

**Graph calls fail with insufficient privileges.**
- Cause: the signed-in identity lacks the required Graph scopes.
- Resolution: consent the needed read scopes for the operator identity and re-authenticate (`Connect-MgGraph`).


---


# 7. Best Practices — Backup Validation & Recoverability Assurance Program

These practices keep the program credible, safe, and continuously improving. Apply them throughout the seven phases.

## Treat retention as not-backup

- Never count Microsoft 365 **retention policies, Recycle Bin, or Litigation Hold** as backup. They are retention controls with finite, administratively mutable windows and do not protect against ransomware-encrypted synced files, malicious deletion past the window, or tenant loss. Recoverability is proven only against an **independent** third-party backup copy.

## Prove, don't assume

- A backup job marked "success" is a copy confirmation, not a restore guarantee. **Only a completed test restore proves recoverability.** Let the test-restore cadence — not job status — be the measure of assurance.
- Rotate test restores so that, over a full cycle, **every** in-scope workload is actually restored at least once. Sampling one workload forever leaves the rest unverified.

## Protect production at all costs

- Always restore to the **non-production restore target / sandbox**. For Azure VMs, **Create new** into an isolated resource group and network — never **Replace existing**. For Azure Files and M365 workloads, always restore to an **alternate location**, never overwrite the source.
- Keep restored test VMs off the production network to avoid IP/name collisions and lateral exposure, and **delete restored test resources** after validation to control cost.

## Measure against agreed objectives

- Test restores are meaningless without **RPO/RTO targets** to grade them. Agree targets per workload class with the client, and reconcile desired objectives with what the backup product can actually achieve.
- Track **RPO adherence** (data age of recovery points) and **RTO adherence** (restore elapsed time) every cycle; a passing restore that exceeds RTO is still a FAIL.

## Capture audit-grade evidence

- Complete a **Test-Restore Record – Per-Workload – Evidence** for every test with timestamps, recovery-point ID, restore target, operator, change reference, and a data-verification note plus supporting screenshots/logs.
- Store evidence in a secure, access-controlled, retained location. Set retention to outlast the audit/insurer window. Evidence that expires before review is worthless.

## Keep coverage honest as the estate drifts

- Re-baseline the **Coverage Baseline – Backup Estate – Assessment** whenever mailboxes, sites, VMs, or file shares are added or removed. New resources frequently fall outside existing backup policies — measure coverage continuously, never once.
- Run `BACKUPVAL-Discovery.ps1` regularly to surface unprotected resources between formal re-baselines.

## Default to read-only and authorized change

- Run discovery, validation, and reporting **read-only**. Run remediation in **`-WhatIf`** by default and only **`-Apply`** an on-demand backup after change-control authorization.
- Require a **change reference** on every test restore and every triggered backup so all activity is traceable.

## Report for the audience

- Write the **Recoverability Assurance Report – Backup Estate – Reporting** for client and auditor consumption: lead with coverage %, RPO/RTO adherence, and pass rate; include open exceptions and remediation status. Track trends across cycles — a rising coverage % and pass rate is the proof the program is working.

## Close every gap and failure

- Treat each coverage gap and failed restore as an action item, not a footnote. Resolve it or record an authorized, time-bound exception. Unaddressed gaps undermine the entire assurance claim.


---


# 8. Deliverables Summary — Backup Validation & Recoverability Assurance Program

This section lists everything included in the program package. Together these deliverables let an IT team stand up, run, and report a recoverability assurance program for Microsoft 365 and Azure workloads.

## Documentation

| # | Document | Purpose |
|---|----------|---------|
| 1 | **Solution Overview** (`01-solution-overview.md`) | What the program is, why backups must be proven, the named objects, and the seven-phase model. |
| 2 | **Requirements** (`02-requirements.md`) | All prerequisites (R1–R11) with Description / Why / Verify / Implement-if-missing. |
| 3 | **Global Requirements — Backup & DR Solutions** (`global-requirements-backup-dr-solutions.md`) | Category-wide prerequisites shared across all Backup & DR solutions. |
| 4 | **Implementation** (`03-implementation.md`) | The seven phases with full navigation paths, per-workload test-restore procedures, evidence capture, and reporting. |
| 5 | **Testing & Validation** (`05-testing.md`) | The acceptance gates that confirm the program is operating correctly. |
| 6 | **Best Practices** (`07-best-practices.md`) | Operating guidance to keep the program safe, credible, and improving. |
| 7 | **Troubleshooting** (`06-troubleshooting.md`) | Common failures and resolutions across discovery, restore, validation, and reporting. |
| 8 | **Executive Summary** (`executive-summary.md`) | Business-level summary for decision-makers. |

## Scripts

Five PowerShell scripts (Az / Microsoft Graph where applicable). All ship with standard header blocks and a neutral `.NOTES` line. Discovery, validation, and reporting are **read-only**; remediation defaults to read-only / `-WhatIf`.

| # | Script | Purpose |
|---|--------|---------|
| 1 | **`BACKUPVAL-Discovery.ps1`** | Inventory backup coverage — Azure Recovery Services vault backup items and protected vs. unprotected resources. Read-only. |
| 2 | **`BACKUPVAL-Validation.ps1`** | Verify last-backup recency vs. RPO and last successful restore-test recency vs. cadence; emit PASS/FAIL. Read-only. |
| 3 | **`BACKUPVAL-Report.ps1`** | Produce the recoverability assurance report data — coverage %, RPO adherence, last test-restore per workload — to CSV. Read-only. |
| 4 | **`BACKUPVAL-Remediation.ps1`** | Flag unprotected resources and trigger an on-demand backup for a named item. Read-only / `-WhatIf` by default; `-Apply` to act. |
| 5 | **`BACKUPVAL-Set-RestoreTestSchedule.ps1`** | Scaffold and track the restore-test schedule rotation. `-WhatIf` preview. |

## Named program objects

These artifacts are produced/maintained by running the program (templates referenced throughout the docs):

- **Coverage Baseline – Backup Estate – Assessment** — inventory of in-scope workloads and protection status.
- **Restore-Test Schedule – Backup Estate – Cadence** — the test-restore rotation plan.
- **Test-Restore Record – Per-Workload – Evidence** — the per-test evidence record.
- **Recoverability Assurance Report – Backup Estate – Reporting** — the periodic client/audit report.

## Visual asset

- **`BACKUPVAL-hero.png`** — hero image for the solution listing.
