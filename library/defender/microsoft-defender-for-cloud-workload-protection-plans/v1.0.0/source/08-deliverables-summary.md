# 8. Deliverables Summary — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | CSPM vs CWPP, and each workload plan — Servers, Containers, Databases, Storage, Key Vault, App Service, Resource Manager; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — enable plans on the pilot subscription, wire Servers MDE/agents, continuous export, alert tuning, notify-only workflow, validate, expand |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Az / Microsoft Graph Security + KQL)
| Script | What it does |
|---|---|
| `MDCWP-Discovery.ps1` | Read-only readiness — subscriptions onboarded to Defender for Cloud, current plan state per subscription, the running account's rights, agent coverage, and workspace for export |
| `MDCWP-Validate.ps1` | Targeted validation (`-Plan Servers\|Containers\|Databases\|Storage\|Export\|Workflow\|All`) — confirms plan state, Servers agent/MDE coverage, export, and the notify-only response workflow |
| `MDCWP-Report.ps1` | Coverage report by section (`-Section Alerts\|Cost\|All`) — alert inventory/suppression posture and protected-resource counts (cost), with drift versus a saved baseline |
| `MDCWP-EnablePlans.ps1` | `-WhatIf`-gated helper that enables the named workload plans on a subscription (safe preview by default; `-Apply` to enable) |
| `MDCWP-Hunt.ps1` | Runs the KQL query `MDC Workload Alert Validation` (via the `SecurityAlert` workspace table / Graph Security) to confirm workload alerts stream (read-only) |

## What the buyer receives
- This solution as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot-subscription plan enablement with automated response kept notify/approval-gated and cost monitored throughout.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
Active workload threat protection across servers, containers, databases, storage, Key Vault, and App Service — the CWPP layer on top of your CSPM posture — with alerts tuned to signal, a notify-first response workflow, and cost understood, proven on a pilot subscription before you scale.
