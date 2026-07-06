# 5. Testing Guide — Oracle C2M & WebLogic Patching & Upgrade Runbook (to 25.4)

Run in each environment after the apply (Runbook Phase C) and before promoting the change up. Each
test confirms one part of the patch/upgrade landed correctly and the environment is healthy. The
pass/fail gate at the end is the go/no-go for promoting to the next environment.

## Test 1 — Backup was verified before apply (readiness)
Do: Confirm the Phase A backups exist and a restore was proven; run
`OC2MPATCH-Validation.sh --pre-check`.
Expected: Database restore point/RMAN, Oracle Home, domain, and OUAF config backup markers are present;
the pre-check reports PASS. (This test gates the apply, not the promotion — it must have passed before
Phase B.)

## Test 2 — WebLogic patch inventory shows the change
Do: Run `opatch lsinventory` from the WebLogic Oracle Home (or read it via `OC2MPATCH-Validation.sh`).
Expected: The expected patch number(s) appear as applied for a patch, or the expected release/OPatch
level for an upgrade; no unexpected conflicts.

## Test 3 — C2M / OUAF inventory shows the change
Do: Run `OC2MPATCH-Validation.sh` and check the OUAF fix/version inventory.
Expected: The expected C2M/OUAF fix or target release (e.g. 25.4) shows as installed; the OUAF
error-checker reported clean at install.

## Test 4 — Managed servers reach RUNNING
Do: After `spl.sh -start` and the WebLogic start, check server state via WLST or the Administration
Console (or `OC2MPATCH-Validation.sh`).
Expected: The admin server and all managed servers are RUNNING; no server stuck in ADMIN/FAILED.

## Test 5 — Database is at the expected level
Do: Run the database checks in `OC2MPATCH-Validation.sh` (release/patch-level query against the C2M
schema).
Expected: The database component reports the expected post-patch/upgrade level; no invalid objects
introduced by the change.

## Test 6 — C2M functional smoke test
Do: Log in to C2M and exercise a representative transaction path for the environment (a read and a
core business function per your smoke-test set).
Expected: The application responds normally; no new errors in the logs attributable to the change.

## Test 7 — Coverage report is clean and matches baseline intent
Do: Run `OC2MPATCH-Report.sh` and compare against the Phase A baseline from `OC2MPATCH-Discovery.sh`.
Expected: The report shows the intended patch/version delta per node and no unexpected drift between
nodes in the environment.

## Test 8 — Rollback path is confirmed available
Do: Confirm (do not execute unless a gate fails) the documented rollback for this change: `opatch
rollback` / OUAF back-out for a patch, or restore-from-backup for an upgrade.
Expected: The rollback steps are written into the change record and the backup needed for restore is
present and verified.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Apply gate (Gate A) | Test 1 passes — verified backups present — before any Phase B apply |
| Promote gate (Gate C) | Tests 2–7 pass in this environment and Test 8 (rollback available) is confirmed, before promoting the change to the next environment up |
| Production gate | Every lower environment passed its promote gate; Tests 2–7 pass in Production inside the approved window |
