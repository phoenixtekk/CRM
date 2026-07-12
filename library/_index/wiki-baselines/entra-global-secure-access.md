# Entra Global Secure Access (Internet & Private Access)

> **Version 1.0.0** · Category: Entra · Solution code: ENTGSA

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Entra Global Secure Access (Internet & Private Access)

## The problem
The traditional VPN is now the weak point it was meant to protect. It backhauls all traffic through a
concentrator, grants a connected device **flat access to the whole network**, and inspects little of
what leaves for the internet or unsanctioned SaaS. Remote work made this worse: more tunnels, more
lateral-movement risk, and no identity signal at the network layer. Meanwhile access to Microsoft 365,
internet sites, and internal line-of-business apps is governed by three different, disconnected control
planes — so a compromised session can reach far more than it should, and no one can answer "who reached
what, from where, and under which conditions."

## The solution
This solution deploys **Microsoft Entra Global Secure Access (GSA)** — Microsoft's **Security Service
Edge (SSE)** — to converge network access under identity. It installs the **GSA client** on managed
devices, deploys **Private Access connectors** to reach on-prem apps, and enables the three **traffic
forwarding profiles**:
1. **Microsoft traffic profile** — routes Microsoft 365 / Entra traffic through GSA so it can be
   secured with **Conditional Access** and **compliant-network** checks (source-IP restore, anti-token-theft).
2. **Internet Access (SWG)** — a Secure Web Gateway for general internet and SaaS traffic, with **web
   content filtering** and TLS-aware policy, replacing uninspected direct egress.
3. **Private Access (ZTNA)** — **per-app**, identity-conditioned access to internal apps **without a
   VPN**, so users reach only the specific apps they are entitled to — never the flat network.

Every path is tied to **Conditional Access** and **Continuous Access Evaluation (CAE)**, so access is
granted per identity, per device posture, and revoked in near-real-time when risk changes. Delivery
follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model: prove one internet
policy, one private app, and CA enforcement against a **pilot** group first, confirm explicit pass/fail
gates, then expand in waves — VPN kept as fallback until Private Access is trusted.

## What's included
Full documentation (overview, requirements, ordered implementation, testing matrix, troubleshooting,
best practices) plus **five PowerShell (Microsoft Graph / Az) tools** — with **KQL** queries for the
GSA traffic logs — that inventory the current GSA posture, validate the named objects are in place,
report connector health, export traffic/sign-in evidence, and preview any change. Every tool is
**read-only or `-WhatIf` by default**, uses least-privilege Graph scopes, and stores **no credentials**.

## Business value
- **VPN replaced by per-app ZTNA** — no flat network access; a session reaches only entitled apps.
- **Internet and SaaS traffic inspected** — a Secure Web Gateway with content filtering, not blind egress.
- **Identity-conditioned everywhere** — Conditional Access + CAE apply to network access, not just apps.
- **Full visibility** — every flow is logged and queryable for audit and incident response.
- **Repeatable and reversible** — a pilot-first, gated method with a documented rollback and VPN fallback.

## Effort and boundary
A competent identity/network admin can stand up the pilot (client, one connector, one private app, one
internet policy, and CA enforcement) in a few focused sessions, then expand in waves. This is a
**technical implementation** guide: it provides the controls and the automation. **Which** apps to
publish privately, **what** internet categories to block, and the production **cutover from VPN** remain
the customer's network, security, and change-management decisions.

> **Licensing & preview note:** the **Microsoft traffic profile** and Conditional Access integration are
> available with **Entra ID P1**; **Internet Access (SWG)** and **Private Access (ZTNA)** require
> **Microsoft Entra Internet Access / Private Access** (part of the **Microsoft Entra Suite** or as
> standalone add-ons). Some GSA capabilities are in **preview**. *Verify current licensing and feature
> availability in your tenant before you begin.*


---


# 1. Solution Overview — Entra Global Secure Access (Internet & Private Access)

## What this solution is
This solution deploys **Microsoft Entra Global Secure Access (GSA)**, Microsoft's **Security Service
Edge (SSE)** platform, to converge network access under identity. It replaces (or fronts) the VPN with a
cloud edge that every device connects to through the **GSA client**, and it secures three classes of
traffic:

- **Microsoft traffic** — Microsoft 365 and Entra traffic acquired by GSA so it can be protected with
  **Conditional Access**, **compliant network** checks, and source-IP restoration (defeats token replay
  from unexpected locations).
- **Internet Access** — a **Secure Web Gateway (SWG)** for general internet and SaaS: **web content
  filtering** by category/FQDN, TLS-aware policy, and logging of egress that used to be blind.
- **Private Access** — **Zero Trust Network Access (ZTNA)**: users reach specific internal apps through
  lightweight **Private Access connectors**, gaining **per-app** access instead of the flat network a VPN
  hands out. This is how you retire the VPN one app at a time.

## How the technology works
GSA has three moving parts:

- **The GSA client** — an agent on the managed endpoint (Windows/macOS/iOS/Android) that acquires traffic
  matching the enabled **forwarding profiles** and tunnels it to the Global Secure Access edge. Where a
  client can't be installed, **remote networks** (an IPsec tunnel from a branch router) forward traffic
  instead.
