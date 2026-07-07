# 3. Implementation — File-Share & On-Prem SharePoint → SharePoint Online Migration

Follow these steps in order. The migration is structured **Assess → Design → Configure → Pilot →
Validate → Expand**. Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused verbatim in
later steps, testing, troubleshooting, and the scripts. **The source stays authoritative until each
wave's validation gate passes** — that is the rollback.

> **Safety posture.** Assessment and validation are **read-only**. The remediation and the migration
> execution change data — those steps default to **report / dry-run** and require an explicit
> `-Commit` (or the equivalent approval) before anything is written or moved. Never run a broad wave
> before the pilot's validation gate passes.

---

## Phase A — Assess the source

### A1. Inventory the migration sources
1. List every in-scope **file share** (by UNC path) and every in-scope **on-prem SharePoint** site
   collection / library. Record the owner and rough size of each.
2. Confirm source read + ACL-read access from the migration workstation (Requirements §1).

### A2. Run the source assessment (read-only)
1. Run **`SPOMIG-Assessment.ps1`** against each source, passing the **current SPO limits** you
   confirmed (Requirements §5) so the check tracks Microsoft's real numbers:
   ```
   .\SPOMIG-Assessment.ps1 -Path \\fs01\Finance -MaxUrlLength 400 -MaxFileSizeGB 250 -CsvPath .\SourceAssessment.csv
   ```
2. The script flags, per item: **path/URL length** near the limit, **invalid characters / reserved
   names**, **blocked file types**, **oversized files**, deep nesting, and it summarizes the
   **permission surface** (distinct principals in the ACLs).
3. Save the export as **`Source Assessment – FileShare+SP – Discovery`**.
4. **Gate A (assessment complete):** every source has an assessment export and a blocker count. Do not
   design the target until the true blocker picture is known.

---

## Phase B — Design the target and the remediation

### B1. Build the remediation punch-list
1. From `Source Assessment – FileShare+SP – Discovery`, list each blocker with its fix: shorten path,
   rename invalid item, remove/archive blocked or dead content, split an oversized folder/library.
2. Record it as **`Remediation Plan – Source – PreMigration`**, noting which fixes happen **at source**
   (rename before migrating) vs. **in-flight** (the tool can rename on ingest — confirm the tool's
   behavior in its docs).
3. **Compliance note:** whether legacy content is *retained, archived, or deleted* is a
   **compliance/records/legal determination** — this plan records the technical action, not the
   decision to keep or destroy.

### B2. Design the target IA and destination map
1. Map each source share/library to a target **site → library → folder** and a **hub**, applying the
   naming convention and the intended owners and sharing posture. Do **not** mirror drive letters or
   deep legacy trees — flatten and organize.
2. Record it as **`Target IA Map – SPO – Design`** (source path → destination URL, one row per task).
   This map is the input to the migration task builder.
3. Provision (or confirm) the target sites, including at minimum the pilot target **`SPO Site – Pilot –
   Prod`**.

### B3. Build the permission map
1. Run **`SPOMIG-PermissionMap.ps1`** (read-only) to enumerate source principals and propose a target
   mapping (NTFS/SP group → SPO group / M365 group / Entra security group + permission level):
   ```
   .\SPOMIG-PermissionMap.ps1 -Path \\fs01\Finance -CsvPath .\PermissionMap.csv
   ```
2. Review every row; **resolve unmatched principals** (the script flags them) with a decision, not a
   guess. Prefer mapping to **groups**, not individuals.
3. Save as **`Permission Map – Source→SPO – Design`**.
4. **Gate B (design complete):** remediation plan approved, target IA map complete, permission map has
   **zero unresolved principals**.

---

## Phase C — Configure the migration tool

### C1. Verify tenant + target readiness (read-only)
1. Run **`SPOMIG-ScopeHealth.ps1`** to confirm the target site exists and is writable, storage is
   sufficient, and the migration prerequisites are green:
   ```
   .\SPOMIG-ScopeHealth.ps1 -SiteUrl https://contoso.sharepoint.com/sites/PilotProd
   ```
2. Resolve anything red before defining tasks.

### C2. Register the tool and define tasks from the map
1. **Migration Manager** path: in the SharePoint admin center → **Migration**, confirm the agent is
   **online/healthy**, then create a **bulk migration** and upload the CSV emitted from the map (see
   C3). *The Migration Manager console UI is deferred to Microsoft's docs.*
