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
