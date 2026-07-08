# 7. Best Practices

Durable practices for running data lifecycle and records management org-wide in Microsoft Purview. They
encode the house model — pilot-first, evidence-based, records/legal-owned determinations — into
day-to-day operation.

## Governance & ownership
- **Records/legal own the schedule; you own the implementation.** Never invent a retention period, record
  status, event trigger, or disposition rule. Treat the schedule as the source of truth and keep a
  traceable link from each Purview artifact back to its schedule category and regulatory citation (use
  file-plan descriptors for exactly this).
- **Keep a single label inventory.** One retention/record label per schedule category, named per the
  convention, reused across workloads and across the SharePoint records product — do not mint duplicate
  labels per workload.
- **Separate duties.** Records managers configure labels and the file plan; **Disposition Management**
  reviewers act on the queue and nothing else; workload admins apply where needed. Grant least privilege
  and review membership periodically.

## Policy vs label discipline
- **Use policies as the floor, labels for precision.** A tenant-wide retention **policy** is the safety
  net ("keep everything for at least N years"); reserve **labels** for records, event-based retention,
  disposition review, and file-plan reportability. Don't try to express records-grade behavior with a
  bare policy.
- **Design for retention precedence, then validate it.** Whenever policies and labels overlap, reason
  through precedence (retention > deletion; longest retention wins; explicit > implicit; shortest deletion
  wins) *and confirm the effective outcome on real content*. Precedence is a design input, not an
  afterthought.
- **Scope tightly, then widen.** Start policies on pilot locations or a pilot adaptive scope; expand to
  `All` or a production adaptive scope only after validation. Prefer **adaptive scopes** for production so
  coverage tracks the estate automatically.

## Records & the file plan
- **Reserve regulatory records for genuine legal mandates.** A regulatory-record label is **one-way** —
  it cannot be removed, changed, or shortened. Use it only where records/legal explicitly require, gate it
  behind an explicit sign-off, and never test it on content you are not prepared to keep forever.
- **Populate file-plan descriptors from day one.** Retention **authority**, **category**, **department**,
  **citation**, and **reference ID** make the records inventory reportable and defensible — fill them as
  you create labels, not later.
- **Communicate the lock before you apply it.** A record label removes edit/delete by design; tell content
  owners before declaring records in a live location.

## Event-based retention
- **Define the event source and the raise process.** An event type is only useful if someone/something
  reliably **raises** the event (with the asset ID / keyword that matches the content) when it happens.
  Document who raises `Employee-Termination` / `Contract-Expiration` events and integrate it with the
  system of record (HR/CLM) where possible.
- **Test events on disposable assets.** Prove the trigger and the resulting clock on a test asset before
  wiring the real process.

## Change-safety
- **Stage disabled, publish to pilot, then enforce.** Policies are created disabled; labels are published
  to the pilot scope; enforcement is a deliberate, change-controlled step after the gates pass.
- **Ring your rollout.** Expand by department/site/workload ring rather than a single tenant-wide flip;
  re-run the compliance report after each ring.
- **Write the rollback — and flag the irreversible parts.** Reversible: disable/unpublish policies and
  labels, remove non-record labels, un-declare non-regulatory records. **No-rollback:** regulatory
  records, completed disposition, elapsed event-based deletions. Every change ticket states which is which.

## Operations & evidence
- **Report on a cadence.** Run the compliance report regularly; watch label coverage, policy
  locations/enabled state, records counts, and pending-disposition backlog — a growing disposition backlog
  is an operational risk, not just a metric.
- **Work the disposition queue.** Reviewed disposition only stays defensible if reviewers actually act;
  monitor the backlog and reviewer coverage.
- **Respect eventual consistency.** Application, propagation, event processing, and disposition run on
  timers (hours to days). Build that latency into expectations and never judge a change in the first
  minutes.
- **Verify by cloud.** In GCC/GCC High/DoD, confirm portal paths, endpoints (`Connect-IPPSSession
  -ConnectionUri`), and feature availability — do not assume Commercial parity.
- **Keep automation credential-free.** All scripts use interactive modern auth; never embed secrets. Keep
  assessment/reporting read-only and configuration `-WhatIf`-by-default with an explicit `-Commit`.

## Alignment with the broader program
- **Don't rebuild what the program owns.** Sensitivity labels, DLP, and tenant-wide data governance belong
  to the broader Purview program — align to them, don't duplicate.
- **Defer SharePoint library mechanics.** Default library labels, in-place records inside libraries, and
  PnP-driven application are the SharePoint records/retention product's province — keep label names
  consistent and defer that mechanic rather than re-documenting it.
