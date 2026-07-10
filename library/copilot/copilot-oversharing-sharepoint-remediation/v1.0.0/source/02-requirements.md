# 2. Requirements — Secure Microsoft 365 Copilot: Oversharing & SharePoint Permissions Remediation

The category-level prerequisites (Microsoft 365 tenant and workloads, Copilot licensing, Entra ID
identity/MFA, administrative roles, network/client readiness, and governance/responsible-use policy) are
covered once in **`global-requirements-copilot.md`** — confirm those first and do not repeat them here.
Below are the prerequisites **specific to this oversharing-remediation solution**. Each: **Description /
Why required / How to verify / How to implement if missing.**

## 2.1 SharePoint Administrator (and read access for discovery)
- **Description:** A SharePoint Administrator role for remediation, plus a reader identity (Global Reader
  or the read Graph scopes below) for discovery.
- **Why required:** Removing broad grants, applying RAC/RCD, and running RSS require SharePoint
  Administrator; discovery only needs read.
- **How to verify:** Entra portal → **Roles and administrators** → confirm **SharePoint Administrator**
  on the operator; confirm a reader identity for discovery.
- **How to implement if missing:** Assign SharePoint Administrator (least privilege for this task);
  reserve Global Administrator for tenant-wide changes only.

## 2.2 PowerShell modules — Microsoft Graph, PnP, SharePoint Online Management Shell
- **Description:** `Microsoft.Graph` (for discovery/validation), `PnP.PowerShell` (site/permission
  reporting), and `Microsoft.Online.SharePoint.PowerShell` (RSS / tenant sharing controls) installed on
  the operator workstation.
- **Why required:** The bundled scripts and the RSS control depend on these modules.
- **How to verify:** `Get-Module Microsoft.Graph,PnP.PowerShell,Microsoft.Online.SharePoint.PowerShell
  -ListAvailable`. The discovery script also reports which modules are present.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`;
  `Install-Module PnP.PowerShell -Scope CurrentUser`;
  `Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser`. PowerShell 7+ recommended.
  *(PnP PowerShell app-registration/consent requirements have changed over time — verify the current
  sign-in method for your tenant.)*

## 2.3 SharePoint Advanced Management (SAM) — verify licensing
- **Description:** SharePoint Advanced Management, which unlocks Data Access Governance reports,
  Restricted Access Control, Restricted Content Discovery, and site access reviews.
- **Why required:** These are the tenant-scale levers for prioritizing and fencing oversharing; without
  SAM you fall back to manual sharing cleanup and interim RSS.
- **How to verify:** SharePoint admin center → look for **Reports → Data access governance** and the
  **Restricted Content Discovery** / **Restricted access control** controls. *(SAM is a paid add-on and
  its feature surface evolves — verify current availability and licensing in your tenant.)*
- **How to implement if missing:** Acquire the SAM add-on, or proceed with manual remediation + interim
  RSS and note SAM controls as pending. The scripts degrade gracefully when SAM is absent.

## 2.4 A defined in-scope estate and pilot ring
- **Description:** The list of SharePoint sites / OneDrive accounts in scope, and a **pilot ring** of
  sites to remediate first.
- **Why required:** Remediation is piloted before broad rollout; you must know which sites are in scope
  and which are the pilot targets.
- **How to verify:** A documented site list (from the SharePoint admin center **Active sites** export or
  the discovery script) and an agreed pilot subset.
- **How to implement if missing:** Export **Active sites** from the SharePoint admin center; agree a
  pilot ring (e.g. the sites that back the Copilot pilot cohort) with the site owners.

## 2.5 Site owners identified and available
- **Description:** Named **owners** for the in-scope sites who can make (or approve) access decisions.
- **Why required:** *Who should have access* is a data-owner determination, not an admin one; site access
  reviews and grant removals need owner input to avoid breaking legitimate collaboration.
- **How to verify:** Each in-scope site has a current owner in **Site permissions**; owners are reachable
  for the pilot window.
- **How to implement if missing:** Assign/confirm site owners before remediation; where a site is
  orphaned, escalate to the business to name one.

## 2.6 Sensitivity-label & DLP baseline (alignment, referenced)
- **Description:** A published sensitivity-label taxonomy and, ideally, DLP-for-Copilot policies (built in
  the Copilot data-governance solution / Purview information-protection solutions).
- **Why required:** This solution *aligns* corrected access with information protection so boundaries are
  defended in depth; labels with encryption/usage rights are honored by Copilot at item level.
- **How to verify:** Purview portal → **Information Protection** shows published labels; DLP shows any
  Copilot-scoped policies.
- **How to implement if missing:** Not a hard blocker for permission remediation — proceed, and build the
  label/DLP layer via the Copilot data-governance solution. Note label alignment as pending.

## 2.7 Change window and rollback plan
- **Description:** An agreed change window for enforcement steps and a documented rollback (restore prior
  sharing, disable RSS, remove RCD).
- **Why required:** Removing broad access and enabling RSS/RCD can affect legitimate collaboration; a
  window and rollback keep it safe and reversible.
- **How to verify:** A recorded change window and a rollback note per remediation action; the discovery
  export is retained as the before-state.
- **How to implement if missing:** Schedule the window; keep the `Oversharing Discovery – Estate – Assess`
  export as the restore reference before making any change.

## 2.8 Auditing enabled (for verification)
- **Description:** Microsoft Purview / unified audit logging enabled, so Copilot interactions and sharing
  changes are recorded.
- **Why required:** Copilot-side verification and the before/after evidence rely on the audit trail.
- **How to verify:** Purview portal → **Audit** shows recording is on; `Search-UnifiedAuditLog` returns
  recent events.
- **How to implement if missing:** Enable auditing (Purview **Audit** → *Start recording user and admin
  activity*); allow time for backfill before relying on it.
