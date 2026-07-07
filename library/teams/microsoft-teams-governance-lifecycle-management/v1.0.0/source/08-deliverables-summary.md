# Deliverables Summary

Everything included in **Microsoft Teams Governance & Lifecycle Management**, at a glance.

## Documentation

- **Solution Overview** (`01-solution-overview.md`) — the governance model (creation control, naming/
  classification, ownership, expiration/retention/archival, reporting), reference design with named
  artifacts, benefits, limitations, and the Assess→Design→Configure→Pilot→Validate→Expand model.
- **Requirements Guide** (`02-requirements.md`) — solution-specific prerequisites (Entra ID P1, Graph +
  beta directory-setting cmdlets, creators security group, Purview plan, published container labels, the
  agreed standard) on top of the shared Teams global requirements — each with Verify / Implement.
- **Implementation Guide** (`03-implementation.md`) — exact ordered steps to set creation control + naming,
  classification, ownership, and expiration/retention/archival — pilot-first, `-WhatIf` before commit,
  with pass/fail gates and a documented rollback. Every artifact named to convention.
- **Testing & Validation** (`05-testing.md`) — 10 procedures, each with an expected PASS/FAIL signal.
- **Troubleshooting** (`06-troubleshooting.md`) — common failure modes and resolutions.
- **Best Practices** (`07-best-practices.md`) — durable governance/lifecycle practices.
- **Executive Summary** (`executive-summary.md`) — the outcome, approach, and why it is low-risk.

## PowerShell scripts (5)

All scripts use modern-auth `Connect-*` (no stored credentials), are **read-only or `-WhatIf` by default**,
and require an explicit `-Commit` to write.

1. **`Get-TeamsGovernanceInventory.ps1`** — *Discovery / gap assessment (read-only).* Inventories every
   team/M365 Group and flags **ownerless**, **stale**, **duplicate**, and **unclassified** teams; reports
   whether open creation is still on. Exports the baseline CSV.
2. **`Set-TeamsCreationNamingPolicy.ps1`** — *Creation-control + naming config helper (`-WhatIf`/`-Commit`).*
   Sets `EnableGroupCreation=false` + `GroupCreationAllowedGroupId` (the creators group), applies the
   prefix/suffix naming requirement + blocked words, and optionally enables container labels. `-Rollback`
   restores open creation.
3. **`Set-TeamsLifecyclePolicy.ps1`** — *Expiration / retention / archival config helper (`-WhatIf`/
   `-Commit`).* Creates the M365 Groups expiration policy (scope All/Selected), creates a Purview retention
   policy **only when a compliance-supplied duration is passed**, and archives stale teams read-only via
   `Set-TeamArchivedState`. Supports `-RemoveExpiration` and un-archive for rollback.
4. **`Get-TeamsGovernanceReport.ps1`** — *Governance / lifecycle report (read-only).* One schedulable
   report combining control posture (creation, naming, classification, expiration) with estate metrics
   (ownerless/stale/duplicate/unclassified). Exports CSV + HTML for trending.
5. **`Test-TeamsGovernanceReadiness.ps1`** — *Validation / scope-health helper (read-only).* Emits PASS/FAIL
   per governance gate (creation controlled, naming enforced, classification on, expiration active,
   ownership, stale handled) and exits non-zero on failure so it can gate a rollout.
