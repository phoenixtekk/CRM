# 2. Requirements Guide — Compliance-Failure Diagnostics (Government / GCC High)

Confirm every requirement below **before** diagnosing. The category-level prerequisites
(`global-requirements-intune-solutions.md`) still apply — but on GCC High you must confirm them using
the **`*.us` sovereign portals**, not the Commercial `.com` ones. Each entry: **Description · Why ·
Verify · Implement-if-missing.** Anything Microsoft does not explicitly confirm for GCC High is marked
**"verify for GCC High."**

> **Golden rule:** if any URL you open, allow, or script against ends in `.com`, stop — on GCC High
> it should almost always end in `.us`. See the portal map in section 1.

## R1. A GCC High (or DoD) tenant on the US Government cloud
**Description:** The tenant is provisioned in the Intune **government cloud** (GCC High / DoD, IL4/IL5),
not Commercial or GCC (which shares the Commercial Intune instance).
**Why:** Every portal, endpoint, and Graph call in this pack targets `*.us`; on a Commercial tenant
they won't resolve to your data.
**Verify:** You sign in at **`https://intune.microsoft.us`** and the admin center loads with your
tenant. **Tenant administration → Tenant status** shows an active Intune subscription.
**Implement:** GCC High is purchased through an authorized government/agency licensing path; it cannot
be converted from a Commercial tenant in place (devices must unenroll and re-enroll). Engage your
licensing provider.

## R2. US Government licensing that includes Intune
**Description:** A Gov plan that bears Intune — e.g. **Microsoft 365 G3 / G5 (GCC High)**, **Enterprise
Mobility + Security G3/G5**, or standalone **Intune Plan 1 for Government**.
**Why:** Compliance policy evaluation and Conditional Access require Intune (and Entra ID P1/P2 for CA).
**Verify:** `portal.office365.us` → **Billing → Licenses**; confirm a Gov SKU that includes Intune and
Entra ID P1 or higher.
**Implement:** Assign the Gov SKU to affected users.

## R3. Administrative roles (assigned in the Gov portals)
**Description:** The operator holds **Intune Administrator** (and read access to Entra sign-in / CA).
**Why:** Editing compliance policies, assignments, and Conditional Access requires elevated rights.
**Verify:** **`portal.azure.us`** → **Microsoft Entra ID → Roles and administrators** → confirm
**Intune Administrator** (and, for CA changes, **Conditional Access Administrator** or **Security
Administrator**).
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.
For the scripts, the same account signs in via `Connect-MgGraph -Environment USGov`.

## R4. Microsoft Graph PowerShell configured for US Gov
**Description:** The **Microsoft.Graph** PowerShell modules, used with **`-Environment USGov`**
(or **`USGovDoD`** for DoD).
**Why:** Without `-Environment`, the module authenticates against **Commercial** Graph and returns
nothing for a GCC High tenant — the No. 1 scripting failure on GCC High.
**Verify:** In PowerShell: `Get-MgEnvironment` lists **USGov** (graph = `https://graph.microsoft.us`,
login = `https://login.microsoftonline.us`) and **USGovDoD** (graph = `https://dod-graph.microsoft.us`).
Then `Connect-MgGraph -Environment USGov -Scopes "DeviceManagementManagedDevices.Read.All"` succeeds.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. The built-in Microsoft Graph
PowerShell app is supported for USGov/USGovDoD (no custom app registration required); other sovereign
clouds do require a custom app — **verify for GCC High** if your tenant is in a different sovereign
cloud.

## R5. Device network access to the US Gov service endpoints (no TLS break)
**Description:** Managed devices reach the **`*.us`** Intune service endpoints for enrollment,
compliance check-in, and reporting — **without SSL/TLS inspection** on the endpoints where Microsoft
prohibits it.
**Why:** A device that cannot check in (or whose TLS is broken by a proxy) sits at **Not evaluated** or
goes **stale**, which reads as non-compliant to Conditional Access.
**Verify:** From an affected device, confirm reachability of the endpoints below; confirm your proxy is
**not** doing TLS interception on `*.manage.microsoft.us` or `*.dm.microsoft.us`.
**Implement:** Allow these through the proxy/firewall (HTTP **80** and HTTPS **443**), unauthenticated
where noted, and **exclude them from SSL inspection**:

| Endpoint (GCC High / US Gov) | Used for |
| --- | --- |
| **`*.manage.microsoft.us`** | Intune enrollment, compliance check-in, reporting. **No SSL inspection.** Needs *unauthenticated* proxy access for some tasks (e.g. software-update downloads). |
| **`*.dm.microsoft.us`** | Defender for Endpoint security-settings-management and Endpoint Privilege Management check-in/reporting. **No SSL inspection.** |
| **`login.microsoftonline.us`** | Sign-in / token issuance (Evo STS). |
| **`enterpriseregistration.microsoftonline.us`** | Entra device registration (ADRS). |
| **`graph.microsoft.us`** (DoD: `dod-graph.microsoft.us`) | Microsoft Graph — used by these scripts and by the portal. |
| **`portal.manage.microsoft.us`** | Company Portal (web) for end users. |
| **`has.spserv.microsoft.com`** | Health/attestation service dependency. **No SSL inspection.** (This one is a `.com` host by Microsoft's design — verify against the current Gov endpoints list.) |
| **`*.events.data.microsoft.com`** | Client-health diagnostic data. |

> Endpoints and IPs change as the service scales; always re-confirm against Microsoft's live
> **"Network endpoints for US government deployments — Microsoft Intune"** list (cited in
> `gcc-high-parity-notes.md`) — the wildcards exist precisely because the underlying hosts rotate.

## R6. A supported, enrolled Windows baseline
**Description:** Windows 10 21H2+ or Windows 11, current updates, **enrolled** in the GCC High tenant.
**Why:** Compliance only evaluates enrolled, checked-in devices on a supported OS.
**Verify:** On the device, `winver`; in **`intune.microsoft.us`** → **Devices → All devices**, the
device appears with a recent **Last check-in**.
**Implement:** Enroll/re-enroll the device in the GCC High tenant (there is **no** in-place migration
from Commercial — unenroll then re-enroll). Patch to a supported build.

## R7. A pilot/target security group (created in `portal.azure.us`)
**Description:** An Entra **security group** of the affected (or pilot) users/devices.
**Why:** Fixes are piloted and assigned by group, never tenant-wide first.
**Verify:** **`portal.azure.us`** → **Microsoft Entra ID → Groups**; the group exists.
**Implement:** **Groups → New group → Security**; add the affected members. `Set-ScopeTargeting.ps1`
can preview and apply a policy's group assignment (default `-WhatIf`).

## R8. Feature-availability check for the rules you're diagnosing
**Description:** Confirm the specific compliance rule you're troubleshooting is a **supported** feature
in GCC High before assuming a misconfiguration.
**Why:** A rule that depends on a feature **absent** in GCC High (e.g. an MTD vendor not present in
Gov, or a planned-but-unavailable capability) can never evaluate — that's a parity gap, not a bug.
**Verify:** Cross-check the rule against `gcc-high-parity-notes.md` and Microsoft's **Intune
Government service** description.
**Implement:** If the feature is absent/planned in GCC High, remove or replace the rule (section 3
covers the substitutions); do not spend hours "fixing" a rule the sovereign cloud cannot evaluate.

---
**Deployment model:** **Assess → Configure → Pilot → Validate → Expand.** Do not skip Pilot — a
compliance change that flips a whole fleet to **Not compliant** blocks every user at once through
Conditional Access.
