# GPO Rationalization & Cleanup with Group Policy Analytics

> **Version 1.0.0** · Category: Migrations · Solution code: GPORAT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — GPO Rationalization & Cleanup with Group Policy Analytics

Years of Group Policy leave a thicket: nested and redundant policies, duplicate audit settings, and
intent that nobody fully understands. Migrating that estate to Intune as-is just moves the chaos into
a new console. This solution is the foundational cleanup that comes *before* the migration — inventory
every GPO, use Intune Group Policy analytics to score migration readiness, de-duplicate and resolve
conflicts, retire what is dead, document intent, and produce a clean, sequenced migration backlog — so
the move to a modern Intune baseline starts from order, not sprawl.

This is a complete, do-it-today package for rationalizing a complex GPO estate, written for an
administrator with no prior rationalization experience. It is the repeatable way: assess first,
classify deliberately, prove it on a pilot scope, then expand.

## What you get
- A plain-language Solution Overview of why you rationalize before migrating, how Group Policy
  analytics scores readiness, and the keep / retire / consolidate / replace workflow.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps: export and inventory all GPOs, import to Group
  Policy analytics, classify each GPO, resolve redundant audit and conflicting policies, document
  intent, and produce a sequenced migration backlog.
- Five PowerShell scripts for GPO export/inventory discovery, rationalization-coverage validation, a
  redundancy/conflict and readiness report, safe remediation of dead and duplicate links, and a
  migration-backlog/scope-group builder.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
A rationalized GPO estate with the dead and duplicate policies gone, conflicts and redundant audit
settings resolved, intent captured in a register, and a documented, sequenced migration backlog —
proven on a pilot scope before you scale.

## The deployment model
Assess to Configure to Pilot to Validate to Expand.

## Outcome
The Intune migration is built on solid ground: a clean inventory, an analytics-scored readiness
picture, and a backlog that tells you exactly what to migrate, in what order, and what to leave behind.


---


# 1. Solution Overview — GPO Rationalization & Cleanup with Group Policy Analytics

## Why rationalize before you migrate
A mature Active Directory estate accumulates Group Policy Objects over many years: GPOs created for
projects that ended, settings duplicated across several policies, audit settings configured three
different ways, conflicting values that resolve by link-order accident, and policies whose original
purpose nobody remembers. Lifting that estate into Intune unchanged simply re-creates the mess in a
modern console — and makes the migration look larger, riskier, and slower than it needs to be.

Rationalization is the foundational cleanup that comes first. You inventory every GPO, decide which
ones deserve to make the trip, eliminate the redundancy and conflicts, capture the intent, and hand
the migration team a clean, ordered backlog. The actual settings migration (translating supported
settings into the Intune settings catalog and imported ADMX) is a separate, later phase — this
solution makes that phase smaller and safer.

## How Group Policy analytics fits
Intune Group Policy analytics is a built-in report that ingests a GPO export and tells you, per GPO,
a migration readiness percentage and a per-setting breakdown of what is supported and mapped to an
MDM equivalent, what is deprecated or not supported in MDM, and what needs review. You do not use it
to migrate yet — you use it as the scoring engine for rationalization: high-readiness GPOs are
cheap to migrate and good early-backlog candidates; low-readiness GPOs flag re-implementation or
retirement work to plan deliberately.

## The rationalization workflow
1. Inventory every GPO and export each one (the export is both the analytics input and your
   retained record).
2. Import the exports into Group Policy analytics and read each GPO's migration readiness percentage
   and supported / not-supported / needs-review breakdown.
3. Classify every GPO into one of four dispositions: keep (migrate as-is), retire (dead or
   superseded — do not migrate), consolidate (merge duplicates/overlaps into one), or replace
   (re-implement via a modern Intune surface).
4. Resolve the cross-cutting problems: redundant audit settings configured in multiple places, and
   directly conflicting policy values.
5. Document the intent of every GPO you keep or consolidate, so the migration team knows what each
   policy is *for*.
6. Produce a sequenced migration backlog — what to migrate, in what order, with the scope groups
   already named — gated by a pilot scope.

## The four dispositions
- Keep — the GPO is still needed, has high readiness, and migrates with little change.
- Retire — the GPO is dead (unlinked, empty, superseded, or for a decommissioned system); it is
  intentionally not migrated and its links are removed after sign-off.
- Consolidate — two or more GPOs overlap or duplicate each other; they merge into one before
  migration so you migrate the intent once, not three times.
