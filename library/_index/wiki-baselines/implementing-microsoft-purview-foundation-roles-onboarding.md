# Implementing Microsoft Purview — Foundation, Roles & Onboarding

> **Version 1.0.0** · Category: Purview · Solution code: PURVIMP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Implementing Microsoft Purview: Foundation, Roles & Onboarding

Microsoft Purview is powerful and sprawling, and most organizations turn on pieces of it ad hoc —
a label here, a DLP policy there, a handful of people made Global Administrator — with no foundation
underneath. The result is over-granted access to sensitive compliance data, core services that were
never enabled (so there is no audit history to investigate), and no baseline to measure compliance
against. This solution is the **entry point** for Microsoft Purview: it stands the platform up properly
so every capability you add later lands on solid ground.

It gives you a repeatable way to organize the **Purview portal**, establish **least-privilege role
groups and RBAC** across compliance, records, insider risk, eDiscovery, and audit, enable the **core
data services** (the unified audit log and the Content/Activity Explorer visibility surfaces), baseline
**Compliance Manager**, and connect the **in-scope workloads** — using only the Microsoft Purview
portal, the Microsoft 365 admin center, Security & Compliance PowerShell, and Microsoft Graph.

This is a complete, deploy-it-today package for the foundational Purview implementation, written for a
competent M365/compliance administrator standing Purview up for the first time.

## What you get
- A plain-language Solution Overview of the Purview portal and capability map, the least-privilege
  role/RBAC model, the core data services, and the phased-adoption approach.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, including which
  capabilities your licensing actually unlocks.
- An Implementation Guide of precise, ordered portal + PowerShell + Graph steps, with roles applied
  pilot-first and each role group and workload named.
- Five PowerShell scripts: readiness/licensing/role assessment, a least-privilege role-group setup
  helper (`-WhatIf` by default), a core-services enablement checker/enabler, a compliance-signal
  baseline report, and a workload scope/health helper.
- Testing and Troubleshooting guides for a confident, safe rollout.

## What this delivers
An understood tenant (which Purview capabilities your plan unlocks), a least-privilege role matrix with
sensitive roles (insider risk, communication compliance, eDiscovery) named and separated, the unified
audit log ingesting from day one, Content and Activity Explorer visible to the right reviewers, a
captured Compliance Manager baseline, and a mapped set of connected in-scope workloads — validated on a
pilot ring before the tenant is treated as production-ready.

## The deployment model
Assess → Design → Configure → Pilot → Validate → Expand.

## Scope boundary
This is the **foundation**, not the capabilities. Building the label taxonomy, authoring DLP and
retention policies, standing up records management, insider risk, communication compliance, running
eDiscovery, DSPM, and data governance are each the subject of a dedicated Purview solution that builds
on this foundation and pilots high-impact policies in simulation/test/disabled mode first. Regulatory,
records, and legal determinations are deferred to the organization's compliance, records, privacy, and
legal functions — this solution provides the technical method and evidence, not the determination.

## Outcome
Microsoft Purview stood up the right way — portal organized, roles least-privileged and separated, core
services on, Compliance Manager baselined, workloads connected — so every Purview capability you add
next builds on a solid, defensible foundation.


---


# 1. Solution Overview — Implementing Microsoft Purview: Foundation, Roles & Onboarding

## What this solution is
Microsoft Purview is a broad suite of compliance and data-governance capabilities — sensitivity and
retention labels, data loss prevention (DLP), data lifecycle and records management, insider risk,
communication compliance, audit, eDiscovery, data security posture management, and data governance.
Most organizations turn these on piecemeal: someone enables a label here, a DLP policy there, grants a
handful of people Global Administrator, and never establishes an operating foundation underneath. This
solution is the **entry point** for the Purview line — it stands up Purview *properly* so every
capability you add later lands on solid ground:

- Organize the **Microsoft Purview portal** (purview.microsoft.com) and build a capability map.
- Establish **least-privilege role groups and RBAC** across compliance, records, insider risk,
  eDiscovery, and audit — instead of over-granting Global Administrator.
- Enable the **core data services** every capability depends on: the unified audit log, and the
  **Content Explorer** and **Activity Explorer** visibility surfaces.
- Baseline **Compliance Manager** so you have a starting compliance posture to improve against.
- Connect the **in-scope workloads** (Exchange Online, SharePoint, OneDrive, Teams, and endpoints).
- Set the **phased-adoption foundation** the rest of the Purview capabilities build on.

Everything is done with the Microsoft Purview portal, the Microsoft 365 admin center, **Security &
Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **This is the foundational deployment, not the deep-dive.** It establishes the portal, roles, core
> services, baseline, and workload connections. The *configuration* of each capability — building the
> label taxonomy, authoring DLP policies, defining retention schedules and records file plans, standing
> up insider-risk and communication-compliance policies, running eDiscovery cases, and data governance
> — is the subject of the dedicated Purview solutions that build on this foundation. Where this guide
> reaches the edge of a capability, it points to that capability's own solution rather than duplicating
> it.

## Why this matters
- **Roles are the highest-risk shortcut.** Purview uses fine-grained role groups for a reason: insider
  risk, communication compliance, and eDiscovery expose sensitive employee data. Granting broad admin
  to avoid learning the role model is the single most common — and most dangerous — foundation mistake.
