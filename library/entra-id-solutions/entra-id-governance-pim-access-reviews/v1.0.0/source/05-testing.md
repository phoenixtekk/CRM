# 5. Testing Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

Run after the pilot scope is configured (Implementation Step 9) and after each governance cycle or
expansion.

## Test 1 — Role is eligible, not standing
Do: Entra -> `Identity governance -> Privileged Identity Management -> Microsoft Entra roles -> Assignments`; or run `IGA-Validation.ps1`.
Expected: The onboarded pilot role shows Eligible assignments for pilot admins; no unexpected standing (active) assignments except documented break-glass.

## Test 2 — Activation is approval-gated and time-bound
Do: A pilot admin activates the role in PIM (justification + MFA); an approver approves.
Expected: Activation requires approval and MFA, records a justification, grants the role for the configured window, and expires automatically.

## Test 3 — Break-glass excluded
Do: Confirm the two break-glass accounts still hold permanent active `Global Administrator` and are not subject to PIM activation; run `IGA-Validation.ps1`.
Expected: Break-glass accounts sign in without PIM activation; they are flagged as intentionally excluded, not as a violation.

## Test 4 — Privileged-role access review works
Do: Open `Access Review – Privileged Roles – Pilot`; a reviewer records approve/deny decisions; let auto-apply run.
Expected: Denied access is removed on apply; the review is logged with reviewer decisions.

## Test 5 — App/group access review works
Do: Open `Access Review – App Access – Pilot`; a reviewer recertifies membership.
Expected: Unapproved members are removed on apply; decisions are recorded.

## Test 6 — Access package grants with policy and expiry
Do: A pilot user requests `Access Package – App Access – Pilot`; an approver approves.
Expected: Access is granted per the resource role, subject to approval, and carries the configured expiry (or scheduled review).

## Test 7 — Governance coverage report
Do: Run `IGA-Report.ps1`.
Expected: A clear picture of standing vs eligible privileged assignments, roles onboarded to PIM, access reviews in place, and access packages published.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-4 pass; activation is approval-gated and time-bound; break-glass excluded |
| Expand pass | Tests 5-7 pass for the broader scope before onboarding `Global Administrator` tenant-wide |
