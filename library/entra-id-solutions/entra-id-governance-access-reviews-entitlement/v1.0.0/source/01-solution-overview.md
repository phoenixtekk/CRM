# 1. Solution Overview — Entra ID Governance: Access Reviews & Entitlement Management

## What this solution is
This solution deploys the three pillars of **Microsoft Entra ID Governance** that together automate the
access lifecycle:

- **Entitlement management** — a self-service, policy-governed way to grant access. You bundle
  resources (groups, enterprise apps, SharePoint sites) into an **access package**, publish it in a
  **catalog**, and attach **assignment policies** that control who can request it, who approves, and how
  long the grant lasts. Users request access from **My Access**; approved grants are **time-bound** and
  expire automatically.
- **Access reviews** — scheduled recertification. A review targets the members of a group, the users
  assigned to an application, or the guests in the tenant, and asks named **reviewers** (or the users
  themselves) to confirm access is still needed. Decisions can **auto-apply** so removals actually happen.
- **Lifecycle workflows** — event-driven automation for the employee lifecycle. A **workflow** runs a
  set of **tasks** (enable account, add to groups, send a welcome email, request a package, remove
  memberships, disable account, revoke sessions) triggered by joiner, mover, or leaver conditions based
  on attributes like `employeeHireDate` and `employeeLeaveDateTime`.

## How the technology works
All three features live under **Identity Governance** in the Microsoft Entra admin center
(`https://entra.microsoft.com` → **Identity governance**) and are backed by the Microsoft Graph
`identityGovernance` API set. The building blocks nest as follows:

- **Catalog** → a container that owns **resources** and **access packages**. Catalogs let you delegate
  administration to resource owners without giving them tenant-wide rights.
- **Access package** → the requestable unit. It references **resource roles** (e.g. Member of a group,
  a specific app role, a SharePoint site role) drawn from its catalog.
- **Assignment policy** → attached to an access package; defines the **requestor scope** (specific
  users, all members, or specific connected external organizations for guests), the **approval**
  settings (one or two stages, approvers, justification), and the **lifecycle** (expiry, access review
  on renewal).
- **Access review definition** → the recurring schedule, scope, reviewers, and decision behavior
  (auto-apply, what to do if reviewers don't respond).
- **Workflow** → the ordered list of **tasks** plus the **execution conditions** (trigger and scope).

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand** — inventory current access sprawl and decide the
> first scope (Assess); build one catalog, one access package with an approval policy, one access review,
> and one lifecycle workflow (Configure); target them at a small **pilot** group first (Pilot); prove the
> pass/fail gates — request→approve→expire, review→auto-apply removal, workflow runs (Validate); then
> roll the pattern out to the full set of resources, groups, apps, and guests in waves (Expand). Every
> production change has a rollback.

## What is in scope
- One **governance catalog** with resources added.
- One or more **access packages** with **approval + lifecycle policies** (time-bound, review-on-renewal).
- **Recurring access reviews** for a group, an application's assignments, and **all guests**.
- **Lifecycle workflows** for **joiner** (onboarding) and **leaver** (offboarding), plus the pattern for
  **mover**.
- **Guest governance** — reviewing external users and enforcing **time-bound external access** via
  package expiry and guest access reviews.
- Read-only **reporting** for audit and recertification evidence via the included scripts.

## What is out of scope
- **Privileged Identity Management (PIM)** for just-in-time **role** activation and role-assignment
  reviews is a **separate, adjacent solution** (Entra ID Governance — PIM & Access Reviews). This
  solution governs **resource and app access**, not privileged directory-role activation.
- **Conditional Access** policy design (a separate Zero Trust solution).
- The **decision** of which resources, how often, and who approves/reviews — those are governance,
  compliance, and business-owner determinations. This guide provides the technical controls.

## Authentication and connections used
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) → **Identity governance** for all
  configuration.
- **Microsoft Graph** for the automation scripts, via `Connect-MgGraph` with least-privilege scopes
  (`EntitlementManagement.Read.All`, `AccessReview.Read.All`, `LifecycleWorkflows.Read.All`,
  `User.Read.All`). No credentials or secrets are stored in the scripts.
- **My Access** portal (`https://myaccess.microsoft.com`) — where end users request packages and
  reviewers act on reviews.

## Limitations (be honest with buyers)
- **Licensing gate:** entitlement management, access reviews, and lifecycle workflows require **Entra ID
  Governance** / P2-class licensing. Lifecycle workflows in particular are part of the **Entra ID
  Governance** add-on. *Verify current SKU coverage and any per-user licensing rules against Microsoft's
  current documentation and your tenant.*
- **Auto-apply actually removes access.** An access review with auto-apply, or an access package expiry,
  will **remove memberships/assignments** — always pilot with report-style behavior first and confirm
  reviewers understand the decision.
- Some governance capabilities and settings evolve; the portal blades and Graph beta endpoints change.
  Steps are flagged where a name or path may drift — verify against current Microsoft guidance.
