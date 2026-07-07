# 6. Troubleshooting Guide — BitTitan MigrationWiz: M365 → Google Migration Execution

Common failure modes and resolutions when executing an M365 → Google migration on MigrationWiz. Each
entry gives the **symptom**, the **likely cause**, and the **resolution**. Deep MigrationWiz console
internals, per-error-code behavior, licensing, and support are **BitTitan's to document** ("verify for
your version"); this guide covers the procedure-level failures the operator resolves and points to the
right vendor surface for the rest.

## Every line item fails with an authorization/permission error
- **Likely cause:** An endpoint identity is wrong — the source Entra **app registration** is missing a
  consented application permission, or the Google **service account** lacks **domain-wide delegation**
  for the required scopes. A whole-project identical failure almost always means the endpoint, not the
  data.
- **Resolution:** Run `btw-config-helper.py --check-delegation`. Fix the source app registration
  (permissions + admin consent) per MigrationWiz's source-endpoint docs, and authorize the SA client
  ID for the exact scopes in **Admin console → Security → API controls → Domain-wide delegation**.
  Re-prove one test line item before re-running any pass. Do not run pre-stage on a failed endpoint.

## Passes crawl or stall (throttling)
- **Likely cause:** The pass tripped a source (M365/Graph) or target (Google API) protective limit and
  is backing off; concurrency is set too high, so more threads make it worse.
- **Resolution:** Run `btw-config-helper.py --check-throttle`. If throttling is sustained, **lower**
  project concurrency per `btw-wave-planner.py` guidance and re-run — do not raise it. **Verify the
  provider's current limits for your tenant**; they change and are not ours to assert.

## Cutover window overruns
- **Likely cause:** Too much data is being moved at cutover because the **pre-stage** was skipped or
  its age filter was too recent, leaving a large delta.
- **Resolution:** Run a heavier **Pre-Stage Migration** (`BTW Pass – Pre-Stage – Per Wave`) well ahead
  of cutover with an age filter that leaves only recent items; confirm with Testing Test 3 that only
  the expected small delta remains before scheduling the DNS/MX cutover.

## Items appear duplicated after a re-run
- **Likely cause:** A **full** pass was run where a **delta** pass was intended, or the pass
  configuration/age filter changed between runs.
- **Resolution:** Re-run as a **delta** pass so only items changed since pre-stage move; validate
  idempotency with Testing Test 7. **Verify pass (delta vs full) behavior for your version** in
  BitTitan's docs before expanding.

## Recent mail/items missing after cutover
- **Likely cause:** The **delta pass** was not run at cutover, or coexistence routing delivered recent
  mail to the old platform after the user was declared migrated.
- **Resolution:** Run `BTW Pass – Delta Cutover – Per Wave`, then re-validate with
  `btw-postmigration-validation.py`. Confirm the split/dual-delivery routing rule is **keyed to the
  current migrated population** (a stale rule mis-delivers).

## Documents migrate but SharePoint content lands in the wrong place
- **Likely cause:** A missing or wrong **SharePoint site → Shared Drive** mapping, or personal vs
  shared content routed incorrectly.
- **Resolution:** Fix the mapping in `BTW Project – Documents – Prod` and regenerate the line-item CSV
  with `btw-project-mapping-builder.py`; re-run the document pass for the affected items. Confirm target
  Shared Drives exist and the service identity has access.

## Teams-to-Chat migration is incomplete or unexpected
- **Likely cause:** Teams-to-Chat coverage and behavior are **version/preview-dependent**; not all
  Teams data types map to Chat spaces.
- **Resolution:** Confirm exactly which collaboration data types are in scope in
  `BTW Project – Teams to Chat – Prod`, and **verify Teams-to-Chat coverage for your version** in
  BitTitan's docs. Record what is migrated vs handled another way; validate the mapped Chat space
  manually (validation flags this as a manual check).

## A line item won't resolve (source or target)
- **Likely cause:** The source UPN changed, or the target account is not provisioned/licensed yet.
- **Resolution:** Run `btw-project-mapping-builder.py --validate`; fix the source→target pair or
  provision/license the target (per the identity source of truth), then re-import the line item. Do not
  start a pass with unresolved line items.

## The Device Management Agent (DMA) was deployed but isn't needed (or is needed but wasn't)
- **Likely cause:** The DMA decision was skipped in design. Cloud-to-cloud mail typically needs no DMA;
  some document/desktop-source paths do.
- **Resolution:** Revisit the **DMA decision** in the project design and **verify for your version and
  project type** which paths require it. Remove speculative agents; deploy only where a project path
  genuinely requires one.

## Mail is lost or double-delivered during coexistence
- **Likely cause:** The routing rule is not keyed to the migrated population, MX TTL was not lowered, or
  split vs dual delivery is misconfigured.
- **Resolution:** Correct the coexistence design (`BTW Cutover – DNS/MX – Per Wave`): keep the routing
  rule current, lower the MX TTL ahead of changes, and re-run Testing Test 5 (a message to a migrated
  and a not-yet-migrated user each reach the correct platform) before the DNS/MX cutover.

## Validation fails on item counts even though data looks present
- **Likely cause:** The item-count **tolerance** is too tight, or expected counts include items the tool
  legitimately skips (per BitTitan's skip rules).
- **Resolution:** Set a realistic tolerance in the design and confirm which item types the tool
  skips/normalizes (**verify for your version**); re-run `btw-postmigration-validation.py` with the
  agreed tolerance. Investigate genuine gaps by re-queuing/retrying the specific line items.

## Where to go for tool-internal issues
For MigrationWiz **console errors, per-error-code meanings, licensing questions, and support**, use
**BitTitan's own documentation and support** — these are outside this solution's boundary. This guide
resolves the **procedure, sequencing, endpoint-identity, throttling, pre-stage/delta, coexistence, and
validation** failures; the tool's internals are the vendor's.
