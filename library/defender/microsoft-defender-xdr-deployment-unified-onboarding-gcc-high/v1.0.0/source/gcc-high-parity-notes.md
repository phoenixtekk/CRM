# GCC High Parity Notes — Microsoft Defender XDR Deployment & Unified Onboarding (Government edition)

This addendum is specific to the **Government (GCC High)** edition of this solution. It records the
national-cloud endpoints the solution uses, the GCC High/DoD **feature-parity considerations** you must
confirm for each Defender pillar, and the **compliance & data-residency context** that explains
*why GCC High*. It does **not** assert availability or make an authorization determination — where
something may differ, it says **verify against current Microsoft Government documentation**.

---

## 1. National cloud endpoints (what this solution uses)

| Purpose | Commercial | This edition (GCC High) | DoD (IL5) — verify |
| --- | --- | --- | --- |
| Sign-in / token host | `login.microsoftonline.com` | **`login.microsoftonline.us`** | `login.microsoftonline.us` |
| Unified Defender portal (all pillar activation, RBAC, incidents, Secure Score, advanced hunting) | `security.microsoft.com` | **`security.microsoft.us`** | `security.microsoft.us` |
| Azure portal / Microsoft Entra ID (Azure Government) | `portal.azure.com` / `entra.microsoft.com` | **`portal.azure.us`** (Azure Government) | `portal.azure.us` |
| Intune / Endpoint Manager admin center (endpoint onboarding) | `intune.microsoft.com` | **`intune.microsoft.us`** — *verify current GCC High portal URL* | `intune.microsoft.us` — *verify* |
| Microsoft Graph (PowerShell scripts) | `graph.microsoft.com` | **`graph.microsoft.us`** | **`dod-graph.microsoft.us`** |
| Microsoft Graph PowerShell environment | `Global` | **`Connect-MgGraph -Environment USGov`** | **`-Environment USGovDoD`** |
| Az PowerShell / Azure environment (continuous export workspace) | `AzureCloud` | **`Connect-AzAccount -Environment AzureUSGovernment`** | `AzureUSGovernment` |

The delivered PowerShell scripts (`DEFXDRG-Discovery.ps1`, `DEFXDRG-Validate.ps1`, `DEFXDRG-Hunt.ps1`,
`DEFXDRG-Report.ps1`, `DEFXDRG-Onboard-DeviceRing.ps1`) **default to the US Gov cloud** — Graph
`-Environment USGov` (`graph.microsoft.us`), switchable to `-GraphEnvironment USGovDoD`
(`dod-graph.microsoft.us`) for DoD. `DEFXDRG-Onboard-DeviceRing.ps1` remains **`-WhatIf`/preview by
default**; every other script is read-only. *Confirm the exact current endpoints for your cloud against
Microsoft Government documentation — national-cloud URLs (especially the Intune/Entra admin-center hosts)
occasionally change.*

## 2. Feature-parity considerations (verify each — do not assume commercial behavior)

GCC High and DoD frequently **lag commercial** or omit features. For **onboarding the four XDR pillars**,
confirm each of the following against current Microsoft Government documentation for your cloud:

- **Defender for Endpoint (MDE).** Endpoint onboarding, EDR, and the Intune ↔ MDE connector are generally
  available in GCC High, but **specific advanced features, OS/platform support, and network endpoint
  lists differ in Government** — *verify the current Government onboarding endpoints and supported
  platforms.*
- **Defender for Identity (MDI).** Sensor OS support, the **DSA/gMSA** requirements, and the **MDI
  service URLs the sensors must reach** are Government-specific and can differ from commercial — *verify
  the current Government sensor endpoints and prerequisites before installing on domain controllers.*
- **Defender for Office 365 (MDO).** Preset policies (Safe Links / Safe Attachments / anti-phishing) are
  available, but **Attack Simulation Training and some MDO P2 capabilities have historically lagged or
  been unavailable in GCC High/DoD** — *verify current MDO feature availability; do not promise
  Attack Simulation Training without confirming it.*
