# Entra External Identities (B2B) & Cross-Tenant Access

> **Version 1.0.0** · Category: Entra · Solution code: ENTB2B

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Entra External Identities (B2B) & Cross-Tenant Access

White-label · Entra ID Solutions

Ungoverned guest sprawl and wide-open external collaboration are a data-exfiltration surface: guests
who never expire, no Conditional Access scoped to external users, and no record of who invited whom or
why. Microsoft Entra External Identities fixes this at the control plane. Cross-tenant access settings
decide which partner tenants you trust and how (B2B collaboration, B2B direct connect, and inbound MFA
trust); guest invitation and self-service sign-up controls decide who can bring guests in; entitlement
management packages external access with a policy and an expiry; Conditional Access scoped to guests
enforces MFA and device or session controls on external users; and access reviews recertify guests on
a schedule so stale external access decays on its own.

This solution stands the capability up the right way. It is written for an administrator with no prior
external-identity experience — exact, ordered, click-by-click steps in the Microsoft Entra admin
center, every object you create named with a consistent convention and reused through testing and
troubleshooting, and a pilot-first method so you prove the model on one partner and a small guest scope
before you expand tenant-wide.

## What you get
- A plain-language Solution Overview of External Identities, cross-tenant access settings (default vs organizational, inbound/outbound, trust settings), guest invitation and self-service sign-up, entitlement-managed guest access, Conditional Access for guests, cross-tenant synchronization, and the guest lifecycle (reviews, expiry, cleanup).
- A Requirements Guide with Verify / Implement-if-missing for every solution-specific prerequisite (the category-wide ones live in the separate global-requirements file), including the licensing and preview items flagged *verify*.
- An Implementation Guide of precise, ordered steps in the Entra admin center — cross-tenant settings for one partner, guest controls, a scoped Conditional Access policy in report-only first, an entitlement-management access package for external users, and a guest access review — piloted before expansion.
- Five PowerShell scripts (Microsoft Graph) for external-identity discovery, configuration validation, a guest-lifecycle report, safe cross-tenant-access configuration for a named partner (default `-WhatIf`), and safe stale-guest cleanup (default `-WhatIf`).
- Testing and Troubleshooting guides, plus Best Practices and a Deliverables Summary, for a confident rollout.

## What this delivers
Governed external collaboration: partner tenants are trusted deliberately through cross-tenant access
settings rather than by default; guests enter through invitation or self-service policy, receive access
through entitlement-management packages with an owner and an expiry date, are subject to a Conditional
Access policy that requires MFA, and are recertified by an access review that removes anyone no longer
needed. Break-glass emergency accounts are excluded from the guest-scoped policies so a
misconfiguration can never lock every administrator out.

## Scope boundary
This solution configures the External Identities and cross-tenant plane. It deliberately does **not**
re-implement the entitlement-management engine, the Conditional Access baseline, or hybrid identity —
those are separate catalog areas it plugs into (see the cross-references in the Overview and Best
Practices). Regulatory, data-classification, and partner-approval decisions belong to your
compliance, security, and business owners; this guide provides the technical controls, not the
decisions.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
External access that is deliberate, scoped, and time-bound — partners onboarded through trusted
cross-tenant settings, guests granted through packaged access with MFA and expiry, and stale guests
removed on review — proven on a pilot before you scale.


---


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


---


# 2. Requirements Guide — Entra External Identities (B2B) & Cross-Tenant Access

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (tenant, base licensing, admin roles, break-glass
accounts, network access) are in `global-requirements-entra-id-solutions.md` and are not repeated here.

> Licensing and preview items below are flagged **verify** — confirm current availability and the
> feature-to-license mapping in *your* tenant before you rely on them; Microsoft changes these over
> time.

## 2.1 Entra ID P1 (cross-tenant access trust + Conditional Access) — verify
Description: Microsoft Entra ID P1 for the users and administrators involved, to use cross-tenant access **trust settings** and **Conditional Access**.
Why: Trusting a partner's MFA/device claims and enforcing a guest-scoped Conditional Access policy are P1 features. Basic B2B invitation works without P1, but the governance in this solution needs it.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1 (often bundled in M365 E3/E5 or EMS). In Entra, `Protection -> Conditional Access` is available. Run `ENTB2B-Discovery.ps1`. *Verify current licensing in your tenant.*
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1 to the administrators and to any internal users whose collaboration is governed.

