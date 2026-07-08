# 8. Deliverables Summary — Microsoft Purview Maturity Assessment

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a Purview maturity assessment is — the 10-domain × 6-level model, scorecard, roadmap — benefits, limitations |
| 2. Requirements Guide | Every assessment-specific prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact ordered steps — evidence discovery, rubric scoring, roadmap, readout, optional pilot baseline |
| 5. Testing Guide | Validation procedures with pass/fail gates (assessment, baseline, trend) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PURVIEW-Discovery.ps1` | Reads the tenant's Purview configuration across all ten domains (D1–D10) as scoring evidence; flags licensing/preview signals and unreadable domains (read-only) |
| `PURVIEW-MaturityScore.ps1` | Applies the `Purview Maturity Model - 10 Domains x 6 Levels` rubric to the discovery evidence and emits the `Purview Maturity Scorecard` — per-domain 0–5 score, evidence sentence, weighted overall band (read-only) |
| `PURVIEW-Validation.ps1` | Confirms the optional quick-win baseline objects exist, are **non-enforcing**, and are scoped to `Purview - Pilot Users`; re-checks domain gates (read-only) |
| `PURVIEW-Remediation.ps1` | Applies only the approved quick-win baseline (enable audit, baseline label, DLP in **Test** mode, Compliance Manager) in simulation/test — default `-WhatIf`; changes only with `-Commit`; never enforces |
| `PURVIEW-Set-ScopeTargeting.ps1` | `-HealthCheck` reports connectivity, roles, and per-domain readability; without it, builds/updates the `Purview - Pilot Users` Entra group |

## What the buyer receives
- The assessment documentation set as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable maturity model, scorecard, and roadmap following the house model:
  **Assess → Design → Configure → Pilot (simulate) → Validate → Expand**, with pass/fail gates, any
  quick win piloted in test before enforcement, and a documented rollback.

## Outcome
A defensible, evidence-based picture of where the Microsoft Purview program stands — a 0–5 score per
domain, a weighted overall maturity band, and a sequenced Now/Next/Later roadmap — with quick wins
piloted and validated, and regulatory/records/legal determinations deferred to the relevant governance
functions. Re-run the same model to prove the trend over time.
