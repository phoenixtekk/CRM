# 5. Testing Guide — BitTitan MigrationWiz: M365 → Google Migration Execution

Run these validations for **every wave** before its DNS/MX cutover and again after. Each test states
what to check and the **expected pass/fail**. A wave passes its go/no-go gate only when all applicable
tests pass. Validation is per user across **every in-scope data type** — a user is never "migrated" on
mail alone. Use `btw-postmigration-validation.py` (read-only) to drive the per-user checks and
`btw-config-helper.py --check-throttle` for provider-limit signals; MigrationWiz's own per-project statistics
(items migrated / failed / skipped) are read from the console (**verify for your version**).

## Test 1 — Endpoint authorization (pre-flight)
- **Check:** One test line item migrates a small set of items over each endpoint without an
  authorization error; `btw-config-helper.py --check-delegation` reports the Google service account's
  client ID authorized for the required scopes and the source app registration reachable.
- **Pass:** Test item lands source→target; delegation and source consent both healthy.
- **Fail:** Any authorization / permission error — resolve the app registration (source) or
  domain-wide delegation scopes (target) before any bulk pass. **Do not run pre-stage on a failed
  endpoint.**

## Test 2 — Line-item mapping integrity
- **Check:** `btw-project-mapping-builder.py --validate` confirms every line item in the wave's CSV has
  a resolvable source UPN, a provisioned + licensed target account, and no duplicate/blank rows.
- **Pass:** 100% of line items resolve to a provisioned, licensed target; zero duplicates/blanks.
- **Fail:** Any unresolved source, unprovisioned/unlicensed target, or duplicate — fix the mapping and
  re-import before pre-stage.

## Test 3 — Pre-stage completeness
- **Check:** After `BTW Pass – Pre-Stage – Per Wave`, MigrationWiz reports the pre-stage pass complete
  for each project with failures triaged; the residual (items newer than the age filter) is small and
  expected.
- **Pass:** Pre-stage complete per project; only the expected recent-item delta remains; failures are
  triaged (retryable vs blocked), not ignored.
- **Fail:** Pre-stage stalled, a large unexplained residual, or untriaged failures — investigate
  throttling (Test 6) and per-item errors before cutover.

## Test 4 — Per-user data-type validation (mail / documents / chat)
- **Check:** `btw-postmigration-validation.py` confirms, per user: the target mailbox exists and mail/
  calendar/contacts are present (folder/label and recent-item spot checks); OneDrive/SharePoint content
  is present in the user Drive / mapped Shared Drive with expected item counts; Teams content is present
  in the mapped Chat space (**Teams-to-Chat coverage: verify for your version**).
- **Pass:** Every user shows all in-scope data types present; item-count deltas within the tolerance
  the design sets.
- **Fail:** Any user missing a data type or with an out-of-tolerance count — re-queue/retry that line
  item, re-run the delta pass, and re-validate before declaring the user done.

## Test 5 — Coexistence mail routing
- **Check:** With split/dual delivery applied, a test message to a **migrated** user is delivered in
  Gmail, and a test message to a **not-yet-migrated** user is routed onward to Exchange Online; a
  cross-platform meeting resolves free/busy.
- **Pass:** Each test message reaches the correct current platform; no double-delivery or loss;
  free/busy resolves across the divide.
- **Fail:** Mis-delivery, double-delivery, or a routing loop — correct the routing rule (keyed to the
  migrated population) before the DNS/MX cutover.

## Test 6 — Throttling / provider-limit health
- **Check:** `btw-config-helper.py --check-throttle` reads target Google API signals (and source Graph
  indicators where available) for throttling/429-style backoff during passes; the throttling profile
  `BTW Throttle – Project Concurrency – Per Wave` keeps concurrency within limits.
- **Pass:** No sustained provider throttling; passes progress at the planned rate.
- **Fail:** Sustained backoff/throttling or a stalled pass — lower concurrency per the planner's
  guidance and re-run; **verify the provider's current limits for your tenant.**

## Test 7 — Delta pass idempotency (no duplication)
- **Check:** After the delta/cutover pass, re-validate a sample: migrated items are **not duplicated**
  and only items changed since pre-stage were moved.
- **Pass:** No duplicate mail/files; recent items present exactly once.
- **Fail:** Duplicates or missing recent items — review the pass configuration (delta vs full) and the
  age filter; **verify pass behavior for your version** before expanding.

## Test 8 — DNS/MX cutover and rollback
- **Check:** The staged MX/DNS change applies for the wave and the documented back-out has been tested;
  post-cutover, inbound mail for the wave is delivered in Gmail.
- **Pass:** MX/DNS change applied under change control, mail delivered in Gmail, and a proven rollback
  exists.
- **Fail:** Mail disruption or no tested back-out — invoke rollback, restore prior routing, and do not
  proceed until the runbook and back-out are proven.

---
## Wave go/no-go gate
A wave passes only when: endpoints authorized (T1), mappings clean (T2), pre-stage complete (T3),
**every user validated across every in-scope data type** (T4), coexistence routing correct (T5), no
sustained throttling (T6), the delta pass introduced no duplication (T7), and the DNS/MX cutover is
applied and reversible (T8). Any fail blocks the wave until remediated and re-tested.
