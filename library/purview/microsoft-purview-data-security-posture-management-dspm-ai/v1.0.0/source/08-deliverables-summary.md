# 8. Deliverables Summary — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What DSPM and DSPM for AI show (posture, sensitive-data risk, AI/Copilot data access, sensitive prompts/responses, oversharing controls), the availability/licensing caveat, the outcome-vs-determination boundary, and the naming convention |
| 2. Requirements Guide | Every DSPM/DSPM-for-AI prerequisite with Verify / Implement-if-missing (licensing, DSPM roles, auditing, labels+DLP foundation, Copilot/AI in scope, sharing signal, pilot discipline) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell steps: confirm scope, inventory controls, read posture & risk, open DSPM for AI, assess AI exposure, baseline recommendations, pilot reduction in simulation/test, validate, expand/enforce, recurring review |
| 5. Testing Guide | Validation procedures with explicit pass/fail and the enforcement gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for measuring and reducing posture safely |

## PowerShell scripts
All are safe-by-default (read-only, or `-WhatIf` / simulation-test unless `-Commit`), use
`Connect-IPPSSession` and/or `Connect-MgGraph`, and store **no** credentials.
| Script | What it does |
|---|---|
| `PURVDSPM-ScopeConfig.ps1` | Read-only scope/health helper: confirms sign-in, reports whether **auditing** is on, and enumerates the licensing-dependent features (labels, DLP, auto-labeling, Insider Risk presence) feeding posture. Resolves Requirements 2.1–2.3 |
| `PURVDSPM-Discovery.ps1` | Read-only inventory of sensitivity labels, label policies, DLP policies/rules, and auto-labeling policies (and, with `-IncludeSensitiveTypes`, the sensitive info types). Writes `DSPM Posture – Estate – Discovery` and `Sensitive-Data Risk – Estate – Assess` |
| `PURVDSPM-AIExposure.ps1` | Read-only DSPM-for-AI exposure report: AI/Copilot interaction activity from Purview auditing plus SharePoint/OneDrive oversharing signal. Writes `AI Exposure – Copilot – Assess` and `Oversharing Report – Sites – Assess` |
| `PURVDSPM-Tracker.ps1` | Read-only recommendation/action tracker: snapshots DSPM recommendations and DLP / auto-labeling policy states. Writes `DSPM Recommendations – Estate – Tracker` |
| `PURVDSPM-Reduce-Oversharing.ps1` | Oversharing-reduction helper (label / DLP-for-AI / sharing-review / enforce). Defaults to `-WhatIf`; with `-Commit` creates auto-labeling in **simulation** and DLP for AI in **test**, produces the prioritized sharing list, and (Enforce) flips named policies from simulation/test to on — never silently |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand (enforce).**

## Outcome
Data-security risk made **visible and reduced**: posture measured across the estate, recommendations
actioned to completion, and Copilot/AI oversharing surfaced and controlled through labels, DLP for AI,
and sharing restriction — every high-impact change piloted in simulation/test before enforcement — so
data is safer before and during AI adoption. Regulatory, records, and legal determinations remain with
the organization's governance functions; this solution delivers the technical method and the evidence.
