# Deliverables Summary — Windows Autopilot (Government / GCC High)

Everything included in this **Government (GCC High) edition** of Windows Autopilot, and how the
pieces fit the **Assess → Configure → Pilot → Validate → Expand** model. The solution is built
entirely on the **supported** GCC High technology — **Windows Autopilot device preparation**
(user-driven, Microsoft Entra join) — because **classic Windows Autopilot is not available in
GCC High/DoD**.

## Documents (in `source/`)

| File | What it gives you |
| --- | --- |
| `01-solution-overview.md` | The pivot (classic Autopilot unavailable → device preparation), the **Commercial vs GCC High — what's different** tables, the named-object set, and the deployment model. |
| `02-requirements.md` | The **Assess** gate — GCC-High- and device-preparation-specific prerequisites (R1–R10) with Verify/Implement for each, on top of the category `global-requirements`. |
| `03-implementation.md` | The **Configure** + **Pilot** steps — exact `*.us` portal navigation, named objects, GCC-High caveats inline at each step, culminating in the device preparation profile. |
| `05-testing.md` | The **Validate** gate — T1–T6 with explicit pass/fail conditions. |
| `06-troubleshooting.md` | GCC-High-ordered symptoms and fixes, plus an escalation checklist. |
| `07-best-practices.md` | Operating habits for a stable sovereign deployment. |
| `gcc-high-parity-notes.md` | The **cited** Commercial-vs-GCC-High reference, separating doc-confirmed facts from **"verify for GCC High"** flags. |
| `executive-summary.md` | One-page situation/complication/resolution for decision-makers. |
| `global-requirements-intune-solutions.md` | Category-level prerequisites shared by all Intune solutions. |

## PowerShell scripts (in `scripts/`)

All five connect to **Microsoft Graph US Gov** (`-Environment USGov`; `graph.microsoft.us`),
print the resolved environment on connect, and **refuse to make changes** when the environment
is not US Gov. Discovery/Validation/Report are **read-only**; Remediation and
Set-ScopeTargeting default to **`-WhatIf`** (preview before change).

| Script | Purpose | Changes anything? |
| --- | --- | --- |
| `WAPG-Discovery.ps1` | Read-only inventory of the current GCC High provisioning posture (environment, device-preparation profiles, `WAPG` groups, Provisioning Client SP). | No |
| `WAPG-Validation.ps1` | Read-only pass/fail checks for the **Validate** gate (groups exist, device group Assigned, **Provisioning Client owns it**, profile mode/join type, ESP/ring/compliance assignments). | No |
| `WAPG-Report.ps1` | Read-only deployment-status report (per-device / per-app / per-script) from the device-preparation monitoring surface. | No |
| `WAPG-Remediation.ps1` | Safely fixes the top failure — adds the **Intune Provisioning Client** as **owner** of the assigned device group. | Only with `-WhatIf:$false` |
| `WAPG-Set-ScopeTargeting.ps1` | Safely widens provisioning scope during **Expand** (adds members to a `WAPG` scope group). | Only with `-WhatIf:$false` |

## Named objects you will have built

`WAPG-Provisioning-Users` · `WAPG-Pilot` · `WAPG-Autopilot-Devices` (Assigned, Provisioning
Client owner) · `WAPG-DevicePrep-UserDriven-EntraJoin` · `WAPG-ESP-Provisioning` ·
`WAPG Device Preparation Administrator` (RBAC) · `WAPG-UpdateRing-Pilot` ·
`WAPG-Compliance-Win11` · `WAPG` (scope tag).

## Definition of done

- Every **Assess** requirement (R1–R10) verified.
- All **Configure** objects built with the exact names above, in the `*.us` portals.
- One device provisioned **zero-touch** end to end in **Pilot**.
- Every **Validate** gate (T1–T6) passes — most importantly, the Provisioning Client **owns**
  the device group.
- Scope widened deliberately in **Expand** with `WAPG-Set-ScopeTargeting.ps1` (preview first).

## The one thing to remember

**In GCC High there is no classic Autopilot, no hardware hash, and no deployment profile.**
The supported path is **Windows Autopilot device preparation** — user-driven, Entra join,
assigned device group owned by the Intune Provisioning Client. Build for that, service via
update rings, and validate on a pilot before you scale.

## Sources

- Microsoft, *Intune Government Service overview*; *Windows Autopilot device preparation
  overview / requirements*; *Network endpoints for US government deployments*; *Microsoft Graph
  national cloud deployments*. Full cited list in `gcc-high-parity-notes.md`.
