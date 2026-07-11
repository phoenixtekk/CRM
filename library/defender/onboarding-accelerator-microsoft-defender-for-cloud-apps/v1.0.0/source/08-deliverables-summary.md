# 8. Deliverables Summary — Onboarding Accelerator: Microsoft Defender for Cloud Apps

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What MDCA is — app connectors, Cloud Discovery, app governance/OAuth policies, session/access control; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — connect apps, discovery, app governance, monitor-first policies, Conditional Access App Control, validate, enforce/expand |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Microsoft Graph Security / Entra + KQL)
| Script | What it does |
|---|---|
| `MCAONB-Discovery.ps1` | Read-only readiness — MDCA activation, plan hints, admin roles, existing app connectors, Cloud Discovery source, app-governance status |
| `MCAONB-Validate.ps1` | Targeted validation (`-Check Connectors\|Discovery\|Policy`) — confirms connectors, discovery flow, and that session/access policies are report-only and pilot-scoped |
| `MCAONB-Report.ps1` | Coverage report by section (`-Section OAuth\|Policies\|All`) — risky OAuth apps, policy inventory/posture, and drift versus a saved baseline |
| `MCAONB-ScopePolicy.ps1` | `-WhatIf`-gated helper that scopes/updates the Conditional Access App Control policy to the pilot user group (safe preview by default) |
| `MCAONB-Hunt.ps1` | Runs the KQL advanced-hunting query `MDCA Signal Validation` via Graph Security to confirm `CloudAppEvents`/OAuth data stream (read-only) |

## What the buyer receives
- This solution as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot-scoped, monitor-first onboarding with enforcing/revoke actions kept approval-gated until trusted.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A validated, monitored Defender for Cloud Apps deployment delivering CASB — connectors streaming from priority SaaS apps, Cloud Discovery surfacing shadow IT, app governance and OAuth policies watching risky consents, and session/access policies enforcing real-time control on a pilot scope — proven before you enforce tenant-wide.
