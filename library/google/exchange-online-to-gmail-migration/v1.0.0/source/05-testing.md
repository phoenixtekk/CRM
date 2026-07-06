# 5. Testing Guide — Exchange Online → Gmail Migration (Mail, Calendar, Contacts)

Run these validation gates for **every** batch — first for the pilot (`GWGMAIL Pilot - Mail Batch -
Wave 0`), then for each expansion wave — before that wave's DNS/MX cutover and go/no-go. Each test
confirms one part of the migration and cutover worked for the wave's population. A wave does not pass
until its gate criteria are met, and a mailbox is not "migrated" until mail **and** calendar **and**
contacts all validate.

## Test 1 — Batch membership is complete and correct
Do: Confirm every user intended for the wave is in the wave's target group and no one is in two waves;
run `GWGMAIL-Set-ScopeTargeting.ps1` (preview) to confirm membership.
Expected: The batch's members match the plan; no duplicate or missing assignment.

## Test 2 — Readiness: target accounts provisioned and licensed
Do: Run `GWGMAIL-Validation.ps1` for the batch.
Expected: Every batch user resolves in the source and has a Gmail-bearing target account provisioned
and licensed; readiness signals report present with no gaps.

## Test 3 — Mail migrated
Do: For a sample of batch users, confirm mailbox contents (folders/labels, read/unread, history)
landed in Gmail; run a **delta pass** and confirm it brings only new mail without duplicating
([Google — migrate email with the data migration service](https://knowledge.workspace.google.com/admin/migrate/migrate-email-with-the-new-data-migration-service)).
Expected: Sampled users see their mail in Gmail; the delta pass adds only new items, no duplicates.

## Test 4 — Calendar migrated
Do: For a sample of batch users, confirm primary and additional calendars, events (all-day,
attendees, status, sensitivity, reminders), and any resource/room calendars imported per the mapping
([Google — what's imported from Exchange Online](https://knowledge.workspace.google.com/admin/migrate/whats-migrated-in-an-exchange-online-migration)).
Expected: Calendars and events resolve in Google Calendar with attendees and resource mappings intact.

## Test 5 — Contacts migrated
Do: For a sample of batch users, confirm contacts landed in Google Contacts.
Expected: Non-deleted contacts appear for the sampled users, matching the source.

## Test 6 — Coexistence routes mail correctly
Do: Send a test message to a migrated batch user and to a not-yet-migrated user; send one from each
back out.
Expected: Each message reaches the correct platform per the split/dual-delivery design — no loss, no
double delivery — matching `GWGMAIL Coexistence - Mail Routing - Transition`
([Google — split delivery](https://knowledge.workspace.google.com/admin/gmail/advanced/send-email-to-2-email-systems-with-split-delivery)).

## Test 7 — Cross-platform free/busy resolves
Do: Create a cross-platform meeting between a migrated user and a not-yet-migrated user.
Expected: Free/busy resolves both ways and the invite is delivered on both platforms.

## Test 8 — DNS/MX cutover applied under change control
Do: Confirm the wave's MX/DNS change was applied with an approved change record, a lowered MX TTL, and
a documented back-out.
Expected: The change is recorded, reversible, and mail follows the wave's migrated users to Gmail.

## Test 9 — Coverage and exceptions reported
Do: Run `GWGMAIL-Report.ps1` for the batch.
Expected: Per-user coverage across mail/calendar/contacts renders; exceptions (users missing a data
type) are listed for remediation, not hidden.

## Test 10 — Rollback is proven available
Do: Review the wave's rollback step and confirm the back-out (revert routing/DNS, re-point the batch)
is documented and executable.
Expected: A clear, tested rollback exists; it is invoked only if the gate fails.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot (Wave 0) pass | Tests 1–10 pass; every pilot user validated across mail, calendar, and contacts; every runbook/design defect fixed before expanding |
| Expansion wave pass | Tests 1–10 pass for the wave; the DNS/MX cutover applied and reversible; go/no-go cleared before the next wave |
| Coexistence decommission | All waves migrated, validated, and cut over before the split/dual-delivery routing and onward route are retired |