- **Forwarding profiles** — policy that decides **which traffic** the client captures: the **Microsoft**
  profile (Microsoft 365/Entra endpoints), the **Internet Access** profile (everything outbound to the
  internet), and the **Private Access** profile (the FQDNs/IP segments of your published private apps).
- **The Global Secure Access edge** — Microsoft's cloud service that enforces policy, applies **web
  filtering** and **Conditional Access**, and logs every flow. **Private Access connectors** installed
  next to your apps make outbound-only connections to the edge, so no inbound firewall ports are opened.

The control plane lives in the Microsoft Entra admin center (`https://entra.microsoft.com` →
**Global Secure Access**) and is backed by Microsoft Graph. The building blocks nest as follows:

- **Traffic forwarding profile** → toggled on per class (Microsoft / Internet / Private).
- **Connector group** → a set of Private Access connectors serving a location; a **published private
  app** (an enterprise application of type Global Secure Access) is bound to a connector group and defines
  **application segments** (FQDN/IP + ports).
- **Filtering / security profile** → the web content filtering policies (allow/block by category or FQDN)
  linked into Conditional Access as a **Global Secure Access security profile**.
- **Conditional Access policy** → targets the Global Secure Access traffic (or a specific published app)
  and enforces grant controls (MFA, compliant device) plus **CAE** for near-real-time revocation.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand** — inventory current VPN use, egress paths, and the
> apps to publish (Assess); activate GSA, enable the Microsoft profile, deploy connectors, publish one
> private app, and create one internet-filtering and one CA policy (Configure); target the client and
> policies at a small **pilot** group first (Pilot); prove the pass/fail gates — Microsoft traffic
> tunneled, private app reachable without VPN, internet category blocked, CA enforced (Validate); then
> expand the client fleet, publish more apps, and tighten policy in waves, retiring the VPN app-by-app
> (Expand). Every production change has a rollback and the VPN stays available until Private Access is
> trusted.

## What is in scope
- **GSA activation** and the **GSA client** rollout to a pilot device set.
- The **Microsoft traffic** and **Internet Access** forwarding profiles.
- **Private Access** — at least one **connector group** and one **published private app** with
  application segments, replacing VPN access to that app.
- **Web content filtering** — a baseline filtering policy and a Global Secure Access **security profile**.
- **Conditional Access + CAE** integration for GSA traffic (compliant network / MFA / device compliance).
- **Logging** — enabling GSA traffic logs to Log Analytics and the included read-only reporting (with KQL).

## What is out of scope
- **Conditional Access baseline design** (the full Zero Trust policy set) is a **separate, adjacent
  solution** (Zero Trust — Conditional Access Baseline). This solution *integrates* GSA with CA; it does
  not design your whole CA estate.
- **Application authentication migration** (AD FS → Entra SSO, App Proxy publishing of on-prem web apps
  for browser SSO) is the **separate** *Migrate & Protect Applications with Entra* solution. GSA Private
  Access publishes **network** access to any TCP app; that app-auth solution publishes **web SSO**. They
  are complementary — see §7.
- **SIEM content / detections** on the GSA logs (a Sentinel solution) beyond the basic KQL provided here.
- The **decision** of which apps to move off VPN, which internet categories to block, and the production
  VPN-retirement timeline — those are the customer's network/security/change determinations.

## Authentication and connections used
- **Microsoft Entra admin center** (`https://entra.microsoft.com` → **Global Secure Access**) for all
  configuration.
- **Microsoft Graph** for the automation scripts, via `Connect-MgGraph` with least-privilege scopes
  (`NetworkAccess.Read.All`, `Application.Read.All`, `Policy.Read.All`, `AuditLog.Read.All`). No
  credentials or secrets are stored in the scripts.
- **Azure Monitor / Log Analytics** (via the `Az` module or the portal Logs blade) for the GSA
  **traffic logs**, queried with the **KQL** provided in the reporting script and testing guide.
- **The GSA client** on endpoints and **Private Access connectors** on servers next to the apps.

## Limitations (be honest with buyers)
- **Licensing gate:** the **Microsoft profile** + CA integration work with **Entra ID P1**, but
  **Internet Access (SWG)** and **Private Access (ZTNA)** require **Microsoft Entra Internet
  Access / Private Access** (Entra Suite or standalone add-ons). *Verify current SKU coverage and
  per-user licensing against Microsoft's current documentation and your tenant.*
- **Preview features.** Parts of GSA (certain platforms, TLS inspection depth, some profile controls)
  may be in **preview**; steps are flagged where a capability or path may still be changing — *verify
  current availability*.
- **Traffic capture is disruptive if mis-scoped.** Enabling a forwarding profile changes how traffic
  leaves the device — always pilot on a small device group, keep the VPN as fallback, and watch for
  broken flows before expanding.
- Portal blade names and Graph beta endpoints for GSA evolve; match by intent and verify against current
  Microsoft guidance.


---


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


---


# Global Requirements — Entra ID Solutions (category-level)

These requirements apply to every solution in the Entra ID Solutions category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying any identity solution. Each entry: Description / Why / Verify / Implement-if-missing.

> The identity plane is high risk. A mistake here breaks sign-in for everyone, so every change is
> staged and a break-glass account is kept ready before you touch anything.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID tenant.
Why: It is the cloud identity backbone every other identity service builds on.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 or Azure subscription, which provisions a tenant.

