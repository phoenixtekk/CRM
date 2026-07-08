# 8. Deliverables Summary — Print DLP (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The print exfiltration gap, how Endpoint DLP's Print activity + printer groups close it, and the Assess→Design→Configure→Pilot(simulate)→Validate→Expand model |
| 2. Requirements Guide | Every print-DLP prerequisite with Verify / Implement-if-missing (category Purview GRs referenced, not duplicated): licensing, DLP roles, device onboarding, classification intent, printer groups, pilot ring, alert triage |
| Global Requirements (Purview) | Category-wide Purview prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal + S&C PowerShell + Graph steps: detectors, printer groups, the Devices-only Print policy **in simulation**, tune, enforce to a ring, expand — each artifact named, with pass/fail gates + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates (readiness, simulation, enforcement) |
| 6. Troubleshooting Guide | Print-DLP issues by symptom → root cause → fix |
| 7. Best Practices | Field-proven recommendations for a print restriction that survives real users |

## PowerShell scripts (Security & Compliance PowerShell / Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `DLPPRINT-Discovery.ps1` | Posture assessment: existing DLP policies + mode, which scope the Devices/Endpoint location, any Print restriction already configured, built-in vs custom SIT coverage | Read-only |
| `DLPPRINT-Config.ps1` | Configuration/remediation helper: previews/creates the Devices-only Print policy + rule **in simulation mode**, and (with `-SetScope`) sets the pilot-ring include scope; never leaves a policy in enforce | Default `-WhatIf`; `-Commit` to write |
| `DLPPRINT-Validation.ps1` | Validates the policy shape: Devices-only, Print activity set, printer groups resolve, simulation vs enforce mode, scoped identities — the "is it built right" report | Read-only |
| `DLPPRINT-Report.ps1` | Exports print DLP activity (matches, overrides, printers, SIT/label, confidence) over N days from the audit log for false-positive/alert review | Read-only |
| `DLPPRINT-EndpointReadiness.ps1` | Scope/health helper: onboarded-device readiness and licensing signals for the Devices location and the Print activity | Read-only |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**

## Outcome
Printing of sensitive documents is **controlled by policy** on onboarded endpoints — proven in **simulation**
first, tuned to a low false-positive rate, enforced from a pilot ring outward, with **corporate printing
still allowed**, restricted prints **audited and alerted**, and the whole control **defensible and
evidenced** in Microsoft Purview. Regulatory/records/legal determinations remain with the relevant
governance functions; this package delivers the technical method and the proof.
