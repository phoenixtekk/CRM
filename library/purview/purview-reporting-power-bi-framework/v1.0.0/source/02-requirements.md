# 2. Requirements Guide — Microsoft Purview Reporting & Power BI Framework

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (GR1–GR6);
this guide adds the solution-specific ones. Purview reporting sources are **licensing-/plan-dependent**
and some are in preview — where a source is gated, verify availability in *your* tenant rather than
assuming it.

## 2.1 Compliance licensing for the in-scope reporting sources (GR1)
**Description:** Microsoft 365 licensing that exposes each source you intend to report on — E3 for
baseline audit/alerts; **E5 / E5 Compliance** for Activity Explorer (DLP & label activity), advanced
alerts, Audit Premium, and DSPM/insider-risk aggregates.
**Why:** Every dashboard page is only as available as its source; an unlicensed source returns no data.
**Verify:** In the Purview portal confirm each capability's report/page loads (e.g. **Activity
Explorer**, **Alerts**, **Audit**); in the M365 admin center confirm the E5/E5 Compliance add-on.
**Implement:** Assign/purchase the required plan before building the page that depends on it; until
then, mark that page "not licensed — verify tenant" rather than populating it.

## 2.2 Least-privilege Purview reporting roles (GR2)
**Description:** A reporting account holding the **read** roles the sources need — typically
**Compliance Administrator** or **Compliance Data Administrator** (or the granular **View-Only** report
roles), plus **Audit Reader / Audit Manager** for the audit log and **Security Reader** for Graph
security data. Global Administrator is **not** required for read-only reporting.
**Why:** Purview uses fine-grained role groups; each export cmdlet/endpoint checks the matching role.
**Verify:** Purview portal → **Roles & scopes → Permissions** shows the role group membership;
`Search-UnifiedAuditLog` and `Export-ActivityExplorerData` run without an access error.
**Implement:** Assign the least-privilege role groups under change control; keep the reporting identity
separate from any insider-risk / communication-compliance case role (see 2.7).

## 2.3 Security & Compliance PowerShell + Microsoft Graph toolchain (GR3)
**Description:** An admin workstation with **ExchangeOnlineManagement** (provides `Connect-IPPSSession`
and `Search-UnifiedAuditLog`) and **Microsoft.Graph** PowerShell SDK, using modern-auth / MFA.
**Why:** All five scripts pull data through `Connect-IPPSSession` (S&C PowerShell) and `Connect-MgGraph`
(Graph).
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` both succeed with the reporting account;
`Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Authentication`.
**Implement:** `Install-Module ExchangeOnlineManagement, Microsoft.Graph -Scope CurrentUser`.

## 2.4 Graph permission scopes (consented, read-only)
**Description:** Delegated read scopes for the Graph sources: `SecurityEvents.Read.All` (alerts),
`SecurityActions.Read.All` / `SecureScore` via `SecurityEvents.Read.All`, and `AuditLog.Read.All`
where the Graph audit-query API is used. No write scope is needed for reporting.
**Why:** The framework is read-only against Graph; these scopes pull alerts, secure score, and audit
data without granting any change capability.
**Verify:** Run `OPSREPORT-Discovery.ps1` (read-only) — it connects and reports which scopes are
consented and which are missing.
**Implement:** Consent at first `Connect-MgGraph`; if admin consent is required, an admin approves the
read scopes once in Entra (**Identity → Applications → Enterprise applications**).

## 2.5 Power BI licensing and a workspace path
**Description:** **Power BI Desktop** (free) to build the model, and **Power BI service** capacity to
host it — a **Pro** licence for pilot/small audiences or **Premium/Fabric capacity** (PPU/F-SKU) for
scheduled refresh at scale — plus the ability to create the pilot and production workspaces.
**Why:** The dashboards are Power BI; scheduled refresh and sharing require the service and the right
capacity.
**Verify:** You can create a workspace in the Power BI service and publish a report to it; a Pro/PPU
licence is assigned to the publishing account.
**Implement:** Assign Power BI Pro/PPU (or provision Premium/Fabric capacity); create the
`Purview Reporting – Pilot – Stage1` workspace. The optional `MicrosoftPowerBIMgmt` module lets
`OPSREPORT-Configuration.ps1` create the workspace for you.

## 2.6 An export storage location and the dataset contract
**Description:** A governed location for the exports (a secured folder, SharePoint document library, or
storage account) that Power BI can read, and agreement on the **dataset shape** (the fixed columns each
source contributes) recorded as `Purview Compliance Dataset – Report`.
**Why:** The exports are the single source of truth the dashboards bind to; a stable column contract is
what keeps the model from breaking when a portal report layout changes.
**Verify:** The location exists, the reporting identity can write to it, and Power BI can read from it;
the dataset column list is documented.
**Implement:** Provision the location with least-privilege access; record the dataset contract before
building dashboards (the implementation guide specifies the columns per source).

## 2.7 Privacy & role separation for HR-sensitive sources
**Description:** For insider-risk and communication-compliance sources, a decision that only
**aggregate counts** (e.g. number of alerts by severity) are reported — never case content, subjects,
or reviewers — and that the reporting identity has **no** insider-risk/communication-compliance case
role.
**Why:** These capabilities are HR/privacy-sensitive; reporting must preserve privacy-by-design and
strict role separation, with outcomes deferred to HR/legal.
**Verify:** The reporting account is not a member of any insider-risk or communication-compliance role
group; only aggregate counts are configured for those pages.
**Implement:** Keep the roles separated; where an aggregate is needed, export the count only (portal
aggregate export), not the underlying records.

## 2.8 Compliance, records, privacy & legal stakeholders and a pilot scope (GR5, GR6)
**Description:** Named compliance/records/privacy/legal stakeholders who own what each number *means*,
a **pilot audience** for the dashboards, and a change window to promote to production.
**Why:** The framework reports the data; the interpretation and any action are the stakeholders'. A
pilot validates accuracy before leadership sees it.
**Verify:** Stakeholders and a pilot audience are named; the pilot workspace is agreed as the first
target.
**Implement:** Identify owners and the pilot audience before publishing; agree the promotion path to
production.

---
## Checklist
- [ ] Compliance licensing confirmed for each in-scope source (E5/E5 Compliance where required) — GR1
- [ ] Least-privilege reporting roles assigned (Compliance/Audit/Security Reader) — GR2
- [ ] ExchangeOnlineManagement + Microsoft.Graph installed; `Connect-IPPSSession` / `Connect-MgGraph` succeed — GR3
- [ ] Graph read scopes consented (`SecurityEvents.Read.All`, `AuditLog.Read.All`)
- [ ] Power BI Desktop + Pro/PPU (or Premium/Fabric capacity); pilot workspace creatable
- [ ] Export storage location provisioned; `Purview Compliance Dataset – Report` contract recorded
- [ ] Insider-risk / comm-compliance = aggregate-only; reporting identity role-separated
- [ ] Stakeholders + pilot audience named; promotion change window agreed — GR5/GR6