## G2. Entra ID licensing (P1, P2 where noted)
Description: Microsoft Entra ID P1 (or P2 for risk-based and PIM features).
Why: Hybrid features such as seamless sign-in, password writeback, and Conditional Access require P1+.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2 (often bundled in M365 E3/E5 or EMS).
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## G3. Administrative roles
Description: Hybrid Identity Administrator and Global Administrator for the operator.
Why: Configuring directory synchronization and authentication methods needs these elevated roles.
Verify: Entra -> `Roles and administrators`; confirm `Hybrid Identity Administrator` (and a Global Administrator for the one-time first-sync consent).
Implement: Assign `Hybrid Identity Administrator`; reserve `Global Administrator` for tenant-wide and first-sync changes.

## G4. Break-glass (emergency access) accounts
Description: At least two cloud-only emergency access accounts, excluded from Conditional Access and MFA-broad policies.
Why: If sync, federation, or an auth-method change locks out admins, break-glass accounts get you back in.
Verify: Entra -> `Users`; confirm two cloud-only accounts (`@onmicrosoft.com`) with strong stored credentials and documented use.
Implement: Create two cloud-only Global Administrator accounts; exclude them from policies; store credentials securely and monitor sign-ins.

## G5. Healthy on-premises Active Directory
Description: A functional AD forest/domain with healthy replication and DNS.
Why: Synchronization reads from AD; replication or DNS faults corrupt or stall the sync.
Verify: Run `dcdiag` and `repadmin /replsummary` on a domain controller with no errors; run `HYBID-Discovery.ps1`.
Implement: Resolve AD replication, DNS, and time-sync issues before synchronizing.

## G6. An Entra Connect host server
Description: A domain-joined Windows Server (2016+), patched, for Microsoft Entra Connect Sync (or a lightweight host with the Cloud Sync agent).
Why: Connect Sync runs as a service on this host and must reach both AD and Entra ID.
Verify: A supported, domain-joined server with TLS 1.2, .NET, and PowerShell available; run `HYBID-Discovery.ps1`.
Implement: Provision a dedicated server (not a domain controller for production), patch it, and enable TLS 1.2.

## G7. UPN / domain hygiene
Description: User principal names use a public, verified, routable domain (not `.local`).
Why: A non-routable UPN suffix produces sign-in problems and `onmicrosoft.com` fallbacks in the cloud.
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; AD UPN suffixes match it; run `HYBID-Discovery.ps1`.
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD and update user UPNs.

## G8. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS (443) from the Connect host to Entra ID, plus required Microsoft 365 service URLs.
Why: Synchronization, authentication-agent traffic, and tokens depend on these endpoints.
Verify: From the Connect host, reach `https://login.microsoftonline.com` and the Microsoft 365 published URL/IP ranges.
Implement: Allow the Microsoft 365 / Entra service URLs and IP ranges through the proxy/firewall.

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation Guide — Entra Global Secure Access (Internet & Private Access)

Follow these steps **in order**, in the **Microsoft Entra admin center** (`https://entra.microsoft.com`
→ **Global Secure Access**). Names in `code` are the exact objects to create — keep them consistent so
the scripts, testing, and troubleshooting all refer to the same objects. Portal blade names evolve; if a
label differs, match by intent and verify against current Microsoft guidance.

**Object naming convention:** `ENTGSA – <Purpose> – <Scope> – <Stage>`. The objects you will build:

| Object | Name |
|--------|------|
| Pilot user group | `ENTGSA-Pilot` |
| Private Access connector group | `ENTGSA – ConnectorGroup – Datacenter` |
| Published private app (enterprise app) | `ENTGSA – PrivateApp – IntranetWeb – Pilot` |
| Web content filtering policy | `ENTGSA – WebFilter – Baseline` |
| Global Secure Access security profile | `ENTGSA – SecurityProfile – Baseline` |
| Conditional Access (Microsoft/Internet traffic) | `ENTGSA – CA – InternetAccess – Pilot` |
| Conditional Access (Private app) | `ENTGSA – CA – PrivateApp – Pilot` |
| Log Analytics diagnostic setting | `ENTGSA – Diag – TrafficLogs` |

> **Model:** Assess → Configure → Pilot → Validate → Expand. Build each object, scope it to
> **`ENTGSA-Pilot`** and the pilot devices first, prove the gates in §5, then expand. Keep the VPN as a
> fallback until Private Access is trusted. Every production change has a rollback (see end of file).

## Step 1 — Assess and baseline the current state
1. Run **`ENTGSA-Discovery.ps1`** — inventories whether GSA is activated, which forwarding profiles are
   enabled, existing connector groups, published private apps, filtering policies, and any CA policies
   already targeting GSA. On a new tenant this is largely empty.
2. Confirm the pilot group `ENTGSA-Pilot` exists (Entra → **Groups**) with test users, and that you have
   2–5 pilot devices you control.
3. Record the **one private app** you will publish first (Requirement 2.6): its internal FQDN/IP and ports.

## Step 2 — Activate Global Secure Access and enable the Microsoft profile
1. **Global Secure Access → Get started → Activate** (one-time tenant activation).
2. **Global Secure Access → Connect → Traffic forwarding.** Turn on the **Microsoft traffic profile**
   first — it is the lowest-risk profile and enables compliant-network / source-IP restore for M365.
