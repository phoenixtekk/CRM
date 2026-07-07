# 5. Testing & Validation — File-Share & On-Prem SharePoint → SharePoint Online Migration

Each test states **how to run it** and the **expected pass/fail signal**. Assessment and validation
are **read-only**. Run the pilot-scope tests before any broad wave; re-run the per-wave tests for
every subsequent wave. The overall gate is: **content migrated (counts), permissions migrated
(spot-check), delta clean, target governed.**

---

## Test 1 — Assessment completeness (pre-migration)
- **Run:** `.\SPOMIG-Assessment.ps1 -Path \\fs01\PilotFinance -MaxUrlLength <current-limit> -MaxFileSizeGB <current-limit> -CsvPath .\a.csv`
- **PASS:** The export `Source Assessment – FileShare+SP – Discovery` exists and reports a blocker
  count for path length, invalid characters, blocked types, and oversized files, plus a distinct-
  principal count for the permission surface.
- **FAIL:** The scan errors, misses subtrees (access denied), or the limit parameters don't match the
  current Microsoft-documented values → fix access / confirm current limits and re-run.

## Test 2 — Remediation punch-list resolves every blocker
- **Run:** Reconcile `Remediation Plan – Source – PreMigration` against the assessment export.
- **PASS:** Every blocker in the assessment has a corresponding fix (at-source rename/shorten/remove,
  or an in-flight tool rename confirmed against the tool's docs). Zero blockers are unaddressed.
- **FAIL:** Any assessed blocker has no planned fix → resolve before configuring tasks (unremediated
  blockers fail mid-migration).

## Test 3 — Permission map has no unresolved principals
- **Run:** `.\SPOMIG-PermissionMap.ps1 -Path \\fs01\PilotFinance -CsvPath .\pm.csv` then review the
  `Unmatched` column.
- **PASS:** `Permission Map – Source→SPO – Design` maps every source principal to an SPO/M365/Entra
  target with a permission level; **zero rows flagged unmatched**; mappings favor groups over
  individuals.
- **FAIL:** Any principal is unmatched or maps to an individual where a group exists → resolve with a
  decision before migrating (prevents day-one over-share or lockout).

## Test 4 — Target readiness (scope/health)
- **Run:** `.\SPOMIG-ScopeHealth.ps1 -SiteUrl https://contoso.sharepoint.com/sites/PilotProd`
- **PASS:** Target site resolves and is writable by the migration account, storage is sufficient for
  the wave, and the reported prerequisites are green.
- **FAIL:** Site missing/not writable, storage short, or a prerequisite red → resolve before defining
  tasks.

## Test 5 — Task build validates (dry-run)
- **Run:** `.\SPOMIG-TaskBuilder.ps1 -MapCsv .\TargetIAMap-Pilot.csv -BulkCsvOut .\SPMT-Pilot.csv`
  (no `-Commit`).
- **PASS:** A well-formed bulk CSV is produced, every row has a valid source and a resolvable
  destination URL, and the dry-run reports no structural errors. **No migration is started** (safe
  default).
- **FAIL:** Malformed rows, unresolved destinations, or the script attempts to move data without
  `-Commit` → fix the map / do not proceed.

## Test 6 — Pre-stage pass completes
- **Run:** Execute the pilot pre-stage (`-Commit` / start the Migration Manager task) with the source
  **read/write**.
- **PASS:** The tool's per-item report shows all in-scope items migrated (or only expected filtered
  skips); failures are re-run/repaired to zero. Users are still working on the live source.
- **FAIL:** Persistent per-item failures → map to a root cause (see Troubleshooting) and repair before
  cutover.

## Test 7 — Delta cutover is incremental and clean
- **Run:** Set the source **read-only**, run the incremental (delta) pass for the same task.
- **PASS:** The delta pass moves **only changed items** (not a full re-copy) and completes with
  nothing left behind; the tool reports the incremental set.
- **FAIL:** The pass re-copies everything (task identity changed) or reports items it could not carry
  → confirm the same task/mapping is reused and repair.

## Test 8 — Item-count reconciliation (source vs target)
- **Run:** `.\SPOMIG-Validation.ps1 -SourcePath \\fs01\PilotFinance -SiteUrl <site> -Library "Documents" -CsvPath .\v.csv`
- **PASS:** Target **item count ≥ source count** net of intentionally filtered content; the report
  `Post-Migration Validation – Pilot – Validate` shows the reconciliation.
- **FAIL:** Target short of source beyond the known filter set → investigate the missing items before
  passing the gate.

## Test 9 — Permission spot-check matches the map
- **Run:** Use the validation report's permission section (and spot-check in the SPO UI) against
  `Permission Map – Source→SPO – Design` for a sample of libraries/folders.
- **PASS:** Sampled target permissions match the mapped groups and levels — no unexpected broad access,
  no missing access for a mapped group.
- **FAIL:** Over-share (e.g. "Everyone"/broad group where the map said a scoped group) or a mapped
  group missing → remediate permissions before declaring the wave done.

## Test 10 — Target governance applied
- **Run:** Confirm the target site/library has the intended **owner**, **sharing** posture, and any
  **retention intent** label from the design (compliance *determination* deferred to records/legal).
- **PASS:** Owner set, sharing matches design, retention intent applied where required.
- **FAIL:** Orphaned site (no owner), sharing looser than design, or missing retention intent →
  apply before retiring the source.

---

### The wave gate (all must pass to expand / retire the source)
1. **Test 8** — counts reconcile.
2. **Test 9** — permissions match the map.
3. **Test 7** — delta clean, nothing left behind.
4. **Test 10** — target governed.

If any fail, **roll back** (source is still authoritative; lift read-only) and re-run. Do not expand
on a failed pilot, and do not retire a source until its wave gate passes and the soak period ends.
