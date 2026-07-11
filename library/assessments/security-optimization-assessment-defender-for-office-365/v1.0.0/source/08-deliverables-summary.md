# 8. Deliverables Summary — Security Optimization Assessment: Defender for Office 365

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | The business case — why a licensed MDO is not a tuned one, and what a read-only scored assessment (including hidden bypasses) delivers |
| 1. Solution Overview | What MDO/EOP's protections are (anti-spam/malware/phish, Safe Links, Safe Attachments, preset policies, Tenant Allow/Block List, transport-rule interactions), what "good" looks like, and how the score works |
| 2. Requirements | Solution-specific prerequisites with Verify / Implement-if-missing (category-wide ones live in Global Requirements — Assessments) |
| Global Requirements (Assessments) | Category-wide prerequisites, published once |
| 3. Implementation | Exact, ordered, read-only steps — validate access, discover every policy/rule, check coverage and bypass hygiene, score, generate the findings report, review, re-run to trend |
| 5. Testing | Read-only and accuracy gates with pass/fail — proves non-disruptive and reconciled with the portal |
| 6. Troubleshooting | Common run issues → cause → fix |
| 7. Best Practices | Keep-it-read-only, hunt-the-bypasses, score-the-effective-policy guidance and where to go next |

## Automation artifacts (all read-only)
| File | What it does |
|---|---|
| `SOAMDO-Discovery.ps1` | **PowerShell (Exchange Online + Graph), read-only.** Collects every EOP/MDO policy and rule — anti-spam/malware/phish, Safe Links, Safe Attachments, preset rules, connection filter, DKIM — plus **transport rules** and the **Tenant Allow/Block List** for bypass hygiene, and Secure Score / `EmailEvents` signals, into a dated run folder. Changes nothing. |
| `SOAMDO-Coverage.ps1` | **PowerShell, read-only.** Resolves the **effective** policy per recipient by priority, finds recipients covered by nothing/weak policy against the expected mailbox count, checks preset usage, and produces a consolidated **bypass** list (allow lists + transport rules + connection-filter IPs + disabled protections). |
| `SOAMDO-Assess.ps1` | **PowerShell, read-only.** Scores each check Pass/Partial/Fail/N-A against the preset + Secure Score baseline, weights bypass findings high, assigns severities, and rolls up a weighted posture score (%). Writes the scorecard with the baseline stamped in. |
| `SOAMDO-Report.ps1` | **PowerShell, read-only.** Generates the risk-ranked findings report (HTML) sorted High → Low with evidence, affected recipients/counts, and remediation pointers — bypass findings at the top — plus a tracking CSV. |
| `SOAMDO-Validate.ps1` | **PowerShell, read-only.** Self-check that the assessor can read every policy type **plus transport rules and the Tenant Allow/Block List**, run a hunting query, **and has no write role/scope**. The assessment's read-only guarantee. |

## What the buyer receives
- This assessment guide as a **Word** document and **PDF**.
- All five read-only PowerShell scripts in a single ZIP — yours to keep and re-run to trend your posture and shrink your bypass list over time.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand** — this package owns **Assess** (read-only); the fixes are the paired Remediation Playbook, done pilot-first.

**Delivered as a Complete Solution Package (PDF + Word + scripts).**

## Outcome
A defensible, point-in-time **posture score** for Defender for Office 365 and a **prioritized, risk-ranked remediation backlog** — including every override and bypass that quietly weakens filtering — the evidence to fix what matters, in order, plus the scripts to re-score. Risk-acceptance and remediation priority remain the customer's security owners' decisions.
