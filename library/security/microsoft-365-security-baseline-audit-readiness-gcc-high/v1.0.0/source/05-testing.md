# Testing & Validation — Microsoft 365 Security Baseline & Audit Readiness (Government / GCC High)

Testing is **gate-based**: each phase has a pass/fail check you must clear before moving on. All checks
use the **sovereign `*.us` portals** and the **US Gov Graph** (`-Environment USGov`). If a check fails,
stop and go to `06-troubleshooting.md` before proceeding.

> **Golden rule for GCC High:** a check "failing" is sometimes actually **feature parity** — the
> Commercial control you expected may simply not exist in GCC High. Before treating a missing
> recommendation as a defect, confirm against `gcc-high-parity-notes.md` (**verify for GCC High**).

## Test environment sanity checks (run first)

| # | Check | How | Pass |
| --- | --- | --- | --- |
| E1 | You're in the sovereign cloud | `https://security.microsoft.us` loads your tenant | Portal shows your GCC High org, Secure Score visible |
| E2 | Graph is on US Gov | PowerShell: `(Get-MgContext).Environment` after `Connect-MgGraph -Environment USGov` | Returns `USGov` |
| E3 | Graph root is correct | `Get-MgEnvironment` | `USGov` row shows `https://graph.microsoft.us` |
| E4 | Compliance portal reachable | `https://compliance.microsoft.us` → Compliance Manager | Overall score + assessments render |

If **E2** returns anything other than `USGov`, **every** subsequent script result is invalid — you are
querying the wrong cloud. Disconnect (`Disconnect-MgGraph`) and reconnect with `-Environment USGov`.

## Phase 0 — Assess gate

| # | Check | How | Pass |
| --- | --- | --- | --- |
| T0.1 | Baseline Secure Score captured | `security.microsoft.us` → Secure Score; screenshot | Score, %, action count recorded |
| T0.2 | Baseline Compliance score captured | `compliance.microsoft.us` → Compliance Manager | Overall score recorded |
| T0.3 | Discovery ran clean | `.\M365SECG-Discovery.ps1` | Completes; output file written; connected as `USGov` |
| T0.4 | No changes made | Review discovery is read-only | No write operations performed |

**Gate 0 passes when** T0.1–T0.4 are all green.

## Phase 1 — Configure gate

| # | Check | How | Pass |
| --- | --- | --- | --- |
| T1.1 | Pilot group exists | `entra.microsoft.us` → Groups → `SEC-Baseline-Pilot` | Group present with pilot members |
| T1.2 | Assessment created | `compliance.microsoft.us` → Compliance Manager → Assessments | Named assessment (e.g. `GCCHigh-DPB-Baseline`) present |
| T1.3 | Backlog is GCC-High-real | Secure Score → Improvement actions | Backlog contains only actions that exist in *your* tenant |
| T1.4 | Change ticket approved | Ticketing system | Approver, window, pilot scope, rollback documented |

**Gate 1 passes when** T1.1–T1.4 are all green.

## Phase 2 — Pilot gate

| # | Check | How | Pass |
| --- | --- | --- | --- |
| T2.1 | Policies scoped to pilot | `entra.microsoft.us` → policy assignment | Assignment = `SEC-Baseline-Pilot`, **not** All users |
| T2.2 | Named consistently | Policy list | Names reused per plan (e.g. `CA-Baseline-Admins-MFA`) |
| T2.3 | No parity-blocked actions staged | Cross-check parity notes | No action depends on Threat Experts / enterprise IoT (absent in GCC High) |

**Gate 2 passes when** T2.1–T2.3 are all green **and** no tenant-wide assignment was made.

## Phase 3 — Validate gate

| # | Check | How | Pass |
| --- | --- | --- | --- |
| T3.1 | Validation script PASS | `.\M365SECG-Validation.ps1` | Every check reports PASS for batch 1 |
| T3.2 | Score moved | `security.microsoft.us` → Secure Score → History | Increase visible (allow ~24–48h refresh; **verify for GCC High**) |
| T3.3 | Assessment progressed | `compliance.microsoft.us` → Compliance Manager | Batch-1 improvement actions show implemented/tested |
| T3.4 | No user lockout | Pilot users sign in & reach apps | All pilot users unaffected |

**Gate 3 passes when** T3.1–T3.4 are all green. **If T3.4 fails, execute rollback immediately.**

## Phase 4 — Expand gate (per wave)

| # | Check | How | Pass |
| --- | --- | --- | --- |
| T4.1 | Wave scoped correctly | `entra.microsoft.us` / `intune.microsoft.us` | Assignment = current wave cohort only |
| T4.2 | Re-validation PASS | `.\M365SECG-Validation.ps1` | PASS for the widened scope |
| T4.3 | No lockout in wave | Sample users in the new cohort | All can sign in |
| T4.4 | Report generated | `.\M365SECG-Report.ps1` | Point-in-time report produced and archived |

**Gate 4 passes when** T4.1–T4.4 are green **for each wave**. Do not start the next wave until the
current one passes.

## Remediation script test (if used)

| # | Check | How | Pass |
| --- | --- | --- | --- |
| RM.1 | Default is safe | Run `.\M365SECG-Remediation.ps1` with no switches | Runs in `-WhatIf`; only previews, changes nothing |
| RM.2 | Preview matches ticket | Read the `-WhatIf` output | Previewed change equals the approved action, scoped to pilot |
| RM.3 | Execute is deliberate | Re-run with `-Execute` | Applies only after review; connected as `USGov` |
| RM.4 | Post-change validation | `.\M365SECG-Validation.ps1` | PASS; no lockout |

## End-to-end acceptance

The solution is validated end-to-end when:

1. Baseline captured (Gate 0), and a **later** report shows a **measurable Secure Score increase** on
   the GCC High tenant.
2. At least one **Compliance Manager assessment** shows progressed improvement actions.
3. Every change went **pilot → validate → expand** with **no unresolved lockouts**.
4. All script runs confirm `(Get-MgContext).Environment` = **`USGov`** (never Commercial).
5. Evidence (discovery, validation, report outputs + screenshots) is archived for audit.