3. Leave the **Internet Access** and **Private Access** profiles **off** for now; you will enable them
   after the client is proven on the pilot.

## Step 3 — Deploy the GSA client to the pilot devices
1. **Global Secure Access → Connect → Client download** — download the client installer.
2. Install it on the **pilot devices** (manually for the pilot, or via Intune for scale — see the Modern
   Endpoint Management catalog for the packaged deployment).
3. Sign in as a `ENTGSA-Pilot` user. Open the client status UI and confirm it shows **Connected** and the
   **Microsoft** channel is **Active**.
4. Run **`ENTGSA-Validate.ps1`** — confirms the Microsoft profile is enabled and the tenant is receiving
   traffic.

## Step 4 — Deploy Private Access connectors
1. On the connector host (Requirement 2.5): **Global Secure Access → Connect → Connectors → Download
   connector service**, install it, and sign in with a GSA admin when prompted.
2. In **Connectors**, confirm the connector shows **Active**. Install a **second** connector for HA.
3. Create a connector group: **Connectors → Connector groups → + New connector group**, name it
   `ENTGSA – ConnectorGroup – Datacenter`, and assign both connectors to it.
4. Run **`ENTGSA-ConnectorHealth.ps1`** — confirms the connector group is healthy and reachable.

## Step 5 — Publish the first private app (ZTNA)
1. **Global Secure Access → Applications → Enterprise applications → + New application** (Global Secure
   Access / Private Access app).
2. **Basics:** Name `ENTGSA – PrivateApp – IntranetWeb – Pilot`; **Connector group** =
   `ENTGSA – ConnectorGroup – Datacenter`.
3. **Application segments → + Add:** enter the app's **internal FQDN or IP**, the **ports/protocols**
   (e.g. TCP 443, or 3389 for RDP), from Requirement 2.6. Add a segment per destination the app needs.