- **The core services are silent prerequisites.** Content Explorer, Activity Explorer, and audit search
  are what let you *see* what labels, DLP, and retention are doing. If the unified audit log was never
  turned on, you have no history to investigate — and history cannot be back-filled.
- **A baseline turns compliance into a measurable program.** Compliance Manager gives a starting score
  and improvement actions; without a captured baseline, "are we more compliant than last quarter?" has
  no answer.
- **Workload scope drives everything downstream.** Labels, DLP, and retention key off the in-scope
  workloads. Getting the scope and connections right once, at the foundation, saves re-work in every
  capability that follows.

## How it works
1. **Assess.** Read the tenant's compliance licensing (which Purview capabilities are actually
   available on the current plan), the existing role-group assignments, the audit-log status, and the
   in-scope workloads — read-only, no changes.
2. **Design.** Map capabilities to the licensing you have, and design a **least-privilege role matrix**:
   who needs which built-in role group, with Global Administrator reserved for the few genuinely
   tenant-wide actions.
3. **Configure.** Populate the role groups, enable the unified audit log, confirm the Content/Activity
   Explorer visibility roles, and connect the in-scope workloads — role/RBAC changes applied with a
   `-WhatIf` preview first.
4. **Pilot.** Validate the foundation on a **pilot ring** (a small set of named admins and one or two
   in-scope sites/teams) before treating the tenant as production-ready. High-impact capability policies
   (DLP, labels, retention, insider risk) are always piloted in **simulation/test/disabled** mode in
   their own solutions — this foundation just proves the plumbing.
5. **Validate.** Confirm each role group resolves to the right people, the audit log is ingesting, the
   Explorers render, and Compliance Manager shows a captured baseline.
6. **Expand.** Hand off to the capability solutions (labels, DLP, retention/records, insider risk,
   communication compliance, audit investigations, DSPM, data governance) with the foundation in place.

## The least-privilege role model (foundation)
Prefer the **built-in Purview/compliance role groups** and add members to them — create custom role
groups only where you need tighter scoping. The foundation set:

| Function | Built-in role group | Who it is for |
|---|---|---|
| Compliance administration | **Compliance Administrator** | Foundation admins who configure Purview |
| Classification data | **Compliance Data Administrator** | Manage device onboarding, data classification |
| Information protection | **Information Protection Admin** | Owners of the future label program |
| Records | **Records Management** | Records/retention owners (deep work deferred) |
| Insider risk | **Insider Risk Management** | HR/security analysts — strictly separated |
| eDiscovery | **eDiscovery Manager** | Legal/investigations — strictly separated |
| Audit | **Audit Manager** / **Audit Reader** | Audit investigators / read-only reviewers |
| Classification visibility | **Content Explorer Content Viewer** + **Content Explorer List Viewer** | See what is classified where |
| Communication compliance | **Communication Compliance** | HR/compliance — strictly separated |

> **Separation of duties is a design rule, not a nicety.** Insider Risk, Communication Compliance, and
> eDiscovery see sensitive employee content. Their role groups are kept **separate** from general
> compliance administration, membership is minimal and named, and — for insider risk and communication
> compliance — privacy-by-design (pseudonymization where the capability supports it) is applied in that
> capability's own solution. The *determination* of who may hold these roles is deferred to HR, privacy,
> and legal.

## What you can control
- Which compliance licensing tier the tenant runs on (E3 baseline vs E5 / E5 Compliance) and therefore
  which capabilities are in scope.
- The membership of each role group (least-privilege, named individuals or groups).
- Which workloads are in scope (Exchange, SharePoint, OneDrive, Teams, endpoints).
- The unified audit log retention (default vs extended, licensing-dependent).
- The pilot ring used to validate the foundation before broad adoption.

## Limitations (be honest with buyers)
- **Purview is heavily licensing-gated.** Many capabilities (advanced DLP, auto-labeling, insider risk,
  communication compliance, Audit Premium/long-term retention, DSPM) require **Microsoft 365 E5** or the
  **E5 Compliance** add-on; some are in preview. This solution enables the *foundation* and flags which
  capabilities your licensing unlocks — **verify availability against your own tenant and plan.**
- **The portal is evolving.** Microsoft is actively changing the Purview portal and transitioning parts
  of role management to a unified Purview RBAC model. Portal paths and role-management surfaces are
  cited as of authoring and flagged **"verify in your tenant"** — never invented.
- **Compliance Manager has no fully GA PowerShell/Graph write surface.** Its assessments and improvement
  actions are managed and exported from the **portal**; this solution captures a compliance-signal
  baseline (Secure Score, audit status, role posture) and records the Compliance Manager score from the
  portal export — it does not programmatically author assessments.
- **Records, retention, legal-hold, and insider-risk determinations are deferred.** This foundation
  provides the technical method and evidence; retention schedules, records file plans, legal holds, and
  insider-risk/communication-compliance case actions are decided by compliance, records, privacy, and
  legal.

## Naming convention (used in every doc and script)
Artifacts this solution creates or captures follow `<Purpose> – Purview – <Stage>` and are reused
verbatim across the docs, scripts, and portal.

