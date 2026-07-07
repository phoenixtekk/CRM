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