## 2.2 Entra ID P2 / Entra ID Governance (access reviews + access packages) — verify
Description: Microsoft Entra ID P2 or Microsoft Entra ID Governance for the guest-lifecycle features — **access reviews** and **entitlement-management access packages**.
Why: Recertifying guests with access reviews and granting governed guest access with access packages are P2 / Governance features.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P2 or Entra ID Governance; in Entra, `Identity governance` shows `Access reviews` and `Entitlement management`. Run `ENTB2B-Discovery.ps1`. *Verify current licensing in your tenant.*
Implement: Assign Entra ID P2 (E5/EMS E5) or Entra ID Governance to administrators, sponsors/reviewers, and the internal users who own access packages. (Full governance build-out is the `ENTIGA` solution; this solution uses one package and one review.)

## 2.3 Administrative roles for the operator
Description: A `Global Administrator` or the combination of `Security Administrator` (Conditional Access + cross-tenant access settings) and `Identity Governance Administrator` (access reviews + entitlement management), plus `Guest Inviter` where invitation is delegated.
Why: Cross-tenant access settings and Conditional Access require security-admin rights; access packages and reviews require identity-governance rights; a first-run consent may require `Global Administrator`.
Verify: Entra -> `Roles and administrators`; confirm the operator holds the roles above. Run `ENTB2B-Discovery.ps1`.
Implement: Assign `Security Administrator` and `Identity Governance Administrator` to the operator; reserve `Global Administrator` for the one-time consent.

## 2.4 A named partner tenant (or partner contact) for the pilot
Description: One real partner you actually collaborate with — their tenant's default domain (for example `contoso.com` / `contoso.onmicrosoft.com`) and a pilot guest contact there.
Why: Cross-tenant **organizational** settings, trust, and cross-tenant sync are configured per partner tenant; the pilot proves the model on one partner before you expand.
Verify: You know the partner's tenant domain and have a test guest email at that partner. Run `ENTB2B-Discovery.ps1` to see existing organizational settings.
Implement: Identify one partner tenant and a willing pilot contact; agree which apps/resources the pilot guest needs.

## 2.5 Guest inventory and current cross-tenant baseline
Description: A current inventory of existing guest (`#EXT#`) users — how many, how they arrived, last sign-in — and the current default cross-tenant access policy.
Why: You cannot govern guest sprawl without first seeing it; the default policy may already be more open than you think.
Verify: Entra -> `Users` (filter User type = Guest); Entra -> `External Identities -> Cross-tenant access settings -> Default settings`. Run `ENTB2B-Discovery.ps1` and `ENTB2B-Report.ps1`.
Implement: Export the guest list and classify each guest (keep, expire, remove); record the current default inbound/outbound settings before changing them.

## 2.6 Pilot scope group and sponsor/approver group
Description: A pilot scope group of internal users who will collaborate with the partner, and a sponsor/approver group for the guest access package and review.
Why: Conditional Access, the access package request policy, and the access review target defined groups; approvals need at least two approvers so they are not delayed by one absence.
Verify: Entra -> `Groups`; confirm a pilot scope group and an approver group (2+ members). Run `ENTB2B-Set-CrossTenantAccess.ps1 -WhatIf` (which can report/create the groups it needs) or create them manually.
Implement: Create `B2B Pilot – Guest Scope – Pilot` and `Partner Approvers – B2B – Pilot`; add representative members.

## 2.7 Guest-scoped Conditional Access policy prerequisites (report-only first)
Description: The ability to create a Conditional Access policy scoped to Guest or external users, deployed in **report-only** first, with break-glass accounts excluded.
Why: Enforcing MFA on external sign-ins is the core guest control; report-only proves impact before enforcement, and break-glass exclusion prevents lockout.
Verify: Entra -> `Protection -> Conditional Access`; confirm you can create a policy targeting `Guest or external users`, and that break-glass accounts are excluded from broad policies. Run `ENTB2B-Validate.ps1`.
Implement: Confirm the two break-glass accounts (per global requirement G4) are excluded from broad Conditional Access; plan the new guest policy in report-only.

