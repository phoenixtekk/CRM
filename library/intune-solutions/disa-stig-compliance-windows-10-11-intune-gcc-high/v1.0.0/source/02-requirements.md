# Requirements Guide — Government / GCC High edition

This guide lists every prerequisite for delivering DISA STIG alignment via Intune **in the US Government cloud (GCC High / DoD)**, and for each one tells you how to **verify** it and how to **implement it if it is missing**.

> The **category-level global requirements** (Entra tenant, Intune subscription, admin roles, enrollment, pilot group, supported Windows, network access) are published once in **`global-requirements-intune-solutions.md`** and are **not** repeated in full here. This document covers the **GCC-High/DoD-specific** requirements *and* restates the global ones only where the sovereign cloud changes how you verify or implement them (different portal URLs, licensing SKUs, endpoints).

Each entry: **Description · Why · Verify · Implement-if-missing.**

---

## R1. A GCC High or DoD tenant (not Commercial, not GCC)

**Description:** The work must be performed in a **US Government cloud** tenant — GCC High (IL4) or DoD (IL5).
**Why:** Intune's government instance is a physically separate, locked-down datacenter shared by GCC High and DoD. Commercial and GCC/GCC-High/DoD are different clouds; there is **no in-place migration** between them (devices must unenroll and re-enroll). Using Commercial steps/URLs against a Gov tenant fails.
**Verify:** Sign in at **`https://intune.microsoft.us`**. If that portal loads and `intune.microsoft.com` does **not** represent your tenant, you are in the Gov cloud. Confirm the sign-in authority is `login.microsoftonline.us`.
**Implement:** Acquire the appropriate US Government subscription through an authorized channel (GCC High or DoD). This is a procurement/onboarding action, not a portal toggle. *Note: "GCC" (state/local) is the Commercial Intune instance — this edition is specifically for **GCC High / DoD**.*

## R2. US Government licensing that carries Intune (Gov SKUs)

**Description:** An Intune-bearing **US Government** license plan for each targeted user/device.
**Why:** Only Gov SKUs light up the government Intune instance.
**Verify:** `https://portal.office365.us` → **Billing → Licenses**; confirm an Intune-bearing Gov plan (e.g., **Microsoft 365 G3/G5 (GCC High or DoD)**, **Enterprise Mobility + Security E3/E5 (Gov)**, or **Intune Plan 1 (Gov)**) is assigned.
**Implement:** Purchase/assign the Gov equivalent of the plan you'd use in Commercial. Confirm the exact SKU name with your licensing channel — **verify for GCC High/DoD**, since SKU naming differs from Commercial.

## R3. Correct sovereign portal access for the operator

**Description:** The operator can reach the **`*.us`** admin portals.
**Why:** All configuration happens on sovereign URLs; Commercial URLs won't represent the Gov tenant.
**Verify:** Confirm you can load, signed in as an admin: `https://intune.microsoft.us`, `https://portal.azure.us`, `https://portal.office365.us`, and (for validation/reporting) `https://security.microsoft.us`.
**Implement:** If a portal is blocked, allow the `*.us` admin hostnames through web filtering (see R6) and confirm the account exists in the Gov tenant.

## R4. Administrative roles (in the Gov tenant)

**Description:** **Intune Administrator** (and, for role/scope work, appropriate Entra roles) held **in the GCC High/DoD tenant**.
**Why:** Creating configuration profiles, compliance policies, and scope tags requires elevated rights; roles are per-tenant.
**Verify:** `https://portal.azure.us` → **Microsoft Entra ID → Roles and administrators** → confirm **Intune Administrator** on the operator account.
**Implement:** Assign **Intune Administrator** in the Gov tenant. Reserve **Global Administrator** for tenant-wide changes only. (This restates global **G3** using the sovereign portal.)

## R5. Windows 10 / 11 devices enrolled in the Gov Intune instance

**Description:** Targeted Windows 10 (21H2+) / Windows 11 devices are Entra-joined and enrolled into the **government** Intune instance.
**Why:** Policies only reach enrolled devices, and enrollment must be into the Gov instance (device check-in uses `*.manage.microsoft.us`).
**Verify:** `https://intune.microsoft.us` → **Devices → All devices**; confirm the pilot devices appear and check in.
**Implement:** Enable **automatic enrollment** for Windows in the Gov tenant (`intune.microsoft.us` → **Devices → Enrollment**) and Entra-join devices. **Caveat:** classic **Windows Autopilot is not available** in GCC High/DoD — use **Autopilot device preparation** (partial support) or a non-Autopilot enrollment path. **Verify for GCC High/DoD.** (Restates global **G4** with the sovereign caveat.)

## R6. Network access to US Government endpoints (not Commercial endpoints)

