# Best Practices

Durable practices for running Teams governance & lifecycle over time.

## Governance model

- **Govern at creation, not after.** The cheapest sprawl to remove is the team that was never created.
  Keep `EnableGroupCreation = false` and manage a small, well-known `Group Creators – Governed – Prod`
  group (or a request/approval front end) rather than reactively cleaning up.
- **One creators group, clearly owned.** `GroupCreationAllowedGroupId` accepts exactly one security group.
  Keep its membership deliberate and reviewed; treat additions as a governance decision.
- **Decisions on paper before settings in the tenant.** The naming standard, classification scheme,
  expiration lifetime, and archival criteria should be signed off before you touch directory settings —
  configuring first causes user-facing churn.

## Naming & classification

- **Make names self-describing and queryable.** A consistent prefix/suffix (department, function) lets the
  reporting script and admins slice the estate. Reserve blocked words for the terms that must never appear
  (`CEO`, `Payroll`, executive names).
- **Use container sensitivity labels, not legacy classifications.** The old `ClassificationList` is
  deprecated; standardize on published container labels scoped to Groups & sites, and let the label drive
  privacy/guest settings so classification and access stay coupled.
- **Keep the label set small.** Three to five container labels are easier to apply correctly than a long
  list; correctness beats granularity.

## Lifecycle: expiration, retention, archival

- **Separate expiration from retention.** Expiration removes *inactive* groups; retention *preserves*
  content for a compliance duration. They serve different owners and must not be conflated — a group can be
  expired while its content is still under a retention hold.
- **Retention duration belongs to compliance.** Never set a retention or records duration from a technical
  default; capture it from the compliance/records owner and record who decided it.
- **Prefer archive over delete for ambiguous teams.** When in doubt, `Set-TeamArchivedState` keeps the team
  read-only and reversible instead of a hard delete; expiration soft-delete is restorable only within the
  deleted-groups window (verify duration in your tenant).
- **Renewal notifications go to a monitored mailbox.** Point `alternateNotificationEmails` at a governance
  distribution list, not one person, so renewals aren't missed when someone is out.
- **Auto-renew on activity.** M365 Groups expiration auto-renews groups that show activity — rely on it so
  active teams are not falsely expired, and target the manual review at genuinely idle groups.

## Ownership

- **Enforce a minimum of two owners.** A single owner is a single point of failure; require ≥ 2 and use the
  ownerless groups policy to recruit owners automatically before a team goes orphaned.
- **Re-check ownership on a cadence.** Owners leave the org; schedule the inventory script to resurface
  ownerless/under-owned teams monthly.

## Operations & safety

- **Always dry-run first.** Every write script defaults to `-WhatIf`/report mode; run it, read the plan,
  then `-Commit`. Creation control and tenant-wide expiration are the two changes most worth a second look.
- **Pilot scope with `Selected`, expand to `All`.** Use `-ManagedGroupTypes Selected` to validate
  expiration on a handful of groups before switching to `All`.
- **Announce high-impact changes.** Turning off open creation, enforcing naming, and enabling tenant-wide
  expiration are visible to end users — communicate ahead of the commit.
- **Keep the baseline.** Retain the Stage-1 inventory as the "before" record and rollback reference.
- **No secrets in code.** Use interactive modern-auth `Connect-*` (or a managed identity / app registration
  with least-privilege consent for scheduled runs) — never hardcode credentials.
- **Verify plan- and cloud-dependent behavior in your tenant.** Entra ID P1 gating, Purview plan coverage,
  label-sync cmdlet names, deleted-group restore windows, and Government-cloud portal URLs
  (`*.office365.us`) all vary — confirm rather than assume.

## Reporting & continuous improvement

- **Report on a schedule and trend it.** Run `Get-TeamsGovernanceReport.ps1` monthly; a falling
  ownerless/stale/duplicate count is the proof the governance model is working.
- **Close the loop.** Feed report findings (new duplicates, recurring bad names) back into the naming
  standard, blocked-words list, and creator training.