- Replace — the GPO contains settings with no direct MDM equivalent (logon scripts, drive maps,
  Group Policy Preferences) and is re-implemented later via a platform script, proactive
  remediation, or an endpoint security profile rather than a settings-catalog copy.

## What you control
- The inventory of every GPO, its links, status, and last-modified date.
- The readiness score and supported/unsupported breakdown for each GPO via Group Policy analytics.
- The disposition (keep / retire / consolidate / replace) recorded for every GPO in a rationalization
  register.
- The resolution of redundant audit settings and conflicting policy values.
- The sequenced migration backlog and the Entra scope groups that will drive the later migration.

## Limitations (be honest with buyers)
- This solution rationalizes and sequences; it does not perform the settings migration itself (that
  is the separate Group Policy to Intune settings migration phase).
- Group Policy analytics scores settings coverage; it does not judge business intent — a human must
  classify keep/retire/consolidate/replace.
- Remediation here is scoped to dead and duplicate GPO links (unlink/remove); it does not edit the
  settings inside a GPO.
- A few settings (preferences, scripts, drive maps) have no MDM equivalent and are flagged for
  re-implementation, not a like-for-like migration.

## The deployment model
> Inventory and export all GPOs to import to Group Policy analytics and read readiness to classify
> and resolve conflicts to document intent and build a sequenced backlog — proven on a pilot scope
> first. The repeatable way: Assess to Configure to Pilot to Validate to Expand.


---


# 2. Requirements Guide — GPO Rationalization & Cleanup with Group Policy Analytics

Verify **every** requirement before you begin. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (the Entra ID tenant, Intune licensing, source
access, inventory, pilot/wave structure, change control) are in `global-requirements-migrations.md`
and are assumed here.

## 2.1 Access to export GPOs
**Description:** Administrative read access to Active Directory Group Policy and a domain-joined admin
workstation that can run the Group Policy Management Console (GPMC).
**Why:** Rationalization begins by inventorying and exporting every GPO; the export is both the Group
Policy analytics input and your retained record.
**Verify:** Open GPMC; you can see the domain's GPOs and right-click to back up/export a GPO.
**Implement-if-missing:** Install RSAT Group Policy Management Tools
(`Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0`) and obtain a
Group Policy read/backup role from the AD owner.

## 2.2 The GroupPolicy PowerShell module
**Description:** The `GroupPolicy` module (`Get-GPO`, `Get-GPOReport`) on the admin workstation.
**Why:** The discovery, validation, and report scripts use it to enumerate and export GPOs
programmatically.
**Verify:** `Get-Module -ListAvailable -Name GroupPolicy` returns the module; run
`GPORAT-Discovery.ps1`.
**Implement-if-missing:** Install RSAT Group Policy Management Tools as in 2.1.

## 2.3 Intune with Group Policy analytics
**Description:** Microsoft Intune access with the Group Policy analytics report available.
**Why:** Group Policy analytics is the scoring engine — it produces each GPO's migration readiness
percentage and supported/not-supported/needs-review breakdown.
**Verify:** Sign in to `https://intune.microsoft.com` and open **Reports > Group Policy analytics**;
the **Import** action is present.
**Implement-if-missing:** Confirm Intune licensing and the Intune Administrator role per
`global-requirements-migrations.md` (G2).

## 2.4 Microsoft Graph access (for scope groups and analytics reporting)
**Description:** The `Microsoft.Graph` PowerShell module and consent for `Group.ReadWrite.All` and
`DeviceManagementConfiguration.Read.All`.
**Why:** The report and backlog scripts read Intune Group Policy migration reports and build the Entra
scope groups via Graph.
**Verify:** `Connect-MgGraph` succeeds with the scopes above; run `GPORAT-Report.ps1 -UseGraph`.
**Implement-if-missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; have an admin grant
consent for the listed scopes.

## 2.5 A rationalization owner
**Description:** A named person (or small group) accountable for the keep/retire/consolidate/replace
decisions and for signing off retirements.
**Why:** Group Policy analytics scores coverage but cannot judge business intent; retiring a GPO is a
decision that needs an owner.
**Verify:** A named owner is recorded in the rationalization register.
**Implement-if-missing:** Assign the owner before classifying; route retirements through change
control per `global-requirements-migrations.md` (G7).

## 2.6 A change window and rollback for link changes
**Description:** A change window for unlinking/removing dead and duplicate GPOs, and the retained GPO
exports as the rollback source.
**Why:** Unlinking a GPO changes what applies to live devices; it must be reversible.
**Verify:** A change window is approved and the export folder from `GPORAT-Discovery.ps1` is retained.
**Implement-if-missing:** Schedule the window; keep the export folder as the backup before any
remediation.

