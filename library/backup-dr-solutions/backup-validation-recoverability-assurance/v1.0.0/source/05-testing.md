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
