# 5. Testing & Validation — Azure Backup & Site Recovery — Deployment & Configuration

Testing confirms three things: the **vaults are hardened**, the **backup policies actually protect
the estate**, and **recovery works** (restore + failover) within target. Use the scripts by name;
each is read-only unless explicitly gated. Record results as deployment evidence in the secure
store (GR4).

> **Boundary.** This section validates the *deployment* (does it work, once). The ongoing,
> scheduled discipline of proving restores across the estate over time is the separate **Backup
> Validation & Recoverability Assurance** program — do not duplicate that cadence here.

---

## Test 1 — Vault hardening

**Procedure:** Run **`BCKDR-Validate.ps1`** and check the portal (**Recovery Services vaults >
`rsv-backup-core-prod` > Properties**, and **Backup vaults > `bvault-backup-object-prod` >
Properties**).

**Pass criteria:**
- **Soft delete** is **Enabled** on both vaults, with the retention window from R3.
- **Immutability** is in the state agreed in R3 (enabled during pilot; locked only after Stage 4).
- Vaults exist in the intended region and resource group.

---

## Test 2 — Policy existence and assignment

**Procedure:** Run **`BCKDR-Validate.ps1`**; cross-check **`rsv-backup-core-prod` > Backup items**.

**Pass criteria:**
- All four policies exist: **VM Backup Policy – Daily-30d – Configure**, **Files Backup Policy –
  Daily-30d – Configure**, **SQL Backup Policy – Log-15m – Configure**, **Blob Backup Policy –
  Vaulted-30d – Configure**.
- Every in-scope pilot (then, post-Expand, estate) item is assigned to the correct policy —
  **no in-scope item is unprotected**.
- Schedule/retention on each policy matches the RPO/RTO decisions (R1). For SQL-in-VM, the **log
  backup interval** (e.g. 15 min) matches the SQL RPO.

---

## Test 3 — First successful recovery point

**Procedure:** For each pilot item, **Backup items > (item) > Last backup status**; or read
`BCKDR-Validate.ps1` output.

**Pass criteria:**
- Each pilot item shows a **successful** recent recovery point (data age within the RPO).
- No item is stuck in **Warning** / initial-backup-never-completed.

---

## Test 4 — Restore proof (into the isolated sandbox)

**Procedure:** Perform one **File Recovery** restore from a pilot VM recovery point into
**DR Test Sandbox – Isolated – Validate** (`rg-dr-test-sandbox`). Confirm a known file is present
and readable. **Never restore over production.**

**Pass criteria:**
- The restore completes within the workload's **RTO**.
- The restored file is present and its content is intact.
- Nothing in production was modified.

---

## Test 5 — ASR replication health and RPO

**Procedure:** Run **`BCKDR-Validate.ps1`**; check **`rsv-backup-core-prod` > Site Recovery >
Replicated items**.

**Pass criteria:**
- Pilot (then estate) DR-tier items are **Protected** with a healthy replication status.
- Current **RPO** is at or below the target set in **ASR Replication Policy – A2A-RPO – Configure**.
- No replication errors or "RPO exceeded" alerts are open.

---

## Test 6 — Recovery-plan test failover

**Procedure:** Run a **non-disruptive test failover** of **Recovery Plan – Tier1 App – Pilot**
(`rp-tier1-app`) into `rg-dr-test-sandbox` (portal **Test Failover**, or
`BCKDR-Validate.ps1 -RunTestFailover`). **Always run Cleanup test failover afterward.**

**Pass criteria:**
- Groups fail over in the defined order (e.g. DB → app → web); pre/post actions run successfully.
- Failed-over VMs boot in the isolated network and the application responds.
- Total elapsed time is within the application's **RTO**.
- Production is unaffected throughout; **Cleanup test failover** removes all test resources.

---

## Test 7 — Alerting

**Procedure:** Confirm **Backup & DR Alert Rule – Health – Expand** (`alert-backupdr-health`) is
configured and fires. Trigger a benign test (e.g. an alert-rule test notification or a controlled
failed-job condition in a lab).

**Pass criteria:**
- Backup-failure, restore-failure, and ASR-health/RPO-breach alerts are enabled.
- At least one test alert reaches the action group destination (email/Teams/ITSM).

---

## Evidence to capture

For each test, record: date/time, operator, the object name(s) involved, the recovery point used,
elapsed time vs. RTO, data age vs. RPO, PASS/FAIL, and the change reference (GR5). Store in the
secure evidence store (GR4). Run **`BCKDR-Report.ps1`** to compile the estate-wide posture summary
for the handover pack. Any FAIL routes to Section 6 (Troubleshooting) before go-live.
