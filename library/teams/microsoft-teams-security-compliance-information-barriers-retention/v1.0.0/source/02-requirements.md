# 2. Requirements Guide

These are the **solution-specific** prerequisites for the Teams security & compliance controls. They
build **on top of** the shared prerequisites in the category file `global-requirements-teams.md`
(tenant + Teams licensing, least-privilege Teams roles, the MicrosoftTeams/Graph toolchain, an
identity/group source of truth, a pilot scope + change control, and security/compliance stakeholder
engagement) — read that first; the items below add what is specific to information barriers, Teams
retention, and Teams DLP. Each item lists **Description / Why / Verify / Implement if missing.**

---

## 1. Compliance licensing for Information Barriers and Teams DLP
- **Description:** The Microsoft 365 / Purview plan that entitles **Information Barriers** and **Teams
  DLP**. Per Microsoft's public licensing guidance these capabilities are in the higher compliance
  SKUs (for example Microsoft 365 E5, the **E5 Compliance** add-on, or **E5 Information Protection &
  Governance** / Insider Risk Management for IB) — **exact entitlement is plan-dependent; verify in
  your tenant.**
- **Why required:** Without the entitlement the `New-InformationBarrierPolicy` /
  `New-DlpCompliancePolicy` operations and the Teams-location DLP will not be available or will not
  enforce.
- **Verify:** In the Microsoft 365 admin center review the subscriptions and add-ons; in the Purview
  portal confirm the **Information barriers** and **Data loss prevention** solutions are visible.
- **Implement if missing:** Assign/purchase the required compliance plan or add-on before starting.

## 2. Least-privilege compliance roles
- **Description:** The Purview role groups the work needs — **Information Barriers** processors for IB
  (`Get/New/Set-*InformationBarrier*`, segments, and running application), **Compliance
  Administrator** or **DLP Compliance Management** for DLP, and **Retention Management** for retention.
  These are separate from the Teams Administrator role in the category GR.
- **Why required:** Segment/IB, DLP, and retention cmdlets run against **Security & Compliance
  PowerShell** and are gated by these Purview role groups, not by Teams roles.
- **Verify:** In the Purview portal **Roles & scopes → Permissions**, confirm your account is in the
  Information Barriers, Compliance/DLP, and Retention role groups (or a role group that contains them).
- **Implement if missing:** Have a Compliance/Global Admin add your account to the required role
  groups under change control.

## 3. Security & Compliance PowerShell connectivity (Connect-IPPSSession)
- **Description:** The **ExchangeOnlineManagement** module, used to reach **Security & Compliance
  PowerShell** via `Connect-IPPSSession` (this is a *different* endpoint from `Connect-ExchangeOnline`
  and from `Connect-MicrosoftTeams`). Government clouds use different connection URIs (for example
  `*.office365.us`) — **flag and verify your cloud's endpoint.**
- **Why required:** All IB, retention, and DLP cmdlets and the four compliance-facing scripts in this
  solution run through the Security & Compliance PowerShell endpoint.
- **Verify:** `Connect-IPPSSession` succeeds and `Get-OrganizationSegment` / `Get-DlpCompliancePolicy`
  return without an access error.
- **Implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; for
  Government cloud pass the appropriate `-ConnectionUri`/`-AzureADAuthorizationEndpointUri` per
  Microsoft's cloud-specific docs (verify in your tenant).

## 4. A directory attribute to define IB segments — governed by compliance
- **Description:** A clean, authoritative user attribute (for example **Department**, **job title**,
  or membership of a specific Entra group) that reliably identifies each population the barrier must
  separate. **Which populations must be separated, and by which attribute, is a compliance/legal
  determination — not a technical one.**
- **Why required:** IB segments are defined by an attribute filter (`-UserGroupFilter`). If the
  attribute is inconsistent or missing, users fall outside every segment and the barrier does not
  apply to them.
- **Verify:** Confirm the chosen attribute is populated and accurate for the affected users (spot-check
  in Entra ID / `Get-MgUser`). Confirm compliance has **defined** the segments and the block/allow
  relationships in writing.
- **Implement if missing:** Have identity remediate the attribute for the in-scope users; obtain the
  segment/relationship definitions from compliance before configuring IB.

## 5. Scoped directory search enabled in Teams (IB dependency)
- **Description:** Information barriers in Teams require **scoped directory search** to be enabled
  org-wide so that people search respects the barriers. This is a Teams **org-wide setting**, set in
  the Teams admin center (or via configuration), and applies tenant-wide.
- **Why required:** Without scoped directory search enabled, IB cannot fully constrain search/discovery
  in Teams and Microsoft's IB enablement steps are incomplete.
- **Verify:** In the **Teams admin center → Org-wide settings → Teams settings**, confirm the search
  scope option; or review the current Teams client configuration.
- **Implement if missing:** Enable scoped directory search per Microsoft's IB prerequisite steps
  during a change window (it is tenant-wide) **before** starting IB application — coordinate with the
  Teams admin owner from the category GR.

## 6. No conflicting address book policies (IB dependency)
- **Description:** Information barriers are **incompatible with legacy Exchange Address Book Policies
  (ABPs)** used for address-list segregation. The tenant must not have an ABP-based segmentation that
  conflicts with IB.
- **Why required:** IB and ABP-based segregation cannot both govern the same directory partitioning;
  Microsoft's IB docs call out the conflict.
- **Verify:** Check for existing ABPs (`Get-AddressBookPolicy` in Exchange Online PowerShell) and
  confirm none are relied upon for the populations IB will segment.
- **Implement if missing:** Plan the migration off ABP-based segregation with the messaging owner
  before enabling IB (this is an existing-environment dependency — surface it early).

## 7. Existing Purview posture (retention / DLP) — align, don't collide
- **Description:** The current Purview state that Teams controls must fit into: the sensitive-information
  types / sensitivity labels this Teams DLP will reference, and any existing org-wide retention that
  already includes or excludes the Teams locations.
- **Why required:** Teams DLP should reuse the org's approved sensitive-info types/labels rather than
  inventing new ones, and Teams retention must not double-apply against a retention policy that already
  covers Teams.
- **Verify:** Run the assessment script (or `Get-RetentionCompliancePolicy` / `Get-DlpCompliancePolicy`)
  to list what already covers the Teams locations; confirm the label/SIT set with the Purview owner.
- **Implement if missing:** Where the broader Purview program is absent, reference the separate Purview
  program work; do **not** rebuild the label taxonomy or org-wide DLP here.

## 8. Compliance, records & legal stakeholders and their determinations
- **Description:** Written determinations from the org's **compliance, records, and legal** functions:
  the IB segment/relationship definitions (item 4), the Teams **retention schedule** (how long, what
  end-of-life action), and the Teams **DLP intent** (which content, audit vs block). This is the
  Teams-specific instance of category GR item 6.
- **Why required:** Retention durations, records determinations, legal-hold interactions, and IB
  policy definitions are **legal/compliance decisions**; the technical steps implement them but must
  not invent them.
- **Verify:** Confirm named approvers and the written schedule/segment/DLP definitions exist before
  configuring.
- **Implement if missing:** Identify the owners and capture the determinations before any policy is
  created.