**Description:** Outbound HTTPS from devices and admin workstations to the **`*.us`** service endpoints.
**Why:** Enrollment, policy sync, authentication, script/app delivery, and reporting all use sovereign endpoints; SSL inspection is **not supported** on `*.manage.microsoft.us`.
**Verify:** From a managed device, confirm reachability to `login.microsoftonline.us`, `enterpriseregistration.microsoftonline.us`, and `*.manage.microsoft.us`. From the admin workstation, confirm `graph.microsoft.us` (GCC High) or `dod-graph.microsoft.us` (DoD).
**Implement:** Allow, through proxy/firewall (and **exclude from SSL inspection** where noted): `*.manage.microsoft.us`, `login.microsoftonline.us`, `enterpriseregistration.microsoftonline.us`, `graph.microsoft.us` / `dod-graph.microsoft.us`, `*.dm.microsoft.us` (Defender/EPM), `*.events.data.microsoft.com`. See `gcc-high-parity-notes.md` for the cited endpoint list. (Restates global **G7** with sovereign hosts.)

## R7. Microsoft Graph PowerShell configured for US Gov

**Description:** The **Microsoft.Graph** PowerShell module installed and able to connect with **`-Environment USGov`** (GCC High) or **`-Environment USGovDoD`** (DoD).
**Why:** The five scripts in this package, and any Graph automation, must target the sovereign Graph host (`graph.microsoft.us` / `dod-graph.microsoft.us`), not `graph.microsoft.com`.
**Verify:** In PowerShell 7+, run `Get-MgEnvironment` and confirm **`USGov`** and **`USGovDoD`** are listed; run `Connect-MgGraph -Environment USGov -Scopes "DeviceManagementConfiguration.Read.All"` and confirm `Get-MgContext` shows the Gov account.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Use **PowerShell 7+**. If the interactive sign-in popup hangs from a jumpbox, disable the WAM broker: `Set-MgGraphOption -DisableLoginByWAM $true`, then reconnect.

## R8. The authoritative DISA STIG benchmark content

**Description:** The current **DISA STIG** benchmark(s) for your OS — e.g., *Microsoft Windows 11 STIG*, *Microsoft Windows 10 STIG* — plus **STIG Viewer**.
**Why:** This solution deliberately does **not** ship STIG rule IDs or check/fix text. You map DISA's authoritative rules to Intune settings; the rules must come from DISA.
**Verify:** You have the current benchmark ZIP(s) from the **DoD Cyber Exchange STIGs Document Library** and can open them in **STIG Viewer**.
**Implement:** Download from **`https://public.cyber.mil/stigs/downloads/`** (STIG Viewer from the same site). Track the **benchmark version/release date** — STIGs are revised on a DISA cadence, and your Intune mapping must be re-checked when the benchmark updates.

## R9. (Optional) Advanced Analytics for the STIG audit baseline

**Description:** The Intune **Advanced Analytics** add-on, which surfaces a **STIG audit baseline** in GCC High.
**Why:** It provides an audit-only assessment of Windows devices against DISA STIG recommendations (it **assesses**, it does **not enforce**). Enforcement still comes from your Settings Catalog/ADMX/custom profiles.
**Verify:** `https://intune.microsoft.us` → **Reports → Advanced Analytics** (or Endpoint security → Security baselines) shows the **STIG** audit baseline. Availability is **GCC High only** and requires the add-on. **Verify for GCC High/DoD** — DoD availability and current status can differ.
**Implement:** License the **Advanced Analytics** add-on (in addition to Intune Plan 1/Plan 2) via your Gov licensing channel, then enable it in the tenant.

## R10. Change control / evidence process

**Description:** A documented change-control and evidence-capture process appropriate to an IL4/IL5 environment.
**Why:** STIG programs are audited; every policy change should be traceable, and every phase gate should produce evidence (the Report script emits this).
**Verify:** You have a place to store `STIGG-Report.ps1` output (JSON/CSV) and a change-approval record for each policy assignment.
**Implement:** Define who approves scope-target changes, where evidence is retained, and how the benchmark-version → policy-version mapping is recorded.

---

### Requirements at a glance

| # | Requirement | Sovereign specifics |
| --- | --- | --- |
| R1 | GCC High / DoD tenant | `intune.microsoft.us`; no Commercial↔Gov migration |
| R2 | Gov Intune licensing | G3/G5 Gov, EMS Gov, or Intune P1 Gov — verify SKU |
| R3 | Sovereign portal access | `*.us` admin URLs reachable |
| R4 | Intune Administrator (Gov) | assigned via `portal.azure.us` |
| R5 | Windows enrolled in Gov instance | Autopilot classic N/A — device prep / non-Autopilot |
| R6 | US Gov network endpoints | `*.manage.microsoft.us`, no SSL inspection |
| R7 | Graph PowerShell US Gov | `-Environment USGov` / `USGovDoD`, PS7+ |
| R8 | DISA STIG benchmark | from `public.cyber.mil`; track version |
| R9 | Advanced Analytics (optional) | STIG audit baseline, GCC High, audit-only |
| R10 | Change control / evidence | IL4/IL5 audit readiness |
