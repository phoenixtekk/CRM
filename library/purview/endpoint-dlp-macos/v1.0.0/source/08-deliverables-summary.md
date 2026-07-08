# 8. Deliverables Summary — Endpoint DLP for macOS (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The macOS Endpoint DLP model, onboarding (Intune/Jamf), the egress channels, simulation-first rollout, what's exact vs deferred |
| 2. Requirements Guide | Every macOS Endpoint DLP prerequisite with Verify / Implement-if-missing (category Purview GRs referenced, not duplicated) |
| Global Requirements (Purview) | Category-wide Purview prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview + Intune + Security & Compliance PowerShell steps: onboard macOS, endpoint DLP settings, DLP policy in test/simulation, pilot, validate, enforce; each object named, pass/fail gates + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates (onboarding → simulation → enforcement) |
| 6. Troubleshooting Guide | Onboarding, extension/Full-Disk-Access, policy-scope, channel-coverage, and enforcement issues by symptom → root cause |
| 7. Best Practices | Field-proven recommendations for a safe, defensible macOS DLP rollout |

## PowerShell scripts (Security & Compliance PowerShell / Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `DLPMac-Discovery.ps1` | Endpoint DLP readiness: lists DLP policies scoped to the **Devices** location, each policy's **Mode** (flags anything in `Enable`), and each rule's endpoint egress restrictions; advises verifying macOS onboarding in the portal | Read-only (`Connect-IPPSSession`) |
| `DLPMac-Set-Policy.ps1` | Creates the endpoint-scoped DLP policy **in `TestWithoutNotifications` (simulation)** and the `macOS Egress - Sensitive Content` rule with **Audit** endpoint restrictions; idempotent by name; never creates in `Enable` | Default `-WhatIf`; `-Commit` to write (test mode only) |
| `DLPMac-Validation.ps1` | Validates the policy targets **Devices**, is in a **test/simulation** mode, and the rule includes the intended egress channels and references a present restricted-app group | Read-only |
| `DLPMac-Report.ps1` | Exports **Endpoint DLP** activity from **Activity Explorer** (`Export-ActivityExplorerData`) for the Mac fleet — audited/blocked egress events by activity, app, and rule — the evidence trail | Read-only |
| `DLPMac-Onboarding-Check.ps1` | Scope/health helper (Graph): reports managed **macOS** devices + OS versions from Intune and whether the onboarding / extension / Full-Disk-Access configuration profiles are present; defers definitive onboarding status to the Purview portal | Read-only (`Connect-MgGraph`) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**

## Outcome
macOS endpoints brought into the **Microsoft Purview** DLP program: **onboarded**, watched across the
key **egress channels** (cloud/browser, USB, network share, clipboard, print, restricted apps),
**piloted in simulation**, **validated** in Activity Explorer, and **enforced** on a controlled scope —
a closed Mac blind spot that is configured, evidenced, and **defensible**, with regulatory/records/
legal determinations left to the relevant governance functions.
