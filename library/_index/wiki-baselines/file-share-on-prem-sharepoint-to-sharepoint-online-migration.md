# File-Share & On-Prem SharePoint → SharePoint Online Migration

> **Version 1.0.0** · Category: SharePoint · Solution code: SPOMIG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — File-Share & On-Prem SharePoint → SharePoint Online Migration

**Outcome.** Legacy file servers and on-premises SharePoint content are moved into SharePoint Online
**cleanly** — assessed and remediated, mapped to a governed target information architecture, migrated
with permissions intact, and validated with evidence — so content lands **organized and governed**,
not as a cloud copy of the old mess. The result is retired file servers and on-prem farms, lower
infrastructure cost and risk, and content that people can actually find and that the business can
actually govern.

**The problem it solves.** The tempting shortcut — drag everything up with a copy tool — recreates
every legacy problem in a platform where they cost more and are harder to fix: broken permissions,
folders nested past the platform's limits, filenames SharePoint rejects, oversized files that fail
mid-copy, and no owner for anything. Migrations that skip assessment discover these failures at scale,
on cutover night, and slip by weeks.

**The approach.** A repeatable, **pilot-first** method using only supported Microsoft tooling
(**Migration Manager** and the **SharePoint Migration Tool / SPMT**) and PowerShell:

1. **Assess** the source for the blockers that fail SPO migrations (path/URL length, invalid
   characters, blocked types, oversized files, permission surface).
2. **Design** a governed target IA and a permission map (source principals → SPO/M365/Entra groups),
   resolving every principal rather than guessing.
3. **Configure** the migration tool from the map (bulk tasks, migrate-permissions settings).
4. **Pilot** one representative scope end-to-end using **pre-stage + delta** — the bulk copy runs
   while users keep working, and only the changes move during a short read-only cutover window.
5. **Validate** with counts, a permission spot-check, and a delta-clean check — an explicit pass/fail
   gate — then **Expand** wave by wave, retiring each source only after its gate passes.

**Why it's low-risk.** The source stays **authoritative and read-only** — never destroyed — until each
wave's validation gate passes, so rollback is simply lifting the freeze and redirecting users back.
Assessment, permission-mapping, and validation are **read-only**; the only data-moving step is gated
behind an explicit `-Commit`. Pre-stage + delta shrinks the downtime window from days to hours.
Compliance and legal determinations (retention, legal hold, records schedules) remain with the
organization's compliance function — this solution provides the technical method and the evidence, not
the determination.

**What's included.** Solution overview, requirements guide, step-by-step implementation, testing/
validation procedures, troubleshooting, best practices, and **five PowerShell tools** — source
assessment, permission mapping, task builder + runner (safe-by-default), post-migration validation,
and a scope/health helper — all read-only or dry-run by default, with no credentials in code.

**Bottom line.** Legacy content moved to SharePoint Online the right way — assessed and remediated,
mapped to a governed target IA, migrated with permissions and validated — organized, not a cloud
repeat of the mess.


---


# 1. Solution Overview — File-Share & On-Prem SharePoint → SharePoint Online Migration

## What this solution is
Legacy file servers and on-premises SharePoint Server farms are expensive to run, hard to secure,
and increasingly a liability — but the naive fix (copy everything up with a drag-and-drop tool)
simply recreates the mess in the cloud: broken permissions, orphaned folders nested twenty levels
deep, filenames the platform rejects, and no owner for anything. This solution is a **repeatable,
pilot-first method to migrate file shares and on-prem SharePoint content into SharePoint Online
(SPO) and OneDrive cleanly** — assess and remediate the source, map it to a governed target
information architecture (IA), execute with Microsoft's supported migration tooling (**Migration
Manager** and the **SharePoint Migration Tool / SPMT**) using a pre-stage + delta pattern, map
permissions, and validate that content and access actually landed.

It uses only supported Microsoft tooling and PowerShell (SharePoint Online Management Shell, **PnP
PowerShell**, the **SPMT PowerShell** module, and Microsoft Graph). The migration-tool *console
internals* (the Migration Manager agent UI, the SPMT desktop wizard screens) are deferred to
Microsoft's product documentation — this solution gives you the **procedure, sequencing, and
automation** around them, which is where migrations actually succeed or fail.