4. **Save** the application.
5. **Users and groups → + Add:** assign **`ENTGSA-Pilot`** (pilot-first — only pilot users get access).
6. Enable the **Private Access** forwarding profile: **Connect → Traffic forwarding → Private Access =
   On** (this profile now carries only the published segments' traffic).
7. If the app uses a private FQDN, configure **Private DNS / DNS suffix** on the app so clients resolve it
   through GSA (Requirement 2.7).

## Step 6 — Enable Internet Access and create the web filtering policy
1. **Global Secure Access → Connect → Traffic forwarding → Internet Access = On** (scoped by CA in
   Step 8 so only pilot users are affected).
2. **Global Secure Access → Secure → Web content filtering policies → + Create policy.**
3. **Name:** `ENTGSA – WebFilter – Baseline`. Add rules that **block** a small, uncontroversial set of
   categories for the pilot (e.g. *Malicious*, *Adult*) — start minimal to avoid breaking legitimate work.
4. **Global Secure Access → Secure → Security profiles → + Create profile.** Name
   `ENTGSA – SecurityProfile – Baseline`; **link** the `ENTGSA – WebFilter – Baseline` policy and set its
   priority. This security profile is what Conditional Access will attach in the next step.

## Step 7 — Wire Conditional Access for the Private app
1. **Entra → Protection → Conditional Access → + New policy.** Name `ENTGSA – CA – PrivateApp – Pilot`.
2. **Users:** include **`ENTGSA-Pilot`**; **exclude** your **break-glass** accounts (global requirement G4).
3. **Target resources:** **Global Secure Access → select the published app** `ENTGSA – PrivateApp –
   IntranetWeb – Pilot` (or the Private Access traffic target).
4. **Grant:** require **Multi-factor authentication** and (if devices are managed) **Require device to be
   marked as compliant**.
5. **Session:** enable **Customize continuous access evaluation** so revocation is near-real-time.
6. **Enable policy:** **Report-only** first. Create.

## Step 8 — Wire Conditional Access for Internet/Microsoft traffic + the security profile
1. **+ New policy.** Name `ENTGSA – CA – InternetAccess – Pilot`.
2. **Users:** include **`ENTGSA-Pilot`**; **exclude break-glass**.
3. **Target resources:** **Global Secure Access → Internet traffic** (and **Microsoft traffic** if you
   want to require compliant-network for M365).
4. **Session → Use Global Secure Access security profile →** select `ENTGSA – SecurityProfile – Baseline`
   so the web filtering is enforced for pilot users' internet traffic.
5. **Grant:** require **MFA** / **compliant device** as your standard dictates.
6. **Enable policy: Report-only** first. Create.
7. Review both policies' **report-only** impact (Entra → **Conditional Access → Insights**), then switch
   each to **On** once the pilot confirms no legitimate access is blocked.

## Step 9 — Turn on GSA traffic logging
1. **Global Secure Access → Monitor → (or Entra → Diagnostic settings for Global Secure Access)** →
   **+ Add diagnostic setting**. Name `ENTGSA – Diag – TrafficLogs`.
2. Select the GSA log categories (enriched network traffic / Microsoft 365 traffic logs) and **send to
   Log Analytics workspace** (Requirement 2.8).
3. Run **`ENTGSA-Report.ps1`** after some pilot activity — it runs the KQL and should return traffic rows.

## Step 10 — Validate the pilot (the gates)
Run **`ENTGSA-Validate.ps1`** and confirm on `ENTGSA-Pilot` (see §5 for the full matrix):
- **G1 Microsoft traffic** — client shows Microsoft channel active; M365 traffic is tunneled.
- **G2 Private app, no VPN** — with the **VPN disconnected**, a pilot user reaches
  `ENTGSA – PrivateApp – IntranetWeb – Pilot` via its FQDN, and **cannot** reach other internal hosts.
- **G3 Internet filtering** — a blocked category is blocked; normal sites work.
- **G4 Conditional Access + CAE** — access requires MFA/compliant device; revoking the session cuts access.

**Pass** = all four gates green. **Fail** = fix before expanding (see §6).

## Step 11 — Expand in waves (retire the VPN app-by-app)
1. **Expand the client fleet** — deploy the GSA client to more device groups via Intune, one wave at a time.
2. **Publish more private apps** using the same convention (`ENTGSA – PrivateApp – <App> – Prod`) and,
   as each is proven, **remove that app's VPN route** — retiring the VPN incrementally.
3. **Broaden CA scope** from `ENTGSA-Pilot` to the intended population; switch both policies from
   **Report-only** to **On**.
4. **Tighten web filtering** — add categories/FQDNs to `ENTGSA – WebFilter – Baseline` in measured steps,
   watching the logs for false blocks.
5. Re-run **`ENTGSA-Validate.ps1`** and **`ENTGSA-Report.ps1`** after each wave to capture evidence.

> **Rollback (any step):** disable rather than delete. Turn a **forwarding profile Off** (Connect →
> Traffic forwarding) to stop capturing that traffic class; set a **CA policy to Report-only** or Off; set
> a published app's users back to `ENTGSA-Pilot`; **stop** the connector service to fail Private Access
> back to the VPN. Keep the **VPN available** for every app until its Private Access path is validated.
> Break-glass accounts are excluded from all GSA CA policies so an edge/CA fault never locks out admins.

---
### Order of operations
`Assess (Discovery) → activate + Microsoft profile → client to pilot → connectors + group → publish
private app → Internet Access + web filter + security profile → CA (private) → CA (internet) → traffic
logging → validate the 4 gates → expand + retire VPN in waves`


---


# 5. Testing & Validation — Entra Global Secure Access (Internet & Private Access)

Validate on the **pilot** (`ENTGSA-Pilot`) and the pilot devices first. Each test has a **pass/fail**
signal. Do not expand until all gates pass. Reference scripts are named in each row.

## Test matrix

| # | Gate | What you do | Pass signal | Fail signal |
|---|------|-------------|-------------|-------------|
| 1 | **G1 Microsoft traffic** | On a pilot device signed in as a pilot user, open the GSA client status | Client shows **Connected**; **Microsoft** channel **Active**; M365 traffic tunneled | Client disconnected / Microsoft channel inactive |
| 2 | **G2 Private app reachable** | With the **VPN disconnected**, browse to the internal FQDN of `ENTGSA – PrivateApp – IntranetWeb – Pilot` | App loads over Private Access; no VPN needed | App unreachable / still needs VPN |
| 3 | **G2 No flat access** | From the same device, try to reach an internal host **not** in any published segment | Connection **fails** (only entitled segments are reachable) | Other internal hosts reachable (flat access) |
| 4 | **G2 Least privilege** | Sign in as a user **not** in `ENTGSA-Pilot` and try the private app | Access denied (not assigned) | Non-assigned user reaches the app |
| 5 | **G3 Internet block** | Browse to a site in a **blocked** category from `ENTGSA – WebFilter – Baseline` | Request is **blocked** by the SWG | Blocked category loads normally |
| 6 | **G3 Internet allow** | Browse to a normal business site | Loads normally; appears in traffic logs | Legitimate site blocked (over-filtering) |
| 7 | **G4 Conditional Access** | Access GSA traffic / the private app under `ENTGSA – CA – *` | **MFA / compliant device** is enforced as configured | Access granted without the required control |
| 8 | **G4 CAE revoke** | Revoke the pilot user's sessions (Entra → User → **Revoke sessions**) | Access is cut **near-real-time** (CAE) | Session persists long after revoke |
| 9 | **Logging** | Generate traffic, then run the traffic-log KQL | Rows appear for the pilot user's flows (allowed + blocked) | No rows / logging not flowing |

## Automated checks
- **`ENTGSA-Discovery.ps1`** — inventories GSA activation, enabled forwarding profiles, connector groups,
  published private apps + segments, filtering policies, and CA policies targeting GSA, so you can confirm
  the named objects exist with the expected configuration.
- **`ENTGSA-Validate.ps1`** — checks each **named** object from §3 is present and correctly wired (Microsoft
  profile on; private app has segments + `ENTGSA-Pilot` assigned; filtering policy linked to the security
  profile; CA policies target GSA and exclude break-glass) and **flags gaps** — the automated form of the
  gate table.
- **`ENTGSA-ConnectorHealth.ps1`** — reports each connector group and connector's **status/health** so you
  can confirm Private Access has a healthy path before testing G2.
- **`ENTGSA-Report.ps1`** — runs the **KQL** against the Log Analytics workspace to export traffic
  evidence: top destinations, allowed vs blocked, and per-user private-app access (the audit artifact).
- **`ENTGSA-TrafficLogs.ps1`** — focused KQL helper for **blocked/denied** flows and Private Access
  connection outcomes, for validating filtering and diagnosing reachability.

## Reference KQL (Global Secure Access traffic logs)
Run in **Log Analytics** (or via `ENTGSA-Report.ps1`). Table/field names may differ by tenant/preview —
verify against current schema.

```kql
// Allowed vs blocked internet traffic, last 24h
NetworkAccessTraffic
| where TimeGenerated > ago(24h)
| summarize Flows = count() by Action, DestinationFqdn
| order by Flows desc
```
```kql
// Private Access connections for the pilot app segments
NetworkAccessTraffic
| where TimeGenerated > ago(24h)
| where TrafficType == "Private"
| summarize Connections = count() by UserPrincipalName, DestinationFqdn, Action
| order by Connections desc
```

## Evidence to capture (for audit / go-live)
- Screenshot: GSA client showing **Connected** with the active channels.
- Screenshot: private app reachable **with VPN off**; and a **failed** connection to a non-published host.
- Screenshot: a blocked category page from the SWG.
- CA **Insights / report-only** results before enforcement, and enforcement confirmed after.
- `ENTGSA-Report.ps1` KQL export of allowed/blocked flows and per-user private-app access.

## Exit criteria (before Expand)
- [ ] G1 — Microsoft profile active and tunneling on pilot devices
- [ ] G2 — private app reachable **without VPN**, and **no** flat access to other hosts
- [ ] G3 — a blocked category is blocked; normal sites work
- [ ] G4 — Conditional Access enforced and **CAE** revokes access near-real-time
- [ ] Connectors healthy (`ENTGSA-ConnectorHealth.ps1`)
- [ ] Traffic logs flowing and queryable (`ENTGSA-Report.ps1`)
- [ ] `ENTGSA-Validate.ps1` shows no gaps for the pilot objects


---


# 6. Troubleshooting — Entra Global Secure Access (Internet & Private Access)

Symptom → likely root cause → fix. Start with **`ENTGSA-Discovery.ps1`** (is GSA activated and are the
named objects present and wired?) and **`ENTGSA-Validate.ps1`** (which gate is failing?) — most GSA issues
are a disabled profile, an unhealthy connector, a DNS mismatch, or a CA policy scoped wrong.

## The Global Secure Access blades show a licensing banner / Internet or Private profile won't enable
- **Root cause:** the tenant/users lack **Microsoft Entra Internet Access / Private Access** licensing;
  the Microsoft profile works on **P1**, but the SWG and ZTNA profiles need the Entra Suite / add-ons.
- **Fix:** assign the correct SKU (M365 admin center → **Billing → Licenses**) to the operator and in-scope
  users, then re-open **Connect → Traffic forwarding**. *Verify current SKU coverage and preview status —
  it changes.*

## The GSA client won't connect / shows a channel inactive
- **Root cause:** the profile for that channel is **Off**, the device can't reach the GSA edge (outbound
  443 blocked), the signed-in user isn't in `ENTGSA-Pilot`, or the client version is outdated/unsupported.
