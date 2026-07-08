# 7. Best Practices — Implementing Microsoft Purview: Foundation, Roles & Onboarding

- **Enable the unified audit log first, before anything else.** Audit history cannot be back-filled — a
  day without ingestion is a day you can never investigate. Turn it on early even if you enable nothing
  else that week.
- **Start from least privilege, not from Global Admin.** Add people to the specific built-in role group
  their function needs; reserve Global Administrator for the two one-time setup actions (audit
  enablement, Graph consent). Broad admin "to get unblocked" is the mistake this whole foundation exists
  to prevent.
- **Keep the sensitive roles separated and named.** Insider Risk Management, Communication Compliance,
  and eDiscovery see sensitive employee content — keep their role groups minimal, named, separate from
  general compliance admin, and confirmed with HR/privacy/legal. Who may hold them is their call, not a
  technical default.
- **Always dry-run role changes.** Run `PURVIMP-Set-RoleGroups.ps1 -WhatIf` and read every line before
  `-Commit`; the script prints the exact reverse command for each add so rollback is trivial.
- **Prefer built-in role groups; create custom ones only to scope tighter.** Proliferating custom role
  groups makes the model harder to reason about. Use `New-RoleGroup` only where a built-in group grants
  more than the function needs.
- **Validate on a pilot ring before calling the tenant ready.** Prove roles, audit, Explorers, scope,
  and the baseline on a handful of admins and one or two sites first — the foundation is cheap to fix on
  a ring and expensive to fix tenant-wide.
- **Record what your licensing unlocks — and what it doesn't.** Purview is heavily plan-gated; document
  per capability "available on this plan" vs "deferred (not licensed)" so downstream solutions are
  scoped honestly. Verify every capability against your own tenant and plan.
- **Capture the Compliance Manager baseline as a dated artifact.** Export the assessment and snapshot the
  supporting signals so compliance improvement is measurable next quarter. The *target* (which
  regulations apply) belongs to compliance/legal.
- **Treat portal paths as provisional.** The Purview portal is actively evolving and role management is
  transitioning to a unified RBAC model — verify each path in your tenant rather than trusting a
  screenshot from last quarter.
- **This is the foundation, not the capabilities.** Do not author labels, DLP, retention, or
  insider-risk policies here — hand off to each capability's dedicated solution, where high-impact
  policies are piloted in simulation/test/disabled mode before enforcement.
