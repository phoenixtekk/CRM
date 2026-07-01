# Adobe Creative Cloud for Enterprise License Management (Admin Console)

> **Version 1.0.0** · Category: Asset Mgt · Solution code: ADOBELIC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Adobe Creative Cloud for Enterprise License Management (Admin Console)

Adobe Creative Cloud for Enterprise is one of the most expensive line items in many software
budgets, and one of the easiest to let drift. Named-user seats get assigned during onboarding and
forgotten, expensive all-apps entitlements go to people who only need a single product, and
reassignments are handled ad hoc when someone leaves. The result is paying for seats nobody uses.

This package gives you the repeatable way to bring Adobe Creative Cloud for Enterprise licensing
under control in the Adobe Admin Console: clean named-user and product-profile assignment,
usage-based right-sizing, reclamation of unused seats, and a recurring review that keeps Adobe spend
matched to real need. It is written for a Software Asset Management (SAM) analyst and is built to be
proven on a pilot scope before it is applied to the whole estate.

Adobe Admin Console internals, identity and single sign-on (SSO) setup, and the exact API
authentication flow are deferred to Adobe's official documentation throughout — this package gives
the correct general procedure and the SAM process around it, not fabricated Adobe menus.

## What you get
- A plain-language Solution Overview of the Creative Cloud for Enterprise licensing model
  (named-user licensing, product profiles, identity types) and the right-sizing and reclamation cycle.
- A Requirements Guide with verify and implement-if-missing steps for every prerequisite.
- An Implementation Guide of precise, ordered steps: confirm identity and product profiles, inventory
  assigned seats and usage, find unused and over-provisioned seats, reclaim and reassign, set a
  recurring review, then pilot, validate, and expand.
- Five PowerShell scripts for assignment and usage discovery, seat-utilization validation, a seat and
  cost report, safe remediation that flags reclaim candidates, and a review-scope group builder.
- Testing and Troubleshooting guides with explicit pass and fail gates, plus field-proven Best Practices.

## What this delivers
A managed Adobe licensing process anchored on named artifacts — a product-profile map, a seat
inventory, a right-sizing register, a review cadence, and review-scope groups — so that every seat is
deliberately assigned, every unused seat is found and reclaimed, and the estate is reviewed on a
predictable schedule.

## The standard deployment model
Assess to Configure to Pilot to Validate to Expand, with a pilot gate that must pass before the
process is applied beyond the first scope.

## Outcome
Adobe Creative Cloud for Enterprise spend matched to real need — clean seat assignment, unused seats
reclaimed, and a recurring review — proven on a pilot before you scale.


---


# 1. Solution Overview — Adobe Creative Cloud for Enterprise License Management

## What this solution is
This is the repeatable way to manage Adobe Creative Cloud for Enterprise licensing in the Adobe
Admin Console. It treats Adobe seats as a Software Asset Management (SAM) problem: every paid seat
should be deliberately assigned to a person who needs it, sized to the right product, reclaimed when
it falls idle, and reviewed on a recurring cadence. The goal is to keep Adobe spend matched to real
need without disrupting the people who genuinely use the tools.

Adobe Admin Console internals, identity and single sign-on (SSO) configuration, and the exact API
authentication flow change over time and are owned by Adobe. This solution defers those specifics to
Adobe's official documentation and focuses on the correct general procedure and the SAM process that
wraps around it.

## The Adobe Creative Cloud for Enterprise licensing model
Creative Cloud for Enterprise uses named-user licensing. A paid entitlement (a seat) is consumed
when a product is made available to a specific user, not when software is installed on a device. The
key building blocks are:

- Named-user licensing — a seat is tied to an individual identity. Assigning or removing a user from
  an entitlement is what consumes or frees a seat.
- Product profiles — within a purchased product (for example an all-apps plan or a single-app plan),
  a product profile defines which services and how many seats are made available, and which users or
  user groups are entitled. Assignment to a product profile is the act that consumes a seat.
- User groups — collections of users that can be attached to product profiles so assignment scales
  by role rather than one person at a time.
- Identity types — Adobe supports more than one identity type for accounts (for example federated
  identity backed by an organization's identity provider, enterprise-managed identities, and Adobe
  IDs). The identity type affects how users are created, authenticated, and governed. The exact setup
  is deferred to Adobe's documentation; for SAM purposes the relevant fact is that each named user
  occupies a seat regardless of identity type.

