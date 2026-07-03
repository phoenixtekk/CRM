# Requirements Guide — Microsoft 365 Copilot Secure Adoption & Governance (GCC High)

Confirm **every** requirement below before you configure anything. This is the Government (GCC High)
edition, so each item is written for the **US sovereign cloud** — the `*.us` portals and the US Gov
Graph. The **category-level** prerequisites (Entra tenant, admin roles, pilot group, network access,
change control) are in `global-requirements-security.md`; this guide adds the **Copilot- and
GCC-High-specific** requirements.

Each entry follows the house format: **Description · Why · Verify · Implement-if-missing.**

> **Portal note:** wherever the global requirements say `entra.microsoft.com`,
> `intune.microsoft.com`, etc., substitute the GCC High URL from the table in the Solution Overview
> (`entra.microsoft.us`, `endpoint.microsoft.us`, `compliance.microsoft.us`, `portal.office365.us`).

---

## R1. GCC High tenant (Entra ID **for Government**)

**Description:** An active Microsoft 365 **GCC High** tenant using **Microsoft Entra ID for
Government**.
**Why:** Copilot and its governance controls operate entirely inside the sovereign boundary; a
Commercial or GCC tenant is a different environment with different portals and identity authority.
**Verify:** Sign in to `https://portal.office365.us` and `https://entra.microsoft.us` as an admin and
confirm the tenant is a **GCC High** tenant (tenant type / domain suffix reflects your Gov tenant).
**Implement:** Onboard to GCC High through an authorized Microsoft Gov reseller/CSP; eligibility is
validated (ITAR/CUI handling). (Source:
[Copilot Studio US Gov customer eligibility](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-licensing-gcc).)

## R2. Copilot-eligible base licensing (GCC High)

