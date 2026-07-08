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
