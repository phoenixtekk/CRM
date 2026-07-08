# 1. Solution Overview — Event-Based Retention (Microsoft Purview)

## What this solution is
Most retention is **date-based**: keep a document for *N* years from the day it was created, last modified,
or labeled — a clock the calendar starts on its own. But some of the most important records must retain
from an **event**, not a date: keep an employee record for *N years after termination*, a contract for *N
years after it expires*, a product record for *N years after end-of-life*. On the day the item is created
nobody knows when its clock should start; it only starts when the event happens. This solution is a
repeatable, pilot-first method to implement **event-based retention in Microsoft Purview** — the **event
types**, the **event-based retention (and record) labels** that start their clock on an event, and the
**asset-ID / keyword triggering** that raises a retention event and starts the clock on exactly the
matching content — configured, piloted, validated, and operable, so the capability is in place and
defensible.

It is deliberately **focused on the event-based mechanic**. The broader tenant-wide retention program —
date-based retention policies, the full records **file plan**, records declaration in depth, and
disposition-review operations — is the province of the org-wide **data lifecycle & records management**
product; where this solution needs that context it **references** that product rather than rebuilding it.
What this solution owns end-to-end is the piece that trips organizations up: getting an event to reliably
**start the retention clock on the right content at the right time**.

## The event-based mechanic — the core distinction
Event-based retention in Microsoft Purview is built from three parts that must be designed together:

- An **event type** is a named category of event — `Event Type – Employee-Termination`, `Event Type –
  Contract-Expiration`, `Event Type – Product-EndOfLife`. It is the reusable definition; it does not by
  itself start any clock.
- An **event-based retention label** is a retention (or record) label whose trigger is set to **"start
  retention based on an event"** and bound to an event type. Until the event is raised, content with this
  label sits in a **pending** state — the label is applied, the duration is known, but the clock has not
  started; the item shows *"retention starts on event."*
- A **retention event** is the act of declaring that the event has happened. It names the event type and
  identifies the affected content by **asset ID** and/or **keyword**. When Microsoft Purview processes the
  event, it finds every labeled item whose asset ID / keyword matches and **starts the retention clock**
  from the event date for exactly those items.

The event type is the vocabulary, the label is the pending instrument, and the retention event is the
trigger. All three must line up — same event type on the label and the event, and an asset-ID / keyword
strategy that actually matches the content — or the clock never starts.

## Asset-ID vs keyword triggering — how content is matched to an event
When a retention event is raised, Microsoft Purview needs to know **which items** the event applies to.
There are two matching mechanisms, and choosing correctly is the crux of a working design:

- **Asset ID (SharePoint / OneDrive).** Each document carries a **Compliance Asset Id** property (a
  managed-metadata column Purview recognizes). You stamp the relevant asset identifier — an employee ID, a
  contract number, a product SKU — onto the in-scope documents. When you raise the retention event you
  supply the same asset IDs, and Purview starts the clock on the documents whose `Compliance Asset Id`
  matches. This is **precise**: only the tagged items are affected.
- **Keyword (Exchange, and as an alternative).** Instead of (or alongside) asset IDs, a retention event can
  match content by **keyword query**. This is how mailbox content is typically matched, and it is broader —
  anything matching the query is affected — so it must be scoped carefully.

The reference design keys SharePoint/OneDrive event-based retention on **asset IDs** for precision, uses
**keywords** where asset-ID stamping is impractical (notably Exchange), and — critically — **defines who
stamps the asset ID and when** so the matching data actually exists on the content before an event is ever
raised. *(Exact property names, matching behavior, and cmdlet parameters are plan- and version-dependent —
verify in your tenant.)*

## What this solution is NOT (the deferred boundary)
- **The retention schedule itself is not authored here.** *Which* content is event-based, *which* event
  starts its clock, *how long* it then retains, and *whether* it is a record or regulatory record are
  determined by the organization's **records-management, compliance, privacy, and legal** functions. This
  solution takes those determinations as input and configures Purview to execute them faithfully; it does
  not invent event types, retention periods, record status, or legal determinations.