| Artifact | Name |
|---|---|
| Readiness / licensing / role assessment export | `Purview Readiness – Foundation – Assess` |
| Role assignment matrix | `Purview Role Matrix – Design` |
| Core-services enablement baseline | `Purview Core Services – Enablement` |
| Compliance-signal baseline snapshot | `Purview Compliance Baseline – Report` |
| Workload scope map | `Purview Workload Scope – Map` |
| Foundation pilot ring | `Purview Pilot Ring – Stage1` |

## The standard deployment model
> Assess the tenant → design the role/RBAC model → configure roles, core services, and workload
> connections → pilot on a small ring → validate every gate → expand to the capability solutions.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Implementing Microsoft Purview: Foundation, Roles & Onboarding

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 Compliance licensing inventory (which capabilities are actually available)
**Description:** A confirmed inventory of the tenant's **compliance licensing** — E3 for baseline
capabilities, **Microsoft 365 E5** or the **E5 Compliance** add-on for advanced DLP, auto-labeling,
insider risk, communication compliance, Audit Premium (long-term retention), and DSPM.
**Why:** Purview capabilities are plan-gated; the foundation must record what the current plan unlocks
so downstream capability solutions are scoped to what you can actually use (Global Requirement 1).
**Verify:** Microsoft 365 admin center → `Billing → Licenses` shows the subscriptions/add-ons; run
`PURVIMP-Assess-Readiness.ps1` — it reads `subscribedSkus` via Graph and reports which compliance SKUs
are present. Confirm capabilities appear in the Purview portal.
**Implement:** Assign/purchase the required licensing before enabling a capability that needs it. Where
a capability is not licensed, record it as out-of-scope for now rather than attempting to enable it.

## 2.2 Least-privilege Purview admin access (not blanket Global Admin)
**Description:** An account holding **Compliance Administrator** (to configure Purview) plus, for the
one-time setup actions that require it, a **Global Administrator** who enables the unified audit log and
consents Graph scopes. Everyday configuration uses the least-privilege compliance role, per Global
Requirement 2.
**Why:** Purview's fine-grained role model exists to limit exposure to sensitive compliance data;
over-granting Global Administrator undermines the foundation you are building.
**Verify:** Purview portal → `Settings → Roles & scopes → Role groups` (verify path in your tenant) —
confirm your account is in **Compliance Administrator**. `Connect-IPPSSession` succeeds.
**Implement:** Add the account to **Compliance Administrator**; reserve a named Global Administrator only
for the audit-enablement and Graph-consent steps.

## 2.3 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (provides
`Connect-IPPSSession` for Security & Compliance PowerShell **and** `Connect-ExchangeOnline` for the
audit-config cmdlets) and the **Microsoft Graph PowerShell SDK**, with a modern-auth/MFA admin account
(Global Requirement 3).
**Why:** Every script in this solution runs through S&C PowerShell, Exchange Online PowerShell, and/or
Graph.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Authentication`;
`Connect-IPPSSession` and `Connect-MgGraph` both succeed. `PURVIMP-Assess-Readiness.ps1` installs
missing modules and reports connectivity.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph -Scope CurrentUser`; confirm modern-auth sign-in.

## 2.4 Graph permission scopes (consented, read-first)
**Description:** Delegated Graph scopes for the read-only assessment and baseline:
`Organization.Read.All`, `Directory.Read.All`, `User.Read.All`, `RoleManagement.Read.Directory`,
`SecurityEvents.Read.All` (Secure Score). No write scopes are required for the foundation scripts.
**Why:** The readiness, baseline, and scope scripts read licensing, role, and Secure Score data through
Graph; keeping to read scopes matches the safe-by-default posture.
**Verify:** Run `PURVIMP-Report-ComplianceBaseline.ps1` (read-only) — it connects with the read scopes
and reports if consent is missing.
**Implement:** Consent at first `Connect-MgGraph`; if admin consent is required, a Global Administrator
approves the scopes once in Entra (`Identity → Applications → Enterprise applications`).

## 2.5 In-scope workloads and endpoint onboarding intent
**Description:** The **workloads in scope** for Purview — Exchange Online, SharePoint Online, OneDrive,
Teams (connected by virtue of being M365 workloads) and **endpoints/devices** (which require explicit
onboarding to Purview) — plus the classification/sensitivity intent that will drive labels, DLP, and
retention later (Global Requirement 4).
**Why:** Purview policies key off the in-scope workloads; endpoints in particular are not automatically
connected and must be onboarded before endpoint DLP can see them.
**Verify:** Run `PURVIMP-Scope-Config.ps1` — it confirms the M365 workloads and reports device
onboarding status from the Purview device-onboarding surface. Confirm the in-scope list with
stakeholders.
**Implement:** Define the scope; plan endpoint onboarding (Purview portal → `Settings → Device
onboarding`, verify path) for a later endpoint-DLP solution — the foundation records readiness, it does
not roll out device onboarding tenant-wide.

