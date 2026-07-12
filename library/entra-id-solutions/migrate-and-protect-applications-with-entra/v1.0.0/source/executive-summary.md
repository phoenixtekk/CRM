# Executive Summary — Migrate & Protect Applications with Entra

## The problem
Most organizations run a long tail of applications whose authentication is stuck in the past: relying
parties on an **AD FS** farm nobody wants to touch, internal web apps reachable only over the VPN, and a
handful of SaaS apps wired up with bespoke or forgotten SSO. Each one is an unmanaged risk. AD FS is a
single point of failure and a prized attacker target (Golden SAML); on-prem-only apps force the flat
network access that Zero Trust is meant to end; and apps outside Entra can't be protected by Conditional
Access, can't be reviewed, and don't show up when an auditor asks "which apps can this user reach, and
under what conditions." The result is a fragile estate that blocks the move to Zero Trust.

## The solution
This solution **migrates application authentication to Microsoft Entra** and protects every app it moves,
in four coordinated tracks:
1. **Discover & plan** — inventory AD FS relying parties, on-prem web apps, and SaaS SSO; use the **AD FS
   application activity** signal to prioritize; produce a per-app **migration plan** with a cutover and
   rollback for each.
2. **Migrate AD FS → Entra SSO** — recreate each relying party as an Entra **enterprise application**
   (SAML/OIDC), validate with a **pilot** audience, then **cut over** federation to Entra and retire the
   AD FS relying party — reversible at every step.
3. **Publish on-prem apps** — make internal web apps reachable without a VPN via **Application Proxy** (or
   **GSA Private Access**), with pre-authentication in Entra.
4. **Provision & protect** — automate account provisioning with **SCIM**, and wrap **every migrated app**
   in **Conditional Access** and periodic **access reviews**.

Delivery follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model: migrate and
prove **one** app of each type against a pilot group first, confirm explicit pass/fail gates, then move
the rest in waves — AD FS kept live as fallback until each relying party is validated on Entra.

## What's included
Full documentation (overview, requirements, ordered implementation, testing matrix, troubleshooting,
best practices) plus **five PowerShell (Microsoft Graph) tools** — with **KQL** for sign-in evidence —
that inventory AD FS relying parties and Entra apps, validate the named migrated objects, report SCIM
provisioning status, export cutover/sign-in evidence, and preview cutover changes. Every tool is
**read-only or `-WhatIf` by default**, uses least-privilege Graph scopes, and stores **no credentials**.

## Business value
- **AD FS retired** — the single point of failure and Golden SAML target is removed, app-by-app.
- **On-prem apps reachable without a VPN** — published through Entra with pre-authentication.
- **Every app under Conditional Access** — MFA, device compliance, and risk conditions on all app access.
- **Provisioning automated** — SCIM creates/updates/deprovisions accounts, closing the leaver gap.
- **Audit-ready & reversible** — access reviews per app, and a documented rollback for every cutover.

## Effort and boundary
A competent identity admin can migrate and protect the pilot (one AD FS relying party, one App Proxy app,
one SCIM integration, and Conditional Access) in a few focused sessions, then migrate the rest in waves.
This is a **technical implementation** guide: it provides the migration method, the publishing and
provisioning setup, and the automation. The application **inventory decisions** — which apps migrate in
which wave, cutover windows, and app-owner sign-off — remain the customer's change-management calls.

> **Scope note (avoids overlap):** this solution is the **AD FS migration + on-prem publishing** track. If
> you need **SSO onboarding at scale** — a repeatable factory for integrating many SAML/OIDC SaaS apps —
> that is the separate *Cloud Identity as Enterprise IdP — SAML App Integration Factory* solution; the two
> are complementary and cross-referenced in §7.
>
> **Licensing & preview note:** **Application Proxy** and Conditional Access require **Entra ID P1**;
> **GSA Private Access** (an alternative publishing path) requires the **Microsoft Entra Suite / Private
> Access** add-on; **access reviews** require **Entra ID Governance / P2**. Some capabilities may be in
> **preview**. *Verify current licensing and feature availability in your tenant before you begin.*
