# Troubleshooting

Common mail-plane failure modes and their resolutions. Use the **named artifacts** from
`03-implementation.md` and the read-only scripts to diagnose. **Email Log Search**
(**Gmail → Email Log Search**) is the primary tracing tool.

---

## Authentication

### Legitimate mail lands in spam after publishing DMARC
- **Likely cause:** A legitimate sender is **not aligned** (not in SPF or not DKIM-signing as the
  domain) and DMARC is already at `quarantine`/`reject`.
- **Resolve:** Run `dmarc_rua_analyzer.py` to find the failing source, add it to the SPF include list
  or enable DKIM for it, **or** step DMARC back to `p=none` (rollback) until it aligns. Never advance
  DMARC before T3 shows alignment ≥ target.

### SPF returns `permerror` / "too many DNS lookups"
- **Likely cause:** SPF exceeds the **10-lookup** limit (too many `include:`/`a`/`mx`/`exists:`).
  `mailplane_dns_audit.py` / `mailauth_validate.py` reports the count.
- **Resolve:** Remove decommissioned senders, consolidate includes, and only as a last resort use a
  maintained SPF-flattening service. Re-validate with T1/T2.

### SPF permerror from **multiple** SPF records
- **Likely cause:** More than one `v=spf1` TXT record on the domain (only one is permitted).
- **Resolve:** Merge into a single record. `mailauth_validate.py --check spf` flags this.

### DKIM shows `fail` or does not resolve
- **Likely cause:** DKIM was generated in the console but **authentication wasn't started**, the
  `google._domainkey` record isn't published/propagated, or a wrong selector.
- **Resolve:** In **Authenticate email**, confirm the record is published (matching selector
  `google`), then **Start authentication**. Verify with `mailauth_validate.py --check dkim`. Allow
  for DNS propagation (TTL).

### DMARC record present but no aggregate reports arriving
- **Likely cause:** Missing/incorrect `rua=` mailto, or the reporting mailbox isn't monitored, or (for
  a third party) their domain isn't authorized to send you reports.
- **Resolve:** Confirm `rua=mailto:` points at the monitored mailbox; for external processors add the
  cross-domain authorization TXT the processor documents (**verify per your processor's docs**).

## Routing & coexistence

### Mail delivered to the wrong system (split delivery)
- **Likely cause:** Route match/order sends mail for a migrated user to the legacy host (or vice
  versa), or the authoritative system was misidentified.
- **Resolve:** Check `Route – Split Delivery to Legacy – Prod` match and **ordering** in
  **Gmail → Routing**; put the most specific route first; confirm each user's authoritative system.

### Duplicate messages / duplicate auto-replies
- **Likely cause:** **Dual delivery** left on beyond its retirement trigger, or overlapping routes
  both delivering.
- **Resolve:** Retire `Route – Dual Delivery Copy – Prod` at the recorded trigger; check for
  overlapping routes with `mailplane_config_export.py` (T7).

### Mail loops between Google and the legacy host
- **Likely cause:** Both systems forward to each other (each thinks the other is authoritative).
- **Resolve:** Define a single authoritative system per mailbox; ensure the non-authoritative side
  forwards, it does not re-route back. Trace with Email Log Search.

### Relayed inbound mail fails SPF/DMARC
- **Likely cause:** A gateway/relay fronts Google but isn't registered, so Gmail evaluates SPF against
  the relay, not the true origin.
- **Resolve:** Add the gateway IPs under **Spam, phishing, and malware → Inbound gateway**.

## Content compliance & safety

### Legitimate mail quarantined/rejected by a content rule (false positive)
- **Likely cause:** An over-broad match in a `Content Compliance – … – Pilot/Prod` rule, or a rule
  ordered ahead of an exception.
- **Resolve:** Narrow the match, add an exception, or re-order; prefer **quarantine** over **reject**
  so it's reversible. Reconcile with any overlapping **DLP** rule.

### Outbound disclaimer duplicated or missing
- **Likely cause:** Rule scope/order wrong, or the append/prepend condition matches replies too.
- **Resolve:** Scope `Content Compliance – Outbound Disclaimer – Prod` to outbound only and exclude
  internal/reply threads as designed; re-test (T5).

### TLS-required mail to a partner bounces
- **Likely cause:** The partner's receiving server no longer offers/accepts the required TLS, so the
  `TLS Required Partner` route hard-fails.
- **Resolve:** Confirm the partner's TLS status; temporarily relax to opportunistic TLS only under
  change control if policy allows, and notify the partner.

## Scripts & API

### Admin SDK export fails with auth / permission errors
- **Likely cause:** Missing ADC/OAuth, scopes not authorized in **domain-wide delegation**, or the
  account lacks the read-only role.
- **Resolve:** Authorize the read-only Directory scope, set `GOOGLE_APPLICATION_CREDENTIALS` or pass
  `--oauth-client`, or run `mailplane_config_export.py --offline` to validate the manifest only. Never
  commit key files.

### DNS scripts return nothing / stale results
- **Likely cause:** `dnspython` not installed (nslookup fallback in use) or DNS caching within TTL.
- **Resolve:** `pip install dnspython`; account for TTL after any record change (lower TTLs before
  changes so re-checks reflect reality quickly).

### `dmarc_rua_analyzer.py` finds no reports
- **Likely cause:** `--input` points at an empty/wrong path, or reports haven't accrued yet.
- **Resolve:** Point `--input` at the directory receiving RUA reports; allow a full monitoring window
  (days) at `p=none` before expecting representative volume.
