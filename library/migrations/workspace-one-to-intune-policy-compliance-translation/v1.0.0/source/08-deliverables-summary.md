# 8. Deliverables Summary — Workspace ONE to Intune: Policy & Compliance Translation

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The translation model, the three Intune destinations, the per-platform model, naming, and the parity gate (the why, stated once) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: inventory, map per platform, handle gaps, map compliance, pilot, parity gate, expand |
| 5. Testing Guide | Validation procedures with explicit pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts

| Script | What it does |
|---|---|
| `WS1POL-Discovery.ps1` | Normalizes the Workspace ONE source export into a per-platform profile + compliance inventory (read-only; source export deferred to vendor docs) |
| `WS1POL-Validation.ps1` | Parity check — compares source inventory against deployed Intune configuration and compliance policy per platform (read-only, Microsoft Graph) |
| `WS1POL-Report.ps1` | Per-device and per-policy configuration + compliance state report (read-only, Microsoft Graph) |
| `WS1POL-Remediation.ps1` | Identifies and, with confirmation, resolves conflicting policy assignments; defaults to `-WhatIf` |
| `WS1POL-Set-PolicyScopeTargeting.ps1` | Creates and populates the `Policy Scope - Pilot/Production - Stage` Entra groups |

## Named artifacts produced

- `Mapped Config - <Platform> - Pilot` and `- Production` (Windows / iOS / Android / macOS)
- `Mapped Compliance - <Platform> - Pilot` and `- Production` (Windows / iOS / Android / macOS)
- `Policy Translation - All Platforms - Gap Register`
- `Policy Scope - Pilot - Stage` and `Policy Scope - Production - Stage`

## What the buyer receives

- This guide set as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess to Configure to Pilot to Validate to Expand, with
  a parity gate before cutover.

## Outcome

Every Workspace ONE profile and compliance rule translated into Intune with proven parity — the same
effective posture across platforms, every gap handled deliberately — validated on a pilot before the
fleet scales.
