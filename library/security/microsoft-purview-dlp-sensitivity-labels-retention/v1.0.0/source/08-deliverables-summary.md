# 8. Deliverables Summary — Microsoft Purview: DLP, Sensitivity Labels & Retention

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Purview information protection is — labels, auto-labeling, DLP, retention/records — benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Security) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal steps (labels, label policy, auto-labeling, DLP audit-then-enforce, retention/records) |
| 5. Testing Guide | Validation procedures with pass/fail gates and the DLP audit gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PURVIEW-Discovery.ps1` | Reports the tenant's sensitivity labels, DLP policies, and retention policies (labels/DLP/retention config); flags endpoint onboarding and licensing signals |
| `PURVIEW-Validation.ps1` | Confirms the expected labels are published, the DLP policy exists, and the retention policy exists and is on |
| `PURVIEW-Report.ps1` | Classification + DLP-event coverage summary across the enabled services |
| `PURVIEW-Remediation.ps1` | Safe remediation of common gaps (default `-WhatIf`); republishes/enables named objects only when confirmed |
| `PURVIEW-Set-ScopeTargeting.ps1` | Builds/updates the pilot and protection-scope Entra groups |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the Phoenixtekk model: **Assess → Configure → Pilot → Validate →
  Expand**, with a DLP audit gate before enforce and a documented rollback.

## Outcome
Data classified, protected, and retained with Microsoft Purview — a clear label taxonomy with
auto-labeling, DLP tuned in audit before it enforces, and retention that meets compliance without
over- or under-deleting — proven on a pilot before you scale.
