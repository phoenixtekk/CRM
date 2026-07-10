# 1. Solution Overview — Secure Microsoft 365 Copilot: Oversharing & SharePoint Permissions Remediation

## What it is
A repeatable method to **discover, remediate, and verify** the SharePoint Online / OneDrive access that
governs what Microsoft 365 Copilot can surface. Copilot reasons over Microsoft Graph content — files,
sites, pages, chats — and returns anything the prompting user technically has permission to open. If a
site is shared with "Everyone Except External Users," if an anonymous link is live, or if a user carries
stale membership from a former role, Copilot can pull that content into a response. This solution closes
that gap by fixing the underlying permissions, not by turning Copilot off.

## How the technology works
- **Copilot honors existing permissions.** It adds no access of its own. The exposure is entirely a
  function of the current SharePoint/OneDrive sharing and permission state — so remediation is a
  SharePoint access-governance exercise, surfaced by Copilot.
- **The oversharing signals** that matter for Copilot: sites/items granted to **EEEU** or an org-wide
  group; **"Anyone" (anonymous) links**; broad company-wide sharing links; large-membership sites; and
  **stale permissions** (guests, former team members, orphaned groups).
- **SharePoint Advanced Management (SAM)** provides the tenant-scale levers: **Data Access Governance
  (DAG) reports** (oversharing / sharing-links / EEEU / sensitivity-labelled content), **Restricted
  Access Control (RAC)** to lock a site to a named group, **Restricted Content Discovery (RCD)** to
  exclude specific sites' content from Copilot and org-wide search, and **site access reviews** that
  push cleanup back to owners. *(SAM is a licensed add-on — verify current availability in your tenant.)*
- **Restricted SharePoint Search (RSS)** is a tenant-wide **interim** control: an allow-list of up to
  100 sites that Copilot/enterprise search may use, blocking the rest — a stopgap while you clean up, not
  the end state. *(Verify current availability.)*
- **Information protection alignment.** Sensitivity labels with **encryption / usage rights** are honored
  by Copilot at the item level; DLP for Copilot keeps labelled content out of AI responses. This solution
  *aligns* with that layer (built in the Copilot data-governance solution) so access is defended in depth.
- **Automation** is PowerShell: **Microsoft Graph** and **PnP PowerShell** for read-only discovery and
  validation; the **SharePoint Online Management Shell** (`Set-SPOTenantRestrictedSearchMode`, etc.) for
  RSS; the SharePoint admin center and SAM blades for RAC/RCD/DAG.

## The standard deployment model — Assess → Configure → Pilot → Validate → Expand
1. **Assess** — confirm scope, licensing, roles, connections; run read-only discovery to inventory the
   oversharing across the in-scope estate and rank the worst offenders.
2. **Configure** — with site owners, agree the remediation list; stage the access changes, SAM RAC/RCD,
   and interim RSS as **previews / `-WhatIf`** first.
3. **Pilot** — apply remediation to a **pilot ring** of sites; nothing tenant-wide is enforced yet.
4. **Validate** — re-measure the oversharing signal on pilot sites; verify from the **Copilot side** that
   a test user can no longer surface content they should not reach; check no legitimate collaboration
   broke.
5. **Expand** — roll remediation to the remaining waves under change control, remove interim RSS/RCD once
   the underlying access is fixed, record the before/after report, and stand up a recurring review.

## Scope
- Discovery of SharePoint/OneDrive oversharing signals across the in-scope estate.
- Permission remediation: removing/scoping EEEU and org-wide grants, revoking anonymous/company links,
  cleaning stale access, and driving owner-led site access reviews.
- SAM controls where licensed: RAC, RCD, and DAG-report-driven prioritization; interim RSS at tenant
  scope.
- Sensitivity-label + DLP **alignment** so corrected access is reinforced by information protection.
- Copilot-side verification that responses honor the corrected permissions.

## What is out of scope
- **Data-owner access determinations** — who should have access, and what counts as "too broad" — are the
  business's decision; this guide gives the method and evidence.
- **Building the sensitivity-label taxonomy and DLP-for-Copilot policies** — delivered in the Copilot
  data-governance solution and the Purview information-protection solutions; referenced here, not rebuilt.
- **Copilot licensing/enablement, network/client readiness, and identity hardening** — covered by the
  Copilot global requirements and the Entra solutions.
- **Regulatory, records, and legal determinations** — remain with compliance/legal.

## Authentication & connections used
- **Microsoft Graph PowerShell** (`Connect-MgGraph`, read scopes e.g. `Sites.Read.All`,
  `Directory.Read.All`) — read-only discovery/validation.
- **PnP PowerShell** (`Connect-PnPOnline`) — read-only site/permission enumeration and reporting.
- **SharePoint Online Management Shell** (`Connect-SPOService`) — RSS and tenant sharing controls.
- **SharePoint admin center / SAM blades** (`https://<tenant>-admin.sharepoint.com`) — DAG reports, RAC,
  RCD, site access reviews.
- **Roles:** SharePoint Administrator for remediation; Global Reader / read scopes for discovery;
  Security/Compliance roles for the label/DLP alignment (see the global requirements file). Reserve
  Global Administrator for tenant-wide changes only.

> The category-level prerequisites (tenant, Copilot licensing, Entra identity/MFA, admin roles, network/
> client readiness, governance policy) live in **`global-requirements-copilot.md`** — confirm those
> first; this solution's specific prerequisites are in doc 2.
