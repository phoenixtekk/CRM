# 5. Testing Guide — Scoping Application-Permission Mailbox Access

Run after the scope is configured and **after propagation has completed** (Implementation Step 4 for Model A / Step 6 for Model B). Both scoping models are validated the same way — the boundary behaviour is identical, only the mechanism differs. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names.

> **Propagation:** a new Application Access Policy or RBAC assignment is **not** instant. Testing too early gives a false result (an out-of-scope read may still succeed for a short window). Allow the propagation time (commonly cited up to ~30 minutes; *verify with Microsoft*) before trusting a DENIED/allowed result.

## Test 1 — The app is scoped, not tenant-wide
**Do:** Run `MBXRBAC-Validate.ps1`; or confirm the policy/assignment exists (Model A: `Get-ApplicationAccessPolicy`; Model B: the RBAC role assignment — *verify cmdlets*).
**Expected:** `Mailbox Reporting App` (`AppId` `11111111-1111-1111-1111-111111111111`) is covered by `App Mailbox Scope – Reporting – Prod – Policy` **or** `App Mailbox Scope – Reporting – RBAC Assignment`. The app is reported **scoped**, not tenant-wide.
**PASS/FAIL:** PASS = a scope covers the app. FAIL = the app is still tenant-wide.

## Test 2 — Microsoft's built-in policy test (Model A)
**Do:** `Test-ApplicationAccessPolicy -Identity "reports@contoso.com" -AppId "11111111-1111-1111-1111-111111111111"` and again with `-Identity "ceo@contoso.com"` (*verify cmdlet name*).
**Expected:** `reports@contoso.com` → **Granted/AccessCheckResult = Granted**; `ceo@contoso.com` → **Denied**.
**PASS/FAIL:** PASS = in-scope Granted **and** out-of-scope Denied. FAIL = either result is wrong.

## Test 3 — In-scope mailbox read SUCCEEDS
**Do:** Run `MBXRBAC-Test-Boundary.ps1` (it authenticates **as the application** and reads `reports@contoso.com`); or manually call Graph `GET /users/reports@contoso.com/messages?$top=1` with an **application** token for the app.
**Expected:** The read **succeeds** (HTTP 200, at least the message metadata is returned).
**PASS/FAIL:** PASS = in-scope read returns 200. FAIL = in-scope read is denied (scope too tight / wrong group membership — see Troubleshooting).

## Test 4 — Out-of-scope mailbox read is DENIED
**Do:** With the **same** application token, read `ceo@contoso.com` (Graph `GET /users/ceo@contoso.com/messages?$top=1`); `MBXRBAC-Test-Boundary.ps1` does this automatically.
**Expected:** The read is **denied** — HTTP **403** with an `ErrorAccessDenied`-class error (the app is not scoped to this mailbox).
**PASS/FAIL:** PASS = out-of-scope read returns 403/denied. **FAIL = out-of-scope read succeeds** — the scope is not in effect (wrong model applied, mis-scope, or propagation not complete). This is the critical failure the whole solution exists to prevent.

## Test 5 — Evidence captured for auditors
**Do:** Run `MBXRBAC-Report.ps1` and save the CSV.
**Expected:** A tenant report showing every mail-capable application permission and, for each, whether it is scoped and to which mailboxes — with `Mailbox Reporting App` shown scoped to `App Mailbox Scope – Reporting – Prod` / the RBAC scope.
**PASS/FAIL:** PASS = the report shows the app scoped and names the allowed mailboxes; the boundary is auditable without re-running a live read.

## Test 6 — Rollback restores prior state (change-safety check)
**Do:** In a non-production rehearsal, remove the policy/assignment (Model A: `Remove-ApplicationAccessPolicy`; Model B: `Remove-ManagementRoleAssignment` — *verify cmdlets*), re-run `MBXRBAC-Validate.ps1`, then re-apply.
**Expected:** After removal the app reports **tenant-wide** again (proving the scope was what constrained it); after re-apply it reports **scoped**.
**PASS/FAIL:** PASS = removal and re-apply both behave as expected, confirming a working rollback.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Scoped** | Test 1 passes — a policy/assignment covers `Mailbox Reporting App`; it is not tenant-wide |
| **Boundary proven** | Tests 3 **and** 4 pass — in-scope read **succeeds**, out-of-scope read is **DENIED (403)**. Both are required |
| **Auditable** | Test 5 passes — the scoping report names the app and its allowed mailboxes |
| **Reversible** | Test 6 passes — rollback restores prior state cleanly |

**Do not declare an app scoped unless Test 4 (out-of-scope DENIED) passes.** A passing in-scope read alone does not prove least privilege.
