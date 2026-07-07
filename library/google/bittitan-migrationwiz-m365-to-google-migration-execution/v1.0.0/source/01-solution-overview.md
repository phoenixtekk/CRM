# 1. Solution Overview — BitTitan MigrationWiz: M365 → Google Migration Execution

## What this solution is
Many enterprises run their Microsoft 365 → Google Workspace move on **BitTitan MigrationWiz** — a
SaaS migration platform that moves **mailboxes, documents, and collaboration data** from a source
tenant to a target tenant over the vendors' own APIs. This solution is the **MigrationWiz execution
playbook**: it sets up the **project and endpoints** (the M365 source and the Google Workspace
target, each backed by a real app registration / service identity), deploys the **Device Management
Agent (DMA)** only where a local-source path requires it, configures the **mail**, **document**, and
**Teams-to-Chat** migration projects, runs **pre-stage** and **delta** passes with **throttling**,
and **validates** per user — executed **pilot-first** and **rollback-ready** so migrations run
predictably at enterprise scale.

It is authored at the **procedural playbook level**: architecture, prerequisites, endpoint and
project design, wave / pre-stage / delta sequencing, throttling, and validation. The
**MigrationWiz console internals** — exact screen labels, the deep behavior of each project option,
licensing (User Migration Bundle vs per-migration licenses), and support — are **deferred to
BitTitan's own documentation** and flagged **"verify for your version"** where console flow or
version-specific behavior matters. The Google Admin console, Google Cloud service-account/OAuth
setup, and the Microsoft Entra app-registration side are given at exact, current detail because they
are the parts the operator configures directly.

## Why this matters
Tool-driven migrations fail for predictable, avoidable reasons. The **endpoints are misconfigured** —
an Entra app registration missing a consented permission, a Google service account without
domain-wide delegation for the right scopes — so every item fails with an opaque authorization error
discovered at scale instead of on one test mailbox. **Throttling is ignored**, so the migration
either crawls (source/target API limits throttle it) or trips protective limits and stalls. There is
**no pre-stage**, so the entire mailbox and Drive corpus is attempted in the cutover window and the
cutover overruns. The **delta pass is misunderstood** — re-running is feared to duplicate items when,
run correctly, a delta pass brings only what changed since the last pass. And **nobody validates per
user**, so a mailbox is declared "migrated" while its recent mail, calendar, or Drive permissions
never arrived.

A disciplined approach fixes the cause. It stands up and **proves the endpoints** before any bulk
move, designs the **project structure** (which data types, which mappings) once, runs a heavy
**pre-stage pass** well ahead of cutover so only a small **delta** remains at the switch, sets
**throttling** deliberately, and **validates each user** across every data type — and only then cuts
over and expands by wave. MigrationWiz's own model is built for exactly this: **pre-stage (Pre-Stage
Migration) then a delta/full pass at cutover**, per-item **retry**, and **endpoints** that connect
each source/target with the credentials and app registrations the vendors require. Where this
solution touches vendor-specific behavior, it cites BitTitan's public documentation and flags
version-dependent detail for verification, rather than re-documenting the console.

## The MigrationWiz model (how the tool works)
MigrationWiz organizes a migration around a small set of objects. This solution designs and names
each one; the console mechanics of creating them are the vendor's to document.

- **MSPComplete / MigrationWiz workspace** — the account/customer context the migration runs in.
- **Endpoints** — a reusable connection to a source or target system (Microsoft 365, Google
  Workspace, and, for some paths, a document/OneDrive/SharePoint or Teams source). Each endpoint
  holds the connection type and the credentials / app-registration or service-account identity the
  vendor requires. This solution creates a **source M365 endpoint** and a **target Google Workspace
  endpoint** per project family.
