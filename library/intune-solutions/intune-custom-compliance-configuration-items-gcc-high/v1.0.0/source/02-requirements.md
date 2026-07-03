# Requirements — Intune Custom Compliance & Configuration Items (Scripted), Government (GCC High) Edition

> The **category-level** prerequisites (Entra tenant, Intune subscription, admin roles, enrollment, pilot group, supported Windows baseline, network access) are covered once in **`global-requirements-intune-solutions.md`**. Confirm those first. The requirements below are **specific to custom compliance on a GCC High tenant** and to this solution's scripts. Each entry: **Description · Why · Verify · Implement-if-missing.**

Every **Verify** step uses the **US Gov (`*.us`)** portals and endpoints. If a link, script, or copied runbook points at a `.com` commercial URL, it is wrong for GCC High — stop and correct it.

---

## R1. GCC High tenant (US sovereign cloud), not Commercial or GCC-Moderate
**Description:** The tenant is a Microsoft 365 **GCC High** (US Government L4) tenant.
**Why:** GCC High uses distinct `*.us` admin portals, distinct device service endpoints (`*.manage.microsoft.us`), and the US Gov Microsoft Graph root (`https://graph.microsoft.us`). Commercial and GCC-Moderate use the worldwide endpoints; steps and scripts are not interchangeable ([Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments)).
**Verify:** Sign in at `https://intune.microsoft.us/` and `https://portal.azure.us/`. If those load your tenant (and `https://intune.microsoft.com` does **not**), you are in GCC High.
**Implement:** This solution assumes an existing GCC High tenant; provisioning GCC High is a Microsoft licensing/onboarding process outside this solution's scope. Confirm with your Microsoft government account team.

## R2. US Government Intune licensing (G3/G5 Gov)
**Description:** An Intune-bearing US Government plan — typically Microsoft 365 **G3/G5**, or EM+S E3/E5 for Government, or standalone Intune for Government.
**Why:** Custom compliance is an Intune device-compliance feature; it requires an Intune-licensed, enrolled device. Intune for GCC/GCC High is available standalone or within the Government EM+S E3/E5 SKUs.
**Verify:** `https://portal.office365.us/` → **Billing → Licenses**; confirm a Government SKU that includes Intune. In `https://intune.microsoft.us/` → **Tenant administration → Tenant status** shows active.
**Implement:** Assign a Government Intune SKU to the pilot users/devices before targeting them.

## R3. Roles: Intune Administrator (+ default scope tag) in the GCC High tenant
**Description:** The operator holds **Intune Administrator** in Entra, and — because the discovery-script upload workflow does **not** support scope tags — is assigned the **default** scope tag.
**Why:** Creating scripts and compliance policies requires elevated Intune rights. Microsoft explicitly notes that to **create, edit, or view custom compliance discovery scripts you must be assigned the default scope tag**, and the script upload workflow doesn't support scope tags ([Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script)).
**Verify:** `https://entra.microsoft.us` → **Roles and administrators** → confirm **Intune Administrator**. In `https://intune.microsoft.us/` → **Tenant administration → Roles → Scope (Tags)** → confirm your admin has the **Default** scope tag.
**Implement:** Assign **Intune Administrator**; ensure the Default scope tag is present on the admin's role assignment. Reserve Global Administrator for tenant-wide changes only.

## R4. Microsoft Graph PowerShell SDK connecting to US Gov
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used with **`-Environment USGov`**.
**Why:** All five scripts in this solution talk to `https://graph.microsoft.us`. On GCC High you connect with `Connect-MgGraph -Environment USGov`; the default (Global) connection targets `graph.microsoft.com` and will not see your government tenant ([Connect-MgGraph](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph)). **Graph Explorer is not supported for `graph.microsoft.us`**, so the PowerShell SDK is your API recon tool ([Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments)).
**Verify:** In PowerShell run `Get-Module Microsoft.Graph -ListAvailable`. Then test: `Connect-MgGraph -Environment USGov -Scopes "DeviceManagementConfiguration.Read.All"` and confirm `(Get-MgContext).Environment` returns **USGov**.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Confirm `USGov` is a valid environment with `Get-MgEnvironment`.