---
## Checklist
- [ ] Access to export GPOs (GPMC + Group Policy read/backup role)
- [ ] GroupPolicy PowerShell module present — `GPORAT-Discovery.ps1`
- [ ] Intune with Group Policy analytics (Reports > Group Policy analytics > Import)
- [ ] Microsoft Graph access — `Group.ReadWrite.All`, `DeviceManagementConfiguration.Read.All`
- [ ] A named rationalization owner
- [ ] Change window + retained GPO export as rollback
- [ ] Pilot scope group planned (per global requirements)


---


# Global Requirements — Migrations (category-level)

These requirements apply to **every** solution in the **Migrations** category (platform-to-platform
migration programs — e.g. Workspace ONE → Microsoft Intune, Configuration Manager → Intune, Group
Policy → Intune, Exchange/Microsoft 365 tenant moves). They are published once at the category level
so individual listings stay small. Confirm these before running *any* Migrations solution. Each entry:
**Description · Why · Verify · Implement-if-missing.**

## G1. Target Microsoft Entra ID tenant
**Description:** An active, correctly-configured Microsoft Entra ID (Azure AD) tenant — the migration target's identity backbone.
**Why:** Every modern endpoint/identity workload binds to Entra ID; users and devices must resolve there before migration.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create/confirm the Microsoft 365 / Azure subscription that provisions the tenant.

## G2. Target platform licensing & admin access (Intune)
**Description:** An Intune-bearing license plan and the admin roles to build/assign policies and apps in the target.
**Why:** You can't rebuild apps, profiles, or enrollment in the target without licensing and rights.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** active; you hold **Intune Administrator**.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1; grant least-privilege admin roles.

## G3. Access to the SOURCE platform
**Description:** Administrative read (and, for cutover, change) access to the platform you are migrating *from* (e.g. Workspace ONE UEM, Configuration Manager, Active Directory, the source tenant).
**Why:** Migration begins by inventorying and exporting the source's apps, profiles, policies, and device assignments.
**Verify:** You can sign in to the source console and export/inventory its configuration for a sample.
**Implement:** Obtain the source admin role / API credentials from the platform owner.

## G4. A current inventory / source of truth
**Description:** An accurate inventory of in-scope devices, users, apps, and policies on the source platform.
**Why:** Wave planning, parity validation, and decommission all depend on knowing exactly what is in scope.
**Verify:** You can produce a device/app/policy export from the source for the migration scope.
**Implement:** Build the inventory from the source console / discovery before scoping waves.

## G5. Enrollment prerequisites for the target
**Description:** The enrollment plumbing for each in-scope platform — e.g. Apple MDM Push (APNs) certificate and Apple Business Manager for iOS/iPadOS/macOS, managed Google Play for Android, automatic enrollment for Windows.
**Why:** Devices cannot move to the target MDM until its enrollment channels are live.
**Verify:** In Intune, the relevant connector/cert/token shows **Active** for each platform in scope.
**Implement:** Configure the APNs certificate, ABM/ADE token, managed Google Play, and Windows automatic enrollment as needed.

## G6. A pilot group and wave structure
**Description:** A Microsoft Entra security group for the pilot, and a planned set of migration waves/rings.
**Why:** Every migration is piloted and ringed before fleet cutover to contain risk.
**Verify:** Entra → **Groups**; the pilot group exists and the wave plan is documented.
**Implement:** Entra → **Groups → New group → Security**; define waves by department/region/device type.

## G7. Change control, coexistence, and a rollback path
**Description:** A change window, a defined coexistence approach (both platforms managed during transition), and a documented rollback (re-enroll to source / revert assignment).
**Why:** Migrations touch live, enrolled production devices; cutover must be reversible and coordinated.
**Verify:** A rollback procedure and coexistence plan are written and approved before any cutover.
**Implement:** Define rollback per platform, a comms plan, and the order of operations for coexistence → cutover → decommission.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing Guide — GPO Rationalization & Cleanup with Group Policy Analytics

Run after classification and conflict resolution (Implementation Steps 4 to 7) and again before
expanding from the pilot scope. Reuse the artifact names from the Implementation Guide exactly.

## Test 1 — Every GPO is inventoried
**Do:** Run `GPORAT-Discovery.ps1`; compare the count to GPMC's GPO list.
**Expected:** Every GPO in the domain has an XML export and a row in
`Rationalization Register – All GPOs – Assess`.

