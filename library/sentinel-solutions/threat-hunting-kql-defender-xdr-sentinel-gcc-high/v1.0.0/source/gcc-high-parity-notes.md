# GCC High Parity Notes — Threat Hunting with KQL: Microsoft Defender XDR & Sentinel (Government edition)

This addendum is specific to the **Government (GCC High)** edition of this solution. It records the
national-cloud endpoints the solution uses, the GCC High/DoD **feature-parity considerations** you must
confirm, and the **compliance & data-residency context** that explains *why GCC High*. It does **not**
assert availability or make an authorization determination — where something may differ, it says
**verify against current Microsoft Government documentation**.

---

## 1. National cloud endpoints (what this solution uses)

| Purpose | Commercial | This edition (GCC High) | DoD (IL5) — verify |
| --- | --- | --- | --- |
| Sign-in / token host | `login.microsoftonline.com` | **`login.microsoftonline.us`** | `login.microsoftonline.us` |
| Microsoft Defender portal (advanced hunting, custom detections) | `security.microsoft.com` | **`security.microsoft.us`** | `security.microsoft.us` |
| Azure portal (Microsoft Sentinel — Azure Government) | `portal.azure.com` | **`portal.azure.us`** | `portal.azure.us` |
| Microsoft Graph (PowerShell `runHuntingQuery`, Sentinel/Az) | `graph.microsoft.com` | **`graph.microsoft.us`** | **`dod-graph.microsoft.us`** |
| Microsoft Graph PowerShell environment | `Global` | **`Connect-MgGraph -Environment USGov`** | **`-Environment USGovDoD`** |
| Az PowerShell / Azure environment | `AzureCloud` | **`Connect-AzAccount -Environment AzureUSGovernment`** | `AzureUSGovernment` |

The delivered PowerShell scripts (`THREATHUNTG-Discovery.ps1`, `THREATHUNTG-RunHuntLibrary.ps1`,
`THREATHUNTG-Validate.ps1`, `THREATHUNTG-Report.ps1`) **default to the US Gov cloud** (`AzureUSGovernment`
for Az; `USGov` for Graph, switchable to `USGovDoD` via `-GraphEnvironment`). All remain read-only.
*Confirm the exact current endpoints for your cloud against Microsoft Government documentation — national
cloud URLs and environment names occasionally change.*

## 2. Feature-parity considerations (verify each — do not assume commercial behavior)

GCC High and DoD frequently **lag commercial** or omit features. For a *proactive threat-hunting* program,
the parity items that most affect this solution are:

- **Advanced-hunting schema, tables, and columns.** The unified advanced-hunting schema in GCC High/DoD
  can differ from commercial — some tables (or specific columns) may be **absent, delayed, or named
  differently**, and the delivered hunts (`Hunt-LOLBins-Devices-Pilot`, `Hunt-RareParentChild-Devices-Pilot`,
  `Hunt-InboxRules-M365-Pilot`, `Hunt-RareServiceSignin-Entra-Pilot`, `Hunt-BeaconEgress-Network-Pilot`)
  assume tables like `DeviceProcessEvents`, `DeviceNetworkEvents`, `CloudAppEvents`, and `SigninLogs`.
  **Verify each table/column exists on the surface you run it on, against current Microsoft Government
  documentation.**
- **Advanced-hunting retention and query limits.** ~30-day retention and per-query/per-tenant row/time
  limits, plus `runHuntingQuery` API throttling, **may differ in GCC High/DoD.** *Verify.*
- **Defender pillar availability feeding the hunt surface.** The tables you can hunt depend on which
  Defender pillars are onboarded and streaming. In GCC High/DoD, **Defender for Cloud Apps (MDCA),
  Defender for Identity (MDI), and Defender for Office 365 (MDO)** feature sets and the connectors/
  telemetry that populate `CloudAppEvents`, `IdentityLogonEvents`/`IdentityInfo`, and `EmailEvents`
  **may lag or be partially available.** The `Hunt-InboxRules-M365-Pilot` (CloudAppEvents/OfficeActivity)
  and `Hunt-RareServiceSignin-Entra-Pilot` (SigninLogs) hunts in particular depend on this. *Verify pillar
  and connector availability against current Microsoft Government documentation before relying on those
  hunts.*
- **Custom detection rules & scheduled analytics rules (the promotion target).** Availability, limits,
  and behavior of Defender **custom detection rules** and Sentinel **scheduled analytics rules** used to
  promote a hunt **may differ by cloud/license in GCC High/DoD.** *Verify before promoting.*
- **Microsoft Sentinel data connectors.** Sentinel runs in Azure Government; specific **data connectors,
  solutions/content-hub items, and UEBA/notebook/ML features may be delayed or unavailable** versus
  commercial. A hunt can only find what is ingested. *Verify connector availability.*
- **Preview / AI features.** Preview capabilities and any **Copilot / Security Copilot** or AI-assisted
  hunting features are commonly **delayed or unavailable** in GCC High/DoD. Do not assume they are present.
  *Verify.*
- **Third-party / cross-cloud integrations.** Integrations that reach commercial-cloud or third-party
  endpoints may be **restricted** in the sovereign cloud. *Verify.*

None of the above is asserted as available or unavailable here — each is a **checkpoint** to confirm
against current Microsoft Government documentation for your specific cloud (GCC High vs DoD IL5).

## 3. Compliance & data-residency context (why GCC High)

GCC High exists so US public-sector and Defense-Industrial-Base (DIB) organizations can meet obligations
that commercial Microsoft 365 does not target. Relevant context for this solution:

- **FedRAMP High.** GCC High is designed to support **FedRAMP High** authorization boundaries. Your
  hunting telemetry, bookmarks, and hunt register may fall inside that boundary — confirm with your ISSO.
- **DoD Impact Levels (IL4 / IL5).** DoD workloads are categorized by **impact level**; **IL5** (and its
  `dod-graph.microsoft.us` endpoint) applies to certain DoD data. Whether your tenant/data requires IL5
  is a **customer determination**.
- **CMMC 2.0.** DIB contractors handling **CUI** frequently require **CMMC 2.0** alignment; GCC High is a
  common choice for the FCI/CUI data-handling posture. Threat-hunting evidence can contain CUI — handle
  bookmarks/register entries accordingly.
- **ITAR / EAR & data residency.** GCC High provides **US-sovereign data residency** and support handling
  aligned to **ITAR/EAR**-controlled data, with **US-persons** operational handling. If your hunting data
  may include export-controlled technical data, this is a primary reason to be in GCC High.
- **US-persons handling.** Government cloud support and operations are handled by screened **US persons** —
  relevant when hunting evidence includes controlled or sensitive data.

**Boundary:** the accreditation boundary, the applicable **impact level**, and whether specific data is
in scope are **the customer's ISSO / compliance / security team's determinations** — this solution
provides the **technical context and read-only method**, not the authorization. Confirm all determinations
with your compliance authority.

## 4. DoD (IL5) note

Where **DoD (IL5)** differs from GCC High, the most visible difference for this solution is the **Microsoft
Graph endpoint** — DoD uses **`dod-graph.microsoft.us`** (`Connect-MgGraph -Environment USGovDoD`) rather
than GCC High's `graph.microsoft.us` (`-Environment USGov`); Azure remains `AzureUSGovernment`
(`portal.azure.us`). Beyond the endpoint, **Defender pillar/table availability, advanced-hunting schema,
connector support, and feature timelines can differ again at IL5** versus GCC High. Treat every pillar,
table, connector, and feature as **verify against current Microsoft Government documentation** for your
specific DoD environment before relying on it.
