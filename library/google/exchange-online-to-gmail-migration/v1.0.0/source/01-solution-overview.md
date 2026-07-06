# 1. Solution Overview — Exchange Online → Gmail Migration (Mail, Calendar, Contacts)

## What this solution is
Email is the highest-visibility, highest-risk part of a Google move: it is where users feel every
delay, every lost item, and every mis-delivered message immediately. This solution migrates
**Exchange Online mailboxes to Gmail** — **mail, calendar, and contacts** — with the right tooling
pattern, a **coexistence / mail-routing** design for the period the estate is split, a governed
**DNS/MX cutover**, and **per-user validation**, executed **pilot-first** and **rollback-ready** so
nothing is lost and users land smoothly. It is the per-service mail-migration workstream that the
broader **M365 → Google Workspace migration program** sequences and gates; where that program owns
segmentation and program governance across mail, Drive, and chat, this solution owns the **mail,
calendar, and contacts** mechanics and the mail-flow cutover for a given wave.

## Why this matters
Mail migrations fail for predictable reasons. There is no pilot, so an architectural problem —
a mis-mapped resource calendar, a broken free/busy lookup, a routing loop — is discovered at fleet
scale instead of on 50 users. Coexistence is an afterthought, so while half the estate is on each
platform, inbound mail is lost or double-delivered and cross-platform meetings fail. The DNS/MX
cutover is treated as a flip of a switch rather than a change-controlled step with a back-out, so a
bad change takes mail down with no rollback. And nobody validates per user, so a mailbox is declared
"migrated" while its calendar events, contacts, or recent mail never arrived. A disciplined approach
fixes the cause: it picks the tooling deliberately, designs coexistence up front, proves the whole
cutover on a named pilot batch, validates mail **and** calendar **and** contacts per user, and only
then cuts over DNS/MX and expands by wave. Google's own guidance is consistent — migrate email,
calendar, and contacts through a supported tool, run **delta migrations** so re-runs bring only new
mail without duplicating, and route mail during the transition with **split or dual delivery**
([Google — migrate email with the data migration service](https://knowledge.workspace.google.com/admin/migrate/migrate-email-with-the-new-data-migration-service),
[Google — split delivery](https://knowledge.workspace.google.com/admin/gmail/advanced/send-email-to-2-email-systems-with-split-delivery),
[Google — dual delivery](https://support.google.com/a/answer/9228551)).

## The data types in scope
The migration moves three user-facing data types, each with its own validation:

- **Mail** — the mailbox contents (folders/labels, read/unread state, and history), migrated to
  Gmail. Supported tools run **delta migrations**, so a second pass brings only mail that arrived
  since the last run without duplicating what already moved
  ([Google — migrate email with the data migration service](https://knowledge.workspace.google.com/admin/migrate/migrate-email-with-the-new-data-migration-service)).
- **Calendar** — primary and additional calendars and their events (all-day events, attendees,
  status, sensitivity, reminders), migrated to Google Calendar; **resource/room calendars** import
  when a suitable mapping is provided
  ([Google — what's imported from Exchange Online](https://knowledge.workspace.google.com/admin/migrate/whats-migrated-in-an-exchange-online-migration)).
- **Contacts** — the user's contacts, migrated to Google Contacts. Contact migration is supported by
  the desktop migration tool for Exchange (mail, calendar, **and** contacts in one operation)
  ([Google — about GWMME](https://knowledge.workspace.google.com/admin/migrate/about-gwmme)).

## The tooling pattern (tool-agnostic)
This solution is authored **tool-agnostically** — it governs *which pattern and when*, not one
vendor's console clicks. Two supported Google-native patterns exist, plus common third-party tools;
choose per the estate and record the choice as `GWGMAIL Design - Tooling & Data Types - Mail`:

- **Data migration service (Admin console).** Google's built-in **data migration service** migrates
  email from Exchange Online directly from the Admin console, with **delta migrations** and a
  per-batch user limit (Google states up to **250 users at a time**); calendar migration from
  Exchange Online is available alongside mail. Requires a Workspace **super admin** and, on the
  source side, a **Microsoft Entra administrator** to authorize the connection
  ([Google Workspace Updates — migrate email & calendar from Exchange Online](https://workspaceupdates.googleblog.com/2025/06/migrate-email-calendar-content-from-microsoft-exchange-online-to-google-workspace.html),
  [Google — use the default data import method for Exchange Online](https://knowledge.workspace.google.com/admin/migrate/migrate-data-from-an-exchange-online-account)).
- **Desktop migration tool for Exchange (GWMME).** The **Google Workspace Migration for Microsoft
  Exchange** desktop tool migrates **mail, calendar, and contacts** for multiple users in one
  operation from Exchange/IMAP sources — the pattern to use when contacts must move as part of the
  same run or when the source is not covered by the Admin-console path
  ([Google — about GWMME](https://knowledge.workspace.google.com/admin/migrate/about-gwmme),
  [Google — what's migrated with GWMME](https://knowledge.workspace.google.com/admin/migrate/whats-migrated-with-gwmme)).
- **Third-party migration tools.** Where an estate's scale, throughput, or data-shape needs it, a
  third-party mail-migration tool is integrated at the pattern level. Its internal console steps are
  **deferred to the vendor's own docs** (per the Google-category vendor boundary); this solution
  governs the pilot-first sequencing, validation, and cutover around whichever tool is chosen.

> **Vendor boundary.** Migration-**tool internals** (screen-by-screen operation of the data migration
> service job, GWMME, or a third-party tool) are deferred to the vendor's own documentation. This
> solution authors the **repeatable pattern** — assess, configure, pilot, validate mail/calendar/
> contacts, manage coexistence, cut over DNS/MX, expand — around any of them.

## Coexistence and mail routing during the transition
While some users are on Gmail and some are still on Exchange Online, **inbound mail must reach the
right platform for each user** and calendar free/busy should resolve across the divide. Two routing
patterns cover this, per Google's docs:

- **Split delivery.** Point the domain's **MX at Google**; Gmail receives all inbound mail and
  **routes on** to Exchange Online the messages for users who have not yet migrated, per a routing
  rule keyed to the migrated population. This is the usual pattern for a per-wave move
  ([Google — split delivery](https://knowledge.workspace.google.com/admin/gmail/advanced/send-email-to-2-email-systems-with-split-delivery)).
- **Dual delivery.** Deliver a copy to a Gmail inbox **and** to the legacy system — used for
  archiving or a phased overlap where both mailboxes receive mail
  ([Google — dual delivery](https://support.google.com/a/answer/9228551)).

Lower the domain's **MX TTL** (for example to 300 seconds) ahead of the cutover so routing changes
take effect quickly and a back-out is fast. Coexistence is **transitional** — designed with an
intended end and decommissioned once the estate is fully on Gmail, never left running indefinitely.

## The cutover (DNS/MX)
The mail-flow cutover is a **change-controlled** step, not a switch flip. With MX pointed at Google
and split-delivery routing carrying not-yet-migrated users onward, each wave's cutover moves that
wave's users from "routed onward to Exchange" to "delivered in Gmail," and the final wave retires the
onward route entirely. Every DNS/MX change is staged with a **documented, tested back-out** so a
failed validation can be reversed under change control.

## The named artifacts
Author these once and reuse the exact names across every wave, so the migration stays legible across
owners and waves:

| Artifact | Name |
|---|---|
| Source mailbox/estate baseline | `GWGMAIL Discovery - Source Mailboxes - Baseline` |
| Tooling & data-types design | `GWGMAIL Design - Tooling & Data Types - Mail` |
| Coexistence / mail-routing design | `GWGMAIL Coexistence - Mail Routing - Transition` |
| Pilot migration batch | `GWGMAIL Pilot - Mail Batch - Wave 0` |
| Per-wave target group | `GWGMAIL Wave - Target Group - Per Wave` |
| Per-user validation record | `GWGMAIL Validation - Mail/Cal/Contacts - Per User` |
| DNS/MX cutover runbook | `GWGMAIL Cutover - DNS/MX - Per Wave` |

## What this is not
This solution moves **mail, calendar, and contacts** and governs the mail-flow cutover. It does not
own the program-level wave segmentation and cross-service governance (that is the **migration
program** solution), it does not migrate Drive or chat (their own solutions), and it does not
re-document a migration tool's internal screens (deferred to the vendor). Where the included scripts
read the source estate to plan and validate, they read **Microsoft 365 / Microsoft Entra** through
Microsoft Graph, **read-only** — they move no mail and change no mail flow.

## The deployment model
> Baseline the mailboxes and design the tooling/coexistence once, prove the full migration and cutover
> on a named pilot batch, validate mail **and** calendar **and** contacts per user against the gate,
> then cut over DNS/MX and expand wave by wave — the repeatable way: Assess, then Configure, then
> Pilot, then Validate, then Expand.
