# 8. Deliverables Summary — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

This solution is a complete, **deploy-it-today** package for provisioning, standardizing, and
locking down **shared clinical Windows devices** — WOWs, kiosks, nurse-station PCs, and clinical
tablets — with **Microsoft Intune**. Everything below ships in the package.

## Documents
1. **Executive Summary** (`executive-summary.md`) — the business case and what the package delivers.
2. **Solution Overview** (`01-solution-overview.md`) — what the shared-device model is and how it works, in plain language.
3. **Requirements Guide** (`02-requirements.md`) — R1–R11 with **Verify / Implement-if-missing** for every prerequisite.
4. **Global Requirements — Healthcare Solutions** (`global-requirements-healthcare-solutions.md`) — category-wide tenant, licensing, HIPAA/HITRUST, maintenance-window, network, test-device, and rollback prerequisites.
5. **Implementation Guide** (`03-implementation.md`) — ordered, click-by-click Intune steps with full navigation paths and every object named (Autopilot self-deploying profile, Shared PC profile, kiosk profile, power profile, `Clinical – Shared Devices` group).
6. **Testing Guide** (`05-testing.md`) — T1–T8 with PASS/FAIL and an acceptance gate.
7. **Best Practices** (`07-best-practices.md`) — operating the shared fleet reliably over time.
8. **Troubleshooting Guide** (`06-troubleshooting.md`) — the common failure modes and their fixes.

## PowerShell scripts (5)
All scripts default to **read-only**; the two that can change state require an explicit `-Apply`
(and support `-WhatIf`). Each carries a `.SYNOPSIS` with PURPOSE / HOW TO RUN / EXPECTED RESULTS
and a neutral `.NOTES` ("Healthcare Solutions — read-only.").

1. **`CLINDEV-Discovery.ps1`** — inventory shared clinical devices: enrollment type, Shared PC state, group membership, and primary user (should be none). *Read-only.*
2. **`CLINDEV-Validation.ps1`** — per-device PASS/FAIL: enrolled, in `Clinical – Shared Devices`, Shared PC / kiosk profile applied, clinical apps installed, no primary user. *Read-only.*
3. **`CLINDEV-Report.ps1`** — fleet report: counts by device type / profile / compliance → CSV. *Read-only.*
4. **`CLINDEV-Remediation.ps1`** — safe fixes: clear stray primary user, re-assign missing profiles. *Defaults to `-WhatIf`; `-Apply` to act.*
5. **`CLINDEV-Set-SharedDeviceGroup.ps1`** — create the dynamic `Clinical – Shared Devices` group (keyed on Autopilot profile / enrollment) and optionally assign profiles/apps. *Supports `-WhatIf`.*

## Visual
- **`CLINDEV-hero.png`** — hero image for the solution listing.

## What this delivers
A standardized shared-clinical-device platform: devices **self-provision unattended** via an
Autopilot self-deploying profile, run in **Shared PC mode** with no personal owner, are
**kiosk-locked** where single-purpose, carry a **Required clinical app baseline**, and **stay
awake on cart battery** — validated against an acceptance gate and rolled out in waves under
change control.
