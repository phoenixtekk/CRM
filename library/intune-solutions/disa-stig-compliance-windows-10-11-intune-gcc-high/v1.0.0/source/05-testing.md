# Testing & Validation — Government / GCC High edition

Testing in this solution is **gate-based**: each phase of *Assess → Configure → Pilot → Validate → Expand* has explicit **pass/fail** criteria, and you do not advance until the gate passes. All validation runs against the **US Government cloud** — the read-only scripts connect with **`-Environment USGov`** (GCC High) or **`-Environment USGovDoD`** (DoD).

> The read-only trio — **`STIGG-Discovery.ps1`**, **`STIGG-Validation.ps1`**, **`STIGG-Report.ps1`** — make **no changes**. Run them freely. `STIGG-Remediation.ps1` and `STIGG-Set-ScopeTargeting.ps1` default to **`-WhatIf`** and only change state when you re-run with `-WhatIf:$false`.

---

## Pre-flight test — you are in the right cloud

| Check | How | Pass |
| --- | --- | --- |
| Sovereign portal | Load `https://intune.microsoft.us` | Loads your Gov tenant; authority is `login.microsoftonline.us` |
| Graph environment | `Get-MgEnvironment` | `USGov` **and** `USGovDoD` listed |
| Graph connect | `Connect-MgGraph -Environment USGov -Scopes "DeviceManagementConfiguration.Read.All"` then `Get-MgContext` | Shows Gov account; **no** `graph.microsoft.com` in play |
| Endpoints | From a device, reach `*.manage.microsoft.us`, `login.microsoftonline.us` | Reachable; **not** SSL-inspected |

**Fail action:** if any check points at `.com`, stop — you are configured for Commercial. Correct URLs/endpoints and the `-Environment` value before testing anything else.

---

## Gate 1 — Assess

| Test | Pass criteria |
| --- | --- |
| Fleet inventory captured | Windows 10/11 counts, builds, enrollment state recorded |
| `STIGG-Discovery.ps1` run | Output lists existing profiles/policies/baselines/groups; **no naming collisions** with this solution's objects |
| Benchmark loaded | Current DISA STIG benchmark open in STIG Viewer; **version/release date recorded** |
| Rule→mechanism map | Each in-scope STIG rule assigned to Settings Catalog / ADMX / Custom |

**Fail:** missing inventory, a name collision, or an unrecorded benchmark version → resolve before Configure.

---

## Gate 2 — Configure

| Test | Pass criteria |
| --- | --- |
| Objects exist | All profiles (`STIG-Win-SettingsCatalog-*`, `STIG-Win-ADMX-*`, `STIG-Win-Custom-*`), `STIG-Win-Compliance-Baseline`, and (if used) `STIG-Win-AuditBaseline` created |
| Naming convention | Every object matches the names in `01-solution-overview.md` |
| **No assignments** | Every object is assigned to **nobody** |
| Benchmark pin | Each profile's description records the benchmark version it implements |
| Re-Discovery | Second `STIGG-Discovery.ps1` run confirms objects present, unassigned |

**Fail:** any object assigned early, or off-convention naming → fix before Pilot (an early assignment is a change you didn't gate).

---

## Gate 3 — Pilot

| Test | Pass criteria |
| --- | --- |
| Pilot scope only | Every profile/policy assigned to **`SG-STIG-Pilot-Devices`** and nothing else |
| Deployment status | Each profile's **Device status** shows **Succeeded** on pilot devices |
| No conflicts | **Zero** **Error** / **Conflict** states |
| Functional | Pilot users report no broken sign-in, LOB app, VPN/Tunnel, or print workflow |

**Fail action:** a **Conflict** means two policies set the same setting differently — see `06-troubleshooting.md`. An **Error** on a custom OMA-URI usually means a malformed path/value or a CSP not present in the Gov cloud (**verify for GCC High/DoD**).

---

## Gate 4 — Validate (evidence gate)

| Test | Pass criteria |
| --- | --- |
| `STIGG-Validation.ps1 -Environment USGov` | Reports pilot assignments == intended set; **no** drift/conflict/unassigned flags |
| `STIGG-Report.ps1 -Environment USGov` | Produces JSON/CSV evidence; stored per change-control (R10) |
| Audit baseline review (if used) | Advanced Analytics STIG assessment reviewed; assessed-vs-target deltas understood (advisory only) |
| Regression | Pilot devices complete mission workload unchanged |

**Fail:** any validation flag or unexplained audit delta → remediate in pilot and re-run. **Do not expand on a failed Gate 4.**

---

## Gate 5 — Expand

| Test (per wave) | Pass criteria |
| --- | --- |
| Wave scope | Correct devices in `SG-STIG-Prod-Devices` for this wave |
| Post-wave validation | `STIGG-Validation.ps1` clean after each wave |
| Post-wave evidence | `STIGG-Report.ps1` artifact captured per wave |
| Remediation (if run) | `STIGG-Remediation.ps1` previewed with `-WhatIf`, applied only for approved deltas |
| Final | 100% of prod group **Succeeded**; benchmark→policy version record complete |

**Fail:** errors in a wave → **hold**, remediate, re-validate before the next wave.

---

## Regression & maintenance testing

- **On every DISA benchmark update:** re-run Discovery/Validation after revising profiles; re-pilot the changed rules (mini Gate 3 → Gate 4) before pushing to prod.
- **Monthly drift check:** run `STIGG-Report.ps1` against prod and compare to the last stored artifact; investigate any newly non-compliant devices.
- **After tenant/feature changes:** if Microsoft ships a previously-missing feature into GCC High/DoD (e.g., a new Settings Catalog CSP), re-check whether a custom OMA-URI workaround can be retired.

## What "done" looks like

All five gates passed, prod fleet reporting **Succeeded**, an evidence artifact per wave retained, a recorded mapping of **DISA benchmark version → deployed policy version**, and every step performed in the **sovereign `*.us`** cloud with **`-Environment USGov`/`USGovDoD`**.