- **Full records management, the file plan in depth, and disposition-review operations** belong to the
  org-wide data lifecycle & records product — referenced here, not rebuilt.
- **Legal holds and eDiscovery** (what to preserve for a matter) belong to legal/eDiscovery, not to this
  event-based retention configuration.
- **Sensitivity (information-protection) labels, DLP, and the broader Purview data-governance program** are
  aligned to, not rebuilt here.

## Why this matters
- **The calendar cannot express these obligations.** "Keep 7 years after termination" has no fixed start
  date at creation time; only an event-based label plus a raised event can express and enforce it. Without
  it, organizations fall back to keeping everything forever (over-retention, breach and eDiscovery exposure)
  or deleting on a guessed date (under-retention, regulatory breach).
- **The event is the whole game — and the usual failure point.** Event types and labels are easy to create;
  the hard, high-value work is ensuring the event is actually **raised** with an asset-ID / keyword strategy
  that matches the right content, wired to the system of record (HR / CLM / PLM) that knows when the event
  happened. This solution makes that operational, not theoretical.
- **Getting the clock start wrong is expensive both ways.** Start it too early and content is disposed
  before the obligation ends; never start it and content is retained forever. Piloting the trigger on
  disposable test assets, and validating the effective clock start before wiring the real process, is the
  difference between a defensible control and a latent liability.

## How it works (end to end)
1. **Event types** are created in Microsoft Purview → **Records management → Events** (or **Data lifecycle
   management**) — one per real-world event the schedule names (`New-ComplianceRetentionEventType`).
2. **Event-based labels** are created with a retention trigger of **event** (`New-ComplianceTag
   -RetentionType EventAgeInDays -EventType "<event type>"`), carrying the retention action and duration
   that begin **after** the event, and — where records/legal require — the **record** setting.
3. **Labels are applied** to the in-scope content by **publishing** them for users to apply, **auto-applying**
   them by condition, or setting them as a default — scoped to the pilot first.
4. **The asset ID is stamped** on the in-scope SharePoint/OneDrive documents (the **Compliance Asset Id**
   property) — the employee ID / contract number / product SKU — so a future event can match them precisely.
   Where asset-ID stamping is impractical, a **keyword** strategy is defined instead.
5. **Content sits pending.** Labeled items show *"retention starts on event"* — the label and duration are
   set, but no clock is running yet.
6. **The event is raised** when it happens (`New-ComplianceRetentionEvent`), naming the event type and
   supplying the **asset IDs** and/or **keywords** for the affected content, with the **event date**.
7. **The clock starts.** After service propagation, Purview starts the retention period from the event date
   on every labeled item whose asset ID / keyword matched — and only those.
8. **Retention then runs** as configured — retain, then delete or route to disposition review at expiry
   (disposition operations deferred to the records product) — with the whole configuration delivered through
   the house model so it is proven on a bounded pilot before it drives real content.

## The reference design
- **Inputs (from records/legal):** the event-based categories — for each, the **event** that starts the
  clock, the **retention period after the event**, whether it is a **record / regulatory record**, and the
  **system of record** that knows when the event occurred (HR / CLM / PLM).
- **Event types:** one named event type per real-world event (`Event Type – Employee-Termination`, `Event
  Type – Contract-Expiration`, `Event Type – Product-EndOfLife`).
- **Labels:** one event-based retention/record label per category, bound to its event type, named per the
  convention, with the post-event action and duration from the schedule.
- **Application:** published and/or auto-apply label policies, scoped to `Scope – EventRetention-Pilot –
  Static` first.
- **Triggering:** an **asset-ID** strategy for SharePoint/OneDrive (which identifier, who stamps it, when)
  and a **keyword** strategy where asset IDs are impractical — plus the **raise process** (who raises the
  event, from which system of record, on what signal).