> **Scope boundary.** This is an **on-prem / file-share → SharePoint Online** migration. It is
> distinct from any **SPO → other-platform** migration (e.g. SPO → Google Drive), which moves in the
> opposite direction with different tooling. Source here = Windows/NAS file shares (SMB/UNC) and
> **on-premises SharePoint Server** (2013/2016/2019/Subscription Edition) document libraries. Target
> = SharePoint Online team/communication sites and OneDrive for Business.

## Why this matters
- **A bad migration is worse than no migration.** Lift-and-shift with no remediation carries every
  legacy problem — nested-permission sprawl, dead content, unresolvable names — into a platform where
  they are harder to fix and now cost you per-GB.
- **The platform will silently reject content you didn't remediate.** Path/URL length over the SPO
  limit, blocked file types, invalid characters, and oversized files fail *during* the migration —
  discovering that on cutover night, at scale, is how migrations slip weeks.
- **Permissions are the hardest part and the part tools do worst.** NTFS ACLs and on-prem SharePoint
  groups do not map one-to-one to SPO/M365 groups. Getting this wrong either over-shares (a
  compliance incident) or locks people out (a flood of tickets) on day one.
- **Without a target IA, you pave the cow paths.** Deciding *where* content lands — which site, which
  library, which hub — before you move it is what turns a migration into a cleanup.
- **Delta migration is what makes cutover safe.** Pre-staging the bulk while the source stays live,
  then moving only the changes at cutover, shrinks the freeze window from days to hours.

## How it works
1. **Assess the source.** Scan file shares (and inventory on-prem SharePoint libraries) for the things
   that break SPO migrations: **path/URL length** approaching the limit, **invalid characters** and
   reserved names, **blocked file types**, **oversized files**, very large libraries/folders, and the
   **permission model** (NTFS ACLs, share permissions, on-prem SP groups). The output is a factual
   inventory and a remediation punch-list.
2. **Remediate the source (or plan around it).** Fix or flag each blocker: shorten paths, rename
   invalid items, remove or archive blocked/dead content, split oversized structures. Remediation is
   staged and reversible; nothing is changed in production without a report and an approval.
3. **Design the target IA.** Map each source share/library to a target **site → library → folder**
   and to a hub, applying a naming convention and a governance model (owners, sharing, retention
   intent — with the compliance *determination* deferred to the records/legal function). This is a
   *mapping*, not a copy of the source tree.
4. **Map permissions.** Translate each source principal (NTFS group, on-prem SP group, individual
   ACE) to a target **SPO group / M365 group / Entra security group** and a permission level. Where a
   clean mapping doesn't exist, it is flagged for a decision rather than guessed.
5. **Configure the migration tool.** Choose **Migration Manager** (agent-based, best for many file
   shares and on-prem SP at scale, tasks defined in the SharePoint admin center) or **SPMT** (desktop
   / PowerShell, best for smaller or scripted runs); register the target, define tasks from the
   mapping (bulk CSV/JSON), and set the settings (permissions, versions, filters).
6. **Pre-stage, then delta.** Run a full **pre-stage** pass while the source stays read/write, then —
   at the agreed cutover window — set the source read-only and run an **incremental (delta)** pass
   that moves only what changed. This is the pattern both Microsoft tools support for a low-downtime
   cutover.
7. **Validate.** Compare source vs. target **item counts**, spot-check **permissions**, confirm
   metadata/versions per the settings chosen, and confirm the delta is clean (nothing left behind).
   Only then is the source decommissioned per the org's retention rules.

## Reference design (what "good" looks like)
- A **pilot wave** (one representative share or on-prem site collection) proves the whole
  assess → remediate → map → migrate → validate chain end-to-end before any broad wave.
- Bulk migration runs from a **migration workstation/agent** with line-of-sight to the source (SMB /
  on-prem SP) and to SPO, using **Migration Manager agents** (scaled out for throughput) or **SPMT**.
- Content lands in a **governed target IA** — communication/team sites under hubs, with owners,
  sharing settings, and retention intent applied — not a mirror of the old drive letters.
- Every wave uses **pre-stage + delta** so the business keeps working on the source until a short,
  scheduled cutover.
- A **validation gate** (counts + permissions + delta-clean) must pass before a wave is called done
  and the source is retired.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, the SharePoint admin center, and the migration tool. The standard set:

