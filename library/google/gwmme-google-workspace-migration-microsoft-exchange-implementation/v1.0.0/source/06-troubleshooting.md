# Troubleshooting

Common failure modes for a GWMME (Google Workspace Migration for Microsoft Exchange) migration and how
to resolve them. Symptoms map to the named artifacts from Implementation (03) and the gates in Testing
(05). GWMME is a versioned tool — where a symptom depends on its logs or behavior, confirm exact
messages against **Google's current GWMME documentation** ("verify for your version").

---

## 1. Throttling / API-limit failures during a wave

- **Symptoms:** the wave slows to a crawl, GWMME logs show repeated retries or rate/throttle responses
  from the source or destination, mailboxes finish far behind estimate.
- **Likely causes:** wave too large or concurrency too high for the source (EWS throttling policy) or
  destination limits; heavy mailboxes running alongside many others.
- **Resolution:**
  1. Re-plan smaller waves with `gwmme_batch_planner.py` (lower `--max-per-wave` / `--max-wave-gb`) and
     reduce concurrency.
  2. Re-estimate with `gwmme_config_helper.py --throttle-check` to confirm the wave fits the budget.
  3. Isolate oversized mailboxes into their own `Big-NN` waves.
  4. Verify the source EWS throttling policy for the migration identity (verify for your source).

## 2. Permission / access errors opening source mailboxes

- **Symptoms:** GWMME authenticates but rows fail with access-denied / cannot-open-mailbox; whole wave
  fails identically.
- **Likely causes:** `Source Access – Exchange – App Impersonation` lacks impersonation/application
  access over the in-scope mailboxes; EWS disabled; wrong grant mechanism for Exchange Online vs.
  on-prem.
- **Resolution:**
  1. Re-run `gwmme_prereq_validator.py` — it fails fast if the source identity can't open a test mailbox.
  2. Confirm the impersonation/application grant covers **all** in-scope mailboxes, not a subset.
  3. Confirm EWS is enabled/reachable for the source (verify for your version/source).
  4. Re-run the wave after the grant propagates.

## 3. Destination (Google) authorization failures

- **Symptoms:** GWMME connects to the source but fails writing to Google; auth/scope errors on the
  destination.
- **Likely causes:** `Service Identity – Google – Migration` missing required APIs/scopes or domain-wide
  authorization; wrong credential.
- **Resolution:**
  1. Run `gwmme_prereq_validator.py` (Directory API check) to confirm the service identity authenticates.
  2. Enable the required APIs and authorize the migration scopes per Google's current GWMME setup docs
     (verify for your version).
  3. Confirm the credential in use is the intended service identity — **never** an exported key in code.

## 4. Incomplete data / delta gaps (validation shortfall)

- **Symptoms:** `Validation Report – <Scope> – <NN>` shows destination counts short of source beyond
  tolerance for mail, calendar, or contacts.
- **Likely causes:** items arrived at the source after the initial run (no delta); some items skipped
  (unsupported/oversized); partial run due to throttling.
- **Resolution:**
  1. Triage per user with `gwmme_validation_report.py` (which category is short).
  2. Run a **delta** pass for the affected mailboxes to catch newly arrived mail.
  3. Review GWMME per-item errors for skipped/unsupported items; handle or document exceptions.
  4. Re-validate; only pass the gate when within tolerance.

## 5. Missing / broken recurring calendar events or contact fields

- **Symptoms:** event counts match but a recurring meeting is missing/mis-expanded, or contacts lack
  fields (phone/address/notes).
- **Likely causes:** item-level conversion edge cases; unsupported property.
- **Resolution:**
  1. Spot-check a recurring meeting and a multi-field contact by hand (Testing T4/T5).
  2. Check GWMME logs for the specific item's conversion warning (verify for your version).
  3. Document known unsupported edge cases; re-run the item if it was a transient/throttled failure.

## 6. Mapping errors — wrong target or failed rows

- **Symptoms:** data lands in the wrong mailbox, or specific rows fail before any transfer.
- **Likely causes:** duplicate/blank rows, target user not provisioned/licensed, wrong column mapping.
- **Resolution:**
  1. Run `gwmme_config_helper.py --validate` on the mapping (catches duplicates, blanks, bad targets).
  2. Re-run `gwmme_discovery.py` to reconcile against provisioned Google users; provision any missing
     targets.
  3. Correct `Mapping – Users – Master`, re-derive the wave subset (`--wave`), re-run.

## 7. Host / connectivity issues

- **Symptoms:** intermittent drops, GWMME can't reach source or Google, runs stall.
- **Likely causes:** under-resourced or unstable `Migration Host – GWMME – Primary`; network/firewall
  blocking EWS or Google endpoints; disk full from logs.
- **Resolution:**
  1. Run `gwmme_prereq_validator.py` (endpoint reachability checks).
  2. Confirm the host meets GWMME's resource prerequisites and has disk headroom for logs.
  3. Open required outbound access to the source EWS and Google endpoints (verify for your version).

## 8. Cutover mail-flow failure

- **Symptoms:** after MX/DNS cutover, inbound mail bounces (NDRs) or still routes to the old source.
- **Likely causes:** MX/DNS misconfiguration, propagation delay, or premature cutover before all waves
  validated.
- **Resolution:**
  1. Confirm all waves for the domain passed validation **before** cutover.
  2. Verify MX/SPF/DKIM/DMARC records for the routed domain (GR-3).
  3. If mail is bouncing, execute **`Rollback Plan – Cutover – Mail`** — revert MX/DNS to the source,
     re-point clients, confirm source mail flow restored — then diagnose DNS/propagation before
     re-attempting (Testing T9).

---

### Escalation

For behavior that appears to be a **tool bug or version-specific limitation** (unexpected item
handling, undocumented errors, supported-version questions), escalate to **Google's GWMME
documentation and support** — this playbook deliberately defers tool internals to the vendor rather
than inventing them. Retain the GWMME run logs and the relevant `Validation Report – …` when you
escalate.
