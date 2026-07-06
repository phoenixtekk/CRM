# 3. Implementation Guide — Exchange Online → Gmail Migration (Mail, Calendar, Contacts)

Follow these steps in order. This guide migrates **Exchange Online mailboxes to Gmail** — mail,
calendar, and contacts — proving the full migration and DNS/MX cutover on a **named pilot batch**,
validating each user across all three data types, managing **coexistence** during the split, then
expanding **wave by wave**. Artifact names are fixed — create them with the exact names shown and
reuse them every wave. Migration-**tool internals** (the data migration service job screens, GWMME,
or a third-party tool) are deferred to the vendor's own docs; this guide governs the repeatable
pattern around them.

> Model: baseline and design once, prove the migration and cutover on a pilot batch, validate
> mail/calendar/contacts per user against the gate, then cut over DNS/MX and expand. The repeatable
> way: Assess, then Configure, then Pilot, then Validate, then Expand.

## Step 1 — Assess: baseline the source mailboxes
1. Run `GWGMAIL-Discovery.ps1` to baseline the Exchange Online source: total and licensed users,
   shared mailboxes, resource/room mailboxes, and groups read from Microsoft 365 / Entra through
   Microsoft Graph (read-only). Record it as `GWGMAIL Discovery - Source Mailboxes - Baseline`.
2. Add the details the API cannot read: per-mailbox data volumes, contact counts, resource-calendar
   mappings, and any mail-touching integrations (relay connectors, forwarding rules, shared-mailbox
   delegation) that affect the migration or routing.
3. Record gaps against the Requirements checklist. Do not proceed past missing source access, missing
   target licensing, or a missing identity source of truth — resolve those first.

