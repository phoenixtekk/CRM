# 8. Deliverables Summary — Proof-of-Concept Kit: Microsoft Defender for Identity

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | What the PoC proves, the boundary, and the effort |
| 1. Solution Overview | What MDI / ITDR is and how a scoped, safe PoC proves it |
| 2. Requirements Guide | PoC-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — install a pilot sensor, generate benign signal, validate, score, tear down |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Safe-PoC guidance and where to go next |

## PowerShell scripts (Microsoft Graph Security + directory enumeration + KQL)
| Script | What it does |
|---|---|
| `POCMDI-Enable.ps1` | `-WhatIf`-gated pilot enable — previews readiness (plan, DCs, DSA), and can tag the honeytoken decoy `MDI PoC Honeytoken – Pilot` (safe preview by default; sensor install is a guided change-window step) |
| `POCMDI-TestSignal.ps1` | **Benign** test-signal generator — runs harmless read-only directory enumeration and touches the honeytoken (no attack tooling, ever) |
| `POCMDI-Validate.ps1` | Read-only demo/validate — confirms the reconnaissance and honeytoken alerts, the identity timeline, and advanced-hunting rows |
| `POCMDI-Scorecard.ps1` | Scores observations against your evaluation criteria and writes `MDI PoC Scorecard – Pilot DC – Validate` |
| `POCMDI-Teardown.ps1` | `-WhatIf`-gated clean rollback — untags the honeytoken, guides sensor uninstall + DSA removal, resolves test alerts |

## What the buyer receives
- This solution as a **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — run here as a safe, reversible PoC with response kept approval-gated.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A concrete, in-tenant proof that Microsoft Defender for Identity delivers ITDR — a pilot sensor raising real detections from benign reconnaissance and honeytoken activity, visible on the identity timeline with UEBA scoring — scored against your criteria and cleanly torn down.
