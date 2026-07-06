# Best Practices

Field-proven practices for running a per-project group-provisioning model sustainably. These are the
**conditions of approval** in operational form — implement them and the model stays healthy for the
life of the domain.

## Naming standards

- Use a **deterministic, parseable** group name that embeds the project ID and the role:
  **`PRJ-projectId-ROLE (ROLE = READ, WRITE, or PRIV)`** (e.g. `PRJ-1042-READ`, `PRJ-1042-WRITE`,
  `PRJ-1042-PRIV`). Reuse this exact pattern everywhere — reports and cleanup parse the project ID
  from the second hyphen-delimited field.
- Keep the prefix (`PRJ-`) reserved for provisioned project groups only, so a prefix match cleanly
  separates them from the rest of the directory.
- Keep names within length limits and collision-free by construction (the project ID guarantees
  uniqueness). Never encode mutable data (owner name, department) into the name — put that in
  metadata.

## Dedicated OU subtree

- Place every provisioned group in one subtree: **`OU=ProjectGroups,OU=Provisioned,DC=your-domain-dn`**.
  A dedicated OU makes counting, reporting, delegation, and cleanup a single-scope operation.
- Delegate write permissions on that OU to the provisioning service account only — nothing else
  should create objects there.
- Never mix users, computers, or GPO-linked groups into this OU.

## AGDLP and least privilege

- Implement **A → G → DL → P**: project **resource** groups are **Domain Local**; users join via
  **Global role groups** nested into the resource groups. Apply the Domain Local groups directly to
  the resource ACLs.
- Keep the three privilege tiers distinct (Read / Write / Privileged) — do not collapse them just to
  reduce object count; collapse only to solve a **measured** token-bloat problem.
- Recertify **Privileged** membership on a fixed cadence (e.g. quarterly); privileged access drifts
  faster than any other tier.

## Lifecycle automation (the single most important control)

- Tie group lifetime to **project state**. On project close/archive, run a timed pipeline:
  **disable → stage → delete** (e.g. **30 / 60 / 90 days**). This converts an ever-growing pile into
  a steady state and is what makes the whole model sustainable.
  1. **Disable** (day 0 of closure): mark the group, remove it from active use, keep it recoverable.
  2. **Stage** (e.g. day 30): move to a quarantine OU / clear membership, retain for audit.
  3. **Delete** (e.g. day 90): remove the object after the retention window.
- Preview every cleanup run with **`RIDCAP-LifecycleCleanup.ps1`** (defaults to `-WhatIf`) before
  executing, and always drive it from the authoritative **active-projects list**.

## Ownership metadata

- Stamp each group at creation with **owner**, **project ID**, and **creation date** in
  `managedBy` / `info` (or a chosen extension attribute), consistently.
- This is what makes orphan detection, recertification, and cleanup automatable rather than manual.
  A group you cannot attribute to an active project is sprawl by definition.

## Monitoring thresholds

Schedule the read-only scripts and alert on these thresholds:

| Signal | Source script | Warn | Critical |
|---|---|---|---|
| **RID pool consumed** | `RIDCAP-Discovery.ps1` | **80%** of pool ceiling | 90% (plan extended RID pool) |
| **Group-SID count per principal** | `RIDCAP-TokenExposure.ps1` | **900 SIDs** | ~1,015 (hard auth-failure ceiling) |
| **Orphaned project groups** | `RIDCAP-Report.ps1` | any orphan outside lifecycle pipeline | orphan count trending up week-over-week |
| **Projected RID lifetime** | `RIDCAP-Report.ps1` | < 50 years | < 10 years |

- Alerting on RID at **80%** gives enormous lead time — at typical rates the pool sits at a fraction
  of one percent, so an 80% reading means something abnormal is burning RIDs.
- Watch **token size for portfolio-spanning identities** (PMs, power users, service accounts). They,
  not average members, are the token-bloat exposure.

## Bound portfolio-spanning identities

- Scope **service and automation accounts** to only the projects they truly need. An automation
  identity attached to the whole portfolio is the fastest path to token-size auth failures.
- Prefer **role-based** access (a maintained catalog of enterprise role groups) over adding an
  identity to every project's groups individually.

## Keep the safety valve in reserve

- Know that the **extended RID pool** (2^31) exists as a one-way, supported doubling of capacity on
  Server 2012+. Treat it as a genuine last resort triggered by the 80% alert — not a routine step,
  and never something to unlock preemptively.
