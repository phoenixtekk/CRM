# 7. Best Practices — Netskope Client Deployment & Traffic Steering at Scale (Intune)

- Always roll out in rings. A small `Device Group – Pilot – Stage1` proves the client, steering, and
  exceptions before any larger ring inherits them — the single most important practice for an
  agent that sits in the live traffic path.
- Gate every expansion on the pilot. Treat the pilot pass/fail gate as mandatory; never widen the app
  assignment or steering scope until the current ring is clean.
- One steering config, one exception list. Deliver `Steering Profile – Corporate – Production` and
  `Steering Exceptions – Business Apps – Production` consistently fleet-wide; avoid per-machine
  steering tweaks that drift and cannot be audited.
- Build the exception list deliberately and keep it auditable. Record which exception protects which
  business app; an undocumented exception is a silent coverage gap or a future broken app.
- Deliver the decryption certificate with the client. If you inspect SSL, assign the trusted-root
  certificate to the same ring groups as the app so HTTPS never breaks ahead of the client.
- Package for silent, unattended install. Use the vendor silent-install and tenant-enrollment switches
  (Netskope docs) and a reliable detection rule so Intune reports true install state.
- Validate health, not just install. A client can be installed but not enrolled or not steering;
  `NSCLIENT-Validation.ps1` checks running, enrolled, and steering — use it, don't assume.
- Keep a rollback path ready until broad is healthy. Disabling steering, pulling the app assignment, or
  reverting the exception list must be a known, approved move (global G7).
- Chase laggards every wave. Run `NSCLIENT-Report.ps1` on a schedule; a device with a failed or
  unhealthy client is an unprotected device.
- Remediate safely. Run `NSCLIENT-Remediation.ps1` in its default -WhatIf mode first to see what it
  would do before applying any change.
- Document the rollout. Record ring membership, steering config, exception entries, and certificate
  coverage for audits and repeatability.
