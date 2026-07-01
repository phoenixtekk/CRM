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
