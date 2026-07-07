# 7. Best Practices — BitTitan MigrationWiz: M365 → Google Migration Execution

Durable practices for executing an M365 → Google migration on MigrationWiz. They keep migrations
predictable at enterprise scale and keep this solution inside its vendor boundary — the procedure is
ours; the console internals and licensing are BitTitan's.

## Prove endpoints before you move anything
The single highest-leverage step is proving both endpoints on **one test line item** before any bulk
pass. A source app registration missing a consented permission or a target service account missing
domain-wide delegation fails *every* line item identically — cheap to catch on one user, expensive to
discover at scale. Re-prove endpoints whenever the app registration, service account, or consented
scopes change.

## Pre-stage heavy, delta light
Move the bulk of historical mail and documents in a **Pre-Stage Migration** well ahead of cutover,
bounded by an age filter, so the **delta pass at cutover moves only recent changes**. This keeps the
cutover window short and predictable. Fearing that a re-run duplicates items is the classic mistake —
run correctly as a delta, a re-pass brings only what changed; validate idempotency (Testing Test 7)
once and trust it. **Verify pass behavior for your version.**

## Throttle deliberately; treat provider limits as real
Both sides throttle. Set concurrency from the planner's guidance, watch for sustained backoff with
`btw-config-helper.py --check-throttle`, and lower concurrency rather than fighting the limit. A migration that
crawls is usually one that tripped a protective limit and is backing off — not one that needs *more*
threads. **Verify the current provider limits for your tenant**; they change.

## One frozen design, run every wave
Freeze the endpoint design, the project/data-type/mapping design, the DMA decision, and the
pre-stage/delta/throttle plan **before** the pilot, and run that same design unchanged every wave.
Deciding per wave guarantees drift and rework. When the pilot exposes a defect, fix the **design**, not
just the wave, so every later wave inherits the fix.

## Validate per user, across every data type
A user is migrated only when mail **and** documents **and** chat are validated for them — never on mail
alone. Keep the per-user validation record `BTW Validation – Mail/Docs/Chat – Per User` and let the
gate, not optimism, decide the wave. Set an explicit item-count tolerance in the design so validation
is objective.

## Make the DMA a deliberate decision, not a reflex
Deploy the **Device Management Agent only where a project path actually requires it**. Cloud-to-cloud
mail typically does not; some document/desktop-source paths do. Record "no DMA required" when that is
the answer, so no one deploys agents speculatively. **Verify for your version and project type.**

## Design coexistence up front; decommission it on purpose
Mail routing during the split is a first-class design (`BTW Cutover – DNS/MX – Per Wave`), not an
afterthought: split delivery with the routing rule keyed to the migrated population, a lowered MX TTL
for a fast back-out, and free/busy resolving across the divide. Keep the routing rule current as the
migrated population grows, and **retire coexistence after the final wave** — never leave it running.

## Every production change is reversible
Mail flow, DNS, sharing, and cutover are high-impact. Apply each under **change control** with a
**documented, tested rollback**, and use the go/no-go gate to stop a wave that fails validation. A
cutover with no proven back-out is an incident waiting to happen.

## Stay inside the vendor boundary
Author and operate at the procedure level. For MigrationWiz **console screens, project-option
internals, licensing, and support**, defer to **BitTitan's own documentation** and flag
version-dependent behavior **"verify for your version."** Never invent a private BitTitan API — drive
the tool with the **CSV line-item and validation artifacts** it consumes and produces (as the included
Python tools do), and read Google/Microsoft only through their documented APIs.

## Keep credentials out of code and least-privilege
The automation reads Google (Admin SDK / Directory / Reports) and Microsoft (Graph) **read-only** and
uses **OAuth / a service account / ADC** — never hardcoded keys, never a committed key file. Scope the
service account to exactly the read scopes the tools need; scope the migration's write identities to
exactly what MigrationWiz's endpoints require. Rotate and revoke on completion.