## How seat management works
1. Confirm the identity foundation (how users sign in) and the product profiles that exist for each
   purchased Adobe product.
2. Build a product-profile map so it is clear which profile grants which product and how many seats
   each profile is sized for.
3. Inventory the assigned seats — which named users are entitled through which profiles — and gather
   usage data so idle and over-provisioned seats become visible.
4. Right-size: match each user to the cheapest product that meets their real usage (for example move a
   single-app user off an all-apps profile), and flag seats with no recent activity for reclamation.
5. Reclaim idle seats by removing the user from the product profile, freeing the seat for reuse or for
   a true-down at renewal.
6. Reassign freed seats to people on a waiting list instead of buying new ones.
7. Run a recurring review so the estate does not drift back out of alignment.

## Where usage data comes from
Adobe exposes administrative data through the Adobe User Management API (a REST API). Where that API
is available to you, assignment and group data can be read programmatically. Adobe activity and usage
detail is also available through the Admin Console as reports and CSV exports. This solution reads
Adobe data through the User Management API where available and otherwise operates on an Admin Console
CSV export — both paths are supported, and the scripts comment clearly where Adobe-specific endpoints
or export columns are required.

## What you can control
- Which named users are assigned to which product profiles (and therefore which seats are consumed).
- Right-sizing — moving users between an all-apps profile and a single-app profile to fit real usage.
- Reclamation — removing idle users from profiles to free seats.
- Review cadence — the recurring schedule on which the estate is re-inventoried and re-checked.

## Why this matters
- Cost control — all-apps seats are expensive; an unused or over-provisioned seat is pure waste.
- Compliance — assignments stay reconciled against the purchased entitlement count, so you are neither
  over- nor under-licensed at true-up or renewal.
- Predictability — a recurring review means reclamation is routine, not a fire drill triggered by a
  surprise renewal quote.
- Reuse over rebuy — freed seats go to the next requester, deferring or avoiding new purchases.

## Limitations (be honest with buyers)
- This solution manages Adobe Creative Cloud for Enterprise seat assignment and right-sizing. It does
  not negotiate Adobe contracts or perform the purchase or true-up transaction itself.
- The exact Admin Console menus, identity and SSO setup, and API authentication flow are owned by
  Adobe and are deferred to Adobe's official documentation; they may change.
- Usage and activity detail depends on what the Adobe User Management API and Admin Console exports
  expose to your organization; some signals require the appropriate Admin Console report.
- Removing a user from a product profile revokes their access to that product — reclamation must follow
  the review and confirmation steps so active users are never cut off.

## The standard deployment model
> Confirm identity and product profiles, build the product-profile map and seat inventory, identify
> unused and over-provisioned seats, reclaim and reassign, set a recurring review, then prove it on a
> pilot scope before expanding. Standard model: Assess to Configure to Pilot to Validate to Expand.


---


# 2. Requirements Guide — Adobe Creative Cloud for Enterprise License Management

Verify every requirement before configuring. Each entry follows: Description, Why, Verify, and
Implement-if-missing. Category-wide prerequisites are in `global-requirements-asset-mgt.md`; the
requirements below are specific to Adobe Creative Cloud for Enterprise.

Adobe-specific configuration (Admin Console internals, identity and SSO setup, exact API
authentication) is deferred to Adobe's official documentation. The steps below give the correct
general procedure and tell you what to confirm, not fabricated Adobe menus.

## 2.1 Adobe Admin Console administrative access
Description: An administrator account for the Adobe Admin Console with rights to view and manage
users, product profiles, and assignments.
Why: Reading the seat inventory and reclaiming or reassigning seats requires administrative rights in
the console that holds the Adobe entitlements.
Verify: Sign in to the Adobe Admin Console and confirm the Products, Users, and (where present)
Insights or reporting areas load for your account.
Implement-if-missing: Have an existing System Administrator grant the least-privilege Adobe admin role
that covers user and product-profile management (for example a Product Profile Administrator or User
Group Administrator), reserving System Administrator for organization-wide changes. The exact role
names and grant procedure are deferred to Adobe's documentation.

