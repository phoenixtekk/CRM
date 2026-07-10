# 6. Troubleshooting — Entra ID Governance: Access Reviews & Entitlement Management

Symptom → likely root cause → fix. Start with **`ENTIGA-Discovery.ps1`** (are the named objects present
and wired?) and **`ENTIGA-Validate.ps1`** (which gate is failing?) — most governance issues are a
missing policy scope, a licensing gap, or an empty attribute the flow depends on.

## The Identity Governance blades show a licensing banner / creation is blocked
- **Root cause:** the operator or the in-scope users lack **Entra ID Governance / P2** licensing;
  lifecycle workflows need the **Entra ID Governance** SKU specifically.
- **Fix:** assign the correct license (M365 admin center → **Billing → Licenses**) to the operator and to
  requestors/reviewers/workflow-targeted users. Re-open the blade. *Verify current SKU coverage against
  Microsoft's documentation — it changes.*

## An access package isn't requestable in My Access
- **Root cause:** no assignment **policy** targets the requestor, the requestor isn't in the policy's
  scope (`ENTIGA-Pilot` only during pilot), or the catalog isn't **enabled for external users** (for a
  guest requestor).
- **Fix:** confirm `ENTIGA – Policy – Employees – Approval` scopes the user (or the group they're in);
  for guests, confirm the catalog is **enabled for external users** and `ENTIGA – Policy – Guests –
  TimeBound` allows their connected organization. `ENTIGA-Validate.ps1` reports policy scope.

## Approval never arrives / request sits pending
- **Root cause:** the approver is **Manager** but the requestor has **no manager** set; or the named
  approver is disabled; or the approver isn't checking **My Access → Approvals**.
- **Fix:** populate the **Manager** attribute (Requirement 2.5 — `ENTIGA-Report.ps1` lists users missing
  one), or set a **named/fallback approver**. Confirm the approver acts in **My Access**, not email alone.

## A granted assignment has no expiry (access is permanent)
- **Root cause:** the assignment policy's **Lifecycle → Expiration** was left at **Never**.
- **Fix:** edit the policy → **Lifecycle** → set **Access expires → After N days**; enable
  **Require access reviews** on renewal. Existing permanent grants can be ended and re-requested under the
  time-bound policy.

## An access review Deny didn't remove access
- **Root cause:** **Auto apply results** is **Disabled**, so decisions are recorded but not enforced; or
  the review is still in progress; or "if reviewers don't respond" was set to **No change** and nobody
  acted.
- **Fix:** edit the review → **Settings → Enable auto apply results**. Confirm the review has **ended**
  (decisions apply at cycle end). `ENTIGA-Validate.ps1` flags reviews without auto-apply.

## An access review removed access it shouldn't have
- **Root cause:** "if reviewers don't respond" was set to **Remove access** on the **first** cycle and
  reviewers didn't respond in time.
- **Fix:** for early cycles set don't-respond to **No change** and review manually; switch to **Remove
  access** once reviewers are trained. Restore the removed access by re-requesting/re-approving the
  package or re-adding the membership.

## A guest can't request the guest package
- **Root cause:** the catalog isn't **enabled for external users**, the guest's organization isn't a
  recognized **connected organization**, or `ENTIGA – Policy – Guests – TimeBound` scopes a different set
  of external users.
- **Fix:** enable the catalog for external users; add the guest's domain as a **connected organization**
  (Requirement 2.7); confirm the guest policy's requestor scope. `ENTIGA-GuestReview.ps1` shows current
  guests and their source.

## A lifecycle workflow didn't fire on schedule
- **Root cause:** the trigger attribute (**`employeeHireDate`** / **`employeeLeaveDateTime`**) is empty
  or in the wrong format, the user isn't in the workflow **scope**, or the workflow is **disabled**.
- **Fix:** `ENTIGA-Lifecycle.ps1` reports which in-scope users have the trigger attributes populated.
  Populate the attribute from the HR source, confirm the scope rule resolves the user, and ensure the
  workflow is **enabled**. Test **on-demand** first.

## A leaver ran but access/sessions remained
- **Root cause:** the leaver workflow is missing the **remove-assignments / disable / revoke-sessions**
  tasks, or the user's access came from a source the tasks don't cover (e.g. a directly-assigned app role
  outside a package).
- **Fix:** confirm `ENTIGA – Leaver – Offboarding` includes **Remove from all groups/Teams**, **Remove
  all access package assignments**, **Disable account**, and **Revoke all refresh tokens**. Access granted
  outside entitlement management must be removed by its own mechanism (or brought under a package).

## Editing / rebuilding a package broke existing grants
- **Root cause:** removing a **resource role** from a package or deleting a policy can affect existing
  assignments that depend on it.
- **Fix:** change packages additively where possible; when a resource role must change, communicate and
  re-issue assignments. Keep the pilot separate from production packages so experiments don't touch live
  access.

---
### First moves for any governance issue
1. `ENTIGA-Discovery.ps1` — are the named catalog/package/policy/review/workflow objects present?
2. `ENTIGA-Validate.ps1` — which gate is failing (missing expiry, no auto-apply, disabled workflow)?
3. `ENTIGA-Lifecycle.ps1` / `ENTIGA-Report.ps1` — are the driving attributes (manager, hire/leave dates)
   populated for the affected users?
4. Only then change configuration — preview any remediation with `-WhatIf`, and keep the current state as
   your rollback.
