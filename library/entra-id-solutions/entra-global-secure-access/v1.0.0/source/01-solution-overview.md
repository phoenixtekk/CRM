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