## 2.2 Identity foundation confirmed
Description: A known, working identity type for the Adobe organization (for example federated identity
via an identity provider, enterprise-managed identities, or Adobe IDs) so that named users are
governed consistently.
Why: Named-user licensing ties each seat to an identity; you must know how users are created and
authenticated before you reconcile assignments, and a clean identity foundation makes reclamation
safe (you are removing the right person).
Verify: In the Admin Console, confirm the directory and identity type in use and that a sample user
resolves to the expected identity.
Implement-if-missing: Establish the identity type and directory per Adobe's official documentation
(identity setup and SSO are Adobe-owned and out of scope for this package). For SAM purposes you only
need it confirmed and stable, not changed.

## 2.3 Product profiles defined
Description: Product profiles configured for each purchased Adobe product so that assignment happens
through profiles rather than ad hoc.
Why: The product profile is the unit of assignment that consumes a seat; a clean profile structure is
what makes the seat inventory and right-sizing meaningful (all-apps versus single-app).
Verify: In the Admin Console under Products, confirm each purchased product has at least one product
profile and that the profile shows its quota of seats and entitled users or groups.
Implement-if-missing: Create one product profile per product (or per role, where a role needs a
distinct service set) and name it clearly; attach user groups rather than individuals where possible.
Profile creation specifics are deferred to Adobe's documentation.

## 2.4 Entitlement record (purchased seat counts)
Description: An authoritative record of how many seats of each Adobe product were purchased, with the
renewal date — see global requirement G3.
Why: Right-sizing and compliance are only possible against a known, authoritative purchased count;
without it you cannot tell over- from under-licensed.
Verify: You can state the purchased seat quantity and renewal date for at least one representative
Adobe product from your records.
Implement-if-missing: Capture current Adobe order or quote quantities and renewal dates into the
entitlement system of record (G3); reconcile against the Admin Console quota per profile.

## 2.5 Usage and activity data source
Description: A source of Adobe seat activity — preferably the Adobe User Management API (REST) for
assignment data, plus Admin Console usage or activity reporting, or an Admin Console CSV export.
Why: Reclaiming and right-sizing seats requires evidence that a seat is idle or over-provisioned;
assignment data alone is not enough without activity signal.
Verify: You can read assignment data through the Adobe User Management API, or you can export a users
and product-assignment CSV from the Admin Console; and you can identify a recent-activity or
last-active signal for a sample of users (from Adobe reporting where available).
Implement-if-missing: Enable and obtain credentials for the Adobe User Management API per Adobe's
official developer documentation, or schedule a recurring Admin Console CSV export. Where Adobe does
not expose a direct last-active field to you, substitute the best available activity report and note
the limitation in the right-sizing register. The exact API authentication flow is deferred to Adobe's
documentation.

## 2.6 API credentials and access (where the API is used)
Description: Credentials and authorization for the Adobe User Management API, stored securely.
Why: Programmatic, repeatable inventory and validation depend on authorized API access; manual exports
are a fallback.
Verify: A non-secret test call to the Adobe User Management API returns your organization's data; the
credentials are stored in a secret store or environment variables, not in the scripts.
Implement-if-missing: Register the integration and obtain credentials per Adobe's official developer
documentation, grant it the least privilege needed to read users and product assignments, and store
the secret outside source control. If API access is not available, operate the scripts in CSV mode
against an Admin Console export.

## 2.7 Pilot scope identified
Description: A representative subset to prove the process first — one product (for example the all-apps
profile), one department, or one office — see global requirement G7.
Why: Every solution is piloted before broad rollout to validate accuracy and avoid cutting off active
users.
Verify: A pilot scope and its data owner are named.
Implement-if-missing: Choose a high-value, well-understood scope (the all-apps profile is often the
best first pass because it carries the most cost per seat).

---
## Checklist
- [ ] Adobe Admin Console admin access (least privilege)
- [ ] Identity foundation confirmed and stable
- [ ] Product profiles defined per purchased product
- [ ] Entitlement record with purchased counts and renewal dates (G3)
- [ ] Usage and activity data source — User Management API or Admin Console CSV export
- [ ] Adobe User Management API credentials stored securely (where API is used)
- [ ] Pilot scope and data owner identified (G7)


---


# Global Requirements — Asset Mgt (category-level)

