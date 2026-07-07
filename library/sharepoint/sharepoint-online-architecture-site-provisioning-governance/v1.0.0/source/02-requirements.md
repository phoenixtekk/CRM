# Requirements

This solution builds **on** the shared prerequisites in
`global-requirements-sharepoint.md` (the six SharePoint-category requirements: a licensed
M365 tenant with SharePoint Online/OneDrive; least-privilege **SharePoint Administrator**
access; the SPO Management Shell / PnP + Graph toolchain; an IA and identity/group source of
truth; a pilot scope and change control; and security/compliance/records stakeholders).
**Verify those first.** The requirements below are the ones **specific** to architecture and
provisioning governance — do not duplicate the shared six.

---

## 1. PnP PowerShell and a PnP app registration (Entra) for provisioning

- **Description:** The **PnP.PowerShell** module (PowerShell 7 recommended; the module runs on
  5.1 and 7) plus a registered **Entra ID application** that PnP authenticates as. Since
  September 2024 PnP PowerShell no longer ships a default multi-tenant app, so you must
  register your own app (interactive/delegated for hands-on work, or certificate-based
  app-only for unattended provisioning flows).
- **Why required:** The templates are applied and sites provisioned with `Connect-PnPOnline`,
  `Get-PnPSiteTemplate`/`Invoke-PnPSiteTemplate`, and `New-PnPSite`. Unattended provisioning
  (a scheduled or flow-triggered run) needs an app registration with a certificate, not a
  password.
- **How to verify:** `Get-Module PnP.PowerShell -ListAvailable` returns a version; and
  `Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP – Provisioning – Prod" -Tenant <tenant>.onmicrosoft.com`
  has been run once, or an app with the needed Graph/SharePoint permissions exists in Entra.
- **How to implement if missing:** `Install-Module PnP.PowerShell -Scope CurrentUser`. Register
  the app with `Register-PnPEntraIDApp*`, grant and **admin-consent** the delegated
  `Sites.FullControl.All` (and Graph `Group.ReadWrite.All` for group-connected sites) it
  requires, and record the client (application) ID. Name the app `PnP – Provisioning – Prod`.
  For app-only, add a certificate and consent the application permissions. Treat the client
  ID as configuration and the certificate/secret as a secret — never hardcode it in scripts.

## 2. SharePoint tenant settings that permit governed provisioning

- **Description:** Tenant-level SharePoint settings configured so that **governed** provisioning
  is the path and **ungoverned** self-service creation is constrained: the SharePoint admin
  center **"Site creation"** setting (whether users can create sites, and from where) and the
  Microsoft 365 group creation setting (restricting group creation to an approved security
  group).
- **Why required:** The request→approve→provision pipeline only holds if users cannot simply
  click "New site" (or create an M365 group, which creates a site) outside the process.
- **How to verify:** In the SharePoint admin center → **Settings → Site creation**, review who
  can create sites; and check the Entra/Graph `Set-SPOTenant`/group-creation policy
  (`AllowedMembersToCreateGroups`). `Get-SPOTenant | Select DisableSelfServiceSiteCreation` and
  the group-creation directory setting show current state.
- **How to implement if missing:** Plan the change with the governance stakeholders (it is
  tenant-wide and high-impact). Restrict M365 group creation to an approved group, and set site
  creation to route through the request process. **Do this at Pilot/Expand under change
  control**, not on day one — see the implementation guide's rollback.

## 3. Term store administrator and a taxonomy source of truth

- **Description:** A designated **Term Store Administrator** (assigned in the SharePoint admin
  center → **Content services → Term store**) and a business-supplied source of truth for the
  controlled vocabulary (which departments, document types, and regions are valid values).
- **Why required:** The solution creates the term **structure** (`Term Group – Enterprise
  Metadata – Prod` and its term sets) but the **term values** are the organization's own
  vocabulary and must come from the business/records owners, not be invented.
- **How to verify:** In the term store, confirm at least one **Term store admin** is listed and
  that a business owner has provided (or committed to provide) the term lists.
- **How to implement if missing:** Assign a Term Store Administrator; nominate a taxonomy owner
  in the business who signs off the term sets. Capture the term lists before configuring the
  taxonomy.

## 4. Content type publishing (content type gallery) available

- **Description:** The tenant **content type gallery** (the modern replacement for the classic
  Content Type Hub) so the governed content type can be **published** and syndicated to all
  site collections, rather than defined per-site.
- **Why required:** `Content Type – Governed Document – Prod` and its site columns must exist
  once and appear everywhere; publishing from the gallery is what makes the taxonomy consistent
  across sites the templates create.
- **How to verify:** In the SharePoint admin center → **Content services → Content type
  gallery**, confirm access and that content types can be created/published there.
- **How to implement if missing:** Use the content type gallery in the admin center (available
  in current SharePoint Online — **verify in your tenant**; older tenants may still surface the
  classic Content Type Hub at `/sites/contentTypeHub`). Create the site columns and content type
  there and publish.

## 5. A governance approver and a Power Automate (or scripted) approval path

- **Description:** A named **governance approver** (person or group) who owns the approval gate,
  and a **Power Automate** environment (or an equivalent scripted/ticketing approval) able to
  run an approval flow against the `Site Request – Intake – Prod` list.
- **Why required:** The "approve" step of request→approve→provision is a real, auditable gate.
  Without a named approver and an approval mechanism, provisioning is not governed.
- **How to verify:** Confirm the approver (e.g. a `Governance Approvers` group) and that Power
  Automate is available in the tenant (or the org's ITSM tool will hold the approval).
- **How to implement if missing:** Name the approver group; confirm Power Automate licensing/
  environment, or decide the approval will live in the existing ITSM tool and the provisioning
  script runs on ticket closure.

## 6. A reference/build site to author each template from

- **Description:** A hand-built **reference site per archetype** (or a design spec for each) that
  the PnP template is **extracted from** with `Get-PnPSiteTemplate`. You need a place to build
  and validate the ideal team/communication/project site before templatizing it.
- **Why required:** A PnP provisioning template is only as good as the site it is extracted from;
  the templates `Template – Team Site – Prod`, `Template – Communication Site – Prod`,
  `Template – Project Site – Prod`, and `Template – Department Hub Site – Prod` are captured from
  reference sites, not written by hand.
- **How to verify:** Confirm a reference site (or an agreed spec) exists for each archetype in
  the solution's scope.
- **How to implement if missing:** Provision a plain site of each base type in the pilot scope,
  configure it to the design (libraries, columns, content type, navigation, theme), validate it,
  then extract the template from it.
