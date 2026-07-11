# 8. Deliverables Summary — Security Optimization Assessment: Defender for Identity

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | The business case — why sensors on "most" DCs is not identity coverage, and what a read-only scored assessment delivers |
| 1. Solution Overview | What MDI's pieces are (sensors, DSA, honeytokens, ISPM, detections), what "good" looks like, and how the score works — with sensor-coverage reconciliation the centerpiece |
| 2. Requirements | Solution-specific prerequisites with Verify / Implement-if-missing (category-wide ones live in Global Requirements — Assessments) |
| Global Requirements (Assessments) | Category-wide prerequisites, published once |
| 3. Implementation | Exact, ordered, read-only steps — validate access, reconcile sensor coverage against the AD inventory, check DSA/honeytoken/ISPM/tuning, score, generate the findings report, review, re-run to trend |
| 5. Testing | Read-only and accuracy gates with pass/fail — proves non-disruptive and that the coverage denominator reconciles with reality and the portal |
| 6. Troubleshooting | Common run issues → cause → fix |
| 7. Best Practices | Keep-it-read-only, the-denominator-is-everything, confirm-what-has-no-API guidance and where to go next |

## Automation artifacts (all read-only)
| File | What it does |
|---|---|
| `SOAMDI-Discovery.ps1` | **PowerShell (AD read + Graph), read-only.** Collects the AD inventory (all DCs, AD FS / AD CS role holders), the MDI sensor list & health where available, the DSA and honeytoken signals (portal-confirm items flagged `verify`), ISPM recommendations, and identity detection activity, into a dated run folder. Changes nothing. |
| `SOAMDI-Coverage.ps1` | **PowerShell, read-only.** Reconciles **sensor coverage** — DCs with a healthy sensor vs. the AD-derived total, **naming every un-sensored/unhealthy DC** — plus AD FS / AD CS coverage, honeytoken presence, and the DSA signal. The blind-spot list for remediation. |
| `SOAMDI-Assess.ps1` | **PowerShell, read-only.** Scores each check Pass/Partial/Fail/N-A against the MDI + identity Secure Score baseline (un-sensored DC = High), assigns severities, and rolls up a weighted posture score (%). Writes the scorecard with the baseline stamped in. |
| `SOAMDI-Report.ps1` | **PowerShell, read-only.** Generates the risk-ranked findings report (HTML) sorted High → Low with evidence, affected servers/counts, and remediation pointers — the un-sensored-DC list at the top — plus a tracking CSV. |
| `SOAMDI-Validate.ps1` | **PowerShell, read-only.** Self-check that the assessor can enumerate DCs via AD read, connect to Graph with read scopes, run an identity hunting query, **and has no write scope**. The assessment's read-only guarantee. |

## What the buyer receives
- This assessment guide as a **Word** document and **PDF**.
- All five read-only PowerShell scripts in a single ZIP — yours to keep and re-run to trend your coverage toward 100% over time.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand** — this package owns **Assess** (read-only); the fixes are the paired Remediation Playbook, done pilot-first.

**Delivered as a Complete Solution Package (PDF + Word + scripts).**

## Outcome
A defensible, point-in-time **posture score** for Defender for Identity and a **prioritized, risk-ranked remediation backlog** — starting with the named un-sensored domain controllers — the evidence to fix what matters, in order, plus the scripts to re-score. Risk-acceptance and remediation priority remain the customer's security owners' decisions; response actions and IR determinations belong to the SOC.
