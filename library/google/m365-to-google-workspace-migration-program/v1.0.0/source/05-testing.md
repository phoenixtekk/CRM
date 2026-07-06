# 5. Testing Guide — Microsoft 365 → Google Workspace Migration Program & Wave Plan

Run these per-wave validation gates for **every** wave — first for Wave 0 (the pilot), then for each
expansion wave — before that wave's go/no-go decision. Each test confirms one part of the cutover
runbook worked for the wave's population. A wave does not pass until its gate criteria are met.

## Test 1 — Baseline and wave assignment are complete
Do: Confirm every user in the wave is assigned to exactly one wave in
`GWMIGPROG Wave Plan - Segmentation - 150k` and appears in the wave's target group; run
`GWMIGPROG-Set-ScopeTargeting.ps1` (preview) to confirm membership.
Expected: The wave's members match the plan; no user is in two waves and none is unassigned.

## Test 2 — Readiness: identity and licensing provisioned
Do: Run `GWMIGPROG-Validation.ps1` for the wave.
Expected: The wave's users/groups are provisioned into Google and licensed; readiness signals report
present with no gaps.

## Test 3 — Coexistence routes mail correctly
Do: Send a test message to a migrated wave user and to a not-yet-migrated user; send one from each
back out.
Expected: Each message reaches the correct platform per the split/dual-delivery design — no loss, no
double delivery — matching `GWMIGPROG Coexistence - Mail & Calendar - Transition`.

## Test 4 — Coexistence resolves calendar free/busy
Do: Create a cross-platform meeting between a migrated user and a not-yet-migrated user.
Expected: Free/busy resolves both ways and the invite is delivered on both platforms.

## Test 5 — Mail-flow / DNS change applied under change control
Do: Confirm the wave's routing/DNS change was applied with an approved change record and a documented
back-out.
Expected: The change is recorded, reversible, and mail follows the wave's migrated users.

## Test 6 — Data move completed for the wave
Do: For a sample of wave users, confirm mail/calendar, Drive content (permissions preserved), and
chat/collaboration moved per the design; run `GWMIGPROG-Report.ps1`.
Expected: The report shows the wave's users migrated and covered across the in-scope services; sampled
users can access their moved data in Google Workspace.

## Test 7 — Rollback is proven available
Do: Review the wave's rollback step and confirm the back-out (revert routing/DNS, re-point the wave)
is documented and executable.
Expected: A clear, tested rollback exists for the wave; it is invoked only if the gate fails.

## Test 8 — Progress and coverage reported
Do: Run `GWMIGPROG-Report.ps1` for the program.
Expected: Cumulative migration progress/coverage (waves complete, users migrated vs total, coexistence
scope) renders without gaps for the wave.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Wave 0 (pilot) pass | Tests 1-8 pass; the full runbook ran end to end and every runbook defect is fixed in the runbook/design before expanding |
| Expansion wave pass | Tests 1-8 pass for the wave; the go/no-go gate `GWMIGPROG Gate - Go/No-Go - Per Wave` is cleared before the next wave starts |
| Program decommission | All waves passed and cleared hypercare before coexistence routing and the source-tenant footprint are retired |
