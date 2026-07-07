# Troubleshooting

Common failure modes running **Google Workspace Migrate** at scale, and how to resolve them. Named
artifacts (`Connection – Microsoft 365 – Source`, `Bridge – Identity – Corp`,
`Migration Wave – Finance – Pilot`, the throttling plan) are the ones created in
`03-implementation.md`.

> For anything tied to a specific console screen, node installer prompt, or supported-scope
> behavior, **verify against Google's Google Workspace Migrate documentation for your version** — the
> resolutions below are procedural, not version-locked.

---

## Throttling / API rate limits

**Symptom:** throughput drops; logs show Microsoft Graph **429 / "throttled"** or Google
**rate-limit / quota** responses; `migration-health-check.py --watch` reports sustained throttle
events (≥ threshold).
- **Cause:** concurrency/request rate is above the source or target ceiling for your tenant.
- **Resolve:** lower `concurrency_per_node` and the `graph_rps_ceiling` / `google_rps_ceiling` in the
  throttling plan (`wave-batch-builder.py`), let the current run drain, and re-run. Prefer running
  **steadily under** the ceiling over tripping throttling and backing off. Move heavy pre-stage
  passes to **off-peak** windows. Re-raise ceilings only via `--calibrate` after a clean pilot.

## Connection authentication / permission errors

**Symptom:** `Connection – Microsoft 365 – Source` or `Connection – Google Workspace – Target` fails
its test; scan or transfer aborts with auth/scope/consent errors.
- **Microsoft side:** the Entra app registration (R2) is missing a required Graph/SharePoint
  application permission or **admin consent** was not granted, or the client secret expired. Re-check
  the permissions **for your version**, grant admin consent, rotate the secret in the secret manager.
- **Google side:** the service account's client ID is not authorized in **Domain-wide delegation** for
  the exact OAuth scopes (R3), a required API is not enabled in the Cloud project, or the service
  account cannot impersonate the target user. Add the scopes in Admin console → Security → API
  controls → Domain-wide delegation; enable the APIs. Confirm with
  `migration-health-check.py --connections`.

## Mapping / identity-bridge errors

**Symptom:** content lands in the wrong target, ownership is wrong, or scan reports unresolved
objects.
- **Cause:** a source object doesn't resolve to exactly one target, or `Bridge – Identity – Corp`
  is missing/duplicated identities.
- **Resolve:** run `connection-mapping-generator.py --validate` — it flags unresolved, duplicate, or
  orphaned identities. Fix the directory source of truth (GR-4), regenerate, review, and re-import.
  Never migrate on an unvalidated mapping set.

## Delta pass re-copies everything, or misses changes

**Symptom:** the delta wave transfers far more (or far fewer) items than the changes made on the
source since pre-stage.
- **Cause:** delta/change-detection configuration or timing is off for your version.
- **Resolve:** confirm the delta configuration and change-detection behavior in Google's docs **for
  your version**; ensure the pre-stage pass fully completed before the delta; re-run the delta for the
  affected scope. Use `post-migration-validation.py` to confirm the incremental count is expected.

## Incomplete / skipped / unsupported items

**Symptom:** validation shows an item-count shortfall beyond the parity threshold; scan/run logs list
skipped or unsupported items.
- **Cause:** items of a type/attribute Google Workspace Migrate does not carry, oversized objects, or
  items that errored mid-transfer.
- **Resolve:** open the validation report from `post-migration-validation.py`, identify the specific
  missing items, and disposition them: re-run the failed items, handle oversized objects per Google's
  supported-scope guidance **for your version**, and record documented unsupported types so the parity
  threshold accounts for them. Do not close the wave until the shortfall is explained.

## Node platform / database issues

**Symptom:** a worker node shows unhealthy/disconnected; throughput collapses; console errors on the
platform node.
- **Cause:** node resource exhaustion (CPU/RAM/disk), the platform **database volume** near capacity,
  or a node lost connectivity to the platform node.
- **Resolve:** check node health in the console; free/expand the database volume (R1); restart the
  affected `GWSM Worker Node – Migration – NN` and confirm it re-registers to
  `GWSM Platform Node – Migration – Prod`. If throughput is structurally short of plan, add worker
  nodes per `node-sizing-assessment.py`.

## Bandwidth / network egress bottleneck

**Symptom:** throughput is flat well below the plan even with nodes healthy and no throttling.
- **Cause:** the corporate egress bandwidth or a proxy/firewall path is the cap (R4).
- **Resolve:** confirm firewall/proxy allow-listing for the current endpoint list, measure available
  sustained bandwidth vs. volume ÷ window, schedule bulk passes off-peak, or relocate nodes closer to
  better egress. Node count cannot exceed what bandwidth allows.

## Mail routing / cutover problems

**Symptom:** after cutover, mail loops, bounces, or does not deliver to the target mailbox; the mail
round-trip test (T9) fails.
- **Cause:** mail routing/DNS not switched correctly, or coexistence routing conflict during cutover.
- **Resolve:** this is the high-impact step — execute the **cutover rollback**: revert mail routing to
  the source under the same change window (GR-3/R7), keep users on the source, and diagnose the
  routing/DNS change before re-attempting. Source data is preserved through cutover, so the wave can
  be re-run once routing is corrected.

## Permissions/sharing dropped or over-broadened on target

**Symptom:** validation (T8) shows ownership wrong, sharing lost, or **unexpected public/broad
sharing** introduced.
- **Cause:** bridge/mapping resolved identities incorrectly, or a source sharing construct mapped to a
  broader target scope.
- **Resolve:** correct `Bridge – Identity – Corp`/the mapping for the affected objects and re-run that
  scope; treat any unexpected public sharing as a **fail** and remediate before closing the wave.
