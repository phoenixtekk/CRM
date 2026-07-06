# Deliverables Summary

This solution is a self-contained **runbook library and IT-support enablement kit** plus supporting
scripts for managing and supporting Intune-managed Macs. Everything below is yours to keep and reuse
across the fleet.

## Documents
- **Solution Overview** (`01-solution-overview.md`) — the macOS support operating model
  (intake → triage → diagnose → resolve/escalate → document), how it maps to an Intune-managed Mac
  fleet (Intune, Entra, Apple Business Manager, the Mac), the fixed anatomy every runbook uses, and
  how to keep the library current with Intune/Apple changes.
- **Requirements Guide** (`02-requirements.md`) — the technician prerequisites (Intune read role,
  Graph read access, a macOS remote-control tool, Mac asset/user context, a place to record
  outcomes), each with Description / Why / Verify / Implement-if-missing, plus the category-level
  global requirements read with the macOS note.
- **Runbook Library** (`03-implementation.md`) — the seven categorized runbooks — ADE/enrollment,
  SSO setup, app deployment (VPP/LOB), passwordless/FileVault procedures, BYOD, compliance &
  Conditional Access, and incident response (encryption/SecureToken/lock-out) — each with triage
  tree, checks, resolution/steps, escalation gate, and evidence to collect.
- **Testing Guide** (`05-testing.md`) — pass/fail gates per runbook and per script, run on a pilot
  Mac before fleet use and re-run on each major macOS release.
- **Troubleshooting Guide** (`06-troubleshooting.md`) — cross-cutting edge cases that span runbooks
  and macOS-specific pitfalls.
- **Best Practices** (`07-best-practices.md`) — documentation, training/enablement, and deliberate
  feature evaluation, plus Mac-specific live-environment safety.
- **Global Requirements — Infrastructure** (`global-requirements-infrastructure.md`) — the
  category-level prerequisites shared by all Infrastructure solutions.

## PowerShell scripts
All scripts read from Microsoft Graph with read-only scopes; the two that can change state default
to `-WhatIf`. Every script filters to macOS devices.

- **MACRUN-Discovery.ps1** — Mac fleet health/context discovery across target devices
  (enrollment, compliance, FileVault-escrow indicator, OS, primary user) (read-only).
- **MACRUN-Validation.ps1** — per-device state validation (enrollment, compliance with named
  non-compliant policies, assigned config profiles, recovery-key escrow) (read-only).
- **MACRUN-Report.ps1** — support-metrics / Mac-fleet-health summary report (read-only).
- **MACRUN-Remediation.ps1** — safe common fixes (Sync, Rotate FileVault key); defaults to `-WhatIf`.
- **MACRUN-Set-ScopeTargeting.ps1** — build/adjust pilot and support target groups; defaults to
  `-WhatIf`.

## How the pieces fit together
Read the **Overview** to learn the operating model, confirm the **Requirements**, then work Mac
tasks and tickets from the **Runbook Library**. Use **Discovery/Validation/Report** during the
*Checks* and *Document* stages, **Remediation** for the safe fixes (including Rotate FileVault key),
and **Set-ScopeTargeting** to correct group-based targeting. Prove everything on a pilot Mac using
the **Testing** gates, lean on **Best Practices** for documentation/training/feature evaluation, and
reach for **Troubleshooting** when a ticket doesn't fit a single runbook.

## Outcome
A Mac-support team that resolves issues the same repeatable way and adopts new features
deliberately — a runbook library, an enablement kit, and scripts you keep and reuse across the
fleet, at a fraction of the cost of ad-hoc consulting.
