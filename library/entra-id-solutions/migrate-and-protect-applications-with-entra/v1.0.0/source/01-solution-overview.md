# 1. Solution Overview — Migrate & Protect Applications with Entra

## What this solution is
This solution moves **application authentication** onto **Microsoft Entra** and protects every app it
migrates. It covers the three ways an app is typically stranded and brings each into the Entra control
plane:

- **AD FS relying parties → Entra SSO.** Recreate each AD FS relying party as an Entra **enterprise
  application** using **SAML** or **OIDC**, migrate claim/attribute logic, validate on a pilot, then
  **cut over** and retire the AD FS relying party — removing the AD FS dependency app-by-app.
- **On-prem web apps → published through Entra.** Make internal web apps reachable **without a VPN** using
  **Microsoft Entra Application Proxy** (a connector-based reverse proxy) or **GSA Private Access**, with
  **pre-authentication** in Entra so Conditional Access applies before the app is ever reached.
- **SaaS / modern apps → integrated + provisioned.** Integrate SAML/OIDC apps and automate account
  lifecycle with **SCIM** provisioning, then protect them with Conditional Access and access reviews.

## How the technology works
Everything is configured under **Enterprise applications** and **Application proxy** in the Microsoft
Entra admin center (`https://entra.microsoft.com`) and is backed by the Microsoft Graph `applications`,
`servicePrincipals`, and `onPremisesPublishing` APIs. The building blocks:

- **Enterprise application (+ service principal)** → the migrated app in Entra. It holds the **SSO
  configuration** (SAML metadata / OIDC settings), the **user/group assignments**, the **provisioning**
  (SCIM) job, and is the resource a Conditional Access policy targets.
- **AD FS application activity** → a usage/insights report (Entra → **Usage & insights**) that lists AD FS
  relying parties and whether each is ready to migrate, so you prioritize by real usage.
- **Application Proxy connector group** → connectors installed on-prem that make outbound-only
  connections to Entra; a **published app** maps an **external URL** to an **internal URL** and sets the
  **pre-authentication** method (Entra ID) and SSO mode (KCD / header-based / password).
- **Provisioning (SCIM) job** → on the enterprise app; connects to the app's SCIM endpoint with a tenant
  URL + secret token, **maps attributes**, and is **scoped** to a group so it creates/updates/deprovisions
  only in-scope users.
- **Conditional Access policy** → targets the migrated app(s) and enforces MFA / compliant device / risk.
- **Access review** → recurring recertification of who is assigned to each migrated app.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand** — inventory AD FS relying parties, on-prem apps, and
> SaaS SSO and build the migration plan (Assess); recreate one AD FS app in Entra, publish one on-prem app
> via App Proxy, set up one SCIM integration, and author the Conditional Access policy (Configure); target
> them at a small **pilot** group and keep AD FS live (Pilot); prove the pass/fail gates — pilot SSO works
> on Entra, the published app loads without VPN, SCIM provisions, CA enforces (Validate); then cut over the
> AD FS relying party and migrate the remaining apps in waves (Expand). Every cutover is reversible.

## What is in scope
- **App discovery + a per-app migration plan** (AD FS relying parties, on-prem web apps, SaaS SSO).
- **One AD FS relying party migrated** to an Entra enterprise app with staged **cutover + rollback**
  (the repeatable pattern for the rest).
- **One on-prem web app published** via **Application Proxy** (or GSA Private Access) with Entra
  pre-authentication.
- **One SAML/OIDC integration** with **SCIM provisioning** (create/update/deprovision).
- **Conditional Access** protection and a recurring **access review** for the migrated apps.
- Read-only **reporting** for cutover/sign-in evidence via the included scripts (Graph + KQL).

## What is out of scope
- **SSO onboarding at scale** — a repeatable factory for integrating **many** SaaS SAML/OIDC apps — is the
  **separate, adjacent** *Cloud Identity as Enterprise IdP — SAML App Integration Factory* solution. This
  solution is the **AD FS migration + on-prem publishing** track; use the Factory when the job is "onboard
  50 SaaS apps to SSO," and this solution when the job is "get off AD FS and publish on-prem apps."
- **Conditional Access baseline design** (the full Zero Trust policy set) — a separate solution; here CA
  is *applied to* the migrated apps.
- **Network-layer ZTNA** for non-web/TCP apps at fleet scale — that is **GSA Private Access** in the
  *Entra Global Secure Access* solution (referenced as an alternative publishing path here).
- The **decision** of which apps migrate in which wave, cutover windows, and app-owner sign-off — those
  are the customer's change-management determinations.

## Authentication and connections used
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) → **Enterprise applications**,
  **Application proxy**, **Usage & insights (AD FS application activity)**, **Conditional Access**.
- **Microsoft Graph** for the automation scripts, via `Connect-MgGraph` with least-privilege scopes
  (`Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, `AuditLog.Read.All`; write scopes only
  for the gated cutover preview). No credentials or secrets are stored in the scripts.
- **AD FS management** (`Get-AdfsRelyingPartyTrust`, run on an AD FS server) for the on-prem relying-party
  inventory that Graph can't see directly.
- **Application Proxy connectors** on-prem; and, optionally, **Azure Monitor / Log Analytics** for the
  sign-in KQL.

## Limitations (be honest with buyers)
- **Licensing gate:** Application Proxy + Conditional Access need **Entra ID P1**; **GSA Private Access**
  needs the **Entra Suite / Private Access** add-on; **access reviews** need **Entra ID Governance / P2**.
  *Verify current SKU coverage against Microsoft's documentation and your tenant.*
- **Cutover is a real change.** Repointing federation from AD FS to Entra affects live sign-in — always
  pilot with a limited audience, keep AD FS as fallback, and cut over under change control.
- **Claims parity matters.** Complex AD FS **claim rules** (transforms, custom attributes) must be
  reproduced as Entra **claims mapping**; some edge cases need extra work — the plan flags these per app.
- Portal blade names and Graph beta endpoints evolve; match by intent and verify against current guidance.
