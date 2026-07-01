# 5. Testing Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval)

Run after the pilot approval is configured (Implementation Step 8) and after each governance change.

## Test 1 — Custom roles exist and are scoped
Do: Intune → Tenant administration → Roles → All roles → confirm `App Manager – Region A – Prod` and
`Policy Reader – All – Audit`; or run `RBACGOV-Validation.ps1`.
Expected: Both custom roles exist with only their intended permissions and scope tags.

## Test 2 — Role assignment is correct
Do: Open `App Manager – Region A – Prod` → Assignments → confirm `App Manager Assignment – Region A – Prod`.
Expected: Members = `Intune Admins – Region A – Prod`; scope tag = `Region A – Devices – Prod`; scope
groups as designed.

## Test 3 — Scope tags limit visibility
Do: Sign in as a member of `Intune Admins – Region A – Prod`.
Expected: Only objects carrying `Region A – Devices – Prod` are visible/manageable; objects without
the tag are hidden.

## Test 4 — Least privilege holds
Do: As the app-manager admin, attempt an action outside the role (for example create a device
compliance policy).
Expected: The action is blocked / not available — the role grants app permissions only.

## Test 5 — Access policies exist and target the approver group
Do: Tenant administration → Multi admin approval → Access policies → confirm
`App Deploy Approval – All – Prod` and `Script Deploy Approval – All – Prod`; or run
`RBACGOV-Validation.ps1`.
Expected: Both policies exist, target the correct resource types, and approver = `Change Approvers – Apps – Prod`.

## Test 6 — A gated change requires approval
Do: As an app-manager admin, change a gated app; as a different approver, review under Received
requests.
Expected: The change is held pending until a second admin approves; it does not apply on its own.

## Test 7 — Rejection blocks the change
Do: Submit another gated change and have the approver reject it with a note.
Expected: The change is not applied; the requester sees the rejection.

## Test 8 — Governance coverage report
Do: Run `RBACGOV-Report.ps1`.
Expected: A clear report of roles, scope-tag coverage, assignments, approval-policy coverage, and any
over-privileged assignments flagged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–7 pass on the pilot scope; one approval and one rejection behave correctly |
| Broad pass | Tests 1–6, 8 pass across the expanded scope before declaring governance complete |
