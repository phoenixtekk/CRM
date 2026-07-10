# GCC High Parity Notes — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion

This document is specific to the **Government (GCC High)** edition of this solution. It records the
national-cloud endpoints this deployment uses, the feature/connector parity questions you must resolve
against Microsoft's Government documentation (do **not** assume commercial parity), and the compliance /
data-residency context that motivates GCC High. It complements — it does not replace — the main
implementation, requirements, and testing docs.

> **Golden rule for the sovereign cloud:** GCC High and DoD (IL5) frequently **lag commercial** or lack
> features entirely, and endpoints differ. Wherever this document says **"verify against current
> Microsoft Government documentation,"** treat it as a required pre-work step, not a formality. Availability,
> GA-vs-preview status, pricing, and endpoints change; confirm them for **your** cloud before you plan on
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
| Microsoft 365 / Purview compliance portals | `*.office.com` / `compliance.microsoft.com` | **`*.office365.us` / GCC High `*.microsoft.us` equivalents** *(verify current URL)* | *(verify)* |

The delivered PowerShell scripts (`SENTDEPG-*.ps1`) default their `-Environment` parameter to
**`AzureUSGovernment`** for this edition. If you pass the value explicitly, keep it on the US Gov value.

---

## 2. Feature-parity considerations

Each item below **may differ, lag, or be unavailable** in GCC High/DoD relative to commercial. Confirm
each **against current Microsoft Government documentation** before you commit the ingestion/connector
plan.

- **Content hub catalog & data connectors.** The set of solutions and connectors published to Content
  hub can differ in GCC High/DoD. Confirm each of the five in-scope connectors — **Microsoft Entra ID,
  Microsoft Defender XDR, Microsoft 365 (Office 365), Azure Activity, and Syslog/CEF via AMA** — is
  present and **GA (not preview or unavailable)** in your Government cloud. *Verify.*
- **Microsoft Defender XDR connector & advanced-hunting tables.** The XDR connector, unified incident
  sync, and the specific advanced-hunting `Device*` event tables available in GCC High/DoD may lag
  commercial. *Verify which tables and sync behavior are supported in your cloud.*
- **Log tiers (Analytics vs Basic vs Auxiliary).** Table-tier eligibility and the Basic/Auxiliary log
  options evolve and can differ by cloud and by table. *Verify current tier eligibility per table in your
  Government tenant.*
- **Azure Monitor Agent (AMA) & supported Linux distributions.** The AMA is the syslog/CEF path here;
  supported distributions and the exact CEF installer command are region/cloud-specific. *Use the exact
  command shown on the connector page in your Government portal; verify distro support.*
- **Preview / AI capabilities.** Any preview feature, and AI-assisted capabilities (e.g. Copilot for
  Security integrations), are commonly delayed or absent in GCC High/DoD. Do **not** plan on them without
  confirmation. *Verify.*
- **Unified Defender portal onboarding for Sentinel.** Whether and how Microsoft Sentinel surfaces inside
  the US Gov Defender portal (`security.microsoft.us`) can differ from commercial. *Verify current
  onboarding path.*
- **Pricing & commitment tiers.** Sentinel / Log Analytics pricing differs by cloud; the `SENTDEPG-Report.ps1`
  cost projection is indicative only. *Verify current Government pricing before committing a commitment
  tier.*
- **Third-party / non-Microsoft connectors.** AWS, GCP, and specific appliance connectors follow the
  generic syslog/CEF pattern but per-vendor availability in GCC High/DoD varies. *Verify per vendor.*

---

## 3. Compliance & data-residency context (why GCC High)

This context explains *why* a public-sector or defense-industrial-base tenant chooses GCC High and what
the operator must confirm. **Accreditation-boundary and impact-level determinations are the customer's
ISSO / compliance decision — this document provides technical context, not an authorization.**

- **FedRAMP High.** Azure Government / GCC High services are offered to support **FedRAMP High** baselines.
  Which specific services in your architecture carry a current authorization is a determination to confirm
  with your compliance function. *Verify service-by-service authorization status.*
- **DoD Impact Levels (IL4 / IL5).** GCC High supports workloads up to **IL4**; **IL5** typically maps to
  the **DoD** cloud with its own endpoints (see §4). Confirm the impact level of the data you will ingest
  into the Sentinel workspace and that the target cloud matches it. *This is an ISSO determination.*
- **CMMC 2.0.** Defense-industrial-base tenants handling **CUI** commonly select GCC High to support
  **CMMC 2.0 Level 2** and NIST SP 800-171 control objectives. Sentinel telemetry (sign-in, audit,
  security logs) supports audit/accountability control families, but the accreditation itself is the
  customer's. *Verify scope with your assessor.*
- **ITAR / EAR & data residency.** GCC High provides **US-sovereign data residency** and US-persons
  operational handling, which is why **ITAR/EAR**-regulated data is kept out of commercial. Confirm the
  workspace **region** (fixed for life — see R1) satisfies your residency obligation, and that all
  ingestion paths keep data in the sovereign boundary. *Compliance determination.*
- **US-persons handling.** GCC High is operated with US-persons support screening. Confirm this satisfies
  the personnel-handling requirements applicable to your data. *Verify.*

The operator must confirm, with their compliance/security function: the required **impact level**, the
**accreditation boundary**, the **residency region**, and that every in-scope service carries the needed
authorization — before ingesting regulated data.

---

## 4. DoD (IL5) note

Where a tenant is **DoD / IL5** rather than GCC High, key differences apply and each must be **verified
against current Microsoft Government documentation**:

- **Microsoft Graph host is `dod-graph.microsoft.us`** (not `graph.microsoft.us`). Use
  `Connect-MgGraph -Environment USGovDoD` (verify the exact environment name for your module version).
- **Azure / PowerShell** still uses `-Environment AzureUSGovernment`, but service **endpoints and feature
  availability** for the DoD cloud can differ further from GCC High. *Verify.*
- **Portal URLs** for the Defender / compliance experiences may differ for DoD. *Verify current URLs.*
- **Feature and connector parity** is generally **most constrained** at IL5 — assume nothing is available
  without confirmation.

If you are unsure whether your tenant is GCC High or DoD, resolve that **before** running the scripts or
enabling connectors — the wrong environment/endpoint is the most common failure mode in the sovereign
cloud (see `06-troubleshooting.md`).
