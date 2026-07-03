# 1. Solution Overview — Microsoft Defender for Endpoint Integration (Government / GCC High)

This is the **Government (GCC High) edition** of the Microsoft Defender for Endpoint (MDE)
Integration solution. It walks a novice administrator through wiring **Microsoft Defender for
Endpoint** to **Microsoft Intune** on a **US sovereign-cloud (GCC High)** tenant, so device risk
signals drive compliance and access — using the **`.us` admin portals**, **US Gov service
endpoints**, and **US Gov Microsoft Graph**, with the **Commercial-vs-GCC High parity gaps** called
out where they change what you can do.

> **Why a separate Government edition?** GCC High is **not** the Commercial portal behind a different
> sign-in. The admin URLs differ, the device onboarding endpoints differ, the Graph environment
> differs, and **some MDE capabilities lag, are limited, or are absent** versus Commercial. Following
> Commercial steps on a GCC High tenant leads you to portals that don't exist there and to features
> that silently aren't present. This edition gives you the **sovereign-correct** path.

## What this solution delivers

The Intune ↔ MDE integration lets Defender assess **device risk in real time** and lets Intune
**automatically mark a compromised device noncompliant**, so Conditional Access can block it from
corporate resources until it is remediated. In this edition you will:

1. **Establish the service-to-service connection** between Intune (GCC High) and MDE (GCC High).
2. **Onboard devices** to MDE using an Intune **Endpoint detection and response (EDR)** policy.
3. **Wire the MDE machine risk score into a device compliance policy.**
4. **(Recommended) Enforce with Conditional Access** — require a compliant device.
5. **Validate on a pilot**, then **expand** in waves.

## The portals you will use (GCC High — memorize these)

| Purpose | Commercial URL | **GCC High URL (use this)** |
| --- | --- | --- |
| Sign-in / authentication | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Entra admin center | `entra.microsoft.com` | **`entra.microsoft.us`** |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Microsoft Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Microsoft Defender portal (MDE) | `security.microsoft.com` | **`security.microsoft.us`** |
| Microsoft Purview / compliance | `compliance.microsoft.com` | **`compliance.microsoft.us`** |
| Microsoft 365 admin center | `admin.microsoft.com` | **`portal.office365.us`** |

> The Defender portal URL differs again for **DoD** (`security.apps.mil`) and **GCC**
> (`security.microsoft.com`). This solution targets **GCC High → `security.microsoft.us`**. If your
> tenant is GCC or DoD, substitute the matching portal from the table in
> `gcc-high-parity-notes.md`. Cited: Microsoft, *"Microsoft Defender for Endpoint for US Government
> customers"* — Portal URLs.

## Commercial vs GCC High — what's different

Read this before you start. These are the differences that actually change the steps:

- **Different admin portals.** Every portal is a `.us` (or `portal.office365.us`) host, not `.com`.
  A bookmark or a doc that sends you to `security.microsoft.com` is Commercial and will show you the
  wrong (or an empty) tenant.
- **Different sign-in authority.** Authentication is `login.microsoftonline.us`. Scripts and API
  clients must target the **US Gov** authority, not the Commercial one.
- **Different Microsoft Graph environment.** Automation connects with
  **`Connect-MgGraph -Environment USGov`** (US Gov L4 Graph, `graph.microsoft.us`). A script that
  omits `-Environment USGov` silently talks to the Commercial cloud and returns nothing for your
  tenant.
- **Different MDE API base URIs.** The Defender for Endpoint API is
  `https://api-gov.securitycenter.microsoft.us` for **GCC High & DoD** (and
  `https://api-gcc.securitycenter.microsoft.us` for GCC) — **not** the public
  `api.securitycenter.microsoft.com`. Cited: Microsoft, *"…for US Government customers"* — API.
- **Different device onboarding/telemetry endpoints.** Devices must reach the **US Gov service
  URLs** (the "Gov/GCC/DoD" connectivity URL lists), not the Commercial MDE endpoints. Use the
  **streamlined** Gov URL list where supported to reduce the allow-list. Cited: Microsoft — Required
  connectivity settings (Gov/GCC/DoD).
- **Feature parity gaps.** Some capabilities are **not available** in GCC High/DoD (for example
  **Microsoft Threat Experts** and **enterprise IoT security**), and **Microsoft Secure Score** is
  present but omits some recommendations. Automated investigation & response and other analytics/
  reporting/integration surfaces have historically lagged Commercial — **verify what is present in
  your tenant today.** The full, cited map is in `gcc-high-parity-notes.md`.

> Everything else — the *shape* of the integration (connector → EDR onboarding → risk into
> compliance → Conditional Access) — is the same as Commercial. The prevention, detection,
> investigation, and remediation engine is the same underlying technology, built in the Azure US
> Government environment. Cited: Microsoft, *"…for US Government customers"* — overview.

## Objects this solution creates (named, and reused across the docs)

You will create and **reuse** these exact objects throughout the guide:

| Object | Name | Where |
| --- | --- | --- |
| Pilot security group | **`SG-MDE-Pilot`** | Entra (`entra.microsoft.us`) → Groups |
| Production wave group | **`SG-MDE-Prod-Wave1`** | Entra → Groups |
| EDR onboarding policy | **`MDE - EDR Onboarding - Pilot`** | Intune → Endpoint security |
| Windows compliance policy (risk-wired) | **`CP-Windows-MDE-Risk`** | Intune → Devices → Compliance |
| Conditional Access policy (optional) | **`CA-Require-Compliant-MDE`** | Entra → Conditional Access |

## The standard deployment model

Like every solution in this library, you follow **Assess → Configure → Pilot → Validate → Expand**,
with a **gate** at each boundary (do not proceed until the gate passes):

1. **Assess** — confirm GCC High tenant, US Gov licensing, roles, portal access, and endpoint
   reachability (`02-requirements.md`).
2. **Configure** — enable the connector, create the EDR onboarding policy, wire risk into compliance
   (`03-implementation.md`).
3. **Pilot** — assign to **`SG-MDE-Pilot`** only.
4. **Validate** — run the included scripts and the Testing Guide (`05-testing.md`); confirm devices
   onboarded, sensor healthy, risk score flowing, compliance reacting.
5. **Expand** — roll out to **`SG-MDE-Prod-Wave1`** and subsequent waves, re-validating each.

## What's inside

- **`02-requirements.md`** — every prerequisite with **Verify** and **Implement-if-missing**, tuned
  for GCC High (US Gov licensing, roles, `.us` portal access, Gov connectivity URLs).
- **`03-implementation.md`** — the exact ordered click-path on the GCC High portals, with GCC-High
  caveats inline at the step where they matter, including the **Intune ↔ MDE connector for Gov**.
- **`05-testing.md`** — pass/fail validation gates.
- **`06-troubleshooting.md`** — GCC-High-specific gotchas (wrong-cloud symptoms, endpoint blocks).
- **`07-best-practices.md`** — operating guidance for a sovereign tenant.
- **`gcc-high-parity-notes.md`** — the cited Commercial-vs-GCC High/DoD parity reference.
- **5 PowerShell scripts** — discovery, validation, reporting, safe remediation, and scope-group
  targeting, all connecting to **US Gov Graph** (`-Environment USGov`).

---
*Sources: Microsoft Learn, "Microsoft Defender for Endpoint for US Government customers"
(learn.microsoft.com/defender-endpoint/gov); "Integrate Microsoft Defender for Endpoint with Intune
for Device Compliance" (learn.microsoft.com/intune). Verify all GCC High / DoD specifics against
your tenant, as US Gov availability changes over time.*
