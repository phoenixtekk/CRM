# Solution Overview — Intune Custom Compliance & Configuration Items (Scripted), Government (GCC High) Edition

## What this solution delivers

This solution takes **Intune Custom Compliance & Configuration Items (Scripted)** and re-authors it for a **US sovereign cloud (GCC High)** tenant. Custom compliance lets you extend Intune device-compliance evaluation beyond the built-in settings: you upload a **PowerShell discovery script** plus a **JSON rules file**, Intune runs the script on each targeted Windows device, and the returned values are graded against the JSON. Devices that fail can be marked **not compliant**, which then drives Conditional Access, notifications, and remediation.

On GCC High this is **not** the commercial portal with a different sign-in. The admin consoles, the device service endpoints, and the Microsoft Graph API you script against are all **`*.us` / US Gov** URLs, and some capabilities lag or differ from commercial. This edition gives you the correct sovereign portals and endpoints, the exact ordered steps, and an explicit map of where commercial guidance would silently mislead you.

You get:

- A **discovery script** authored for Windows devices, packaged and ready to upload.
- A **JSON rules file** pattern (SettingName / Operator / DataType / Operand / MoreInfoUrl / RemediationStrings).
- Five **PowerShell scripts** that connect to **US Gov Graph** (`-Environment USGov`) to discover, validate, report, safely remediate, and build the scope/target group — all read-only by default except where explicitly gated behind `-WhatIf`.
- A **testing and troubleshooting** playbook with GCC-High-specific gates.

The deployment model is the standard one used across every solution in this library: **Assess → Configure → Pilot → Validate → Expand**, with a gate at the end of each phase.

## Named objects (create once, reuse everywhere)

Use these names consistently across the portal, the JSON, and the scripts so the solution is auditable and repeatable. Adjust the prefix to your naming standard, but keep it consistent:

| Object | Suggested name | Where it lives |
| --- | --- | --- |
| Discovery script | `CUSTCOMPG-Discovery-Win` | Intune → Endpoint security → Device compliance → Scripts |
| Custom compliance policy | `CUSTCOMPG-Compliance-Baseline` | Intune → Devices → Compliance |
| JSON rules file | `CUSTCOMPG-Rules.json` | Uploaded into the compliance policy |
| Pilot group | `CUSTCOMPG-Pilot-Devices` | Entra (`entra.microsoft.us`) → Groups |
| Production group | `CUSTCOMPG-Prod-Devices` | Entra → Groups |
| Scope tag | `CUSTCOMPG` | Intune → Tenant administration → Roles → Scope tags |

## Commercial vs GCC High — what's different

This is the section that keeps a government deployment from failing. If you (or a script, or a copied runbook) use commercial URLs on a GCC High tenant, sign-in and API calls fail or return nothing — often **silently**.

| Area | Commercial | GCC High (this edition) | Source |
| --- | --- | --- | --- |
| Intune admin center | `https://intune.microsoft.com` | `https://intune.microsoft.us/` | [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| Entra admin center | `https://entra.microsoft.com` | `https://entra.microsoft.us` | [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| Azure portal | `https://portal.azure.com` | `https://portal.azure.us/` | [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) |
| M365 admin | `https://admin.microsoft.com` | `https://portal.office365.us/` | [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| Defender portal | `https://security.microsoft.com` | `https://security.microsoft.us` | Microsoft GCC High portal references (verify for GCC High) |
| Company Portal | `https://portal.manage.microsoft.com` | `https://portal.manage.microsoft.us/` | [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| Sign-in / auth | `login.microsoftonline.com` | `login.microsoftonline.us` | [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) |
| Microsoft Graph root | `https://graph.microsoft.com` | `https://graph.microsoft.us` (L4/GCC High) | [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) |
| Graph PowerShell connect | `Connect-MgGraph` (Global) | `Connect-MgGraph -Environment USGov` | [Connect-MgGraph](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph) |
| Device service endpoints | `*.manage.microsoft.com` | `*.manage.microsoft.us` | [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| Graph Explorer (browser API tester) | Supported | **Not supported** for `graph.microsoft.us` | [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) |

Additional GCC High realities to plan around (detailed with citations in `gcc-high-parity-notes.md`):

- **Feature lag.** Microsoft states that certain services and features available in the global service may not be available in national clouds, and government clouds commonly trail commercial by weeks or months. Before relying on any newer custom-compliance behavior, **verify it is live in your GCC High tenant** rather than assuming commercial documentation applies.
- **No Graph Explorer.** You cannot use the browser-based Graph Explorer against `graph.microsoft.us`; do your API recon with the Microsoft Graph PowerShell SDK using `-Environment USGov` (that is exactly what the five scripts in this solution do).
- **No third-party MDM/MAM integration** in GCC High — plan to do everything natively in Intune.
- **SSL inspection is not supported** on `*.manage.microsoft.us`; if your proxy breaks TLS, discovery-script delivery and compliance check-in will fail.

## Who this is for

Government tenants (DoD contractors, agencies, CMMC-scoped organizations) running Microsoft 365 GCC High that need to enforce compliance conditions Intune's built-in settings don't cover — for example, a required security agent version, a registry hardening value, a TPM/BIOS attribute, or a third-party app baseline — and need it done with the **correct sovereign portals and endpoints**, proven on a pilot before scaling.

> **Sourcing note:** URLs and behaviors marked with a Microsoft Learn citation are confirmed against current Microsoft documentation (retrieved July 2026). Items marked *"verify for GCC High"* are drawn from Microsoft government-portal references that Microsoft has not re-confirmed on a first-party Learn page for every capability; confirm them live in your own tenant before production rollout. Nothing in this solution is invented.
