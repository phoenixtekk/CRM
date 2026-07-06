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
