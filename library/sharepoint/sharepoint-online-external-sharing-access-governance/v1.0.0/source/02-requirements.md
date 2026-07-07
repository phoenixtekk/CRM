# 2. Requirements — SharePoint Online External Sharing & Access Governance

These are the **solution-specific** prerequisites for external sharing & access governance. They build
**on top of** the shared SharePoint-category requirements in **`global-requirements-sharepoint.md`**
(a licensed SharePoint Online / OneDrive tenant, least-privilege SharePoint admin access, the SPO
Management Shell / PnP / Graph toolchain, an information-architecture + identity/group source of truth,
a pilot scope + change control, and security/compliance/records stakeholders). Do not duplicate those
six — verify them there first, then confirm the items below.

Each item lists **Description / Why / Verify / Implement if missing**.

---

## 2.1 SharePoint Administrator role (and Global Admin only where noted)
- **Description:** The **SharePoint Administrator** Entra role, which grants access to the SharePoint
  admin center and the `Set-SPOTenant` / `Set-SPOSite` cmdlets. Tenant-wide sharing changes are made
  here; a small number of adjacent tasks (publishing a sensitivity label, creating an Entra Access
  Review) need **Compliance/Purview** or **Identity Governance** roles held by their respective owners.
- **Why required:** `Set-SPOTenant` (tenant `SharingCapability`, default link type, expiration, domain
  mode) requires SharePoint Administrator; you should **not** run this work as Global Administrator by
  default (least privilege).
- **How to verify:** Microsoft 365 admin center → **Roles**, or Entra admin center → **Roles &
  admins**, confirm the operator holds **SharePoint Administrator**. Confirm `Connect-SPOService` to the
  `-admin` URL succeeds.
- **How to implement if missing:** Have a Global Administrator assign **SharePoint Administrator** under
  change control. For label publishing / access reviews, confirm the compliance and identity-governance
  owners hold their roles — those steps are theirs, not the SharePoint admin's.

## 2.2 SharePoint Online Management Shell connected to the admin endpoint
- **Description:** The **Microsoft.Online.SharePoint.PowerShell** module (SharePoint Online Management
  Shell), connected with `Connect-SPOService -Url https://<tenant>-admin.sharepoint.com` (Commercial),
  or the **Government** admin URL for your cloud (e.g. `https://<tenant>-admin.sharepoint.us` — **verify
  your cloud's admin host**).
- **Why required:** All tenant/site sharing settings (`Get-/Set-SPOTenant`, `Get-/Set-SPOSite`,
  `Get-SPOExternalUser`) run through this module against the **admin** endpoint, not a site URL.
- **How to verify:** `Get-Module -ListAvailable Microsoft.Online.SharePoint.PowerShell`, then
  `Connect-SPOService -Url https://<tenant>-admin.sharepoint.com` and `Get-SPOTenant` returns settings.
- **How to implement if missing:** `Install-Module Microsoft.Online.SharePoint.PowerShell -Scope
  CurrentUser`. On Government clouds pass `-Region ITAR`/the correct region and the `.us` admin host.

## 2.3 PnP PowerShell for link + permission enumeration
- **Description:** **PnP.PowerShell** for enumerating sharing links and permissions at the site/file/
  folder level (`Get-PnPFileSharingLink`, `Get-PnPFolderSharingLink`, `Get-PnPTenantSite`), connected
  with `Connect-PnPOnline` using an **app registration** (interactive or certificate) with the
  delegated/app permissions your tenant requires.
- **Why required:** Tenant/site *settings* come from SPO cmdlets, but the **actual sharing links and
  external principals** (the exposure inventory that feeds `External Exposure – SPO – Report`) are read
  through PnP / Graph, not `Set-SPOTenant`.
- **How to verify:** `Get-Module -ListAvailable PnP.PowerShell`; `Connect-PnPOnline -Url
  https://<tenant>.sharepoint.com/sites/<pilot> -Interactive` succeeds and `Get-PnPFileSharingLink`
  runs against a document library.
- **How to implement if missing:** `Install-Module PnP.PowerShell -Scope CurrentUser`. Register the PnP
  Entra app (`Register-PnPEntraIDAppForInteractiveLogin` or your own app registration) and consent to
  the required Sites/Graph permissions. Modern-auth only — **no stored credentials in scripts.**

## 2.4 Microsoft Graph PowerShell for guests and access reviews
- **Description:** The **Microsoft.Graph** PowerShell SDK, connected with `Connect-MgGraph` using the
  scopes the tasks need (e.g. `Sites.Read.All`, `User.Read.All` for exposure reporting;
  `AccessReview.ReadWrite.All` for creating reviews — the latter held by the identity-governance owner).
- **Why required:** Guest enumeration and **Entra Access Reviews** are Graph/Entra features; external
  principals on sharing links resolve through Graph.
- **How to verify:** `Connect-MgGraph -Scopes "Sites.Read.All","User.Read.All"` succeeds; `Get-MgUser
  -Filter "userType eq 'Guest'"` returns the guest population.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to the
  scopes. On Government clouds pass `Connect-MgGraph -Environment USGov`/`USGovDoD` as appropriate.

## 2.5 A documented external-sharing policy (from the policy owner)
- **Description:** A written statement of the **approved** sharing posture: the tenant sharing level,
  the default link type/permission, the Anyone-link expiration and guest-expiration values, the
  **allow-list or block-list of domains**, which site tiers are "confidential" and how tight they must
  be, and the guest-review cadence.
- **Why required:** Every setting this solution applies encodes a **policy decision**. The technical
  method is ours; the *values* are the security/compliance owner's determination (see Overview →
  "The determination boundary"). Configuring without an agreed policy risks either breaking
  collaboration (too tight) or leaving exposure (too loose).
