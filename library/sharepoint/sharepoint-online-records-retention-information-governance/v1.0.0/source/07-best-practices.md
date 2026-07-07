# 7. Best Practices

Durable practices for applying and operating records, retention, and information governance on
SharePoint Online content. These outlast any single rollout.

## Governance & scope
- **Implement the schedule; never author it.** Records periods, triggers, record status, and
  disposition authority come from records/legal. If the schedule is silent or ambiguous, get a decision
  in writing before configuring — do not guess a retention period.
- **Stay in your lane relative to Purview.** This is SharePoint-scoped records/retention. Sensitivity
  labels, DLP, insider-risk, and Exchange/Teams retention belong to the broader Purview program —
  reference and align, don't duplicate or override.
- **One label per schedule category, named consistently.** `<Purpose> – <Scope> – <Stage>` everywhere
  (portal, PowerShell, docs). Mint `– Prod` artifacts from validated `– Pilot` ones; never edit a
  validated artifact in place.

## Labels, records & disposition
- **Prefer default library labels for single-category libraries.** It is the most reliable way to get
  consistent coverage without relying on users to label each item.
- **Use record labels for defensibility, regulatory records sparingly.** A record label locks content
  in place (auditable, reversible by un-declare). A **regulatory record is irreversible** — reserve it
  for categories records/legal explicitly mandate, and communicate the lock before applying.
- **Route high-value categories through disposition review.** Automatic disposal is fine for low-risk
  categories; anything a regulator or auditor may question should end in a human-approved, evidenced
  disposition.
- **Keep reviewer access least-privilege.** Only named reviewers belong in the **Disposition
  Management** role group; review the membership periodically.
- **Import file-plan descriptors.** Retention authority / category / sub-category on each label makes
  the file plan reportable and the audit story defensible.

## Change safety
- **Pilot-first, always.** Prove the label→apply→declare→dispose chain on a bounded static scope before
  touching the tenant. Enable policies **disabled-then-enabled**, one change at a time, watching each
  propagate.
- **Respect propagation.** Retention, application, and disposition run on timers — do not judge a
  configuration in the first minutes, and build the delay into test plans and comms.
- **Understand retention precedence before you layer policies.** Retention beats deletion; longest
  retention wins; explicit beats policy; shortest deletion wins. Design and then **validate the
  effective outcome** on real content — never assume the last policy wins.
- **Baseline safety net, not tenant-wide delete, in a pilot.** A pilot retention policy should be
  retain-only; introduce deletion outcomes only after the schedule and behavior are proven.
- **Document and rehearse rollback, and flag the no-rollback parts.** Know exactly how to disable a
  policy and remove a default label; explicitly mark regulatory records and completed dispositions as
  irreversible.

## Automation & operations
- **Safe-by-default automation.** Assessment/reporting read-only; configuration scripts dry-run /
  `-WhatIf` unless `-Commit`. Modern-auth `Connect-*` only — never store credentials or secrets in
  scripts.
- **Work the disposition queue on cadence.** Disposition is an ongoing operational duty, not a one-time
  event; a growing backlog is a governance risk.
- **Report on a schedule.** Track label coverage %, records declared, and pending dispositions over
  time with `Get-SpoRecordsComplianceReport.ps1`; a downward trend in un-labeled content and a worked
  disposition queue is the health signal.
- **Verify plan-dependent features in your tenant and cloud.** Auto-apply, adaptive scopes, regulatory
  records, event-based retention, and multi-stage review are licensing-gated; portal URLs and feature
  availability differ in Government clouds (`*.office365.us`). Confirm before you design around them.