These requirements apply to **every** solution in the **Asset Mgt** category (Software Asset
Management, license compliance, and entitlement governance). They are published once at the category
level so individual listings stay small. Confirm these before deploying *any* Asset Mgt solution.
Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for user-based license assignment, access, and reporting.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Administrative access to the license sources
**Description:** Admin rights to the consoles that hold entitlements — at minimum the Microsoft 365
admin center (`https://admin.microsoft.com`), plus any others in scope (Adobe Admin Console,
publisher portals).
**Why:** Reading and adjusting entitlements, assignments, and true-ups requires elevated rights.
**Verify:** Each console loads and shows the licensing/billing area for an admin account.
**Implement:** Assign the least-privilege admin role per console (e.g. License Administrator or
Billing Administrator in Microsoft 365); reserve Global Administrator for tenant-wide changes.

## G3. A system of record for entitlements
**Description:** A maintained record of purchased entitlements, contracts, and renewal dates — a
SAM/ITAM tool, a ServiceNow/CMDB instance, or (at minimum) a controlled spreadsheet/repository.
**Why:** Compliance and optimization are only possible against a known, authoritative entitlement count.
**Verify:** You can locate the current entitlement quantity and renewal date for a representative product.
**Implement:** Stand up the records repository and import current purchase orders / true-up statements.

## G4. Deployment / usage discovery data
**Description:** A source of what is actually installed or used — Microsoft Intune, Configuration
Manager (SCCM), a discovery tool (e.g. Flexera), or sign-in/usage telemetry.
**Why:** Reconciling entitlements against real deployment/usage is the core of compliance and reharvesting.
**Verify:** You can export an installed-software or license-usage report for a sample of devices/users.
**Implement:** Enable Intune/Configuration Manager inventory or onboard a discovery tool; for SaaS,
enable usage/sign-in reporting.

## G5. Reporting toolchain
**Description:** Excel (PivotTables, Power Query) and/or Power BI for analysis and dashboards.
**Why:** License usage, compliance, and cost-optimization findings are delivered as reports/dashboards.
**Verify:** Power BI Desktop opens and can connect to a data source; Excel Power Query is available.
**Implement:** Install Power BI Desktop and a current Excel; provision a Power BI workspace if sharing.

## G6. Stakeholder and process alignment
**Description:** Named owners across IT, procurement, and finance, plus a request/intake channel
(e.g. ServiceNow) for license actions.
**Why:** Renewals, true-ups, and reharvesting require coordinated decisions and an auditable workflow.
**Verify:** A request can be raised and routed to the correct owner; procurement contacts are known.
**Implement:** Define roles (SAM analyst, approver, procurement liaison) and a documented intake process.

## G7. A pilot scope
**Description:** A representative subset (one product family, one department, or one publisher) to prove
the process before fleet-wide rollout.
**Why:** Every solution is piloted before broad adoption to validate accuracy and avoid disruption.
**Verify:** A pilot scope and its data owners are identified.
**Implement:** Choose a high-value, well-understood product/department as the first pass.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Adobe Creative Cloud for Enterprise License Management

Follow these steps in order. Work in the Adobe Admin Console and, where available, the Adobe User
Management API; the supplied scripts assist at each read-only step.

Adobe-specific configuration (exact Admin Console menus, identity and SSO setup, API authentication)
is deferred to Adobe's official documentation. The steps below give the correct general procedure and
name every artifact you produce so the same names are reused in Testing, Troubleshooting, and the
recurring review.

> Model: Confirm the foundation, inventory and analyze, reclaim and reassign, then institutionalize a
> recurring review — proven on a pilot scope first. Standard model: Assess to Configure to Pilot to
> Validate to Expand.

Named artifacts produced by this guide (reuse these exact names):
- `Product-Profile Map – All Adobe Products – Configure`
- `Seat Inventory – Pilot Scope – Assess`
- `Right-Sizing Register – Pilot Scope – Validate`
- `Review Cadence – Adobe Estate – Expand`
- `Reclaim-Review Group – Pilot Scope – Validate`

## Step 1 — Confirm identity and product profiles (Assess)
1. In the Admin Console, confirm the identity type and directory are in place and stable (requirement
   2.2). Do not change identity setup here; only confirm it.
2. Under Products, list every purchased Adobe product and its product profiles, and record each
   profile's seat quota and entitled users or groups into `Product-Profile Map – All Adobe Products – Configure`.
3. For each profile note whether it is an all-apps or single-app entitlement and its per-seat cost
   from the entitlement record (requirement 2.4). This map is what makes right-sizing possible.