## 2.6 Unified audit log — enable early
**Description:** The **unified audit log** turned on so activity is recorded from day one (search and
long-term retention are licensing-dependent).
**Why:** Audit history **cannot be back-filled** — if ingestion was never enabled, the record simply
does not exist. Content Explorer, Activity Explorer, and every investigation depend on it.
**Verify:** `PURVIMP-Enable-CoreServices.ps1` (read-only by default) reports
`UnifiedAuditLogIngestionEnabled`; in the portal, audit search returns results.
**Implement:** Enable with `PURVIMP-Enable-CoreServices.ps1 -Commit` (wraps
`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`) — a one-time action; ingestion can take
up to ~24 hours to begin surfacing results.

## 2.7 Content Explorer / Activity Explorer visibility roles
**Description:** The role groups that grant visibility into classified content — **Content Explorer
Content Viewer** and **Content Explorer List Viewer** — assigned to the people who need to see what is
classified where (Activity Explorer visibility comes with the data-classification roles).
**Why:** These Explorers are the foundation's *observability*; without the viewer roles, admins cannot
see classification results even though the data is being classified.
**Verify:** Run `PURVIMP-Enable-CoreServices.ps1` — it reports whether the viewer role groups exist and
have members. In the portal, `Data classification → Content explorer` renders.
**Implement:** Add the intended reviewers to the viewer role groups with `PURVIMP-Set-RoleGroups.ps1`.

## 2.8 Stakeholders and a captured Compliance Manager baseline
**Description:** Engagement with **compliance, records, privacy, security, and legal** stakeholders
(Global Requirement 5), and a **captured Compliance Manager baseline** score/assessment exported from
the portal.
**Why:** The foundation aligns to enterprise policy, not technical defaults; the captured baseline makes
future compliance improvement measurable. Regulatory/records/legal determinations are the stakeholders'
to make.
**Verify:** Named approvers are recorded; Purview portal → `Compliance Manager` shows a score, and you
have exported the assessment (`Assessments → Export`). `PURVIMP-Report-ComplianceBaseline.ps1` captures
the supporting signals (Secure Score, audit status, role posture).
**Implement:** Identify owners; open Compliance Manager, note the current score and the default
data-protection baseline assessment, export it, and store it as `Purview Compliance Baseline – Report`.

## 2.9 A pilot ring and change control
**Description:** A small **pilot ring** (`Purview Pilot Ring – Stage1`) — a handful of named admins and
one or two in-scope sites/teams — and a **change-control** process, per Global Requirement 6.
**Why:** The foundation is validated on the ring before the tenant is treated as production-ready; every
downstream capability policy is piloted in simulation/test/disabled mode in its own solution.
**Verify:** The ring is defined and a change window/approval path exists.
**Implement:** Define the ring and agree change control before applying role or service changes.

---
## Checklist
- [ ] Compliance licensing inventoried; available capabilities recorded (E3 vs E5 / E5 Compliance)
- [ ] Compliance Administrator access confirmed; Global Admin reserved for one-time setup
- [ ] ExchangeOnlineManagement + Microsoft Graph SDK installed; `Connect-IPPSSession` / `Connect-MgGraph` succeed
- [ ] Graph read scopes consented (no write scopes needed for the foundation)
- [ ] In-scope workloads agreed; endpoint onboarding readiness assessed
- [ ] Unified audit log enabled (or scheduled to enable early)
- [ ] Content/Activity Explorer viewer roles assigned
- [ ] Stakeholders named; Compliance Manager baseline exported as `Purview Compliance Baseline – Report`
- [ ] `Purview Pilot Ring – Stage1` defined; change control agreed


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


# 3. Implementation Guide — Implementing Microsoft Purview: Foundation, Roles & Onboarding

