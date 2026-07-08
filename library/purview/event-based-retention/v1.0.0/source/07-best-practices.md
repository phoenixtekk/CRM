# 7. Best Practices

Durable practices for running event-based retention in Microsoft Purview. They encode the house model —
pilot-first, evidence-based, records/legal-owned determinations — into day-to-day operation, and they
concentrate on the part that actually fails in the field: getting an event to reliably start the clock on
the right content.

## Governance & ownership
- **Records/legal own the schedule; you own the implementation.** Never invent an event type, a post-event
  retention period, a record status, or a matching rule. Treat the event-based schedule as the source of
  truth and keep a traceable link from each event type and label back to its schedule category and citation.
- **Keep a single, shared inventory.** Reuse existing event types and labels from the broader retention/
  records program — one event type per real-world event, one label per category, named per the convention.
  Do not mint duplicate event types (`Employee-Termination` twice) — they fragment triggering and reporting.
- **Restrict who can raise events.** Raising a retention event starts real retention clocks. Limit
  event-raising to a small, named, authorized set of operators and route every real event through change
  control; keep it separate from routine label administration.

## The raise process is the deliverable
- **An event type without a raise process is dead weight.** The most common failure is content that sits
  **pending forever** because no one raises the event. For every event type, name the **system of record**
  (HR/CLM/PLM), the **signal** that indicates the event, and the **owner** who raises it — and prefer
  **integrating** the raise with the system of record over relying on someone to remember.
- **Supply the right asset IDs / keywords at raise time.** The event only matches content you identify;
  build the raise process to pull the exact asset IDs (or keyword) from the system of record so the clock
  starts on precisely the affected items.
- **Record the event date deliberately.** The retention clock counts from the **event date**, not the raise
  date — set it to when the event actually occurred (e.g. the real termination date), especially if the
  event is raised after the fact.

## Asset-ID / keyword matching
- **Stamp the asset ID before the event, ideally at ingestion.** Matching is only as good as the
  `Compliance Asset Id` on the content. Bake asset-ID stamping into the content's creation/ingestion process
  so the data is already there when the event fires — retrofitting IDs after an event is error-prone.
- **Prefer asset IDs for precision; use keywords deliberately.** Asset-ID matching (SharePoint/OneDrive)
  affects only tagged items; keyword matching (typically Exchange) is broader — validate a keyword query
  against real content to confirm it matches in-scope and **excludes** out-of-scope content before relying
  on it.
- **Keep asset-ID schemes stable and documented.** The identifier used to stamp content (employee ID /
  contract number / SKU) must be the same value the raise process supplies — document the scheme and its
  source so the two never drift apart.

## Change-safety
- **Publish to pilot, prove the trigger, then expand.** Labels are published to the pilot scope; the trigger
  is proven by a **test event on a disposable asset**; production is a deliberate, change-controlled step
  after the gates pass.
- **Test events on disposable assets only.** Prove the clock start on a throwaway asset before wiring the
  real process — never rehearse with content that a started (or elapsed) delete clock would harm.
- **Write the rollback — and flag the irreversible parts.** Reversible: unpublish/disable label policies,
  remove non-record labels. Mitigable-before-elapse: extend/relabel while a delete clock still runs.
  **No-rollback:** an elapsed event-based deletion and any regulatory-record designation. Every change ticket
  states which is which.

## Operations & evidence
- **Monitor pending vs triggered.** A growing population of **pending** event-based content with no
  corresponding events being raised is an operational red flag — either events are not happening, or the
  raise process has broken. Report on it, don't just count labels.
- **Report on a cadence.** Run the compliance report regularly; watch event-type coverage, event-based label
  counts, raised events, and gaps (labels with no event type, event types with no label, events that matched
  nothing).
- **Respect eventual consistency.** Label propagation, asset-ID indexing, and event processing run on timers
  (hours to days). Build that latency into expectations and never judge a raised event in the first minutes.
- **Verify by cloud.** In GCC/GCC High/DoD, confirm portal paths, endpoints (`Connect-IPPSSession
  -ConnectionUri`), the `Compliance Asset Id` property, and cmdlet parameters — do not assume Commercial
  parity.
- **Keep automation credential-free.** All scripts use interactive modern auth; never embed secrets. Keep
  assessment/validation/reporting read-only and configuration (including event-raising) `-WhatIf`-by-default
  with an explicit `-Commit`.

## Alignment with the broader program
- **Design with retention precedence.** Where an event-based label overlaps other retention on the same
  content, reason through Microsoft's precedence (retention > deletion; longest retention wins; explicit >
  implicit; shortest deletion wins) and **validate the effective outcome** — don't assume it.
- **Defer records, file plan, and disposition mechanics.** Records declaration in depth, the file plan, and
  disposition-review operations belong to the org-wide data lifecycle & records product — align label names
  and defer those mechanics rather than re-documenting them.
- **Don't rebuild what the program owns.** Sensitivity labels, DLP, and tenant-wide data governance belong
  to the broader Purview program — align to them, don't duplicate.
