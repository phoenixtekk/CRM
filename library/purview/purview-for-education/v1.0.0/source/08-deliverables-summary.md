# 8. Deliverables Summary — Microsoft Purview for Education (FERPA)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case: an education-tailored, FERPA-aligned Purview program, piloted in simulation/test and defensible |
| 1. Solution Overview | The education-fit program (labels/DLP/retention/posture), why "tailored to education" matters, industry-bundle model, what's authored vs deferred |
| 2. Requirements Guide | Every education/FERPA prerequisite with Verify / Implement-if-missing (the six category Purview GRs referenced, not duplicated) |
| Global Requirements (Purview) | Category-wide Purview prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal + S&C PowerShell + Graph steps: labels → custom Student-ID SIT → publish to pilot → DLP in Test → (auto-label simulation) → retention per approved schedule → Compliance Manager; pilot-in-simulation-first, pass/fail + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates (nothing enforced) |
| 6. Troubleshooting Guide | Labels, DLP, retention, SIT, licensing, and audit issues by symptom → root cause → fix |
| 7. Best Practices | Field-proven recommendations; pilot-in-simulation discipline; determinations deferred to governance |

## PowerShell scripts (Security & Compliance PowerShell / Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `EDU-Discovery.ps1` | Read-only inventory: sensitivity labels + label policies, DLP policies **and their mode**, retention labels/policies, custom SITs (incl. `EDU - Student ID`), and audit state | Read-only |
| `EDU-Set-Configuration.ps1` | Creates the education label set, the FERPA DLP policy **in Test mode**, and the retention label — `-Area Labels/DLP/Retention` | Default `-WhatIf`; `-Commit` to write; **DLP always created in Test — never enforces** |
| `EDU-Validation.ps1` | Policy-state checks: DLP is in **Test** (flags any enforcing), label policy targets the pilot, retention label has the approved period, DLP conditions reference the education-record signal | Read-only |
| `EDU-Report.ps1` | Activity/coverage: DLP match/incident counts (Test + enforced), label usage, and disposition/retention coverage where readable | Read-only |
| `EDU-Scope-Health.ps1` | Readiness helper: compliance licensing the tenant exposes, operator Purview role-group membership (where readable), in-scope workloads, and gaps vs the Requirements Guide | Read-only |

## What the buyer receives
- This implementation guide as a **PDF** (and, per the factory, a white-label local copy).
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**

## Outcome
A Microsoft Purview program **tailored to education and aligned to FERPA** — an agreed label taxonomy
published to a pilot, a custom student-ID sensitive information type anchoring FERPA-oriented DLP proven
in **Test/simulation** before it blocks anyone, student-record retention enforced to the records
owner's approved schedule, and a **scored, evidenced** Compliance Manager posture — configured,
validated against pass/fail gates, and defensible. Regulatory, records, and legal determinations remain
with the institution's governance functions.
