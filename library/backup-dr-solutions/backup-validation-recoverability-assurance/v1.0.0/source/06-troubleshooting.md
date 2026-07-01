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
