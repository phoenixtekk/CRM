# 1. Solution Overview — SharePoint Online External Sharing & Access Governance

## What this solution is
External sharing is the feature that lets SharePoint Online and OneDrive for Business drive
collaboration with partners, vendors, and customers — and it is also the single largest lever for
accidental data exposure. This solution **governs external sharing and access** end to end: it sets
the **tenant-level sharing capability**, aligns **OneDrive** sharing to policy, tunes **site-level
sharing** so sensitive sites are tighter than the tenant default, sets **sharing-link defaults and
expiration** (so links stop defaulting to "Anyone" and stop living forever), enforces **allow/block
domain** restrictions, wires **sensitivity-label-driven** controls on site containers, stands up
**guest access reviews**, and produces **external-exposure reporting** so the organization can see who
outside the company can reach what.

The work is done in the **SharePoint admin center** and **Microsoft 365 admin center**, the **Microsoft
Entra admin center** (guests and access reviews), and the **Microsoft Purview portal** (sensitivity
labels), and automated with **SharePoint Online Management Shell** (`Set-SPOTenant` / `Set-SPOSite`),
**PnP PowerShell**, and **Microsoft Graph**. The result: sharing stays **enabled** where the business
needs it, but it is **scoped, defaulted safely, time-boxed, domain-restricted, reviewed, and
auditable**.

## Scope — what this is, and what it deliberately is NOT
This solution is **scoped to external sharing and external access governance** for SharePoint Online and
OneDrive: the tenant/OneDrive/site sharing capability, sharing-link types + defaults + expiration,
external-domain allow/block, applying (not designing) sensitivity labels that carry container sharing
controls, guest lifecycle + access reviews, and external-exposure reporting.

It is **not**:
- **Internal permissions management.** Site groups, permission levels, "broken" inheritance, and
  Everyone/Everyone-Except-External-Users (EEEU) cleanup are **internal** access and are a **separate
  product** (SharePoint permissions & access management). This solution touches internal permissions
  only where they create *external* exposure (an EEEU claim, an anyone-link).
- **Records, retention, or DLP.** Retention labels, records disposition, and Data Loss Prevention are a
  **separate Microsoft Purview product**. This solution *applies* a sensitivity label's **container**
  (site/group) sharing controls; it does **not** design the label taxonomy or its file-level
  encryption/DLP — **that is the compliance/records owner's determination** (see below).
- **Conditional Access / device policy.** Unmanaged-device restrictions (`-ConditionalAccessPolicy`,
  App-Enforced Restrictions) are referenced where they intersect sharing, but the Entra Conditional
  Access design is out of scope.
- **B2B identity architecture.** Entra External ID / cross-tenant access settings are referenced as the
  identity substrate for guests, but their full design is a separate identity product.

## The determination boundary (read this before configuring)
**What the policy should be — which domains are trusted, which sites are "confidential", how long a
guest may retain access, what an acceptable external-exposure posture is — is a
security/compliance/data-governance determination, not the implementer's.** This solution supplies the
**technical method** (the exact settings, cmdlets, gates, and evidence) and the **reporting** to inform
that decision; it does not decide the policy. Sensitivity-label definitions in particular are **authored
by the compliance owner in Microsoft Purview** — this solution applies an already-published label to a
container.

## Why this matters
- **"Anyone" links are unauthenticated and forwardable.** An Anyone (anonymous) link works for whoever
  holds the URL, with no sign-in — great for frictionless sharing, dangerous for sensitive content. If
  the tenant default link type is "Anyone" and links never expire, exposure accumulates silently.
- **Guests accumulate and go stale.** External users invited for a project remain long after it ends.
  Without expiration and periodic **access reviews**, the guest population — and what it can reach —
  only grows.
- **Sharing to any domain is sharing to competitors.** Without an **allow-list** (share only to named
  partner domains) or **block-list** (never share to these), a user can invite anyone.
- **You cannot govern what you cannot see.** Most tenants have no routine view of which sites carry
  Anyone-links, which have EEEU, or who the external users are. **External-exposure reporting** turns
  that blind spot into a monitored, auditable posture.

## How it works
1. **Assess the current posture first (read-only).** Capture the tenant sharing capability, OneDrive
   sharing capability, default link type/permission, expiration settings, domain mode, guest-expiration
   settings, per-site sharing capability for the sites in scope, and the external-user population. This
   is the `External Exposure – SPO – Discovery` baseline and the evidence for the policy decision.
2. **Set the tenant sharing baseline.** With `Set-SPOTenant`, set the tenant **`SharingCapability`** to
   the approved level, set **`DefaultSharingLinkType`** to *Specific people* (`Direct`) and
   **`DefaultLinkPermission`** to *View*, require **Anyone-link expiration**
   (`RequireAnonymousLinksExpireInDays`), require **guest-access expiration**
   (`ExternalUserExpirationRequired` + `ExternalUserExpireInDays`), and set the **domain restriction
   mode** and its allow/block list. This is `Tenant Sharing Baseline – SPO – Prod`.
3. **Align OneDrive.** Set **`OneDriveSharingCapability`** no looser than the SharePoint tenant setting
   (it cannot exceed it) so personal OneDrive sharing matches policy.
4. **Tighten sites that need it.** With `Set-SPOSite`, set a more restrictive **per-site
   `SharingCapability`**, per-site link defaults, per-site domain lists, and per-site Anyone-link
   expiration overrides (`OverrideTenantAnonymousLinkExpirationPolicy`) on the sites that hold sensitive
   content — a site can be **tighter** than the tenant, never looser.
