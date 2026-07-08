# 7. Best Practices

Durable practices for delivering and running regulatory & immutable records and a mapped file plan in
Microsoft Purview. They encode the house model — pilot-first, evidence-based, records/legal-owned
determinations — into day-to-day operation.

## Governance & ownership
- **Records/legal own the determination; you own the implementation.** Never invent record status, a lock
  period, a citation, or — above all — the **regulatory** designation. Treat the records determination as
  the source of truth and keep a traceable link from each label back to its authority and citation (the
  file-plan descriptors exist for exactly this).
- **Keep a single label inventory.** One record (or regulatory) label per determination category, named
  per the convention, reused across workloads and across the SharePoint records product — never mint
  duplicate labels per workload; it fragments the file plan.
- **Separate duties.** Records managers configure labels and the file plan; **Disposition Management**
  reviewers act on the queue and nothing else; workload admins apply where needed. Grant least privilege
  and review membership periodically.

## Immutability discipline — record vs regulatory record
- **Reserve regulatory records for genuine legal mandates.** A regulatory-record label is **one-way** —
  it cannot be removed, changed, un-declared, or shortened. Use it only where records/legal explicitly
  require an irreversible lock, gate it behind an explicit sign-off reference, and **never** apply it to
  content — even in pilot — beyond a single disposable test item you are prepared to keep for its full
  period.
- **Prefer the reversible rung when it satisfies the mandate.** A **record** label already locks content
  against edit and early deletion, and a records manager can un-declare it if the schedule allows. If the
  determination does not demand irreversibility, a record label is the safer default.
- **Communicate the lock before you apply it.** A record label removes edit/delete by design; tell content
  owners before declaring records in a live location, and be explicit that regulatory records can never be
  reversed.

## The file plan — map everything, from day one
- **Build descriptors before labels.** Create the authority, category/sub-category, department, citation,
  and reference-ID descriptors first, then attach them as each label is created — never leave a record
  label unmapped and "fill it in later."
- **Every immutable record must trace to an authority and citation.** A record locked without a documented
  reason is an audit finding waiting to happen. The report's mapping-completeness check exists to catch
  exactly this — treat any unmapped record label as a defect.
- **Reuse descriptors; don't duplicate them.** Enumerate existing descriptors during assessment and reuse
  them so the file plan stays coherent across the whole records program.
- **Use bulk import/export for scale.** For large records schedules, use the portal's file-plan
  import/export (CSV) to create labels-with-descriptors in bulk, then verify with the report — but keep
  names consistent with the convention.

## Change-safety
- **Publish to pilot, then expand.** Record labels are published/auto-applied to the pilot scope; a
  regulatory label touches only a disposable test item in pilot; production is a deliberate,
  change-controlled step after the gates pass.
- **Ring your rollout.** Expand by department/site/workload ring rather than a single flip; re-run the
  report after each ring.
- **Write the rollback — and flag the irreversible parts.** Reversible: unpublish label policies, remove
  non-record labels, un-declare non-regulatory records. **No-rollback:** regulatory records and completed
  disposition. Every change ticket states which is which, with a sign-off reference on the irreversible
  categories.

## Operations & evidence
- **Report on a cadence.** Run the records & file-plan report regularly; watch record/regulatory counts,
  **file-plan mapping completeness**, and label-policy coverage — an unmapped or mis-declared record is an
  operational risk, not just a metric.
- **Respect eventual consistency.** Publish, auto-apply, and declaration run on service timers (hours to
  days; up to 7 days for auto-apply of existing content). Build that latency into expectations and never
  judge a change in the first minutes.
- **Point disposition to the portal.** Reviewed disposal is actioned in **Records management →
  Disposition**; the report points reviewers there rather than approving disposals from a script, and the
  disposition *operation* is owned by the broader records product.
- **Verify by cloud.** In GCC/GCC High/DoD, confirm portal paths, endpoints (`Connect-IPPSSession
  -ConnectionUri`), and feature availability — do not assume Commercial parity.
- **Keep automation credential-free.** All scripts use interactive modern auth; never embed secrets. Keep
  assessment/reporting read-only and configuration `-WhatIf`-by-default with an explicit `-Commit`, and
  keep regulatory writes behind `-AllowRegulatory -SignOffRef`.

## Alignment with the broader program
- **Don't rebuild what the lifecycle product owns.** Tenant-wide retention policies, event-based-retention
  programs, and the full disposition-review operation belong to the broader data lifecycle & records
  product — align to them (keep label and descriptor names consistent), don't duplicate.
- **Defer SharePoint library mechanics.** Default library labels, in-place records inside libraries, and
  PnP-driven application are the SharePoint records/retention product's province — keep label names
  consistent and defer that mechanic rather than re-documenting it.
- **Align to sensitivity labels and DLP, don't re-implement them.** Those are owned by the broader Purview
  program; this solution is the immutability + file-plan layer only.
