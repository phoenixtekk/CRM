# 8. Deliverables Summary — Proof-of-Concept Kit: Microsoft Defender for Cloud Apps

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | What the PoC proves, the boundary, and the effort |
| 1. Solution Overview | What MDCA / CASB is and how a scoped, safe, monitor-first PoC proves it |
| 2. Requirements Guide | PoC-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — enable discovery + audit policy, generate benign signal, validate, score, tear down |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Safe-PoC guidance and where to go next |

## PowerShell scripts (Microsoft Graph Security + KQL)
| Script | What it does |
|---|---|
| `POCMDCA-Enable.ps1` | `-WhatIf`-gated pilot enable — previews readiness, then enables discovery and an audit-mode activity policy scoped to `MDCA PoC – Pilot Users – Pilot` (safe preview by default) |
| `POCMDCA-TestSignal.ps1` | **Benign** test-signal helper — uploads Microsoft's sample Cloud Discovery log and guides benign policy-matching activity (no real exfiltration, ever) |
| `POCMDCA-Validate.ps1` | Read-only demo/validate — confirms the discovery report, policy match, alert, and activity-log / hunting visibility |
| `POCMDCA-Scorecard.ps1` | Scores observations against your evaluation criteria and writes `MDCA PoC Scorecard – Pilot Users – Validate` |
| `POCMDCA-Teardown.ps1` | `-WhatIf`-gated clean rollback — deletes the policy, discovery report, and connector, resolves test alerts |

## What the buyer receives
- This solution as a **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — run here as a safe, reversible, monitor-first PoC.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A concrete, in-tenant proof that Microsoft Defender for Cloud Apps delivers CASB — a Shadow IT discovery report from a benign sample log, an audit-mode activity policy matching benign test activity, an alert surfaced, and full activity-log visibility — scored against your criteria and cleanly rolled back.
