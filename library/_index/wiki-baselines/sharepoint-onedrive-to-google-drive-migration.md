# SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

> **Version 1.0.0** · Category: Google · Solution code: GWDRIVE

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Moving files off SharePoint Online and OneDrive to Google Drive is not a copy job — it is a **mapping
job**, and permissions and sharing are where it goes wrong. A SharePoint site does not map one-to-one
onto Google Drive: team content dumped into a personal My Drive gets one owner who can lock everyone
out; permission levels flatten so a team that should still edit lands as view-only; sharing links
break or, worse, widen; and any identity that was not mapped has its access **silently dropped**, so
the file arrives with no permissions at all — none of it discovered until a user reports they cannot
open their own work. This solution removes those failure modes.

This is a complete, self-guided package written for a competent migration admin. It supplies the
**mapping model** (which sites/libraries become which Shared Drives, whose OneDrive becomes whose My
Drive), the **permission and sharing translation** (SharePoint levels → Google roles, SharePoint
sharing → Google sharing, via a complete identity map), the **tooling pattern** (tool-agnostic — the
engine is chosen in the design and its internals deferred to the vendor), and the **per-item
validation** that proves each file landed in the right place with the right access. It is executed
**pilot-first** and **rollback-ready**.

## What you get
- A **Solution Overview** of the SPO/OneDrive → Drive/Shared Drives mapping model — sites/libraries →
  Shared Drives, OneDrive → My Drive, the permission level → role translation, and the sharing
  translation rules.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite: source
  SPO/OneDrive access, a Google tenant with Shared Drives and storage, a chosen migration tool, a
  complete identity map, the mapping decisions, and a named pilot.
- An **Implementation Guide** of precise, ordered steps: discover the source, define the content /
  permission / identity / sharing mapping, prove it on a named pilot with per-item validation, fix the
  mapping (not just the item), then migrate wave by wave and validate each wave before the next.
- **Five PowerShell scripts** — source content/permission discovery, per-item migration + permission
  validation, a coverage/exception report, safe remediation, and a wave target-group builder — all
  read-only against Microsoft Graph except the two write scripts, which default to `-WhatIf`.
- **Testing and Troubleshooting** guides with explicit per-item gates (files migrated, permissions
  correct, sharing works), plus Best Practices for shared-drive structure — and a migration playbook
  outline the migration runs from.

The solution keeps the migration engine **tool-agnostic**: it owns the mapping, translation, and
validation, so a change of tool touches the engine, not the method.

## What this delivers
A governed, validated Drive migration: SharePoint Online and OneDrive content on Google Drive / Shared
Drives with **permissions and sharing intact**, mapped deliberately and validated per item, proven on
a pilot before any business unit's content moves.

## The deployment model
Assess, then Configure, then Pilot, then Validate, then Expand — with per-item validation of files,
permissions, and sharing before every wave passes, and source content set read-only only after
validation is clean.

## Outcome
Files and shares land on Google Drive / Shared Drives with the **right access** — team content in
Shared Drives, personal content in My Drive, roles preserved, sharing translated, and nothing silently
dropped or widened — proven on a pilot and validated wave by wave.


---


# 1. Solution Overview — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

## What this solution is
This solution migrates **SharePoint Online (SPO) and OneDrive for Business** content to **Google
Drive and Shared Drives** — with the content, folder structure, **permissions, and sharing**
mapped deliberately rather than dumped file-for-file. The hard part of a Drive migration is never
the bytes; it is that a SharePoint site and a OneDrive do **not** map one-to-one onto Google Drive,
and that permissions and sharing are where these migrations quietly go wrong. This solution supplies
the **mapping model** (what becomes a Shared Drive, what becomes a folder, whose OneDrive becomes
whose My Drive), the **permission/sharing translation** (SharePoint permission levels → Google roles,
SharePoint sharing → Google sharing), the **tooling pattern** (tool-agnostic — the migration engine
is chosen and its internals deferred to the vendor), and the **per-item validation** that proves each
item landed in the right place with the right access. It is executed **pilot-first** and
**rollback-ready**.