**Description:** Users need an **eligible GCC High base plan** *plus* the **Microsoft 365 Copilot
add-on**.
**Why:** Copilot is an add-on; the base plan supplies the workloads (Exchange, SharePoint, OneDrive,
Teams, Office apps) Copilot reasons over.
**Verify:** In `https://portal.office365.us` → **Billing → Licenses**, confirm eligible base plans
(e.g. **Microsoft 365 G3 / G5**, or eligible Office 365 G-plans) and the **Microsoft 365 Copilot**
add-on are present. Microsoft lists GCC/GCC High/DoD Copilot as an add-on to **Microsoft 365 G3,
G5, F1** and **Office 365 G1/G3/G5/F3** (among others). (Source:
[Microsoft 365 Copilot licensing — US Government licenses](https://learn.microsoft.com/en-us/microsoft-365/copilot/microsoft-365-copilot-licensing).)
**Implement:** Purchase eligible base + Copilot add-on through your Gov CSP/VL channel.

> **Parity note — plan for what each SKU includes.** **G5 (GCC High)** includes the Purview and
> Defender suites Copilot leans on for sensitivity labeling, DLP, and threat protection; **G3**
> typically requires **Defender Suite GCCH** and **Purview Suite GCCH** add-ons to reach comparable
> coverage. Confirm your SKU actually includes the Purview capabilities this solution configures, or
> budget the add-ons. **Verify for your contract** — licensing bundles change. (General guidance;
> confirm current SKU contents with your licensing desk.)

## R3. Administrative roles (least privilege)

**Description:** The operator holds the right **Entra for Government** admin roles.
**Why:** Configuring labels, DLP, SharePoint/Copilot search controls, and assigning Copilot licenses
each require specific privileges; use least privilege, not blanket Global Admin.
**Verify:** In `https://entra.microsoft.us` → **Roles and administrators**, confirm the operator has
the roles needed for the tasks below.
**Implement:** Assign the minimum roles:
- **Compliance Administrator** (or **Compliance Data Administrator**) — sensitivity labels & DLP in
  Purview (`compliance.microsoft.us`).
- **SharePoint Administrator** — Restricted SharePoint Search and site-level controls.
- **License / User Administrator** — assign Copilot licenses.
- Reserve **Global Administrator** for tenant-wide switches only.

## R4. Sovereign portal access (all `*.us`)

**Description:** The operator can reach every GCC High portal this solution uses.
**Why:** A Commercial URL will not administer a GCC High tenant.
**Verify:** Confirm each of these loads *your* tenant: `portal.office365.us`, `entra.microsoft.us`,
`compliance.microsoft.us`, `security.microsoft.us`, `endpoint.microsoft.us`, `portal.azure.us`, and
(if using agents) `high.powerva.microsoft.us`.
**Implement:** Correct bookmarks/allow-lists to the `*.us` set; remove Commercial URLs to avoid
misconfiguration.

## R5. Network access to US Gov endpoints

**Description:** Outbound HTTPS to the **US Government** service endpoints, not the Commercial ones.
**Why:** Sign-in, Graph, Purview, SharePoint, and Copilot traffic in GCC High use `*.us` /
`*.usgovcloudapi.net` endpoints; filtering only Commercial ranges will break the tenant.
**Verify:** From an admin workstation, reach `https://login.microsoftonline.us` and
`https://graph.microsoft.us`.
**Implement:** Allow the US Gov endpoint set through proxy/firewall, including (per Microsoft's Gov
URL guidance) `*.microsoft.us`, `*.azure.us`, `*.usgovcloudapi.net`, `*.windows.net`, and the
`AzureCloud.usgovvirginia` / `AzureCloud.usgovtexas` IP ranges. (Source:
[Copilot Studio US Gov service URLs & IP ranges](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-licensing-gcc).)

## R6. Microsoft Graph PowerShell — US Gov environment

**Description:** The **Microsoft.Graph** PowerShell SDK, able to connect with `-Environment USGov`.
**Why:** All five scripts read/write via **US Gov Graph** (`graph.microsoft.us`); the default
(Global) environment will not resolve a GCC High tenant.
**Verify:** In PowerShell: `Get-Module Microsoft.Graph -ListAvailable`, then
`Connect-MgGraph -Environment USGov -Scopes "Sites.Read.All"` succeeds and
`(Get-MgEnvironment -Name USGov).GraphEndpoint` shows `https://graph.microsoft.us`.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts always pass
`-Environment USGov`; **never** run them against the default environment.

## R7. SharePoint / OneDrive governance baseline

**Description:** SharePoint Online (GCC High) with the ability to set tenant search and site-level
controls.
**Why:** Copilot's reach *is* SharePoint/OneDrive access; Restricted SharePoint Search and site
permissions are the primary guardrails.
**Verify:** SharePoint admin center (from `portal.office365.us` → **Admin centers → SharePoint**)
loads and you can open **Settings** and **More features → Restricted SharePoint Search**.
**Implement:** Ensure SharePoint Administrator role (R3) and that RSS is available in your tenant —
**verify for GCC High**, as feature availability can lag.

## R8. Microsoft Purview — sensitivity labels & DLP (GCC High)

**Description:** Purview in GCC High (`compliance.microsoft.us`) with **sensitivity labels** and
**DLP** available.
**Why:** Labels and DLP are how CUI is marked and how Copilot output/access respects
classification; they are the substance of "secure adoption."
**Verify:** `https://compliance.microsoft.us` loads; **Information protection → Labels** and
**Data loss prevention → Policies** are accessible.
**Implement:** Confirm your SKU includes Purview Information Protection + DLP (see R2 parity note);
add the Purview Suite GCCH add-on if on G3 without it.

## R9. A CUI sensitivity-label taxonomy (organization-mandated)

**Description:** Your program's **existing CUI label scheme** (e.g. a `CUI//BASIC` baseline label and
any specified categories).
**Why:** GCC High tenants handle CUI; Copilot governance must honor the *mandated* classification —
not one invented for this project.
**Verify:** Confirm which label taxonomy your organization/contract requires.
**Implement:** Use the mandated taxonomy in Purview. **Do not invent a label scheme.** Where this
solution names a label, it is a placeholder for your mandated one.

## R10. Pilot & expansion security groups

**Description:** Named Entra security groups for staged rollout: `SG-COPILOTG-Pilot` and
`SG-COPILOTG-Wave2`.
**Why:** Copilot is licensed and enabled by assignment; a named group is how you keep the pilot
bounded and expansion controlled.
**Verify:** `https://entra.microsoft.us` → **Groups** shows both groups.
**Implement:** Create them (or let `COPILOTG-Set-ScopeTargeting.ps1` build/populate them — it runs
**-WhatIf by default**).

## R11. Change control (authentication- and access-impacting)

**Description:** A documented change/rollback process (per global requirement G8) covering label,
DLP, and search-scope changes.
**Why:** RSS and DLP changes alter what users and Copilot can find; a bad rollout can hide needed
content or expose CUI. A pilot gate and rollback are mandatory.
**Verify:** A change ticket exists with approver, window, and rollback step.
**Implement:** Record the change, name the pilot group, define rollback, get approval before
production assignment.

---

**Gate to proceed:** R1–R11 all pass (or documented as N/A with reason). Only then move to the
Implementation Guide.