| Artifact | Name |
|---|---|
| Source assessment export | `Source Assessment – FileShare+SP – Discovery` |
| Remediation punch-list | `Remediation Plan – Source – PreMigration` |
| Target IA / destination map | `Target IA Map – SPO – Design` |
| Permission mapping table | `Permission Map – Source→SPO – Design` |
| Pilot migration task | `Migration Task – Pilot – Wave0` |
| First broad wave task | `Migration Task – Finance – Wave1` |
| Cutover runbook (per wave) | `Cutover Plan – <Scope> – <WaveN>` |
| Post-migration validation report | `Post-Migration Validation – <Scope> – Validate` |
| Target site (pilot) | `SPO Site – Pilot – Prod` |

## Benefits
- **Content lands organized and governed**, not a cloud copy of the legacy mess.
- **No cutover-night surprises** — blockers are found and fixed in assessment, not discovered at scale.
- **Permissions arrive intact and intentional**, mapped to modern SPO/M365 groups.
- **Low-downtime cutover** via pre-stage + delta.
- **Evidence of success** — counts and permission validation prove the migration, per wave.

## Limitations (be honest with buyers)
- **Migration-tool console internals are deferred to Microsoft docs.** This solution gives the method,
  sequencing, task definitions, and PowerShell — not a screen-by-screen tour of the Migration Manager
  or SPMT UI, which Microsoft documents and changes.
- **SPO service limits are Microsoft's, not ours, and change.** Path/URL length, file-size, blocked
  file types, and list-view limits are enforced by the service; the exact current values must be
  **verified against Microsoft's documentation for your tenant/cloud** (see Requirements/Testing).
- **Government and sovereign clouds differ.** GCC High / DoD (`*.sharepoint.us` / `*.office365.us`)
  and other sovereign clouds can differ in tool support, endpoints, and limits — **verify in your
  tenant**; do not assume Commercial behavior.
- **Not every source is tool-supported.** Encrypted, in-use, or exotic sources (e.g. some NAS
  permission models, IRM/RMS-protected files, third-party ECM) may need vendor tooling or manual
  handling; those are integrated at the pattern level and deferred to the vendor's docs.
- **Compliance/legal determinations are out of scope.** What to retain, what is under legal hold, and
  which records schedule applies are **decided by the org's compliance/records/legal functions** —
  this solution provides the technical method and evidence, not the determination.

## The standard deployment model
> Assess and remediate the source → design the target IA and permission map → configure the tool →
> run a **pilot** wave (pre-stage + delta) and validate → expand wave by wave, retiring each source
> only after its validation gate passes.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates
> and a documented rollback (the source stays authoritative until validation passes).


---


# 2. Requirements — File-Share & On-Prem SharePoint → SharePoint Online Migration

These are the **solution-specific** prerequisites for migrating file shares and on-premises
SharePoint Server content into SharePoint Online. They build **on top of** the shared
`global-requirements-sharepoint.md` (M365 tenant with SPO/OneDrive and licensing; least-privilege
SharePoint Administrator access; SPO Management Shell / PnP / Graph toolchain; a defined information
architecture and identity/group source of truth; a pilot scope and change control; and security /
compliance / records stakeholder engagement). **Verify the six shared requirements first**, then the
migration-specific items below. Each item: **Description / Why / Verify / Implement if missing**.

---

## 1. Source access — file shares and/or on-prem SharePoint
- **Description:** Read access to the migration sources: file shares by **UNC path** (SMB) with an
  account that can read the files **and their NTFS ACLs**, and/or on-premises **SharePoint Server**
  (2013/2016/2019/Subscription Edition) with a farm/site-collection account that can read the content
  databases/libraries the migration tool will pull from.
- **Why required:** Assessment, remediation, permission mapping, and the migration tool all read
  directly from the source; without ACL-read rights the permission map is incomplete.
- **How to verify:** From the migration workstation, `Get-ChildItem \\server\share -Recurse` and
  `Get-Acl` succeed; for on-prem SP, confirm the tool's supported version and that the account can
  enumerate the target webs/libraries.