## Test 2 — Readiness scored for every GPO
**Do:** Intune > **Reports > Group Policy analytics**; or run `GPORAT-Report.ps1 -UseGraph`.
**Expected:** Each imported GPO shows a migration readiness percentage and a
supported / not-supported / needs-review breakdown, captured in the register.

## Test 3 — Full rationalization coverage
**Do:** Run `GPORAT-Validation.ps1`.
**Expected:** 100% rationalization coverage — every GPO has a disposition (keep / retire /
consolidate / replace); the unclassified list is empty.

## Test 4 — Redundant audit settings resolved
**Do:** Run `GPORAT-Report.ps1` and review `Conflict Resolution Log – Audit & Overlaps – Configure`.
**Expected:** Each audit area has a single authoritative GPO; no duplicated audit settings remain in
the report.

## Test 5 — Conflicts resolved
**Do:** Run `GPORAT-Report.ps1`.
**Expected:** No setting is configured with different values across linked GPOs; every prior conflict
is recorded as resolved in the conflict log.

## Test 6 — Dead/duplicate links removed safely
**Do:** Run `GPORAT-Remediation.ps1` (preview), then with `-Apply` in the change window.
**Expected:** Preview lists exactly the retire/consolidate-away GPOs from the register; after apply,
those GPOs are unlinked (present, not deleted) and the retained exports remain as rollback.

## Test 7 — Sequenced backlog produced
**Do:** Run `GPORAT-Set-MigrationBacklogTargeting.ps1`.
**Expected:** `Migration Backlog – Sequenced – Configure` lists keep/consolidate GPOs ordered by
readiness, replace items tagged with a re-implementation surface, retire items excluded; and both
`Rationalization Scope – Devices – Pilot` and `Rationalization Scope – Devices – Broad` exist.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot-scope pass** | Tests 1 to 6 pass for `Rationalization Scope – Devices – Pilot`; the backlog (Test 7) is produced and reviewed by the rationalization owner |
| **Expand pass** | Tests 1 to 7 pass across the full estate before the settings-migration phase begins |


---


# 6. Troubleshooting Guide — GPO Rationalization & Cleanup with Group Policy Analytics

Use `GPORAT-Discovery.ps1` / `GPORAT-Validation.ps1` for inventory and coverage state,
`GPORAT-Report.ps1` for redundancy/conflict/readiness, and `GPORAT-Remediation.ps1` for safe link
cleanup.

## A. GPO export / inventory problems
| Symptom | Cause | Remediation |
|---|---|---|
| `GPORAT-Discovery.ps1` finds no GPOs | GroupPolicy module missing or no AD read access | Install RSAT Group Policy Management Tools; confirm a Group Policy read/backup role |
| Some GPO exports fail | Permissions on individual GPOs, or special characters in names | Re-run elevated; the script sanitizes names and reports each failed export to retry |
| Inventory count differs from GPMC | Filtered/blocked-inheritance links not counted, or stale RSAT | Refresh GPMC; re-run discovery; reconcile against the GPMC list |

## B. Group Policy analytics import problems
| Symptom | Cause | Remediation |
|---|---|---|
| Import shows no readiness % | Wrong export format uploaded | Upload the GPMC backup/export (the same XML `GPORAT-Discovery.ps1` produces), not a settings report |
| A GPO is missing from analytics | It was not included in the import set | Re-import that GPO into `GPO Analytics Import – All GPOs – Assess` |
| Readiness is 0% / very low | The GPO is mostly preferences/scripts with no MDM equivalent | Expected — classify it **Replace** and tag its re-implementation surface in the register |

## C. Classification / coverage gaps
- `GPORAT-Validation.ps1` reports unclassified GPOs → open the register and assign every listed GPO a
  keep / retire / consolidate / replace disposition; coverage must reach 100% before the pilot gate.
- Unsure whether a GPO is dead → check its links and last-modified date in the inventory; an unlinked,
  long-unmodified GPO for a decommissioned system is a retire candidate (route through the owner).

## D. Redundant audit / conflicting policies
| Symptom | Cause | Remediation |
|---|---|---|
| Same audit area set in several GPOs | Audit policy duplicated over the years | Pick one authoritative GPO per area; clear the duplicates; log each in `Conflict Resolution Log – Audit & Overlaps – Configure` |
| A setting has different values across GPOs | Link-order accident, never reconciled | Decide the intended value, set it on the surviving GPO, remove it from the others, and record the resolution |

