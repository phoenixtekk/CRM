# 7. Best Practices — File-Share & On-Prem SharePoint → SharePoint Online Migration

Durable practices for migrating file shares and on-prem SharePoint into SharePoint Online cleanly.

## Assess before you move — always
- **Never migrate un-assessed content.** Path/URL length, invalid characters, blocked file types, and
  oversized files fail *during* the migration; find them in assessment, not at scale on cutover night.
- **Track Microsoft's limits as live values, not memorized constants.** SPO service limits change and
  differ by cloud (Commercial vs Government / sovereign). Feed the *current* documented values into
  `SPOMIG-Assessment.ps1` as parameters and re-confirm per engagement.
- **Measure the permission surface early.** The number of distinct principals in the source ACLs
  predicts how hard the permission map will be — surface it in assessment so it isn't a surprise.

## Design a target, don't mirror the source
- **Map to a governed IA; don't pave the cow paths.** Migration is the one chance to flatten deep
  trees, retire dead shares, and land content where it belongs. Mirroring drive letters wastes it.
- **Every target site has an owner and a sharing posture before content lands.** Migrating into an
  ungoverned site creates orphans on day one.
- **Name everything once** with `<Purpose> – <Scope> – <Stage>` and reuse the names across the
  assessment, map, tasks, validation, and cutover plan — traceability from source path to destination
  URL is what makes validation possible.

## Permissions: map to groups, resolve every principal
- **Prefer SPO/M365/Entra groups over individuals.** Individual ACEs migrated verbatim recreate the
  unmanageable sprawl you're trying to escape.
- **Resolve unmatched principals with a decision, never a guess.** An unmapped principal either
  over-shares or locks people out — both are day-one incidents. `SPOMIG-PermissionMap.ps1` flags them
  so they get a decision.
- **Break-permission inheritance sparingly in the target.** Re-establish clean inheritance where the
  legacy source had ad-hoc unique permissions everywhere.

## Migrate with pre-stage + delta — keep downtime tiny
- **Pre-stage while the source is live, delta at cutover.** Do the slow bulk copy with users still
  working; freeze the source read-only only for the short incremental pass. This turns a multi-day
  freeze into hours.
- **Reuse the same task for the delta.** Incremental only works when the delta pass is the *same*
  task/mapping as the pre-stage — a new task re-copies everything.
- **Scale throughput with multiple agents (Migration Manager)** for large estates rather than one
  overloaded host; measure and right-size.
- **Never set the source read-only before pre-stage completes** — the freeze belongs at the delta/
  cutover moment, not before.

## Validate every wave — evidence, not optimism
- **Counts + permissions + delta-clean + governed** is the gate. A wave isn't done because the tool
  said "complete"; it's done when the validation report proves it.
- **Spot-check permissions in the real UI**, not just the tool's log — confirm no broad group crept
  in and every mapped group is present.
- **Keep the source authoritative until the gate passes and a soak period ends.** The source read-only
  copy is your rollback; don't destroy it early.

## Safety and secrets
- **Read-only by default; writes gated behind `-Commit`.** Assessment, permission-mapping, scope-
  health, and validation change nothing. Task execution moves data only on explicit `-Commit`.
- **No hardcoded credentials.** Use modern-auth `Connect-PnPOnline` / `Connect-SPOService` /
  `Register-SPMTMigration` interactive or app-registration sign-in; never embed secrets in the
  scripts or the CSVs.
- **Least-privilege migration account.** Grant only the source read/ACL-read and the target
  contribute/owner the migration needs; don't run migrations as a tenant Global Admin by default.

## Compliance stays with compliance
- **Technical method, not legal determination.** What to retain, what's under legal hold, and which
  records schedule applies are decided by the compliance/records/legal functions. This solution
  supplies the migration method and the evidence; the *decision* to delete or archive a retired source
  is theirs.

## Government and sovereign clouds
- **Verify, don't assume.** GCC High / DoD (`*.sharepoint.us` / `*.office365.us`) and other sovereign
  clouds can differ in tool support, endpoints, and limits. Confirm each in your tenant before
  planning a wave there.
