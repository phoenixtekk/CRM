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
