# 5. Testing & Validation — Epic Go-Live & Command Center Endpoint Readiness Playbook

Testing in this playbook has two layers. **Solution validation** proves the fleet meets the readiness standard and feeds the go/no-go gate (the validation sweep). **Operational rehearsal** proves the command center, triage runbook, and escalation paths work *before* the floor goes live. Both are covered here. All tests are read-only unless explicitly a remediation rehearsal, which runs on the test device first (GR6).

---

## 1. The validation sweep (per-device PASS/FAIL)

The validation sweep is the primary test that proves device readiness. Run **`EPICGOLIVE-Validation.ps1`** against the **Readiness Device Group – Clinical Fleet – Validation**; it returns a PASS/FAIL per device against the **Endpoint Readiness Checklist – Clinical Fleet – Pre-Go-Live**.

For each device, confirm the sweep evaluates:

| # | Check | PASS condition |
|---|-------|----------------|
| 1 | Enrollment | Device enrolled in Intune, expected managed identity in Entra |
| 2 | Compliance | Compliant with the assigned compliance policy |
| 3 | Epic client version | Installed version equals the designated version (exact string) |
| 4 | Imprivata agent | Agent present and reporting healthy (for classes requiring tap) |
| 5 | Peripherals | Expected peripheral set for the device class enumerates |
| 6 | Printing | Required printer(s)/pathway present (functional test confirmed in sweep) |
| 7 | Login time | Measured login time at or below the class target |
| 8 | Check-in | Device has checked in recently (not stale/offline) |

**How to run and confirm:**
1. Connect to Microsoft Graph with the read-only scopes.
2. Run `EPICGOLIVE-Validation.ps1` scoped to the readiness group.
3. Confirm every device returns a clear PASS or FAIL with a reason for each FAIL.
4. Re-run after any late fix — the sweep is idempotent and read-only.

---

## 2. Readiness scorecard (aggregate evidence)

Run **`EPICGOLIVE-Report.ps1`** to roll the sweep results into the **Readiness Scorecard – Clinical Fleet – Validation** (CSV).

Confirm the scorecard shows:
- Per-device PASS/FAIL with the specific failing check(s).
- Roll-ups: percent PASS by device class, by unit/department, and overall.
- A count of unresolved **safety-critical** failures (wristband/label printing on affected units, tap-and-go for medication administration).
- Only device/posture metadata — **no ePHI** (GR3). Verify this before sharing the export.

The scorecard is the evidence the go/no-go gate reads. Confirm its numbers reconcile to the in-scope denominator from R1 (the count of devices reported equals the agreed inventory count).

---

## 3. Functional spot-tests (human-in-the-loop)

Some checks need a person at the device. During validation, walk a representative sample per device class and confirm hands-on:

1. **Tap-and-go** — badge tap logs the test user into a usable Epic session within the login-time target; fast user switching behaves per policy.
2. **Manual-login fallback** — credential login works when tap is bypassed (the triage runbook depends on this).
3. **Wristband/label print** — a test wristband/label prints correctly through the intended pathway.
4. **Document print** — a test document prints to the mapped document printer.
5. **Scanner** — a barcode scan registers; **signature pad** captures; **document scanner** scans (per the device class's expected peripherals).

Record results against the readiness checklist. Any safety-critical functional failure (wristband print, med-admin tap) is a go/no-go blocker until resolved.

---

## 4. Test-device rehearsal of remediation (safe-change proof)

Before any `-Apply` remediation touches the fleet, prove it on the test device (GR6):

1. Run `EPICGOLIVE-Remediation.ps1` with default `-WhatIf` against the test device; review the planned actions.
2. Run with `-Apply` against the test device only.
3. Confirm the device reaches the intended state (re-run `EPICGOLIVE-Discovery.ps1`).
4. Confirm the rollback (GR7) reverses the change on the test device.
5. Only then expand to the readiness group inside an approved window (GR4).

---

## 5. Command-center operational rehearsal (dry run)

Test the operating model before go-live, not during it.

1. **Roster walkthrough** — confirm the **Command Center Roster – Endpoint Support – Hypercare** names real people for every role and shift, including nights/weekends, and that each person knows their tier and coverage.
2. **Dispatch dry run** — inject sample issues (one per triage category: login/SSO, printing, not-enrolled, slow) and confirm each flows report → dispatcher → correct tier within the target response time.
3. **Triage runbook walkthrough** — have ATE staff execute each runbook entry against the test device(s) and confirm the steps are accurate and fast.
4. **Escalation drill** — escalate a simulated safety-critical issue up the ladder (ATE → command-center lead → Epic program; and to the right Tier-3 vendor/app team) and confirm it reaches the right person on the first hop.
5. **Comms cadence** — run one practice status huddle using the real reporting format and the live counts from `EPICGOLIVE-Report.ps1`.

Capture any gap (a role unstaffed for nights, a dispatch path that misroutes, a runbook step that's wrong) and fix it before the activation.

---

## 6. Go/no-go gate validation

Confirm the **Go/No-Go Gate – Endpoint Domain – Activation** is ready to be walked:
1. Thresholds are explicit (minimum percent PASS; zero unresolved safety-critical failures).
2. The decision authority is named and available at the scheduled review.
3. The conditional-go tracking mechanism exists (conditions carry into hypercare with owners).
4. The gate reads from the readiness scorecard, and the scorecard is current.

---

## 7. Exit-criteria validation (hypercare → steady state)

Confirm the **Hypercare Exit Criteria – Endpoint Domain – Handover** are measurable and instrumented:
1. The metrics they depend on (endpoint ticket volume, open safety-critical count) are actually being tracked during hypercare.
2. Service-desk leadership has agreed to the criteria and the handover package contents.
3. There is a defined "measure, then decide" review rather than an arbitrary end date.

---

## Validation checklist (summary)

- [ ] Validation sweep returns PASS/FAIL for 100% of in-scope devices, reasons on every FAIL.
- [ ] Scorecard reconciles to the R1 inventory count; contains no ePHI.
- [ ] Safety-critical functional tests (wristband print, med-admin tap) pass on every affected unit.
- [ ] Remediation rehearsed and rolled back on the test device before any fleet `-Apply`.
- [ ] Command-center roster fully staffed including off-hours; dispatch dry run passed.
- [ ] Triage runbook walked through and accurate; escalation drill reached the right people.
- [ ] Go/no-go gate thresholds explicit, authority named, scorecard current.
- [ ] Hypercare exit criteria measurable and instrumented; service desk agreed.
