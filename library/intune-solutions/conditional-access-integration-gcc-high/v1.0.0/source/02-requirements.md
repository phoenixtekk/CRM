# 2. Requirements Guide — Conditional Access Integration (Government / GCC High)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

> **Government note:** all portal/verify URLs below are the **US sovereign cloud** (`*.us`)
> endpoints. If a step sends you to a `*.com` portal, you are on the wrong cloud for a GCC High
> tenant.

## 2.1 GCC High tenant (separate US sovereign cloud)
**Description:** An active Microsoft 365 / Entra **GCC High** tenant (`*.onmicrosoft.us`).
**Why:** GCC High is a distinct sovereign cloud; it is not your Commercial or GCC tenant with a
different sign-in. Portals, endpoints, and some features differ.
**Verify:** Sign in to **`https://entra.microsoft.us`** as an administrator; the tenant domain ends
in `.onmicrosoft.us`.
**Implement:** Provision a GCC High tenant through an authorized government/agreement path (this is
a separate tenant from any Commercial/GCC tenant you hold). [Microsoft — GCC High
endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

## 2.2 Government licensing (Entra ID P1 / P2)
**Description:** Microsoft Entra ID **P1** (or **P2** for risk-based policies), typically via
**Microsoft 365 G3 / G5 (Government)**.
**Why:** Conditional Access is a P1 feature; sign-in/user-risk conditions need P2.
**Verify:** M365 admin center **`https://portal.office365.us`** → **Billing → Licenses** — confirm a
Government plan carrying Entra ID P1/P2.
**Implement:** Assign M365 G3/G5 (Government) or standalone Entra ID P1/P2 (Gov) to targeted users.

## 2.3 Break-glass (emergency access) accounts
**Description:** Two cloud-only Global Administrator accounts excluded from all CA policies.
**Why:** They guarantee you can always sign in if a CA policy misfires — the #1 lockout safeguard.
**Verify:** `https://entra.microsoft.us` → **Users** — two dedicated emergency accounts exist; run
**`CAIG-Validation.ps1`** (which includes a break-glass exclusion check).
**Implement:** Create two cloud-only `.onmicrosoft.us` Global Admins with long random passwords
stored offline; exclude them from every CA policy.

## 2.4 Administrative roles (sovereign portal access)
**Description:** Conditional Access Administrator (or Security Administrator) plus the ability to
open the `*.us` portals.
**Why:** Creating/editing CA policies requires the right role; the operator must also be able to
reach the sovereign portals through any filtering.
**Verify:** `https://entra.microsoft.us` → **Roles and administrators**; confirm **Conditional
Access Administrator** (and **Reports Reader / Security Reader** for log review).
**Implement:** Assign **Conditional Access Administrator**; reserve Global Administrator for
break-glass and tenant-wide changes.

## 2.5 Device compliance (for "require compliant device")
**Description:** Intune device compliance policies in place in the GCC High tenant.
**Why:** The "require compliant device" control needs Intune to be marking devices Compliant.
**Verify:** Intune **`https://intune.microsoft.us`** → **Devices → Compliance**; devices report
Compliant.
**Implement:** Deploy the **Device Compliance Policies (GCC High)** solution first.

## 2.6 MFA registration
**Description:** Users are able to register MFA methods.
**Why:** "Require MFA" challenges users; they must have a method registered.
**Verify:** `https://entra.microsoft.us` → **Protection → Authentication methods**.
**Implement:** Enable authentication methods and (optionally) the registration campaign or SSPR.
Confirm each method is available in GCC High before relying on it.

## 2.7 Sign-in logs / reporting
**Description:** Access to Entra sign-in logs in the GCC High tenant.
**Why:** Report-only impact is reviewed in the sign-in logs before enforcing.
**Verify:** `https://entra.microsoft.us` → **Monitoring & health → Sign-in logs** loads.
**Implement:** Ensure the operator has **Reports Reader** / **Security Reader**.

## 2.8 App protection (optional — mobile)
**Description:** Intune app protection policies for mobile apps.
**Why:** The "require app protection policy" control needs them defined.
**Verify:** Intune `https://intune.microsoft.us` → **Apps → App protection policies**.
**Implement:** Create app protection policies for iOS/Android (optional companion work; deploy the
**MAM App Protection (GCC High)** solution).

## 2.9 Network access to US Gov endpoints
**Description:** Outbound HTTPS to the GCC High service/admin endpoints through any proxy/firewall.
**Why:** Blocking `.us` domains breaks authentication, Graph, and the admin portals for a GCC High
tenant.
**Verify:** From an admin workstation, reach **`login.microsoftonline.us`**, **`graph.microsoft.us`**,
`entra.microsoft.us`, `intune.microsoft.us`, and `security.microsoft.us`.
**Implement:** Allow the published **GCC High URL & IP ranges** through filtering. [Microsoft —
GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

## 2.10 Microsoft Graph PowerShell (US Gov) for the scripts
**Description:** Microsoft Graph PowerShell SDK, connected with **`-Environment USGov`**.
**Why:** The reporting/validation scripts must target `graph.microsoft.us`, not the Commercial
endpoint. A missing `-Environment USGov` connects to the wrong cloud and returns nothing (or errors).
**Verify:** `Get-MgEnvironment` lists **USGov** (Graph `https://graph.microsoft.us`); run
**`CAIG-Discovery.ps1`**.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`, then always
`Connect-MgGraph -Environment USGov -Scopes '<scopes>'`. [Microsoft — Graph national cloud
deployments](https://learn.microsoft.com/en-us/graph/deployments)

---
## Checklist
- [ ] **GCC High tenant** (`.onmicrosoft.us`) — `entra.microsoft.us` loads
- [ ] Government Entra ID P1/P2 licensing (M365 G3/G5) assigned
- [ ] **Two break-glass admins created and excluded** — `CAIG-Validation.ps1`
- [ ] Conditional Access Administrator role held; sovereign portals reachable
- [ ] Device compliance policies in place (GCC High)
- [ ] MFA methods enabled / users can register
- [ ] Sign-in log access for review
- [ ] `.us` endpoints allowed through filtering
- [ ] Graph PowerShell connects with **`-Environment USGov`** — `CAIG-Discovery.ps1`
- [ ] Pilot Entra group created (`CA-Pilot-Gov`)
