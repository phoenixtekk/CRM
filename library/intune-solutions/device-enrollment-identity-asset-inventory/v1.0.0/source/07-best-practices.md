# 7. Best Practices — Device Enrollment, Identity Association & Asset Inventory

- **Pilot first, always.** Enroll a small `Enrollment – Pilot Devices – Pilot` group and validate the
  full chain — enrollment, primary user, reconciliation — before turning automatic enrollment to
  **All**. The pilot gate is the single most important practice.
- **Gate enrollment with restrictions.** Only allow the platforms and ownership types you actually
  support; a tight `Enrollment Restriction – Supported Platforms – Production` is what keeps the
  inventory clean from day one.
- **One rule for primary user.** Primary user = the daily user; shared/DEM devices have **none**.
  Apply it consistently so service-desk lookup always works — and don't "fix" shared devices to a
  person.
- **Use the enrollment status page for corporate Windows.** Blocking the desktop until apps/policies
  install means the device is ready before the user touches it, which prevents a wave of day-one
  tickets.
- **Reconcile on a cadence.** Run `ENROLLID-Report.ps1` against a "should exist" list regularly;
  chase stale records, duplicates, and missing owners while they are fresh, not at audit time.
- **Remediate safely.** Keep `ENROLLID-Remediation.ps1` in `-WhatIf` by default; review the planned
  changes, then commit per item. Never bulk-overwrite primary users blindly.
- **Name everything to a convention.** `<Purpose> – <Scope> – <Stage>` for every group, restriction,
  profile, and status page makes the tenant self-documenting and audits trivial.
- **Treat Intune as the source of truth — and keep it honest.** Inventory is only trustworthy if you
  retire stale records and resolve duplicates; a clean count is what the service desk relies on.
- **Document the enrollment methods you use.** Record which of Autopilot / Entra join / bulk-DEM /
  BYOD are enabled and for whom, so the next operator inherits a clear map.
- **Separate shared from assigned.** Keep shared/kiosk hardware in
  `Enrollment – Shared Devices – Production` so per-user logic and primary-user expectations never
  apply to it.
