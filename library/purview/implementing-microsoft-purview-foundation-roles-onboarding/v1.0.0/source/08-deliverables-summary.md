# 8. Deliverables Summary — Implementing Microsoft Purview: Foundation, Roles & Onboarding

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Purview portal and capability map, the least-privilege role/RBAC model, the core data services (Content/Activity Explorer, unified audit), Compliance Manager, the phased-adoption approach, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + S&C PowerShell + Graph steps (assess, design role matrix, apply roles pilot-first, enable core services, confirm workload scope, baseline Compliance Manager, validate, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PURVIMP-Assess-Readiness.ps1` | Read-only readiness + licensing + role assessment: compliance SKUs (E3/E5/E5 Compliance) via Graph, existing role groups + members via S&C PowerShell, unified-audit status, and toolchain connectivity. Writes `Purview Readiness – Foundation – Assess` |
| `PURVIMP-Set-RoleGroups.ps1` | Least-privilege role-group / RBAC setup helper: adds named members to built-in role groups (and creates custom scoped groups where needed) from a matrix CSV; **`-WhatIf` by default**, `-Commit` to apply; prints the reverse command for each change |
| `PURVIMP-Enable-CoreServices.ps1` | Core-services enablement checker/enabler: reports (and with `-Commit` enables) the unified audit log, and reports Content/Activity Explorer viewer-role posture. Writes `Purview Core Services – Enablement` |
| `PURVIMP-Report-ComplianceBaseline.ps1` | Read-only compliance-signal baseline: captures Secure Score (Graph), audit status, and role posture alongside the portal Compliance Manager score you supply. Writes `Purview Compliance Baseline – Report` |
| `PURVIMP-Scope-Config.ps1` | Read-only scope/health helper: confirms the in-scope M365 workloads and reports endpoint device-onboarding readiness. Writes `Purview Workload Scope – Map` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything. No credentials or secrets are stored in code; every script uses interactive
modern-auth (`Connect-IPPSSession` / `Connect-ExchangeOnline` / `Connect-MgGraph`).

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
A Microsoft Purview foundation done right — the portal organized, role groups least-privileged and
separated, the unified audit log and Content/Activity Explorer visibility on, Compliance Manager
baselined, and the in-scope workloads connected — so every Purview capability you add next (labels, DLP,
retention/records, insider risk, communication compliance, audit investigations, DSPM, data governance)
lands on solid ground.
