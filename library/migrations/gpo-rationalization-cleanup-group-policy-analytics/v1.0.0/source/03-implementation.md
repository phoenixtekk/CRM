# 3. Implementation Guide — GPO Rationalization & Cleanup with Group Policy Analytics

Follow these steps **in order**. GPO export is done in the **Group Policy Management Console (GPMC)**
on a domain-joined admin workstation; the analytics and scope-group work is in the **Microsoft Intune
admin center** (`https://intune.microsoft.com`) and **Microsoft Entra** (`https://entra.microsoft.com`).
Reuse every artifact name **exactly** as written — each is named `<Purpose> – <Scope> – <Stage>`.

> **Model:** Inventory and score first, classify deliberately, resolve the conflicts, capture intent,
> then build the sequenced backlog and prove it on a pilot scope before you expand. The repeatable
> way: Assess to Configure to Pilot to Validate to Expand.

## Artifacts you will create (reuse these names verbatim)
| Artifact | Name |
|---|---|
| Analytics import set | `GPO Analytics Import – All GPOs – Assess` |
| Rationalization register | `Rationalization Register – All GPOs – Assess` |
| Conflict/redundancy log | `Conflict Resolution Log – Audit & Overlaps – Configure` |
| Migration backlog | `Migration Backlog – Sequenced – Configure` |
| Pilot scope group | `Rationalization Scope – Devices – Pilot` |
| Broad scope group | `Rationalization Scope – Devices – Broad` |

## Step 1 — Export and inventory every GPO (Assess)
1. Open **GPMC** on a domain-joined admin workstation.
2. Right-click the **domain > Back Up All** (or right-click a single GPO > **Back Up**), choose a
   folder, and complete the wizard — this writes the GPO backup/export that Group Policy analytics
   needs.
3. Alternatively, run `GPORAT-Discovery.ps1`, which uses the GroupPolicy module (`Get-GPO` and
   `Get-GPOReport`) to export every GPO to XML and produce an inventory (display name, GUID, status,
   links, created/modified). Retain this export folder — it is both the analytics input and your
   rollback source.
4. Record the inventory as `Rationalization Register – All GPOs – Assess` (one row per GPO; the script
   seeds the CSV).

## Step 2 — Import the GPOs into Group Policy analytics (Assess)
1. Intune > **Reports > Group Policy analytics > Import**.
2. Upload the GPO backup/export from Step 1. Repeat per GPO if you exported individually. Treat this
   import set as `GPO Analytics Import – All GPOs – Assess`.
3. Wait for the import to finish processing; the report lists every imported GPO with its readiness
   value.

## Step 3 — Read the migration readiness percentage (Assess)
1. In **Group Policy analytics**, read the **migration readiness percentage** for each imported GPO.
2. Open a GPO to see the per-setting breakdown: **Supported** (mapped to an MDM equivalent),
   **Not supported / deprecated**, and **Needs review**.
3. Write each GPO's readiness percentage and supported/not-supported counts into
   `Rationalization Register – All GPOs – Assess`. Run `GPORAT-Report.ps1 -UseGraph` to pull the
   Group Policy migration reports (`groupPolicyMigrationReports`) and the readiness figures
   programmatically into the register.

## Step 4 — Classify every GPO: keep / retire / consolidate / replace (Configure)
For each GPO, record one disposition in `Rationalization Register – All GPOs – Assess`:
1. **Keep** — needed, high readiness, migrates with little change.
2. **Retire** — dead or superseded (unlinked, empty, for a decommissioned system); do not migrate.
   Mark it for the change window in Step 7.
3. **Consolidate** — overlaps or duplicates another GPO; choose the surviving GPO and note which GPOs
   merge into it.
4. **Replace** — contains settings with no MDM equivalent (logon scripts, drive maps, Group Policy
   Preferences); flag for later re-implementation via a platform script, proactive remediation, or an
   endpoint security profile — not a settings-catalog copy.

