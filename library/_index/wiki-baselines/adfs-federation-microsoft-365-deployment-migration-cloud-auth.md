# ADFS Federation for Microsoft 365 — Deployment, Troubleshooting & Migration to Cloud Auth

> **Version 1.0.0** · Category: Messaging · Solution code: ADFSM365

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

**Outcome.** Reliable Microsoft 365 sign-in — either a healthy, diagnosable **ADFS federation** or a
cleanly retired path to **managed cloud authentication**. For most organizations, replacing on-premises
ADFS with cloud authentication removes a fragile single point of failure (certificate-expiry outages,
on-premises dependency, claims errors) and simplifies operations, while preserving the sign-in experience
users expect.

**The problem.** Many enterprises still authenticate to Microsoft 365 through **ADFS**. When it works,
few notice; when a **token-signing certificate** lapses, a **claims rule** is wrong, or the **ADFS/WAP**
service or on-premises network fails, **every federated user is locked out** of Microsoft 365. Managed
cloud authentication does not carry that on-premises sign-in dependency.

**The approach.** This solution covers both jobs. Where federation stays, it makes ADFS **healthy and
diagnosable** — verifying claims rules, rolling the **token-signing certificate** safely, and confirming
endpoints, WAP, and the Microsoft Entra federation trust. Where the organization is ready to simplify, it
runs a **staged, reversible migration** to **Password Hash Sync** or **Pass-through Authentication** with
**Seamless SSO**: pilot selected users with **Microsoft Entra Connect Staged Rollout** (while the domain
stays federated), validate, convert the domain **federated → managed**, then **decommission ADFS/WAP** —
keeping the farm parked until the change is proven.

**Why it's low-risk.** Every change is **pilot-first with a documented rollback**. Staged Rollout proves
the target sign-in path on a small group **without converting the domain**, and is reversible per user.
Conditional Access parity is established **before** conversion so no access control is silently lost.
Provided PowerShell tooling is **safe-by-default** — read-only assessment and reporting, and change
helpers that **preview with `-WhatIf`** and only act on an explicit commit, with **no credentials stored
in code**. The result: fewer moving parts, fewer outages, and a modern security posture — delivered
self-guided at a fraction of a bespoke consulting engagement.


---


# Solution Overview

## What this is

This solution covers the full lifecycle of **Active Directory Federation Services (ADFS) federation for
Microsoft 365 sign-in** — and, when the organization is ready, its **retirement in favour of managed
cloud authentication**. It does two related jobs:

1. **Run and troubleshoot ADFS federation for Microsoft 365** — the federated sign-in path where a
   domain is set up in Microsoft Entra ID (Azure AD) as **federated**, and authentication is redirected
   to an on-premises ADFS farm (optionally fronted by **Web Application Proxy (WAP)** for extranet
   sign-in). This includes claims (issuance transform) rules, the **token-signing certificate** and its
   rollover, federation **endpoints and metadata**, the Microsoft 365 **relying-party trust**, and the
   `Get-MgDomainFederationConfiguration` / `Update-MgDomain` (Graph) and `Update-MSOLFederatedDomain`
   (legacy MSOnline) federation trust settings.

2. **Migrate to managed authentication and decommission ADFS** — convert the federated domain(s) to
   **managed** authentication using **Password Hash Synchronization (PHS)** or **Pass-through
   Authentication (PTA)**, add **Seamless Single Sign-On (Seamless SSO)** for a comparable
   domain-joined experience, roll the change out with the Microsoft Entra Connect **Staged Rollout**
   feature (a per-user, reversible cut-over), then convert the domains federated → managed and
   **decommission the ADFS/WAP servers**.

The organization chooses the path that fits: keep a healthy ADFS farm running well, or simplify M365
sign-in by removing an on-premises single point of failure. Both paths are **pilot-first with a
documented rollback**, because authentication changes are high-impact — a mistake affects sign-in for
every federated user.

> **Scope note.** ADFS is Microsoft's on-premises federation product used for Microsoft 365 (and other
> relying parties). This solution addresses ADFS **as it serves Microsoft 365 / Microsoft Entra ID
> sign-in**. It does not cover unrelated third-party relying parties on the same farm beyond noting that
> decommissioning ADFS affects **all** its relying-party trusts, not only Microsoft 365 — inventory them
> before you retire the farm.

## How it works

### The federated sign-in model (current state, path A)

When a Microsoft 365 domain is **federated**:

- The domain is marked `Authentication = Federated` in Microsoft Entra ID, pointing at the on-premises
  ADFS farm's issuer URI and endpoints (the **federation trust**).
- A user signing in to a Microsoft 365 service is redirected (home-realm discovery) to the ADFS farm's
  `/adfs/ls/` sign-in endpoint — internally direct to ADFS, or from the extranet through **WAP**.
- ADFS authenticates the user against **Active Directory**, applies its **claims (issuance transform)
  rules** for the Microsoft 365 relying-party trust to emit the required claims (notably the
  **ImmutableID / sourceAnchor**, UPN, and `issuerId`), and signs the token with its **token-signing
  certificate**.
- Microsoft Entra ID validates the token's signature against the federation trust's configured signing
  certificate and issues the user their Microsoft 365 session.

The fragility of this model is well known: if the **token-signing certificate** expires (or rolls over
without Entra being updated), if **claims rules** are wrong, if the **ADFS/WAP service or its
certificates** fail, or if the **on-premises AD / network** is unavailable, **federated sign-in stops**
— an outage that managed authentication does not share.

### The managed authentication model (target state, path B)

When a domain is **managed**, Microsoft Entra ID authenticates users itself. Directory objects are
still synchronised from on-premises AD by **Microsoft Entra Connect (Azure AD Connect)**, but the sign-in
credential is validated in the cloud by one of:

- **Password Hash Synchronization (PHS)** — Entra Connect synchronises a **hash of the AD password hash**
  to Entra ID; Entra validates sign-in against it. No on-premises sign-in dependency; supports
  **leaked-credential detection**. This is Microsoft's recommended default for most organizations.
- **Pass-through Authentication (PTA)** — a lightweight on-premises **PTA agent** validates the password
  against AD in real time (no password hash leaves on-prem). Requires the agent(s) to be available for
  sign-in; deploy **multiple agents** for resilience. Often paired with **PHS as a backup** sign-in
  method.
- **Seamless SSO** — gives domain-joined, corporate-network users silent sign-in (Kerberos-based),
  approximating the ADFS "no prompt on the corpnet" experience. Works with **both PHS and PTA**.

**Microsoft Entra Connect Staged Rollout** lets you move **selected groups of users** to cloud
authentication (PHS or PTA, with Seamless SSO) **while the domain is still federated** — a reversible,
per-user test of the target sign-in path before you flip the whole domain. Once validated, you convert
the domain federated → managed (all remaining users move), then decommission ADFS/WAP.

## Reference design / model