## Step 2 — Configure: fix the tooling and data-types design
1. Choose the migration **tool/pattern** and record it in `GWGMAIL Design - Tooling & Data Types - Mail`:
   - **Data migration service (Admin console)** — migrate email (and calendar) from Exchange Online
     from the Admin console, using **delta migrations** to finalize recent mail at cutover; needs a
     Workspace super admin and a source-side Microsoft Entra administrator, and migrates up to the
     per-batch user limit Google states (**250 users at a time**)
     ([Google — migrate email with the data migration service](https://knowledge.workspace.google.com/admin/migrate/migrate-email-with-the-new-data-migration-service),
     [Google Workspace Updates](https://workspaceupdates.googleblog.com/2025/06/migrate-email-calendar-content-from-microsoft-exchange-online-to-google-workspace.html)).
   - **Desktop tool (GWMME)** — migrate **mail, calendar, and contacts** together for multiple users;
     the pattern to choose when contacts must move in the same run
     ([Google — about GWMME](https://knowledge.workspace.google.com/admin/migrate/about-gwmme)).
   - **Third-party tool** — a named tool whose internal steps are deferred to its vendor docs.
2. Fix which **data types** move and in what order (typically mail and calendar aligned to the mail
   cutover, contacts alongside), and the **mappings** required — resource/room calendars and
   attendee/target-email mappings so calendar events resolve correctly
   ([Google — what's imported from Exchange Online](https://knowledge.workspace.google.com/admin/migrate/whats-migrated-in-an-exchange-online-migration)).
3. Decide the **delta** approach: an initial bulk pass ahead of cutover, then a delta pass at cutover
   that brings only new mail without duplicating.
4. Author the design **tool-agnostically** and **freeze** it before the pilot. Every wave runs this
   same design.

## Step 3 — Configure: design and stand up coexistence
1. Design the transition state as `GWGMAIL Coexistence - Mail Routing - Transition`:
   - **Mail routing.** Choose **split delivery** — point the domain **MX at Google**, and have Gmail
     **route onward to Exchange Online** the mail for users not yet migrated, per a routing rule keyed
     to the migrated population (the usual per-wave pattern) — or **dual delivery** where a copy goes
     to both systems ([Google — split delivery](https://knowledge.workspace.google.com/admin/gmail/advanced/send-email-to-2-email-systems-with-split-delivery),
     [Google — dual delivery](https://support.google.com/a/answer/9228551)).
   - **Calendar interop.** Define how free/busy resolves across the two platforms during the split so
     cross-platform scheduling works.
   - **Lower the MX TTL** (for example 300 seconds) ahead of the cutover so routing/DNS changes take
     effect quickly and a back-out is fast.
2. Stand up the routing on a test host/domain and prove it: a test message reaches the correct
   platform for a migrated and a not-yet-migrated user, and a cross-platform meeting resolves
   free/busy.
3. Set coexistence's intended **end** — it is transitional, decommissioned as the estate completes,
   never permanent.

## Step 4 — Configure: build the pilot batch
1. Assemble `GWGMAIL Pilot - Mail Batch - Wave 0`: a small, representative set (core IT and early
   adopters, plus at least one shared mailbox and one resource calendar so those paths are exercised).
2. Build the batch's target group with `GWGMAIL-Set-ScopeTargeting.ps1` (runs with `-WhatIf` by
   default; re-run with `-WhatIf:$false` to apply).

## Step 5 — Author the DNS/MX cutover runbook and rollback
1. Author `GWGMAIL Cutover - DNS/MX - Per Wave` with the fixed sequence:
   1. **Readiness** — the batch's target accounts are provisioned and licensed, the tool can read the
      source, and `GWGMAIL-Validation.ps1` reports the batch ready.
   2. **Migrate mail/cal/contacts** — run the tool for the batch: bulk mail + calendar + contacts
      ahead of cutover.
   3. **Coexistence routing** — apply the split/dual-delivery routing so the batch's mail follows them
      to Gmail, under change control.
   4. **Validate** — run `GWGMAIL-Validation.ps1` per user (mail **and** calendar **and** contacts)
      and `GWGMAIL-Report.ps1` for coverage; run a **delta pass** to finalize recent mail.
   5. **DNS/MX cutover** — apply the staged MX/DNS change for the wave with a documented back-out.
   6. **Rollback** — revert routing/DNS to the prior platform and re-point the batch, used only if the
      gate fails.
2. Define the go/no-go: the wave passes only when readiness held, all three data types validated per
   user, the delta pass is clean, and the DNS/MX change is applied and reversible.

## Step 6 — Pilot: run Wave 0 end to end
1. Build the Wave 0 group with `GWGMAIL-Set-ScopeTargeting.ps1 -WhatIf:$false`.
2. Execute the full runbook on the pilot batch: readiness → migrate mail/cal/contacts → coexistence
   routing → validate → DNS/MX cutover.
3. Run `GWGMAIL-Validation.ps1` per user and `GWGMAIL-Report.ps1` for coverage/exceptions. The pilot
   passes only when the whole runbook ran end to end and every user validated across all three data
   types.

## Step 7 — Validate: fix the runbook, not just the batch
1. Complete the Testing Guide for the pilot. Treat every issue as a **runbook/design** defect: fix the
   tooling design, the mappings, or the coexistence routing so later waves inherit the fix.
2. Remediate coverage/data gaps with `GWGMAIL-Remediation.ps1` (runs with `-WhatIf` by default) — for
   example re-queuing a mailbox's failed items or normalizing the wave members list — then re-run
   validation and the delta pass.

## Step 8 — Expand wave by wave
1. For each subsequent wave, re-run the same runbook: build the wave group
   (`GWGMAIL-Set-ScopeTargeting.ps1`), migrate mail/cal/contacts, apply coexistence routing, validate
   per user (`GWGMAIL-Validation.ps1`), report coverage (`GWGMAIL-Report.ps1`), run the delta pass, and
   cut over DNS/MX — passing the go/no-go before the next wave.
2. Keep the coexistence routing rule current as the migrated population grows so every user's mail
   always reaches their current platform; a stale rule silently mis-delivers.

## Step 9 — Decommission coexistence
1. After the **final** wave validates and cuts over, retire the split/dual-delivery routing and the
   onward route to Exchange Online, and finalize the MX so all mail is delivered in Gmail — never
   mid-migration. Confirm no forwarding loop or stale route remains.

---
### Order of operations
`Assess/baseline -> Design (tooling+data types) -> Coexistence -> Pilot batch -> Cutover runbook+rollback -> Wave 0 pilot -> Validate/fix runbook -> Expand wave by wave -> Decommission coexistence`
