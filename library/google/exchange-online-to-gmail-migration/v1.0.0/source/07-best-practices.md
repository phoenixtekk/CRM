# 7. Best Practices — Exchange Online → Gmail Migration (Mail, Calendar, Contacts)

Field-proven practices for moving mailboxes to Gmail **without losing data and without breaking mail
flow** — focused on cutover and coexistence.

- **Pilot the whole thing first.** Prove the full migration and DNS/MX cutover on a named pilot batch
  (`GWGMAIL Pilot - Mail Batch - Wave 0`) of core IT and early adopters — including at least one
  shared mailbox and one resource calendar — before any production wave. It is cheaper to find a
  mapping or routing defect in 50 users than in a business unit of thousands.
- **Validate all three data types per user.** A mailbox is not migrated until mail **and** calendar
  **and** contacts validate. Declaring "migrated" on mail alone hides missing calendars and contacts
  until users complain ([Google — what's imported from Exchange Online](https://knowledge.workspace.google.com/admin/migrate/whats-migrated-in-an-exchange-online-migration)).
- **Bulk-migrate ahead, delta at cutover.** Run an initial bulk pass before the cutover and a **delta
  migration** at cutover so only new mail moves — no duplicates, no long freeze at go-live
  ([Google — migrate email with the data migration service](https://knowledge.workspace.google.com/admin/migrate/migrate-email-with-the-new-data-migration-service)).
- **Stand up coexistence before the first cutover, and time-box it.** Mail routing and calendar
  interop must be live before anyone cuts over so migrated and not-yet-migrated users still mail and
  schedule each other — and coexistence is transitional, decommissioned as waves complete, never left
  running indefinitely ([Google — split delivery](https://knowledge.workspace.google.com/admin/gmail/advanced/send-email-to-2-email-systems-with-split-delivery),
  [Google — dual delivery](https://support.google.com/a/answer/9228551)).
- **Keep the routing rule following users.** As each wave completes, update the split/dual-delivery
  rule so every user's mail always reaches their current platform; a stale rule silently mis-delivers
  or double-delivers.
- **Lower the MX TTL before the cutover.** Drop the MX TTL (for example to 300 seconds) ahead of the
  cutover so routing/DNS changes apply quickly and a back-out is fast; raise it again once the estate
  is stable.
- **Treat the DNS/MX cutover as a change-controlled step, not a switch flip.** Apply every MX/DNS
  change under change control with a documented, tested back-out; a high-impact mail-flow change
  without a rollback is not ready to run.
- **Get the calendar mappings right up front.** Resource/room calendars and attendee/target-email
  mappings must be defined before the pilot, or events import without their rooms and attendees
  ([Google — what's imported from Exchange Online](https://knowledge.workspace.google.com/admin/migrate/whats-migrated-in-an-exchange-online-migration)).
- **Enable smart features ahead of the mail migration.** For the data migration service, enable smart
  features and personalization at least 24 hours before migrating so migrated mail sorts and searches
  correctly ([Google — about GWMME](https://knowledge.workspace.google.com/admin/migrate/about-gwmme)).
- **Fix the runbook, not just the batch.** Every issue found in a wave is a defect in the runbook,
  the tooling design, or the coexistence routing — fix it there so later waves inherit the fix, so
  each wave stops re-learning the same lesson.
- **Provision and license the target first, always.** A mailbox cannot land in an account that does
  not exist; provision each wave's Gmail accounts and licenses before any data moves or any routing
  addresses them.
- **Defer tool internals to the vendor.** This solution governs the pilot-first pattern, validation,
  coexistence, and cutover; the data migration service job, GWMME, and third-party tools' internal
  screens live in their own docs — keep the pattern tool-agnostic so a tooling change touches the
  tool layer, not the migration design.
- **Report coverage and exceptions cumulatively.** Track users migrated vs total and per-user
  mail/calendar/contacts coverage every cadence with `GWGMAIL-Report.ps1`; a stalled coverage trend
  or a growing exception list is an early warning.
