# 2. Requirements Guide — Data-Owner & Steward Framework (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 Purview foundation already stood up (roles, audit, workloads connected)
**Description:** A working Purview foundation — the portal organized, least-privilege role groups in
place, the unified audit log enabled, and the in-scope M365 workloads connected. This framework operates
*on top of* that foundation.
**Why:** You cannot assign accountability for controls that aren't connected or visible; the audit log is
what evidences the cadence. (Extends Global Requirements 2, 4.)
**Verify:** In the Purview portal the capabilities in scope (Information Protection, DLP, Data Lifecycle,
Unified Catalog) appear and render; role groups resolve. Run `DGSTEWARD-Assess-Ownership.ps1` — it reports
connectivity and the objects it can see.
**Implement:** If the foundation is not in place, stand it up first (the *Implementing Microsoft Purview:
Foundation, Roles & Onboarding* solution) before running this framework.

## 2.2 Compliance licensing for the surfaces in scope
**Description:** The **compliance licensing** each in-scope surface requires — E3 for baseline label/DLP,
**Microsoft 365 E5 / E5 Compliance** for advanced DLP, auto-labeling, records management, and Audit
Premium; and, for the Unified Catalog / Data Governance side, an **Azure subscription** for the
**consumption-based** Data Governance billing.
**Why:** Purview capabilities are plan-gated; the framework must record which surfaces are actually
available so ownership is assigned only to controls you can operate (Global Requirement 1).
**Verify:** M365 admin center → `Billing → Licenses`; confirm each capability appears in the Purview
portal. For Data Governance, confirm the linked Azure subscription and that consumption billing is
understood. **Verify against your own tenant and plan — capability/pricing availability evolves.**
**Implement:** Assign/purchase the required licensing; where a surface is unlicensed, record it as
out-of-scope for ownership assignment for now rather than attempting to enable it.

## 2.3 Least-privilege stewardship roles (compliance side)
**Description:** Access to assign members to the built-in S&C role groups the framework uses —
**Compliance Administrator** (to operate), **Information Protection Admin**, **Records Management**, and
the visibility roles (**Content Explorer Content Viewer / List Viewer**) — with Global Administrator
reserved for the rare tenant-wide action. Per Global Requirement 2.
**Why:** Assigning stewardship means adding named people to the correct least-privilege role group; over-
granting Global Administrator undermines the accountability model you are building.
**Verify:** Purview portal → `Settings → Roles & scopes → Role groups` (verify path in your tenant);
`Connect-IPPSSession` succeeds and `Get-RoleGroup` returns the groups.
**Implement:** Add the operating account to **Compliance Administrator**; reserve Global Administrator
for one-time actions only.

## 2.4 Unified Catalog governance-domain roles (data-governance side, if in scope)
**Description:** Where the **Unified Catalog / Data Governance** is in scope, the governance-domain-level
roles — **governance domain owner**, **data owner**, **data steward**, **data reader** — assigned at the
**domain** level, plus a minimal account-level admin group.
**Why:** Catalog stewardship is scoped by governance domain; assigning owners/stewards there is how
accountability is recorded for catalogued assets.
**Verify:** Purview portal → Unified Catalog → the governance domain → its roles (verify the exact path
and role names in your tenant — the Data Governance experience is evolving and partly in preview).
**Implement:** Create the governance domain(s) and assign the domain roles to named people. The
*determination* of who owns a domain is a business decision; you implement the assignment.

## 2.5 Microsoft Graph toolchain and read scopes
**Description:** The **Microsoft Graph PowerShell SDK** with a modern-auth/MFA admin, and the delegated
read scopes the assessment/report scripts use: `Organization.Read.All`, `Directory.Read.All`,
`User.Read.All`, `Group.Read.All` (to resolve named owners/stewards to real identities). No write scope
is required for the read-only scripts. Per Global Requirement 3.
**Why:** The assessment, accountability, and cadence reports read licensing, group, and (where available)
governance-domain data through Graph; keeping to read scopes matches the safe-by-default posture.
**Verify:** `Connect-MgGraph` succeeds with the scopes; `DGSTEWARD-Report-Accountability.ps1` (read-only)
reports if consent is missing.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent at first `Connect-MgGraph`
(admin consent once in Entra → Enterprise applications if required).

## 2.6 The in-scope data assets and control inventory
**Description:** The **data assets and Purview controls** the framework will assign ownership for — the
in-scope SharePoint sites/Teams/domains, the sensitivity labels, DLP policies, retention policies, and
governance domains — plus the **classification/sensitivity intent** that drives which are highest
priority. Per Global Requirement 4.
**Why:** You cannot assign an owner to an asset you have not enumerated; the assessment script builds the
inventory the RACI is applied against.
**Verify:** Run `DGSTEWARD-Assess-Ownership.ps1` — it inventories labels, DLP/retention policies, and (via
Graph, where available) governance domains, and flags which have no recorded owner/steward.
**Implement:** Confirm the in-scope list with stakeholders before authoring the RACI.

## 2.7 Named stakeholders and the RACI authority
**Description:** Engagement with the **compliance, records, privacy, security, and legal** stakeholders
and the business **data owners** who will be named in the RACI, plus the authority who approves it. Per
Global Requirement 5.
**Why:** A RACI is only real if the named Accountable/Responsible parties have agreed to it and an
authority has ratified it; sensitive-role membership (insider risk, communication compliance, eDiscovery)
must be confirmed by HR/privacy/legal.
**Verify:** Confirm the named owners/stewards per domain and the approver of `Data-Owner/Steward RACI –
Design`.
**Implement:** Identify the owners and capture their agreement before configuring assignments. The
*determination* of who holds a role is theirs; you implement it.

## 2.8 A pilot scope and review cadence agreed
**Description:** A **bounded pilot scope** (one or two governance domains / a small named asset set) to
validate the framework on, and an **agreed review cadence** (e.g. quarterly re-certification, monthly gap
chase — the interval is a business decision) with a change-control path. Per Global Requirement 6.
**Why:** The framework is validated on a ring before estate-wide rollout, and the cadence must have an
owner and an interval or it will not run.
**Verify:** Confirm the named `Stewardship Pilot Domain – Stage1`, the cadence interval, and who owns
running it.
**Implement:** Define the pilot and agree the cadence and change control before expanding.