- **How to implement if missing:** Grant a dedicated migration service account read (and ACL-read)
  on the shares and the required least-privilege role on the SharePoint farm; confirm the on-prem SP
  **version is supported** by the chosen tool (verify in Microsoft's Migration Manager / SPMT docs).

## 2. A migration workstation / agent with line-of-sight to source and SPO
- **Description:** A domain-joined Windows machine (or set of machines) that can reach the source over
  SMB / the on-prem SP endpoint **and** reach SharePoint Online over HTTPS (443), meeting the chosen
  tool's requirements — for **Migration Manager**, the **migration agent** installed and registered;
  for **SPMT**, the SharePoint Migration Tool and/or its **`Microsoft.SharePoint.MigrationTool.PowerShell`**
  module.
- **Why required:** The tool moves bytes through this host; throughput, reliability, and the delta
  passes all depend on it. Multiple agents scale throughput for large estates.
- **How to verify:** The agent shows **online/healthy** in the SharePoint admin center (Migration
  Manager), or `Import-Module Microsoft.SharePoint.MigrationTool.PowerShell` loads and
  `Register-SPMTMigration` connects (SPMT).
- **How to implement if missing:** Provision the host(s), install the agent/SPMT per Microsoft's
  current install docs, and allow outbound 443 to the SPO/Microsoft 365 endpoints (verify the current
  endpoint list for your cloud).

## 3. Migration tooling chosen and its version confirmed
- **Description:** A decision on the migration engine — **Migration Manager** (agent-based, tasks
  defined in the SharePoint admin center, strong for many file shares and on-prem SP at scale),
  **SPMT** (desktop/PowerShell, strong for smaller or scripted runs), or an approved **third-party**
  tool — with its current version installed.
- **Why required:** Task definition, CSV/bulk format, supported sources, and the pre-stage/delta
  behavior differ per tool; the provided `SPOMIG-TaskBuilder.ps1` targets the **SPMT PowerShell**
  module and emits a Migration Manager–compatible bulk CSV.
- **How to verify:** The tool launches, signs in to your tenant, and lists its supported source types
  and limits (confirm against Microsoft's docs).
- **How to implement if missing:** Install the current tool; if using a third-party engine, its
  console is deferred to the vendor's docs — this solution still supplies the assessment, mapping,
  and validation around it.

## 4. Target SharePoint Online IA provisioned (or ready to provision)
- **Description:** The **target sites, libraries, and hubs** that content will land in — named per the
  `Target IA Map – SPO – Design` — provisioned or scripted for provisioning, with the intended
  **owners** and **sharing** posture set.
- **Why required:** Migration tasks need a destination URL; migrating into an ungoverned or
  not-yet-created site is how content lands orphaned.
- **How to verify:** The target site URLs resolve and the migration account can write to them
  (`Connect-PnPOnline` + `Get-PnPWeb` succeed on the destination).
- **How to implement if missing:** Provision the target IA first (often the *SharePoint Online
  Architecture & Site Provisioning* solution); at minimum create the pilot target `SPO Site – Pilot –
  Prod` before the pilot wave.

## 5. Sufficient SharePoint Online storage and a checked list of service limits
- **Description:** Enough **tenant + per-site storage** for the migrated content, and a documented
  check of the current SPO **migration-relevant service limits**: URL/path length, file-size limit,
  invalid characters / reserved names, blocked file types, and per-library/list-view thresholds.
- **Why required:** Insufficient storage stalls a wave; unremediated limit violations fail items
  mid-migration. These limits are **Microsoft's and can change** — they must be read from current docs
  or measured, not assumed.
- **How to verify:** In the SharePoint admin center check tenant/site storage; confirm the current
  limit values in Microsoft's SharePoint limits documentation for your cloud (Commercial vs
  Government may differ).
- **How to implement if missing:** Increase storage / adjust quotas; feed the confirmed limit values
  into the assessment (`SPOMIG-Assessment.ps1` accepts them as parameters so the check tracks the
  real, current numbers).

## 6. Identity mapping — source principals resolve to Entra ID / M365 groups
- **Description:** A way to resolve source principals (NTFS local/domain groups, on-prem SP groups,
  individual users) to **Entra ID** users/groups, so permissions can be mapped to **SPO groups / M365
  groups / Entra security groups** in the target.
- **Why required:** Permission mapping is only possible if source identities correspond to cloud
  identities; unmatched principals must be surfaced for a decision, not dropped.
- **How to verify:** Users/groups from the source ACLs exist in Entra ID (spot-check with Graph or
  `Get-PnPAzureADGroup` / `Get-MgUser`); confirm whether **Entra Connect** hybrid sync is in place.
- **How to implement if missing:** Ensure directory sync / identity provisioning is complete for the
  in-scope population before the permission map is finalized; `SPOMIG-PermissionMap.ps1` reports
  unmatched principals so gaps are explicit.

## 7. A cutover window and change control for each wave
- **Description:** An agreed **cutover window** per wave during which the source can be set
  **read-only**, the delta pass runs, and users are redirected — under the change-control process from
  the shared requirements.
- **Why required:** The pre-stage/delta pattern needs a defined moment to freeze the source; migration
  cutover is **high-impact** (users switch to a new location) and needs approval and a rollback.
- **How to verify:** A named change window, an approver, a user-communication plan, and a rollback
  (source stays authoritative until validation passes) are documented in the `Cutover Plan` for the
  wave.
- **How to implement if missing:** Schedule the window, draft the comms, and document the rollback
  before the wave's delta/cutover step.

---

*All six shared SharePoint requirements plus these seven migration-specific items should be green
before the pilot wave. The migration follows the house model — **Assess → Design → Configure → Pilot
→ Validate → Expand** — with the source remaining authoritative until each wave's validation gate
passes. Automation is **PowerShell** with **no hardcoded credentials or secrets**.*


---


# Global Requirements — SharePoint Online & OneDrive Solutions

These requirements apply to **every** solution in the **SharePoint** category (SharePoint Online
architecture & provisioning, external sharing, OneDrive for Business, migration to SPO, permissions,
search, and records/retention). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every SharePoint solution).** The **SharePoint admin center**, the
> **Microsoft 365 admin center**, the **SharePoint Online Management Shell** and **PnP PowerShell**,
> and **Microsoft Graph** are authored at exact, current click-by-click / cmdlet detail from Microsoft's
> public documentation. Where a capability, setting, or portal path is **plan- or version-dependent**
> (storage limits, sharing controls, Syntex/records features, Commercial vs Government cloud), it is
> **cited or flagged "verify in your tenant"** — never invented. **Third-party migration and governance
> tools** (e.g. ShareGate, Migration Manager, AvePoint) are integrated at the pattern level; their
> consoles are deferred to the vendor's docs. Automation is **PowerShell** (SPO Management Shell / PnP /
> Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with SharePoint Online / OneDrive and licensing
- **Description:** A Microsoft 365 tenant with **SharePoint Online** and **OneDrive for Business** and
  the licensing the capability requires (e.g. an E-plan for advanced records/retention, Syntex where used).