## Step 2 — Inventory assigned seats for the pilot scope (Assess)
1. Choose the pilot scope (requirement 2.7) — typically the all-apps profile or one department.
2. Run `ADOBELIC-Discovery.ps1` to read assignments. Where the Adobe User Management API is available,
   the script reads users and product assignments via the API; otherwise it reads an Admin Console CSV
   export you provide. Save the output as `Seat Inventory – Pilot Scope – Assess`.
3. Confirm the inventory's seat count per profile reconciles to the Admin Console quota and to the
   purchased count in the entitlement record. Note any variance.

## Step 3 — Identify unused and over-provisioned seats (Validate)
1. Run `ADOBELIC-Validation.ps1` against the seat inventory plus the activity or last-active signal
   (from Adobe reporting where available; otherwise the best available export). The script classifies
   each seat as active, idle (no recent activity beyond your threshold), or over-provisioned (for
   example an all-apps seat used as a single app).
2. Record the candidates in `Right-Sizing Register – Pilot Scope – Validate`, one row per user with:
   current profile, recommended action (keep, downsize, reclaim), evidence (last-active or usage), and
   a confirmation owner.
3. Run `ADOBELIC-Report.ps1` to produce a seat and cost summary — assigned versus active seats per
   profile and the estimated cost of idle and over-provisioned seats. This is the business case for the
   reclamation.

## Step 4 — Build the reclaim-review group (Configure)
1. Run `ADOBELIC-Set-ScopeTargeting.ps1` to assemble the reclaim and downsize candidates from the
   right-sizing register into a review group named `Reclaim-Review Group – Pilot Scope – Validate`.
   The script prepares the list (and, where the API is available, can stage an Adobe user group);
   it does not remove anyone.
2. Route the group to the confirmation owners named in the register. Reclamation only proceeds for
   users a confirmation owner approves — this protects active users from losing access.

## Step 5 — Reclaim and reassign (Validate, pilot gate)
1. For each approved reclaim candidate, remove the user from the product profile in the Admin Console
   (or via the User Management API where you have a tested, authorized write path). Removing the user
   from the profile frees the seat. The exact removal action is deferred to Adobe's documentation.
2. For each approved downsize candidate, remove the user from the all-apps profile and add them to the
   appropriate single-app profile.
3. Reassign freed seats to people on the waiting list before purchasing any new seats.
4. Re-run `ADOBELIC-Discovery.ps1` and `ADOBELIC-Report.ps1` and confirm the freed and reassigned
   seats are reflected. This is the pilot gate — see the Testing Guide for the pass and fail criteria.

## Step 6 — Set the recurring review (Expand)
1. Define `Review Cadence – Adobe Estate – Expand`: the schedule (for example monthly or quarterly),
   the owner, the idle threshold, and the artifacts to refresh each cycle (the seat inventory, the
   right-sizing register, and the seat-and-cost report).
2. Schedule `ADOBELIC-Discovery.ps1`, `ADOBELIC-Validation.ps1`, and `ADOBELIC-Report.ps1` to run each
   cycle so the next review starts from current data.
3. Tie the cadence to the renewal date in the entitlement record so a true-down is prepared before
   renewal, not discovered after.

## Step 7 — Expand beyond the pilot
1. After the pilot gate passes, repeat Steps 2 through 5 for the next scope (the next product profile,
   department, or office), reusing the same named artifacts scoped to the new area.
2. Continue until the whole Adobe estate is covered, then let `Review Cadence – Adobe Estate – Expand`
   keep it aligned.

---
### Order of operations
`Confirm identity and profiles -> Seat inventory -> Identify idle and over-provisioned -> Reclaim-review group -> Reclaim and reassign (pilot gate) -> Recurring review -> Expand`


---


# 5. Testing Guide — Adobe Creative Cloud for Enterprise License Management

Run these tests after the pilot scope is inventoried and reclaimed (Implementation Steps 2 through 5)
and again each review cycle. They confirm the named artifacts are accurate and that reclamation freed
seats without cutting off active users.

## Test 1 — Product-profile map is complete
Do: Compare `Product-Profile Map – All Adobe Products – Configure` against the Admin Console Products
list.
Expected: Every purchased product and profile appears, each with its seat quota and per-seat cost.

