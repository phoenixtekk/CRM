# GCC High Parity Notes — Universal Print (cited)

This reference consolidates the **Commercial vs GCC High** differences for Universal Print, with
citations. Where Microsoft's Government documentation does not confirm a specific behavior, the
item is flagged **"verify for GCC High/DoD."** Nothing here is invented — every claim is either
cited to Microsoft or explicitly flagged as needing verification.

**Primary source:** Microsoft Learn — *Universal Print in Government*
(`https://learn.microsoft.com/en-us/universal-print/fundamentals/universal-print-government`,
page updated 2025-07-21). Supporting sources cited inline.

---

## 1. Availability by cloud

| Cloud | Universal Print available? | Source |
| --- | --- | --- |
| Commercial | Yes | Microsoft Learn, *Universal Print in Government* |
| **GCC** | **Yes (GA)** | Microsoft Learn, *Universal Print in Government*; Microsoft Community Hub GA announcement |
| **GCC High** | **Yes (GA)** | Microsoft Learn, *Universal Print in Government*; Microsoft Community Hub GA announcement |
| **DoD** | **No — not available** | Microsoft Learn FAQ: "Universal Print is currently not available in DoD." |

> **Bottom line:** This solution applies to **GCC High** (and GCC). It does **not** apply to
> **DoD** — there is no supported Universal Print deployment in DoD at authoring. *Verify for
> DoD* against the Microsoft 365 roadmap before assuming a change.

## 2. Admin portals & identity (GCC High)

| Function | Commercial | GCC High | Source |
| --- | --- | --- | --- |
| Azure / Universal Print portal | `portal.azure.com` | **`portal.azure.us`** | Microsoft Learn, *Universal Print in Government* (Usage/Reports on the UP portal); Graph national cloud deployments |
| Microsoft 365 admin | `admin.microsoft.com` | **`portal.office365.us`** | Microsoft 365 Government service descriptions |
| Intune / Endpoint | `intune.microsoft.com` | **`intune.microsoft.us`** (endpoint.microsoft.us) | Microsoft Government portal conventions — *verify current URL for your tenant* |
| Entra admin | `entra.microsoft.com` | **`entra.microsoft.us`** / Entra blade in `portal.azure.us` | Microsoft Government portal conventions — *verify current URL* |
| Identity authority | `login.microsoftonline.com` | **`login.microsoftonline.us`** | Microsoft Learn, *Universal Print in Government* (GCC High Entra ID endpoint); Graph national cloud deployments |
| Microsoft Graph | `graph.microsoft.com` | **`graph.microsoft.us`** | Microsoft Graph national cloud deployments (USGov) |
| Graph PowerShell env | `-Environment Global` | **`-Environment USGov`** | `Connect-MgGraph` docs; Graph national cloud deployments (USGov → `login.microsoftonline.us` / `graph.microsoft.us`) |

## 3. Universal Print service endpoints (GCC High)

From Microsoft Learn, *Universal Print in Government* → "Government endpoints":

| Service | GCC High endpoint |
| --- | --- |
| Print service | `https://print.print.azure.us` |
| Registration service | `https://register.print.azure.us` |
| Discovery service | `https://discovery.print.azure.us` |
| Notification service | `https://notification.print.azure.us` |
| Graph service (print) | `https://graph.print.azure.us` |
| Microsoft Entra ID | `https://login.microsoftonline.us/` |

For contrast, **GCC** uses Commercial endpoints **plus** `gcc-*.print.azure.us` variants, and
**DoD** endpoints are `*.print-dod.azure.us` — but DoD is not yet a supported deployment (§1).
(Source: same "Government endpoints" section.)

## 4. Windows client support (GCC High)

| Client | GCC High behavior | Source |
| --- | --- | --- |
| **Windows 11 22H2+** | **Natively supported** — no registry changes | Microsoft Learn, *Universal Print in Government* (Prerequisites + FAQ) |
| **Windows 10 / earlier Windows 11** | Supported **only** after adding three `HKCU\SOFTWARE\Microsoft\Print\MPS` registry values pointing at the US Gov authority/Graph | Microsoft Learn, *Universal Print in Government* (Prerequisites) |

The three registry values (deployable via Intune to the user context):