- **Projects** — a migration of one **data type** for a set of line items: a **Mailbox** project
  (mail, calendar, contacts), a **Document/Personal-Drive** project (OneDrive → Drive, SharePoint →
  Shared Drives), and a **Collaboration/Teams** project (Teams → Google Chat/Spaces, "verify for
  your version"). Each project references a source and target endpoint.
- **Line items (users / migration pairs)** — the source→target mappings a project migrates, one row
  per user or resource. This solution generates these from the directory as a **CSV the tool
  consumes** — it does not invent a private MigrationWiz API.
- **Passes** — how a project runs: a **Pre-Stage Migration** (bulk-move historical data ahead of
  cutover, typically bounded by an age filter such as "older than N days"), then a **Full/Delta
  Migration** at cutover that moves only what remains. Re-runnable; per-item **retry** handles
  transient failures.
- **Device Management Agent (DMA)** — deployed to endpoints **only** where a project path needs a
  local agent (for example certain document/desktop-source scenarios). Cloud-to-cloud mail projects
  typically do not require it; **verify for your version and project type** which paths need the DMA
  before planning a deployment.

## Where MigrationWiz fits vs native tools
MigrationWiz is one of several supported patterns for an M365 → Google move; this solution governs
its execution. Google-native paths — the Admin-console **data migration service** and the desktop
**GWMME** — and other third-party tools each have their own solution. Choose MigrationWiz when its
throughput, coverage of mail **and** documents **and** collaboration in one platform, and per-item
retry/reporting fit the estate. The **wave, pre-stage/delta, coexistence, and validation discipline**
in this solution is the same regardless of tool; only the tool's own configuration differs, and that
configuration is deferred to BitTitan.

## Coexistence and mail routing during the transition
While part of the estate is on Gmail and part is still on Exchange Online, **inbound mail must reach
each user's current platform** and calendar free/busy should resolve across the divide. MigrationWiz
moves the mailbox contents; the **mail-flow coexistence** is a Google/DNS concern designed alongside:

- **Split delivery** — point the domain **MX at Google**; Gmail receives inbound mail and **routes
  onward to Exchange Online** the messages for users not yet migrated, per a routing rule keyed to the
  migrated population ([Google — split delivery](https://knowledge.workspace.google.com/admin/gmail/advanced/send-email-to-2-email-systems-with-split-delivery)).
- **Dual delivery** — deliver a copy to both systems, for archiving or a phased overlap
  ([Google — dual delivery](https://support.google.com/a/answer/9228551)).

**Lower the MX TTL** (for example to 300 seconds) ahead of cutover so routing changes take effect
quickly and a back-out is fast. Coexistence is **transitional** — decommissioned once the estate is
fully on Gmail.

## The named artifacts
Author these once and reuse the exact names across every project and wave, so the migration stays
legible across owners:

| Artifact | Name |
|---|---|
| Source/target scope & readiness baseline | `BTW Discovery – Source & Target – Baseline` |
| M365 source endpoint | `BTW Endpoint – M365 Source – Prod` |
| Google Workspace target endpoint | `BTW Endpoint – Google Target – Prod` |
| Mailbox migration project | `BTW Project – Mailbox – Prod` |
| Document migration project | `BTW Project – Documents – Prod` |
| Teams-to-Chat migration project | `BTW Project – Teams to Chat – Prod` |
| Line-item / user-mapping file | `BTW Mapping – User Pairs – Per Project` |
| Pilot wave | `BTW Wave – Pilot – Wave 0` |
| Per-wave production wave | `BTW Wave – <Segment> – Per Wave` |
| Pre-stage pass | `BTW Pass – Pre-Stage – Per Wave` |
| Delta / cutover pass | `BTW Pass – Delta Cutover – Per Wave` |
| Throttling profile | `BTW Throttle – Project Concurrency – Per Wave` |
| Per-user validation record | `BTW Validation – Mail/Docs/Chat – Per User` |
| DNS/MX cutover runbook | `BTW Cutover – DNS/MX – Per Wave` |

## What this is not
This solution **executes a MigrationWiz migration** and governs the wave/pre-stage/delta sequencing,
throttling, coexistence, and validation around it. It does **not** re-document MigrationWiz's console
screens, project-option internals, licensing, or support (deferred to BitTitan). It does not own the
program-level segmentation across mail/Drive/chat (that is the migration-program solution), and it
does not replace the tenant-decommission solution. The included Python tools read the **Google
Workspace** target (Admin SDK) and the **Microsoft 365 / Entra** source (Microsoft Graph)
**read-only**, and **generate the mapping/validation CSV artifacts MigrationWiz consumes and
produces** — they call **no** private BitTitan API and move no data themselves.

## The deployment model
> Baseline the source and target and design the endpoints/projects once, prove the whole migration
> (endpoints → project → pre-stage → delta → validate) on a named pilot wave, validate each user
> across mail **and** documents **and** chat against the gate, then cut over and expand wave by wave —
> the repeatable way: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit
> pass/fail gates and a documented, tested rollback for every production change (mail flow, DNS,
> sharing, cutover).
