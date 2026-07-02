# Testing — Measured Pass/Fail Gates

Troubleshooting is only "done" when a measurement proves it. This section is the single source of
**pass/fail gates**: run the check, read the value, compare to the gate. Use it twice — once to
confirm the *cause* (a failing gate), and again after the fix to confirm the *cure* (a passing gate).

The gates below are sensible enterprise defaults. Where you have an Intune **Endpoint analytics**
baseline (requirement R5), tune each threshold to your fleet's own distribution and record the value
you chose.

---

## T1. Prerequisite readiness gates

Run before any measurement. All must PASS or the numbers cannot be trusted.

| Check | Command / location | PASS |
|-------|--------------------|------|
| Elevation | `IsInRole(Administrator)` (R1) | `True` |
| Diagnostics-Performance log readable | `Get-WinEvent -LogName '...Diagnostics-Performance/Operational' -MaxEvents 1` | returns an event |
| System / Application logs readable | `Get-WinEvent -LogName System -MaxEvents 1` | returns an event |
| Counters readable | `Get-Counter '\Processor(_Total)\% Processor Time' -MaxSamples 1` | returns a sample |
| Storage health readable | `Get-PhysicalDisk` | lists disk(s) with HealthStatus |
| PowerShell version | `$PSVersionTable.PSVersion` | ≥ 5.1 |

**WINPERF-Discovery.ps1** performs T1 automatically and reports READY / NOT READY.

---

## T2. Boot performance gate (Branch A)

| Metric | Source | PASS | FAIL |
|--------|--------|------|------|
| `BootTime` | Diag-Perf event 100 | ≤ 60,000 ms (SSD) | > 60,000 ms |
| Repeated slow driver (102) | Diag-Perf | none recurring | same driver across boots |
| Repeated slow service (103) | Diag-Perf | none recurring | same service across boots |

Re-test after **two** reboots (the first re-baselines).

---

## T3. Sign-in / profile gate (Branch B)

| Metric | Source | PASS | FAIL |
|--------|--------|------|------|
| Sign-in to responsive desktop | Endpoint analytics / User Profile Service log | ≤ 30 s | > 30 s |
| Startup app count | Run keys + Startup folders + logon tasks | ≤ 10 (default) | well above baseline |
| Profile size | `Win32_UserProfile` | reasonable for fleet | oversized / growing |

Re-test with a fresh sign-out / sign-in.

---

## T4. Steady-state resource gates (Branch C)

Sampled over a ~60-second window.

| Resource | Counter | PASS | FAIL |
|----------|---------|------|------|
| CPU | `\Processor(_Total)\% Processor Time` (avg) | < 70% | ≥ 85% sustained |
| Memory | `\Memory\% Committed Bytes In Use` | < 80% | ≥ 90% |
| Memory | `\Memory\Available MBytes` | comfortably > 0 | near 0 (constant paging) |
| Disk | `\PhysicalDisk(_Total)\% Disk Time` (avg) | < 80% | ~100% sustained |
| Disk | `\PhysicalDisk(_Total)\Current Disk Queue Length` | < 2 sustained | ≥ 2 sustained |

A single named process may not exceed the gate on its own for a PASS.

---

## T5. Stability gate (Branch D)

| Metric | Source | PASS | FAIL |
|--------|--------|------|------|
| Bugchecks (Stop) | System event 1001 | none in last 14 days | any in window |
| Unexpected shutdowns | System event 41 | none unexplained | recurring |
| Repeated app crash/hang | Application event 1000 / 1002 | no repeated faulting module | same module repeating |

A bugcheck fix passes only by **absence over the 14-day window**, not immediately.

---

## T6. Storage health gate (Branch E)

| Metric | Source | PASS | FAIL |
|--------|--------|------|------|
| Health status | `Get-PhysicalDisk` HealthStatus | Healthy | Warning / Unhealthy |
| Failure prediction | `MSStorageDriver_FailurePredictStatus` | False | True |
| Free space | `Get-Volume` (free ÷ size) | ≥ 15% | < 15% |

A FAIL on failure prediction or health status is a **hardware** replacement, not a software fix.

---

## T7. Whole-solution acceptance

The engagement passes when:

1. Every device in scope has been run through **WINPERF-Discovery** + **WINPERF-Validation** and has a
   recorded T1 READY result.
2. Each reported symptom maps to a **named branch and a measured cause** (no "unknown / rebooted it").
3. Every applied fix has a **before/after** measurement showing the failing gate now passes (or, where
   the cause is hardware, a documented replacement/upgrade recommendation with the evidence).
4. **WINPERF-Report.ps1** produces a fleet roll-up with no unexplained FAIL rows.
