# 6. Troubleshooting

Common failure modes across migration cutover operations, with the symptom, likely cause, and
resolution. Symptoms reference the named artifacts and tests from the Implementation and Testing guides.

---

## Throttling & API limits

### 429 / `RESOURCE_EXHAUSTED` storms stall a wave
- **Symptom:** The engine logs sustained `429 Too Many Requests` (Microsoft Graph) or
  `RESOURCE_EXHAUSTED` (Google APIs), throughput collapses, and the pre-stage/delta pass misses its
  window (T4 fails).
- **Likely cause:** Concurrency was set above the `Throttle Budget – <Wave> – Design`, or the limits in
  `limits.json` were stale/optimistic.
- **Resolution:** Lower the engine concurrency to the planner's recommended workers/pacing — do **not**
  push higher. Confirm `Retry-After` backoff is honored (back off exponentially, don't hammer).
  Re-confirm current limits in **Google Cloud console → APIs & Services → Quotas** and against current
  Microsoft Graph throttling guidance, re-run `throttle-planner.py`, and if a wave genuinely needs more,
  **request a quota increase** or split the wave / widen the window.

### A wave won't fit its window even at the budget
- **Symptom:** `throttle-planner.py` reports `fits_window: false` / negative `headroom_pct` (T3 fails).
- **Cause:** The wave's data volume is too large for the window under the binding vendor limit.
- **Resolution:** Split the wave (`wave-batcher.py --max-users` smaller, or by volume), widen the change
  window, or request a quota increase. Never "fix" it by raising concurrency past the budget.

## Wave design / clusters

### A delegate or shared-mailbox user loses access at cutover
- **Symptom:** After cutover a manager's delegate can't open the mailbox/calendar, or a shared-mailbox
  member is locked out; `cutover-readiness.py` flagged `no_split_clusters: red` (T2/T5).
- **Cause:** The dependency cluster was split across two waves — some members migrated, others didn't.
- **Resolution:** Re-batch with `wave-batcher.py --keep-clusters` so the whole cluster is in one wave;
  confirm `split_clusters` is empty before accepting the plan. For an already-split cluster, migrate the
  stragglers into the same wave (or accelerate them) and re-grant the delegate/shared access.

### Batcher can only split alphabetically
- **Symptom:** Waves look like arbitrary A–M / N–Z splits; clusters are ignored.
- **Cause:** The discovery export is missing `delegates` / `shared_mailboxes` / `manager` attributes
  (T1 flagged `missing_attributes`).
- **Resolution:** Enrich the export from Entra ID / Exchange Online (and optionally
  `discovery-profile.py --google-directory` for the target view), then re-batch.

## Item counts / delta completeness

### Post-migration item counts don't match source
- **Symptom:** `validate-migration.py` reports a user's `variance_pct` over tolerance (T6 fail).
- **Likely causes & resolution:**
  - **Legitimate engine dedup/skips** (system items, duplicates) → confirm the behavior in the engine's
    docs and set the agreed `count_tolerance_pct` in `validation-criteria.json` accordingly. This is a
    criteria issue, not a data-loss issue.
  - **Incomplete delta** — items created after the last delta weren't moved → run another delta pass and
    re-validate.
  - **Throttling gap** — a throttled pass silently skipped items → check the engine error log, re-run the
    affected pass, re-validate.
  - **Unsupported item type** — the engine doesn't migrate a specific type → confirm against the engine's
    documented supported-items list (**verify for your version**) and handle out-of-band if needed.

## Permissions & sharing

### Drive sharing or mailbox permissions missing after migration
- **Symptom:** `validate-migration.py` `permissions` check red (T7): a Shared Drive member or mailbox
  delegate isn't present on the target.
- **Cause:** The engine migrated content but not all ACLs, or an external/again-not-yet-migrated
  principal couldn't be mapped.
- **Resolution:** Re-run the engine's permission/ACL pass for the affected objects (per its docs), or
  apply the missing grant, then re-validate. For principals that aren't migrated yet, note them and
  re-check after their wave.

## Mail flow & coexistence

### Mail bounces or double-delivers during coexistence
- **Symptom:** Test mail to a migrated user bounces, or arrives in both the source and target mailbox
  (T8 fail).
- **Cause:** Mail-routing / dual-delivery for the wave isn't correctly configured, or the DNS/MX cutover
  is half-applied.
- **Resolution:** Verify the coexistence routing (dual/split delivery) per the program's coexistence
  design; confirm the wave's MX/routing state matches the intended cutover step. If cutover was
  mid-switch when it failed, **roll back** the routing/DNS change to the pre-cutover state (returns the
  wave to coexistence, no data loss) and reschedule.

### Old address stops resolving after cutover
- **Symptom:** Mail to a user's pre-migration address is rejected.
- **Cause:** The source alias/routing was removed before coexistence was meant to end.
- **Resolution:** Restore the source-side routing/alias for the coexistence period per the change record.

## Calendar / free-busy

### Free/busy fails across the migration divide
- **Symptom:** A migrated user can't see a not-yet-migrated user's free/busy (or vice versa) (T9 fail).
- **Cause:** Calendar interop for the coexistence state isn't configured, or events didn't fully migrate.
- **Resolution:** Verify calendar interop per the coexistence design; re-run the calendar delta for the
  user if events are missing, then re-validate.

## Automation & credentials

### Google API calls return 401/403 from the tools
- **Symptom:** `discovery-profile.py --google-directory`, `cutover-readiness.py --verify-google`, or
  `validate-migration.py` live pulls fail with 401/403.
- **Cause:** The service account isn't authorized for the read scope, domain-wide delegation isn't set,
  or `--delegated-admin` is wrong.
- **Resolution:** In **Admin console → Security → API controls → Domain-wide delegation**, authorize the
  service account for exactly the **read-only** scopes each tool's `--help` lists; pass the correct
  `--delegated-admin`. Use OAuth/ADC — never hardcode or commit keys.

### A tool changed something unexpectedly
- **Symptom:** Concern that a tool mutated a directory or routing (T11).
- **Cause:** This should not happen — assessment, batcher, planner, readiness, and validation are
  read-only, and every write path is gated behind `--apply`.
- **Resolution:** Re-run without `--apply`; confirm the tool only wrote plan/report files. Report any
  tool that writes without `--apply` as a defect and stop using it against production until fixed.

## Hypercare

### A wave is "done" but users are still blocked
- **Symptom:** `validate-migration.py hypercare report` shows `sla_breaches` for the wave (T10 fail).
- **Cause:** Post-cutover issues were logged but not resolved within their severity SLA.
- **Resolution:** The wave is **not** done — resolve the breaching issues before starting the next wave.
  If the same issue recurs across waves, fix the runbook/readiness check so future waves prevent it.
