# GCC High Parity Notes — Remote Help

This reference records what is **confirmed**, what **differs**, and what is **not available** for
Microsoft **Remote Help** on the US Government clouds (**GCC**, **GCC High**, **DoD**) versus
Commercial. Every claim is cited to Microsoft documentation or explicitly flagged **verify against
current Microsoft documentation** where sovereign parity is not confirmed. **Never assume Commercial
parity.** Sovereign availability changes — **the availability line below is the single most important
thing to re-verify at deployment time.**

## 0. The headline (confirmed at authoring time — re-verify)

> **Remote Help is NOT available on GCC High or DoD.** It is available in **GCC** (which, for Intune,
> is the **commercial** service instance). This inverts the usual "GCC High edition" assumption: there
> is no `*.us` Remote Help service to deploy. If your tier is GCC High / DoD, the compliant path is the
> **alternative** in §4, not a Remote Help rollout.

Sources (verify against current Microsoft documentation):
- Microsoft Learn — **"Plan for Remote Help with Microsoft Intune"** (`/intune/remote-help/plan`, ms.date 2026-06-24): *"Remote Help is supported in Government Community Cloud (GCC) environments except in Azure Virtual Desktop (AVD). Remote Help isn't supported on GCC High or DoD (U.S. Department of Defense) tenants."*
- Microsoft Learn — **"Microsoft Intune Government Service overview"** (`/intune/fundamentals/government-service`): lists **Remote Help** under **"Intune features planned for GCC High and DoD"** (not available; planning started; no ETA published).

## 1. Cloud-plane / endpoint parity (verify against current Microsoft documentation)

The correct plane depends on the tier. **A critical, easily-missed point:** Intune has **no separate
GCC instance** — GCC IS the commercial instance — so a GCC Remote Help deployment uses the
**commercial** endpoints, not `*.us`. GCC High / DoD administer on the `*.us` sovereign plane (but have
no Remote Help feature there yet).

