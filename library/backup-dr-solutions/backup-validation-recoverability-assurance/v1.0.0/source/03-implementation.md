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