## Why this matters
Drive migrations fail on access, not volume. A team's SharePoint site is copied into a personal My
Drive and now has one owner who can lock everyone out. Permission levels are flattened — a
SharePoint "Contribute" that should have become a Google **Contributor** lands as **Viewer**, and the
team can no longer edit. Sharing links break: an "anyone with the link" SharePoint share does not
carry across, or worse, carries across too broadly. Identities are not mapped, so permissions granted
to `jsmith@source` never resolve on the Google side and are silently dropped — the file arrives with
no access at all ([CloudM — Drive permission changes](https://support.cloudm.io/hc/en-us/articles/25031144447644-Google-Drive-Permission-Changes-Microsoft-365-to-Google-Workspace)).
And because nothing was validated per item, none of this is discovered until a user reports they
cannot open their own files — weeks after the tool declared success. This solution fixes the cause:
it decides the content and permission mapping **up front**, proves it on a **named pilot**, validates
files, permissions, and sharing **per item**, and only then migrates the rest **by wave** — each wave
validated before the next.

## The SPO/OneDrive → Drive/Shared Drives mapping model
The migration is driven by an explicit mapping. Author it once, name it, and reuse it for every wave.

| Source (Microsoft 365) | Target (Google) | Rationale |
|---|---|---|
| **SharePoint team site / document library** (team-owned content) | **Shared Drive** | Team content must be team-owned. A Shared Drive has no single personal owner, so access survives when a person leaves — the correct home for site/library content. |
| **SharePoint site with several libraries** | **One Shared Drive per library**, or one Shared Drive with a folder per library | Keeps Shared Drives within item/member limits and gives each library a clean access boundary. |
| **OneDrive for Business** (personal content) | The same user's **My Drive** | Personal content stays personal, owned by the same identity. |
| **SharePoint folder** | **Folder inside the target Shared Drive** | Structure is preserved beneath the Shared Drive root. |
| **SharePoint permission level** | **Google Drive role** (see translation below) | Access intent is preserved, not flattened. |
| **SharePoint / OneDrive share** (direct grant or link) | **Google sharing** (member/permission or link) | Sharing intent is translated deliberately, not lost or over-broadened. |

The named mapping artifacts:

| Artifact | Name |
|---|---|
| Content + structure mapping | `GWDRIVE Mapping - Content & Structure - Source to Target` |
| Permission/role translation table | `GWDRIVE Mapping - Permissions - Level to Role` |
| Identity mapping table | `GWDRIVE Mapping - Identity - Source to Google` |
| Sharing translation rules | `GWDRIVE Mapping - Sharing - Link & Grant Rules` |
| Pilot scope | `GWDRIVE Pilot - Scope - Wave 0` |
| Per-wave migration + validation runbook | `GWDRIVE Runbook - Migrate & Validate - Per Wave` |

## Permission translation — SharePoint level → Google role
Google Shared Drives have five member access levels; the migration maps each source permission level
to the closest Google role so **access intent is preserved** rather than flattened
([Google — shared drive roles](https://developers.google.com/workspace/drive/api/guides/ref-roles)).

| SharePoint permission level (typical) | Google Drive role | What the role grants |
|---|---|---|
| Full Control / site owner | **Manager** (`organizer`) | Manage files, folders, members, and settings; delete; move out of the drive |
| Design / Edit (manage content) | **Content manager** (`fileOrganizer`) | Add, edit, move, and organize content; share items; cannot manage members |
| Contribute | **Contributor** (`writer`) | View, comment, edit, and create files; cannot manage members or settings |
| Read + comment | **Commenter** | View and comment only |
| Read | **Viewer** (`reader`) | View only |

Exact source permission-level names vary per SharePoint tenant; the translation table is authored
against the source tenant's **actual** levels, not assumed defaults, and reviewed with the content
owners before the pilot.

## Sharing translation
SharePoint sharing (direct grants and sharing links) is translated by rule into Google sharing:
- **Direct grants** to named users/groups → Google **permissions** on the item or membership on the
  Shared Drive, via the **identity mapping table** so each source principal resolves to a Google
  identity. **Any principal missing from the identity map is dropped** by the tool and its permission
  is lost — so the identity map must be complete before migrating
  ([CloudM — Drive permission changes](https://support.cloudm.io/hc/en-us/articles/25031144447644-Google-Drive-Permission-Changes-Microsoft-365-to-Google-Workspace)).
- **Organization sharing links** ("people in your organization") → Google **domain** sharing at the
  matching role.
- **Anyone-with-the-link** shares → translated **only where policy allows**; otherwise down-scoped to
  domain or named access and flagged for owner review, so a migration does not silently widen access.
- **Note on visibility:** as of early 2026, folders a user could not see in SharePoint may appear
  **greyed out** (visible but inaccessible) in Google Drive — visibility changed, not access — so
  users are told to expect this and restricted content is best placed in separate top-level folders
  before migrating.

## The deployment model
> Define the content, permission, identity, and sharing mapping and confirm access; prove the whole
> mapping on a **named pilot**; validate files, permissions, and sharing **per item**; then migrate
> **by wave** and validate each wave before the next — the repeatable way: Assess, then Configure,
> then Pilot, then Validate, then Expand.

## What this is not
This solution governs the **mapping, translation, and per-item validation** of an SPO/OneDrive →
Drive migration. It does **not** re-document the internal console steps of any specific migration
engine — the tool is chosen in the design and its mechanics are deferred to the vendor's own docs
(tool-agnostic). Where the included scripts read the source, they read **SharePoint Online and
OneDrive through Microsoft Graph, read-only**; they move no content and change no permissions (the
one write script and the scope-targeting script default to `-WhatIf`).


---


# 2. Requirements Guide — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Verify every requirement before starting the migration. Each entry gives **Description**, **Why**,
**How to verify**, and **How to implement if missing**. Category-wide prerequisites (the Google
Workspace tenant, the source Microsoft 365 / Entra environment, DNS control, the identity source of
truth, a pilot scope, and governance stakeholders) are in `global-requirements-google.md`; this guide
adds what a Drive migration specifically needs.

## 2.1 Source SharePoint Online & OneDrive access
- **Description:** Administrative read access to the source **SharePoint Online** sites/libraries and
  **OneDrive for Business** in scope — through the Microsoft 365 admin roles and the Microsoft Graph
  read scopes the included scripts request (`Sites.Read.All`, `Files.Read.All`, `User.Read.All`,
  `Group.Read.All`).
- **Why required:** Discovery reads the source content, structure, and permissions to build the
  mapping; the migration tool reads the source to move it. Without this, the migration cannot see
  what it is moving.
- **How to verify:** Sign in with the migration admin account and confirm the in-scope sites and
  OneDrives are enumerable; run `GWDRIVE-Discovery.ps1`.
- **How to implement if missing:** Obtain the SharePoint/Global admin roles (or a scoped migration
  account) from the source tenant owner and consent to the read scopes on first script run.

## 2.2 Target Google Workspace tenant & licensing
- **Description:** A provisioned Google Workspace tenant (per the global requirements) with **Shared
  Drives enabled** for the target org units and enough Drive storage/licensing for the content being
  moved.
- **Why required:** Team content lands in Shared Drives and personal content in each user's My Drive;
  both must exist and have storage headroom before content arrives.
- **How to verify:** In the Google Admin console, confirm Shared Drive creation is enabled for the
  target OUs and that pooled/assigned storage covers the discovered source volume.
- **How to implement if missing:** Enable Shared Drives for the target OUs and provision storage /
  licensing (through Google or an authorized reseller) before the pilot.

## 2.3 A migration tool (chosen, tool-agnostic)
- **Description:** A selected third-party Drive migration engine capable of moving SPO/OneDrive
  content to Google Drive/Shared Drives **with permission and sharing mapping and identity mapping**,
  authorized against both tenants.
- **Why required:** This solution supplies the mapping, translation, and validation; the engine does
  the byte movement. Choosing it up front (not per wave) keeps outcomes consistent.
- **How to verify:** The tool is selected, authorized to read the source and write the target, and its
  identity/permission-mapping capability is confirmed in a test move.
- **How to implement if missing:** Select and authorize the engine, connect both tenants, and prove a
  single test item moves with permissions in a lab before the pilot. The engine's internal console
  steps are deferred to the vendor's own documentation.

## 2.4 Identity mapping — source principals → Google identities
- **Description:** A complete **identity mapping table** — `GWDRIVE Mapping - Identity - Source to
  Google` — mapping every source domain, group, and user that holds a permission or share to its
  Google counterpart.
- **Why required:** Permissions and shares are re-applied to the mapped Google identity; **any source
  principal missing from the map has its permission silently dropped**, so the item arrives with lost
  access. Completeness of this table is the single largest determinant of a clean permission result
  ([CloudM — Drive permission changes](https://support.cloudm.io/hc/en-us/articles/25031144447644-Google-Drive-Permission-Changes-Microsoft-365-to-Google-Workspace)).
- **How to verify:** Every principal discovered on in-scope content resolves to a Google identity;
  run `GWDRIVE-Discovery.ps1` to enumerate principals and `GWDRIVE-Validation.ps1` to confirm coverage.
- **How to implement if missing:** Build the map from the discovery output (or your identity/
  provisioning source of truth) and fill every gap before migrating; use `GWDRIVE-Remediation.ps1`
  (`-WhatIf` by default) to help stage additions.

## 2.5 Mapping decisions — content, permissions, sharing
- **Description:** The authored, owner-approved mapping set: the **content/structure** map
  (`GWDRIVE Mapping - Content & Structure - Source to Target` — which sites/libraries become which
  Shared Drives, which OneDrives become which My Drives), the **permission/role translation table**
  (`GWDRIVE Mapping - Permissions - Level to Role`), and the **sharing translation rules**
  (`GWDRIVE Mapping - Sharing - Link & Grant Rules`).
- **Why required:** SPO/OneDrive does not map one-to-one onto Drive; deciding the mapping per wave (or
  letting the tool default it) produces inconsistent structure and flattened permissions. The mapping
  is the design every wave executes.
- **How to verify:** Each in-scope site/library/OneDrive has a named target; each source permission
  level has a Google role; each sharing type has a rule — all reviewed with the content owners.
- **How to implement if missing:** Author the three mapping artifacts in Implementation Step 2 against
  the source tenant's **actual** permission levels and sharing settings, and freeze them before the
  pilot.

## 2.6 A named pilot and change control
- **Description:** A named pilot — `GWDRIVE Pilot - Scope - Wave 0` — of a representative SharePoint
  site (or library) and a small set of OneDrives, with a change-control window for the production
  target changes.
- **Why required:** The pilot proves the whole mapping (content, permissions, identity, sharing) end
  to end at low blast radius before any business unit's content moves; change control protects the
  production Google tenant.
- **How to verify:** A representative pilot scope is named and agreed, and a change window/approval
  path exists (aligns to the global-requirements pilot and change-control items).
- **How to implement if missing:** Choose a representative site + OneDrive sample as Wave 0 and agree
  the change-control process with the content and platform owners before migrating.

---
## Checklist
- [ ] Source SPO/OneDrive read access confirmed — `GWDRIVE-Discovery.ps1`
- [ ] Target Google tenant: Shared Drives enabled + storage/licensing sufficient
- [ ] Migration tool selected, authorized both tenants, permission-mapping proven in a test move
- [ ] Identity map complete — every source principal resolves to Google — `GWDRIVE-Validation.ps1`
- [ ] Content/structure map authored — `GWDRIVE Mapping - Content & Structure - Source to Target`
- [ ] Permission/role translation table authored — `GWDRIVE Mapping - Permissions - Level to Role`
- [ ] Sharing translation rules authored — `GWDRIVE Mapping - Sharing - Link & Grant Rules`
- [ ] Named pilot + change control agreed — `GWDRIVE Pilot - Scope - Wave 0`


---


# Global Requirements — Google Workspace & Gemini Solutions

These requirements apply to **every** solution in the **Google** category. They are the common
foundation each Google Workspace / Gemini solution assumes is already in place (or stands up as part
of its own Requirements section). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Google solution).** The **Google Admin console**
> (admin.google.com), **Google Cloud / Cloud Identity**, and the **Microsoft / Entra** sides are
> authored at exact, current click-by-click detail from the vendors' public documentation. **Gemini
> Enterprise** capabilities that are in preview or rolling out are **cited or flagged "verify in your
> tenant"** — never invented. **Third-party migration tools** (e.g. for mail/Drive/Chat data movement)
> and **third-party enterprise apps** (ServiceNow, SAP, Databricks, etc.) are integrated at the
> pattern/architectural level; their internal console steps are deferred to the vendor's own docs.

## 1. Google Workspace / Cloud Identity tenant
- **Description:** A provisioned Google Workspace (or Cloud Identity) tenant with a **super-admin**
  account for configuration, and the appropriate Workspace edition/licensing for the capability in
  scope (e.g. Enterprise Plus for Vault/CAA/DLP, Gemini/AI add-on where required).
- **Why required:** All configuration, policy, and API work is performed against this tenant.
- **How to verify:** Sign in to **admin.google.com** as a super-admin; confirm edition and license
  counts under **Billing / Subscriptions**.
- **How to implement if missing:** Provision the tenant and licenses through Google or an authorized
  reseller before starting.

## 2. Source Microsoft 365 / Entra environment (for migration & coexistence)
- **Description:** For migration/coexistence/identity solutions, administrative access to the source
  **Microsoft 365** tenant and **Microsoft Entra ID** (Global Administrator or the least-privilege
  roles the solution names).
- **Why required:** Migration, directory sync, SSO federation, and coexistence read from and change
  the Microsoft side.
- **How to verify:** Confirm access to the M365 admin center and the Entra admin center with the
  required role.
- **How to implement if missing:** Obtain the role from the M365/Entra tenant owner.

## 3. DNS control for the routed domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF, DKIM, DMARC, TXT, CNAME) for the
  domains being migrated, coexisting, or verified.
- **Why required:** Domain verification, mail routing/coexistence, and authentication all depend on
  DNS changes.
- **How to verify:** Confirm access to the authoritative DNS zone for each domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow changes are high-impact).

## 4. Identity & provisioning source of truth
- **Description:** A defined **identity source of truth** (on-prem AD, Entra ID, or an HR/IGA system)
  and the sync mechanism (e.g. **Google Cloud Directory Sync (GCDS)** or SCIM-based provisioning).
- **Why required:** Consistent users/groups across ecosystems underpin SSO, licensing, and access.
- **How to verify:** Confirm which directory is authoritative and how objects flow into Google.
- **How to implement if missing:** Define the source of truth and provisioning model before configuring
  SSO or migrating.

## 5. A pilot scope (OU / group) and change control
- **Description:** A **pilot organizational unit or group** to validate on before fleet-wide rollout,
  and a **change-control** process for production changes (especially mail flow, DNS, identity, and DLP).
- **Why required:** Every solution follows an **Assess → Configure → Pilot → Validate → Expand** model;
  the pilot proves the design and change control protects production.
- **How to verify:** Confirm a named pilot OU/group exists and a change window/approval path is available.
- **How to implement if missing:** Create a pilot OU/group and agree the change-control process with the
  owners before making production changes.

## 6. Security, compliance & governance stakeholders
- **Description:** Engagement with the **security (CISO), legal/eDiscovery, and data-governance**
  stakeholders whose policies the configuration must satisfy (DLP, retention, Vault/Purview, and any
  regulatory regime such as ITAR/DFARS/Assured Controls where applicable).
- **Why required:** Data governance, eDiscovery, DLP, and regulated-workload settings must align to
  enterprise policy and legal requirements, not just technical defaults.
- **How to verify:** Confirm the applicable policies and named stakeholders/approvers.
- **How to implement if missing:** Identify the owners and obtain the policy/compliance requirements
  before configuring governance controls.

*The deployment model across every Google solution is the same: **Assess → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.*


---


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


---


# 5. Testing Guide — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Run these validation gates for **every** scope — first for Wave 0 (the pilot), then for each
expansion wave — before that wave is declared done. Each test confirms one part of the mapping
(files, permissions, sharing, structure, identity) worked for the wave's content. A wave does not
pass until its gate criteria are met. Use `GWDRIVE-Validation.ps1` for the per-item checks and
`GWDRIVE-Report.ps1` for coverage and exceptions.

## Test 1 — Discovery and mapping are complete
Do: Confirm every in-scope site/library/OneDrive in the wave has a named target in
`GWDRIVE Mapping - Content & Structure - Source to Target`, every source permission level has a role
in `GWDRIVE Mapping - Permissions - Level to Role`, and every discovered principal resolves in
`GWDRIVE Mapping - Identity - Source to Google`; run `GWDRIVE-Discovery.ps1`.
Expected: No in-scope scope, permission level, or principal is unmapped for the wave.

## Test 2 — Files migrated (content coverage)
Do: For the wave's scopes, compare source item/folder counts against the target; run
`GWDRIVE-Validation.ps1`.
Expected: Every source file and folder has a corresponding target item in the mapped Shared Drive / My
Drive; item counts reconcile within the tool's known exclusions, and no scope is empty.

## Test 3 — Permissions correct (roles preserved, not flattened)
Do: For a sample of items across each permission level, confirm the target Google role matches the
translated level in `GWDRIVE Mapping - Permissions - Level to Role`; run `GWDRIVE-Validation.ps1`.
Expected: Full Control → Manager, manage-content → Content manager, Contribute → Contributor,
read+comment → Commenter, read → Viewer — access intent preserved, nothing flattened to Viewer.

## Test 4 — No dropped principals
Do: For the sampled items, confirm every source grantee has a corresponding Google grant (no principal
was silently dropped for want of an identity mapping).
Expected: Every permission on the source item is present on the target item at the mapped role; any
dropped grant traces to a gap in the identity map, which is then closed.

## Test 5 — Sharing translated correctly
Do: Check the wave's shared items: direct grants, organization links, and anyone-with-the-link shares
against `GWDRIVE Mapping - Sharing - Link & Grant Rules`.
Expected: Direct grants map to Google permissions/membership; organization links map to domain sharing
at the matching role; anyone-with-the-link shares are translated only where policy allows and
otherwise down-scoped and flagged — no share is silently widened or lost.

## Test 6 — Structure preserved
Do: Spot-check folder hierarchy for a sample of migrated scopes.
Expected: Folder structure beneath each target root matches the source; nesting is within the Shared
Drive limit and no folders collapsed or re-parented incorrectly.

## Test 7 — Users can access their content
Do: Have a sample of wave users open their migrated content (team content in the Shared Drive, personal
content in My Drive) at their expected role.
Expected: Users can view/edit/manage per their mapped role; owners can manage Shared Drive members;
users are briefed that previously-hidden folders may appear greyed out (visibility change, not access).

## Test 8 — Coverage and exceptions reported
Do: Run `GWDRIVE-Report.ps1` for the wave.
Expected: The report shows content coverage (items migrated vs source), permission/sharing validation
pass rate, and an itemized exception list with no unresolved exceptions before the wave passes.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Wave 0 (pilot) pass | Tests 1-8 pass; every exception is fixed in the **mapping artifact** (not just the item) before expanding |
| Expansion wave pass | Tests 1-8 pass for the wave; the exception list from `GWDRIVE-Report.ps1` is empty before the next wave starts |
| Migration complete | All waves passed, users confirmed access at mapped roles, and source content set read-only / decommissioned only after validation was clean |


---


# 6. Troubleshooting Guide — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Use `GWDRIVE-Discovery.ps1` for the source content/permission inventory, `GWDRIVE-Validation.ps1` for
per-item files/permissions/sharing validation, `GWDRIVE-Report.ps1` for coverage/exceptions, and
`GWDRIVE-Remediation.ps1` (runs with `-WhatIf` by default) for safe fixes to identity-map / permission
gaps. Failures **inside the migration engine** (a specific file's transfer, a tool connector) are
diagnosed in the tool's own docs; this guide covers the **mapping, permission, sharing, structure, and
validation** issues this solution owns.

## A. A migrated file has no access / lost permissions
| Symptom | Cause | Remediation |
|---|---|---|
| File arrived but no one (or the wrong people) can open it | A source principal was **not in the identity map**, so its grant was dropped | Add the missing principal to `GWDRIVE Mapping - Identity - Source to Google`; re-apply with `GWDRIVE-Remediation.ps1` (`-WhatIf:$false`) and re-run `GWDRIVE-Validation.ps1` (Testing Test 4) |
| Whole scope has no grants | The identity map was incomplete for that scope's principals | Complete the map for the scope, remediate, re-validate — completeness is a gate ([CloudM — Drive permission changes](https://support.cloudm.io/hc/en-us/articles/25031144447644-Google-Drive-Permission-Changes-Microsoft-365-to-Google-Workspace)) |

## B. Permissions were flattened (everyone is a Viewer)
- A team that should still edit lands as view-only. The **permission translation table** is wrong or
  incomplete for that source level. Fix `GWDRIVE Mapping - Permissions - Level to Role` so the source
  level maps to the correct Google role (Contribute → Contributor, manage-content → Content manager,
  Full Control → Manager), re-apply, and re-run Testing Test 3.

## C. Team content ended up in a personal My Drive
- A SharePoint site/library was mapped to a My Drive and now has a single personal owner. Correct
  `GWDRIVE Mapping - Content & Structure - Source to Target` to target a **Shared Drive**, re-migrate
  that scope, and re-validate. Team content must never live in one person's My Drive.

## D. Sharing was widened or lost
| Symptom | Cause | Remediation |
|---|---|---|
| A file is now shared "anyone with the link" when it should not be | Anyone-link share translated without a policy check | Fix `GWDRIVE Mapping - Sharing - Link & Grant Rules` to down-scope anyone-links to domain/named and flag for owner review; re-apply and re-run Testing Test 5 |
| A previously-shared file is no longer shared | Organization-link or grant not translated | Confirm the sharing rule and identity map cover it; re-apply and re-validate |

## E. Folders appear greyed out to users
- Users report visible-but-unopenable folders. This is expected Google Drive behavior for content they
  could not see in SharePoint — **visibility changed, not access**. Brief users to expect it; where it
  causes confusion, place restricted content in separate top-level folders before migrating (Best
  Practices).

## F. A Shared Drive hit a limit
- A migration into one Shared Drive stalls or is rejected near **500,000 items**, **600 members**, or
  deep nesting. Split the source across multiple Shared Drives in
  `GWDRIVE Mapping - Content & Structure - Source to Target` (one per library / access boundary) and
  re-run ([Google — shared drive limits](https://support.google.com/a/answer/7338880)).

## G. File counts don't reconcile
- Target item count is lower than source. Some items are legitimate tool exclusions (system files,
  unsupported types); others are real misses. Run `GWDRIVE-Report.ps1` for the exception list, confirm
  the excluded types against the tool's docs, and re-migrate the genuine misses before passing the
  wave (Testing Test 2).

## H. The same problem recurs every wave
- A defect fixed only for one item/scope reappears. Fix the **mapping artifact** (content, permission,
  identity, or sharing) — not just the item — so later waves inherit the fix (Implementation Step 5).
  Recurring issues are almost always an un-fixed mapping, not bad luck.

## I. Graph scripts fail to connect
- `GWDRIVE-Discovery.ps1`, `GWDRIVE-Validation.ps1`, `GWDRIVE-Report.ps1`, and
  `GWDRIVE-Set-ScopeTargeting.ps1` use Microsoft Graph against the source Microsoft 365 / Entra
  tenant. If connection fails, confirm the Microsoft Graph PowerShell SDK is installed and the
  signed-in account holds the read scopes the script requests (`Sites.Read.All`, `Files.Read.All`,
  `User.Read.All`, `Group.Read.All`; `Group.ReadWrite.All` for scope targeting) — consent on first
  run, then re-run.

## J. Diagnostics quick reference
```powershell
.\GWDRIVE-Discovery.ps1                                        # source content/permission/sharing inventory
.\GWDRIVE-Set-ScopeTargeting.ps1 -GroupName "..." -ScopeCsv .\wave.csv   # -WhatIf by default
.\GWDRIVE-Validation.ps1 -ScopeCsv .\wave.csv                  # per-item files/permissions/sharing
.\GWDRIVE-Report.ps1 -ScopeCsv .\wave.csv                      # coverage + exception list
.\GWDRIVE-Remediation.ps1 -IdentityMapCsv .\identity-map.csv   # -WhatIf by default; add -WhatIf:$false to act
```

## K. When to escalate
If the identity map is complete, the permission/sharing translations are correct, the tool reports the
move finished, and `GWDRIVE-Validation.ps1` still reports gaps after remediation, capture the
`GWDRIVE-Validation.ps1` and `GWDRIVE-Report.ps1` output and review the affected scope with the content
owners, the identity/provisioning owner, and the migration-tool vendor before passing the wave.


---


# 7. Best Practices — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Field-proven practices for moving SPO/OneDrive to Google Drive/Shared Drives **without losing access**,
with a focus on shared-drive structure.

## Shared-drive structure
- **Team content goes to a Shared Drive, never a personal My Drive.** A SharePoint site/library is
  team-owned; putting it in one person's My Drive gives that person a kill switch over everyone's
  access and loses the content when they leave. Map site/library content to **Shared Drives** and
  personal OneDrive content to the same user's **My Drive**.
- **One Shared Drive per library (or per clean access boundary), not one giant drive.** A Shared Drive
  caps at **500,000 items** and **600 members** (100 of them groups), and Google recommends staying
  well under **100 levels** of folder nesting ([Google — shared drive limits](https://support.google.com/a/answer/7338880)).
  Split large sites across drives so no drive nears a limit and each has a coherent membership.
- **Set access at the Shared Drive with groups, then vary per-folder/-file only where needed.** Add a
  group as a member at the right role and let it cascade; reserve per-item permissions for the
  exceptions. This keeps membership legible and avoids thousands of one-off grants.
- **Put restricted content in its own top-level folder before migrating.** Google shows
  previously-hidden folders **greyed out** (visible, not accessible) after migration; isolating
  restricted items in separate top-level folders keeps that behavior clean and predictable.
- **Keep folder trees shallow.** Deep SharePoint nesting is technically supported but hurts usability
  and can complicate permission mapping — flatten obviously-over-nested trees during the mapping step.

## Permissions & sharing
- **Complete the identity map before you migrate — it is the whole game.** Every source principal that
  holds a permission or share must resolve to a Google identity; **anything missing is silently
  dropped** and the file arrives with lost access ([CloudM — Drive permission changes](https://support.cloudm.io/hc/en-us/articles/25031144447644-Google-Drive-Permission-Changes-Microsoft-365-to-Google-Workspace)).
  Treat map completeness as a gate.
- **Map permission levels to roles deliberately — do not flatten.** Translate each SharePoint level to
  the closest Google role (Full Control → Manager, manage-content → Content manager, Contribute →
  Contributor, read+comment → Commenter, read → Viewer) against the source tenant's *actual* levels,
  and have owners confirm the intent is preserved ([Google — shared drive roles](https://developers.google.com/workspace/drive/api/guides/ref-roles)).
- **Apply folder-level permissions to folders, file-level to files.** This is the accurate default;
  reserve root/drive-level grants for cases where the top-level access should genuinely cascade to
  everything — over-using them over-shares.
- **Never let a migration silently widen access.** Translate anyone-with-the-link shares only where
  policy allows; otherwise down-scope to domain/named access and flag for owner review. A migration
  that broadens sharing is a security incident, not a success.
- **Tell users about the greyed-out folders.** Brief them ahead of cutover so a visible-but-locked
  folder reads as expected behavior, not a bug.

## Method
- **Map once, migrate many.** Freeze the content, permission, identity, and sharing maps before Wave 0;
  deciding mapping per wave (or letting the tool default it) is the biggest source of inconsistent
  structure and flattened permissions.
- **Prove the whole mapping on a named pilot.** Wave 0 (a representative site + OneDrive sample)
  exercises files, permissions, identity, and sharing end to end — cheaper to find a mapping defect on
  one site than across a business unit.
- **Fix the mapping, not just the item.** Every validation exception is a defect in the content,
  permission, identity, or sharing artifact — fix it there so later waves inherit the fix.
- **Validate per item, every wave.** Reconcile files, check that roles match, confirm no dropped
  principals, and verify sharing — for every wave, before it passes. A tool's "success" is not
  validation.
- **One scope, one wave, fixed.** Assign every site/library/OneDrive to exactly one wave and never move
  a confirmed scope between waves — that risks duplicate content.
- **Cut over only after validation is clean.** Set source content read-only / decommission only once
  users are confirmed to have access at the mapped roles — never before.
- **Keep the tool internals with the vendor.** This solution owns the mapping, translation, and
  validation; the engine's console steps live in the vendor's docs — so a tool change touches the
  engine, not the method.


---


# 8. Deliverables Summary — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The SPO/OneDrive → Drive/Shared Drives mapping model, permission/sharing translation, and the deployment model (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: discover, define the mapping, pilot + per-item validate, then migrate by wave and validate |
| 5. Testing Guide | Per-item / per-wave validation gates with pass/fail criteria |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Shared-drive structure, permissions/sharing, and method |

## Named mapping artifacts
| Artifact | Name |
|---|---|
| Content + structure mapping | `GWDRIVE Mapping - Content & Structure - Source to Target` |
| Permission/role translation table | `GWDRIVE Mapping - Permissions - Level to Role` |
| Identity mapping table | `GWDRIVE Mapping - Identity - Source to Google` |
| Sharing translation rules | `GWDRIVE Mapping - Sharing - Link & Grant Rules` |
| Pilot scope | `GWDRIVE Pilot - Scope - Wave 0` |
| Per-wave migration + validation runbook | `GWDRIVE Runbook - Migrate & Validate - Per Wave` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWDRIVE-Discovery.ps1` | Inventories the source SharePoint sites/libraries and OneDrives: item/folder counts, structure, permission principals, and sharing (Microsoft Graph, read-only) |
| `GWDRIVE-Validation.ps1` | Per-item migration + permission validation: files present, roles match the translation, no dropped principals, sharing translated (read-only) |
| `GWDRIVE-Report.ps1` | Renders coverage and an itemized exception list: items migrated vs source and permission/sharing pass rate (read-only) |
| `GWDRIVE-Remediation.ps1` | Safe remediation of identity-map / permission gaps; runs with `-WhatIf` by default |
| `GWDRIVE-Set-ScopeTargeting.ps1` | Builds a wave's target group in Microsoft Entra from a members/scope CSV; runs with `-WhatIf` by default |

## The migration playbook (outline)
A single reusable playbook the migration runs from, assembled from the artifacts above:

1. **Discovery baseline** — source sites/libraries/OneDrives, counts, structure, principals, sharing.
2. **Content + structure map** — `GWDRIVE Mapping - Content & Structure - Source to Target`: which
   sites/libraries become which Shared Drives; which OneDrives become which My Drives.
3. **Permission/role translation** — `GWDRIVE Mapping - Permissions - Level to Role`: each source
   level → Google role, owner-confirmed.
4. **Identity map** — `GWDRIVE Mapping - Identity - Source to Google`: every principal resolved to a
   Google identity (completeness is a gate).
5. **Sharing rules** — `GWDRIVE Mapping - Sharing - Link & Grant Rules`: direct grants, organization
   links, and anyone-with-the-link translated deliberately.
6. **Pilot** — `GWDRIVE Pilot - Scope - Wave 0`: a representative site + OneDrive sample, validated
   per item.
7. **Per-wave runbook** — `GWDRIVE Runbook - Migrate & Validate - Per Wave`: build wave group → migrate
   → validate files/permissions/sharing → report → remediate → pass.
8. **Close out / cut over** — confirm access at mapped roles, brief users on greyed-out folders, set
   source read-only / decommission only after validation is clean.

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable Drive migration following the model: Assess, then Configure, then Pilot, then Validate,
  then Expand.

## Outcome
SharePoint Online and OneDrive content on Google Drive / Shared Drives with **permissions and sharing
intact** — mapped deliberately, validated per item — proven on a pilot before scaling, and migrated
wave by wave so files land in the right shared drives with the right access.
