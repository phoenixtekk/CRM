# Solution Overview

## What this solution is

This solution is a **procedural implementation playbook for Google Workspace Migration for Microsoft
Exchange (GWMME)** — the free Google-provided tool that migrates **email, calendar, and contacts**
from Microsoft Exchange (on-premises Exchange Server) and **Microsoft 365 / Exchange Online** into
Gmail on Google Workspace. It takes a competent Workspace migration engineer from a cold start to a
validated, batched cutover: install and configure GWMME on a suitable host, grant the required
Exchange/M365 access and Google service identity, build the user-mapping data GWMME consumes, run a
pilot batch, validate mail/calendar/contacts, then scale batches with throttling awareness.

GWMME is a **client-side migration utility**: it runs on a Windows host you control, authenticates to
the Microsoft source and to the Google destination, and copies mailbox items over. Because it is a
tool with its own installer, UI, and versioned behavior, this playbook covers it at the **procedural
level** — architecture, prerequisites, access, mapping design, wave sequencing, throttling, and
validation. **Deep GWMME console internals, exact dialog labels, licensing, and support are deferred
to Google's own GWMME documentation** and are flagged **"verify for your version"** wherever
version- or build-dependent behavior matters. Nothing about the tool's internal behavior is invented
here.

## Where GWMME fits (and where it does not)

Choosing the right migration tool is a design decision, not a default. GWMME is the correct choice for
a specific shape of project:

- **GWMME — mail-focused, smaller-to-mid scale.** Migrates **mail, calendar, and contacts** only.
  It is a **single-host, client-side** tool: throughput is bounded by that host, the network, and
  source/destination throttling. It is ideal for **smaller organizations, departmental moves,
  or the mail/calendar/contacts portion of a larger program** where a lightweight, no-server-
  infrastructure tool is preferred. It does **not** migrate Drive/OneDrive/SharePoint files,
  Teams, or chat history.
- **Google Workspace Migrate — larger scale, more data types.** A **server-based** platform (with a
  management/node architecture) built for **large enterprises** and broader data types (including
  **Drive/file data**). Choose it when scale, parallelism, or file migration exceed what a
  single-host tool handles. (Covered by its own solution; its console internals are deferred to
  Google's docs.)
- **Third-party tools (BitTitan MigrationWiz, CloudM Migrate, etc.)** — used when you need
  coexistence features, multi-workload coverage in one pane, or SaaS-hosted orchestration. Integrated
  at the pattern level; their internals are deferred to those vendors.

> **Rule of thumb:** if the move is **mail/calendar/contacts** for a manageable user count and you
> want zero server infrastructure, GWMME fits. If you must move **files at enterprise scale**, plan
> Google Workspace Migrate (or a third-party tool) for that portion and, optionally, GWMME for mail.

## How GWMME works (reference model)

1. **Host.** GWMME is installed on a **Windows migration host** — a dedicated, well-connected machine
   (a jump box / VM) reserved for the migration. This host reaches both the Microsoft source and the
   Google destination.
2. **Source connection.** GWMME connects to the Exchange source. For **Exchange Online / Microsoft
   365** this is over **Exchange Web Services (EWS)** / the M365 endpoints; for **on-premises
   Exchange** it connects to the Exchange server's EWS. GWMME reads mailbox items using a source
   identity that has been granted the right to read the mailboxes in scope (impersonation /
   application access — see Requirements).
3. **Destination connection.** GWMME authenticates to Google Workspace using a **Google service
   identity** (a service account / OAuth credential authorized for the migration scopes) so it can
   write mail, calendar, and contacts into each target user's Gmail.
4. **Mapping.** GWMME migrates according to a **user-mapping** input (which source mailbox maps to
   which Google target user), typically expressed as a **CSV / mapping file** the tool consumes.
5. **Batches (waves).** You migrate in **batches** — sets of mailboxes run together — rather than all
   at once, so you can control load, respect throttling, and validate each wave before the next.
6. **Validation.** After each batch you validate that **mail folders, calendar events, and contacts**
   arrived complete, triage per-item errors, and re-run deltas as needed.

> **Verify for your version:** the exact GWMME connection dialogs, supported Exchange/EWS versions,
> the precise mapping-file columns, and the retry/delta behavior are defined by the GWMME build you
> download. Confirm them against Google's current GWMME documentation before executing.

## Naming convention (used throughout)

Every artifact this playbook creates is named `<Purpose> – <Scope> – <Stage>` and the **same name is
reused** in implementation, testing, troubleshooting, and the scripts:

- `Migration Host – GWMME – Primary` — the Windows host running GWMME.
- `Source Access – Exchange – App Impersonation` — the Microsoft-side identity/permission GWMME reads with.
- `Service Identity – Google – Migration` — the Google service account/credential GWMME writes with.
- `Mapping – Users – Master` — the full source→target user map (superset).
- `Migration Wave – Pilot – 01` … `Migration Wave – Finance – 02` — the batch definitions.
- `Validation Report – Pilot – 01` — the per-wave completeness report.
- `Rollback Plan – Cutover – Mail` — the documented back-out for mail-flow/cutover changes.

## Deployment model

This solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
**pilot-first**, with explicit pass/fail gates and a documented rollback for every production change
(mail routing, DNS/MX, and cutover are high-impact):

- **Assess** — inventory source mailboxes, sizes, item counts, and special cases (shared mailboxes,
  large mailboxes, resource calendars); confirm the source is a fit for GWMME.
- **Design** — decide GWMME vs. alternatives for each data type, define waves, the throttling budget,
  and the coexistence/cutover approach; write the rollback.
- **Configure** — build the host, grant source and destination access, install GWMME, build the
  master mapping.
- **Pilot** — run `Migration Wave – Pilot – 01` on a small, representative set.
- **Validate** — confirm mail/calendar/contacts completeness against the gates; triage errors.
- **Expand** — scale batches wave by wave, each behind its own gate, until complete; then cut over.

## Benefits

- **Right-sized tool, right-sized effort** — GWMME needs no migration server farm; a single host
  moves mail/calendar/contacts with a documented, repeatable procedure.
- **Complete mailbox data** — mail, calendar, and contacts validated per wave, so nothing is
  silently dropped.
- **Throttle-aware batching** — waves sized to the source/destination limits avoid the failed,
  half-finished runs that come from firing everything at once.
- **Low-risk, pilot-first** — every production change has a pass/fail gate and a rollback.
- **Repeatable & auditable** — named artifacts, mapping CSVs, and validation reports make each wave
  traceable.

## Limitations (scope boundaries)

- **Mail, calendar, contacts only.** No Drive/OneDrive/SharePoint files, no Teams, no chat. Plan a
  separate tool (Google Workspace Migrate or third-party) for those.
- **Single-host throughput.** Scale is bounded by the host, network, and throttling; very large
  estates may be better served by a server-based platform.
- **Tool internals deferred.** Exact GWMME dialogs, supported versions, and licensing are Google's to
  define — always confirm against current GWMME documentation for your build.
- **Not a coexistence engine.** GWMME copies data; it does not provide long-running free/busy or
  cross-platform mail coexistence. Coexistence, if needed, is a separate design.