- **Defender for Cloud Apps (MDCA).** MDCA availability and the specific **app connectors / catalog**,
  session controls, and the MDE-to-MDCA discovery integration **can differ or lag in GCC High/DoD** —
  *verify MDCA availability and connector support before relying on `CloudAppEvents`.*
- **Unified RBAC.** The Defender **unified role-based access control** activation steps and available
  roles/data-sources **may differ or roll out later in Government** — *verify current unified-RBAC
  availability and activation steps in your cloud.*
- **Cross-pillar correlation & advanced-hunting tables.** Correlation depends on all pillars streaming;
  in GCC High/DoD a table (`DeviceInfo`, `IdentityInfo`, `EmailEvents`, `CloudAppEvents`) may be **empty
  because the pillar/feature is not yet available in your cloud**, not because onboarding failed. *Verify
  table/pillar availability before treating an empty table as a defect.*
- **Automated Investigation & Response (AIR).** Available, but **behavior/limits can differ**; keep it
  **approval-gated** regardless (this is also a security-team decision). *Verify.*
- **Preview / AI features (incl. Security Copilot).** Preview capabilities and AI-assisted features are
  commonly **delayed or unavailable** in GCC High/DoD. Do not assume they are present. *Verify.*
- **Third-party / cross-cloud integrations.** Integrations reaching commercial-cloud or third-party
  endpoints may be **restricted** in the sovereign cloud. *Verify.*
- **Licensing SKUs.** Government/GCC High Defender SKUs differ from commercial; **entitlement to a pillar
  or feature does not imply the same plan behavior.** *Verify current Government licensing.*

None of the above is asserted as available or unavailable here — each is a **checkpoint** to confirm
against current Microsoft Government documentation for your specific cloud (GCC High vs DoD IL5).

## 3. Compliance & data-residency context (why GCC High)

GCC High exists so US public-sector and Defense-Industrial-Base (DIB) organizations can meet obligations
that commercial Microsoft 365 does not target. Relevant context for this solution:

- **FedRAMP High.** GCC High is designed to support **FedRAMP High** authorization boundaries. The
  Defender telemetry, incidents, Secure Score data, and any continuous-export workspace may fall inside
  that boundary — confirm with your ISSO.
- **DoD Impact Levels (IL4 / IL5).** DoD workloads are categorized by **impact level**; **IL5** (with its
  `dod-graph.microsoft.us` endpoint) applies to certain DoD data. Whether your tenant/data requires IL5
  is a **customer determination**.
- **CMMC 2.0.** DIB contractors handling **CUI** frequently require **CMMC 2.0** alignment; GCC High is a
  common choice for the FCI/CUI data-handling posture. XDR incident evidence can contain CUI — handle
  accordingly.
- **ITAR / EAR & data residency.** GCC High provides **US-sovereign data residency** and support handling
  aligned to **ITAR/EAR**-controlled data. If Defender telemetry may include export-controlled technical
  data, this is a primary reason to be in GCC High.
- **US-persons handling.** Government cloud support and operations are handled by screened **US persons** —
  relevant when incident evidence includes controlled or sensitive data.

**Boundary:** the accreditation boundary, the applicable **impact level**, and whether specific data is
in scope are **the customer's ISSO / compliance / security team's determinations** — this solution
provides the **technical onboarding method and context**, not the authorization. Confirm all
determinations with your compliance authority.

## 4. DoD (IL5) note

Where **DoD (IL5)** differs from GCC High, the most visible difference for this solution is the **Microsoft
Graph endpoint** — DoD uses **`dod-graph.microsoft.us`** (`Connect-MgGraph -Environment USGovDoD`) rather
than GCC High's `graph.microsoft.us` (`-Environment USGov`); Azure remains `AzureUSGovernment`
(`portal.azure.us`) and the Defender portal `security.microsoft.us`. Beyond the endpoint, **Defender
pillar availability (especially MDCA, MDO P2 / Attack Simulation Training, and preview/AI features),
unified-RBAC rollout, sensor endpoints, and feature timelines can differ again at IL5** versus GCC High.
Treat every pillar, connector, and feature as **verify against current Microsoft Government documentation**
for your specific DoD environment before relying on it.
