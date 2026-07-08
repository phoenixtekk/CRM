# 8. Deliverables Summary — Android Enterprise App Management via Managed Google Play (Intune)

## What you receive
A complete, self-guided package to deliver and govern Android apps through **managed Google Play** in
Microsoft Intune — store, private (LOB), and web apps, managed configuration, app protection, and
update-track control, targeted by enrollment model.

### Documentation
- **Solution Overview** — app types on managed Google Play, the four levers (approve+assign, managed
  config, app protection, update track), and how intent maps to each enrollment model.
- **Requirements Guide** — app-management-specific prerequisites (healthy connection, enrollment models,
  app inventory + package names, private/web publishing, managed-config schema, APP prerequisites,
  assignment groups), each with Verify / Implement, on top of the six category global requirements.
- **Implementation Guide** — ordered steps: groups → baseline → approve store app → private/web →
  assign to pilot (intent + track) → managed config → app protection → validate → expand, every object named.
- **Testing & Validation** — the four gates (Delivery, Configuration, Protection, Update track) as a
  per-model pass/fail matrix, with automated checks and evidence to capture.
- **Troubleshooting** — symptom → root-cause → fix for the common failures (approved app never appears,
  app not offered, config not applied, APP not enforced, wrong track, uninstall not taking).
- **Best Practices** — catalog governance, assignment discipline (the `assign`-replaces-all gotcha),
  managed config, APP layering, track piloting, and change safety.

### PowerShell tools (Microsoft Graph) — safe by default
| Script | Purpose | Default mode |
|--------|---------|--------------|
| **`ANDROIDAPP-Discovery.ps1`** | Inventory approved managed Google Play apps + assignment posture (intent, group, track, auto-update mode) | Read-only |
| **`ANDROIDAPP-AssignConfig.ps1`** | Stage an app **assignment** (intent + track + auto-update) and report managed-config attachment; write only with `-Commit` | `-WhatIf` |
| **`ANDROIDAPP-AppProtection.ps1`** | List Android app protection policies + assignments; stage/create a baseline APP policy with `-Commit` | Read / `-WhatIf` |
| **`ANDROIDAPP-Validation.ps1`** | Per-app report: has assignment? managed config? app protection? defined track/mode? — flags gaps | Read-only |
| **`ANDROIDAPP-Scope.ps1`** | Managed Google Play binding + app-sync health and scope check (pre-flight) | Read-only |

All scripts use `Connect-MgGraph` with **least scopes**, contain **no credentials or secrets**, and
gate every write behind `-Commit` (with `-WhatIf` preview).

## Outcomes
- Apps delivered through managed Google Play with the **right type and intent** per enrollment model.
- Apps arrive **pre-configured** via managed app configuration (including OEMConfig at the pattern level).
- Corporate app data **protected** via Android app protection policies.
- Updates **controlled** by track and auto-update mode, piloted before the fleet.
- A **pilot-first**, gated, reversible rollout with a documented rollback for every change.

## Assumptions & boundaries
- A **healthy managed Google Play binding** already exists (established by the connection-setup solution).
- Private LOB / web-app **publishing** happens on the **Google side** first; Intune approves and assigns.
- OEM (Samsung Knox / Zebra) and third-party app specifics are at the **pattern level** — vendor docs are
  authoritative for schemas/keys.
- **AMAPI transition, web/account-driven enrollment, and re-enrollment behavior are evolving** — verify
  against current Microsoft guidance / your tenant before high-impact changes.
