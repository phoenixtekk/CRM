# 8. Deliverables Summary — Microsoft Defender for Endpoint Integration (Government / GCC High)

Everything included in the **Government (GCC High) edition** of the MDE Integration solution, and how
the pieces fit together.

## Documents

| File | What it gives you |
| --- | --- |
| `01-solution-overview.md` | The solution, the `.us` portal map, and an explicit **Commercial vs GCC High — what's different** section. |
| `02-requirements.md` | MDE-integration + GCC-High prerequisites, each with **Verify** and **Implement-if-missing**, ending in a requirements gate. |
| `03-implementation.md` | The exact ordered click-path on the **GCC High** portals, including the **Intune ↔ MDE connector for Gov**, with GCC-High caveats inline. |
| `05-testing.md` | Eight pass/fail validation gates for the pilot. |
| `06-troubleshooting.md` | GCC-High-specific symptoms and fixes (wrong-cloud root cause, endpoint blocks, parity-vs-bug). |
| `07-best-practices.md` | Operating guidance for a sovereign tenant (portals, onboarding hygiene, rollout discipline, parity playbooks, least privilege). |
| `gcc-high-parity-notes.md` | The **cited** Commercial-vs-GCC High/DoD parity reference (portals, API, licensing, connectivity, feature gaps). |
| `executive-summary.md` | One-page business framing for approvers. |
| `global-requirements-intune-solutions.md` | Category-level prerequisites shared by all Intune solutions. |

## PowerShell scripts (all connect to **US Gov Graph**, `-Environment USGov`)

| Script | Type | What it does |
| --- | --- | --- |
| `MDEG-Discovery.ps1` | Read-only | Inventories devices, onboarding state, and the sovereign context so you know your starting point. |
| `MDEG-Validation.ps1` | Read-only | Validates the Intune↔MDE connector, sensor health, and that onboarding resolves to the **US Government** environment. |
| `MDEG-Report.ps1` | Read-only | Reports onboarded devices, machine risk scores, and Intune compliance state — your per-wave evidence record. |
| `MDEG-Remediation.ps1` | Change (**`-WhatIf` default**) | Fixes common gaps (e.g. re-assigns onboarding/compliance to the correct group) after showing planned changes. |
| `MDEG-Set-ScopeTargeting.ps1` | Change (**`-WhatIf` default`**) | Applies scope tags / group targeting so regional/mission admins see only their own devices and policies. |

> **Safety:** discovery/validation/report scripts are strictly **read-only**. The two change scripts
> default to **`-WhatIf`** — they show what they *would* do; re-run intentionally (removing `-WhatIf`
> or passing `-Confirm:$false` where offered) to apply.

## Named objects you build (reused across the docs)

| Object | Name |
| --- | --- |
| Pilot security group | `SG-MDE-Pilot` |
| Production wave group | `SG-MDE-Prod-Wave1` |
| EDR onboarding policy | `MDE - EDR Onboarding - Pilot` |
| Windows compliance policy (risk-wired) | `CP-Windows-MDE-Risk` |
| Conditional Access policy (optional) | `CA-Require-Compliant-MDE` |

## How to use this solution
1. Read `01-solution-overview.md` (esp. **Commercial vs GCC High**).
2. Pass the requirements gate in `02-requirements.md`.
3. Execute `03-implementation.md` **in order** on the `.us` portals.
4. Validate against `05-testing.md` on `SG-MDE-Pilot`; use `06-troubleshooting.md` if a gate fails.
5. Expand in waves per `03-implementation.md` Step 9; keep `MDEG-Report.ps1` output as evidence.
6. Consult `gcc-high-parity-notes.md` before depending on any analytics/reporting/response feature.

*Sources: Microsoft Learn — US Government customers page; Intune ↔ Defender integration pages.
Verify GCC High / DoD specifics in your tenant.*
