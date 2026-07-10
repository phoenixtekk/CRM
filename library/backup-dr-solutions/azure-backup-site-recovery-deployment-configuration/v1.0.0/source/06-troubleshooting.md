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