The solution follows the house **Assess → Design → Configure → Pilot → Validate → Expand** model with
named artifacts. The named artifacts you will create/reference throughout:

- `Federation Assessment – M365 – Prod` — the read-only health/state report of the current ADFS farm,
  WAP, certificates, claims rules, and the Entra federation trust (produced by the discovery script).
- `Token-Signing Cert – ADFS – Rollover` — the token-signing certificate rollover artifact (new cert +
  federation-metadata update to Entra).
- `Sign-In Method – Cloud – Target` — the chosen managed method (PHS or PTA + Seamless SSO).
- `Staged Rollout – Pilot – Wave1` — the first Staged Rollout group (pilot users) moved to cloud auth.
- `Domain Conversion – <domain> – Managed` — the federated → managed conversion of a domain.
- `Decommission – ADFS/WAP – Prod` — the ordered decommission of the ADFS and WAP servers.

## Benefits

- **Reliable Microsoft 365 sign-in** — either a diagnosable, well-maintained ADFS farm, or a managed
  cloud-auth model with **fewer moving parts and no on-premises sign-in single point of failure**.
- **Cert-expiry outages eliminated** — the number-one ADFS incident (token-signing certificate expiry)
  is either proactively managed (rollover helper) or removed entirely by migrating to managed auth.
- **Reversible, low-risk migration** — Staged Rollout moves pilot users to cloud auth **without**
  converting the domain, so you validate the target path and can revert per-user before committing.
- **Modern security posture** — managed auth enables **leaked-credential detection** (PHS) and removes
  the ADFS attack surface (e.g. token-signing key theft / "Golden SAML"-class risks).
- **Self-guided and scripted** — read-only assessment, `-WhatIf`-gated change helpers, and validation
  reporting, so the team runs the change with evidence at each gate.

## Limitations & considerations

- **Not a substitute for Microsoft's own migration tooling judgement.** This solution wraps and
  sequences the supported Microsoft steps (Entra Connect, Staged Rollout, domain conversion). It does
  **not** replace Microsoft's product behavior; where a capability is **version-dependent** (Entra
  Connect build, ADFS on the Windows Server version in use, MSOnline vs Microsoft Graph cmdlet
  availability) **verify in your tenant/version**.
- **MSOnline / AzureAD PowerShell are deprecated.** The legacy `Set-MsolDomainAuthentication` /
  `Update-MSOLFederatedDomain` and `AzureAD` cmdlets are retired/retiring; current guidance is
  **Microsoft Graph PowerShell** (`Update-MgDomain`, `Get-MgDomainFederationConfiguration`) and the
  **Entra Connect** wizard for conversion. Where legacy cmdlets are referenced, they are called out as
  legacy and the Graph/Entra Connect equivalent is given. **Verify current cmdlet availability in your
  tenant.**
- **ADFS may serve more than Microsoft 365.** Decommissioning removes **all** relying-party trusts on
  that farm. Inventory every relying party before retiring ADFS; migrate or re-home the others first.
- **Third-party MFA / access-control on ADFS.** If ADFS enforces third-party MFA or access-control
  policies for Microsoft 365, the equivalent must be re-created in **Entra ID Conditional Access**
  before you remove ADFS, or you lose those controls. This is a required design step, not an afterthought.
- **Commercial vs Government cloud.** Portal URLs and some endpoints differ on **GCC High / DoD**
  (`portal.azure.us`, `login.microsoftonline.us`, `admin.exchange.microsoft.us`) versus Commercial.
  Staged Rollout and managed-auth availability can differ on sovereign clouds — **verify availability
  and the correct endpoints for your cloud** before starting. This guide gives Commercial paths and
  flags the Government difference where it matters.
- **Certificate and secret hygiene.** Nothing in this solution stores credentials. The provided scripts
  use interactive modern-auth sign-in (`Connect-MgGraph` / `Connect-ExchangeOnline`); do not embed
  secrets in any script or scheduled task.

## Deployment model

1. **Assess** — inventory the current federation (ADFS farm, WAP, token-signing cert dates, claims
   rules, Entra federation trust, Entra Connect health, current sign-in method). Read-only. Output:
   `Federation Assessment – M365 – Prod`.
2. **Design** — decide the path (maintain ADFS, or migrate to PHS/PTA + Seamless SSO), pick the managed
   method, map any ADFS MFA/access rules to Entra Conditional Access, define the pilot scope and the
   rollback for each change.
3. **Configure** — either repair/roll ADFS artifacts (claims rules, token-signing cert), or stand up the
   target: enable PHS/PTA and Seamless SSO in Entra Connect (do **not** yet convert the domain).
4. **Pilot** — for the migration path, add pilot users to `Staged Rollout – Pilot – Wave1` and validate
   cloud sign-in for exactly those users while the domain stays federated (reversible).
5. **Validate** — run the pass/fail gates (federated OR managed sign-in works, cert health green, staged
   users authenticate via the cloud, no legacy-auth breakage).
6. **Expand** — convert the domain(s) federated → managed, remove Staged Rollout, and **decommission
   ADFS/WAP** in order, keeping the documented rollback until the change is proven stable.


---


# Requirements

These are the **solution-specific** prerequisites for deploying/troubleshooting ADFS federation for
Microsoft 365 and/or migrating to managed cloud authentication. They build on — and do **not**
duplicate — the shared six in **`global-requirements-messaging.md`** (Microsoft 365 tenant with Exchange
Online; least-privilege admin access; EXO V3 + Graph toolchain; DNS control; hybrid Exchange & AD;
pilot scope and change control). Verify each item below before starting the implementation steps.

> **Reminder (vendor boundary).** ADFS, WAP, Microsoft Entra ID (Azure AD), Microsoft Entra Connect
> (Azure AD Connect), and the Microsoft Graph / MSOnline cmdlets are authored from Microsoft's public
> documentation. Where behavior is **version-dependent** (Windows Server / ADFS version, Entra Connect
> build, MSOnline vs Graph cmdlet availability, Commercial vs Government cloud), it is flagged **"verify
> in your tenant/version"** — never invented.

## R1. Microsoft Entra Connect (Azure AD Connect) installed and healthy

- **Description:** A running, healthy **Microsoft Entra Connect (Azure AD Connect)** server synchronising
  the on-premises AD to Microsoft Entra ID, on a **current supported build**. This is the tool that
  enables PHS, PTA, Seamless SSO, and (via its wizard) the domain conversion and Staged Rollout.
- **Why required:** Every migration action (enable PHS/PTA, Seamless SSO, Staged Rollout, convert domain)
  is performed through Entra Connect or depends on healthy directory sync. Federated sign-in also relies
  on the correct **sourceAnchor / ImmutableID** being synced.
- **How to verify:** On the Entra Connect server open the **Synchronization Service Manager** and confirm
  recent successful sync cycles; run the Entra Connect wizard and note the current sign-in method; confirm
  the build under **Add/Remove Programs**. In Entra ID, check **Microsoft Entra Connect** health.