Follow these steps **in order**. Assessment and baseline come from the **Microsoft Purview portal**
(purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
(`Connect-IPPSSession`), **Exchange Online PowerShell** (`Connect-ExchangeOnline`, for the audit
cmdlets), and **Microsoft Graph**. Role changes are previewed with `-WhatIf` before `-Commit`. Artifact
names follow the `<Purpose> – Purview – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Assess the tenant, design the least-privilege role/RBAC model, configure roles + core
> services + workload connections, validate on a **pilot ring**, confirm every gate, then hand off to
> the capability solutions. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
>
> **Portal paths are cited as of authoring and the Purview portal is evolving — verify each path in your
> own tenant.** Capability availability is licensing-dependent — verify against your plan (Requirement
> 2.1). This foundation enables plumbing only; DLP/label/retention/insider-risk *policies* are piloted
> in simulation/test in their own solutions.

## Step 1 — Assess the tenant (Assess)
1. Open the **Microsoft Purview portal** (`https://purview.microsoft.com`) and orient: the left rail
   lists the capabilities (Information Protection, Data Loss Prevention, Data Lifecycle Management,
   Records Management, Insider Risk Management, Communication Compliance, Audit, eDiscovery, Data Map /
   Unified Catalog, DSPM). Confirm which appear — visibility tracks your licensing.
2. Run `PURVIMP-Assess-Readiness.ps1 -CsvPath .\PurviewReadiness.csv`. Read-only, it captures:
   compliance SKUs present (E3/E5/E5 Compliance), the existing role groups and their members, the
   unified-audit-log status, and connectivity to S&C PowerShell + Graph. It writes
   `Purview Readiness – Foundation – Assess`.
3. Record which capabilities your licensing unlocks and which are out-of-scope for now. **Pass/fail:**
   you can state, per capability, "available on this plan" or "not licensed — deferred."

## Step 2 — Design the least-privilege role matrix (Design)
1. Using the readiness output and the role model in the Overview, build the **role assignment matrix**
   `Purview Role Matrix – Design`: for each function (compliance admin, classification data,
   information protection, records, insider risk, eDiscovery, audit, classification visibility,
   communication compliance) list the built-in role group and the **named** members (individuals or
   security groups).
2. Apply separation of duties: **Insider Risk Management**, **Communication Compliance**, and
   **eDiscovery Manager** membership is minimal, named, and kept **separate** from general compliance
   administration. Membership determinations for these sensitive roles are **confirmed with HR, privacy,
   and legal** — you implement the assignment, they make the call.
3. Reserve **Global Administrator** for only the two one-time setup actions (enabling the unified audit
   log, consenting Graph scopes). **Pass/fail:** every function maps to a least-privilege role group and
   named members; no capability relies on blanket Global Admin.

## Step 3 — Preview and apply role groups (Configure, pilot-first)
1. Dry-run first: `PURVIMP-Set-RoleGroups.ps1 -MatrixPath .\Purview-Role-Matrix.csv -WhatIf`. With
   `-WhatIf` (the default) it makes **no changes** — it prints exactly which member would be added to
   which role group and flags any built-in group that does not yet exist in your tenant.
2. Read every line against `Purview Role Matrix – Design`. Confirm no unintended broad grant and that
   the sensitive-role rows match the HR/legal-approved list.
3. Apply to the **pilot ring first**: run with `-Commit` scoped to the `Purview Pilot Ring – Stage1`
   admins, using `Add-RoleGroupMember` under the hood. Only create a **custom** role group
   (`New-RoleGroup`) where you need tighter scoping than a built-in group provides.
4. **Pass/fail + rollback:** `Get-RoleGroupMember` returns exactly the intended pilot members. Rollback
   is `Remove-RoleGroupMember` for any member added in error (the script prints the exact reverse
   command for each add).

## Step 4 — Enable the core data services (Configure)
1. Check status read-only: `PURVIMP-Enable-CoreServices.ps1`. It reports
   `UnifiedAuditLogIngestionEnabled`, audit retention posture, and whether the **Content Explorer
   Content Viewer** / **Content Explorer List Viewer** role groups exist and have members.
2. If the unified audit log is off, enable it (one-time, Global Admin):
   `PURVIMP-Enable-CoreServices.ps1 -Commit` → wraps
   `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`. Ingestion can take up to ~24 hours
   to begin surfacing results — enable it **early**.
3. Assign the Content/Activity Explorer viewer roles (Step 3 covers the mechanism) to the reviewers in
   the matrix, so `Data classification → Content explorer` and `→ Activity explorer` render for them
   (verify path). Writes/updates `Purview Core Services – Enablement`.
4. **Pass/fail:** audit ingestion reports `True`; the Explorer viewer role groups have the intended
   members; Content/Activity Explorer load for a viewer.

## Step 5 — Connect and confirm the in-scope workloads (Configure)
1. Run `PURVIMP-Scope-Config.ps1 -CsvPath .\PurviewScope.csv`. Read-only, it confirms the M365 workloads
   (Exchange, SharePoint, OneDrive, Teams) are present and reports **endpoint device onboarding**
   readiness from the Purview device-onboarding surface. It writes `Purview Workload Scope – Map`.
2. For endpoints, record onboarding **readiness** (whether devices are onboarded to Purview for future
   endpoint DLP) — actual tenant-wide device onboarding is executed in the endpoint-DLP solution, not
   here. Confirm the in-scope workload list with stakeholders.
3. **Pass/fail:** the scope map lists every in-scope workload with a connected/onboarded/ready status;
   any gap (e.g. endpoints not yet onboarded) is recorded as a hand-off item.

## Step 6 — Baseline Compliance Manager (Configure)
1. Open Purview portal → **Compliance Manager**. Note the current **compliance score** and the default
   **data protection baseline** assessment (verify the assessment name/availability against your
   licensing). Export the assessment: `Assessments → Export`.
2. Run `PURVIMP-Report-ComplianceBaseline.ps1 -CsvPath .\PurviewBaseline.csv -ComplianceScore <score>`
   to capture the supporting compliance signals — **Secure Score** (Graph `security/secureScores`),
   unified-audit status, and the role-group posture — alongside the portal score you supply. It writes
   `Purview Compliance Baseline – Report`.
3. Store the exported assessment plus the snapshot as your baseline. **Determinations about which
   regulations/assessments apply are the compliance team's** — you capture the baseline, they own the
   target. **Pass/fail:** a dated baseline (score + assessment export + signal snapshot) is stored.

## Step 7 — Validate the foundation on the pilot ring (Pilot → Validate)
1. Re-run `PURVIMP-Assess-Readiness.ps1` and confirm the role groups now resolve to the intended pilot
   members and the audit log reports enabled.
2. Have each pilot admin confirm they can perform exactly their function and **not** more (e.g. an
   eDiscovery manager cannot administer insider risk) — separation of duties holds.
3. Confirm Content/Activity Explorer render, audit search returns recent activity, and Compliance
   Manager shows the captured baseline. Complete the **Testing Guide** before expanding. **Pass/fail:**
   all Testing-Guide gates pass on the ring.

## Step 8 — Expand to the capability solutions (Expand)
1. With the foundation validated, broaden role-group membership from the pilot ring to the full named
   set (dry-run `-WhatIf`, then `-Commit`), and confirm audit/Explorer/baseline remain healthy.
2. Hand off to the dedicated Purview capability solutions — **sensitivity & retention labels, DLP,
   data lifecycle & records management, insider risk, communication compliance, audit
   standard/premium investigations, DSPM, and data governance (data map / catalog)** — each of which
   configures its capability on this foundation and pilots high-impact policies in
   simulation/test/disabled mode first. This solution deliberately **does not** duplicate that work.

---
### Order of operations
`Assess tenant → Design role matrix → Dry-run (-WhatIf) roles → Apply roles to pilot ring → Enable core
services (audit + Explorer roles) → Confirm workload scope → Baseline Compliance Manager → Validate on
ring → Expand membership + hand off to capability solutions`


---


# 5. Testing Guide — Implementing Microsoft Purview: Foundation, Roles & Onboarding

Run after building the readiness baseline and after each configuration step. Every test is safe
(read-only or a `-WhatIf` preview). Validate on the `Purview Pilot Ring – Stage1` before treating the
tenant as production-ready.

## Test 1 — Readiness is complete and licensing is understood
**Do:** Run `PURVIMP-Assess-Readiness.ps1`; compare its SKU list against `Billing → Licenses` in the
M365 admin center.
**Expected:** The compliance SKUs match the admin center; the script correctly reports E3 vs E5 / E5
Compliance, and you can name which Purview capabilities are available vs deferred.

## Test 2 — Role matrix dry-run makes no changes
**Do:** Run `PURVIMP-Set-RoleGroups.ps1 -MatrixPath .\Purview-Role-Matrix.csv -WhatIf`; afterward run
`Get-RoleGroupMember` on an affected role group.
**Expected:** The dry-run lists the intended additions and prints the reverse (`Remove-RoleGroupMember`)
command for each; membership is unchanged — `-WhatIf` truly changed nothing.

## Test 3 — Role groups resolve least-privilege
**Do:** After `-Commit` on the pilot ring, run `PURVIMP-Assess-Readiness.ps1` (or `Get-RoleGroupMember`).
**Expected:** Each function's role group contains exactly the intended named members; no pilot admin
holds a role beyond their function; the sensitive role groups (Insider Risk Management, Communication
Compliance, eDiscovery Manager) contain only the HR/legal-approved members and are separate from general
compliance administration.

## Test 4 — Unified audit log is ingesting
**Do:** Run `PURVIMP-Enable-CoreServices.ps1`; in the Purview portal run an audit search over the last
day (`Audit → Search`, verify path).
**Expected:** `UnifiedAuditLogIngestionEnabled` reports `True` and the audit search returns recent
events. (If just enabled, allow up to ~24 hours for results to appear.)

## Test 5 — Content and Activity Explorer render for viewers
**Do:** As a member of the Content Explorer viewer role groups, open `Data classification → Content
explorer` and `→ Activity explorer` (verify path).
**Expected:** Both surfaces load; a non-viewer account cannot open them — the visibility roles gate
access correctly.

## Test 6 — Workload scope map is accurate
**Do:** Run `PURVIMP-Scope-Config.ps1`; review `Purview Workload Scope – Map`.
**Expected:** Every in-scope workload (Exchange, SharePoint, OneDrive, Teams) shows connected; endpoint
onboarding status is reported accurately (onboarded / ready / not-yet-onboarded) and any gap is recorded
as a hand-off item.

## Test 7 — Compliance Manager baseline is captured
**Do:** Run `PURVIMP-Report-ComplianceBaseline.ps1 -ComplianceScore <portal score>`; open Compliance
Manager in the portal.
**Expected:** `Purview Compliance Baseline – Report` records the portal compliance score plus the
supporting signals (Secure Score, audit status, role posture), and the portal assessment export is
stored alongside it.

## Test 8 — Separation of duties holds
**Do:** Have a pilot eDiscovery manager attempt an insider-risk admin action, and an insider-risk
analyst attempt an eDiscovery action.
**Expected:** Each is denied outside their function — the least-privilege boundaries are effective.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Foundation pass** | Tests 1–8 pass on `Purview Pilot Ring – Stage1`: readiness understood, roles least-privileged and separated, audit ingesting, Explorers rendering, scope mapped, baseline captured |
| **Expand pass** | Tests 2–3 pass again after broadening role-group membership from the pilot ring to the full named set, with audit/Explorer/baseline still healthy — ready to hand off to the capability solutions |


---


# 6. Troubleshooting Guide — Implementing Microsoft Purview: Foundation, Roles & Onboarding

Field issues and how to resolve them, in the order you are likely to hit them. Every check here is safe.

## A capability is missing from the Purview portal
**Symptom:** A capability (insider risk, communication compliance, Audit Premium, DSPM, auto-labeling)
does not appear in the left rail, or shows "upgrade required."
**Cause:** It is not licensed on the current plan — Purview is heavily plan-gated (E5 / E5 Compliance;
some previews).
**Fix:** Run `PURVIMP-Assess-Readiness.ps1` and read the capability-availability lines; confirm the SKU
in `Billing → Licenses`. Record the capability as **deferred (not licensed)** rather than trying to
enable it. Verify availability against your own tenant and plan — the script's plan mapping is
indicative.

## `Connect-IPPSSession` or `Connect-ExchangeOnline` fails
**Symptom:** Connection errors, repeated auth prompts, or "module not found."
**Cause:** Missing/old ExchangeOnlineManagement module, or basic-auth/legacy sign-in.
**Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force`; use a modern-auth/MFA admin
account. Both cmdlets ship in that one module. Close and reopen PowerShell if a stale session is cached.

## `Connect-MgGraph` succeeds but data calls return 403 / "insufficient privileges"
**Symptom:** The readiness/baseline/scope scripts connect but a Graph call is denied.
**Cause:** The delegated scope was not consented (e.g. `SecurityEvents.Read.All`,
`DeviceManagementManagedDevices.Read.All`).
**Fix:** Re-run `Connect-MgGraph` with the scopes listed in the script header and consent; if admin
consent is required, a Global Administrator approves them once in Entra → Enterprise applications. The
foundation needs **read** scopes only.

## A role group named in the matrix "does not exist"
**Symptom:** `PURVIMP-Set-RoleGroups.ps1 -WhatIf` flags `[MISSING]` for a role group.
**Cause:** The built-in role-group name differs in your tenant, or the Purview portal has transitioned
that role into the unified Purview RBAC model, or the role belongs to a capability not licensed.
**Fix:** Verify the exact name in Purview portal → `Settings → Roles & scopes → Role groups` (verify
path) and correct the matrix, or create a custom scoped group with `New-RoleGroup`. Do not assume a
name — the portal is evolving.

## Audit search returns nothing after enabling the unified audit log
**Symptom:** `UnifiedAuditLogIngestionEnabled` reports `True` but an audit search is empty.
**Cause:** Ingestion was just enabled — results can take **up to ~24 hours** to begin appearing, and
history before enablement does not exist (it cannot be back-filled).
**Fix:** Wait and re-search; confirm with `PURVIMP-Enable-CoreServices.ps1`. This is exactly why the
Requirements and Best Practices say to enable audit **early**.

## Content Explorer / Activity Explorer shows "you don't have permission"
**Symptom:** A reviewer cannot open Content or Activity Explorer.
**Cause:** They are not in the **Content Explorer Content Viewer** / **Content Explorer List Viewer**
(or the data-classification) role groups.
**Fix:** Add them with `PURVIMP-Set-RoleGroups.ps1` (dry-run then `-Commit`); confirm with
`PURVIMP-Enable-CoreServices.ps1` that the viewer role groups have members. Access is intentionally
gated — a non-viewer being denied is correct behavior, not a bug.

## `Set-AdminAuditLogConfig` reports the change didn't take / access denied
**Symptom:** `-Commit` on the core-services script errors when enabling audit.
**Cause:** The account lacks the required Exchange Online admin role for `Set-AdminAuditLogConfig`.
**Fix:** Run the one-time enablement as an account with the appropriate admin role (Global Administrator
or an Exchange role that includes the audit-config cmdlet); this is one of the few actions for which
elevated rights are reserved.

## Compliance Manager score / assessment can't be pulled by script
**Symptom:** You expected `PURVIMP-Report-ComplianceBaseline.ps1` to read the Compliance Manager score.
**Cause:** Compliance Manager assessments have **no fully GA PowerShell/Graph write surface** — they are
managed and exported from the portal.
**Fix:** Open Purview portal → Compliance Manager, read the score, export the assessment
(`Assessments → Export`), and re-run the script with `-ComplianceScore <value>`. The script captures the
supporting signals (Secure Score, audit, role posture); the portal export is the assessment record.

## Endpoint count is zero or lower than expected in the scope map
**Symptom:** `PURVIMP-Scope-Config.ps1` reports few/no managed devices.
**Cause:** Devices aren't enrolled in Intune/managed, or the `DeviceManagementManagedDevices.Read.All`
scope wasn't consented — and Purview **device onboarding** is separate from device management.
**Fix:** This is a **readiness** signal, not a blocker for the foundation. Record the endpoint gap as a
hand-off item; tenant-wide device onboarding to Purview is performed in the endpoint-DLP solution
(Purview portal → `Settings → Device onboarding`, verify path).

## A pilot admin can do more (or less) than their function
**Symptom:** Separation-of-duties test fails — e.g. an eDiscovery manager can administer insider risk.
**Cause:** The person is a member of more than one role group, or holds a broad role (Global Admin /
Compliance Administrator) that subsumes the function.
**Fix:** Re-run `PURVIMP-Assess-Readiness.ps1` / `Get-RoleGroupMember`, remove the extra membership with
the reverse command the setup helper printed, and re-test. Keep sensitive role groups minimal, named,
and separate — confirmed with HR/privacy/legal.

---
### When to stop and escalate
- A required capability is **not licensed** and the plan can't be changed → record as deferred and scope
  the program to what you have; do not attempt to force-enable it.
- A **records/retention/legal-hold or insider-risk determination** is being asked of you → escalate to
  compliance, records, privacy, or legal. This foundation provides the technical method and evidence,
  never the determination.
- A portal path in this guide **doesn't match your tenant** → the Purview portal is actively evolving;
  verify the current path in your tenant before proceeding rather than assuming the guide is wrong about
  the *step*.


---


# 7. Best Practices — Implementing Microsoft Purview: Foundation, Roles & Onboarding

- **Enable the unified audit log first, before anything else.** Audit history cannot be back-filled — a
  day without ingestion is a day you can never investigate. Turn it on early even if you enable nothing
  else that week.
- **Start from least privilege, not from Global Admin.** Add people to the specific built-in role group
  their function needs; reserve Global Administrator for the two one-time setup actions (audit
  enablement, Graph consent). Broad admin "to get unblocked" is the mistake this whole foundation exists
  to prevent.
- **Keep the sensitive roles separated and named.** Insider Risk Management, Communication Compliance,
  and eDiscovery see sensitive employee content — keep their role groups minimal, named, separate from
  general compliance admin, and confirmed with HR/privacy/legal. Who may hold them is their call, not a
  technical default.
- **Always dry-run role changes.** Run `PURVIMP-Set-RoleGroups.ps1 -WhatIf` and read every line before
  `-Commit`; the script prints the exact reverse command for each add so rollback is trivial.
- **Prefer built-in role groups; create custom ones only to scope tighter.** Proliferating custom role
  groups makes the model harder to reason about. Use `New-RoleGroup` only where a built-in group grants
  more than the function needs.
- **Validate on a pilot ring before calling the tenant ready.** Prove roles, audit, Explorers, scope,
  and the baseline on a handful of admins and one or two sites first — the foundation is cheap to fix on
  a ring and expensive to fix tenant-wide.
- **Record what your licensing unlocks — and what it doesn't.** Purview is heavily plan-gated; document
  per capability "available on this plan" vs "deferred (not licensed)" so downstream solutions are
  scoped honestly. Verify every capability against your own tenant and plan.
- **Capture the Compliance Manager baseline as a dated artifact.** Export the assessment and snapshot the
  supporting signals so compliance improvement is measurable next quarter. The *target* (which
  regulations apply) belongs to compliance/legal.
- **Treat portal paths as provisional.** The Purview portal is actively evolving and role management is
  transitioning to a unified RBAC model — verify each path in your tenant rather than trusting a
  screenshot from last quarter.
- **This is the foundation, not the capabilities.** Do not author labels, DLP, retention, or
  insider-risk policies here — hand off to each capability's dedicated solution, where high-impact
  policies are piloted in simulation/test/disabled mode before enforcement.


---


# 8. Deliverables Summary — Implementing Microsoft Purview: Foundation, Roles & Onboarding

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Purview portal and capability map, the least-privilege role/RBAC model, the core data services (Content/Activity Explorer, unified audit), Compliance Manager, the phased-adoption approach, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + S&C PowerShell + Graph steps (assess, design role matrix, apply roles pilot-first, enable core services, confirm workload scope, baseline Compliance Manager, validate, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PURVIMP-Assess-Readiness.ps1` | Read-only readiness + licensing + role assessment: compliance SKUs (E3/E5/E5 Compliance) via Graph, existing role groups + members via S&C PowerShell, unified-audit status, and toolchain connectivity. Writes `Purview Readiness – Foundation – Assess` |
| `PURVIMP-Set-RoleGroups.ps1` | Least-privilege role-group / RBAC setup helper: adds named members to built-in role groups (and creates custom scoped groups where needed) from a matrix CSV; **`-WhatIf` by default**, `-Commit` to apply; prints the reverse command for each change |
| `PURVIMP-Enable-CoreServices.ps1` | Core-services enablement checker/enabler: reports (and with `-Commit` enables) the unified audit log, and reports Content/Activity Explorer viewer-role posture. Writes `Purview Core Services – Enablement` |
| `PURVIMP-Report-ComplianceBaseline.ps1` | Read-only compliance-signal baseline: captures Secure Score (Graph), audit status, and role posture alongside the portal Compliance Manager score you supply. Writes `Purview Compliance Baseline – Report` |
| `PURVIMP-Scope-Config.ps1` | Read-only scope/health helper: confirms the in-scope M365 workloads and reports endpoint device-onboarding readiness. Writes `Purview Workload Scope – Map` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything. No credentials or secrets are stored in code; every script uses interactive
modern-auth (`Connect-IPPSSession` / `Connect-ExchangeOnline` / `Connect-MgGraph`).

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
A Microsoft Purview foundation done right — the portal organized, role groups least-privileged and
separated, the unified audit log and Content/Activity Explorer visibility on, Compliance Manager
baselined, and the in-scope workloads connected — so every Purview capability you add next (labels, DLP,
retention/records, insider risk, communication compliance, audit investigations, DSPM, data governance)
lands on solid ground.
