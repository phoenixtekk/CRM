# Testing & Validation

Each test below has an explicit **pass/fail** result. Run them at the gate indicated in
`03-implementation.md`. The named artifacts (`Migration Wave – Finance – Pilot`,
`Bridge – Identity – Corp`, the connections) are the same ones created during implementation.

---

## T1. Node platform health (Gate C)
- **Procedure:** In the Google Workspace Migrate console, confirm `GWSM Platform Node – Migration –
  Prod` and every `GWSM Worker Node – Migration – NN` report healthy and connected. Confirm the
  platform database volume has headroom.
- **Pass:** all nodes healthy/connected; database volume < agreed utilization threshold.
- **Fail:** any node unhealthy/disconnected, or database volume near capacity → resolve before
  scanning.

## T2. Connection authentication (Gate C)
- **Procedure:** Run `python migration-health-check.py --connections --dry-run`, then use the
  console's built-in connection test for `Connection – Microsoft 365 – Source` and
  `Connection – Google Workspace – Target`.
- **Pass:** both connections authenticate; the Google connection can impersonate a target user; no
  scope/consent errors.
- **Fail:** auth or scope error → fix the app registration (R2) or domain-wide delegation (R3) and
  retest.

## T3. Mapping & bridge integrity (Gate C)
- **Procedure:** Run `python connection-mapping-generator.py --validate --against mapping-plan/`.
- **Pass:** every in-scope source object resolves to exactly one target; `Bridge – Identity – Corp`
  resolves all source identities; no duplicates or orphans.
- **Fail:** any unresolved, duplicate, or orphaned mapping → correct the source data and regenerate
  before importing.

## T4. Pilot scan review (Gate C)
- **Procedure:** Review the pilot scan output for unsupported item types, oversized objects, and
  permission anomalies.
- **Pass:** no blocking unsupported items; oversized objects identified and dispositioned; anomalies
  understood.
- **Fail:** blocking unsupported/oversized items unaddressed → disposition them (or confirm expected
  behavior for your version in Google's docs) before migrating.

## T5. Pre-stage throughput & throttling (Gate D)
- **Procedure:** During the pilot pre-stage pass, run `python migration-health-check.py --wave
  "Migration Wave - Finance - Pilot" --watch`.
- **Pass:** sustained throughput within the planned range; **no sustained source/target throttling**
  (429/Graph throttling or Google rate-limit responses stay within the plan's ceiling); error rate
  below threshold.
- **Fail:** sustained throttling or error rate above threshold → lower concurrency in the throttling
  plan and re-run (see `06-troubleshooting.md`).

## T6. Delta correctness (Gate D)
- **Procedure:** After the delta pass, confirm the incremental item count is small and equals the
  changes made on the source since pre-stage.
- **Pass:** delta carries only changed items; no full re-copy; no unexpected deletions on target.
- **Fail:** delta re-copies everything or misses changes → verify delta configuration for your
  version in Google's docs and re-run.

## T7. Item-count parity (Gate E)
- **Procedure:** Run `python post-migration-validation.py --wave "Migration Wave - Finance - Pilot"
  --baseline baseline-source.json --out validate-pilot/`.
- **Pass:** target item counts (Drive files, Shared Drive contents) match the source baseline within
  the agreed threshold (accounting for documented unsupported items).
- **Fail:** counts diverge beyond threshold → investigate the delta of missing items in the report
  and re-run the affected scope.

## T8. Permission & ownership fidelity (Gate E)
- **Procedure:** From the same validation report, review the ownership/permission comparison
  (sharing preserved via `Bridge – Identity – Corp`).
- **Pass:** owners and sharing on target match the intended source-to-target mapping; no
  over-permissioning (no unexpected public/broad sharing introduced).
- **Fail:** ownership wrong or sharing dropped/broadened → fix the bridge/mapping and re-run for the
  affected objects.

## T9. Mail count & flow parity (Gate E, mail waves)
- **Procedure:** From the validation report, compare per-mailbox message counts source vs. target
  and send a round-trip test to a cutover pilot user.
- **Pass:** message counts match within threshold; test mail delivers to the target mailbox; no
  routing loop.
- **Fail:** count mismatch or delivery failure → verify mail mapping/routing and re-run the mail
  scope; for routing issues revert routing (cutover rollback) and diagnose.

## T10. End-to-end pilot sign-off (Gate D→E)
- **Procedure:** Confirm T1–T9 all pass for `Migration Wave – Finance – Pilot`.
- **Pass:** all gates green → proceed to **Expand** and schedule production waves.
- **Fail:** any gate red → do not expand; remediate and re-validate the affected test.