## R5. Graph permission scopes for discovery, validation, reporting, remediation
**Description:** Delegated (or app) Graph scopes for reading and writing device-management configuration and compliance.
**Why:** The scripts read compliance policies, scripts, devices, and groups, and (for the remediation/scope scripts, only when you disable `-WhatIf`) write them.
**Verify:** After `Connect-MgGraph -Environment USGov`, run `(Get-MgContext).Scopes` and confirm the scopes below are present.
**Implement:** Reconnect requesting the scopes:
- **Read-only** (Discovery, Validation, Report scripts): `DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`, `Group.Read.All`.
- **Write** (Remediation, Set-ScopeTargeting scripts, only when applying changes): `DeviceManagementConfiguration.ReadWrite.All`, `Group.ReadWrite.All`.
Consent to these in `https://entra.microsoft.us` if an admin-consent prompt appears.

## R6. A tested Windows discovery script + JSON rules file
**Description:** A PowerShell **discovery script** (Windows) and a matching **JSON rules file** defining the compliant conditions.
**Why:** Custom compliance requires both: the script returns discovered values as **compressed single-line JSON** (`ConvertTo-Json -Compress`), and the JSON rules file grades them. Each discovery script pairs with **exactly one** compliance policy, and each policy takes **exactly one** discovery script ([Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script)).
**Why the limits matter:** Script ≤ **1 MB**; output ≤ **1 MB**; Windows script must finish in **≤ 10 minutes**. Exceeding these makes the device fail to return data.
**Verify:** Run the discovery script locally on a representative Windows device and confirm it emits a single compressed JSON line whose keys exactly match the `SettingName` values in the JSON rules file (case-sensitive).
**Implement:** Use this solution's discovery-script pattern and `CUSTCOMPG-Rules.json` template; the `CUSTCOMPG-Validation.ps1` script checks key/type alignment before you upload.

## R7. Sovereign network endpoints allowed through filtering (no TLS break)
**Description:** Outbound access from managed devices to the **US Gov** Intune service endpoints, with **no SSL inspection** on `*.manage.microsoft.us`.
**Why:** Discovery scripts are delivered and compliance results returned over `*.manage.microsoft.us`; sign-in uses `login.microsoftonline.us`; device registration uses `enterpriseregistration.microsoftonline.us`. Microsoft states **SSL inspection is not supported on `*.manage.microsoft.us`** — a TLS-breaking proxy will cause silent check-in/compliance failures ([Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints)).
**Verify:** From a managed device, confirm reachability of `https://portal.manage.microsoft.us/` and `https://login.microsoftonline.us`, and confirm the proxy is **not** intercepting/re-signing `*.manage.microsoft.us`.
**Implement:** Allow `*.manage.microsoft.us`, `login.microsoftonline.us`, `enterpriseregistration.microsoftonline.us`, `graph.microsoft.us`, and `*.events.data.microsoft.com` through proxy/firewall; exempt `*.manage.microsoft.us` from SSL inspection. For EPM/Defender security-management, also allow `*.dm.microsoft.us`.

## R8. Windows devices enrolled in the GCC High tenant, in scope
**Description:** Target Windows 10 21H2+ / Windows 11 devices enrolled in **this** GCC High tenant and members of the pilot group.
**Why:** Compliance policies only reach enrolled, targeted devices; custom compliance for Windows requires a PowerShell-capable Windows client.
**Verify:** `https://intune.microsoft.us/` → **Devices → All devices** → target device appears, is **managed**, and is a member of `CUSTCOMPG-Pilot-Devices`.
**Implement:** Enroll via Automatic Enrollment / Entra join (see `global-requirements`), then add to the pilot group with `CUSTCOMPG-Set-ScopeTargeting.ps1` (run with `-WhatIf` first).

---

**Gate to leave Assess:** R1–R8 all **Verify** green, the discovery script emits valid compressed JSON matching the rules file, and `Connect-MgGraph -Environment USGov` returns `Environment = USGov`. Only then proceed to **Configure**.
