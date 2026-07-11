# 8. Deliverables Summary — Security Optimization Assessment: Defender for Cloud

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box — read-only assessment that scores posture and prioritizes gaps |
| 1. Solution Overview | What Defender for Cloud is, the four assessment domains (Secure Score & recommendations, plan coverage, regulatory posture, agent/agentless coverage), the scoring model, scope, and connections used |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Assessments) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps to run the assessment end to end — Assess → Configure → Pilot → Validate → Expand — with every artifact named |
| 5. Testing Guide | Eight validation tests with pass/fail gates proving the evidence is reliable |
| 6. Troubleshooting Guide | Common run failures and fixes |
| 7. Best Practices | Field-proven guidance and where to go next |

## PowerShell scripts (Az + Azure Resource Graph KQL — all read-only)
| Script | What it does |
|---|---|
| `SOAMDC-Discovery.ps1` | Read-only discovery — Defender for Cloud plan tiers per subscription, Secure Score, registered providers, Log Analytics workspaces, agentless-scanning state, and AWS/GCP connectors; saves the configuration baseline. Makes no changes. |
| `SOAMDC-Validate.ps1` | Checks, per domain, whether the recommended controls are present (Secure Score above a floor with recommendations worked, workload plans on, required compliance standard mapped, agentless scanning enabled), returning Pass/Gap with evidence. |
| `SOAMDC-Score.ps1` | Computes deterministic per-domain and overall posture scores against the reference baseline using documented weights. |
| `SOAMDC-Coverage.ps1` | Read-only Azure Resource Graph (KQL) analysis of plan coverage per resource type and machine agent/agentless coverage — the evidence behind the coverage domains. |
| `SOAMDC-Report.ps1` | Produces the prioritized, risk-ranked findings report (domain, severity, evidence, remediation pointer) and shows drift versus a prior saved baseline. |

## What the buyer receives
- This solution as a **Word** document and **PDF**.
- All five **PowerShell scripts** (read-only, Az + embedded Resource Graph KQL) in a single ZIP.
- A repeatable process following **Assess → Configure → Pilot → Validate → Expand** — read-only, scored, and traceable, with findings ready to hand to the Remediation Playbook.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A scored, evidence-backed picture of your Defender for Cloud posture across Secure Score & recommendations, plan coverage, regulatory posture, and agent/agentless coverage — and a prioritized remediation backlog that tells you what to fix, in order. Read-only: it changes nothing, it tells you what to fix.
