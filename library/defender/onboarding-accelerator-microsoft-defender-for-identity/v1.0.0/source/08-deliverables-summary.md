# 8. Deliverables Summary — Onboarding Accelerator: Microsoft Defender for Identity

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What MDI is — sensors, DSA, honeytokens, sensitive tags, ISPM posture, detections; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — DSA, pilot-DC sensor, sensitive tagging, honeytokens, ISPM, detection validation, expand |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Microsoft Graph Security / AD read helpers + KQL)
| Script | What it does |
|---|---|
| `MDIONB-Discovery.ps1` | Read-only readiness — MDI activation/workspace, plan hints, admin roles, every domain controller and OS, DSA readiness, existing sensor status |
| `MDIONB-Validate.ps1` | Targeted validation (`-Check DSA\|Sensor\|Sensitive\|Honeytoken`) — confirms the DSA, sensor health, sensitive-entity tags, and honeytoken tags |
| `MDIONB-Report.ps1` | Sensor-health, ISPM posture, and coverage report with top Identity recommendations and drift versus a saved baseline; reports response-action posture |
| `MDIONB-Honeytoken.ps1` | `-WhatIf`-gated helper to tag sensitive entities (`-Mode SensitiveTag`) and honeytokens (`-Mode Honeytoken`) — safe preview by default |
| `MDIONB-Hunt.ps1` | Runs the KQL advanced-hunting query `MDI Detection Validation` via Graph Security to confirm the identity tables stream and a test detection is visible (read-only) |

## What the buyer receives
- This solution as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot-DC sensor onboarding with response actions kept approval-gated until trusted.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A validated, monitored Defender for Identity deployment delivering ITDR — sensors healthy on every domain controller, the DSA configured, honeytokens planted and tagged, sensitive entities marked, ISPM recommendations triaged, and a detection proven to fire — onboarded on a pilot DC before you scale.