- **How to implement if missing:** Install/upgrade Microsoft Entra Connect to a current supported build
  and confirm a healthy delta sync before making any auth change. **Verify the current supported build in
  your version.**

## R2. Global Administrator (and Hybrid Identity Administrator) access

- **Description:** **Global Administrator** access to the Microsoft 365 / Entra tenant. Domain federation
  and domain conversion (federated ↔ managed) require it; the **Hybrid Identity Administrator** role
  covers most Entra Connect / sign-in-method operations.
- **Why required:** Beyond the least-privilege Exchange roles in the global requirements, changing a
  domain's **authentication type** and configuring federation trust are tenant-level operations requiring
  Global Administrator (or Hybrid Identity Administrator where the specific action permits it).
- **How to verify:** In the Microsoft 365 admin center / Entra roles, confirm the operator holds Global
  Administrator (and, ideally, Hybrid Identity Administrator).
- **How to implement if missing:** Have an existing Global Administrator assign the role under change
  control; use PIM/just-in-time elevation where available.

## R3. ADFS farm and (if used) WAP access — for the federation/troubleshooting path

- **Description:** Administrative access to the **ADFS farm** (ADFS Management console / ADFS PowerShell
  on a federation server) and any **Web Application Proxy (WAP)** servers fronting it, plus the service
  account and the **token-signing / token-decrypting certificates**.
- **Why required:** Repairing claims rules, rolling the token-signing certificate, inspecting endpoints,
  and eventually decommissioning ADFS all require direct ADFS/WAP administrative access.
- **How to verify:** On a federation server, `Get-AdfsProperties` and `Get-AdfsCertificate` succeed;
  the ADFS Management console opens; you can reach the WAP servers. Confirm the ADFS service account.
- **How to implement if missing:** Obtain local admin on the ADFS/WAP servers and ADFS service
  administrative rights before touching the farm.

## R4. Federation state and certificate visibility

- **Description:** Ability to read the current **federation trust** between Entra ID and ADFS — the
  issuer URI, passive/metadata endpoints, and the **token-signing certificate** currently trusted by
  Entra — and the ADFS **AutoCertificateRollover** setting.
- **Why required:** The number-one federation outage is a **token-signing certificate mismatch/expiry**.
  You must be able to compare the cert ADFS is signing with against the cert Entra trusts, and know
  whether ADFS auto-rolls certificates.
- **How to verify:** `Get-MgDomainFederationConfiguration -DomainId <domain>` (Microsoft Graph) returns
  the trusted signing certificate and endpoints; on ADFS, `Get-AdfsCertificate -CertificateType
  Token-Signing` and `(Get-AdfsProperties).AutoCertificateRollover` return current values.
- **How to implement if missing:** Install the **Microsoft Graph PowerShell** module and connect with the
  required scopes (`Domain.Read.All` for read; `Domain.ReadWrite.All` to change). Ensure ADFS PowerShell
  is available on a federation server. **Legacy note:** the older `Get-MsolFederationProperty` / MSOnline
  cmdlets provide similar data but **MSOnline is deprecated — verify availability in your tenant.**

## R5. Chosen managed sign-in method decided and its prerequisites met — for the migration path

- **Description:** A decision on the target managed method — **PHS** (recommended default) or **PTA** —
  and its prerequisites: for **PTA**, **two or more PTA authentication agents** for resilience; for
  **Seamless SSO**, the requirements for the **AZUREADSSOACC** computer object and the Kerberos
  configuration (browsers must send the corporate-network endpoints the Kerberos ticket, typically via
  the intranet zone / trusted sites).
- **Why required:** The target sign-in path must be resilient and validated before you convert the
  domain. A single PTA agent is a new single point of failure; Seamless SSO silently fails to a normal
  prompt if its prerequisites aren't met.
- **How to verify:** In the Entra Connect wizard, confirm the method can be enabled; for PTA, confirm the
  number of healthy agents under **Entra ID → Connect → Pass-through authentication**; for Seamless SSO,
  confirm the `AZUREADSSOACC` object exists and the Kerberos decryption key rollover plan is understood.
- **How to implement if missing:** Enable the method in Entra Connect (Configure → Change user sign-in),
  deploy additional PTA agents, and push the Seamless SSO browser settings via Group Policy.

## R6. Microsoft Entra Conditional Access parity for any ADFS-enforced controls — for the migration path

- **Description:** An inventory of any **access-control / MFA / client-restriction rules enforced in
  ADFS** for the Microsoft 365 relying party, and an equivalent set of **Entra ID Conditional Access**
  policies to replace them **before** ADFS is removed.
- **Why required:** When authentication moves to the cloud, ADFS-side access rules (e.g. block extranet,
  require MFA for certain groups, device checks) stop applying. Without Conditional Access parity you
  **silently lose** those controls at conversion.
- **How to verify:** Review the ADFS Microsoft 365 relying-party trust's **Access Control Policy** /
  issuance authorization rules and any third-party MFA adapter; confirm matching Entra ID Conditional
  Access policies exist (in report-only first).
- **How to implement if missing:** Author the equivalent Conditional Access policies (requires Entra ID
  P1/P2 — **verify your licensing**), test them in **report-only** mode, and enable them before
  converting the domain.

## R7. Pilot user group and a maintenance/change window

- **Description:** A named **pilot user group** (a handful of representative, low-risk users — ideally the
  implementers) for **Staged Rollout**, and an agreed **change window** with rollback authority for the
  domain conversion and ADFS decommission.
- **Why required:** Auth changes are high-impact. Staged Rollout validates the target path on the pilot
  group first; the domain conversion and decommission are done in a controlled window with rollback ready.
- **How to verify:** Confirm the pilot group membership and that a change window with communicated
  rollback is approved.
- **How to implement if missing:** Create the pilot group, define the Staged Rollout wave
  (`Staged Rollout – Pilot – Wave1`), and schedule the change window with the service owner. (This
  extends the shared "pilot scope and change control" requirement with the specifics for auth cut-over.)


---


# Global Requirements — Microsoft 365 / Exchange Messaging Solutions

These requirements apply to **every** solution in the **Messaging** category (Exchange Online &
Exchange hybrid mail flow, connectors, mail hygiene, email authentication, federation, archiving,
client connectivity, and messaging support operations). They are the common foundation each solution
assumes is already in place (or stands up as part of its own Requirements section). Verify each before
starting a solution's implementation steps.