## Test 2 — Seat inventory reconciles to entitlement
Do: Compare the per-profile seat count in `Seat Inventory – Pilot Scope – Assess` against the Admin
Console quota and the purchased count in the entitlement record (requirement 2.4).
Expected: Counts reconcile, or every variance is explained and recorded.

## Test 3 — Idle and over-provisioned seats classified
Do: Review `Right-Sizing Register – Pilot Scope – Validate` produced by `ADOBELIC-Validation.ps1`.
Expected: Each seat is classified active, idle, or over-provisioned, with last-active or usage
evidence and a confirmation owner per reclaim or downsize row.

## Test 4 — Reclamation freed the seat
Do: After approved reclamations, re-run `ADOBELIC-Discovery.ps1`.
Expected: Reclaimed users no longer appear on their former product profile and the freed seats show as
available against the quota.

## Test 5 — No active user lost access
Do: Spot-check a sample of users who were kept (not reclaimed) and confirm their access is intact;
confirm every reclaimed user had a confirmation-owner approval recorded in the register.
Expected: No active or approved-keep user lost access; no user was reclaimed without approval.

## Test 6 — Downsized users moved correctly
Do: For approved downsize candidates, confirm in the Admin Console they are off the all-apps profile
and on the correct single-app profile.
Expected: Each downsized user holds exactly the intended single-app entitlement.

## Test 7 — Cost report reflects the change
Do: Run `ADOBELIC-Report.ps1` before and after reclamation.
Expected: The seat-and-cost summary shows the reduction in idle and over-provisioned seat cost and the
updated assigned-versus-active counts.

## Test 8 — Recurring review is scheduled
Do: Confirm `Review Cadence – Adobe Estate – Expand` exists with a schedule, owner, idle threshold,
and the scheduled runs of the discovery, validation, and report scripts.
Expected: The next review will start from refreshed data and is tied to the renewal date.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 through 5 pass for the pilot scope; reclaimed seats are freed and no active user lost access |
| Expand pass | Tests 1 through 4, 7, and 8 pass for each new scope before it is treated as complete |


---


# 6. Troubleshooting Guide — Adobe Creative Cloud for Enterprise License Management

Use `ADOBELIC-Discovery.ps1` and `ADOBELIC-Validation.ps1` for current state, `ADOBELIC-Report.ps1`
for the seat-and-cost picture, and `ADOBELIC-Remediation.ps1` (default -WhatIf) to flag reclaim and
downsize candidates safely. Adobe Admin Console internals and the exact API authentication flow are
deferred to Adobe's official documentation.

## A. Discovery returns no data
| Symptom | Cause | Remediation |
|---|---|---|
| API call returns nothing or an auth error | Missing or wrong Adobe User Management API credentials | Confirm the credentials and scope per Adobe's developer documentation; verify a test call; ensure the secret is loaded from the environment, not blank |
| API not available to your org | No integration registered | Run the script in CSV mode against an Admin Console export instead |
| CSV mode reads zero rows | Wrong export or missing columns | Re-export users and product assignments from the Admin Console; confirm the expected columns are present |

## B. Seat counts do not reconcile
| Symptom | Cause | Remediation |
|---|---|---|
| Inventory count is over the quota | Stale assignments or duplicate identities | Re-run `ADOBELIC-Discovery.ps1`; check for duplicate users from a prior identity migration; reconcile against the Admin Console quota |
| Inventory count is under the purchased count | Purchased seats unassigned | Treat the gap as available seats; reassign from the waiting list before any new purchase |
| Cannot match a user to a person | Identity type ambiguity | Confirm the identity foundation (requirement 2.2) before reclaiming that user |

## C. Activity or last-active signal is missing
- Some organizations do not have a direct last-active field exposed by Adobe. Substitute the best
  available Admin Console activity report and record the limitation in `Right-Sizing Register – Pilot Scope – Validate`.
- When no activity signal exists at all, fall back to assignment age plus a confirmation-owner check
  rather than reclaiming on assumption.

## D. A reclaimed user lost access they needed
- Reclamation should never run without a recorded confirmation-owner approval. If access was removed in
  error, re-add the user to the product profile in the Admin Console; the seat is consumed again.
- Tighten the process: confirm the approval column in the register is populated before any removal.

## E. Right-sizing flags the wrong product
- An all-apps user who genuinely uses multiple apps is not over-provisioned. Confirm the usage evidence
  before downsizing; record the keep decision so the next cycle does not re-flag them.

