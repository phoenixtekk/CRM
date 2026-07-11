# 8. Deliverables Summary — Proof-of-Concept Kit: Microsoft Defender for Cloud

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | What the PoC proves, the boundary, cost note, and the effort |
| 1. Solution Overview | What Defender for Cloud (CSPM + CWPP) is and how a scoped, safe PoC proves it |
| 2. Requirements Guide | PoC-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — enable on a pilot subscription, generate benign signal, validate, score, tear down |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Safe, cost-bounded PoC guidance and where to go next |

## PowerShell scripts (Az PowerShell / Az.Security + Microsoft Graph + KQL)
| Script | What it does |
|---|---|
| `POCMDC-Enable.ps1` | `-WhatIf`-gated pilot enable — previews readiness, then enables CSPM + one Defender workload plan on the pilot subscription (safe preview by default) |
| `POCMDC-TestSignal.ps1` | **Benign** test-signal helper — triggers sample security alerts, deploys a benign misconfigured test resource, and guides an optional EICAR trigger on a pilot VM (no real attack/malware, ever) |
| `POCMDC-Validate.ps1` | Read-only demo/validate — confirms the recommendation, Secure Score, security alerts, and regulatory-compliance data |
| `POCMDC-Scorecard.ps1` | Scores observations against your evaluation criteria and writes `MDC PoC Scorecard – Pilot Sub – Validate` |
| `POCMDC-Teardown.ps1` | `-WhatIf`-gated clean rollback — deletes the test resource, **disables the Defender plan to stop billing**, resolves sample alerts |

## What the buyer receives
- This solution as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — run here as a safe, reversible, cost-bounded PoC.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A concrete, in-environment proof that Microsoft Defender for Cloud delivers CSPM & workload protection — a recommendation and Secure Score from a benign misconfiguration, security alerts from sample alerts and EICAR, and regulatory-compliance visibility — scored against your criteria and cleanly torn down, with the Defender plan disabled to stop billing.