- **Fix:** confirm the profile is **On** (Connect → Traffic forwarding); allow outbound 443 to the GSA
  service URLs; sign in as a pilot user; update the client. `ENTGSA-Validate.ps1` confirms which profiles
  are enabled tenant-side.

## A published private app is unreachable (with VPN off)
- **Root cause:** the connector group is **unhealthy**, the **application segment** doesn't match the FQDN/
  port the user is hitting, the user isn't assigned to the app, or the **Private Access profile is Off**.
- **Fix:** run **`ENTGSA-ConnectorHealth.ps1`** — connectors must be **Active**; confirm the segment covers
  the exact FQDN/IP and ports; confirm `ENTGSA-Pilot` is assigned to
  `ENTGSA – PrivateApp – IntranetWeb – Pilot`; confirm the **Private Access** profile is On.

## The private app resolves to the wrong address / "site can't be reached"
- **Root cause:** a **DNS mismatch** — the client resolves the private FQDN to a public/old address instead
  of routing it through GSA, or the connector host can't resolve it internally.
- **Fix:** configure **Private DNS / DNS suffix** on the published app so the client resolves it via GSA;
  confirm the connector host uses **internal DNS** and can `nslookup`/`Test-NetConnection` the app's
  FQDN/port. This is the single most common Private Access failure (Requirement 2.7).

## Users still have flat network access (can reach hosts you didn't publish)
- **Root cause:** the app segment is **too broad** (a whole subnet), or an old VPN route is still active on
  the device alongside GSA.
- **Fix:** narrow the **application segments** to the specific hosts/ports needed; disconnect/remove the
  VPN route for apps now served by Private Access. ZTNA only limits access to the segments you actually
  publish.

## Legitimate websites are being blocked (over-filtering)
- **Root cause:** `ENTGSA – WebFilter – Baseline` blocks a category that a business site falls under, or a
  needed FQDN isn't allow-listed.
- **Fix:** review the **blocked** flows in the traffic logs (`ENTGSA-TrafficLogs.ps1`), remove the
  over-broad category or add an **allow** rule for the specific FQDN, and re-test. Start minimal and
  tighten in measured steps.

## Internet traffic isn't being filtered at all
- **Root cause:** the **Internet Access** profile is Off, the CA policy `ENTGSA – CA – InternetAccess –
  Pilot` isn't attaching the **security profile**, or the CA policy is still **Report-only**.