- **Pilot:** a bounded pilot scope, a disposable test asset, and a **test retention event** to prove the
  clock starts on exactly the matching content before any real event is raised.

## Limitations (be honest with buyers)
- **Event-based retention and records features are plan-dependent.** Event-based retention labels, records
  declaration, auto-apply, and adaptive scopes generally require an **E5 / E5 Compliance-class** plan or
  add-on — **verify what your tenant is licensed for.**
- **The clock only starts when an event is raised.** Creating the event type and label does nothing on its
  own; if no one raises the event (or the asset IDs / keywords don't match), content stays **pending
  forever** and is never disposed. The **raise process is the deliverable**, not an afterthought.
- **Matching depends on the asset ID actually being on the content.** If the `Compliance Asset Id` was never
  stamped (or the keyword doesn't match), the event finds nothing. Asset-ID stamping must happen **before**
  the event, ideally at ingestion.
- **Everything is eventually consistent, not instant.** Label propagation, asset-ID indexing, and event
  processing run on service timers — expect delays (hours to several days) before a raised event visibly
  starts clocks. Do not judge a pilot in the first minutes.
- **A raised event that starts a delete clock cannot be un-raised into the past.** Once the clock has
  started and (for retain-then-delete) elapsed, disposal is real — prove the trigger on disposable test
  assets only.
- **Records and regulatory records are stronger and (for regulatory) one-way.** Where an event-based label
  also declares a record, the item is locked; a regulatory record cannot be shortened or removed. Use per
  records/legal direction only.
- **Commercial vs Government cloud paths differ.** Portal URLs and some feature availability differ in GCC /
  GCC High / DoD (`*.office365.us`, `Connect-IPPSSession -ConnectionUri`) — **verify the path and feature in
  your cloud.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across the
docs, scripts, and the Purview admin surfaces:

| Artifact | Name |
|---|---|
| Event type (termination) | `Event Type – Employee-Termination` |
| Event type (contract) | `Event Type – Contract-Expiration` |
| Event type (product) | `Event Type – Product-EndOfLife` |
| Event-based retention label | `Retention Label – Termination-7yr – Pilot` |
| Event-based record label | `Record Label – Contracts-EventExpiry-7yr – Pilot` |
| Published label policy | `Label Policy – EventBased-Publish – Pilot` |
| Auto-apply label policy | `Label Policy – EventBased-AutoApply – Pilot` |
| Asset-ID property (SPO/OneDrive) | `Compliance Asset Id` (managed-metadata column) |
| Test retention event | `Retention Event – TEST-Termination – Pilot` |
| Pilot scope (static) | `Scope – EventRetention-Pilot – Static` |
| Assessment export | `Event Retention Posture – Tenant – Discovery` |
| Compliance report | `Event Retention Compliance – Tenant – Report` |

When the pilot passes and you expand to production, mint the production equivalents by swapping the `–
Pilot` stage for `– Prod` (e.g. `Record Label – Contracts-EventExpiry-7yr – Prod`) — never edit a validated
pilot artifact in place. Event types are reusable and typically not stage-suffixed.

## The standard deployment model
> **Assess** existing event types, event-based labels, and raised events → **Design** the event-type /
> label / asset-ID (or keyword) / raise-process map from the schedule → **Configure** event types, labels,
> and pilot-scoped label policies, and stamp asset IDs on pilot content → **Pilot** by raising a **test**
> retention event on a disposable asset on `Scope – EventRetention-Pilot – Static` → **Validate** against
> explicit pass/fail gates (the clock starts on exactly the matching content) → **Expand** to production
> labels, real asset-ID coverage, and the live raise process wired to the system of record.

Starting (or failing to start) a retention clock on real content is **high-impact**. Every production change
goes through change control with a documented rollback, test events are raised only on disposable assets, and
nothing drives real content until the gates in Section 5 pass.
