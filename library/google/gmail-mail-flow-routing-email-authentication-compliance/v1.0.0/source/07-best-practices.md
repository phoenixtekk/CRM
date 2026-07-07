# Best Practices

Durable practices for running the Gmail mail plane — how to keep routing, authentication, and
compliance correct over time, and how to move DMARC to enforcement **without breaking legitimate
senders**.

## Authentication

- **Always monitor before you enforce.** Live at `p=none` long enough (typically 1–4 weeks, longer
  for large sender fleets) to see a full billing/marketing cycle in aggregate reports before moving
  to `quarantine`, and again before `reject`. Evidence, not the calendar, gates each step.
- **Ramp with `pct`.** When advancing to `quarantine`/`reject`, ramp `pct=25 → 50 → 100` so a
  misconfiguration affects only a fraction of mail while you watch the reports.
- **Keep SPF under the 10-lookup limit.** Every `include:` and nested lookup counts. Prefer a small
  set of includes; remove decommissioned senders; use SPF-flattening only as a documented last resort
  (it must be maintained). `mailplane_dns_audit.py` reports the lookup count.
- **Sign with 2048-bit DKIM and one clear selector (`google`).** Don't leave stale legacy selectors
  published once the legacy system stops sending — they widen the spoofing surface.
- **Start DMARC alignment relaxed (`adkim=r; aspf=r`), tighten only if needed.** Strict alignment
  breaks common legitimate patterns (subdomains, some ESPs); most organizations reach `p=reject`
  safely on relaxed alignment.
- **Publish DMARC on subdomains too.** Add a subdomain policy (`sp=`) or explicit `_dmarc.<sub>`
  records so an unused subdomain can't be spoofed under a lenient parent.

## Routing & coexistence

- **Name and version every route, host, and rule** with `<Purpose> – <Scope> – <Stage>` and keep the
  exported config as the change record. An unnamed route is a future outage no one can explain.
- **Order matters.** Routing and content-compliance rules evaluate in order; put the most specific
  rules first and confirm ordering with a test message, not assumption.
- **Treat dual delivery as temporary.** Tie it to an explicit retirement trigger; leaving it on
  doubles storage and duplicates auto-replies and DMARC accounting.
- **Lower DNS TTLs before any MX/SPF/DMARC change** and restore them after — this makes rollback fast
  and is the difference between a 5-minute revert and an hour of bad mail.
- **Trust relayed mail correctly.** If a gateway fronts Google, register it as an **inbound gateway**
  so SPF/DMARC is evaluated against the true origin, not the relay.

## Compliance rules

- **Prefer route/modify/quarantine over reject** for content rules where a false positive would lose
  legitimate mail — quarantine is reversible; reject is not.
- **Reconcile with DLP.** A content-compliance rule and a DLP rule can both match the same message.
  Decide precedence deliberately so mail isn't double-handled or silently dropped.
- **Scope by OU and pilot first.** Never author a fleet-wide content rule directly; prove it in the
  pilot OU, then promote `Pilot → Prod`.
- **Enforce TLS to partners with a documented list**, and monitor for delivery failures when a
  partner's TLS lapses.

## Operations & evidence

- **Review DMARC aggregate reports on a schedule**, not just during rollout — a new unaligned source
  usually means a new legitimate app was deployed (add it) or an active spoofing attempt (investigate).
- **Keep the legitimate-sender inventory current.** It is the single source of truth that keeps SPF
  correct and DMARC safe; update it whenever an app that sends mail is added or retired.
- **Re-baseline after every change** with `mailplane_dns_audit.py` + `mailplane_config_export.py` and
  archive the output — the exports are your rollback reference and audit evidence.
- **Run all scripts read-only/dry-run by default**; require an explicit flag for any change, use
  OAuth/ADC (never committed keys), and keep the RUA/report data access least-privilege.