Run `GPORAT-Validation.ps1` to confirm **every** GPO in the inventory has a disposition (it reports
the rationalization-coverage percentage and lists any unclassified GPOs).

## Step 5 — Resolve redundant audit settings (Configure)
1. From the per-setting breakdowns, find audit-policy settings configured in more than one GPO
   (advanced audit policy and the legacy audit settings are a classic source of duplication).
2. Choose a single authoritative GPO to own each audit area; clear the duplicate audit settings from
   the others.
3. Record each decision in `Conflict Resolution Log – Audit & Overlaps – Configure` (the setting, the
   GPOs it appeared in, the surviving owner). `GPORAT-Report.ps1` lists the duplicated audit settings
   across the exports to seed this log.

## Step 6 — Resolve conflicting policies (Configure)
1. From the report, find settings configured with **different values** across linked GPOs (the value
   that currently wins is a link-order accident).
2. Decide the intended single value, set it on the surviving GPO, and remove the conflicting value
   from the others.
3. Record each resolution in `Conflict Resolution Log – Audit & Overlaps – Configure`.

## Step 7 — Remove the dead and duplicate links (Configure)
1. For every GPO marked **Retire** or merged-away under **Consolidate** in the register, plan the
   link change inside the approved change window.
2. Run `GPORAT-Remediation.ps1` to preview the unlink/remove actions — it runs in **-WhatIf** mode by
   **default** and changes nothing until you pass **-Apply**. It reads the register and acts only on
   GPOs explicitly marked retire/consolidate-away.
3. With sign-off, re-run with **-Apply** during the window. Leave retired GPOs present-but-unlinked
   (do not delete) until the migration is complete, so the retained exports plus the unlinked GPOs are
   a full rollback path.

## Step 8 — Document intent for everything you keep (Configure)
1. For every **Keep** and every surviving **Consolidate** GPO, write a one-line intent statement in
   `Rationalization Register – All GPOs – Assess` (what the policy is *for*, who owns it, why it
   stays).
2. This is the hand-off the later settings-migration phase reads — it turns "migrate this GPO" into
   "migrate this intent."

## Step 9 — Build the sequenced migration backlog and scope groups (Configure)
1. Entra > **Groups > New group > Security** > name `Rationalization Scope – Devices – Pilot` (a few
   representative devices). **Create**.
2. Create `Rationalization Scope – Devices – Broad` (the rest of the in-scope fleet). **Create**.
   Or run `GPORAT-Set-MigrationBacklogTargeting.ps1` to build both groups idempotently and seed the
   pilot.
3. Run `GPORAT-Set-MigrationBacklogTargeting.ps1` to emit `Migration Backlog – Sequenced – Configure`
   from the register: a CSV that orders the **Keep**/**Consolidate** GPOs by readiness (high readiness
   first), tags **Replace** items with their re-implementation surface, and lists **Retire** items as
   excluded. This backlog is the input the later settings-migration phase consumes.

## Step 10 — Prove it on the pilot scope, then expand (Pilot / Validate / Expand)
1. Validate the backlog against `Rationalization Scope – Devices – Pilot`: run `GPORAT-Validation.ps1`
   (100% rationalization coverage — every GPO classified) and `GPORAT-Report.ps1` (no unresolved
   conflicts or redundant audit settings remain). Complete the **Testing Guide**; do not expand until
   the pilot-scope gate passes.
2. Only after the pilot gate passes, extend the same register, conflict log, and backlog to
   `Rationalization Scope – Devices – Broad` and re-run `GPORAT-Report.ps1` / `GPORAT-Validation.ps1`
   across the full estate.

---
### Order of operations
`Export + inventory all GPOs -> import to Group Policy analytics -> read readiness % -> classify
keep/retire/consolidate/replace -> resolve redundant audit -> resolve conflicts -> remove dead/dup
links -> document intent -> sequenced backlog + scope groups -> validate on pilot scope -> expand`