> **Vendor boundary (applies to every Messaging solution).** The **Exchange admin center (EAC)**, the
> **Microsoft 365 admin center**, **Exchange Online PowerShell (EXO V3 module)**, **Microsoft Graph**,
> and on-premises **Exchange Server / Active Directory** are authored at exact, current click-by-click
> and cmdlet detail from Microsoft's public documentation. Where a capability, default, or portal path
> is **version- or plan-dependent** (Exchange Server build/CU, EOP vs Defender for Office 365 plan,
> Exchange Online Archiving / auto-expanding archive availability, Commercial vs Government cloud), it
> is **cited or flagged "verify in your tenant/version"** — never invented. **Third-party mail hygiene,
> archiving, and signature/gateway products** are integrated at the pattern level; their internal
> consoles are deferred to the vendor's own docs. **Commercial vs Government (GCC/GCC High/DoD)** portal
> URLs and endpoints differ — where a solution's setup materially differs on a sovereign cloud, flag it
> (per the house Commercial-vs-Government rule). Automation is delivered as **PowerShell** (Exchange
> Online PowerShell / Graph) — never with hardcoded credentials or secrets in code.

## 1. Microsoft 365 tenant with Exchange Online
- **Description:** A Microsoft 365 tenant with **Exchange Online** and the appropriate licensing for the
  capability in scope (e.g. Exchange Online Plan 1/2, EOP, **Defender for Office 365** for advanced
  hygiene, Exchange Online Archiving / auto-expanding archive where required).
- **Why required:** All mail-flow, hygiene, archiving, and client configuration is performed against
  this tenant and depends on the right plan.
- **How to verify:** Sign in to the Microsoft 365 admin center; confirm the Exchange Online subscription
  and license counts under **Billing > Licenses**.
- **How to implement if missing:** Provision/assign the required licensing before starting.

## 2. Administrative access (least-privilege Exchange/365 roles)
- **Description:** Administrative access with the **least-privilege role** the solution names —
  typically **Exchange Administrator** (or specific EAC role groups such as Organization Management,
  Recipient/Records/Hygiene Management), and **Global Administrator** only where genuinely required
  (e.g. federation/ADFS, connector auth).
- **Why required:** Mail-flow, connector, hygiene, archiving, and federation changes require the
  corresponding admin role.
- **How to verify:** Confirm the role assignment in the Microsoft 365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. Exchange Online PowerShell (EXO V3) + Graph toolchain
- **Description:** A workstation with the **ExchangeOnlineManagement (EXO V3)** PowerShell module and,
  where used, **Microsoft Graph PowerShell**; modern-auth / MFA-capable admin sign-in.
- **Why required:** Configuration, automation, and the provided scripts run through EXO PowerShell /
  Graph; Basic Auth is retired.
- **How to verify:** `Connect-ExchangeOnline` succeeds with the admin account; `Get-Module
  ExchangeOnlineManagement`.
- **How to implement if missing:** Install the module (`Install-Module ExchangeOnlineManagement`) and
  confirm modern-auth sign-in before running the steps.

## 4. DNS control for the mail domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF (TXT), DKIM (CNAME), DMARC (TXT),
  Autodiscover, and connector/host records) for the domains in scope.
- **Why required:** Email authentication, mail routing/coexistence, connector validation, and client
  autodiscover all depend on DNS.
- **How to verify:** Confirm access to the authoritative DNS zone for each mail domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow and authentication changes are high-impact).

## 5. Hybrid Exchange & Active Directory (for hybrid solutions)
- **Description:** For **hybrid / on-premises** solutions, access to the on-premises **Exchange Server**
  organization (correct roles/CU), **Active Directory**, **Azure AD Connect** (directory sync), and the
  relevant network/firewall paths (e.g. for Edge/transport, hybrid connectors, autodiscover).
- **Why required:** Hybrid mail flow, Edge Transport, connectors, and federation read from and change
  the on-premises side.
- **How to verify:** Confirm on-prem Exchange admin access, AD access, and that directory sync is healthy.
- **How to implement if missing:** Obtain access and confirm the on-prem Exchange/AD/AAD-Connect health
  before making hybrid changes.