## F. Recurring review drifts
- If the estate creeps back out of alignment, confirm the scheduled runs of the discovery, validation,
  and report scripts are actually executing and that `Review Cadence – Adobe Estate – Expand` has a
  named owner and a written idle threshold.

## G. When to escalate
If discovery and reconciliation are clean, credentials are valid, and an assignment still cannot be
read or changed as expected, capture the script output and the Admin Console state and open a support
case with Adobe — console behavior and API specifics are Adobe-owned.


---


# 7. Best Practices — Adobe Creative Cloud for Enterprise License Management

- Assign through product profiles and user groups, not one user at a time. Profile-based assignment is
  what keeps the seat inventory readable and right-sizing possible.
- Right-size before you reclaim. Many seats are not idle, they are over-provisioned — an all-apps seat
  used as a single app. Downsizing recovers cost without removing anyone's access.
- Never reclaim without a confirmation owner. Removing a user from a profile revokes access; require a
  recorded approval in `Right-Sizing Register – Pilot Scope – Validate` before any removal.
- Reuse freed seats before buying new ones. Reassign reclaimed seats from the waiting list first; a
  freed seat is the cheapest seat you will ever provision.
- Use a clear idle threshold and write it down. Define what "idle" means (for example no activity in N
  days) in `Review Cadence – Adobe Estate – Expand` so reclamation is consistent and defensible.
- Reconcile to the entitlement record every cycle. Tie the seat inventory to the purchased counts and
  renewal dates so you enter renewal knowing your true-down number.
- Prefer the Adobe User Management API where available, fall back to CSV cleanly. Programmatic reads
  are repeatable; an Admin Console export is the reliable fallback when the API is not available.
- Keep API credentials out of the scripts. Store secrets in a secret store or environment variables,
  never in source control, and grant the integration least privilege.
- Run reclamation as a routine, not a renewal fire drill. A recurring review tied to the renewal date
  turns a stressful true-up into a known quantity.
- Pilot first, every time. Prove the inventory, classification, and reclamation on one high-value
  scope (often the all-apps profile) before applying the process to the whole estate.
- Defer Adobe internals to Adobe. Identity and SSO setup, exact console menus, and API authentication
  are Adobe-owned and change; follow Adobe's official documentation and keep this process around it.


---


# 8. Deliverables Summary — Adobe Creative Cloud for Enterprise License Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The Creative Cloud for Enterprise licensing model (named-user, product profiles, identity types), assignment, right-sizing, reclamation, benefits, limitations |
| 2. Requirements Guide | Every Adobe-specific prerequisite with Verify and Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: confirm identity and profiles, inventory, classify, reclaim and reassign, recurring review, expand |
| 5. Testing Guide | Validation procedures with pass and fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts (reused across the documents)
| Artifact | Scope and stage |
|---|---|
| `Product-Profile Map – All Adobe Products – Configure` | Which profile grants which product, seat quota, per-seat cost |
| `Seat Inventory – Pilot Scope – Assess` | Named users assigned through each profile |
| `Right-Sizing Register – Pilot Scope – Validate` | Per-user keep, downsize, or reclaim decision with evidence and owner |
| `Reclaim-Review Group – Pilot Scope – Validate` | Candidates routed to confirmation owners |
| `Review Cadence – Adobe Estate – Expand` | Schedule, owner, idle threshold, refresh artifacts |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ADOBELIC-Discovery.ps1` | Reads users and product assignments via the Adobe User Management API where available, else an Admin Console CSV export (read-only) |
| `ADOBELIC-Validation.ps1` | Classifies seats active, idle, or over-provisioned against an activity signal (read-only) |
| `ADOBELIC-Report.ps1` | Seat-and-cost summary: assigned versus active per profile and idle/over-provisioned cost (read-only) |
| `ADOBELIC-Remediation.ps1` | Safe remediation that flags reclaim and downsize candidates; defaults to -WhatIf and makes no change without explicit confirmation |
| `ADOBELIC-Set-ScopeTargeting.ps1` | Builds the reclaim-review group from the right-sizing register |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the standard model: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Adobe Creative Cloud for Enterprise spend matched to real need — clean seat assignment, unused seats
reclaimed, over-provisioned seats downsized, and a recurring review — proven on a pilot before you scale.
