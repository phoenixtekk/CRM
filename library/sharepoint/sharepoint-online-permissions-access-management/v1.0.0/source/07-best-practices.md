# 7. Best Practices

Durable practices for keeping SharePoint access intentional and auditable after the initial remediation.

## Model & structure
- **Grant to groups, never to users.** Make it a hard rule: a person never appears in a role assignment;
  a **group** does. Add the person to `SPO Group – Finance Members – Prod` (or the backing `M365 Group –
  Finance – Prod`), not to the site or the item. Group-based access is the single most important habit —
  it is what makes access legible and self-cleaning.
- **Back SharePoint groups with a governed Entra/M365 group** wherever possible, so joins/leaves/transfers
  flow automatically from the identity source of truth rather than being maintained by hand.
- **Keep the Owners group tiny.** Full Control includes permission management; every extra owner is
  someone who can re-break the model. Two or three owners per site is plenty.
- **Standardize on the built-in permission levels** (Full Control / Edit / Contribute / Read). Introduce a
  custom level (`Perm Level – Read No Download – Prod`) only for a real requirement the built-ins can't
  express, and **never edit a built-in level in place** — it changes behavior everywhere it's used.

## Inheritance & unique permissions
- **Inheritance is the default; unique permissions are an exception.** Every place inheritance is broken
  is a boundary you must maintain forever. Treat each one as debt: it needs a documented reason, an owner,
  and a group (not a user) grant — or it gets reset to inherit.
- **Don't break inheritance to solve a one-off.** The reflex "just give them this one folder" is how the
  tangle grows. Prefer a **separate site or library** with its own group for content that genuinely needs
  a different audience, rather than a unique-permission scope buried inside a shared site.
- **Remediate Limited Access by removing its cause.** Limited Access is system-managed noise created by
  sub-scope unique grants; you clear it by resetting the underlying scope, not by touching Limited Access.
- **Prefer library/list-level boundaries over item-level.** Item-level unique permissions are the hardest
  to audit and the easiest to orphan. If a boundary is needed, put it as high as possible.

## Change discipline
- **Audit before you change, always.** The `Permission Audit – SPO – Discovery` export is both your
  evidence and your rollback baseline. Never remediate without a current one.
- **`-WhatIf` before `-Commit`, pilot before broad.** High-impact permission changes go through the full
  house cycle every time: read-only audit → owner review → dry-run → commit → validate.
- **Owner-approve every exception.** A unique-permission scope survives only if the information owner signs
  off; otherwise it's remediated. Keep the exception list in `Access Model – SPO – Design` current.
- **Name everything consistently.** Reuse the `<Purpose> – <Scope> – <Stage>` names across groups,
  reviews, reports, and change records so the model is self-documenting.

## Ongoing attestation & drift control
- **Run recurring access reviews.** Access is only as good as its last review. Use Entra ID Access Reviews
  (P2) for group membership, SharePoint site access review + Data Access Governance reports (SAM) for
  over-share detection, or the scheduled `SPOPERM-AccessReview.ps1 -Report` where the add-ons aren't
  licensed — whichever the tenant supports.
- **Report on a schedule, not just on request.** A recurring `Access Report – SPO – Report` catches drift
  (new direct grants, new broken inheritance) between formal reviews.
- **Re-baseline after big changes.** After a reorg, migration, or mass onboarding, re-run discovery and
  compare — new sprawl is easiest to fix while it's small.
- **Watch for the return of direct grants.** The failure mode is always the same: someone "just adds a
  user" to fix an urgent access request. Make the recurring report flag new direct grants so they're
  converted to group membership quickly.

## Cloud & licensing awareness
- **Verify plan-dependent features in your tenant.** Access Reviews (Entra ID P2) and DAG reports / site
  access review (SAM) are add-on-gated and evolve — confirm availability before designing around them, and
  keep the PowerShell fallback path viable.
- **Mind Commercial vs Government cloud differences.** Admin-center URLs and some feature availability
  differ on GCC / GCC High / DoD (`*.sharepoint.us`, `portal.azure.us`) — verify paths on your cloud
  rather than assuming the commercial ones.
