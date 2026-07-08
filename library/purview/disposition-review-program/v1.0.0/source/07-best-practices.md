# 7. Best Practices

Durable practices for running a disposition review program in Microsoft Purview. They encode the house
model — pilot-first, evidence-based, records/legal-owned determinations, strict role separation — into
day-to-day operation.

## Governance & ownership
- **Records/legal own the decision; you own the workflow.** Never invent which categories require review,
  how many stages, who reviews, or the disposition outcome. This program delivers the *method* and the
  *evidence*; the determination to delete, extend, or relabel is the reviewer's (records/legal) call.
- **Keep the review requirement traceable.** Maintain a link from each disposition label back to the
  records/legal requirement that says it must be reviewed and to the stage/reviewer decision — so the
  configuration is auditable against its authority.
- **Align to the org-wide records program, don't duplicate it.** Retention labels, policies, event-based
  retention, records declaration, and the file plan are the Data Lifecycle & Records Management product's
  province. This program **adds/verifies disposition review** on those labels and keeps label names
  consistent — it does not mint parallel labels.

## Role separation (a compliance control, not a convenience)
- **Reviewers get Disposition Management and nothing more.** Membership in **Disposition Management** is
  what lets a reviewer see and act on the queue; grant it **only** to named reviewers and keep it separate
  from the admin who configures labels/stages, so the person disposing content is not the person who set the
  schedule.
- **Manage stage reviewers via mail-enabled groups.** Address each stage with a mail-enabled security group
  and manage membership there — never hard-code individual reviewers into the label, which forces a label
  edit on every personnel change. Keep each group's members in Disposition Management.
- **Review permission membership periodically.** Reviewers change roles; a stale Disposition Management
  membership is both a broken queue (missing reviewers) and an over-grant (departed reviewers) — audit it.

## Multi-stage design
- **Add stages only where accountability requires them.** Each stage is a real sign-off, not decoration —
  more stages mean slower disposal and larger backlogs. Use single-stage where one authority suffices;
  reserve multi-stage (e.g. `Records → Compliance → Legal`) for genuinely high-value categories.
- **Order stages deliberately and validate the order.** Disposal happens only after the **final** stage —
  design the sequence from the records/legal requirement and prove advancement order in pilot; never assume
  it.
- **Verify the multi-stage capability in your tenant.** Multi-stage disposition review is newer than
  single-stage, is plan-dependent, and its configuration shape has changed across releases — confirm
  availability and the exact property model against current Microsoft docs before relying on it.

## Change-safety
- **Publish to pilot, prove a full cycle, then govern production.** Disposition labels are published to the
  pilot scope with short-duration disposable test content so a **complete** review-and-dispose cycle
  (including proof of disposal) is validated before any production content is governed.
- **Ring your rollout.** Expand by department/site/workload ring rather than a single tenant-wide flip;
  re-run the evidence report after each ring and confirm no review category is silently auto-deleting.
- **Write the rollback — and flag the irreversible part.** Reversible: disable/unpublish the label policy,
  adjust reviewer-group and Disposition Management membership, change review config on not-yet-expired
  labels. **No-rollback:** a completed (approved) disposition permanently deletes content. Every change
  ticket states which is which and never exercises a real disposition to test rollback.

## Operations & evidence
- **Work the disposition queue on a cadence.** Reviewed disposition is only defensible if reviewers actually
  act. Monitor the pending-disposition backlog and reviewer coverage per stage — a growing backlog is an
  operational and compliance risk, not just a metric. Ensure notifications/reminders are enabled.
- **Treat proof of disposal as the deliverable.** The value of this program is the evidence: for each
  disposed item, *what* was disposed, *who* approved each stage, and *when*. Export the disposition record
  from the portal and corroborate with the audit log; retain it per your evidence-retention requirement.
- **Report regularly.** Run the evidence/compliance report on a schedule; watch review-config coverage,
  Disposition Management membership, empty stages, and the auto-delete-no-review gap.
- **Respect eventual consistency.** Application, expiry, queue entry, notification, and disposal run on
  timers (hours to days). Build that latency into expectations and never judge a cycle in the first minutes.
- **Respect the legal-hold boundary.** Content under legal/eDiscovery hold is exempt from disposal even
  after review approval — hold management stays with legal/eDiscovery; do not attempt to manage holds from
  this program.
- **Keep automation credential-free and safe-by-default.** All scripts use interactive modern auth; never
  embed secrets. Assessment and reporting stay read-only; configuration is `-WhatIf`-by-default with an
  explicit `-Commit`; no script approves, extends, or deletes a disposition.

## Cloud & plan discipline
- **Verify by cloud.** In GCC/GCC High/DoD, confirm portal paths, endpoints (`Connect-IPPSSession
  -ConnectionUri`), and feature availability — do not assume Commercial parity.
- **Verify by plan.** Disposition review (and multi-stage in particular) is plan-gated. Confirm the tenant's
  entitlement and the current configuration shape before designing, rather than assuming a capability is
  present.
