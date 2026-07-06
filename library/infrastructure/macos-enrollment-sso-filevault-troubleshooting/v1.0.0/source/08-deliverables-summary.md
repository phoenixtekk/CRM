# 8. Deliverables Summary — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The macOS + Intune signal path (ADE/enrollment → profiles → SSO → SecureToken/FileVault → compliance/CA), the layered model, the five failure classes, and the diagnose-then-resolve method |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing — Intune + Graph read access, ABM/ASM vantage point, on-Mac diagnostic access, device logs |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Diagnostic Playbook | The symptom tree: classify → confirm the layer above → read the signal → branch fix, across all five branches (ADE/enrollment, SSO, SecureToken/FileVault, compliant-but-denied, locked-out) |
| 5. Testing Guide | Validation procedures with pass/fail gates, one per branch |
| 6. Troubleshooting Guide | Troubleshooting the toolkit itself (Graph sign-in, device lookup, on-Mac commands, escrow reads) |
| 7. Best Practices | Evidence-based escalation and field-proven recommendations |

## PowerShell scripts (Microsoft Graph SDK)
| Script | What it does |
|---|---|
| `MACDX-Discovery.ps1` | Lists macOS managed devices with enrollment state, ownership, compliance, OS build, and last check-in (read-only) |
| `MACDX-Validation.ps1` | Per-device, per-layer state check (`-Check Enrollment/Profiles/FileVault/Compliance`): enrollment/token, SSO-extension profile state, FileVault + recovery-key escrow, named non-compliant settings (read-only) |
| `MACDX-Report.ps1` | Fleet summary — enrollment/compliance mix, stale devices, OS-version spread, FileVault recovery-key escrow coverage (read-only) |
| `MACDX-Remediation.ps1` | Safe remediation helper (`-WhatIf` by default): issue a device **Sync** to re-pull policy and re-evaluate; never wipes/resets/retires |
| `MACDX-Set-ScopeTargeting.ps1` | Pilot/target-group builder (`-WhatIf` by default): ensure an Entra security group exists and add the device so a missing profile/app flows to it |

## What the buyer receives
- This playbook as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP (Graph SDK; read-only Discovery/Validation/Report;
  Remediation and Set-ScopeTargeting default to `-WhatIf`).
- A repeatable process following the standard model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
The failing layer of a stuck Mac isolated in minutes — enrollment, SSO, SecureToken/FileVault, or
compliance — by classifying the symptom, confirming top-down, and reading the one authoritative
signal per layer. A repeatable diagnostic capability the team keeps and reuses, validated on real
failures before it scales out.
