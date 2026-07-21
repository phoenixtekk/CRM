# 8. Deliverables Summary — Remote Help Operations & Adoption

> **Prerequisite:** the base **Remote Help** solution (slug `remote-help`) — this package is the
> operations/adoption layer on top of it and does not repeat install/enable/security-model setup.

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case: turning a Remote Help deployment into a running help-desk capability |
| 1. Solution Overview | The operating model, what this adds vs. the base product, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (base deployment, tiers, RBAC, licensing, ticketing, reporting) |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Ordered steps: tier groups, scope groups, per-tier RBAC roles, unattended governance, role assignment + session-to-ticket workflow, reporting, pilot + adoption, expand |
| 5. Testing Guide | PASS/FAIL validation (in-scope only, capability per tier, governed unattended, ticket logging, escalation, KPIs, adoption) |
| 6. Troubleshooting Guide | Field issues and remediation (wrong scope, unattended not available, session not logged, KPIs missing, low adoption) |
| 7. Best Practices | Field-proven recommendations for role/scope, unattended, workflow, and adoption |

## PowerShell scripts
| Script | What it does |
|---|---|
| `RHELPOPS-Discovery.ps1` | Read-only: reports existing Remote Help RBAC role assignments, scope groups, and who-can-help-whom |
| `RHELPOPS-Validate.ps1` | PASS/FAIL: role/scope model in place, reporting available, unattended governed |
| `RHELPOPS-Report.ps1` | Exports usage/outcome/adoption KPIs to CSV |
| `RHELPOPS-Test-Scope.ps1` | Read-only: proves an agent tier is scoped to the intended users and no more |
| `RHELPOPS-Set-RoleScope.ps1` | The only state-changer: assigns a Remote Help RBAC role + scope group to a help-desk tier. **Defaults to `-WhatIf`.** |

## What the buyer receives
- This operations/adoption guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the standard model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Remote Help running as a real help-desk capability — right-scoped tier roles, governed unattended
access, a session-to-ticket workflow with escalation, outcome/adoption reporting, and end-user
adoption — not just an installed app.
