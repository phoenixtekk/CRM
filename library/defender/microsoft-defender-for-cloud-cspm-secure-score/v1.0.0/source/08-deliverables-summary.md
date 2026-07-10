# 8. Deliverables Summary — Microsoft Defender for Cloud: CSPM & Secure Score Remediation

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Defender for Cloud CSPM is — foundational vs Defender CSPM, Secure Score, agentless scanning, attack paths, compliance dashboard, multicloud; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal steps — enable CSPM, agentless scanning, compliance dashboard, prioritized remediation, governance, continuous export, pilot-first |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Az + KQL / Azure Resource Graph)
| Script | What it does |
|---|---|
| `DEFCSPM-Discovery.ps1` | Read-only posture discovery — Defender for Cloud plan tiers per subscription, Secure Score, registered providers, Log Analytics workspaces, and existing AWS/GCP connectors |
| `DEFCSPM-Validate.ps1` | Confirms Defender CSPM on, agentless scanning enabled, provider registered, governance rule present, and continuous export configured |
| `DEFCSPM-Report.ps1` | Secure Score + top recommendations report with drift versus a saved baseline (measures whether remediation is raising the score) |
| `DEFCSPM-Enable-CSPM.ps1` | `-WhatIf`-gated helper that enables the Defender CSPM plan on a subscription (safe preview by default) |
| `DEFCSPM-Hunt.ps1` | Runs KQL via Azure Resource Graph (`securityresources`) to query recommendations and attack paths (read-only) |

## What the buyer receives
- This solution as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL / Resource Graph queries) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot-subscription first, every change preview/`-WhatIf` first, with a documented rollback.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A continuous, prioritized view of cloud posture and a remediation cadence that measurably raises Secure Score — Defender for Cloud CSPM enabled, agentless scanning and the compliance dashboard on, attack paths remediated by risk, governance and exemptions tracked, and posture trended via continuous export — proven on a pilot subscription before you scale, including to AWS/GCP.