| Purpose | GCC (commercial instance) | GCC High | DoD | Commercial |
|---|---|---|---|---|
| Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` | `intune.microsoft.us` | `intune.microsoft.com` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` | `entra.microsoft.us` | `entra.microsoft.com` |
| Azure portal | `portal.azure.com` | `portal.azure.us` | `portal.azure.us` | `portal.azure.com` |
| M365 admin center | `admin.microsoft.com` | `portal.office365.us` | `portal.office365.us` | `admin.microsoft.com` |
| Defender / security | `security.microsoft.com` | `security.microsoft.us` | `security.microsoft.us` | `security.microsoft.com` |
| Sign-in | `login.microsoftonline.com` | `login.microsoftonline.us` | `login.microsoftonline.us` | `login.microsoftonline.com` |
| Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` | `dod-graph.microsoft.us` | `graph.microsoft.com` |
| Graph PowerShell `-Environment` | `Global` | `USGov` | `USGovDoD` | `Global` |
| **Remote Help service endpoint** | `remotehelp.microsoft.com` (443, TLS 1.2, RDP) | **none — feature not offered** | **none — feature not offered** | `remotehelp.microsoft.com` |

Sources: Microsoft Learn — "Microsoft Graph national cloud deployments"; "Microsoft 365 U.S. Government
GCC High endpoints"; "Plan for Remote Help" (service endpoint / port / TLS). **Verify all against
current Microsoft documentation.**

## 2. Feature parity — where Remote Help IS available (GCC), vs Commercial (verify)

Where Remote Help runs (GCC / Commercial), the capability is broadly the same, but GCC has platform
limits. Confirm the current list against Microsoft Learn — "Plan for Remote Help."

| Area | Commercial | GCC | GCC High / DoD |
|---|---|---|---|
| Remote Help feature | ✅ Available | ✅ Available | ❌ **Not available** (planned, no ETA) |
| Azure Virtual Desktop (AVD) | ✅ Supported | ❌ **Not** supported | n/a |
| Windows / Windows ARM64 / Windows 365 | ✅ | ✅ | n/a |
| macOS 13 / 14 / 15 | ✅ | ✅ | n/a |
| Android (Samsung/Zebra, **dedicated** enrollment) | ✅ | ✅ | n/a |
| Conditional Access for helpers | Windows/macOS only | Windows/macOS only | n/a |
| Licensing (Remote Help add-on for helpers **and** sharers) | Required | Required (verify gov SKU) | n/a |
| Same-tenant requirement | ✅ | ✅ | n/a |

## 3. Security / consent model (where available — verify)

- **Entra-authenticated**, **same-tenant** helpers and sharers; **RBAC** decides view / full control /
  elevation / unattended.
- **Consent + on-screen indicator** on every session; **no session recordings** stored by the service;
  session metadata retained ~30 days by Microsoft (verify against current Microsoft documentation).
- **Unattended** is Android-dedicated only and should be used sparingly.
- Do not SSL-inspect the Remote Help service endpoint.

## 4. The compliant alternative for GCC High / DoD (because Remote Help is unavailable)

Since Remote Help is not offered on GCC High / DoD, do **not** fabricate a `*.us` Remote Help
deployment. Select a **compliant** governed-remote-assistance substitute **within your authorization
boundary**, matching Remote Help's security properties (authenticated, least-privilege, consent-based,
audited). Each option must be **verified for your impact level (IL4/IL5) and ATO against current
documentation**:

| Option | Fit | Verify before use |
|---|---|---|
| **Third-party remote-support tool with government authorization** (FedRAMP High / DoD IL4–IL5 authorized) | Closest functional match; governed, auditable | Confirm the product's authorization covers **your** IL and is permitted in your boundary; integrate identity + logging |
| **In-boundary Windows tooling** (Remote Desktop, Windows Remote Assistance) under existing controls | No new cloud dependency; stays in boundary | Confirm your STIG/security posture permits it; ensure session governance + auditing |
| **Quick Assist** | Microsoft-native, but consumer/commercial-plane | **Do not assume** it is authorized for GCC High / DoD — verify with your compliance authority first |
| **Wait + monitor the roadmap** | Remote Help is *planned* for GCC High / DoD | Track "Intune features planned for GCC High and DoD"; re-run the availability gate; adopt when it ships |

**Do not** drop in an unauthorized consumer/commercial tool to close the gap — that reintroduces the
ungoverned-access risk Remote Help exists to remove.

## 5. Verify against current Microsoft documentation (the moving parts)

Treat all of the following as **verify** — do not assume Commercial parity, and re-check at deployment
time:

- **Remote Help availability on GCC High / DoD** — the gating item; it is *planned*, so it may have
  shipped since authoring. Re-read the government-service overview and the Remote Help plan page.
- **Exact sovereign admin-portal URLs** for Intune / Entra / Azure / M365 / Defender in GCC High **and**
  DoD (DoD paths can differ from GCC High).
- **Government Remote Help / Intune Suite SKU names** and whether the add-on is offered for your tier.
- **Supported-platform list and AVD exclusion** in GCC.
- **Network endpoint list** for Remote Help ("Network endpoints for Remote Help").
- **Conditional Access support scope** for Remote Help helpers.

## 6. Sources
- Microsoft Learn — *Plan for Remote Help with Microsoft Intune*: `https://learn.microsoft.com/en-us/intune/remote-help/plan`
- Microsoft Learn — *Microsoft Intune Government Service overview*: `https://learn.microsoft.com/en-us/intune/fundamentals/government-service`
- Microsoft Learn — *Use Remote Help to assist users authenticated by your organization*: `https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/remote-help`
- Microsoft Learn — *Microsoft Graph national cloud deployments*: `https://learn.microsoft.com/en-us/graph/deployments`
- Microsoft Learn — *Connect-MgGraph* national-cloud `-Environment` values: `https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph`
- Microsoft Learn — *Apps for GCC High and DoD environments*: `https://learn.microsoft.com/en-us/intune/app-management/deployment/deploy-gcc-dod`

> All availability, endpoint, licensing, and platform specifics above must be **verified against
> current Microsoft documentation** at deployment time. The availability line (§0) is the one that most
> often changes.