## 2.8 Microsoft Graph PowerShell SDK
Description: The Microsoft Graph PowerShell SDK on the operator workstation.
Why: The five scripts in this package call Microsoft Graph for discovery, validation, reporting, and the two safe change operations.
Verify: `Get-Module Microsoft.Graph.Authentication -ListAvailable` returns a version; `Connect-MgGraph` connects to `graph.microsoft.com`. Run `ENTB2B-Discovery.ps1`.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.9 Cross-tenant synchronization prerequisites (optional / where used) — verify
Description: If you will auto-provision guests from a partner, cross-tenant synchronization configured between the two tenants (a configuration on your side and consent on the partner side).
Why: Cross-tenant sync provisions B2B guests automatically instead of one-by-one invitation; it requires both tenants to cooperate and specific configuration.
Verify: Entra -> `Cross-tenant synchronization` (under External Identities / Cross-tenant access settings) is present; the partner has enabled inbound sync. Run `ENTB2B-Discovery.ps1`. *Verify current availability in your tenant.*
Implement: Configure cross-tenant sync only after the invitation-based pilot succeeds and the partner agrees; keep it out of the initial pilot.

---
## Checklist
- [ ] Entra ID P1 assigned (cross-tenant trust + Conditional Access) — `ENTB2B-Discovery.ps1` · *verify*
- [ ] Entra ID P2 / Governance assigned (access reviews + access packages) — `ENTB2B-Discovery.ps1` · *verify*
- [ ] Operator holds Security Administrator + Identity Governance Administrator
- [ ] One named partner tenant + pilot guest contact identified
- [ ] Guest inventory and current default cross-tenant settings captured — `ENTB2B-Report.ps1`
- [ ] Pilot scope group and approver group created (2+ approvers)
- [ ] Break-glass accounts excluded from broad Conditional Access — `ENTB2B-Validate.ps1`
- [ ] Graph PowerShell SDK present; `Connect-MgGraph` connects
- [ ] (Optional) Cross-tenant sync prerequisites confirmed with the partner · *verify*


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


# 3. Implementation Guide — Entra External Identities (B2B) & Cross-Tenant Access

Follow these steps in order, in the **Microsoft Entra admin center** (`https://entra.microsoft.com`),
mostly under **`External Identities`** and **`Protection -> Conditional Access`**. Configure one
partner and a small guest scope first; expand only after the Testing Guide passes.

> Model: set conservative defaults, trust one named partner deliberately, bring guests in through a
> governed access package, enforce a guest-scoped Conditional Access policy (report-only first), and
> recertify with an access review — validated on a pilot before the tenant. Break-glass accounts stay
> excluded from the guest policy throughout.
>
> Naming convention: every object uses `<Purpose> – <Scope> – <Stage>`. The pilot objects are:
> `B2B Pilot – Guest Scope – Pilot` (group), `Partner Approvers – B2B – Pilot` (group),
> `Connected Org – Contoso – Pilot` (connected organization), `External Collaboration Catalog – Partners – Pilot`
> (catalog), `Partner Access – Project X – Pilot` (access package), `Require MFA – Guest Users – Pilot`
> (Conditional Access policy), and `Access Review – Guests – Pilot` (access review). Reuse these exact
> names in testing, troubleshooting, and the scripts. Replace `Contoso` / `Project X` with your real
> partner and project.

## Step 1 — Assess the current baseline
1. Run `ENTB2B-Discovery.ps1` to record the current default cross-tenant access settings, existing organizational settings, guest count, guest-scoped Conditional Access policies, and any access packages/reviews already present. Keep the output as your before-state.
2. Entra -> `External Identities -> Cross-tenant access settings -> Default settings`; note the current inbound and outbound B2B collaboration, direct connect, and trust settings before you change anything.
3. Entra -> `Users`, filter `User type = Guest`; run `ENTB2B-Report.ps1` for a guest-lifecycle snapshot (never signed in, inactive, no sponsor). This is your cleanup candidate list for later.

## Step 2 — Set conservative default cross-tenant access settings
1. Entra -> `External Identities -> Cross-tenant access settings -> Default settings -> Edit inbound defaults`.
2. **B2B collaboration**: allow inbound (so you can still invite guests) but keep it scoped to what you need; **B2B direct connect**: leave inbound **blocked** by default (enable only per-partner if you use Teams shared channels). **Trust settings**: do **not** trust MFA/device claims from unknown tenants by default.
3. `Edit outbound defaults` similarly — allow your users to be invited to partners you approve; block direct connect by default. Save.

> Why conservative defaults: the default policy applies to every tenant you have not explicitly named.
> Locking it down means new/unknown partners get the safe posture and you relax settings only for
> partners you vet in Step 3.

