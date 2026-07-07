# 6. Troubleshooting — File-Share & On-Prem SharePoint → SharePoint Online Migration

Common failure modes and how to resolve them. Symptoms are grouped by phase. Where a limit or behavior
is Microsoft's and version/cloud-dependent, **verify the current value in Microsoft's docs for your
tenant/cloud** rather than assuming.

---

## Assessment & remediation

### Items fail migration for "path too long" even though the source path looked fine
- **Cause:** The failure is the **projected SPO URL** length (target site URL + relative path, with
  spaces URL-encoded), not the raw source path — the destination base adds length.
- **Resolve:** Re-run `SPOMIG-Assessment.ps1` with the **real target base URL** (`-TargetBaseUrl`) and
  the **current** `-MaxUrlLength`; shorten deep folders or land the content under a shorter target
  path. Flatten legacy tree depth in the `Target IA Map`.

### "Invalid character" / "reserved name" failures
- **Cause:** Names containing SPO-invalid characters, trailing spaces/dots, or reserved leaf names.
- **Resolve:** Rename at source per `Remediation Plan – Source – PreMigration`, or confirm the tool's
  **rename-on-ingest** behavior in its current docs and enable it. Don't assume the tool auto-fixes —
  verify.

### Assessment misses subtrees ("access denied")
- **Cause:** The migration account lacks read/ACL-read on some folders.
- **Resolve:** Grant the account read + ACL-read across the whole in-scope tree (Requirements §1) and
  re-run; an incomplete assessment yields an incomplete permission map.

---

## Permission mapping

### `SPOMIG-PermissionMap.ps1` reports unmatched principals
- **Cause:** Source NTFS/SP principals (local groups, deleted accounts, un-synced identities) don't
  resolve to Entra ID objects.
- **Resolve:** Complete directory sync for the population, replace local/stale groups with Entra
  groups, and make a **decision** for each unmatched principal — never migrate it as a guess. The wave
  gate requires **zero** unmatched.

### Day-one over-share or lockout after cutover
- **Cause:** A principal mapped to too broad a group (over-share) or a mapped group missing on the
  target (lockout).
- **Resolve:** Re-check `Permission Map – Source→SPO – Design`, prefer scoped **groups** over "Everyone"
  / broad groups, re-apply, and re-run the validation permission spot-check (Testing §9).

---

## Migration execution (Migration Manager / SPMT)

### The delta pass re-copies everything instead of only changes
- **Cause:** The incremental pass isn't the **same task/mapping** as the pre-stage, so the tool treats
  it as a new full migration.
- **Resolve:** Reuse the identical task (`Migration Task – <Scope> – Wave<N>`) and destination for the
  delta; incremental only works against the same task identity.

### `SPOMIG-TaskBuilder.ps1` moved nothing / built only a CSV
- **Cause:** That is the **safe default** — it dry-runs (build + validate) and does not start a
  migration without `-Commit`.
- **Resolve:** After validating the CSV, re-run with `-Commit` to `Register-SPMTMigration` /
  `Start-SPMTMigration`. If it still won't start, confirm the
  `Microsoft.SharePoint.MigrationTool.PowerShell` module is installed and sign-in succeeded.

### Migration Manager agent shows offline / tasks stuck
- **Cause:** The agent host lost line-of-sight to the source (SMB / on-prem SP) or to SPO (443), or the
  agent service stopped.
- **Resolve:** Confirm the agent is **online/healthy** in the SharePoint admin center, the host can
  reach both source and SPO endpoints (verify the current endpoint list for your cloud), and scale to
  **multiple agents** for throughput on large estates.

### Throttling / slow throughput mid-wave
- **Cause:** SPO service throttling under heavy concurrent load, or a single overloaded agent.
- **Resolve:** Spread load across more agents, migrate during off-peak windows, and let the tool's
  built-in retry/backoff run. Don't fight throttling with more parallelism on one host.

### Some files skipped: blocked type / oversized / in-use
- **Cause:** Files exceeding the SPO file-size limit, on the blocked-file-type list, or locked/open at
  scan time.
- **Resolve:** These should have surfaced in assessment — reconcile against
  `Source Assessment – FileShare+SP – Discovery`, remediate (archive/split/close), and re-run the
  delta. IRM/RMS-protected or encrypted files may need vendor handling (deferred to vendor docs).

---

## Validation & cutover

### Target item count is lower than source
- **Cause:** Legitimate filtered content (system files, blocked types) **or** genuinely missed items.
- **Resolve:** `SPOMIG-Validation.ps1` reports both counts; subtract the **intended** filter set — if a
  gap remains, inspect the tool's per-item report for the missing items and re-run the delta before
  passing the gate (Testing §8).

### Versions or metadata didn't come across as expected
- **Cause:** The migration **settings** (version-history depth, metadata options) didn't match the
  design.
- **Resolve:** Confirm the tool's settings against the design, re-run for the affected scope. Verify
  the exact setting names/behavior in the tool's current docs (they change).

### Users still editing the source after cutover ("split-brain")
- **Cause:** The source wasn't actually set **read-only** at the delta/cutover window.
- **Resolve:** Enforce read-only on the source at cutover per `Cutover Plan – <Scope> – Wave<N>`, re-run
  the delta to capture stragglers, then redirect users. Keep the source read-only (not deleted) until
  the wave gate passes.

---

## Government / sovereign cloud

### A step or tool behaves differently in GCC High / DoD
- **Cause:** Sovereign clouds (`*.sharepoint.us` / `*.office365.us`) can differ in tool support,
  endpoints, and limits.
- **Resolve:** **Verify in your tenant** — confirm the tool supports your cloud, use the correct
  endpoints, and re-confirm limit values; do not assume Commercial behavior.