- **Fix:** enable the Internet profile; in the CA policy **Session → Use Global Secure Access security
  profile → `ENTGSA – SecurityProfile – Baseline`**; switch the policy from Report-only to **On** once
  validated. `ENTGSA-Validate.ps1` flags a security profile not linked into CA.

## A Conditional Access policy locked users (or an admin) out of GSA traffic
- **Root cause:** the CA grant is too strict for the pilot, or **break-glass** wasn't excluded.
- **Fix:** set the offending `ENTGSA – CA – *` policy back to **Report-only**, confirm **break-glass**
  accounts (global requirement G4) are **excluded**, and sign in as break-glass to recover. Re-enable after
  correcting the grant/scope.

## No rows in the traffic-log KQL
- **Root cause:** the **diagnostic setting** (`ENTGSA – Diag – TrafficLogs`) isn't sending to the workspace,
  the wrong workspace is queried, or no pilot traffic has been generated yet.
- **Fix:** confirm the diagnostic setting targets the Log Analytics workspace and the GSA log categories are
  selected; query the **correct** workspace; generate pilot traffic and allow ingestion latency.
  `ENTGSA-Report.ps1` prints the workspace it queried.

## Continuous Access Evaluation isn't revoking sessions quickly
- **Root cause:** CAE isn't enabled on the CA policy session controls, or the app/scenario doesn't support
  CAE for that flow.
- **Fix:** enable **Customize continuous access evaluation** on `ENTGSA – CA – PrivateApp – Pilot` /
  `ENTGSA – CA – InternetAccess – Pilot`; verify with a **Revoke sessions** test (Testing gate G4).

---
### First moves for any GSA issue
1. `ENTGSA-Discovery.ps1` — is GSA activated and are the profiles/connector groups/apps/policies present?
2. `ENTGSA-ConnectorHealth.ps1` — are the Private Access connectors healthy (for any reachability issue)?
3. `ENTGSA-Validate.ps1` — which gate is failing (profile off, segment wrong, filter not linked, CA scope)?
4. `ENTGSA-TrafficLogs.ps1` — what do the allowed/blocked flow logs say for the affected user?
5. Only then change configuration — disable rather than delete to roll back, and keep the **VPN fallback**.


---


# 7. Best Practices — Entra Global Secure Access (Internet & Private Access)

## Rollout & change safety
- **Pilot-first, always.** Prove the four gates on `ENTGSA-Pilot` and a handful of devices before you
  touch the wider fleet. Traffic capture changes how a device reaches the network — a mis-scoped profile
  can break work for everyone at once.
- **Keep the VPN as a fallback** until each app's Private Access path is validated, then **retire the VPN
  route app-by-app**. A big-bang VPN cutover is the classic way to strand users.
- **Conditional Access in Report-only first.** Ship `ENTGSA – CA – *` policies as **report-only**, read
  the Insights, then enforce. Always **exclude break-glass** accounts from every GSA CA policy.
- **One change at a time.** Enable a profile, or publish an app, or tighten a filter — not all three in
  one window. When something breaks you want one variable to unwind.

## Private Access (ZTNA)
- **Publish the app, not the network.** Define tight **application segments** (specific FQDNs/IPs and
  ports) so users reach only what they need — that is the whole point of ZTNA over VPN. Never publish a
  whole subnet when a handful of hosts will do.
- **Two connectors per location.** Run connectors in pairs in a **connector group** for HA, positioned
  with clean internal line-of-sight and DNS to the apps they serve.
- **Get DNS right up front.** Most Private Access failures are name-resolution mismatches — plan
  **Private DNS / DNS suffixes** so clients resolve private FQDNs through GSA and connectors resolve them
  internally.
- **Assign by group, review access.** Assign published apps to groups (start with `ENTGSA-Pilot`), and
  fold private-app access into your **access reviews** so entitlement doesn't sprawl.

## Internet Access (SWG)
- **Filter minimally, then tighten.** Start `ENTGSA – WebFilter – Baseline` with a small, uncontroversial
  block set (malicious, adult) and add categories/FQDNs in **measured steps**, watching the logs for false
  blocks. Over-filtering on day one erodes trust fast.
- **Let policy follow identity.** Attach the security profile through **Conditional Access** so filtering
  can differ by user/role/risk — not a single flat policy for everyone.

## Conditional Access & CAE
- **Condition network access on identity + device.** Require **MFA** and (for managed fleets) **compliant
  device** for GSA traffic and published apps, so a stolen token from an unmanaged device gets nowhere.
- **Enable Continuous Access Evaluation** so revocation and risk changes cut access in near-real-time,
  not at the next token refresh.
- **Use compliant-network** (from the Microsoft profile) to require that M365 access comes **through** GSA.

## Logging & operations
- **Send traffic logs to Log Analytics** and keep them — they are your audit trail and incident-response
  surface. Run `ENTGSA-Report.ps1` regularly and review blocked/denied flows.
- **Watch connector health.** Schedule `ENTGSA-ConnectorHealth.ps1`; a silently dead connector looks like
  "the app is down" to users.
- **No secrets in automation.** Scripts authenticate interactively via `Connect-MgGraph` / `Connect-AzAccount`
  with least read scopes — never embed credentials or tokens.

