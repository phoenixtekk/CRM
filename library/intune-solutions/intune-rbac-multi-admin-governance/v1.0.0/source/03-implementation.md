# 3. Implementation Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval)

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).

> Model: Design least-privilege roles and a scope-tag taxonomy, build admin/approver scope groups,
> create custom roles and assignments, apply scope tags to objects, then enable access policies
> (multi-admin approval) for high-risk resource types. Pilot one approval before broad enforce, and
> keep a break-glass admin so you never lock yourself out.

All artifact names below are used verbatim; reuse them exactly.

## Step 1 — Build the admin and approver scope groups
1. Entra → Groups → New group → Security → `Intune Admins – Region A – Prod` (the admins who will
   hold the custom role). Add members. Create.
2. New group → Security → `Change Approvers – Apps – Prod` (the second-approver group). Add the
   approvers. Create.
3. Optionally build both groups in one pass with `RBACGOV-Set-ScopeTargeting.ps1`.

## Step 2 — Create the scope tag
1. Intune → Tenant administration → Roles → Scope tags → Create.
2. Name: `Region A – Devices – Prod`. Next.
3. Assignments → add the groups/objects this tag should be visible to as needed. Create.

## Step 3 — Create the custom roles
1. Intune → Tenant administration → Roles → All roles → Create → Custom role.
2. Name: `App Manager – Region A – Prod`. Under Permissions, enable only the app-management
   permissions this persona needs (for example Mobile apps: Read/Create/Update/Assign); leave
   device and policy permissions off. Next.
3. Scope (Tags): select `Region A – Devices – Prod`. Next → Create.
4. Create a second custom role `Policy Reader – All – Audit` with read-only permissions across the
   workloads an auditor must view, no write permissions. Create.

## Step 4 — Assign the custom role
1. Tenant administration → Roles → All roles → open `App Manager – Region A – Prod` → Assignments →
   Assign.
2. Assignment name: `App Manager Assignment – Region A – Prod`.
3. Admin Groups (members): add `Intune Admins – Region A – Prod`.
4. Scope (Groups): add the managed group(s) this role may administer.
5. Scope (Tags): select `Region A – Devices – Prod`. Next → Create.

## Step 5 — Apply the scope tag to objects
1. For each app/policy/profile this region owns, open the object → Properties → Scope tags → add
   `Region A – Devices – Prod` → Save.
2. This makes the object visible/manageable only to admins whose assignment carries the same tag.
   Run `RBACGOV-Discovery.ps1` to confirm tag coverage.

## Step 6 — Enable multi-admin approval for high-risk apps
1. Intune → Tenant administration → Multi admin approval → Access policies → Create.
2. Name: `App Deploy Approval – All – Prod`.
3. Profile type: select the apps resource type (so app create/change/delete requires approval).
4. Approvers: select `Change Approvers – Apps – Prod`. Create.

## Step 7 — Enable multi-admin approval for high-risk scripts
1. Multi admin approval → Access policies → Create.
2. Name: `Script Deploy Approval – All – Prod`.
3. Profile type: select the scripts resource type.
4. Approvers: select `Change Approvers – Apps – Prod`. Create.

## Step 8 — Pilot one approval (the pilot gate)
1. As an admin in `Intune Admins – Region A – Prod`, make a small change to a gated resource (for
   example edit a test app assignment). The change is held as a pending request.
2. As a different admin in `Change Approvers – Apps – Prod`, go to Multi admin approval → Received
   requests, review, and Approve with a note.
3. Confirm the change applies only after approval, and that a rejection blocks it. Run
   `RBACGOV-Validation.ps1` to confirm the policy is active and the role assignment is correct.

## Step 9 — Validate and report
1. Run `RBACGOV-Validation.ps1` → confirms role assignments and approval policies match the design.
2. Run `RBACGOV-Report.ps1` → governance coverage and any over-privileged assignments.
3. Complete the Testing Guide before expanding.

## Step 10 — Expand to production
1. Roll the scope-tag taxonomy out to the remaining regions/business units; create additional custom
   roles and assignments following the same naming pattern.
2. Add access policies for any other high-risk resource types once the pilot approval is proven.
3. Re-validate each change with `RBACGOV-Validation.ps1` / `RBACGOV-Report.ps1`.

> Rollback note: if an assignment or approval gate is too tight, loosen or remove it using your
> break-glass Global Administrator (excluded from the gate). `RBACGOV-Remediation.ps1` runs with
> `-WhatIf` by default so you can preview any tightening before it is applied.

---
### Order of operations
`Scope groups → Scope tag → Custom roles → Role assignment → Tag objects → App approval policy → Script approval policy → Pilot approval → Validate/report → Expand`
