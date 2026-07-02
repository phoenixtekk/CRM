# Deliverables Summary

Everything included in this solution, and how the pieces fit the **measure → isolate → fix →
re-measure** method.

## Documents

| Document | What it gives you |
|----------|-------------------|
| **01 — Solution Overview** | The performance/reliability model (boot → sign-in/profile → steady-state resource use → stability → storage health), the signals to measure, and the root-cause tree. |
| **02 — Requirements** | Every prerequisite (endpoint/admin access, event & counter access, storage/SMART readability, Endpoint analytics where available, Graph for targeting) with Description / Why / Verify / Implement-if-missing. |
| **Global Requirements — Infrastructure** | The category-level prerequisites (Entra tenant, Intune, admin roles, enrollment, pilot group, supported Windows, network). |
| **03 — Diagnostic Playbook** | The symptom tree with exact measurements and pass/fail gates per branch: slow boot, slow sign-in/profile, high CPU/RAM/disk, crashes/bugchecks, storage/SSD health. |
| **05 — Testing** | The consolidated measured pass/fail gates — used to confirm both the cause and the cure. |
| **06 — Troubleshooting** | What to do when the tooling itself does not behave (no events, corrupt counters, SMART unavailable, remote-run failures). |
| **07 — Best Practices** | Baselining and repeatable performance triage as an operating standard. |

## PowerShell scripts

All scripts share a standard header (PURPOSE / HOW TO RUN / EXPECTED RESULTS). Discovery, Validation,
and Report are **read-only**. Remediation and Set-ScopeTargeting default to a **preview (`-WhatIf`)**
mode so nothing changes until you decide.

| Script | Role in the method | Read-only? |
|--------|--------------------|-----------|
| **WINPERF-Discovery.ps1** | Quick sweep of performance/reliability signals; confirms prerequisites (T1) and flags where to look. | Yes |
| **WINPERF-Validation.ps1** | Deep per-device measurement — boot, sign-in/profile, CPU/RAM/disk over a window, crashes, storage health — evaluated against the pass/fail gates. | Yes |
| **WINPERF-Report.ps1** | Fleet-wide performance/reliability roll-up from collected results; highlights FAIL rows and trends. | Yes |
| **WINPERF-Remediation.ps1** | Safe, reversible fixes for the common causes — startup bloat, temp/disk pressure, profile cache — **defaults to `-WhatIf`**. | Preview by default |
| **WINPERF-Set-ScopeTargeting.ps1** | Builds/populates the pilot or rollout Entra group via Microsoft Graph so measurement and remediation are scoped — **defaults to `-WhatIf`**. | Preview by default |

## How to use them together

1. **WINPERF-Discovery.ps1** across the fleet → who is slow / unstable, and are prerequisites ready.
2. **WINPERF-Set-ScopeTargeting.ps1** → put the affected devices in a scoped pilot group.
3. **WINPERF-Validation.ps1** on a device → the measured cause, mapped to a playbook branch.
4. **WINPERF-Remediation.ps1 -WhatIf** → preview the safe fix, then apply.
5. **WINPERF-Validation.ps1** again → re-measure and confirm the gate now passes.
6. **WINPERF-Report.ps1** → record the outcome and watch the fleet trend.
