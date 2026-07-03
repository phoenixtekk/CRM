# Deliverables Summary — Cloud-First Autopilot Zero-Touch Provisioning (Government / GCC High)

Everything included in this Government (GCC High) edition, and where to start.

## Documents (`source/`)

| Document | What it gives you |
| --- | --- |
| `executive-summary.md` | One-page situation/complication/resolution for decision-makers — why GCC High is not "Commercial with a different login." |
| `01-solution-overview.md` | The zero-touch model in GCC High, the **Commercial vs GCC High — what's different** section, the standard deployment model, and the named objects. |
| `02-requirements.md` | Every solution-specific prerequisite with **Description · Why · Verify · Implement**, and the **Assess** pass/fail gate. |
| `03-implementation.md` | Ordered build steps in the **`*.us` portals**, with GCC-High-only caveats **inline** at each step. |
| `05-testing.md` | The **Validate** gate — T1–T6 with explicit pass/fail conditions. |
| `06-troubleshooting.md` | GCC-High-specific failure modes and fixes (empty device group, wrong cloud, blocked endpoints, WHfB PIN reset, etc.). |
| `07-best-practices.md` | Sovereign-cloud practices, including the servicing-without-Autopatch model. |
| `gcc-high-parity-notes.md` | The **cited** Commercial-vs-GCC-High reference; doc-confirmed vs "verify for GCC High." |
| `global-requirements-intune-solutions.md` | Category-level prerequisites shared by all Intune solutions (provided; not modified here). |

## PowerShell scripts (`scripts/`)

All connect to **Microsoft Graph US Gov** with **`-Environment USGov`** (USGovDoD
supported), print the resolved environment before acting, and use hyphenated placeholders
(e.g. `your-tenant-id`) — never angle brackets.

| Script | Type | Default safety | Purpose |
| --- | --- | --- | --- |
| `CFAPG-Discovery.ps1` | Read-only | n/a | Inventory the tenant's provisioning posture (groups, device-prep profiles, provisioning-client SP, enrollment configs). |
| `CFAPG-Validation.ps1` | Read-only | n/a | Pass/fail the build: groups exist, device group is **Assigned**, and the **Intune Provisioning Client owns** it. |
| `CFAPG-Report.ps1` | Read-only | n/a | Rollout report — Entra-join/enrollment/compliance state of devices in `CFAPG-Autopilot-Devices`, optional CSV. |
| `CFAPG-Remediation.ps1` | Changes state | **`-WhatIf` (preview) by default** | Adds the Intune Provisioning Client as **owner** of the device group (the #1 fix). Applies only with `-WhatIf:$false`. |
| `CFAPG-Set-ScopeTargeting.ps1` | Changes state | **`-WhatIf` (preview) by default** | Widen scope during **Expand** by adding members to `CFAPG-Provisioning-Users`. Applies only with `-WhatIf:$false`. |

**Prerequisite for scripts:** Microsoft Graph PowerShell SDK
(`Install-Module Microsoft.Graph -Scope CurrentUser`). Sign in with an account that holds
the read (or, for the two write scripts, write) permissions listed in each script header.

## Named objects created (verbatim)

`CFAPG-Provisioning-Users` · `CFAPG-Autopilot-Devices` (assigned; owner = Intune
Provisioning Client) · `CFAPG-Pilot` · `CFAPG-DevicePrep-UserDriven-EntraJoin` ·
`CFAPG-ESP-Provisioning` · `CFAPG Device Preparation Administrator` (RBAC role) ·
`CFAPG-UpdateRing-Pilot` · `CFAPG-Compliance-Win11` · `CFAPG` (scope tag).

## Suggested order of use

1. Read `executive-summary.md` and `01-solution-overview.md` (esp. **Commercial vs GCC
   High**).
2. Work the **Assess** gate in `02-requirements.md`; run `CFAPG-Discovery.ps1`.
3. Build per `03-implementation.md`; run `CFAPG-Validation.ps1` — fix any FAIL (use
   `CFAPG-Remediation.ps1` in preview first).
4. Pilot, then run the **Validate** gate in `05-testing.md` and `CFAPG-Report.ps1`.
5. **Expand** with `CFAPG-Set-ScopeTargeting.ps1` (preview, then apply).
6. Keep `06-troubleshooting.md`, `07-best-practices.md`, and `gcc-high-parity-notes.md`
   on hand throughout.

## The one thing to remember

**Classic Windows Autopilot does not exist in GCC High.** This solution delivers zero-touch
provisioning entirely on the supported **Windows Autopilot device preparation** path — right
portals, right technology, parity gaps handled.
