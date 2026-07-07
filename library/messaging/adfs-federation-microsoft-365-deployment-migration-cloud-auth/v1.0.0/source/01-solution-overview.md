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
