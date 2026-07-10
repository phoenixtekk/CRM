# 2. Requirements Guide — Entra ID Governance: Access Reviews & Entitlement Management

Verify **every** requirement before you configure governance. Each entry: **Description · Why required ·
How to verify · How to implement if missing.** The category-wide prerequisites (an active Entra ID
tenant, base licensing, administrative roles, and break-glass accounts) are defined once in
`global-requirements-entra-id-solutions.md` — confirm those first. The items below are **specific to
Identity Governance**.

## 2.1 Entra ID Governance / P2 licensing for the users in scope
**Description:** Entitlement management, access reviews, and lifecycle workflows require **Microsoft
Entra ID Governance** (features formerly under **Entra ID P2**). Lifecycle workflows are specifically
part of the **Entra ID Governance** SKU.
**Why required:** Without the correct license the Identity Governance blades appear but creating
packages, reviews, or workflows is blocked, and licensing applies to the **users who use** the features
(requestors, reviewers, workflow-targeted users).
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**; confirm **Entra ID Governance**
(or P2) coverage. In the Entra admin center, **Identity governance** blades load without a licensing
banner. Run **`ENTIGA-Discovery.ps1`** to confirm the governance endpoints respond.
**How to implement if missing:** Assign Entra ID Governance / P2 (often via EMS E5 or an add-on) to the
in-scope users. *Verify current licensing rules against Microsoft's documentation — SKU coverage
changes.*

## 2.2 Identity Governance administrative role
**Description:** The operator holds a role that can administer entitlement management, access reviews,
and lifecycle workflows — **Identity Governance Administrator** (least privilege) or Global
Administrator for tenant-wide setup.
**Why required:** Creating catalogs, packages, reviews, and workflows requires the governance admin
role; day-to-day catalog work can be delegated to **catalog owners** without tenant-wide rights.
**How to verify:** Entra → **Roles and administrators**; confirm **Identity Governance Administrator**
on the operator.
**How to implement if missing:** Assign **Identity Governance Administrator**; reserve Global
Administrator for the initial setup only. Delegate catalog administration to resource owners.

## 2.3 The resources to govern exist (groups, apps, sites)
**Description:** The **groups**, **enterprise applications**, and **SharePoint sites** that access
packages will grant must already exist and be identified.
**Why required:** An access package references **resource roles** that must be present in its catalog;
you cannot bundle access to a group or app that doesn't exist.
**How to verify:** Entra → **Groups** / **Enterprise applications**; confirm the target objects. Run
**`ENTIGA-Discovery.ps1`** to inventory current groups and app assignments.
**How to implement if missing:** Create the groups/apps first, or scope the pilot to resources that
already exist. Record each resource's exact name for the catalog.

## 2.4 A pilot group and named requestors / approvers / reviewers
**Description:** An **Entra security group `ENTIGA-Pilot`** with a handful of test users, and named
people to act as **approvers** (entitlement) and **reviewers** (access reviews).
**Why required:** The pilot-first model targets `ENTIGA-Pilot`; approval and review flows need real
identities to route to.
**How to verify:** Entra → **Groups**; confirm `ENTIGA-Pilot` and its members. Confirm approver/reviewer
identities exist.
**How to implement if missing:** Create `ENTIGA-Pilot` (Assigned membership) and add test users;
nominate approvers/reviewers (often the resource owner or the user's manager).

## 2.5 Manager attribute populated (for manager-as-approver / reviewer and mover workflows)
**Description:** The **Manager** attribute is set on in-scope users where you will use *manager* as the
approver, *manager* as the self-review escalation, or a **mover** workflow keyed on manager change.
**Why required:** "Manager" as a dynamic approver/reviewer and manager-based lifecycle logic resolve
against the directory **Manager** relationship; if it is empty, routing fails or falls back.
**How to verify:** Entra → **Users → (user) → Edit properties → Manager** is populated. Run
**`ENTIGA-Report.ps1`** to list in-scope users missing a manager.
**How to implement if missing:** Populate the Manager attribute (via HR sync, Entra Connect, or Graph)
before relying on manager-based approval/review.

## 2.6 Employee lifecycle attributes for workflows (joiner/mover/leaver)
**Description:** For **lifecycle workflows**, the trigger attributes must be populated —
**`employeeHireDate`** for joiner scheduling and **`employeeLeaveDateTime`** for leaver scheduling
(typically written from an HR source such as Workday, SuccessFactors, or an HR-driven provisioning
inbound flow).
**Why required:** Scheduled joiner/leaver workflows fire relative to these dates; without them, only
**on-demand** workflow runs are possible.
**How to verify:** Entra → **Users → (user)** attributes, or Graph `employeeHireDate` /
`employeeLeaveDateTime`. Run **`ENTIGA-Lifecycle.ps1`** to report which in-scope users have the trigger
attributes set.
**How to implement if missing:** Populate the attributes from the HR source (HR inbound provisioning or
directory write), or plan to run workflows **on-demand** until the attribute feed exists.

## 2.7 Guest / external collaboration settings decided
**Description:** The **External collaboration settings** (who can invite guests, guest permissions) and,
if used, **connected organizations** for external requestors are configured to support governed guest
access.
**Why required:** Guest governance (time-bound external access, guest access reviews, external requestor
policies) depends on how guests enter the tenant and which external organizations are recognized.
**How to verify:** Entra → **External Identities → External collaboration settings** and
**Identity governance → Entitlement management → Connected organizations**. Run **`ENTIGA-GuestReview.ps1`**
to inventory current guest accounts and their sign-in recency.
**How to implement if missing:** Set external collaboration settings to your standard and add any
**connected organizations** whose users should request packages, before publishing guest-facing packages.

## 2.8 Microsoft Graph PowerShell toolchain
**Description:** The **Microsoft Graph PowerShell SDK** installed on the operator's workstation, with
consent for the least-privilege read scopes the scripts use.
**Why required:** The five included tools authenticate via `Connect-MgGraph`; discovery, validation,
and reporting run through Graph.
**How to verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; running
**`ENTIGA-Discovery.ps1`** connects successfully.
**How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to
`EntitlementManagement.Read.All`, `AccessReview.Read.All`, `LifecycleWorkflows.Read.All`, `User.Read.All`
on first run.

---
## Checklist
- [ ] Category global requirements confirmed (`global-requirements-entra-id-solutions.md`)
- [ ] Entra ID Governance / P2 licensing for in-scope users — *verify current SKU coverage*
- [ ] Identity Governance Administrator role held by the operator
- [ ] Target groups / apps / sites to govern exist and are named
- [ ] `ENTIGA-Pilot` group created; approvers and reviewers nominated
- [ ] Manager attribute populated where manager-based routing is used
- [ ] `employeeHireDate` / `employeeLeaveDateTime` populated (or on-demand plan) — `ENTIGA-Lifecycle.ps1`
- [ ] Guest / external collaboration + connected organizations decided — `ENTIGA-GuestReview.ps1`
- [ ] Microsoft Graph PowerShell SDK installed — `ENTIGA-Discovery.ps1`