5. **Apply sensitivity-label container controls.** For Group-connected sites, apply the compliance-owned
   **sensitivity label** whose **container settings** enforce external-sharing scope (and privacy /
   unmanaged-device access) at the container level — `Container Label – <Level> – Prod`. The label is
   published by the compliance owner; this solution applies it.
6. **Stand up guest access reviews.** Use **Microsoft Entra Access Reviews** (Graph / Entra portal) to
   review the guest population and the membership of externally-shared groups on a recurring cadence —
   `Access Review – Guests – Quarterly` — so access that is no longer needed is removed.
7. **Report external exposure on a cadence.** Enumerate sharing links and external principals across the
   sites in scope, plus the SharePoint **Data Access Governance (DAG)** reports, to produce
   `External Exposure – SPO – Report` — the recurring audit artifact.

Every change is **pilot-first**, on a named `Sharing Scope – Pilot – Stage1` set, with explicit
pass/fail gates and a rollback, before expanding to `Sharing Scope – Broad – Stage2`.

## The reference model (artifacts this solution creates)
Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across the docs, scripts,
the admin centers, and reports.

| Artifact | Name |
|---|---|
| Read-only external-exposure baseline export | `External Exposure – SPO – Discovery` |
| Tenant + OneDrive sharing baseline (Set-SPOTenant) | `Tenant Sharing Baseline – SPO – Prod` |
| Pilot site scope | `Sharing Scope – Pilot – Stage1` |
| Broad site scope | `Sharing Scope – Broad – Stage2` |
| Per-site tightened sharing (Set-SPOSite) | `Site Sharing – <SiteName> – Prod` |
| Default sharing-link type/permission | `Link Default – Specific-People-View – Prod` |
| Anyone-link expiration policy | `Anyone Link Expiration – 30d – Prod` |
| Guest-access expiration policy | `Guest Expiration – 60d – Prod` |
| Domain allow-list (share only to these) | `Domain Allowlist – Partners – Prod` |
| Domain block-list (never share to these) | `Domain Blocklist – Restricted – Prod` |
| Sensitivity label applied to a container | `Container Label – <Level> – Prod` |
| Recurring guest access review | `Access Review – Guests – Quarterly` |
| Recurring external-exposure report | `External Exposure – SPO – Report` |

> Replace `<SiteName>` and `<Level>` with your real site title and your published sensitivity-label name.
> The domain lists, expiration values (30d/60d are illustrative), and label names are the policy owner's
> determination — do not invent them.

## Benefits
- Sharing is **enabled but bounded** — the tenant/OneDrive/site capability matches approved policy, not
  the Microsoft default.
- New links default to **Specific people / View** and **Anyone-links expire**, so casual sharing stops
  creating unauthenticated, permanent exposure.
- External sharing is **domain-restricted** — only trusted partner domains (allow-list) or never
  blocked domains (block-list).
- Guests are **time-boxed and reviewed** on a cadence, so external access does not accumulate.
- External exposure is **visible and auditable** through a recurring report and the DAG reports.
- Every change is **pilot-first** with pass/fail gates and a rollback, so tenant-wide sharing — a
  high-impact change — is de-risked.

## Limitations (be honest with buyers)
- **Site sharing cannot exceed tenant sharing.** A per-site `SharingCapability` can only be **equal to
  or more restrictive** than the tenant setting; you cannot make one site "Anyone" if the tenant is
  "New and existing guests". Tightening the tenant setting **retroactively caps** looser sites.
- **Tightening tenant sharing can break existing links.** Reducing `SharingCapability` (e.g. removing
  Anyone) **disables** existing links of the now-disallowed type. This is why the rollout is pilot-first
  with a rollback and stakeholder sign-off.
- **Sharing settings are not instant tenant-wide.** `Set-SPOTenant` changes can take time to propagate
  across the service; validate after a propagation window, not immediately.
- **Sensitivity-label container controls are Purview-owned and license-dependent.** Applying a label
  requires the label to be **published** by the compliance owner, and container-label features depend on
  the plan — **verify in your tenant/plan**. This solution applies a label; it does not author one.
- **Access Reviews are an Entra ID Governance feature and are license-dependent.** Entra Access Reviews
  require **Microsoft Entra ID P2 / Microsoft Entra ID Governance** licensing — **verify in your
  tenant/plan**. Where that licensing is absent, this solution provides a scripted review artifact as a
  fallback.
- **Reporting is a snapshot, and enumeration has limits.** Link/permission enumeration through Graph and
  PnP reflects the moment it runs and can be throttled on very large tenants; treat the report as a
  recurring cadence, not a live feed. The SharePoint **DAG** reports themselves are a plan-dependent
  admin-center feature.
- **Commercial vs Government clouds differ.** Admin-center and tenant URLs differ on **GCC / GCC High /
  DoD** (`*.sharepoint.us`, `*.office365.us`, and Graph/endpoint variants); connect commands and some
  feature availability differ — **verify on your cloud**.

## The standard deployment model
> **Assess** the current sharing/exposure posture and licensing → **Design** the tenant baseline, site
> tiers, link defaults, domain lists, and review cadence (with the policy owner) → **Configure** them →
> apply to a **Pilot** scope first → **Validate** (sharing scoped to policy, links defaulted + expiring,
> external exposure visible, stale access reviewed) → **Expand** to the broad scope.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates
> and a documented rollback. Tenant-wide sharing is **high-impact** — this is not optional.