## E. Remediation (unlink/remove) problems
- `GPORAT-Remediation.ps1` made no changes → it runs in -WhatIf by default; re-run with `-Apply`
  inside the approved change window.
- Removed too much / need to roll back → retired GPOs are left present-but-unlinked, not deleted;
  re-link from GPMC, or restore from the retained `GPORAT-Discovery.ps1` export folder.

## F. Graph / scope-group problems
- `Connect-MgGraph` fails or returns no reports → confirm `Microsoft.Graph` is installed and consent
  exists for `Group.ReadWrite.All` and `DeviceManagementConfiguration.Read.All`; sign in as an admin.
- Scope group already exists → `GPORAT-Set-MigrationBacklogTargeting.ps1` reuses an existing group of
  the same name (it is idempotent), it does not duplicate.

## G. When to escalate
If exports succeed, analytics imports cleanly, coverage is 100%, and the report still shows conflicts
you cannot reconcile, capture `GPORAT-Report.ps1` output and the register, and review with the
rationalization owner before committing any link removal.


---


# 7. Best Practices — GPO Rationalization & Cleanup with Group Policy Analytics

- **Rationalize before you migrate, always.** Cleaning the estate first is the single most valuable
  step — it shrinks the migration, removes the conflicts, and means you migrate intent once instead of
  duplicating the mess in a new console.
- **Let analytics score, let a human decide.** Group Policy analytics gives you the readiness
  percentage and supported/unsupported breakdown; the keep / retire / consolidate / replace call is a
  business decision a named owner makes — never auto-retire on a score alone.
- **Retire by unlinking, not deleting.** Leave retired GPOs present-but-unlinked until the migration is
  complete; with the retained exports that is a clean, instant rollback.
- **Keep the export folder as your rollback source.** The `GPORAT-Discovery.ps1` export is both the
  analytics input and the backup — retain it for the whole program.
- **One authority per audit area.** Duplicated audit settings are the most common redundancy; pick one
  authoritative GPO per area and clear the rest, recording each in the conflict log.
- **Resolve conflicts by intent, not by link order.** Where values differ across GPOs, decide the
  value you *mean* and set it once — do not preserve a winner that only won by accident of link order.
- **Document intent for everything you keep.** A one-line "what this is for" per surviving GPO is the
  hand-off the settings-migration phase depends on.
- **Sequence by readiness.** Put high-readiness GPOs first in the backlog for early, low-risk wins;
  schedule low-readiness and replace items deliberately.
- **Name every artifact consistently.** Use `<Purpose> – <Scope> – <Stage>` for every register, log,
  backlog, import set, and scope group, and reuse the names verbatim so the migration team can follow.
- **Prove it on a pilot scope first.** Validate the register, conflict log, and backlog against the
  pilot scope group before expanding to the broad fleet.


---


# 8. Deliverables Summary — GPO Rationalization & Cleanup with Group Policy Analytics

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | Why rationalize first, how Group Policy analytics scores readiness, the keep/retire/consolidate/replace workflow |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: export and inventory, analytics import, classify, resolve conflicts/redundant audit, document intent, sequenced backlog |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GPORAT-Discovery.ps1` | Exports every GPO to XML (`Get-GPO` / `Get-GPOReport`) and produces the inventory that seeds the rationalization register (read-only) |
| `GPORAT-Validation.ps1` | Reports rationalization coverage — confirms every GPO has a keep/retire/consolidate/replace disposition (read-only) |
| `GPORAT-Report.ps1` | Redundancy/conflict + readiness report: duplicated audit settings, conflicting values, and Group Policy analytics readiness via Graph (read-only) |
| `GPORAT-Remediation.ps1` | Safely unlinks/removes the dead and duplicate GPOs marked in the register (-WhatIf by default; -Apply to change) |
| `GPORAT-Set-MigrationBacklogTargeting.ps1` | Builds the sequenced migration backlog and the Entra pilot/broad scope groups |

## Named artifacts (reuse verbatim)
- `GPO Analytics Import – All GPOs – Assess`
- `Rationalization Register – All GPOs – Assess`
- `Conflict Resolution Log – Audit & Overlaps – Configure`
- `Migration Backlog – Sequenced – Configure`
- `Rationalization Scope – Devices – Pilot`
- `Rationalization Scope – Devices – Broad`

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand.

## Outcome
A clean, rationalized GPO estate with a documented, sequenced migration backlog — the dead and
duplicate policies gone, conflicts and redundant audit resolved, and intent captured — so the Intune
migration is built on solid ground, proven on a pilot scope before you scale.
