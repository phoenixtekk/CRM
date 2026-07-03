# Solution Overview — DISA STIG Compliance for Windows 10 & 11 in Microsoft Intune (Government / GCC High edition)

## What this solution is

This is the **Government (GCC High / DoD) edition** of the *DISA STIG Compliance for Windows 10 & 11 in Microsoft Intune* solution. It shows a novice administrator how to stand up, pilot, validate, and expand a Windows STIG-alignment program on Microsoft Intune **inside the US sovereign cloud** — the environment used by GCC High (Impact Level 4 / IL4) and Department of Defense (IL5) tenants.

It is **not** the Commercial guide with a different sign-in URL. In the US Government cloud the admin portals live on **`*.us`** domains, Microsoft Graph uses **US Gov endpoints**, and a number of Intune capabilities are **delayed, limited, or absent** versus Commercial. Following Commercial steps on a GCC High tenant leads to authentication failures and to configuring features that silently do not exist. This edition uses the correct sovereign portals and endpoints throughout and calls out every Commercial-vs-GCC-High parity gap at the step where it matters.

> **DISA STIG rule content is deferred to the authoritative source.** The **Security Technical Implementation Guides (STIGs)** themselves — the rule IDs (`SV-…`), Group IDs (`V-…`), CCIs, severities, and check/fix text — are published and maintained by the **Defense Information Systems Agency (DISA)** at the **DoD Cyber Exchange** ([`https://public.cyber.mil/stigs/`](https://public.cyber.mil/stigs/)) and are read with **STIG Viewer**. This solution does **not** reproduce or invent STIG rule IDs. It teaches you the repeatable Intune **delivery and validation mechanism**; you obtain the current DISA STIG benchmark (e.g., *Microsoft Windows 11 STIG*, *Microsoft Windows 10 STIG*) from DISA and map its rules to Intune settings.

## The problem it solves

STIGs were written for domain-joined, Group Policy-managed Windows. Moving that control set to **cloud-managed (Intune / MDM)** Windows in a **sovereign** tenant introduces three compounding problems:

1. **Translation** — each STIG rule must be expressed as an Intune setting (Settings Catalog, ADMX/Administrative Templates, or a custom OMA-URI), and not every GPO setting has a 1:1 MDM equivalent.
2. **Sovereign portals** — the work happens in `intune.microsoft.us`, not `intune.microsoft.com`; app registrations, scripts, and reporting all target US Gov Graph.
3. **Parity gaps** — some Intune features an admin would reach for in Commercial (for example Windows Autopilot, Remote Help, Windows Update-for-Business feature/quality update policies) are **not available** in GCC High/DoD, so the deployment design must route around them.

This solution supplies a proven, repeatable method plus five PowerShell scripts (all US-Gov-Graph-aware) so a government tenant is configured **correctly on the first pass**, piloted safely, validated with evidence, and expanded under change control.

## Commercial vs GCC High / DoD — what's different

The single most important thing to internalize before you touch anything:

| Area | Commercial | GCC High / DoD (this edition) |
| --- | --- | --- |
| Intune admin center | `https://intune.microsoft.com` | **`https://intune.microsoft.us`** |
| Entra / Azure portal | `https://entra.microsoft.com` · `https://portal.azure.com` | **`https://portal.azure.us`** (Entra blades via the Azure Gov portal) |
| Microsoft 365 admin | `https://admin.microsoft.com` | **`https://portal.office365.us`** |
| Defender portal | `https://security.microsoft.com` | **`https://security.microsoft.us`** |
| Purview / compliance | `https://compliance.microsoft.com` | **`https://compliance.microsoft.us`** |
| Sign-in authority | `https://login.microsoftonline.com` | **`https://login.microsoftonline.us`** |
| Microsoft Graph host | `graph.microsoft.com` | **`graph.microsoft.us`** (GCC High) · **`dod-graph.microsoft.us`** (DoD) |
| Graph PowerShell env | `-Environment Global` (default) | **`-Environment USGov`** (GCC High) · **`-Environment USGovDoD`** (DoD) |
| Device check-in / service | `*.manage.microsoft.com` | **`*.manage.microsoft.us`** |
| STIG **audit** baseline (Advanced Analytics) | Rolling out | **GCC High only**, requires Advanced Analytics add-on; **audit-only** (assesses, does not enforce) — *verify current availability for your tenant* |
| Windows Autopilot (classic) | Available | **Not available** — use Autopilot **device preparation** (partial) or Entra join + Autopilot-independent enrollment |
| Remote Help | Available | **Planned / not yet available** — *verify for GCC High/DoD* |
| Windows Update feature/quality/expedite/driver policies | Available | **Not available** in GCC High/DoD — plan servicing another way |
| Cloud PKI | Available | **Planned (GCC High only)** — *verify* |
| Security Copilot in Intune | Available | **Not available** |

Sources for the parity table are Microsoft's US Government service description and endpoint docs — see **`gcc-high-parity-notes.md`** for the full cited list. Because these lists change as Microsoft ships features into the sovereign cloud, every gap in this solution is written as **"verify for GCC High/DoD"** and pinned to a Microsoft US Gov citation rather than asserted as permanent.

## How STIG settings are delivered in Intune (unchanged mechanism, sovereign portal)

STIG rules reach Windows devices through the **same three Intune delivery mechanisms** in the sovereign cloud as in Commercial — you just author them in `intune.microsoft.us`:

1. **Settings Catalog** — the primary, modern surface. Most STIG-relevant CSP/ADMX settings are here. In GCC High with **Advanced Analytics** enabled, Microsoft also surfaces a **STIG audit baseline** (audit-only) in Advanced Analytics that assesses devices against DISA STIG recommendations — *verify this is enabled/available for your tenant*.
2. **Administrative Templates (ADMX)** — for classic policy settings expressed as ADMX-backed CSPs.
3. **Custom / OMA-URI profiles** — for STIG rules whose CSP has no catalog UI yet.

Enforcement and audit are complementary: **enforce** the configuration with Settings Catalog/ADMX/custom profiles, and **audit/report** with the STIG audit baseline (where available) plus the reporting script in this package.

## Named objects you will create (reuse these names throughout)

To keep the deployment auditable, this solution names its objects once and reuses them. Create them exactly as written:

- **Security group (pilot):** `SG-STIG-Pilot-Devices`
- **Security group (production):** `SG-STIG-Prod-Devices`
- **Settings Catalog profile(s):** `STIG-Win-SettingsCatalog-{domain}` (e.g., `STIG-Win-SettingsCatalog-Account`, `-Audit`, `-Defender`)
- **Administrative Templates profile:** `STIG-Win-ADMX-{domain}` (e.g., `STIG-Win-ADMX-Account`)
- **Custom/OMA-URI profile:** `STIG-Win-Custom-{rule-area}`
- **Compliance policy:** `STIG-Win-Compliance-Baseline`
- **(If used) Advanced Analytics STIG audit baseline instance:** `STIG-Win-AuditBaseline`

## The standard deployment model

Every solution in this library follows the same gated model, applied here to the sovereign cloud:

**Assess → Configure → Pilot → Validate → Expand**, with an explicit **gate** between each phase. You do not proceed to the next phase until the current phase's pass criteria are met (see `05-testing.md`). This is doubly important in GCC High/DoD, where mis-scoping a lockdown policy across an IL4/IL5 fleet is operationally expensive to unwind.

## What's inside this package

- **Source documents** — this overview, a requirements guide, an implementation guide (sovereign steps + caveats), testing, troubleshooting, best practices, a deliverables summary, an executive summary, and a cited GCC High parity reference.
- **5 PowerShell scripts** — Discovery, Validation, Report (read-only), Remediation and Set-ScopeTargeting (change-making, default `-WhatIf`), all connecting to **US Gov Graph** and supporting **`-Environment USGov`** and **`-Environment USGovDoD`**.

## Who this is for

Government (GCC High / DoD) administrators and their MSP/consulting partners who must bring Windows 10 & 11 endpoints into alignment with DISA STIGs using Intune, and who need the sovereign-cloud specifics handled correctly rather than discovered through failed sign-ins and missing features.
