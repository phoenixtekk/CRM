# 2. Requirements Guide — Entra Global Secure Access (Internet & Private Access)

Verify **every** requirement before you configure Global Secure Access. Each entry: **Description · Why
required · How to verify · How to implement if missing.** The category-wide prerequisites (an active
Entra ID tenant, base licensing, administrative roles, and break-glass accounts) are defined once in
`global-requirements-entra-id-solutions.md` — confirm those first. The items below are **specific to
Global Secure Access**.

## 2.1 Global Secure Access licensing (P1 for Microsoft profile; Internet/Private Access add-ons)
**Description:** The **Microsoft traffic profile** and Conditional Access integration are available with
**Entra ID P1**. **Internet Access (SWG)** and **Private Access (ZTNA)** require **Microsoft Entra
Internet Access** and **Microsoft Entra Private Access** (part of the **Microsoft Entra Suite** or as
standalone add-ons).
**Why required:** Without the correct license the Global Secure Access blades load but enabling the
Internet/Private profiles, web filtering, and per-app publishing is blocked; licensing applies to the
**users assigned** to GSA.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**; confirm the Entra Suite /
Internet Access / Private Access SKUs. In the Entra admin center, **Global Secure Access** blades load
without a licensing banner. Run **`ENTGSA-Discovery.ps1`** to confirm the GSA endpoints respond.
**How to implement if missing:** Assign the Entra Suite (or the Internet Access / Private Access add-ons)
to in-scope users. *Verify current licensing rules against Microsoft's documentation — SKU coverage and
preview status change.*

## 2.2 Global Secure Access Administrator role
**Description:** The operator holds **Global Secure Access Administrator** (least privilege for GSA) or
Global Administrator for tenant-wide setup; publishing apps and CA also touch the **Application
Administrator** and **Conditional Access Administrator** roles.
**Why required:** Activating GSA, enabling profiles, deploying connectors, and creating filtering
policies require the GSA admin role; wiring Conditional Access requires the CA admin role.
**How to verify:** Entra → **Roles and administrators**; confirm **Global Secure Access Administrator**
(and Conditional Access Administrator) on the operator.
**How to implement if missing:** Assign **Global Secure Access Administrator** and **Conditional Access
Administrator**; reserve Global Administrator for the initial activation only.

## 2.3 A pilot device set and a pilot user group
**Description:** A small set of **managed devices** that can run the **GSA client**, and an Entra security
group **`ENTGSA-Pilot`** containing the pilot users.
**Why required:** Traffic capture is disruptive if mis-scoped; the pilot-first model targets
`ENTGSA-Pilot` and its devices so a broken flow affects a handful of users, not everyone.
**How to verify:** Entra → **Groups**; confirm `ENTGSA-Pilot` and its members. Confirm the pilot devices
meet the GSA client OS requirements.
**How to implement if missing:** Create `ENTGSA-Pilot` (Assigned membership) with test users; identify
2–5 pilot devices you control. The client can be deployed by Intune or installed manually for the pilot.

## 2.4 GSA client deployment channel (Intune or manual)
**Description:** A way to install and update the **Global Secure Access client** on endpoints — **Intune**
(app deployment) for scale, or manual install for the pilot.
**Why required:** The client is what captures and forwards traffic; without it (outside remote-network
sites) GSA does nothing on that device.
**How to verify:** For the pilot, the client installs and shows **Connected** to the enabled profiles in
its status UI. For scale, an Intune Win32/line-of-business app is prepared.
**How to implement if missing:** Download the GSA client from **Global Secure Access → Connect → Client
download**; package it in Intune (see the *Modern Endpoint Management* catalog) or install manually on
pilot devices. *Verify current client OS support — platform availability changes.*

## 2.5 A Private Access connector host (for ZTNA to on-prem apps)
**Description:** At least one **Windows Server (2019/2022+)**, patched, with outbound HTTPS to the GSA
service, positioned with network line-of-sight to the internal app(s) you will publish. Two per location
for high availability.
**Why required:** The **Private Access connector** makes the outbound-only bridge from the GSA edge to
your internal app; without it, Private Access has nothing to reach.
**How to verify:** A domain-joined or workgroup server that can resolve and reach the target app's
internal FQDN/IP, with outbound 443 to the Microsoft GSA endpoints; run **`ENTGSA-ConnectorHealth.ps1`**
after install.
**How to implement if missing:** Provision the server (not a domain controller), open **outbound** 443 to
the GSA service URLs, and install the connector from **Global Secure Access → Connect → Connectors →
Download connector service**. Deploy **two** for HA.

