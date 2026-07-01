# Deliverables Summary

Everything included in this solution, and what each piece does.

## Documentation

| Document | Purpose |
|---|---|
| **Solution Overview** (`01-solution-overview.md`) | How per-app VPN works on iOS and Android, the managed-app-to-VPN association, on-demand behavior, and where Intune's per-app VPN config meets the Cisco head-end. |
| **Requirements** (`02-requirements.md`) | Every prerequisite with Description / Why / Verify / Implement-if-missing — Intune enrollment + managed apps, Cisco Secure Client app + VPN profile, certificate/auth method, Entra groups, pilot group, iOS supervised/ADE + APNs, Android Enterprise. |
| **Implementation Guide** (`03-implementation.md`) | Exact ordered steps: build the per-app VPN profile for iOS and Android, associate the named managed apps, assign to the pilot, validate only those apps tunnel, expand. |
| **Testing** (`05-testing.md`) | Pass/fail gates — associated apps tunnel, other traffic direct, on-demand, scope containment, rollback. |
| **Troubleshooting** (`06-troubleshooting.md`) | Fixes for VPN not triggering for the app, all traffic tunneling, and app not associated. |
| **Best Practices** (`07-best-practices.md`) | Running the managed-app model well over time. |
| **Global Requirements — Network** (`global-requirements-network.md`) | Category-wide prerequisites (Entra, Intune, admin roles, pilot group, change control/rollback). |
| **Executive Summary** (`executive-summary.md`) | One-page business framing for decision-makers. |

## PowerShell scripts

All scripts are **read-only** against Microsoft Graph except the two remediation/targeting tools,
which default to **`-WhatIf`** (preview) and change nothing until you opt in. Cisco head-end internals
are deferred to Cisco's documentation.

| Script | What it does | Default safety |
|---|---|---|
| **`CPAVPN-Discovery.ps1`** | Per-app VPN readiness: enumerates iOS/Android VPN profiles, managed apps, and assignments; confirms the Entra scope groups exist. | Read-only |
| **`CPAVPN-Validation.ps1`** | For a named managed device, confirms the per-app VPN profile is present and reports the app↔VPN association state. | Read-only |
| **`CPAVPN-Report.ps1`** | Per-app VPN coverage across managed mobile devices — which devices carry the profile, which apps are associated. | Read-only |
| **`CPAVPN-Remediation.ps1`** | Safely previews/fixes mis-scoped app/VPN associations (e.g. an app that should/shouldn't be associated). | `-WhatIf` by default |
| **`CPAVPN-Set-ScopeTargeting.ps1`** | Creates/populates the pilot (and broad) Entra targeting group(s). | `-WhatIf` by default |

### Required Microsoft Graph scopes

- **Discovery / Validation / Report (read-only):** `DeviceManagementConfiguration.Read.All`,
  `DeviceManagementApps.Read.All`, `DeviceManagementManagedDevices.Read.All`, `Group.Read.All`.
- **Remediation / Set-ScopeTargeting (write):** `DeviceManagementConfiguration.ReadWrite.All`,
  `DeviceManagementApps.ReadWrite.All`, `Group.ReadWrite.All`, `GroupMember.ReadWrite.All`.

## Named objects produced

| Object | Name |
|---|---|
| iOS per-app VPN profile | `Cisco Per-App VPN – iOS` |
| Android per-app VPN profile | `Cisco Per-App VPN – Android` |
| Client certificate profile (if cert auth) | `Cisco Per-App VPN – User Cert` |
| Pilot targeting group | `PILOT – Per-App VPN Users` |
| Broad targeting group | `BROAD – Per-App VPN Users` |

## Outcome

Named managed business apps on iOS and Android open the Cisco Secure Client tunnel on demand to reach
internal resources; all other traffic stays direct — proven on the pilot, reported across the fleet,
and rollback-ready.
