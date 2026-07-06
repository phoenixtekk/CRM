# 2. Requirements Guide — Exchange Online → Gmail Migration (Mail, Calendar, Contacts)

Verify every requirement before running the migration. Each entry gives Description, Why, Verify, and
Implement-if-missing. Category-wide prerequisites (the Google Workspace tenant, the source M365/Entra
environment, DNS control, the identity source of truth, a pilot scope, and governance stakeholders)
are in `global-requirements-google.md`; this guide adds what the Exchange-to-Gmail mail migration
specifically needs.

## 2.1 Source Exchange Online / M365 access for migration
Description: Administrative access to the source **Microsoft 365 / Exchange Online** tenant sufficient
to authorize a mailbox migration — the built-in data migration service requires a **Microsoft Entra
administrator** on the source side to authorize the connection; the desktop tool (GWMME) requires the
source mailbox access (service account / application access) its administration guide specifies.
Why: The tool reads each mailbox's mail, calendar, and contacts from Exchange Online; without
authorized source access no data can be read.
Verify: You can authorize the data migration service against Exchange Online as a Microsoft Entra
administrator, or GWMME can access the source mailboxes; run `GWGMAIL-Discovery.ps1` to confirm you
can read the source estate.
Implement-if-missing: Obtain the Entra administrator role (data migration service) or configure the
source mailbox/service-account access GWMME requires, per the tool's own documentation
([Google — migrate email with the data migration service](https://knowledge.workspace.google.com/admin/migrate/migrate-email-with-the-new-data-migration-service),
[Google — about GWMME](https://knowledge.workspace.google.com/admin/migrate/about-gwmme)).

## 2.2 Google Workspace target tenant and licensing (super admin)
Description: A provisioned Google Workspace tenant with a **super admin** account and Gmail-bearing
licenses for the users being migrated, with target accounts provisioned (per the identity source of
truth in the global requirements) before their mail lands.
Why: Mail, calendar, and contacts land in a licensed Google account; the data migration service and
GWMME both require a Workspace super admin, and a mailbox cannot migrate into an account that does not
yet exist.
Verify: Sign in to admin.google.com as super admin and confirm Gmail licenses for a sample wave;
confirm those users are provisioned in the Admin console.
Implement-if-missing: Provision licenses and the target accounts (GCDS/SCIM per the global
requirements) before scheduling the pilot.

## 2.3 A tooling & data-types design
Description: A decision record — `GWGMAIL Design - Tooling & Data Types - Mail` — fixing the migration
**tool/pattern** (data migration service, GWMME, or a named third-party tool), which **data types**
move (mail, calendar, contacts) and in what order, resource/room-calendar and attendee **mappings**,
and whether **delta migrations** will be used to finalize recent mail at cutover.
Why: Every wave must run the *same* tooling and data-type decisions; deciding per wave guarantees
rework and inconsistent outcomes. Delta migration is what lets a re-run bring only new mail without
duplicating ([Google — migrate email with the data migration service](https://knowledge.workspace.google.com/admin/migrate/migrate-email-with-the-new-data-migration-service)).
Verify: The design names the tool, the data types and order, the required mappings, and the delta
approach, and is agreed by the migration's technical owners.
Implement-if-missing: Hold the design step (Implementation Step 2) and freeze the design before the
pilot.

## 2.4 DNS / mail-flow control and a coexistence design
Description: Control of the domain's **DNS** (MX, SPF, DKIM, DMARC, TXT) and a coexistence design —
`GWGMAIL Coexistence - Mail Routing - Transition` — defining **split delivery** (MX at Google, Gmail
routes not-yet-migrated users onward to Exchange Online) or **dual delivery**, keyed to the migrated
population, with a **lowered MX TTL** for a fast cutover and back-out.
Why: While the estate is split, inbound mail must reach each user's current platform and free/busy
should resolve across the divide; without a coexistence design mail is lost or double-delivered.
Split delivery routes inbound mail to Google or Microsoft 365 per rule; dual delivery delivers to a
primary and a secondary ([Google — split delivery](https://knowledge.workspace.google.com/admin/gmail/advanced/send-email-to-2-email-systems-with-split-delivery),
[Google — dual delivery](https://support.google.com/a/answer/9228551)).
Verify: You can edit the authoritative DNS zone; the design specifies the routing pattern and the
free/busy approach; a test message and a cross-platform meeting resolve correctly in a lab.
Implement-if-missing: Coordinate DNS control, design coexistence in Step 3, stand up routing on a test
host, and prove it before the first production wave. Coexistence is transitional — set its intended
end.

## 2.5 A migration tool, configured
Description: The chosen migration tool is installed/authorized and reachable: the **data migration
service** connection to Exchange Online is authorized, or **GWMME** is installed with source access
per its administration guide, or the named third-party tool is licensed and configured.
Why: The pilot cannot run until the tool can read the source and write to the target; tool
configuration is a prerequisite, not a pilot step.
Verify: A single test mailbox migrates a small set of mail/calendar/contacts to a target test account
without error.
Implement-if-missing: Configure the tool per its own documentation (deferred — vendor boundary), then
prove one test mailbox before the pilot batch. For the data migration service, enable smart
features/personalization **at least 24 hours before** the migration so migrated mail sorts and
searches correctly ([Google — about GWMME](https://knowledge.workspace.google.com/admin/migrate/about-gwmme)).

## 2.6 A pilot batch and per-user validation
Description: A named pilot batch — `GWGMAIL Pilot - Mail Batch - Wave 0` — of a small, representative
user set (core IT and early adopters), plus a per-user validation record
`GWGMAIL Validation - Mail/Cal/Contacts - Per User` that confirms **all three** data types landed.
Why: The full migration and cutover must be proven on a pilot before any production wave, and each
migrated mailbox must be validated for mail **and** calendar **and** contacts — not declared done on
mail alone.
Verify: A named pilot batch exists and the per-user validation record covers the three data types;
build the batch with `GWGMAIL-Set-ScopeTargeting.ps1` and validate with `GWGMAIL-Validation.ps1`.
Implement-if-missing: Define the pilot batch, run it end to end (Implementation Steps 5–6), and
validate per user before expanding.

## 2.7 A DNS/MX cutover runbook with rollback and change control
Description: A repeatable cutover runbook — `GWGMAIL Cutover - DNS/MX - Per Wave` — with the fixed
sequence (readiness → migrate mail/cal/contacts → coexistence routing → validate → DNS/MX cutover →
rollback) applied under **change control**, with a documented, tested back-out.
Why: A DNS/MX change is high-impact; an ungoverned cutover with no rollback becomes an incident.
Verify: The runbook exists with all stages and a documented rollback; the change-control path and the
lowered MX TTL are in place.
Implement-if-missing: Author the runbook in Step 5, prove it on the pilot, and reuse it unchanged for
every wave.

---
## Checklist
- [ ] Source Exchange Online / Entra access authorized — `GWGMAIL-Discovery.ps1`
- [ ] Google Workspace target licensed + accounts provisioned (super admin)
- [ ] Tooling & data-types design frozen — `GWGMAIL Design - Tooling & Data Types - Mail`
- [ ] DNS control + coexistence design proven — `GWGMAIL Coexistence - Mail Routing - Transition`
- [ ] Migration tool configured; one test mailbox proven
- [ ] Pilot batch defined + per-user validation — `GWGMAIL Pilot - Mail Batch - Wave 0`
- [ ] DNS/MX cutover runbook + rollback + change control — `GWGMAIL Cutover - DNS/MX - Per Wave`
