# 5. Testing Guide — Entra Privileged Identity Management (PIM)

Run after the pilot configuration applies (Implementation Step 6) and on the recurring governance
cadence. Keep a break-glass account available throughout.

## Test 1 — Standing-access baseline is complete
Do: Run `ENTPIMG-Discovery.ps1` (add `-IncludeAzureResources` if Azure roles are in scope).
Expected: Every active privileged assignment is listed with account, role, scope, and whether it is
permanent — a usable conversion worklist.

## Test 2 — Break-glass accounts are protected
Do: Run `ENTPIMG-Alerting.ps1`.
Expected: Both `bg-admin-01` / `bg-admin-02` are permanently active Global Administrators, are **not**
PIM-eligible, are excluded from broad CA/MFA policies, and have a sign-in alert configured.

## Test 3 — Activation policy is set correctly
Do: Run `ENTPIMG-Validate.ps1`, or check `Microsoft Entra roles -> Settings -> <role>`.
Expected: Each onboarded role requires MFA and justification; Tier-0 roles require approval with
`PIM Privileged Role Approvers - Tenant - Steady` as approvers; max duration matches the tiering.

## Test 4 — Just-in-time activation works
Do: As a pilot admin, activate an eligible role from `My roles`, completing MFA and justification.
Expected: The role is granted for the configured window, admin work succeeds, and the role
auto-expires at the end — privilege returns to zero with no manual removal.

## Test 5 — Approval gate works (Tier-0)
Do: As a pilot admin, request activation of an approval-gated role.
Expected: Activation is pending until an approver in `PIM Privileged Role Approvers - Tenant - Steady`
approves; on approval the role activates, on denial it does not.

## Test 6 — No standing privilege remains for the pilot cohort
Do: Run `ENTPIMG-Discovery.ps1` filtered to the pilot cohort after Step 5.
Expected: Pilot admins hold the roles as **eligible**, not active; only break-glass accounts still hold
permanent Global Administrator.

## Test 7 — Activation is audited
Do: Run `ENTPIMG-Report.ps1`.
Expected: Each activation appears with actor, role, justification, approver (if any), start time, and
expiry — an audit trail suitable for compliance evidence.

## Test 8 — Access review runs
Do: Run `ENTPIMG-Report.ps1 -AccessReviews`, or check `Microsoft Entra roles -> Access reviews`.
Expected: `Privileged Role Access Review - Tenant - Quarterly` is active on schedule with reviewers
assigned and auto-apply enabled.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–5 pass; the pilot cohort is converted to eligible (Test 6) and an activation is audited (Test 7) |
| Expand pass | Tests 1–3, 6–8 pass tenant-wide; only break-glass accounts hold permanent Global Administrator; access reviews and alerts are on a schedule |
