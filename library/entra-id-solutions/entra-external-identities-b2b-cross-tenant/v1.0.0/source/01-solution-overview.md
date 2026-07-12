# 1. Solution Overview — Entra External Identities (B2B) & Cross-Tenant Access

## What Entra External Identities is
Microsoft Entra External Identities is the set of Entra capabilities for collaborating with people and
organizations outside your tenant without giving them internal accounts. A partner keeps their own
identity in their own tenant (or signs up with an email or social account); your tenant represents them
as a **guest** (a `#EXT#` user object) and grants them scoped access to your resources. Three layers do
the work:

1. **Cross-tenant access settings** decide *which* external tenants you trust and *how*. A **default**
   policy applies to every tenant you have not named; **organizational** settings override it for a
   specific partner tenant. Within each, you control **B2B collaboration** (guests you invite),
   **B2B direct connect** (used by Teams shared channels), and **trust settings** — for example whether
   you trust the partner's multi-factor authentication and compliant/hybrid-joined device claims so a
   guest is not prompted to re-register MFA in your tenant.
2. **Guest onboarding controls** decide *who* can bring guests in and *how they arrive*: admin or
   user invitation, **self-service sign-up** via a user flow, and **entitlement management** access
   packages that let external users request governed access with approval and expiry.
3. **Guest governance** keeps external access honest over time: **Conditional Access scoped to guest
   and external users** enforces MFA, device, and session controls; **access reviews** recertify guests
   on a schedule; and **expiry / cleanup** removes stale guests. Optionally, **cross-tenant
   synchronization** provisions B2B guests from a partner tenant automatically instead of one-by-one
   invitations.

## How it works
1. You set the **default** cross-tenant access policy conservatively (for example, inbound B2B
   collaboration allowed but no direct connect, MFA not trusted from unknown tenants), then add an
   **organizational** entry for each partner you actually collaborate with and relax settings only for
   them.
2. For a trusted partner you can **trust their MFA and device claims** so guests satisfy your MFA and
   device Conditional Access without re-registering — collaboration is smoother without lowering the
   bar.
3. Guests enter your tenant by **invitation**, by **self-service sign-up** through a user flow, or by
   **requesting an entitlement-management access package** — the governed path, because the package
   carries an approver and an expiry.
4. A **Conditional Access policy scoped to Guest or external users** requires MFA (and optionally
   compliant device or session limits) on external sign-ins, so a guest cannot reach your resources
   without a strong second factor.
5. An **access review** targeting guests runs on a schedule; reviewers (the resource owner, a sponsor,
   or the guests themselves) recertify who should keep access, and anyone not approved is removed.
6. **Expiry and cleanup** — access-package expiry, review auto-removal, and periodic cleanup of guests
   who have never signed in or have been inactive — ensure external access does not accumulate.
7. Break-glass emergency accounts are internal cloud-only administrators, deliberately excluded from
   the guest-scoped Conditional Access policy so an external-user policy can never lock every
   administrator out.

## How this fits the rest of the identity catalog (gap-only)
This solution configures the **External Identities and cross-tenant plane** and plugs into adjacent
capabilities rather than duplicating them:

- **Entitlement management, access reviews, and the catalog/access-package engine** are covered in
  depth by the Entra ID Governance solution (sol code `ENTIGA`). This solution *uses* an access
  package to grant guest access and *uses* an access review to recertify guests, but defers the full
  governance build-out to `ENTIGA`.
- **The Conditional Access baseline** (policy structure, personas, report-only discipline, named
  locations) is covered by the Zero Trust Conditional Access solution (sol code `ENTZTCA`). This
  solution adds **one guest-scoped policy** and assumes the baseline lives there.
- **Privileged Identity Management** (`ENTPIM`), **passwordless / passkey** (`ENTPASSKEY`), **hybrid
  identity** (Entra Connect), **SAML app onboarding** (SAML App Factory), and **enterprise-app /
  service-principal governance** are separate catalog areas referenced where relevant.

## What you can control
- Cross-tenant access: default policy, per-organization overrides, inbound and outbound B2B
  collaboration and direct connect, and trust settings (trust MFA, trust compliant device, trust
  hybrid-joined device) per partner.
- Who can invite guests (everyone, admins and specific roles, or no one) and guest-user access
  restrictions (what a guest can see in the directory).
- Self-service sign-up user flows and the attributes collected.
- Entitlement-management access packages for external users — request policy, approval, and expiry —
  and connected organizations for cross-tenant scenarios.
- Conditional Access scoped to Guest or external users (MFA, device, session).
- Cross-tenant synchronization configuration for a partner tenant (where used).
- Guest lifecycle: access-review recurrence and reviewers, guest expiry, and stale-guest cleanup.

## Benefits
- Deliberate trust — you decide which partner tenants are trusted and how, instead of leaving the
  default wide open.
- Smoother, not weaker — trusting a vetted partner's MFA and device claims removes re-registration
  friction without lowering the security bar.
- Governed onboarding — guests arrive through packaged access with an owner and an expiry, not ad-hoc
  shares that never end.
- Enforced on external sign-in — a guest-scoped Conditional Access policy requires MFA on every
  external sign-in.
- Self-cleaning — access reviews and expiry remove stale guests automatically, shrinking the
  standing external-access surface.

## Limitations (be honest with buyers)
- Cross-tenant access **trust settings** (trusting a partner's MFA/device claims) and **cross-tenant
  synchronization** rely on the partner tenant being configured correctly on their side; you cannot
  force a partner's posture.
- **Entra ID P1** is required for cross-tenant access trust settings and Conditional Access; **Entra
  ID P2 / Entra ID Governance** is required for access reviews and entitlement-management access
  packages. *Verify current licensing in your tenant* (see requirements) — feature-to-license mapping
  changes over time.
- **B2B direct connect** currently underpins Teams shared channels; enabling it has a specific,
  narrow use case — do not enable it broadly by default.
- Some External Identities capabilities (for example certain self-service sign-up identity providers
  and cross-tenant sync options) may be in **preview** or vary by cloud — *verify current availability
  in your tenant* before you depend on them.
- This solution does not make regulatory, data-classification, or partner-approval decisions — those
  belong to your compliance, security, and business owners.

## Authentication and connections used
- Portal work is done in the Microsoft Entra admin center (`https://entra.microsoft.com`).
- The scripts use the **Microsoft Graph PowerShell SDK** (`Connect-MgGraph`) with least-privilege,
  read-only scopes for discovery/validation/report, and change scopes only for the two change scripts,
  which default to a safe `-WhatIf` preview.

## The standard deployment model
> Assess current cross-tenant/default settings and guest inventory -> Configure conservative defaults,
> one partner organization, guest controls, a report-only guest CA policy, and a governed access
> package -> Pilot with one partner and a small guest scope -> Validate MFA, access, review, and expiry
> -> Expand to more partners and enforce.
> pattern: Assess -> Configure -> Pilot -> Validate -> Expand.