- **Why required:** All site, sharing, OneDrive, and records configuration depends on the right plan.
- **How to verify:** In the M365 admin center confirm the SharePoint/OneDrive subscription and add-ons.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Administrative access (least-privilege SharePoint roles)
- **Description:** Access with the least-privilege role the solution names — typically **SharePoint
  Administrator** (and Global Administrator only where genuinely required, e.g. tenant-wide sharing).
- **Why required:** Tenant/site settings, sharing, provisioning, and records changes require the role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. SharePoint Online Management Shell / PnP + Graph toolchain
- **Description:** A workstation with the **SharePoint Online Management Shell** and/or **PnP
  PowerShell** (and Graph PowerShell where used), modern-auth / MFA-capable admin sign-in (PnP app
  registration where required).
- **Why required:** Configuration, automation, and the provided scripts run through SPO/PnP/Graph.
- **How to verify:** `Connect-SPOService` / `Connect-PnPOnline` succeeds; modules installed.
- **How to implement if missing:** Install the modules; register the PnP app where needed; confirm sign-in.

## 4. Information architecture & identity/group source of truth
- **Description:** A defined **information-architecture** intent (hub/site structure, taxonomy) and the
  identity/group source (Entra ID groups, M365 Groups backing team sites) that drives access.
- **Why required:** Provisioning, permissions, search, and governance key off the IA and groups.
- **How to verify:** Confirm the intended hub/site structure and which groups model is authoritative.
- **How to implement if missing:** Define the IA and group model (often the Architecture solution) first.

## 5. A pilot scope and change control
- **Description:** A **pilot site collection / hub / user set** to validate on before tenant-wide
  rollout, and a **change-control** process for production changes (sharing, permissions, retention,
  migration cutover are high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; tenant-wide sharing/permission/retention changes are high-impact.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

## 6. Security, compliance & records stakeholders
- **Description:** Engagement with the **security, compliance/records, and data-governance** stakeholders
  whose policies the configuration must satisfy (external sharing, permissions, retention/records,
  sensitivity).
- **Why required:** Sharing, permission, and records settings must align to enterprise policy.
- **How to verify:** Confirm the applicable policies and named approvers.
- **How to implement if missing:** Identify the owners and capture requirements before configuring governance.

*The deployment model across every SharePoint solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (SPO Management Shell / PnP / Graph) — never with
hardcoded credentials or secrets in code.*


---


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


---


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


---


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


---


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


---


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
