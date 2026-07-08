# 8. Deliverables Summary — CJIS DLP Pack (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | CJI DLP in Purview — what it delivers, the CJI detection approach, the Assess→Design→Configure(simulate)→Pilot→Validate→Expand(enforce) model, coverage, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + S&C PowerShell + Graph steps: assess estate/scope, design CJI detection, create the policy in **simulation/test**, pilot & tune, validate gates, promote to **enforce**, expand, and run the evidence cadence — each policy/rule/classification named, with pass/fail gates and rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates (detection accuracy, simulation, enforcement, rollback, drift) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLPCJIS-Discovery.ps1` | Read-only assessment: inventories existing DLP policies + rules and the available sensitive-info-types, flags any CJI-related classification, and confirms toolchain connectivity. Optional `-SaveBaseline` / `-CompareBaseline` for drift. Writes `Policy Baseline – CJIS DLP – <date>` |
| `DLPCJIS-Set-Policy.ps1` | The one write-capable tool, **simulation-first & `-WhatIf` by default**: creates the CJI DLP policy + rule in a **test** mode (`TestWithNotifications`/`TestWithoutNotifications`); `-PromoteToEnforce` moves it to `Enable`; `-Disable` rolls back. Writes only with `-Commit` and stamps `Change Record – CJIS DLP – ChangeControl` |
| `DLPCJIS-Validation.ps1` | Read-only pass/fail validation: confirms the policy exists, is in the expected mode, is scoped to the intended workloads, and the CJI detection rule is present with the intended action |
| `DLPCJIS-Report.ps1` | Read-only evidence report: reads DLP alerts via Microsoft Graph (`/security/alerts_v2`) and summarizes matches/actions by workload. Writes `CJI DLP Evidence – CJIS – Report` |
| `DLPCJIS-Scope-Health.ps1` | Read-only scope/health helper: reports available workloads, endpoint device-onboarding status, and which DLP surfaces the licensing unlocks. Writes `Workload Scope – CJIS DLP – Map` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything, and simulation/test before enforce. No credentials or secrets are stored in code;
every script uses interactive modern-auth (`Connect-IPPSSession` / `Connect-MgGraph`).

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure (simulate) → Pilot → Validate →
  Expand (enforce).**

## Outcome
CJI Data Loss Prevention stood up the right way in Microsoft Purview — a CJI-tuned detection set, a DLP
policy protecting CJI across the M365 workloads, piloted in simulation and validated before enforcement,
with the ongoing evidence to prove the control is live and working. The CJIS determinations, retention,
and the rest of the CJIS Security Policy remain with your CSO/TAC, compliance, records, and legal owners —
this pack delivers and evidences the DLP control.