- **How to verify:** Confirm a signed-off policy document naming the values above and the approver.
- **How to implement if missing:** Run the **Assess** stage (Discovery report) and workshop the policy
  with the security/compliance stakeholders **before** touching production sharing settings.

## 2.6 Sensitivity labels published (if label-driven controls are in scope)
- **Description:** If the design uses **sensitivity-label container controls**, the labels must already
  be **created and published** in **Microsoft Purview** by the compliance owner, with **group & site**
  (container) protection settings configured (privacy, external sharing, unmanaged-device access), and
  container labeling **enabled** for the tenant.
- **Why required:** This solution **applies** a published label to a container (`Set-SPOSite
  -SensitivityLabel <id>` / Purview) — it cannot apply a label that does not exist, and it does not
  author label taxonomy or file-level encryption.
- **How to verify:** In the Purview portal → **Information protection → Labels**, confirm the label
  exists and is **published** to the right scope, with container settings on. Container labeling for
  SharePoint/Groups is enabled (a tenant-level enablement — **verify in your tenant/plan**, it is
  license-dependent).
- **How to implement if missing:** The **compliance owner** creates and publishes the label and enables
  container labeling. If label-driven controls are not in scope, this requirement does not apply — use
  site-level `SharingCapability` instead.

## 2.7 Entra ID Governance licensing for Access Reviews (if reviews are in scope)
- **Description:** **Microsoft Entra ID P2** or **Microsoft Entra ID Governance** licensing, required to
  create and run **Access Reviews** for the guest population and externally-shared groups.
- **Why required:** Recurring, attested guest access reviews (`Access Review – Guests – Quarterly`) are
  an Entra ID Governance capability; the feature is **not** available on lower plans.
- **How to verify:** Confirm the licensing in the M365 admin center; in the Entra admin center →
  **Identity Governance → Access reviews**, confirm you can create a review.
- **How to implement if missing:** Acquire the licensing, **or** use the scripted guest-review fallback
  (`SPOEXT-ExposureReport.ps1` enumerates guests + their external access for a manual attestation). The
  fallback is a report, not an enforced governance workflow — flag the gap to the policy owner.

## 2.8 A named pilot scope of sites and users
- **Description:** A concrete **`Sharing Scope – Pilot – Stage1`** set — a handful of representative
  site collections (a team site, a communication site, a "confidential" site) and, ideally, a set of
  pilot OneDrive users — to validate settings on before tenant-wide change.
- **Why required:** Tenant `SharingCapability` is tenant-wide and high-impact; site-level tightening and
  link-default/expiration behavior must be proven on a small scope first. (Note: some tenant settings
  are genuinely tenant-wide and cannot be piloted per-site — those are validated in a change window with
  a rollback, per the Implementation guide.)
- **How to verify:** Confirm the named site URLs and pilot user list, and a change window/approval for
  the tenant-wide portions.
- **How to implement if missing:** Select and document the pilot sites/users with the site owners, and
  agree the change window and rollback with change control before Stage 2 (Configure).
