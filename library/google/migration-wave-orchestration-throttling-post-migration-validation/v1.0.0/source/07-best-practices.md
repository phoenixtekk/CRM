# 7. Best Practices

Durable practices for running migration cutover operations at enterprise scale, engine-agnostically.

## Wave design
- **Pilot first, small, and representative.** The first wave should be small (tens of users) but
  *representative* — include a shared mailbox, a manager+delegate cluster, and a heavy Drive user — so
  the pilot exercises the real runbook, not just easy cases.
- **Never split a dependency cluster across waves.** A manager and their delegates, and a shared mailbox
  and its members, must migrate in the **same** wave. A split cluster means someone loses access at
  cutover. Always run the cluster-integrity test (T2) before accepting a wave plan.
- **Size by data volume, not just headcount.** Ten users with 100 GB mailboxes are a bigger wave than
  fifty with 5 GB. Batch on projected bytes/items so the throttle budget is meaningful.
- **Keep wave names stable.** Use `Migration Wave – <Scope> – <Stage>` and never rename mid-flight —
  the name is the join key across the batcher, engine mapping, readiness, validation, and hypercare.

## Throttling & API limits
- **Budget before you run; don't discover limits mid-cutover.** Compute concurrency and pacing against
  both vendors' *current* limits before the wave starts. A 429 storm at cutover is a self-inflicted
  incident.
- **Respect `Retry-After`; back off, don't hammer.** When Microsoft Graph or a Google API returns 429 /
  `RESOURCE_EXHAUSTED`, honor the `Retry-After` and back off exponentially. Sustained retries are a
  signal to *lower* concurrency to the budgeted value, not to push harder.
- **Leave headroom.** Budget to a fraction of the ceiling (the planner defaults to headroom) so normal
  variance and backoff don't tip a wave into throttling.
- **Re-confirm limits per engagement.** Microsoft Graph throttling and Google quotas change and vary by
  license/tenant. Treat any number in this solution as illustrative and **verify current values** —
  request quota increases where a wave genuinely needs more.

## Sequencing (pre-stage → delta → cutover)
- **Pre-stage early, cutover late.** Move the bulk of historical data days ahead with no user impact;
  keep only a small final delta for the change window so cutover is short and low-risk.
- **Gate every transition.** Pre-stage → delta → cutover each has an explicit pass/fail gate. Do not let
  a wave slide from one pass to the next without meeting the gate.
- **Cutover is a change-controlled event.** Mail-routing/DNS switches are high-impact; make them in an
  approved window with a named rollback approver and the rollback steps written down *before* you start.
- **Always have a way back.** Because pre-stage/delta only copy data, reverting mail routing returns a
  wave to coexistence with no data loss. Never cut over a wave whose rollback you haven't confirmed.

## Post-migration validation
- **Validate every wave; "done" means evidenced.** A wave isn't done because the engine said "complete"
  — it's done when the Validation Report passes against the agreed criteria. Keep the reports as the
  audit trail.
- **Agree tolerances up front.** Some engines legitimately deduplicate or skip system items, so counts
  won't match to the item. Define acceptable variance *before* the pilot so every wave is judged the
  same way.
- **Check the things users feel first.** Mail flow, delegates, and calendar/free-busy are what a user
  notices on day one — validate them explicitly, not just raw item counts.

## Hypercare
- **Run hypercare against an SLA, not vibes.** Log every post-cutover issue with severity, owner, and
  SLA; a wave with SLA-breaching issues is not finished.
- **Pace expansion to hypercare capacity.** Don't start a new wave while the previous wave's hypercare
  queue is breaching — the team can't support two tails at once.
- **Feed hypercare patterns back into the runbook.** If the same issue recurs across waves (a delegate
  grant that's always missed), fix the runbook/readiness check, not just the ticket.

## Automation & safety
- **Safe by default.** Assessment, batching, planning, readiness, and validation are read-only; any
  write is gated behind `--apply`. Prove tools are read-only (T11) before running against production.
- **Least-privilege, no secrets in code.** Use OAuth / ADC or a domain-wide-delegated service account
  with only the **read** scopes the tools need. Never hardcode keys or commit exported key files.
- **Keep the automation engine-agnostic.** Drive engines through their documented API/CSV/mapping
  interfaces; do not couple the orchestration to one vendor's private internals so the toolkit outlives
  any single engine choice.
