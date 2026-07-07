# Best Practices

Durable practices for deploying and running **Google Workspace Migrate** at scale. They complement
the ordered steps in `03-implementation.md`.

## Platform & sizing
- **Size from measured data, not guesses.** Drive node count from the `node-sizing-assessment.py`
  baseline (volume ÷ window ÷ per-node throughput), and **round up** for delta passes and headroom.
  Under-provisioning silently blows the timeline.
- **Isolate the platform database.** Put it on a dedicated, encrypted volume with backup; it holds
  all project state, mappings, and scan results — losing it means re-scanning everything.
- **Confirm supported scope for your version first.** Before committing a wave plan, verify in
  Google's Google Workspace Migrate docs exactly which content types/attributes the tool carries and
  which it does not — design mappings around the documented boundary, don't discover it mid-wave.

## Connections & identity
- **Least privilege, dedicated identities.** Use a dedicated Entra app (`Connection – Microsoft 365
  – Source`) and a dedicated Google service account (`Connection – Google Workspace – Target`) — not
  a person's admin account — with only the scopes the current version requires. Store secrets in a
  secret manager; **never** put keys in code, CSVs, or the repo.
- **Get the identity bridge right before scaling.** `Bridge – Identity – Corp` is what preserves
  ownership and sharing. Validate that every source identity resolves to exactly one target
  (`connection-mapping-generator.py --validate`) before the pilot, not after.

## Waves, throttling & sequencing
- **Pilot first, always.** Prove the full pre-stage → delta → cutover sequence on
  `Migration Wave – Finance – Pilot` and pass every gate before any production wave.
- **Pre-stage bulk, delta close, cutover last.** Move the bulk while users work on the source, carry
  changes with deltas, and keep cutover (the only high-impact step) inside a change window with a
  tested rollback.
- **Start throttling conservative, calibrate from the pilot.** Begin below the API ceilings; use the
  pilot's measured throughput (`wave-batch-builder.py --calibrate`) to raise concurrency safely. It
  is faster to run steadily under the limit than to trip throttling and back off repeatedly.
- **Schedule bulk passes off-peak.** Bandwidth is a hard cap; run the heavy pre-stage passes in
  off-peak windows and keep cutover deltas small.

## Validation & change control
- **Validate every wave, not just the pilot.** Run `post-migration-validation.py` and clear
  item-count, permission, and mail gates before closing any wave. "It looked done" is not parity.
- **Watch throttling live.** Keep `migration-health-check.py --watch` running through each wave so
  sustained throttling is caught and tuned early, not discovered in the validation report.
- **Every production change is reversible.** Mail routing, DNS, and cutover changes go through change
  control with a documented rollback; keep source data intact through cutover so any wave can re-run.
- **Preserve the baseline.** `baseline-source.json` is the source of truth for parity — capture it
  before migrating and don't overwrite it.

## Safety & hygiene
- **Safe-by-default automation.** The Python tools are read-only or `--dry-run` until `--apply`; keep
  it that way. Review generated mapping/wave artifacts before importing them into the console.
- **Decommission cleanly.** Only after the final wave validates: decommission the nodes and **revoke**
  the migration app registration and service account so the powerful cross-tenant access does not
  linger.
