# Deliverables Summary

This solution is a self-contained **runbook library** plus supporting scripts. Everything below is
yours to keep and reuse across the fleet.

## Documents
- **Solution Overview** (`01-solution-overview.md`) — the support operating model
  (intake → triage → diagnose → resolve/escalate → document), how it maps to an Intune-managed
  fleet, and the fixed anatomy every runbook uses.
- **Requirements Guide** (`02-requirements.md`) — the technician prerequisites (Intune read role,
  Graph read access, Remote Help/remote tooling, asset/user context, a place to record outcomes),
  each with Description / Why / Verify / Implement-if-missing, plus the category-level global
  requirements.
- **Runbook Library** (`03-implementation.md`) — the six categorized runbooks — sign-in/profile,
  OS/Windows Update, hardware/peripheral, application, network reachability, and
  enrollment/compliance — each with triage tree, checks, resolution, escalation gate, and evidence
  to collect.
- **Testing Guide** (`05-testing.md`) — pass/fail gates per runbook and per script, run on a pilot
  device before fleet use.
- **Troubleshooting Guide** (`06-troubleshooting.md`) — cross-cutting edge cases that span runbooks.
- **Best Practices** (`07-best-practices.md`) — consistent triage, evidence capture, and clean
  escalation.
- **Global Requirements — Infrastructure** (`global-requirements-infrastructure.md`) — the
  category-level prerequisites shared by all Infrastructure solutions.

## PowerShell scripts
All scripts read from Microsoft Graph with read-only scopes; the two that can change state default
to `-WhatIf`.

- **DESKSUP-Discovery.ps1** — endpoint health/context discovery across target devices (read-only).
- **DESKSUP-Validation.ps1** — per-device state validation (enrollment, compliance, key policies)
  (read-only).
- **DESKSUP-Report.ps1** — support-metrics / fleet-health summary report (read-only).
- **DESKSUP-Remediation.ps1** — safe common fixes (sync, cache/flush, targeted retries); defaults
  to `-WhatIf`.
- **DESKSUP-Set-ScopeTargeting.ps1** — build/adjust pilot and support target groups; defaults to
  `-WhatIf`.

## How the pieces fit together
Read the **Overview** to learn the operating model, confirm the **Requirements**, then work tickets
from the **Runbook Library**. Use **Discovery/Validation/Report** during the *Checks* and *Document*
stages, **Remediation** for the safe fixes, and **Set-ScopeTargeting** to correct group-based
targeting. Prove everything on a pilot device using the **Testing** gates, lean on **Best Practices**
for consistency, and reach for **Troubleshooting** when a ticket doesn't fit a single runbook.

## Outcome
Every technician resolves desktop issues the same repeatable way and owns them end to end — a
runbook library and scripts you keep and reuse across the fleet, at a fraction of the cost of
ad-hoc consulting.
