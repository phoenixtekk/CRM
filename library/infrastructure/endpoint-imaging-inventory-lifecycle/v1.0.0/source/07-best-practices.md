# 7. Best Practices — Endpoint Imaging, Inventory & Hardware Lifecycle Management

- Choose one provisioning method deliberately. Default to Windows Autopilot cloud provisioning; keep
  Configuration Manager task-sequence imaging only for sites/device types that genuinely need a
  custom on-disk image or offline deployment. Don't run both for the same population by accident.
- Register hardware identity at procurement. Capture the hardware hash (or have the OEM/reseller
  register devices to Autopilot) before the device reaches the user, so deployment is zero-touch.
- Make Intune the single source of truth. Reconcile against the enrolled-device inventory, never a
  side spreadsheet; a spreadsheet drifts the moment it is saved.
- Reconcile every cycle. Compare purchased serials against `IMGLIFE-Report.ps1` to catch
  procured-but-not-deployed and deployed-but-not-inventoried devices early.
- Use lifecycle-stage groups, named consistently. Move devices through
  `Device Lifecycle – Procurement – Procured`, `– Fleet – Deployed`, `– Aging – Refresh-Due`, and
  `– End-of-Life – Retire`, and reuse those exact names everywhere.
- Define refresh criteria up front. Decide the trigger (age, warranty, spec) so refresh is a rule,
  not a guess, and procure replacements before devices fail.
- Always preview a wipe. Run `IMGLIFE-Remediation.ps1` in its default WhatIf mode and confirm the
  target device before any retire/wipe — the action is irreversible.
- Retire clean, every time. Choose Retire vs. Wipe deliberately, confirm completion, then remove the
  record and de-register from Autopilot so inventory stays accurate.
- Pilot before the fleet. Validate the full procure → deploy → refresh → retire flow on the pilot
  group before expanding.
- Document the lifecycle. Record the chosen provisioning method, refresh criteria, and the retire/
  wipe authorization for audits and repeatability.