## Step 3 — Add the pilot partner as an organizational setting (trusted deliberately)
1. Entra -> `Cross-tenant access settings -> Organizational settings -> Add organization`; enter the partner tenant domain (for example `contoso.com`). Add.
2. Open the new organization entry -> **Inbound access**. Configure **B2B collaboration** to allow the partner's users (all, or a specific group/app). If you use Teams shared channels with this partner, enable **B2B direct connect** here (only here, not in the default).
3. Open **Trust settings** for this organization and, if the partner is vetted, enable **Trust multi-factor authentication from Microsoft Entra tenants**, **Trust compliant devices**, and/or **Trust hybrid Azure AD joined devices** so their guests satisfy your MFA/device Conditional Access without re-registering.
4. Optionally run `ENTB2B-Set-CrossTenantAccess.ps1 -PartnerTenantId <id> -WhatIf` to preview creating/adjusting this organizational configuration via Graph; re-run without `-WhatIf` once the preview is correct.

## Step 4 — Set guest onboarding controls
1. Entra -> `External Identities -> External collaboration settings`.
2. **Guest invite settings**: choose who can invite (recommended: `Member users and users assigned to specific admin roles can invite`, or restrict to the `Guest Inviter` role). **Guest user access**: restrict guest directory access to the most limited option appropriate for you.
3. **Collaboration restrictions**: optionally allow/deny invitations to specific domains (allow-list the partner domains you approve). Save.
4. (Optional) If you want external users to self-serve, Entra -> `External Identities -> User flows -> New user flow`; create a self-service sign-up flow and attach the identity providers and attributes you allow. Keep this out of the first pilot unless self-service is a pilot requirement.

## Step 5 — Build the pilot scope and approver groups
1. Entra -> `Groups -> New group -> Security`; create `B2B Pilot – Guest Scope – Pilot` (internal users collaborating with the partner). Create.
2. Create `Partner Approvers – B2B – Pilot` with at least two members (they approve the access package and can act as review sponsors). Create.

## Step 6 — Create the entitlement-management catalog, connected org, and access package
1. Entra -> `Identity governance -> Entitlement management -> Catalogs -> New catalog`; name it `External Collaboration Catalog – Partners – Pilot`; set **Enabled for external users = Yes**. Create. Open it -> `Resources -> Add resources` and add the app(s)/group(s) the guest needs.
2. Entra -> `Identity governance -> Entitlement management -> Connected organizations -> Add connected organization`; name it `Connected Org – Contoso – Pilot` and add the partner directory/domain. Add. (This lets you scope "who can request" to the partner org.)
3. In the catalog -> `Access packages -> New access package`; name it `Partner Access – Project X – Pilot`.
   - **Resource roles**: add the app/group role the package grants.
   - **Requests**: For users **not** in your directory -> choose `Specific connected organizations` -> `Connected Org – Contoso – Pilot`. Require approval; set the approver to `Partner Approvers – B2B – Pilot`.
   - **Lifecycle**: set an expiry (for example 90 days) and/or require an access review of assignments. Create.

> This is the governed onboarding path: the partner's users request `Partner Access – Project X – Pilot`,
> an approver approves, they become a guest with exactly the package's access, and the grant expires.
> Full entitlement-management design lives in the `ENTIGA` solution.

