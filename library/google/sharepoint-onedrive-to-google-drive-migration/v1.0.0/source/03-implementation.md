# 3. Implementation Guide — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Follow these steps in order. This guide defines the content and permission mapping, proves it on a
**named pilot**, validates files, permissions, and sharing **per item**, then migrates **by wave** and
validates each wave before the next. Artifact names are fixed — create them with the exact names
shown and reuse them for every wave. The migration engine's internal steps are **tool-agnostic** and
deferred to the vendor's own docs; this guide governs the mapping, translation, and validation.

> Model: define the mapping and confirm access, prove it on a pilot, validate per item, then expand
> wave by wave. The repeatable way: Assess, then Configure, then Pilot, then Validate, then Expand.

## Step 1 — Assess: discover the source content, structure, and permissions
1. Run `GWDRIVE-Discovery.ps1` to inventory the in-scope SharePoint sites/libraries and OneDrives:
   item and folder counts, structure, the **permission principals** on each scope, and the **sharing**
   in place (organization/anyone links). Record it as the discovery baseline.
2. Extract the **distinct set of principals** (users, groups, domains) that hold any permission or
   share across the in-scope content — this is the input to the identity map.
3. Record gaps against the Requirements checklist. Do not proceed past missing source access or a
   target tenant without Shared Drives enabled — resolve those first.

## Step 2 — Configure: define the content, permission, identity, and sharing mapping
1. **Content + structure map** — author `GWDRIVE Mapping - Content & Structure - Source to Target`:
   for each SharePoint site/library decide its target **Shared Drive** (one per library where a site
   has several, to stay within the 500,000-item and 600-member Shared Drive limits and keep clean
   access boundaries), and map each **OneDrive** to the **same user's My Drive**. Preserve folder
   structure beneath each target root.
2. **Permission/role translation table** — author `GWDRIVE Mapping - Permissions - Level to Role`
   against the source tenant's **actual** permission levels: Full Control → **Manager**, manage-content
   levels → **Content manager**, Contribute → **Contributor**, read+comment → **Commenter**, read →
   **Viewer** ([Google — shared drive roles](https://developers.google.com/workspace/drive/api/guides/ref-roles)).
   Have the content owners confirm the mapping preserves their intended access.
3. **Identity map** — author `GWDRIVE Mapping - Identity - Source to Google` covering **every**
   principal from Step 1's set. A principal missing here loses its permission on migration — treat the
   map's completeness as a gate, not a nicety.
4. **Sharing translation rules** — author `GWDRIVE Mapping - Sharing - Link & Grant Rules`: direct
   grants → Google permissions/membership (via the identity map); organization links → domain sharing
   at the matching role; anyone-with-the-link → translated only where policy permits, else down-scoped
   and flagged for owner review. Freeze all four artifacts before the pilot.

## Step 3 — Configure the target and the tool
1. Pre-create (or let the tool create) the target **Shared Drives** named per the content map, and
   confirm each user's **My Drive** exists for OneDrive targets.
2. Load the **identity map**, **permission translation**, and **sharing rules** into the chosen
   migration engine (per the vendor's own docs). Confirm the engine will apply folder-level
   permissions to folders and file-level permissions to files where the source differs — the accurate
   default — reserving root/drive-level grants only where the top-level access should cascade.
3. Prove one test item moves with its permission and sharing correct before running the pilot at
   volume.

## Step 4 — Pilot: migrate Wave 0 and validate per item
1. Confirm the pilot scope `GWDRIVE Pilot - Scope - Wave 0` (a representative site/library plus a small
   OneDrive sample) and build its target group with `GWDRIVE-Set-ScopeTargeting.ps1` (runs with
   `-WhatIf` by default; re-run with `-WhatIf:$false` to apply).
2. Run the migration engine over the pilot scope under change control, applying the four mapping
   artifacts.
3. Run `GWDRIVE-Validation.ps1` to validate the pilot **per item**: every source item has a target
   item (files present), each item's permissions match the translated roles, and sharing resolved per
   the rules — with no dropped principals.
4. Run `GWDRIVE-Report.ps1` for pilot coverage and the exception list.

## Step 5 — Validate the pilot and fix the mapping, not just the item
1. Treat every validation exception as a **mapping** defect: a flattened permission means the
   translation table is wrong; a dropped grant means the identity map is incomplete; a mis-placed
   folder means the content map is wrong. Fix the **artifact**, so later waves inherit the fix.
2. Remediate identity-map / permission gaps with `GWDRIVE-Remediation.ps1` (runs with `-WhatIf` by
   default; add `-WhatIf:$false` to act), then re-run `GWDRIVE-Validation.ps1` until the pilot is
   clean. The pilot passes only when files, permissions, and sharing all validate.

## Step 6 — Build the wave plan
1. Segment the remaining in-scope content into sized waves — a coherent set of sites/libraries and
   OneDrives per wave — so no single wave exceeds the tool's throughput or a Shared Drive's limits.
   Keep each wave a coherent business unit so comms and support are focused.
2. Build each wave's target group with `GWDRIVE-Set-ScopeTargeting.ps1` (preview by default). Assign
   every source scope to exactly one wave; never move a confirmed scope between waves (risks duplicate
   content).

## Step 7 — Expand: migrate by wave and validate each wave
1. For each wave, apply the same runbook `GWDRIVE Runbook - Migrate & Validate - Per Wave`: build the
   wave group, run the engine with the four mapping artifacts, then run `GWDRIVE-Validation.ps1`
   (per-item files/permissions/sharing) and `GWDRIVE-Report.ps1` (coverage + exceptions).
2. A wave passes only when its per-item validation is clean. Remediate exceptions with
   `GWDRIVE-Remediation.ps1` (`-WhatIf` by default) before passing the wave and starting the next.
3. Keep the identity map current as later waves introduce new principals; a stale map drops their
   permissions.

## Step 8 — Close out and cut over
1. When all waves validate, confirm users can access their migrated content at the mapped roles, brief
   them on the greyed-out-folder visibility change, and set the source content to read-only (or
   decommission) per the change plan — never before validation is clean.
2. Retain the discovery baseline, mapping artifacts, and final `GWDRIVE-Report.ps1` coverage as the
   record of what moved and where.

---
### Order of operations
`Assess/discover -> Define mapping (content+permission+identity+sharing) -> Configure target+tool -> Pilot (Wave 0) + per-item validate -> Fix the mapping -> Wave plan -> Expand wave by wave + validate each -> Close out / cut over`