- `OAuthAuthority` = `https://login.microsoftonline.us/common`
- `MSGraphBaseUrl` = `https://graph.microsoft.us/v1.0`
- `MSGraphResourceId` = `https://graph.microsoft.us`

(Source: Microsoft Learn, *Universal Print in Government*, Prerequisites.)

## 5. Licensing (GCC High)

All users **including administrators** must hold an eligible license to use **or configure**
Universal Print (Microsoft Learn, *Universal Print in Government*, Licensing note). GCC High
SKUs and monthly job contributions:

| SKU | Part number | Jobs/month |
| --- | --- | --- |
| Microsoft 365 E3 GCC High | `SPE_E3_USGOV_GCCHIGH` | 100 |
| Microsoft 365 E5 GCC High | `SPE_E5_USGOV_GCCHIGH` | 100 |
| Microsoft 365 E3 Unattended GCC High | `SPE_E3_RPA1_USGOV_GCCHIGH` | 100 |
| Universal Print for GCC High (standalone) | `Universal_Print_for_GCCHIGH_USGOV_GCCHIGH` | 5 |

Additional volume is sold in **500** or **10,000** job add-on packs. Access can take **up to 24
hours** to appear after licensing. (Source: Microsoft Learn, *Universal Print in Government*,
Licensing → GCC High.)

## 6. Feature-parity gaps in GCC High (as of authoring)

Microsoft states it is "aiming for feature parity" but confirms specific gaps:

| Feature | Commercial | GCC High | Source / flag |
| --- | --- | --- | --- |
| **Delegated Administration** (scoped Printer Admin via Entra admin units) | Available; available in **GCC** | **"coming to GCC High soon"** | Microsoft Learn FAQ — *verify for GCC High* |
| **macOS client printing** | Available; available in **GCC** | **"not yet available for GCC High"** | Microsoft Learn FAQ — *verify for GCC High* |
| **Direct-connect UP-ready printers** | Emerging | **Not yet in GCC/GCC High** — use the connector | Microsoft Learn FAQ |
| Secure release (iOS/Android, QR/badge) | Available | **Works in GCC and GCC High** | Microsoft Learn FAQ |
| Access from outside the U.S. | N/A | **Allowed** for GCC and GCC High | Microsoft Learn FAQ |

## 7. Compliance context (informational)

Universal Print is **FedRAMP-certified via Office 365** and offered in GCC/GCC High to meet U.S.
government certification requirements; it adheres to Zero Trust principles and encrypts all
connections with **TLS 1.2**. (Sources: Microsoft Learn, *Universal Print in Government*;
Microsoft Community Hub GA announcement.) Specific accreditation levels for a given tenant
(e.g., DoD SRG IL, DFARS/NIST 800-171 scope) should be **verified for your tenant** against
Microsoft's current compliance documentation rather than assumed.

---

## Sources

- Microsoft Learn — *Universal Print in Government*:
  `https://learn.microsoft.com/en-us/universal-print/fundamentals/universal-print-government`
  (updated 2025-07-21) — endpoints, licensing, Windows support, FAQ parity statements.
- Microsoft Learn — *Installing the Universal Print connector*:
  `https://learn.microsoft.com/en-us/universal-print/fundamentals/universal-print-connector-installation`
  — connector prerequisites, `https://aka.ms/UPConnector`, clone warning, LocalSystem proxy.
- Microsoft Learn — *Microsoft Graph national cloud deployments*:
  `https://learn.microsoft.com/en-us/graph/deployments` — USGov → `login.microsoftonline.us`,
  `graph.microsoft.us`.
- Microsoft Learn — *Connect-MgGraph*:
  `https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph`
  — `-Environment USGov`.
- Microsoft Community Hub — *Announcing general availability of Universal Print in GCC/GCC High*:
  `https://techcommunity.microsoft.com/blog/publicsectorblog/announcing-general-availability-of-universal-print-in-gccgcc-high/3939936`
  — GA in GCC/GCC High.

> **Standing instruction:** GCC High parity changes over time. Before each deployment, re-check
> the *Universal Print in Government* page and the Microsoft 365 roadmap, and treat every "verify
> for GCC High/DoD" flag as a real pre-deployment task.