## Where to go next (adjacent catalog areas)
- **Migrate & Protect Applications with Entra** — migrate app **authentication** (AD FS → Entra SSO) and
  publish on-prem **web** apps for browser SSO via Application Proxy. GSA Private Access publishes
  **network** access; that solution publishes **web SSO** — run both for full app coverage.
- **Zero Trust — Conditional Access Baseline** — the full CA policy set that this solution plugs GSA into.
- **Entra ID Governance — Access Reviews & Entitlement Management** — govern who is entitled to each
  published private app over time.
- **Microsoft Sentinel** solutions — build detections and hunting on the GSA traffic logs you just enabled.


---


# 8. Deliverables Summary — Entra Global Secure Access (Internet & Private Access)

## What you receive
A complete, self-guided package to deploy **Microsoft Entra Global Secure Access** — Microsoft's Security
Service Edge (SSE). It stands up the **GSA client**, **Private Access connectors**, and the three traffic
forwarding profiles (**Microsoft**, **Internet Access / SWG**, **Private Access / ZTNA**), wires them to
**Conditional Access + Continuous Access Evaluation**, and turns on traffic logging — so internet and SaaS
traffic is inspected, internal apps are reachable **per-app without a VPN**, and every flow is identity-
conditioned and logged.

### Documentation
- **Executive Summary** — the problem (backhauled VPN, flat access, blind egress), the solution (SSE:
  Microsoft/Internet/Private profiles under identity), the outcome, the boundary, and the licensing gate.
- **Solution Overview** — how the client, forwarding profiles, and connectors fit together, the building
  blocks (connector group → published app → segments; filtering policy → security profile; CA + CAE),
  scope, and what's out of scope (CA baseline design and app-auth migration are separate solutions).
- **Requirements Guide** — GSA-specific prerequisites (licensing incl. Internet/Private Access add-ons,
  the GSA admin role, pilot devices + client channel, connector host, private-app segments, internal DNS,
  a Log Analytics workspace, the Graph/Az toolchain), each with Verify / Implement, on top of the category
  global requirements.
- **Implementation Guide** — ordered steps: assess → activate + Microsoft profile → client to pilot →
  connectors → publish private app → Internet Access + web filter → Conditional Access → traffic logging →
  validate → expand and retire the VPN, with **every object named** using the
  `ENTGSA – <Purpose> – <Scope> – <Stage>` convention.
- **Testing & Validation** — the gates (Microsoft traffic, private app without VPN + no flat access,
  internet filtering, CA + CAE) as a pass/fail matrix, automated checks, and reference **KQL** for the
  traffic logs.
- **Troubleshooting** — symptom → root-cause → fix for the common failures (client not connecting, private
  app unreachable, DNS mismatch, over-filtering, CA lockout, no logs).
- **Best Practices** — pilot-first rollout, tight app segments, connector HA, minimal-then-tighten
  filtering, CA/CAE conditioning, logging, and where to go next.

### PowerShell tools (Microsoft Graph / Az) — safe by default
| Script | Purpose | Default mode |
|--------|---------|--------------|
| **`ENTGSA-Discovery.ps1`** | Inventory GSA activation, forwarding profiles, connector groups, published private apps + segments, filtering policies, and CA-for-GSA (baseline posture) | Read-only |
| **`ENTGSA-Validate.ps1`** | Check each named §3 object exists and is wired (profiles on; app has segments + pilot assigned; filter linked to security profile; CA targets GSA, excludes break-glass); flag gaps | Read-only |
| **`ENTGSA-ConnectorHealth.ps1`** | Report Private Access connector groups and connector health/status before testing ZTNA reachability | Read-only |
| **`ENTGSA-Report.ps1`** | Run KQL against Log Analytics to export traffic evidence — top destinations, allowed vs blocked, per-user private-app access | Read-only (KQL) |
| **`ENTGSA-TrafficLogs.ps1`** | Focused KQL for blocked/denied flows and Private Access connection outcomes; optional CSV export | Read-only (KQL) |

All scripts use `Connect-MgGraph` / `Connect-AzAccount` with **least scopes**, contain **no credentials or
secrets**, and any change/remediation defaults to a **`-WhatIf` preview** gated behind an explicit
`-Commit`.

## Outcomes
- **VPN replaced by per-app ZTNA** — sessions reach only entitled apps; no flat network access.
- **Internet/SaaS traffic inspected** — a Secure Web Gateway with content filtering instead of blind egress.
- **Identity-conditioned network access** — Conditional Access + CAE applied to traffic, not just apps.
- **Full visibility** — every flow logged to Log Analytics and queryable for audit and IR.
- A **pilot-first**, gated, reversible rollout with a documented rollback and a VPN fallback.

## Assumptions & boundaries
- **Licensing** covers the in-scope users — Microsoft profile on **P1**; **Internet/Private Access** on the
  **Entra Suite** or add-ons — *verify current SKU coverage and preview status*.
- The **private apps** to publish and the **internet categories** to block are provided by the customer.
- **CA baseline design** (Zero Trust Conditional Access) and **app-auth migration** (AD FS → Entra SSO,
  App Proxy web publishing) are **separate adjacent solutions**.
- The **VPN-retirement timeline** and change approvals are the customer's network/security decisions.

> Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the full documentation set plus
> all five PowerShell tools in a single ZIP, yours to keep and reuse on every rollout.
