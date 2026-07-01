# 8. Deliverables Summary — Netskope Secure Web Gateway (SWG)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What an SWG is, steering, categorization, filtering, threat/content, on/off-network model, named artifacts, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Network) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps across Netskope, Entra, and Intune |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NSSWG-Discovery.ps1` | Records SWG readiness: Entra steering groups, Intune client/cert deployment, and (optional) Netskope tenant readiness via REST. Read-only |
| `NSSWG-Validation.ps1` | On a device, confirms the Netskope client is running, steering is active, and the decryption certificate is trusted. Read-only |
| `NSSWG-Report.ps1` | Reports steering-scope coverage (Graph) and, optionally, per-category web activity from the Netskope REST API. Read-only |
| `NSSWG-Remediation.ps1` | Safely fixes mis-steered/non-compliant devices (re-sync, re-add to steering scope). Default `-WhatIf` |
| `NSSWG-Set-ScopeTargeting.ps1` | Creates/populates the `Web Steering – Pilot – Stage 1` and `Web Steering – Broad – Stage 2` groups (Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every user's web traffic behind one cloud secure web gateway — categorized, filtered, and consistently
enforced on or off network — proven on a pilot before it scales, with a documented rollback at every
stage.
