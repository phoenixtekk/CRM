# 8. Deliverables Summary — Architecture Service: Microsoft Defender for Cloud

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box — a reference design, not a single-subscription deployment |
| 1. Solution Overview | Defender for Cloud at scale — MG/subscription onboarding model, CSPM vs workload plans, multicloud connectors, RBAC, continuous export, cost drivers; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites (MG hierarchy, deployment identity, cost inputs) with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Design & Implementation Guide | Produce the reference design + decision record, then deploy in waves with Bicep — what-if first, pilot MG first |
| 5. Testing Guide | Eight validation tests with pass/fail gates (inheritance, coverage, RBAC, export, cost) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## Infrastructure-as-code + PowerShell (Bicep + Az + KQL/Resource Graph)
| Artifact | What it does |
|---|---|
| `main.bicep` | **Reference architecture skeleton** — enables Defender for Cloud plans (CSPM + workload plans) at **management-group** scope so subscriptions inherit protection; parameterized per the design; deployed **what-if first** |
| `ARCMDC-Discovery.ps1` | Read-only discovery — management-group hierarchy, per-subscription plan tiers, registered providers, Log Analytics workspaces, existing AWS/GCP connectors, and resource counts (the cost drivers) |
| `ARCMDC-Deploy.ps1` | `-WhatIf`-gated deployment helper that runs the Bicep as an MG-scope `what-if` by default and applies only with `-Apply` (safe preview by default) |
| `ARCMDC-Validate.ps1` | Confirms plans enabled at scope, **inheritance** working, providers registered, governance rule present, RBAC least-privilege, and continuous export configured |
| `ARCMDC-Report.ps1` | Coverage report (with drift vs a saved baseline) and an indicative **cost model** (`-Mode Cost`) from discovered resource counts — the two numbers the design has to get right |

## What the buyer receives
- This solution as a branded **Word** document and **PDF**, including the reference architecture and decision-record structure.
- The **reference Bicep skeleton** (`main.bicep`) plus four **PowerShell scripts** (Az + KQL/Resource Graph) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot management group first, every deployment **what-if / plan first**, with a documented rollback and a cost model.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A scalable, documented Defender for Cloud architecture — plans enabled **consistently** at management-group scope so coverage is uniform and new subscriptions inherit it, a **clean least-privilege RBAC** and governance model, **AWS/GCP connectors** for multicloud, **continuous export** to a central workspace and the SIEM, and a **predictable cost model** — captured as a design record and a what-if-first Bicep skeleton, and validated on a pilot management group before it scales.
