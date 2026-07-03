# 5. Testing Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

Run after the pilot approval is configured (Implementation Step 9) and after each governance change.
All portal steps use `https://intune.microsoft.us`; all scripts connect with `-Environment USGov`.

## Test 1 — Custom roles exist and are scoped
Do: `intune.microsoft.us` → Tenant administration → Roles → All roles → confirm
`App Manager – Region A – Prod` and `Policy Reader – All – Audit`; or run `RBACGOVG-Validation.ps1`.
Expected: Both custom roles exist with only their intended permissions and scope tags.

## Test 2 — Role assignment is correct
Do: Open `App Manager – Region A – Prod` → Assignments → confirm `App Manager Assignment – Region A – Prod`.
Expected: Members = `Intune Admins – Region A – Prod`; scope tag = `Region A – Devices – Prod`; scope
groups as designed.

## Test 3 — Scope tags limit visibility
Do: Sign in to `intune.microsoft.us` as a member of `Intune Admins – Region A – Prod`.
Expected: Only objects carrying `Region A – Devices – Prod` are visible/manageable; objects without
the tag are hidden.

## Test 4 — Least privilege holds
Do: As the app-manager admin, attempt an action outside the role (for example create a device
compliance policy).
Expected: The action is blocked / not available — the role grants app permissions only.

## Test 5 — Access policies exist and target the approver group
Do: Tenant administration → Multi Admin Approval → Access policies → confirm
`App Deploy Approval – All – Prod` and `Script Deploy Approval – All – Prod`; or run
`RBACGOVG-Validation.ps1`.
Expected: Both policies exist, target the correct resource types, and approver = `Change Approvers – Apps – Prod`.

## Test 6 — Approver group is correctly wired (GCC High)
Do: Confirm `Change Approvers – Apps – Prod` is a **security group**, is added to an Intune role
assignment as a member group, and its members hold the resource-specific Read permission.
Expected: Approver membership resolves and persists (Intune does not periodically strip it), and
approvers can open Received requests.

## Test 7 — A gated change requires approval
Do: As an app-manager admin, change a gated app with a Business justification; as a **different**
approver, review under Multi Admin Approval → Received requests and Approve; requester selects
**Complete**.
Expected: The change is held pending until a second admin approves; it does not apply on its own, and
only applies after the requester completes it.

## Test 8 — Rejection blocks the change
Do: Submit another gated change and have the approver reject it with a note.
Expected: The change is not applied; the requester sees the rejection and the Approver notes.

## Test 9 — Governance coverage report
Do: Run `RBACGOVG-Report.ps1`.
Expected: A clear report of roles, scope-tag coverage, assignments, approval-policy coverage, and any
over-privileged assignments flagged.

## Test 10 — Sovereign endpoint check (GCC High)
Do: Run any script and confirm the sign-in prompt is `login.microsoftonline.us` and Graph calls hit
`graph.microsoft.us`; from the admin workstation reach `https://graph.microsoft.us`.
Expected: Authentication and Graph calls stay in the US Government cloud — never `*.com`.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–8, 10 pass on the pilot scope; one approval and one rejection behave correctly, all against `*.us` endpoints |
| Broad pass | Tests 1–6, 9, 10 pass across the expanded scope before declaring governance complete |
