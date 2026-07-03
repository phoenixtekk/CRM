# 3. Implementation Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

Follow these steps in order, in the **Microsoft Intune admin center for US Government**
(`https://intune.microsoft.us`). Entra steps use `https://entra.microsoft.us`.

> GCC High caveat: these are the sovereign portals. If a step below tells you to open a portal, use
> the `*.us` URL — the Commercial `*.com` URL will refuse your government credentials. The
> governance model itself is identical to Commercial; only the URLs and a couple of adjacent
> features differ (see `gcc-high-parity-notes.md`).

> Model: Design least-privilege roles and a scope-tag taxonomy, build admin/approver scope groups,
> create custom roles and assignments, apply scope tags to objects, then enable access policies
> (multi-admin approval) for high-risk resource types. Pilot one approval before broad enforce, and
> keep a break-glass admin so you never lock yourself out.

All artifact names below are used verbatim; reuse them exactly.

## Step 1 — Build the admin and approver scope groups
1. `https://entra.microsoft.us` → Groups → New group → **Security** → `Intune Admins – Region A – Prod`
   (the admins who will hold the custom role). Add members. Create.
2. New group → **Security** → `Change Approvers – Apps – Prod` (the second-approver group). Add the
   approvers. Create.
   - GCC High caveat: the approver group **must be a security group**. Distribution lists, Microsoft
     365 groups, and mail-enabled security groups silently fail to resolve approver membership.
3. Optionally build both groups in one pass with `RBACGOVG-Set-ScopeTargeting.ps1` (connects with
   `-Environment USGov`).

## Step 2 — Create the scope tag
1. `https://intune.microsoft.us` → Tenant administration → Roles → Scope tags → Create.
2. Name: `Region A – Devices – Prod`. Next.
3. Assignments → add the groups/objects this tag should be visible to as needed. Create.

## Step 3 — Create the custom roles
1. Intune (`intune.microsoft.us`) → Tenant administration → Roles → All roles → Create → Custom role.
2. Name: `App Manager – Region A – Prod`. Under Permissions, enable only the app-management
   permissions this persona needs (for example Mobile apps: Read/Create/Update/Assign); leave
   device and policy permissions off. Next.
3. Scope (Tags): select `Region A – Devices – Prod`. Next → Create.
4. Create a second custom role `Policy Reader – All – Audit` with read-only permissions across the
   workloads an auditor must view, no write permissions. Create.
   - Tip: to manage MAA access policies with least privilege later, a custom role can carry the
     **Multi Admin Approval** permissions (Create/Read/Update/Delete access policy) instead of using
     the privileged Intune Administrator role.

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
   Run `RBACGOVG-Discovery.ps1` to confirm tag coverage.

## Step 6 — Prepare the approver group for MAA (GCC High requirement)
1. The approver group `Change Approvers – Apps – Prod` must itself be **added to an Intune role
   assignment as a member group**, or Intune periodically removes members from the approver group.
   Add it to a suitable role assignment (for example a read-scoped role that matches what approvers
   need to review).
2. Approvers also need the **resource-specific Read permission** for the policy type they approve
   (for example Read on Mobile apps to approve app changes).
3. Enable **Allow access to unlicensed admins** only if an approver has no Intune license — note
   this setting is **irreversible** once turned on.

## Step 7 — Enable multi-admin approval for high-risk apps
1. `https://intune.microsoft.us` → Tenant administration → Multi Admin Approval → Access policies →
   Create.
2. On *Basics*: Name `App Deploy Approval – All – Prod`.
3. Profile type: select the **Apps** resource type (so app create/change/delete requires approval).
   Each policy supports a single profile type.
4. Approvers → Add groups → `Change Approvers – Apps – Prod`. (Exclude-group configurations are not
   supported.) Review + Create.
5. A **different** admin (with **Approval for Multi Admin Approval** permission) signs in and
   approves the new access policy, then the original admin re-opens it and selects **Complete** to
   activate it.

## Step 8 — Enable multi-admin approval for high-risk scripts
1. Multi Admin Approval → Access policies → Create.
2. Name: `Script Deploy Approval – All – Prod`.
3. Profile type: select the **Scripts** resource type (Windows scripts).
4. Approvers → `Change Approvers – Apps – Prod`. Review + Create, then approve + Complete as in
   Step 7.

## Step 9 — Pilot one approval (the pilot gate)
1. As an admin in `Intune Admins – Region A – Prod`, make a small change to a gated resource (for
   example edit a test app assignment). On the **Save + Review** surface, enter a **Business
   justification** and submit. The change is held as a pending request.
2. As a **different** admin in `Change Approvers – Apps – Prod`, go to Tenant administration → Multi
   Admin Approval → **Received requests**, open the Business justification, add Approver notes, and
   **Approve**.
3. Back as the requester, open **My requests** and select **Complete** to apply the change. Confirm
   the change applies only after approval, and that a rejection blocks it.
   - GCC High caveat: there is **no Change Review Agent / Copilot** suggestion column — review is
     fully manual. There are **no notifications**; tell approvers out-of-band. Requests **expire in
     3 days** if not completed.
4. Run `RBACGOVG-Validation.ps1` (`-Environment USGov`) to confirm the policy is active and the role
   assignment is correct.

## Step 10 — Validate and report
1. Run `RBACGOVG-Validation.ps1` → confirms role assignments and approval policies match the design.
2. Run `RBACGOVG-Report.ps1` → governance coverage and any over-privileged assignments.
3. Complete the Testing Guide before expanding.

## Step 11 — Expand to production
1. Roll the scope-tag taxonomy out to the remaining regions/business units; create additional custom
   roles and assignments following the same naming pattern.
2. Add access policies for any other high-risk resource types once the pilot approval is proven.
3. Re-validate each change with `RBACGOVG-Validation.ps1` / `RBACGOVG-Report.ps1`.

> Role-policy deadlock warning: if you create an access policy for the **Role** (RBAC) profile type,
> every role change — including the RBAC assignments MAA itself needs — then requires approval, which
> can deadlock you. Configure and verify all other MAA and RBAC assignments **first**; add a Role
> access policy last. To break a deadlock: Multi Admin Approval → Access policies → delete the Role
> policy, wait 3–5 minutes, complete the RBAC assignment, then re-create the Role policy if desired.

> Rollback note: if an assignment or approval gate is too tight, loosen or remove it using your
> break-glass Global Administrator (excluded from the gate). `RBACGOVG-Remediation.ps1` runs with
> `-WhatIf` by default so you can preview any tightening before it is applied.

---
### Order of operations
`Scope groups → Scope tag → Custom roles → Role assignment → Tag objects → Approver group into a role → App approval policy → Script approval policy → Pilot approval → Validate/report → Expand`
