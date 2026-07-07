# 2. Requirements

These are the **solution-specific** prerequisites for SharePoint Online Permissions & Access Management.
They build **on top of** the shared **Global Requirements — SharePoint Online & OneDrive Solutions**
(`global-requirements-sharepoint.md`): a licensed M365 tenant with SharePoint Online, least-privilege
admin roles, the SPO Management Shell / PnP / Graph toolchain, a defined information architecture and
identity/group source of truth, a pilot scope with change control, and engaged security/compliance
stakeholders. Verify those first; the items below are what this solution needs **in addition**.

Each requirement is stated as **Description / Why / Verify / Implement if missing**.

---

## 1. SharePoint Administrator (and a site-collection admin path)
- **Description:** A **SharePoint Administrator** role to run tenant-level audit/reporting, plus a way to
  be **Site Collection Administrator** on each in-scope site (SharePoint Admin can grant itself SCA on a
  site, or the site owner adds it). Global Administrator is **not** required for permission remediation.
- **Why required:** Reading and resetting role assignments, resetting inheritance, and managing site
  groups requires SCA on the target site; tenant audit/reporting requires SharePoint Admin.
- **How to verify:** In the M365 admin center confirm the **SharePoint Administrator** role; confirm
  `Connect-SPOService`/`Connect-PnPOnline` succeeds and that you can read a site's groups
  (`Get-PnPGroup`).
- **How to implement if missing:** Have a Global Admin assign **SharePoint Administrator** under change
  control; grant SCA on the pilot sites (SharePoint admin center → *Sites → Active sites → <site> →
  Membership*, or `Set-SPOUser -IsSiteCollectionAdmin $true`).

## 2. PnP PowerShell with a registered Entra app (for scoped audit/remediation)
- **Description:** **PnP PowerShell** (`PnP.PowerShell`) installed, with an **Entra ID app registration**
  for interactive/delegated modern-auth sign-in. As of PnP.PowerShell v2+, `Connect-PnPOnline
  -Interactive` requires an app registration (`Register-PnPManagementShellAccess` or a custom app) with
  delegated SharePoint permissions.
- **Why required:** The discovery, remediation, review-support, and reporting scripts run on PnP against
  each site; item/list-level inheritance and role-assignment operations are PnP/CSOM.
- **How to verify:** `Get-Module PnP.PowerShell -ListAvailable`; `Connect-PnPOnline -Url
  https://contoso.sharepoint.com/sites/<pilot> -Interactive` succeeds and `Get-PnPWeb` returns the web.
- **How to implement if missing:** `Install-Module PnP.PowerShell`; register the app
  (`Register-PnPManagementShellAccess`) or use your org's existing PnP app; consent the delegated
  permissions. **No client secret is stored in the scripts** — modern-auth interactive/delegated only.

## 3. A defined group source of truth (Entra/M365 groups vs SharePoint groups)
- **Description:** A decision on **what backs access**: Entra ID security groups / Microsoft 365 groups as
  the authoritative membership, surfaced into each site via its **SharePoint groups** (Owners / Members /
  Visitors). Team sites created from a Microsoft 365 group already have the group as the owner/member
  source; communication sites and classic sites use SharePoint groups directly.
- **Why required:** Group-based access is only "self-maintaining" if membership lives in a governed group.
  Without a source of truth, you can still standardize on SharePoint groups, but joins/leaves won't flow
  automatically.
- **How to verify:** Confirm whether in-scope sites are **M365-group-connected** (Team sites) or not;
  confirm which Entra/M365 groups are authoritative for each business area.
- **How to implement if missing:** Define the group model with the identity team (often the Architecture
  product). At minimum, agree that access is granted to **SharePoint groups**, never to individual users.

## 4. Information owners / approvers per site (the entitlement decision)
- **Description:** A named **information owner or approver** for each in-scope site who can decide **who
  should have access** and at what level, and who will **run the access reviews**.
- **Why required:** This solution builds the model and surfaces the evidence, but the **business
  entitlement** — who belongs in `SPO Group – Finance Members – Prod` — is an owner decision, not the
  implementer's. Remediation that removes a unique grant needs an owner to confirm it was not intended.
- **How to verify:** Confirm a named owner/approver exists for each pilot site and agrees to review the
  audit exceptions.
- **How to implement if missing:** Identify the owner with the business/compliance stakeholders before
  remediating; capture their decisions against the `Permission Audit – SPO – Discovery` exception list.

## 5. Licensing for advanced review/reporting (Entra ID P2 and/or SAM) — verify
- **Description:** **Microsoft Entra ID P2** (for **Access Reviews**) and/or **SharePoint Advanced
  Management (SAM)** (for **Data Access Governance reports** and **site access review**) if you intend to
  use those platform features rather than the included PowerShell reporting.
- **Why required:** Access Reviews and DAG reports are **license-gated add-ons**; availability and the
  exact feature set are **plan-dependent and change over time**.
- **How to verify:** In the M365 admin center / Entra admin center confirm **Entra ID P2** assignment; in
  the SharePoint admin center confirm the **Data Access Governance** and **access review** features are
  present (they surface only when SAM is licensed). **Verify in your tenant/plan** — do not assume.
- **How to implement if missing:** Either license the add-ons under change control, **or** use the
  solution's included PowerShell reporting/review-support scripts, which cover the same evidence without
  the platform features. The solution works either way.

## 6. Microsoft Graph permissions for reporting (where Graph is used)
- **Description:** For the Graph-based reporting paths, delegated Microsoft Graph scopes such as
  **`Sites.Read.All`**, **`Group.Read.All`**, and **`Directory.Read.All`** (read-only), consented for the
  sign-in account.
- **Why required:** Expanding Entra/M365 group membership and cross-site reporting uses Graph.
- **How to verify:** `Connect-MgGraph -Scopes 'Sites.Read.All','Group.Read.All','Directory.Read.All'`
  succeeds and `Get-MgGroup -Top 1` returns.
- **How to implement if missing:** Have an admin consent the delegated read scopes; **no application
  secret is stored** — modern-auth delegated sign-in only.

## 7. A pilot scope and documented rollback
- **Description:** A **named pilot site (or small set)** to remediate first — ideally one with real
  broken inheritance / direct grants but limited blast radius — and a **rollback** approach (the audit
  export is the before-state; re-granting a removed unique permission is the reverse action).
- **Why required:** Resetting inheritance and converting direct grants are **high-impact** changes.
  Pilot-first with a rollback is the house model.
- **How to verify:** Confirm the pilot site (`Permission Scope – Pilot – Stage1`), the change window, and
  that a fresh `Permission Audit – SPO – Discovery` export has been captured for it.
- **How to implement if missing:** Choose the pilot site, capture the audit baseline, and agree the change
  window/rollback with the site owner before any `-Commit` run.