## 2.6 The private apps to publish are identified (FQDN/IP + ports)
**Description:** The internal applications you will move off VPN are identified by their **internal
FQDN(s) or IP range(s) and ports** (the **application segments**).
**Why required:** A published private app is defined by its segments; Private Access forwards only the
traffic that matches them, so you must know exactly what to publish.
**How to verify:** You have a list: app name, internal FQDN/IP, ports/protocols, and which users need it.
Run **`ENTGSA-Discovery.ps1`** to see already-published apps.
**How to implement if missing:** Document each app's segments with the app owner; start the pilot with a
**single, low-risk internal app** (e.g. an internal web tool or an RDP/SSH host to a jump box).

## 2.7 Internal DNS resolution and network path for connectors
**Description:** The connector host can **resolve and route** to the app's internal FQDN/IP, and Private
Access **DNS** (Private DNS / DNS suffixes) is planned so clients resolve private FQDNs through GSA.
**Why required:** Users type an FQDN; GSA must map it to a segment and the connector must resolve it
internally. A DNS mismatch is the most common Private Access failure.
**How to verify:** From the connector host, `nslookup`/`Test-NetConnection` to the app's internal
FQDN/port succeeds. Private DNS/suffix settings are decided for the client side.
**How to implement if missing:** Ensure the connector host uses internal DNS; configure **Private DNS**
or the **DNS suffix** list on the published app so clients resolve private names via GSA.

## 2.8 A Log Analytics workspace for GSA traffic logs
**Description:** An **Azure Log Analytics workspace** to receive the **Global Secure Access traffic logs**
(and enriched network/Microsoft 365 logs) via a diagnostic setting.
**Why required:** Traffic logs are the visibility and audit surface; the reporting KQL runs against this
workspace, and it feeds any downstream Sentinel content.
**How to verify:** Azure portal → **Log Analytics workspaces**; a workspace exists and you have
**Log Analytics Reader**. Run **`ENTGSA-Report.ps1`** to confirm the KQL returns rows once logging is on.
**How to implement if missing:** Create a workspace (or reuse the tenant's central one); you will point
GSA diagnostic settings at it in §3.

## 2.9 Microsoft Graph / Az PowerShell toolchain
**Description:** The **Microsoft Graph PowerShell SDK** and the **Az** module installed on the operator's
workstation, with consent for the least-privilege read scopes the scripts use.
**Why required:** The five included tools authenticate via `Connect-MgGraph` (discovery/validation/
reporting) and `Connect-AzAccount` (KQL against Log Analytics).
**How to verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` and
`Get-Module -ListAvailable Az.OperationalInsights` return versions; running **`ENTGSA-Discovery.ps1`**
connects successfully.
**How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`;
`Install-Module Az -Scope CurrentUser`; consent to `NetworkAccess.Read.All`, `Application.Read.All`,
`Policy.Read.All`, `AuditLog.Read.All` on first run.

---
## Checklist
- [ ] Category global requirements confirmed (`global-requirements-entra-id-solutions.md`)
- [ ] GSA licensing (P1 for Microsoft profile; Internet/Private Access add-ons) — *verify current SKU + preview*
- [ ] Global Secure Access Administrator (+ Conditional Access Administrator) role held
- [ ] `ENTGSA-Pilot` group + pilot devices identified
- [ ] GSA client deployment channel ready (Intune or manual)
- [ ] Private Access connector host(s) provisioned with outbound 443 — `ENTGSA-ConnectorHealth.ps1`
- [ ] Private apps identified (FQDN/IP + ports) — `ENTGSA-Discovery.ps1`
- [ ] Internal DNS/route from connector to app confirmed; Private DNS/suffix planned
- [ ] Log Analytics workspace ready for GSA traffic logs — `ENTGSA-Report.ps1`
- [ ] Microsoft Graph + Az PowerShell installed — `ENTGSA-Discovery.ps1`
