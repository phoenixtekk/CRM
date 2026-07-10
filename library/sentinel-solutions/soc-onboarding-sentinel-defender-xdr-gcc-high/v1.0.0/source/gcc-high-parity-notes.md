# GCC High Parity Notes — SOC Onboarding: Microsoft Sentinel + Defender XDR Unified Incidents

This document is specific to the **Government (GCC High)** edition of this solution. It records the
national-cloud endpoints this onboarding uses, the feature/connector parity questions you must resolve
against Microsoft's Government documentation (do **not** assume commercial parity), and the compliance /
data-residency context that motivates GCC High. It complements — it does not replace — the main
implementation, requirements, and testing docs.

> **Golden rule for the sovereign cloud:** GCC High and DoD (IL5) frequently **lag commercial** or lack
> features entirely, and endpoints differ. Wherever this document says **"verify against current
> Microsoft Government documentation,"** treat it as a required pre-work step. Availability, GA-vs-preview
> status, connector behavior, and endpoints change; confirm them for **your** cloud before you plan on
> them.

---

## 1. National cloud endpoints

These are the US Government hosts/portals this solution uses. Replace every commercial endpoint from the
sibling documentation with the GCC High equivalent below. **DoD (IL5) tenants use different Graph (and in
some cases portal) endpoints — see the DoD note.**

| Purpose | Commercial | GCC High (this edition) | DoD / IL5 |
| --- | --- | --- | --- |
| Sign-in / token (Azure AD authority) | `login.microsoftonline.com` | **`login.microsoftonline.us`** | `login.microsoftonline.us` |
| Azure / Microsoft Sentinel portal | `portal.azure.com` | **`portal.azure.us`** (Azure Government) | `portal.azure.us` |
| Microsoft Defender / unified security portal | `security.microsoft.com` | **`security.microsoft.us`** | `security.microsoft.us` *(verify)* |
| Entra / Azure AD admin center | `entra.microsoft.com` | **`entra.microsoft.us`** *(verify current GCC High URL)* | *(verify)* |
| Microsoft Graph | `graph.microsoft.com` | **`graph.microsoft.us`** | **`dod-graph.microsoft.us`** |
| PowerShell — Az environment | `AzureCloud` | **`AzureUSGovernment`** (`Connect-AzAccount -Environment AzureUSGovernment`) | `AzureUSGovernment` |
| PowerShell — Microsoft.Graph environment | `Global` | **`USGov`** (`Connect-MgGraph -Environment USGov`) | **`USGovDoD`** *(verify)* |
| Microsoft 365 / compliance portals | `*.office.com` / `compliance.microsoft.com` | **`*.office365.us` / GCC High `*.microsoft.us` equivalents** *(verify current URL)* | *(verify)* |

The delivered PowerShell scripts (`SOCXDRG-*.ps1`) document connecting with `Connect-AzAccount
-Environment AzureUSGovernment` for this edition. Confirm your context targets US Gov before running them.

---

## 2. Feature-parity considerations

Each item below **may differ, lag, or be unavailable** in GCC High/DoD relative to commercial. Confirm
each **against current Microsoft Government documentation** before you rely on it.

- **Microsoft Defender XDR data connector.** Confirm the Defender XDR connector (and its Content hub
  solution) is available and **GA** in your Government cloud, and that **incident synchronization** and
  **bi-directional status sync** behave as the commercial docs describe. Connector availability and sync
  fidelity can lag in GCC High/DoD. *Verify.*
- **Which Defender workloads feed it.** Defender for Endpoint, Office 365, Identity, and Cloud Apps each
  have their own Government-cloud availability and licensing. Confirm the workloads in your pilot scope
  are supported and licensed in your Government tenant (E5 / E5 Security / standalone). *Verify current
  licensing in your tenant.*
- **Unified security operations experience (Sentinel in the Defender portal).** Whether — and how — you
  can onboard Sentinel into the unified Defender portal experience **commonly lags in GCC High/DoD**. Do
  **not** promise buyers the single-pane experience without confirming it for their cloud. *Verify.*
- **Advanced-hunting / event tables & Fusion correlation.** The specific tables streamed and the
  availability of Fusion / alert-grouping correlation can differ by cloud. *Verify which are supported in
  your Government tenant.*
- **Tenant-scoped Sentinel permission for the connector.** The Defender XDR connector requires
  tenant-scoped Sentinel rights (Requirement 2.3); the exact role and how it is granted can differ in the
  sovereign cloud. *Verify the exact role in your Government tenant.*
- **Preview / AI capabilities.** Any preview feature and AI-assisted capabilities (e.g. Copilot for
  Security in the SOC workflow) are commonly delayed or absent in GCC High/DoD. *Verify.*

---

## 3. Compliance & data-residency context (why GCC High)

This context explains *why* a public-sector or defense-industrial-base SOC runs in GCC High and what the
operator must confirm. **Accreditation-boundary and impact-level determinations are the customer's ISSO /
compliance decision — this document provides technical context, not an authorization.**

- **FedRAMP High.** Azure Government / GCC High services support **FedRAMP High** baselines. Which specific
  services in your incident-management architecture carry a current authorization is a determination to
  confirm with your compliance function. *Verify service-by-service authorization status.*
- **DoD Impact Levels (IL4 / IL5).** GCC High supports workloads up to **IL4**; **IL5** typically maps to
  the **DoD** cloud with its own endpoints (see §4). Confirm the impact level of the incident/alert data
  flowing into the Sentinel workspace and that the target cloud matches it. *ISSO determination.*
- **CMMC 2.0.** Defense-industrial-base SOCs handling **CUI** commonly select GCC High to support **CMMC
  2.0 Level 2** and NIST SP 800-171 objectives — incident detection, response, and audit/accountability
  control families are directly supported by a unified, logged incident queue, but the accreditation is
  the customer's. *Verify scope with your assessor.*
- **ITAR / EAR & data residency.** GCC High provides **US-sovereign data residency** and US-persons
  operational handling, which is why **ITAR/EAR**-regulated organizations keep security operations out of
  commercial. Confirm the workspace **region** and every ingestion/sync path keep incident data in the
  sovereign boundary. *Compliance determination.*
- **US-persons handling.** GCC High is operated with US-persons support screening. Confirm this satisfies
  the personnel-handling requirements applicable to your data. *Verify.*

The operator must confirm, with their compliance/security function: the required **impact level**, the
**accreditation boundary**, the **residency region**, and that Sentinel, Defender XDR, and the connector
each carry the needed authorization — before operating on regulated incident data.

---

## 4. DoD (IL5) note

Where the SOC is **DoD / IL5** rather than GCC High, key differences apply and each must be **verified
against current Microsoft Government documentation**:

- **Microsoft Graph host is `dod-graph.microsoft.us`** (not `graph.microsoft.us`). Use
  `Connect-MgGraph -Environment USGovDoD` (verify the exact environment name for your module version).
- **Azure / PowerShell** still uses `-Environment AzureUSGovernment`, but **Defender XDR connector,
  incident-sync, and unified-experience availability** for the DoD cloud can differ further from GCC High.
  *Verify.*
- **Portal URLs** for the Defender / unified experiences may differ for DoD. *Verify current URLs.*
- **Feature and connector parity** is generally **most constrained** at IL5 — assume nothing (including
  the unified Sentinel + Defender experience and incident sync fidelity) is available without
  confirmation.

If you are unsure whether your tenant is GCC High or DoD, resolve that **before** running the scripts or
connecting Defender XDR — the wrong environment/endpoint is the most common failure mode in the sovereign
cloud (see `06-troubleshooting.md`, section E2).