## Step 7 — Create the guest-scoped Conditional Access policy (report-only)
1. Entra -> `Protection -> Conditional Access -> Create new policy`; name it `Require MFA – Guest Users – Pilot`.
2. **Users**: Include `Guest or external users` -> select the external user types you want (for example `B2B collaboration guest users`); **Exclude** the two break-glass accounts (and any service accounts that must not be caught).
3. **Target resources**: All cloud apps (or scope to the pilot app first).
4. **Grant**: Require multi-factor authentication (optionally also Require compliant device where you trust the partner's device claims).
5. **Enable policy = Report-only**. Create.
6. Let it run and review `Insights and reporting` / sign-in logs. When impact is understood and only intended external sign-ins are affected, set **Enable policy = On**.

> Report-only first is non-negotiable: it shows exactly who the policy would affect before it can block
> anyone. The Conditional Access baseline itself (personas, named locations, full policy set) is the
> `ENTZTCA` solution — this adds one guest policy on top of it.

## Step 8 — Create the guest access review
1. Entra -> `Identity governance -> Access reviews -> New access review`.
2. **Review type**: `Teams + Groups` or `Applications` — select the group/app the pilot guests have access to (or review the access package's assignments). Name it `Access Review – Guests – Pilot`.
3. **Scope**: `Guest users only`. **Reviewers**: the resource owner or `Partner Approvers – B2B – Pilot` as sponsor (or self-review). **Recurrence**: quarterly. **Settings**: enable `Auto apply results`; set `If reviewers don't respond` to `Take recommendations` (safer than immediate Remove for the first cycle). Create.

## Step 9 — Validate on the pilot scope
1. Have the pilot partner contact request `Partner Access – Project X – Pilot`; confirm an approver in `Partner Approvers – B2B – Pilot` approves and the guest is created with the package's access and an expiry.
2. Sign in as the pilot guest and confirm the `Require MFA – Guest Users – Pilot` policy behaves as expected (report-only shows a would-be MFA requirement; once enforced, MFA is required). Confirm break-glass accounts are unaffected.
3. Run `ENTB2B-Validate.ps1` to confirm the default settings are conservative, the partner org is configured, the guest CA policy exists and excludes break-glass, and the access package/review are in place. Complete the Testing Guide.

## Step 10 — Cleanup stale guests (safe)
1. From Step 1 / `ENTB2B-Report.ps1`, identify guests who never signed in or are long inactive and have no current package or sponsor.
2. Run `ENTB2B-CleanupStaleGuests.ps1 -WhatIf` to preview disabling (then, on a later pass, removing) those guests. Review the preview, then re-run without `-WhatIf` once confirmed. Never include break-glass or internal accounts.

## Step 11 — Enforce and expand to production
1. Switch `Require MFA – Guest Users – Pilot` from report-only to **On** once impact is confirmed.
2. Add more partners as organizational settings (Step 3), each vetted before trusting MFA/device claims; publish more access packages per partner/project.
3. Extend the access review to all guests (or per catalog); tighten `If reviewers don't respond` to `Remove access` once reviewers are reliable.
4. (Optional) Configure cross-tenant synchronization with a partner to auto-provision guests, only after the invitation-based model is proven (see requirement 2.9, *verify*).
5. Re-validate each cycle with `ENTB2B-Validate.ps1` and `ENTB2B-Report.ps1`.

---
### Order of operations
`Assess (Discovery/Report) -> Conservative defaults -> Add partner org + trust -> Guest onboarding controls -> Scope/approver groups -> Catalog + connected org + access package -> Guest CA policy (report-only) -> Guest access review -> Validate -> Cleanup stale guests -> Enforce + expand`


---


# 5. Testing Guide — Entra External Identities (B2B) & Cross-Tenant Access

Run after the pilot scope is configured (Implementation Step 9) and after each expansion. Do portal
checks at `https://entra.microsoft.com`; every script connects to Microsoft Graph
(`graph.microsoft.com`).

## Test 0 — Baseline and connectivity confirmed
Do: Run `ENTB2B-Discovery.ps1`.
Expected: The script connects to Graph and prints the default cross-tenant settings, organizational settings, guest count, guest-scoped CA policies, and access packages/reviews. A connection error means the Graph SDK or consent is missing.

## Test 1 — Default cross-tenant settings are conservative
Do: Entra -> `External Identities -> Cross-tenant access settings -> Default settings`; or run `ENTB2B-Validate.ps1`.
Expected: Inbound/outbound B2B direct connect is blocked by default; MFA/device claims are **not** trusted from unknown tenants by default. Only named organizations relax this.

## Test 2 — Pilot partner is trusted deliberately
Do: `Cross-tenant access settings -> Organizational settings`; open `contoso.com`; or run `ENTB2B-Validate.ps1`.
Expected: The partner organization exists with the intended inbound B2B collaboration; trust settings (MFA/device) are enabled only for this vetted partner, not globally.

## Test 3 — Governed guest onboarding works
Do: The pilot partner contact requests `Partner Access – Project X – Pilot`; an approver in `Partner Approvers – B2B – Pilot` approves.
Expected: A `#EXT#` guest is created with exactly the package's access, an approver decision is recorded, and the grant carries the configured expiry. Ad-hoc guest access outside the package is not the path.

## Test 4 — Guest-scoped Conditional Access enforces MFA
Do: Sign in as the pilot guest to the target app. While the policy is report-only, check `Conditional Access -> Insights and reporting` / sign-in logs; after enforcement, attempt sign-in.
Expected: Report-only shows `Require MFA – Guest Users – Pilot` would apply; once enforced, the guest is required to complete MFA (or satisfies it via trusted partner MFA claims). Internal users and break-glass accounts are unaffected.

## Test 5 — Break-glass excluded
Do: Confirm the two break-glass accounts are excluded from `Require MFA – Guest Users – Pilot` and from broad policies; run `ENTB2B-Validate.ps1`.
Expected: Break-glass accounts are listed as excluded from the guest policy — flagged as intended, not a violation.

## Test 6 — Guest access review recertifies
Do: Open `Access Review – Guests – Pilot`; a reviewer records approve/deny decisions; let auto-apply run.
Expected: Denied guests lose access on apply; decisions are logged. With `Take recommendations`, non-response follows the recommendation rather than removing access blindly (first cycle).

## Test 7 — Guest lifecycle report and stale cleanup preview
Do: Run `ENTB2B-Report.ps1`, then `ENTB2B-CleanupStaleGuests.ps1 -WhatIf`.
Expected: The report lists guests by last sign-in / never-signed-in / inactive and flags stale candidates; the cleanup preview shows exactly which guests *would* be disabled, touching no break-glass or internal account and making no change in `-WhatIf`.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Test 0 confirms connectivity; Tests 1-5 pass; defaults are conservative, the partner is trusted deliberately, governed onboarding works, guest MFA applies, and break-glass is excluded |
| Expand pass | Test 6 (review recertifies) and Test 7 (report + safe cleanup) pass before enforcing the guest policy tenant-wide and adding more partners |


---


# 6. Troubleshooting Guide — Entra External Identities (B2B) & Cross-Tenant Access

Use `ENTB2B-Discovery.ps1` / `ENTB2B-Validate.ps1` for current state, `ENTB2B-Report.ps1` for the
guest lifecycle, and the two change scripts (`ENTB2B-Set-CrossTenantAccess.ps1`,
`ENTB2B-CleanupStaleGuests.ps1`, default `-WhatIf`) for safe fixes. Do portal work at
`https://entra.microsoft.com`.

## A. Guest invitation / onboarding problems
| Symptom | Cause | Remediation |
|---|---|---|
| Cannot invite a guest ("not allowed") | Guest invite settings restrict who can invite, or the domain is blocked | `External Identities -> External collaboration settings`; confirm invite permissions and that the partner domain is allowed (not on the deny list) |
| Partner user cannot request the access package | Requestor not scoped, or connected organization missing | Confirm `Partner Access – Project X – Pilot` request policy targets `Connected Org – Contoso – Pilot`; add the partner to the connected organization |
| Guest created but has no access | Package resource roles empty, or approval pending | Confirm the package grants a resource role; confirm an approver in `Partner Approvers – B2B – Pilot` approved the request |
| Self-service sign-up not offered | User flow not created/attached, or feature is preview/limited | Create the user flow under `External Identities -> User flows`; *verify current availability* of the identity providers you selected |

## B. Cross-tenant access / trust problems
| Symptom | Cause | Remediation |
|---|---|---|
| Guest is re-prompted to register MFA in your tenant | Partner's MFA claims are not trusted | In the partner's `Organizational settings -> Trust settings`, enable `Trust multi-factor authentication from Microsoft Entra tenants` (only for the vetted partner) |
| Teams shared channel with partner does not work | B2B direct connect blocked | Enable B2B direct connect **inbound/outbound** for that partner's organizational setting only (not the default) |
| A new/unknown partner has more access than expected | Default policy too permissive | Tighten `Cross-tenant access settings -> Default settings`; run `ENTB2B-Validate.ps1` to confirm defaults are conservative |
| `ENTB2B-Set-CrossTenantAccess.ps1` reports no change | Ran in default `-WhatIf` preview | Review the preview; re-run with `-WhatIf:$false` once correct |

## C. Break-glass and lockout risk
- Confirm the two break-glass accounts are excluded from `Require MFA – Guest Users – Pilot` and from broad Conditional Access; run `ENTB2B-Validate.ps1`.
- Break-glass accounts are internal cloud-only administrators — never scope the guest policy to include them, and never include them in stale-guest cleanup. If a guest/CA change causes broad impact, disable the new policy and sign in with a break-glass account to correct it.

## D. Conditional Access (guest policy) issues
| Symptom | Cause | Remediation |
|---|---|---|
| Guest policy blocks internal users | Policy scoped too broadly (not `Guest or external users`) | Re-scope Users to `Guest or external users` only; keep it in report-only until the sign-in logs show only external users affected |
| Policy has no effect | Still in report-only | Set `Enable policy = On` after confirming impact in `Insights and reporting` |
| Trusted-partner guest still challenged for MFA | Trust settings not enabled for that partner, or claim not satisfied | Enable trust for the partner organization; confirm the partner actually asserts the MFA claim |
| Legitimate external sign-in blocked | Grant control too strict for the scenario | Adjust the grant (for example allow trusted-partner MFA claim); re-test in report-only |

## E. Access review / lifecycle issues
| Symptom | Cause | Remediation |
|---|---|---|
| Review removed guests unexpectedly | `If reviewers don't respond` set to Remove with no decision | Set it to `Take recommendations` for early cycles; re-grant via the access package; re-run the review |
| Review has no reviewer | Sponsor/owner not set, or manager attribute empty | Assign `Partner Approvers – B2B – Pilot` as sponsor or a named reviewer; recreate the review |
| Stale guests not being removed | No review/expiry on the guests, or cleanup only run in preview | Add a recurring guest access review and package expiry; run `ENTB2B-CleanupStaleGuests.ps1` and, after reviewing the preview, re-run with `-WhatIf:$false` |
| Guests never expire | Access package has no expiry/lifecycle | Set a package expiry or periodic review in the package lifecycle settings |

## F. Licensing / feature not visible — verify
- If `Identity governance` (access reviews / entitlement management) is not visible, confirm **Entra ID P2 / Entra ID Governance** is assigned; if cross-tenant trust settings or Conditional Access are unavailable, confirm **Entra ID P1**. Run `ENTB2B-Discovery.ps1`. *Verify current licensing in your tenant.*
- If a capability appears in Microsoft docs but not in your tenant, it may be **preview** or vary by cloud (for example some self-service identity providers or cross-tenant sync options) — *verify current availability in your tenant* before depending on it.

## G. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Policy.Read.All','CrossTenantInformation.ReadBasic.All','User.Read.All','EntitlementManagement.Read.All','AccessReview.Read.All'
# Default + partner (organizational) cross-tenant access settings
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/default'
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/partners'
# Guest users
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userType eq 'Guest'&`$select=displayName,userPrincipalName,signInActivity,createdDateTime"
# Guest-scoped Conditional Access policies
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies'
```

## H. When to escalate
If cross-tenant settings are correct, the partner is trusted, the guest policy is scoped to external
users and excludes break-glass, connectivity is confirmed (Test 0), and onboarding or MFA still fails,
capture `ENTB2B-Report.ps1` output and the guest's sign-in log entry and open a Microsoft support case,
confirming whether the partner tenant's outbound cross-tenant settings permit the collaboration.


---


# 7. Best Practices — Entra External Identities (B2B) & Cross-Tenant Access

- Lock down the default, relax per partner. Set the default cross-tenant access policy conservatively (block direct connect, do not trust unknown-tenant MFA/device claims) and add organizational settings only for partners you vet. The default applies to every tenant you have not named — treat it as your safety net.
- Trust MFA/device claims only for vetted partners. Trusting a partner's multi-factor and compliant/hybrid-joined device claims removes re-registration friction without lowering the bar — but only for a partner whose posture you have confirmed. Never enable trust in the default policy.
- Enable B2B direct connect narrowly. Direct connect currently underpins Teams shared channels; enable it per-organization for the partners who need it, not in the default.
- Onboard guests through packaged access, not ad-hoc shares. Use an entitlement-management access package with an approver and an expiry (connected-organization scoped for external requestors) so every guest has an owner and an end date. Reserve one-off invitations for exceptions.
- Enforce a guest-scoped Conditional Access policy, report-only first. Require MFA on external sign-ins with a policy scoped to `Guest or external users`, deployed in report-only until impact is understood, then enforced. Always exclude the two break-glass accounts.
- Keep break-glass accounts out of the guest policy. Break-glass accounts are internal cloud-only administrators; exclude them from the guest-scoped policy and from broad policies so an external-user policy can never lock every admin out.
- Recertify guests on a schedule. Run a recurring access review scoped to guest users, with auto-apply, so stale external access decays without manual cleanup. Use `Take recommendations` for the first cycle, then tighten to `Remove access` once reviewers are reliable.
- Set expiry everywhere. Give access packages a defined expiry or a periodic review; a guest without an end date is guest sprawl waiting to happen.
- Clean up stale guests safely. Report guests who never signed in or are long inactive, preview removal with `-WhatIf`, disable before you delete, and never touch break-glass or internal accounts.
- Restrict who can invite and what guests can see. Delegate invitation to specific roles (or the `Guest Inviter` role) and restrict guest directory access to the minimum, so guest sprawl and directory enumeration are limited by default.
- Introduce cross-tenant sync only after the invitation model is proven. Auto-provisioning guests from a partner is powerful but couples the two tenants; pilot with invitations/packages first, then add sync deliberately (verify current availability).
- Name every object consistently. Use `<Purpose> – <Scope> – <Stage>` for groups, catalogs, packages, CA policies, and reviews so audits and expansion are repeatable.
- Verify licensing and preview before you rely on it. Cross-tenant trust and Conditional Access need P1; access reviews and access packages need P2 / Governance; some self-service and cross-tenant-sync options may be preview or vary by cloud — verify in your tenant.
- Pilot before you expand. Prove the model on one partner and a small guest scope before enforcing tenant-wide and adding partners, and keep a rollback path (report-only, disable-before-delete).

## Where to go next (adjacent catalog areas)
- **Entra ID Governance (`ENTIGA`)** — the full entitlement-management, catalog, access-package, and access-review build-out this solution plugs into. Adopt it to govern *all* access, not just guests.
- **Zero Trust Conditional Access (`ENTZTCA`)** — the Conditional Access baseline (personas, named locations, report-only discipline) that the guest policy here sits on top of.
- **Privileged Identity Management (`ENTPIM`)** — just-in-time, approval-gated admin roles for the internal administrators who run external collaboration.
- **Passwordless / passkey (`ENTPASSKEY`)** and **enterprise-app / service-principal governance** — strengthen internal authentication and app trust around the collaboration you have opened up.
- **Hybrid identity (Entra Connect)** and the **SAML App Factory** — for the on-premises identity and application onboarding that partners' access often depends on.


---


# 8. Deliverables Summary — Entra External Identities (B2B) & Cross-Tenant Access

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, outcome, scope boundary, and what is in the box |
| 1. Solution Overview | What External Identities is: cross-tenant access settings, guest onboarding, guest governance, benefits, limitations, and how it plugs into `ENTIGA` / `ENTZTCA` (gap-only) |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing, including licensing/preview items flagged *verify* |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites (tenant, base licensing, admin roles, break-glass, network), published once |
| 3. Implementation Guide | Exact, ordered steps in the Entra admin center — conservative defaults, one trusted partner, governed access package, report-only guest CA policy, and a guest access review — with every object named |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Symptom -> cause -> fix for the common failures |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Microsoft Graph)
| Script | What it does |
|---|---|
| `ENTB2B-Discovery.ps1` | Reports default and organizational cross-tenant access settings, guest count, guest-scoped Conditional Access policies, and access packages/reviews (read-only) |
| `ENTB2B-Validate.ps1` | Confirms defaults are conservative, the pilot partner is trusted deliberately, the guest CA policy exists and excludes break-glass, and the access package/review are in place (read-only) |
| `ENTB2B-Report.ps1` | Guest-lifecycle report — guests by last sign-in, never-signed-in, and inactive; flags stale/no-sponsor candidates (read-only) |
| `ENTB2B-Set-CrossTenantAccess.ps1` | Safely creates/adjusts the organizational cross-tenant access configuration and trust settings for a named partner (default `-WhatIf`) |
| `ENTB2B-CleanupStaleGuests.ps1` | Safely disables (then, on a later pass, removes) stale guest accounts; never touches break-glass/internal accounts (default `-WhatIf`) |

All scripts connect to Microsoft Graph (`graph.microsoft.com`). Discovery, Validate, and Report are
read-only; Set-CrossTenantAccess and CleanupStaleGuests change state and default to a safe `-WhatIf`
preview.

## What the buyer receives
Delivered as a **Complete Solution Package (PDF + Word + scripts)**:
- This implementation guide as a Word document and PDF (white-label).
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the standard model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
External access that is deliberate, scoped, and time-bound — partners trusted through named
cross-tenant settings, guests onboarded through packaged access with MFA and expiry, and stale guests
removed on review — proven on a pilot before you scale.
