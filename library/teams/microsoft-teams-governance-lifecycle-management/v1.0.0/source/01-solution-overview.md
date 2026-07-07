# Solution Overview

## What this solution is

**Microsoft Teams Governance & Lifecycle Management** is a run-to-implement solution that puts an
enterprise back in control of how Microsoft Teams is created, named, classified, owned, and retired.
Every team is backed by a **Microsoft 365 Group**, so "Teams governance" is really governance of the
underlying M365 Groups plus the Teams-specific surfaces (channels, archival, reporting). Without
governance, Teams grows into **sprawl**: anyone can spin up a team, duplicates multiply, owners leave
and are never replaced, and data ages indefinitely with no expiration or retention decision behind it.

This solution establishes five governance controls and the lifecycle behind them:

1. **Creation control** — restrict who can create teams/M365 Groups to an approved **group-of-creators**
   (or a request/approval model), instead of letting every user create at will.
2. **Naming & classification policy** — a tenant naming standard (prefix/suffix + blocked words) and a
   **classification** decision on every team (via container **sensitivity labels**), so teams are
   self-describing and their sensitivity is visible.
3. **Membership & ownership standards** — a minimum-owners rule and an ownerless-remediation path so no
   team is left without an accountable owner.
4. **Expiration, retention & archival** — an **M365 Groups expiration policy** so inactive teams are
   renewed-or-removed, **Microsoft Purview retention** for Teams content (the *schedule* is the
   compliance team's determination — you deliver the technical method), and **archival** of teams that
   should be kept read-only rather than deleted.
5. **Governance reporting** — a repeatable report of creation-control status, naming/classification
   coverage, ownerless/stale/duplicate teams, and expiration posture.

## How it works

The controls live in three planes, all driven by **PowerShell** (no hardcoded secrets):

- **Directory settings (`Group.Unified` template)** — the tenant-wide behavior for M365 Group creation,
  the group naming policy (prefix/suffix + custom blocked words), and the switch that turns on
  sensitivity labels for groups. Managed with the **Microsoft Graph PowerShell (beta) directory-setting
  cmdlets** (`Get-MgBetaDirectorySetting` / `Update-MgBetaDirectorySetting`).
- **Group lifecycle policy** — the **expiration** policy (lifetime in days, which groups it covers,
  renewal notifications) managed with `*-MgGroupLifecyclePolicy`.
- **Purview & Teams surfaces** — **retention policies** for Teams channel messages / chats and the
  associated SharePoint/OneDrive files (Security & Compliance PowerShell), **container sensitivity
  labels** for classification (Purview), and **team archival** with `Set-TeamArchivedState`
  (MicrosoftTeams module).

> **Plan / licensing note (verify in your tenant).** The M365 Groups **naming policy**, **expiration
> policy**, and **container sensitivity labels for groups** require **Microsoft Entra ID P1** for the
> affected users, and **Purview retention** requires the appropriate compliance plan. Commercial vs
> Government (GCC/GCC High/DoD) tenants use different portal URLs (e.g. `*.office365.us`) and some
> features roll out differently — confirm availability and the exact portal path in your own tenant.

## Reference design

A worked reference used throughout the implementation, testing, and scripts. Reuse these exact artifact
names when you implement:

| Artifact | Name (convention `<Purpose> – <Scope> – <Stage>`) | Purpose |
|---|---|---|
| Creators security group (pilot) | `Group Creators – Governed – Pilot` | Members who may create M365 Groups/Teams during pilot |
| Creators security group (prod) | `Group Creators – Governed – Prod` | Approved creators tenant-wide after expansion |
| Naming policy | `Naming Policy – M365 Groups – Prod` | Prefix/suffix + blocked-words standard |
| Classification labels | `Sensitivity Label – Public/Internal/Confidential – Prod` | Container labels applied to teams |
| Expiration policy | `Expiration Policy – M365 Groups – Prod` | Renew-or-remove lifetime for teams |
| Retention policy | `Retention Policy – Teams – Prod` | Purview retention for Teams messages + files (schedule set by compliance) |
| Ownerless remediation | `Ownerless Policy – Teams – Prod` | Prompts members to become owners |
| Pilot team set | `Pilot Team – Governance-A – Pilot` … | The teams the pilot validates against |

## Benefits

- **Sprawl stops at creation** — only approved creators (or an approved request) can make a team, so
  duplicates and shadow teams stop multiplying.
- **Every team is self-describing** — naming standard + classification make ownership, purpose, and
  sensitivity visible at a glance and queryable in reporting.
- **No orphaned data** — expiration renews-or-removes inactive teams, retention satisfies the compliance
  schedule, and archival keeps must-retain teams read-only instead of deleting them.
- **Accountable ownership** — minimum-owners and ownerless remediation keep every team owned.
- **Evidence, not guesswork** — the reporting script produces a defensible governance posture on demand.

## Limitations & boundaries

- **Compliance/records/legal determinations are deferred.** Retention **durations**, records schedules,
  legal-hold scope, and which classification maps to which policy are decisions for the org's
  compliance/records/legal functions. This solution delivers the **technical method and evidence**, not
  the determination.
- **Licensing-gated features are flagged, not assumed.** Naming policy, expiration, container labels, and
  retention depend on Entra ID P1 / Purview plans — verify in your tenant.
- **A full self-service request portal** (approval workflow beyond the creators-group model) is an
  optional extension (e.g. a Power Automate / ticketing front end) referenced at the pattern level.
- **Third-party governance/provisioning tools** are out of scope; this solution uses native M365 controls.

## Deployment model

This solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
because turning off open group creation and enabling expiration are **high-impact, tenant-wide** changes:

1. **Assess** — inventory existing teams/groups; find ownerless, stale, and duplicate teams (read-only).
2. **Design** — decide the creators-group model, naming standard, classification scheme, expiration
   lifetime, retention posture (with compliance), and archival criteria.
3. **Configure** — apply each control **against the pilot scope** first, using `-WhatIf` dry-runs.
4. **Pilot** — validate on `Group Creators – Governed – Pilot` and a small pilot team set.
5. **Validate** — run the validation gates (creation controlled, naming enforced, expiration active,
   stale teams handled); confirm each **pass/fail** gate.
6. **Expand** — roll to production (`… – Prod`) under change control, with a **documented rollback**
   (re-enable creation, remove naming/expiration) ready at every step.
