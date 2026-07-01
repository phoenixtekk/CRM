# 5. Testing Guide — SCCM Task Sequence Troubleshooting & Status Message Analysis

Run after you build the query and pilot the runbook (Implementation Steps 2 and 9). These tests
prove the runbook actually diagnoses and resolves real failures — not that the doc reads well.

## Test 1 — Deployment state is visible
**Do:** Console → **Monitoring → Deployments →** the OSD deployment **→ View Status**, or run
`SCCMTS-Discovery.ps1`.
**Expected:** The failing device(s) and their last state (`Failed`/`Error`) are listed.

## Test 2 — Status message query returns the execution messages
**Do:** Run the `TS Execution Errors – OSD – Triage` query for the failing device and time window.
**Expected:** Messages `11123`/`11170`/`11124` appear; the `11124`/`11170` message names the failing
step and carries an exit/error code.

## Test 3 — Exit code captured and mapped
**Do:** Record the exit code from Test 2; check it against the table in `01-solution-overview.md` (or
run `SCCMTS-Report.ps1`).
**Expected:** The code maps to a failure class (content / driver / network / app / reboot / variable).

## Test 4 — Correct `smsts.log` opened and root cause found
**Do:** Open the phase-correct `smsts.log` (WinPE vs. full OS path) in CMTrace; read up from the last
error line.
**Expected:** The log confirms the step, the command, and the inner reason consistent with the exit code.

## Test 5 — Class fix applied
**Do:** Apply the fix for the identified class (Implementation Step 6).
**Expected:** The blocking condition is corrected (content on a reachable DP, right driver/boot NIC,
fixed installer switch/detection, boot order/BitLocker, or corrected variable/condition).

## Test 6 — Re-run succeeds
**Do:** Re-run the task sequence on the piloted device; run `SCCMTS-Validation.ps1`.
**Expected:** Status message **`11127`** and step exit **`0`** (or `3010`); the deployment shows
**Success** for the device.

## Test 7 — Failure summary report
**Do:** Run `SCCMTS-Report.ps1` for the collection.
**Expected:** A clean failure summary with an exit-code breakdown and the affected devices.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Diagnosis pass** | Tests 1–4 pass: state seen, query returns the message, exit code mapped, log confirms the cause |
| **Resolution pass** | Tests 5–6 pass: the class fix is applied and the re-run reports `11127` / exit `0` |
| **Runbook pass** | The full loop is validated on **two** distinct real failures (Implementation Step 9) |
