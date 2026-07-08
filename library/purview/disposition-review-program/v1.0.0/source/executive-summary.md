# Executive Summary

At the end of a retention period, content in Microsoft 365 is either **deleted automatically** or **held
for a human to review first**. Automatic deletion is blind: nothing confirms the content is truly out of
obligation, nothing records why it was disposed, and there is no proof for an auditor or regulator that the
deletion was deliberate and authorised. That gap is a compliance and data-risk exposure. This solution
stands up a **disposition review program in Microsoft Purview** — a multi-stage review workflow with named
reviewers, strict role separation, and a defensible **proof-of-disposal** evidence trail — so content is
reviewed, not blindly deleted, and every disposal is accountable and provable.

**Outcome.** Retention labels configured with **disposition review** so expiring content routes to a
reviewer instead of deleting automatically; **single-stage** review where one authority suffices and
**multi-stage** review (e.g. records → compliance → legal) where accountability requires sequential
sign-offs, with disposal occurring only after the **final** stage approves; reviewers wired with the
**Disposition Management** permission — and nothing more — so the person disposing content is not the person
who set the schedule; and, at the end of each cycle, a retained **disposition record / proof of disposal**
plus audit events showing what was disposed, by whom, and when. Blind deletion becomes governed,
evidenced, defensible disposal.

**Approach.** The work is deliberately **narrow** — it implements the **review layer** on top of retention
labels and **defers the retention schedule and records/legal determinations** (which categories require
review, how many stages, who reviews, and every disposition decision) to the organisation's records,
compliance, and legal functions and to the org-wide Data Lifecycle & Records Management product, which it
references rather than rebuilds. Reviewers approve dispositions **in the Microsoft Purview portal**; the
tooling configures, validates, and reports on the program but never approves, extends, or deletes on a
reviewer's behalf. Delivery follows a disciplined, pilot-first model — **Assess → Design → Configure →
Pilot → Validate → Expand** — proving a **complete review-and-dispose cycle**, including its proof of
disposal, on a bounded pilot scope with short-duration disposable test content before any production
content is governed. Five PowerShell tools (Security & Compliance PowerShell and Graph) handle posture
assessment, disposition-label configuration, reviewer-permission wiring, and evidence reporting — read-only
or dry-run (`-WhatIf`) by default, with no credentials in code.

**Why it is low-risk.** Permanent disposal is irreversible and role separation is a compliance control, so
nothing governs production content until a full cycle is proven on disposable test content. Assessment is
read-only and surfaces the exact gap this program closes (labels that auto-delete where review is required);
configuration is staged and pilot-scoped; reviewers are least-privileged into Disposition Management; and
the one **irreversible** action — a completed disposition — is explicitly flagged no-rollback, exercised
only on test content in pilot, and left as the reviewer's (records/legal) determination in production.
Plan- and cloud-dependent behaviour (multi-stage review availability, the multi-stage property shape,
Government-cloud portal paths) is flagged for tenant verification rather than assumed. The result: content
reviewed before permanent deletion, disposal made accountable and provable — a compliance gap turned into
evidenced, defensible disposition.
