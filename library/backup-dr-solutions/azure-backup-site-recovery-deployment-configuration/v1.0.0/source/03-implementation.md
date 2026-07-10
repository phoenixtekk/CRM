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
