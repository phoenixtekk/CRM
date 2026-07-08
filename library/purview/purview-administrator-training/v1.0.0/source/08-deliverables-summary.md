# 8. Deliverables Summary — Microsoft Purview Administrator Training

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The training model — a lab-and-runbook curriculum that teaches every Purview solution area **scope-first, simulate-first, validate-before-enforce** |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (training environment, scope group, least-privilege roles, toolchain, licensing, illustrative data, stakeholders) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Ordered steps: stand up the program (readiness, scope, baseline), then run each lab in a training scope and simulation/test mode with a pass/fail gate and teardown, then operationalize as runbooks |
| 5. Testing Guide | Per-lab validation gates with explicit PASS conditions, plus the teardown-to-baseline check |
| 6. Troubleshooting Guide | Field issues across labs and their remediation |
| 7. Best Practices | Field-proven recommendations for building durable, evidenced Purview competence |

## PowerShell scripts (Security & Compliance PowerShell / Microsoft Graph — safe by default)
| Script | What it does |
|---|---|
| `OPSTRAIN-Readiness.ps1` | **Scope/health helper (read-only):** confirms `Connect-IPPSSession`/`Connect-MgGraph`, reports the tenant, role context, whether `TRAIN-Pilot-Users` exists, and which Purview feature areas are readable (warns where a feature is unlicensed → walkthrough) |
| `OPSTRAIN-LabScope.ps1` | **Configuration helper (default `-WhatIf`; `-Commit` to apply):** creates/verifies the `TRAIN-Pilot-Users` training scope group of test accounts; the only script that writes, and only the scope group |
| `OPSTRAIN-LabBaseline.ps1` | **Discovery (read-only):** snapshots the current labels, label policies, DLP policies/rules, retention policies, and auto-labeling policies to a baseline CSV — the known-good "before" state for teardown |
| `OPSTRAIN-LabValidate.ps1` | **Validation (read-only):** checks each lab's expected object and **mode/scope** — labels published to the training scope, DLP in **test** mode (not `Enable`), auto-labeling in **simulation**, retention scoped with the illustrative period, audit search returns — pass/fail per lab (`-Lab Labels|DLP|Retention|AutoLabel|Audit|All`) |
| `OPSTRAIN-CompetencyReport.ps1` | **Reporting (read-only):** rolls the validation results and each trainee's `TRAIN-` objects/gates into a competency/progress report CSV — the evidence the team is trained |

All scripts are **read-only by default** (only `OPSTRAIN-LabScope.ps1` writes, and only with `-Commit`,
and only the training scope group). No credentials or secrets are stored. Cmdlets are standard Security
& Compliance PowerShell / Microsoft Graph — none are invented; Insider Risk / Communication Compliance
policy writes are **not** scripted (portal-driven, HR/privacy-sensitive).

## What the buyer receives
- This curriculum (Solution Overview, Requirements, Implementation, Testing, Troubleshooting, Best
  Practices) as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable, evidence-producing training process following the model:
  **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.**

## Scope note
This package delivers **administrator skills training** — the *technical method* for operating every
Microsoft Purview solution area, practiced safely on **illustrative** data in a scoped, simulated
sandbox. It is **not** a records, retention, privacy, or legal determination: real retention schedules,
records file plans, legal holds, and insider-risk / communication-compliance **case outcomes** are
**deferred** to the organization's compliance, records, privacy, HR, and legal functions. Purview is
**licensing-dependent** and the portal **evolves** — availability and paths are **cited or flagged
"verify your licensing/tenant,"** never invented.

## Outcome
A Purview administration team that has **built and proven** competence across labels, DLP, data
lifecycle & records, insider risk, communication compliance, audit, eDiscovery, and DSPM — each
practiced scope-first and simulate-first, validated at a pass/fail gate, and converted into operational
runbooks — with the whole curriculum reusable for every new administrator you onboard, and the training
tenant left clean.