2. **SPMT / PowerShell** path: run **`SPOMIG-TaskBuilder.ps1`** to turn `Target IA Map – SPO – Design`
   into migration tasks. **By default it builds the bulk CSV and does a dry-run** — it only registers
   and starts a migration when you pass `-Commit`:
   ```
   .\SPOMIG-TaskBuilder.ps1 -MapCsv .\TargetIAMap.csv -BulkCsvOut .\SPMT-Bulk.csv    # dry-run: build + validate CSV
   ```
3. Set the migration **settings** to match the design: **migrate permissions** (per the permission
   map), version history depth, filters (skip blocked/dead content), and whether the tool renames
   invalid items in-flight (confirm the exact settings names/behavior in the tool's current docs).

### C3. Name the tasks
1. Name the pilot task **`Migration Task – Pilot – Wave0`** and each subsequent wave
   **`Migration Task – <Scope> – Wave<N>`** (e.g. `Migration Task – Finance – Wave1`). Reuse these
   names in the tool, the validation, and the cutover plan.

---

## Phase D — Pilot wave (pre-stage → delta → validate)

### D1. Pre-stage the pilot (source stays live)
1. With the source still **read/write**, run the pilot **pre-stage** pass — the full copy — for
   `Migration Task – Pilot – Wave0`:
   - SPMT/PowerShell: `.\SPOMIG-TaskBuilder.ps1 -MapCsv .\TargetIAMap-Pilot.csv -BulkCsvOut .\SPMT-Pilot.csv -Commit`
   - Migration Manager: start the pilot task from the admin center.
2. Let it complete; review the tool's per-item result report for failures and re-run/repair as needed.
   Users keep working on the source — nothing has cut over yet.

### D2. Cutover: freeze, delta, redirect
1. In the agreed window (`Cutover Plan – Pilot – Wave0`): set the pilot source **read-only** (remove
   write on the share / set the on-prem library read-only), announce the freeze.
2. Run the **incremental (delta)** pass — it moves only what changed since pre-stage (both tools
   support incremental re-runs of the same task).
3. Redirect users to the target `SPO Site – Pilot – Prod` (updated shortcuts / links / comms).

### D3. Validate the pilot (read-only) — the gate
1. Run **`SPOMIG-Validation.ps1`** to compare source vs. target and spot-check permissions:
   ```
   .\SPOMIG-Validation.ps1 -SourcePath \\fs01\PilotFinance -SiteUrl https://contoso.sharepoint.com/sites/PilotProd -Library "Documents" -CsvPath .\PilotValidation.csv
   ```
2. Save as **`Post-Migration Validation – Pilot – Validate`**.
3. **Gate D (pilot pass/fail):**
   - **PASS** if: target **item count ≥ source** (net of intentionally filtered content), **permission
     spot-check matches** the permission map, versions/metadata match the chosen settings, and the
     delta report shows **nothing left behind**.
   - **FAIL** if any of the above is off → **roll back** (source is still authoritative and read-only
     can be lifted), fix the mapping/settings/remediation, and re-run. Do not expand on a failed pilot.

---

## Phase E — Expand wave by wave

### E1. Repeat the proven chain per wave
1. For each subsequent scope (e.g. `Migration Task – Finance – Wave1`), reuse the exact pattern:
   assess → remediate → confirm map → pre-stage (source live) → delta cutover (source read-only) →
   validate.
2. Save each wave's evidence as **`Post-Migration Validation – <Scope> – Wave<N>`** and pass its gate
   before retiring that source.

### E2. Retire the source (only after the gate)
1. After a wave's validation **passes** and a defined soak period elapses, decommission the source per
   the org's **retention rules** — the *decision* to delete or archive is the compliance/records
   function's, executed here as the technical step.
2. Update the migration tracker: waves complete, sources retired, validation evidence filed.

---

## Rollback (every wave)
Because pre-stage runs while the source is live and the source is only ever set **read-only** at
cutover (never deleted at cutover), rollback is: **lift read-only on the source, redirect users back,
and re-plan.** The source remains the authoritative copy until that wave's validation gate passes and
the soak period ends. No source is destroyed on the strength of an unvalidated migration.
