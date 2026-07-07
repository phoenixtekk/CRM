# 5. Testing & Validation

Each test below states the procedure and its **expected pass/fail** signal. Run the per-wave tests
(T4–T9) against the **pilot wave first** and clear its gate before expanding; then run the same tests
on every subsequent wave. Tests use the named artifacts from the Implementation Guide.

---

## T1 — Discovery profile completeness
- **Procedure:** Run `discovery-profile.py --input discovery-users.csv`. Inspect the
  `Discovery Profile – Enterprise – Assess` report's `missing_attributes` and `clusters` sections.
- **Pass:** every pilot-population row has UPN, department, manager, and delegate/shared-mailbox
  references; delegate/shared clusters are identified.
- **Fail:** rows missing batching attributes are listed → fix the export before batching (Gate A).

## T2 — Cluster integrity in the wave plan
- **Procedure:** Run `wave-batcher.py --keep-clusters …`, then inspect the `Wave Plan` report's
  `split_clusters` field.
- **Pass:** `split_clusters` is empty — every manager+delegate group and every shared-mailbox membership
  is contained within a single wave.
- **Fail:** any cluster is split across waves → a delegate would lose access at cutover; re-batch.

## T3 — Throttle budget fits the window
- **Procedure:** Run `throttle-planner.py --waves waves.csv --limits limits.json --window-hours 8`.
  Read the per-wave `fits_window` and `headroom_pct`.
- **Pass:** every wave reports `fits_window: true` with positive `headroom_pct` under **both** the
  Microsoft Graph and Google quota ceilings.
- **Fail:** a wave reports `fits_window: false` or negative headroom → split the wave, widen the window,
  or request a quota increase (do **not** raise concurrency past the budget). Gate B.

## T4 — Pre-stage throttling stays in budget
- **Procedure:** During the pre-stage pass, sample the engine/API request rate (feed a rate file to
  `throttle-planner.py --observe`).
- **Pass:** observed rate stays at or below the budgeted rate; no sustained `429` / `RESOURCE_EXHAUSTED`
  with `Retry-After` backoff.
- **Fail:** sustained throttling → lower concurrency to the budgeted value and re-run (Gate D1).

## T5 — Cutover readiness (go/no-go)
- **Procedure:** Run `cutover-readiness.py --wave "<wave>" …`. Read the `Cutover Readiness` report.
- **Pass:** all checks green — target accounts exist and are licensed, no split clusters, pre-stage/
  delta complete, coexistence routing in place.
- **Fail:** any check red → **No-Go**; remediate and re-run before touching mail flow (Gate D3).

## T6 — Item-count parity (post-migration)
- **Procedure:** Run `validate-migration.py --wave "<wave>" --source-manifest source-counts.csv
  --criteria validation-criteria.json`. Read the `counts` section of the `Validation Report`.
- **Pass:** per-user item counts by folder/label match source within the **agreed tolerance**
  (accounting for documented engine dedup/skips).
- **Fail:** a user's count variance exceeds tolerance → investigate (throttling gap, incomplete delta,
  or unsupported item type) and re-run the relevant delta. See Troubleshooting.

## T7 — Permission & sharing parity
- **Procedure:** In the same `Validation Report`, read the `permissions` section.
- **Pass:** Drive sharing / mailbox permissions on the target match the required source states per the
  validation criteria.
- **Fail:** a mismatch (e.g. a Shared Drive member missing, a delegate not granted) → remediate the
  permission and re-validate.

## T8 — Mail flow & delegates
- **Procedure:** The `Validation Report` `mailflow` and `delegates` sections; also send a live test
  message to a migrated user's **old** and **new** addresses.
- **Pass:** test mail reaches the target mailbox; the old address still resolves under coexistence; each
  configured delegate can open the delegated mailbox/calendar.
- **Fail:** mail bounces/double-delivers, or a delegate is denied → check coexistence routing and
  delegate grants (Troubleshooting).

## T9 — Calendar & free/busy
- **Procedure:** The `Validation Report` `calendar` section; cross-check a free/busy lookup between a
  migrated user and a not-yet-migrated user.
- **Pass:** calendar events migrated within tolerance; free/busy resolves across the coexistence divide.
- **Fail:** missing events or free/busy gaps → verify calendar interop / delta completeness.

## T10 — Hypercare SLA compliance
- **Procedure:** Run `hypercare-triage.py report --store hypercare.json`. Read `sla_breaches`.
- **Pass:** `sla_breaches` is empty for the wave — every logged issue is within its severity SLA.
- **Fail:** one or more issues breach SLA → the wave is **not** done; resolve before starting the next
  wave (Gate F).

## T11 — Safe-by-default tool behavior
- **Procedure:** Run each write-capable tool without `--apply` and re-run the batcher/planner (read-only
  by nature) on a scratch copy.
- **Pass:** no tool mutates a directory, engine, or mail-routing state without an explicit `--apply`;
  the assessment, batcher, planner, readiness, and validation tools are read-only.
- **Fail:** any tool writes without `--apply` → stop and fix before using it against production.
