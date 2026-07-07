# 8. Deliverables Summary — File-Share & On-Prem SharePoint → SharePoint Online Migration

Everything included in this solution, on one page.

## Documentation
- **01 · Solution Overview** — the migration model (assess/remediate, target IA mapping, tool options,
  pre-stage/delta, permissions, validation), the reference design, benefits, limitations, and the
  Assess → Design → Configure → Pilot → Validate → Expand deployment model.
- **02 · Requirements** — the seven migration-specific prerequisites (source access, migration
  workstation/agent, tool choice, target IA, storage + service-limit check, identity mapping, cutover
  window) that build on the shared SharePoint global requirements.
- **03 · Implementation** — exact ordered steps: assess → remediate + design target IA + permission
  map → configure the tool → pilot pre-stage/delta → validate (gate) → expand wave by wave. Every
  artifact named; pass/fail gates and rollback included.
- **05 · Testing & Validation** — ten tests, each with pass/fail signals, culminating in the wave gate
  (counts + permissions + delta-clean + governed).
- **06 · Troubleshooting** — the common failure modes (blocked items, permission mismatches, delta
  re-copies, agent/throughput, throttling, identity gaps) and their resolutions.
- **07 · Best Practices** — durable practices for assessment, target design, permission mapping,
  pre-stage/delta cutover, validation, safety, and government-cloud verification.
- **Executive Summary** — outcome, approach, and why the migration is low-risk.

## PowerShell tools (5) — read-only or dry-run by default, no credentials in code
1. **`SPOMIG-Assessment.ps1`** — *Source assessment (read-only).* Scans a file share (and inventories
   on-prem SP content passed in) for the blockers that fail SPO migrations — path/URL length near the
   limit, invalid characters/reserved names, blocked file types, oversized files, deep nesting — and
   summarizes the permission surface. Emits `Source Assessment – FileShare+SP – Discovery`. Current
   SPO limits are passed as parameters so the check tracks Microsoft's real numbers. Makes no changes.
2. **`SPOMIG-PermissionMap.ps1`** — *Permission-mapping helper (read-only).* Enumerates source
   principals (NTFS/SP groups, ACEs) and proposes a target mapping to SPO/M365/Entra groups with a
   permission level, flagging **unmatched** principals for a decision. Emits `Permission Map –
   Source→SPO – Design`. Plans only; changes nothing.
3. **`SPOMIG-TaskBuilder.ps1`** — *SPMT task/CSV builder + runner (safe-by-default).* Turns
   `Target IA Map – SPO – Design` into a migration bulk CSV and validates it (**dry-run by default**);
   only registers and starts the SPMT migration when `-Commit` is passed. Uses the
   `Microsoft.SharePoint.MigrationTool.PowerShell` module with modern-auth sign-in.
4. **`SPOMIG-Validation.ps1`** — *Post-migration validation (read-only).* Compares source vs. target
   **item counts** and spot-checks **permissions** against the permission map via PnP PowerShell.
   Emits `Post-Migration Validation – <Scope> – Validate` — the evidence for the wave gate.
5. **`SPOMIG-ScopeHealth.ps1`** — *Scope/config health helper (read-only).* Verifies the target site
   exists and is writable, storage is sufficient, and the migration prerequisites are green before
   tasks are defined. Reports only.

## Named artifacts (created during implementation)
`Source Assessment – FileShare+SP – Discovery` · `Remediation Plan – Source – PreMigration` ·
`Target IA Map – SPO – Design` · `Permission Map – Source→SPO – Design` ·
`Migration Task – Pilot – Wave0` · `Migration Task – <Scope> – Wave<N>` ·
`Cutover Plan – <Scope> – Wave<N>` · `Post-Migration Validation – <Scope> – Validate` ·
`SPO Site – Pilot – Prod`