## 6. A pilot scope and change control
- **Description:** A **pilot group / accepted-domain / test mail flow** to validate on before fleet-wide
  rollout, and a **change-control** process for production changes (mail flow, connectors, DNS,
  authentication, hygiene policy are all high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; the pilot proves the design and change control protects production mail flow.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Define a pilot scope and agree change control with the messaging/
  service owners before making production changes.

*The deployment model across every Messaging solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (Exchange Online PowerShell / Graph) — never with
hardcoded credentials or secrets in code.*


---


# Implementation Guide

This guide follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — and
splits into two tracks after assessment:

- **Track A — Deploy / troubleshoot ADFS federation** (keep federation; make it healthy).
- **Track B — Migrate to managed authentication and decommission ADFS** (retire federation).

Every artifact is **named** with the convention `<Purpose> – <Scope> – <Stage>` and reused verbatim in
testing, troubleshooting, and the scripts. **Pilot-first with rollback** — auth changes affect sign-in
for every federated user.

> **Cloud endpoints.** Commercial paths are shown. On **GCC High / DoD**, substitute
> `portal.azure.us`, `login.microsoftonline.us`, and `admin.exchange.microsoft.us`, and **verify Staged
> Rollout / managed-auth availability for your cloud** first.
>
> **Cmdlet currency.** `Update-MgDomain` / `Get-MgDomainFederationConfiguration` (Microsoft Graph) are
> the current cmdlets; MSOnline (`Set-MsolDomainAuthentication`, `Update-MSOLFederatedDomain`) is
> **legacy/deprecated** and shown only where an operator may still encounter it — **verify availability
> in your tenant**. Domain conversion is best driven from the **Microsoft Entra Connect** wizard.

---

## Phase 0 — Assess (read-only, both tracks)

**Goal:** produce `Federation Assessment – M365 – Prod` — a factual snapshot of the current state.

1. **Inventory the ADFS farm and WAP.** On a federation server:
   - `Get-AdfsProperties` — note `HostName` (the federation service name, e.g. `sts.<domain>`),
     `AutoCertificateRollover`, and the endpoints.
   - `Get-AdfsCertificate -CertificateType Token-Signing` — record the **thumbprint** and **NotAfter**
     (expiry) of the primary (and any secondary) token-signing certificate.
   - `Get-AdfsRelyingPartyTrust` — confirm the **Microsoft 365 / Azure AD** relying-party trust exists
     and note its **issuance transform (claims) rules** and **Access Control Policy**.
   - Identify **all other relying-party trusts** on the farm (they matter at decommission).
   - Note the **WAP** servers publishing ADFS and their certificate expiry.
2. **Inventory the Entra federation trust.** Using Microsoft Graph PowerShell (`Connect-MgGraph -Scopes
   Domain.Read.All`): `Get-MgDomainFederationConfiguration -DomainId <domain>` — record the
   `IssuerUri`, `PassiveSignInUri`, `MetadataExchangeUri`, and the **SigningCertificate** Entra currently
   trusts. Compare its thumbprint to the ADFS token-signing cert from step 1.
3. **Inventory sign-in method and directory sync.** In the Entra Connect wizard, note the current **user
   sign-in** method. Confirm directory sync is healthy (Synchronization Service Manager, recent success).
   List which domains are **Federated** vs **Managed** (`Get-MgDomain`).
4. **Record certificate health.** Flag any token-signing or WAP/SSL certificate expiring within the next
   **60 days** as a priority.

> Run the **discovery script** (`Get-M365FederationAssessment.ps1`) to produce this snapshot
> automatically (read-only).

**Assess gate (pass/fail):** you have a complete `Federation Assessment – M365 – Prod` showing the ADFS
cert thumbprints, the Entra-trusted signing cert, the claims rules, all relying-party trusts, the current
sign-in method, and directory-sync health. **Fail** = missing any of these → do not proceed.

---

## Phase 1 — Design (both tracks)

Decide the **track** and record the design:

- **Track A (keep federation):** you will repair claims/certs/endpoints and put token-signing cert
  rollover on a managed cadence. Record the target `Token-Signing Cert – ADFS – Rollover` plan.
- **Track B (migrate):** choose the managed method — **PHS** (recommended default) or **PTA** — as
  `Sign-In Method – Cloud – Target`. Map every ADFS access-control/MFA rule to an **Entra Conditional
  Access** policy (requirement R6). Define `Staged Rollout – Pilot – Wave1` (the pilot group) and the
  order of `Domain Conversion – <domain> – Managed` and `Decommission – ADFS/WAP – Prod`.

**Design gate:** the track is chosen, the rollback for each planned change is written down, and (Track B)
Conditional Access parity is authored in **report-only**. **Fail** = no rollback documented.

---

## Track A — Deploy / troubleshoot ADFS federation

### A1 — Repair / verify claims (issuance transform) rules

For the Microsoft 365 relying-party trust, the issuance transform rules must emit the required claims:
the **UPN**, the **ImmutableID** (from the sourceAnchor, base64 of the AD `objectGUID` by default), and
the **issuerId** matching the Entra federation trust. In **ADFS Management → Relying Party Trusts →
(Microsoft 365) → Edit Claim Issuance Policy**, confirm the standard Microsoft 365 rule set is present
and unmodified except for intended customizations. If corrupted, re-create from Microsoft's published
Microsoft 365 claim-rule set (the `Convert-MSOLFederatedUser` / Entra Connect-generated rules).

- **Rollback:** before editing, export the current rules
  (`(Get-AdfsRelyingPartyTrust -Name "<name>").IssuanceTransformRules > rules-backup.txt`); restore on
  failure.

### A2 — Roll the token-signing certificate (`Token-Signing Cert – ADFS – Rollover`)

The token-signing certificate expiring (or rolling) without Entra being updated is the classic outage.

1. **Determine rollover mode.** `(Get-AdfsProperties).AutoCertificateRollover`:
   - **`True` (auto):** ADFS generates a new self-signed token-signing cert automatically before expiry.
     You still must **update Entra's federation metadata** so Entra trusts the new cert.
   - **`False` (manual/enterprise CA cert):** you add the new cert yourself.
2. **Generate/promote the new cert.** For auto mode, force generation with
   `Update-AdfsCertificate -CertificateType Token-Signing -Urgent` **only in a maintenance window**
   (`-Urgent` promotes immediately and can disrupt in-flight sessions). For manual mode, import the new
   cert and `Set-AdfsCertificate` as secondary, then promote to primary.
3. **Update Microsoft Entra with the new signing cert.** Because the Microsoft 365 federation trust
   pulls from ADFS metadata, refresh it so Entra trusts the new certificate. Either:
   - **Preferred:** run the Entra Connect wizard's federation-management task to update the trust, or
   - Use Microsoft Graph: `Update-MgDomainFederationConfiguration` with the new `SigningCertificate`
     (base64 public cert) and matching endpoints. **Legacy equivalent:** `Update-MSOLFederatedDomain
     -DomainName <domain>` (MSOnline — deprecated; verify availability).
4. **Validate** immediately (Phase 5 tests): federated sign-in works and Entra's trusted cert thumbprint
   equals the ADFS primary token-signing thumbprint.

- **Rollback:** keep the previous cert as a **secondary** signing cert in ADFS (ADFS can sign with, and
  Entra can trust, two certs during overlap) until the new one is proven; revert the Entra trust to the
  prior metadata if sign-in fails.

> Use `Invoke-TokenSigningCertRollover.ps1 -WhatIf` to preview the rollover steps and the Entra update
> without changing anything.

### A3 — Verify endpoints, metadata, and WAP

- Confirm the federation metadata is reachable:
  `https://<fed-service-name>/federationmetadata/2007-06/federationmetadata.xml` returns valid XML
  internally and (via WAP) externally.
- Confirm the ADFS sign-in page loads at `https://<fed-service-name>/adfs/ls/idpinitiatedsignon`
  (enable `IdpInitiatedSignonPage` if used) and through WAP from the extranet.
- On WAP: confirm the published web application for ADFS is healthy and its SSL cert is valid.

**Track A gate:** federated sign-in works internally and externally; Entra's trusted signing cert matches
ADFS primary; metadata resolves; no cert expires within 60 days. **Fail** = any check red → resolve
before closing the change.

---

## Track B — Migrate to managed authentication and decommission ADFS

### B1 — Configure the target sign-in method (Configure; domain stays federated)

1. **Enable PHS (recommended, or as PTA backup).** In the Entra Connect wizard → **Change user sign-in**
   → select **Password Hash Synchronization** (or **Pass-through Authentication**). Enabling PHS here
   **does not** change the federated domain's live sign-in — it makes the hashes available so Staged
   Rollout / conversion can use them. For **PTA**, install **two or more PTA agents** (R5).
2. **Enable Seamless SSO.** In the same wizard, tick **Enable single sign-on** and provide Domain Admin
   credentials to create the `AZUREADSSOACC` computer object. Push the browser intranet-zone settings
   (`https://autologon.microsoftazuread-sso.com`) via Group Policy so domain-joined clients get silent
   sign-in.
3. Confirm in Entra ID → **Connect** that PHS/PTA and Seamless SSO show **enabled/healthy**.

- **Rollback:** disabling PHS/Seamless SSO in the wizard reverts these; the domain is still federated, so
  live sign-in is unaffected at this stage.

### B2 — Pilot with Staged Rollout (`Staged Rollout – Pilot – Wave1`)

**Staged Rollout moves selected users to cloud auth while the domain stays federated** — reversible.

1. In **Entra admin center → Identity → Hybrid management → Microsoft Entra Connect → Connect Sync →
   Enable Staged Rollout for managed user sign-in**, toggle on **Password Hash Sync** (or **Pass-through
   authentication**) and **Seamless single sign-on**.
2. **Add the pilot group** to the rollout as `Staged Rollout – Pilot – Wave1`. Only those users now
   authenticate through the cloud; everyone else stays on ADFS.
3. Have pilot users sign in to Microsoft 365 (browser and Outlook). Confirm they authenticate via the
   cloud (no ADFS redirect) — see Phase 5 tests and `Test-CloudAuthSignIn.ps1`.

**Pilot gate:** every pilot user signs in via cloud auth (PHS/PTA), Seamless SSO works on the corpnet,
Conditional Access parity policies apply, and **non-pilot** users are unaffected on ADFS. **Fail** =
remove the user/group from Staged Rollout (instant revert) and fix before proceeding.

### B3 — Validate then Expand: convert the domain (`Domain Conversion – <domain> – Managed`)

Once the pilot passes, convert the domain from **federated → managed** so **all** users move to cloud
auth:

1. **Preferred:** run the **Entra Connect wizard → Change user sign-in →** select the target method and
   let the wizard **convert the domain** (it updates the domain authentication type and cleans up the
   federation trust). Do this in the change window.
2. **PowerShell alternative:** `Update-MgDomain -DomainId <domain> -AuthenticationType "Managed"`
   (Microsoft Graph). **Legacy equivalent:** `Set-MsolDomainAuthentication -DomainName <domain>
   -Authentication Managed` (MSOnline — deprecated; verify availability).
3. **Remove Staged Rollout** for that method afterwards (with the domain managed, the whole domain is on
   cloud auth; leaving Staged Rollout configured is redundant).
4. Allow time for propagation; validate broadly (Phase 5).

- **Rollback:** re-federate the domain by re-running the Entra Connect federation task (or
  `Update-MgDomain -AuthenticationType "Federated"` with the ADFS trust settings) — **keep ADFS running
  until the managed conversion is proven stable across a full business cycle.**

Use `Invoke-DomainConversionPlan.ps1 -WhatIf` to preview the conversion (and Staged Rollout state)
without changing anything.

### B4 — Decommission ADFS / WAP (`Decommission – ADFS/WAP – Prod`)

**Only after** all federated domains are converted, validated, and stable, and **all other
relying-party trusts** have been re-homed:

1. Confirm **no domain** is still federated (`Get-MgDomain` → all `Managed`) and no other relying party
   depends on the farm.
2. **Decommission in order:** remove WAP publishing → take ADFS servers out of the load balancer →
   monitor for any sign-in dependency for a soak period → uninstall ADFS / retire the servers → remove
   the ADFS DNS records (`sts.<domain>`) and the ADFS SSL/token certs from certificate stores.
3. Remove any now-unused ADFS service account and firewall rules.

**Decommission gate:** all domains managed, sign-in healthy through a full business cycle, no relying
party orphaned, ADFS/WAP servers retired, DNS/records cleaned. **Fail** = keep ADFS parked (not
uninstalled) until the dependency is resolved.

---

## Rollback summary

| Change | Rollback |
|---|---|
| Claims-rule edit (A1) | Restore exported rules to the relying-party trust |
| Token-signing rollover (A2) | Keep prior cert as secondary; revert Entra trust metadata |
| PHS/Seamless SSO enable (B1) | Disable in Entra Connect wizard (domain still federated) |
| Staged Rollout pilot (B2) | Remove user/group from Staged Rollout (instant per-user revert) |
| Domain conversion (B3) | Re-federate domain via Entra Connect; ADFS still running |
| ADFS decommission (B4) | Keep ADFS parked, not uninstalled, until stable |


---


# Testing & Validation

Run these validations at the gates named in the Implementation Guide. Each has an explicit **pass/fail**
signal. Do not advance a phase until its tests pass. The provided validation and reporting scripts
(`Test-CloudAuthSignIn.ps1`, `Get-M365SignInMethodReport.ps1`) automate most of these read-only checks.

## T1. Assessment completeness (Phase 0 gate)

- **Procedure:** Confirm `Federation Assessment – M365 – Prod` contains: ADFS token-signing cert
  thumbprint(s) + expiry, the Entra-trusted `SigningCertificate` thumbprint, the Microsoft 365
  relying-party claims rules, **all** relying-party trusts, the current sign-in method, and
  directory-sync health.
- **Pass:** all present; ADFS primary token-signing thumbprint **matches** the Entra-trusted cert.
- **Fail:** any item missing, or the thumbprints **differ** (federation will break at token validation —
  fix per Track A2 before anything else).

## T2. Federated sign-in works (Track A)

- **Procedure:** From an internal client and (via WAP) an external client, sign in to
  `https://outlook.office.com` / `https://portal.office.com` with a federated user. Confirm the redirect
  to `https://<fed-service-name>/adfs/ls/` and successful return to Microsoft 365.
- **Pass:** sign-in succeeds internally **and** externally; the ADFS sign-in page renders.
- **Fail:** error at ADFS (see Troubleshooting — cert mismatch, claims, endpoint/WAP).

## T3. Token-signing certificate health (Track A)

- **Procedure:** `Get-AdfsCertificate -CertificateType Token-Signing` (record primary thumbprint +
  NotAfter); `Get-MgDomainFederationConfiguration -DomainId <domain>` (record trusted signing cert).
- **Pass:** primary ADFS token-signing thumbprint **equals** Entra's trusted thumbprint; **NotAfter >
  60 days** out.
- **Fail:** mismatch (Entra will reject tokens) or expiry within 60 days → run `Token-Signing Cert –
  ADFS – Rollover` (A2).

## T4. Federation metadata & endpoints reachable (Track A)

- **Procedure:** Retrieve
  `https://<fed-service-name>/federationmetadata/2007-06/federationmetadata.xml` internally and via WAP.
- **Pass:** valid XML both paths; the certificate in the metadata matches the ADFS primary signing cert.
- **Fail:** unreachable/invalid → check ADFS service, WAP publishing, SSL cert, DNS.

## T5. Cloud sign-in for Staged Rollout pilot users (Track B, Pilot gate)

- **Procedure:** Have each `Staged Rollout – Pilot – Wave1` user sign in (browser + Outlook). Confirm
  **no ADFS redirect** occurs (they authenticate at `login.microsoftonline.com` directly). For PTA,
  confirm the PTA agent shows the auth. Use `Test-CloudAuthSignIn.ps1` to report each user's effective
  sign-in path.
- **Pass:** every pilot user authenticates via the cloud (PHS/PTA); Seamless SSO gives silent sign-in on
  the corpnet; Conditional Access parity policies apply.
- **Fail:** any pilot user still hits ADFS, or Seamless SSO prompts unexpectedly → verify Staged Rollout
  membership, `AZUREADSSOACC`, and browser intranet-zone settings; revert the user from Staged Rollout if
  needed.

## T6. Non-pilot users unaffected (Track B, Pilot gate)

- **Procedure:** Sign in as a **non-pilot** federated user during the pilot.
- **Pass:** they still authenticate via ADFS with no change.
- **Fail:** a non-pilot user changed path → the domain may have been converted prematurely; investigate
  before continuing.

## T7. Domain converted to managed (Track B, Expand)

- **Procedure:** `Get-MgDomain -DomainId <domain>` and check `AuthenticationType`. Sign in as a
  previously federated (non-pilot) user.
- **Pass:** `AuthenticationType = Managed`; all users now authenticate in the cloud; no ADFS redirect.
- **Fail:** still `Federated`, or users error → re-check the conversion; rollback = re-federate
  (ADFS still running).

## T8. Legacy/rich-client and modern-auth clients still work (Track B)

- **Procedure:** Test Outlook (modern auth), a mobile mail client, and any known **legacy-auth**
  dependency. Confirm no broken sign-in after conversion.
- **Pass:** all supported clients authenticate; MFA/Conditional Access behaves as designed.
- **Fail:** a client breaks → check its auth method and Conditional Access; legacy-auth clients that
  relied on ADFS behavior may need reconfiguration.

## T9. No orphaned relying party before decommission (Track B, Decommission gate)

- **Procedure:** Review the relying-party inventory from Phase 0; confirm every non-Microsoft-365
  relying party has been migrated/re-homed.
- **Pass:** only Microsoft 365 depended on ADFS, or all others are migrated.
- **Fail:** an active relying party remains → **do not** decommission ADFS; re-home it first.

## T10. Post-decommission sign-in stability (Track B)

- **Procedure:** After removing ADFS/WAP, monitor sign-in logs (Entra sign-in logs) across a full
  business cycle. Confirm no failures reference the retired federation service.
- **Pass:** clean sign-ins; no references to `sts.<domain>` / ADFS; all domains `Managed`.
- **Fail:** any dependency surfaces → the ADFS servers should still be **parked** (per B4) to restore.


---


# Troubleshooting

Common failure modes for ADFS federation for Microsoft 365 and for the migration to managed auth, with
resolutions. Symptoms are grouped; work top-down.

## Federation sign-in fails for all users

**Symptom:** every federated user gets an error at the ADFS sign-in page or an "invalid token" style
failure returning to Microsoft 365.

- **Token-signing certificate mismatch/expiry (the #1 cause).** Entra rejects tokens signed with a cert
  it no longer trusts. Compare the ADFS primary token-signing thumbprint (`Get-AdfsCertificate
  -CertificateType Token-Signing`) with the Entra-trusted cert (`Get-MgDomainFederationConfiguration
  -DomainId <domain>`). If they differ or the cert expired, run the `Token-Signing Cert – ADFS –
  Rollover` (Implementation A2 / `Invoke-TokenSigningCertRollover.ps1`) and refresh the Entra trust.
- **ADFS or WAP service down / SSL cert expired.** Check the ADFS service and the WAP publishing; verify
  the ADFS SSL and WAP certs are valid. Restart the ADFS service only under change control.
- **Federation metadata unreachable.** Confirm
  `https://<fed-service-name>/federationmetadata/2007-06/federationmetadata.xml` resolves internally and
  via WAP (Testing T4). DNS for `sts.<domain>` and the WAP publishing must be correct.

## Sign-in works internally but fails from outside (or vice-versa)

- **WAP problem.** External sign-in flows through WAP; internal goes direct to ADFS. If only extranet
  fails, check WAP health, its trust with the ADFS farm (re-establish the proxy trust if broken), and the
  WAP SSL certificate. If only intranet fails, check the internal DNS/load balancer to the ADFS farm.
- **Home-realm discovery / split DNS.** Ensure `sts.<domain>` resolves to WAP externally and to the ADFS
  farm (or its internal VIP) internally.

## Individual users can't sign in (but most can)

- **ImmutableID / sourceAnchor mismatch.** The claim ADFS emits must match the synced ImmutableID for the
  user. Duplicate/soft-matched accounts or a changed sourceAnchor break this user. Verify the user's
  on-premises `objectGUID`-derived ImmutableID matches Entra; fix the sync anchor.
- **Claims rule excludes the user.** If the Access Control Policy / issuance authorization rules restrict
  by group or attribute, a user outside the rule is denied. Review the Microsoft 365 relying-party
  trust's rules.

## After a claims-rule edit, sign-in breaks

- **Rules corrupted or missing required claims (UPN, ImmutableID, issuerId).** Restore the exported rules
  (`rules-backup.txt` from Implementation A1). Re-generate the standard Microsoft 365 rule set from
  Microsoft's published set or via the Entra Connect federation task if the backup is unavailable.

## Migration: Staged Rollout pilot user still hits ADFS

- **User not actually in the Staged Rollout group.** Confirm membership of `Staged Rollout – Pilot –
  Wave1` and that the correct method (PHS/PTA) + Seamless SSO toggles are on in the Entra admin center.
  Group membership changes can take time to apply.
- **Cached sign-in.** Have the user clear cached credentials / use a fresh session; confirm they land at
  `login.microsoftonline.com` without an ADFS redirect (Testing T5).

## Migration: Seamless SSO prompts instead of silent sign-in

- **`AZUREADSSOACC` computer object or Kerberos key stale.** Confirm the object exists in AD and roll its
  Kerberos decryption key on the documented schedule.
- **Browser not sending Kerberos ticket.** The corporate endpoint
  (`https://autologon.microsoftazuread-sso.com`) must be in the browser **intranet/trusted** zone —
  push via Group Policy. Non-domain-joined or off-network devices won't get Seamless SSO (expected).

## Migration: PTA sign-in fails or is intermittent

- **Too few / unhealthy PTA agents.** A single agent is a single point of failure. Confirm two or more
  **healthy** PTA agents in Entra ID → Connect → Pass-through authentication; enable **PHS as backup** so
  an agent outage doesn't stop sign-in.

## After domain conversion, some clients break

- **Legacy-auth client relied on ADFS behavior.** Reconfigure the client for modern auth, or account for
  it in Conditional Access. Confirm the conversion completed (`Get-MgDomain` → `Managed`, Testing T7/T8).
- **Lost access control.** If an ADFS access/MFA rule wasn't recreated in Entra Conditional Access
  (requirement R6), that control is now gone. Author and enable the equivalent Conditional Access policy.

## Decommission concerns

- **Another relying party still uses ADFS.** Sign-in for a non-Microsoft-365 app breaks after
  decommission. This is why Phase 0 inventories **all** relying-party trusts and Testing T9 gates on it —
  re-home other relying parties first, keep ADFS **parked** (not uninstalled) until confirmed clear.
- **Need to roll back post-conversion.** As long as ADFS is parked and running, re-federate the domain
  via the Entra Connect wizard (rollback in Implementation B3/B4). Do not uninstall ADFS until stable
  across a full business cycle.

## Cmdlet / tooling issues

- **MSOnline / AzureAD cmdlet not found or failing.** These modules are **deprecated/retiring**. Use
  **Microsoft Graph** (`Update-MgDomain`, `Get-MgDomainFederationConfiguration`) and the **Entra Connect**
  wizard instead. **Verify current cmdlet availability in your tenant/version.**
- **`Connect-MgGraph` scope errors.** Read operations need `Domain.Read.All`; writes need
  `Domain.ReadWrite.All`. Consent to the scope the script requests.
- **Government cloud endpoints.** On GCC High / DoD, connect Graph to the correct environment
  (`Connect-MgGraph -Environment USGov` / `USGovDoD`) and use the `.us` portals — **verify the endpoints
  and Staged Rollout / managed-auth availability for your cloud.**


---


# Best Practices

Durable practices for running ADFS federation for Microsoft 365 and for migrating to managed cloud
authentication.

## Federation health (while you keep ADFS)

- **Track the token-signing certificate like a production expiry.** Its lapse is the single most common
  federation outage. Alert **60+ days** before `NotAfter`, and always keep the previous cert as a
  **secondary** signing cert during rollover overlap so Entra can validate tokens signed by either.
- **Keep AutoCertificateRollover behavior explicit.** Know whether `AutoCertificateRollover` is `True`
  (ADFS self-generates) or `False` (you manage an enterprise-CA cert). In auto mode you **still** must
  refresh the Microsoft Entra federation trust when the cert rolls — automate that refresh.
- **Never edit the Microsoft 365 claims rules blind.** Export the issuance transform rules before any
  change; the Microsoft 365 rule set (UPN, ImmutableID, issuerId) must stay intact or sign-in breaks.
- **Front the extranet with WAP, not by exposing ADFS directly.** Keep WAP and ADFS SSL certs on the same
  expiry cadence as the token-signing cert review.
- **Monitor federation metadata reachability** internally and externally as a synthetic check.

## Choosing and running managed auth

- **Prefer PHS as the default.** It removes the on-premises sign-in dependency and enables
  **leaked-credential detection**. Use **PTA** only when policy forbids syncing password hashes — and
  then deploy **multiple PTA agents** and enable **PHS as a backup** sign-in method so a single agent
  outage can't stop sign-in.
- **Add Seamless SSO** with either method to preserve the domain-joined silent-sign-in experience users
  expect from ADFS; roll the **Kerberos decryption key** for `AZUREADSSOACC` on a schedule.
- **Establish Conditional Access parity before conversion.** Recreate every ADFS access-control/MFA rule
  as an Entra Conditional Access policy and validate it in **report-only** first. Converting a domain
  without this **silently drops** those controls.

## Migration discipline

- **Always pilot with Staged Rollout first.** It is the reversible, per-user proof of the target path
  while the domain stays federated. Validate the pilot fully before converting the domain.
- **Convert with the Entra Connect wizard** where possible — it updates the domain type and cleans up the
  federation trust in one supported operation — rather than hand-editing with deprecated MSOnline cmdlets.
- **Keep ADFS parked, not deleted, until proven.** After conversion, leave ADFS/WAP running (able to
  re-federate) across a full business cycle before decommissioning.
- **Inventory every relying-party trust before decommission.** ADFS often serves apps beyond Microsoft
  365; retiring the farm breaks them all. Re-home the others first.

## Tooling & security hygiene

- **Use current cmdlets.** Prefer **Microsoft Graph PowerShell** (`Update-MgDomain`,
  `Get-MgDomainFederationConfiguration`) and the **Entra Connect** wizard; treat **MSOnline / AzureAD**
  as deprecated and verify availability before relying on them.
- **No credentials in scripts.** Connect interactively with `Connect-MgGraph` / `Connect-ExchangeOnline`
  using modern auth/MFA. Run change helpers with `-WhatIf` first; require an explicit `-Commit`/`-Apply`
  to write.
- **Change control for every auth change.** Mail flow and authentication are high-impact; every change
  goes through a window with a written, tested rollback.
- **Mind the cloud boundary.** On **GCC High / DoD**, use the `.us` portal/endpoints and verify Staged
  Rollout / managed-auth availability for your sovereign cloud before starting.


---


# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** — ADFS federation for Microsoft 365 (claims, token-signing certs, WAP,
  endpoints, the Entra federation trust), its failure modes, and the managed-auth alternatives (PHS/PTA +
  Seamless SSO) with the staged-migration model and the `Assess → Design → Configure → Pilot → Validate →
  Expand` deployment model.
- **Requirements Guide** — the solution-specific prerequisites (Entra Connect health, Global/Hybrid
  Identity Admin, ADFS/WAP access, federation & cert visibility, chosen managed method, Conditional
  Access parity, pilot group + change window), building on the shared Messaging global requirements.
- **Implementation Guide** — the ordered steps split into **Track A** (deploy/troubleshoot ADFS: claims
  rules, token-signing cert rollover, endpoints/WAP) and **Track B** (migrate: enable PHS/PTA + Seamless
  SSO, Staged Rollout pilot, convert domains federated→managed, decommission ADFS/WAP) — pilot-first,
  with pass/fail gates and a rollback table.
- **Testing & Validation** — ten validation procedures (T1–T10), each with an explicit pass/fail signal,
  tied to the implementation gates.
- **Troubleshooting** — the common ADFS/federation and migration failure modes and their resolutions.
- **Best Practices** — durable practices for federation health, choosing/running managed auth, migration
  discipline, and tooling/security hygiene.
- **Executive Summary** — the outcome, approach, and why the change is low-risk.

## PowerShell scripts (5)

All scripts use modern-auth interactive sign-in (`Connect-MgGraph` / `Connect-ExchangeOnline`) — **no
stored credentials** — and are **safe-by-default** (read-only, or `-WhatIf` unless an explicit
`-Commit`/`-Apply` switch is passed).

1. **`Get-M365FederationAssessment.ps1`** *(Discovery — read-only)* — produces `Federation Assessment –
   M365 – Prod`: enumerates each domain's authentication type and, for federated domains, the Entra
   federation trust (issuer, endpoints, trusted signing certificate thumbprint + expiry). Flags certs
   expiring within a threshold. Read-only.
2. **`Invoke-TokenSigningCertRollover.ps1`** *(Remediation — `-WhatIf` by default)* — previews (and, with
   `-Commit`, performs) the `Token-Signing Cert – ADFS – Rollover`: reports current ADFS token-signing
   certs vs the Entra-trusted cert and the Entra federation-metadata update needed so Entra trusts the
   new cert. Defaults to a dry run.
3. **`Test-CloudAuthSignIn.ps1`** *(Validation — read-only)* — reports the effective sign-in method per
   domain and, for the Staged Rollout pilot, checks the target managed method (PHS/PTA) and Seamless SSO
   readiness so you can confirm pilot users authenticate via the cloud. Read-only.
4. **`Get-M365SignInMethodReport.ps1`** *(Reporting — read-only)* — a consolidated report of every
   domain's authentication type (Federated/Managed), the tenant sign-in method (PHS/PTA/Seamless SSO
   status), and Staged Rollout groups, exportable to CSV for the change record. Read-only.
5. **`Invoke-DomainConversionPlan.ps1`** *(Scope/health helper — `-WhatIf` by default)* — previews (and,
   with `-Commit`, performs) the `Domain Conversion – <domain> – Managed`: validates prerequisites
   (managed method enabled, pilot validated), shows the federated→managed conversion plan and rollback,
   and only converts when explicitly committed. Defaults to a dry run.
