# 7. Best Practices — Endpoint PowerShell Deployment & Patch Automation Toolkit

- Always detect before you remediate. A detection script that exits `0`/`1` lets Intune fix only the
  devices that have drifted — never blindly run a change on every device.
- Pilot first, every time. Assign a new or changed remediation to `Endpoint Automation Pilot –
  Windows – Pilot` and pass the Testing Guide gate before adding the production group.
- Keep `-WhatIf` the default. The remediation and the deploy/cleanup runner should report planned
  actions before they change anything; flip to apply only after a clean pilot review.
- Make scripts idempotent. Running a remediation twice must be safe — check current state and exit
  early if the device is already healthy, so re-runs do no harm.
- Run in 64-bit as SYSTEM. Set `Run script in 64-bit PowerShell = Yes` so registry/file paths match;
  default to SYSTEM unless the task genuinely needs the logged-on user.
- Keep remediations fast and non-interactive. Intune enforces a timeout; do the minimum work, never
  prompt, and never assume a UI is present.
- Write a clear status line and the right exit code. Every script should print what it found/did and
  return non-zero on failure so Intune and `PSAUTO-Report.ps1` catch problems.
- Name everything consistently. Use `<Purpose> – <Scope> – <Stage>` for packages, groups, and
  schedules, and reuse the names verbatim across Intune and your docs for auditability.
- Centralize the record. Point the deploy/cleanup runner's `-LogPath` at a share or workspace so you
  have a durable, trendable history beyond Intune's built-in results.
- Version and document your scripts. Record the desired-state values, the schedule, and the target
  groups so the automation is repeatable and auditable.
