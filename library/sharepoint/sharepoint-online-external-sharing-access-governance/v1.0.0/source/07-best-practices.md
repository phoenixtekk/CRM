# 7. Best Practices — SharePoint Online External Sharing & Access Governance

Durable practices for keeping external sharing enabled, controlled, and auditable over time.

## Policy first, settings second
- **Never configure sharing without an approved policy.** Each setting encodes a security/compliance
  decision. Run the Discovery baseline, workshop the values with the policy owner, get sign-off, then
  configure. The implementer supplies the method and the evidence — not the determination.
- **Right-size the tenant level.** Default to the **least-open level that still lets the business work**
  — commonly **New and existing guests** (`ExternalUserSharingOnly`, no Anyone links). Reserve **Anyone**
  (`ExternalUserAndGuestSharing`) for tenants that genuinely need unauthenticated links, and then only
  with **expiration** and preferably **view-only** Anyone links.

## Safe defaults beat after-the-fact cleanup
- **Default the link to Specific people / View.** `DefaultSharingLinkType = Direct` and
  `DefaultLinkPermission = View` stop the most common oversharing at the source — users can still choose
  broader when they mean to, but the safe choice is the default.
- **Expire everything external.** Require Anyone-link expiration (where Anyone is allowed) **and**
  guest-access expiration. Time-boxing is the cheapest control against accumulation.
- **Prevent guest re-sharing** (`PreventExternalUsersFromResharing $true`) and **require the accepting
  account to match the invited account** (`RequireAcceptingAccountMatchInvitedAccount $true`) so an
  invitation can't be forwarded to an unintended recipient.

## Tighten by tier, not tenant-wide only
- **Make sensitive sites tighter than the tenant.** A per-site `SharingCapability` can only be equal to
  or tighter than the tenant — use that to lock down confidential sites while leaving general
  collaboration open. Keep the tenant at the collaboration level the majority need, and step **down**
  per site.
- **Prefer sensitivity-label container controls for consistency.** Where the compliance owner has
  published labels with container settings, applying a label carries the sharing/privacy/device posture
  as a unit and travels with the container — more durable than ad-hoc per-site settings.

## Domains: allow-list when you can
- **Allow-list beats block-list** for high-assurance environments — you enumerate the domains you
  *trust* rather than chasing the infinite set you don't. Use a block-list only when open collaboration
  is the norm and you're excluding specific bad actors/competitors.
- **Keep the domain list under change control.** Adding a partner domain is a policy change; review the
  list on the same cadence as the access reviews.

## Guests are a lifecycle, not a one-time invite
- **Review guests on a recurring cadence** (`Access Review – Guests – Quarterly`) with **auto-apply** so
  unreviewed/denied access is actually removed, not just flagged. Assign group owners as reviewers —
  they know who should still have access.
- **Expire, then clean up.** Guest expiration plus reviews together keep the external population from
  growing without bound. Periodically remove fully stale guests from the directory.

## Make exposure visible on a cadence
- **Run the external-exposure report routinely**, not just at go-live. Sharing drifts as people work;
  the report (`External Exposure – SPO – Report`) plus the admin-center **Data Access Governance**
  reports (Sharing links, EEEU) turn drift into a monitored signal.
- **Watch for EEEU on externally-shared sites.** "Everyone Except External Users" combined with a broad
  sharing capability is a classic oversharing pattern — the DAG EEEU report surfaces it; remediate via
  the internal-permissions product.

## Operate safely
- **Pilot every change and keep the rollback staged.** Tenant sharing is high-impact and tightening can
  disable existing links — always in a change window, always with the Stage-0 values retained.
- **Automate read-only, gate the writes.** Use the Discovery/Validation/Report scripts freely (they only
  read); run the config script **dry-run first**, then `-Commit`. **Never store credentials in scripts**
  — modern-auth `Connect-*` only.
- **Mind Commercial vs Government clouds.** Admin URLs, Graph endpoints, and some feature availability
  differ on GCC / GCC High / DoD — connect with the right host/environment and **verify capability on
  your cloud** rather than assuming Commercial behavior.
- **Document the boundary.** Keep this solution in its lane (external sharing & access); route internal
  permissions, retention/records/DLP, Conditional Access, and label authoring to their owning products
  so nothing falls between the cracks.
