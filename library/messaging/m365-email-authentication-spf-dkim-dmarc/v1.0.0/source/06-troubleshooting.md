# Troubleshooting

Common failure modes when implementing SPF, DKIM, and DMARC on Microsoft 365, with resolutions. Symptoms
are what you observe in `Authentication-Results` headers, aggregate reports, or the provided scripts.

---

## SPF

### SPF `permerror` / "too many DNS lookups"
- **Symptom:** `spf=permerror`; mail intermittently junked; `Get-SpfLookupHealth.ps1` reports > 10.
- **Cause:** The record's `include:`/`a`/`mx`/`ptr`/`exists` mechanisms exceed the RFC 7208 **10-lookup**
  limit — usually stacked third-party `include:` chains.
- **Resolution:** Consolidate `SPF Record – <domain> – Prod`: drop unused includes, replace an
  `include:` with the vendor's published `ip4:` ranges, or move a noisy sender to a sending subdomain
  with its own SPF. Re-run `Get-SpfLookupHealth.ps1` until ≤ 10.

### Two SPF records / `permerror`
- **Symptom:** `Get-EmailAuthPosture.ps1` shows `SpfRecordCount = 2`.
- **Cause:** More than one `v=spf1` TXT record — invalid.
- **Resolution:** Merge into a single record; delete the extras.

### Legitimate sender soft/hard-failing SPF
- **Symptom:** A known sender shows `spf=fail`/`softfail` in reports.
- **Cause:** Its sending host/IP or vendor `include:` is missing from the record.
- **Resolution:** Add the vendor's published `include:` or the on-prem egress `ip4:` to
  `SPF Record – <domain> – Prod`; keep `~all` until verified, then `-all`.

---

## DKIM

### DKIM enable fails — "CNAME record does not exist"
- **Symptom:** `Get-DkimSigningConfig` shows a CNAME-not-found error; `Status` not `Valid`.
- **Cause:** The two selector CNAMEs aren't published, are mistyped, or haven't propagated. The targets
  must match `Selector1CNAME`/`Selector2CNAME` exactly (derived from the tenant initial domain + Domain
  GUID).
- **Resolution:** Publish `DKIM CNAME selector1/2 – <domain> – Prod` exactly as
  `Set-DkimSigning.ps1 -WhatIf` prints them; wait for propagation; re-run enable. Verify with
  `Resolve-DnsName -Type CNAME selector1._domainkey.<domain>`.

### DKIM passes but with `d=<tenant>.onmicrosoft.com` (not aligned)
- **Symptom:** `dkim=pass header.d=<tenant>.onmicrosoft.com`; DMARC still fails DKIM alignment.
- **Cause:** Custom-domain DKIM isn't enabled, so Exchange Online signs with the initial domain, which
  doesn't align to your custom `From:`.
- **Resolution:** Enable custom-domain DKIM (`Set-DkimSigning.ps1 -Domain <domain> -Commit`) so signing
  uses `d=<yourdomain>`.

### DKIM breaks after rotation
- **Symptom:** `dkim=fail` right after `Rotate-DkimSigningConfig`.
- **Cause:** The alternate selector's CNAME isn't published/resolving.
- **Resolution:** Ensure **both** `selector1` and `selector2` CNAMEs are published — Exchange Online
  rotates between the two. Re-test with T2/T3.

---

## DMARC

### No aggregate reports arriving
- **Symptom:** `DMARC RUA – <domain> – Prod` mailbox stays empty > 72h after publishing `p=none`.
- **Cause:** Missing/incorrect `rua=`; the `_dmarc` record didn't publish; or cross-domain reporting
  lacks the external-destination verification TXT.
- **Resolution:** Confirm `_dmarc.<domain>` resolves with a valid `rua=mailto:` (T4). For a report
  address on a different domain, publish `<yourdomain>._report._dmarc.<reportdomain>` TXT = `v=DMARC1`.

### Legitimate mail quarantined/rejected after tightening policy
- **Symptom:** A real sender's mail is junked/bounced after moving to `p=quarantine`/`p=reject`.
- **Cause:** That source wasn't aligned (missing SPF entry or vendor DKIM) and enforcement was advanced
  before the reports were clean — the enforcement gate (T5) was not met.
- **Resolution:** **Immediately step the policy back one stage** (`DMARC Policy – <domain> – Reject` →
  `Quarantine` → `Monitor`). Remediate the source (add to SPF, enable vendor DKIM as `d=<domain>`, or
  route via Exchange Online/a subdomain), confirm it passes in the reports, then re-ramp `pct=`.

### DMARC fails only for forwarded mail
- **Symptom:** Reports show DMARC failures from mailing lists / forwarders.
- **Cause:** Forwarding changes the connecting IP (breaks SPF alignment) and may alter the body (breaks
  DKIM).
- **Resolution:** Rely on **DKIM alignment**, which usually survives forwarding; ensure custom-domain
  DKIM is enabled. Treat residual forwarder failures as expected noise, not a legitimate-sender break.

### Subdomain spoofing still getting through at `p=reject`
- **Symptom:** Spoofed mail from `x.<domain>` isn't rejected though the org domain is at `p=reject`.
- **Cause:** No policy applies to the subdomain; without `sp=`, the subdomain inherits the org policy
  only if it has no record of its own — verify behavior.
- **Resolution:** Set an explicit subdomain policy (`sp=reject`) on the org `_dmarc` record, or publish a
  DMARC record on the subdomain.

---

## Environment / cloud

### Cmdlets or portals not found in Government cloud
- **Symptom:** `Connect-ExchangeOnline` connects to the wrong endpoint; CNAME targets or portal URLs
  don't match.
- **Cause:** GCC High / DoD uses different endpoints and the `*.onmicrosoft.us` initial domain.
- **Resolution:** Connect with `-ExchangeEnvironmentName O365USGovGCCHigh` (or `O365USGovDoD`); use
  `admin.exchange.office365.us`; and **verify the SPF include host and DKIM CNAME targets for your
  cloud** rather than assuming Commercial values.

### `Connect-ExchangeOnline` fails / module missing
- **Symptom:** Command not recognized, or auth errors.
- **Cause:** ExchangeOnlineManagement (EXO V3) not installed, or Basic Auth expected.
- **Resolution:** `Install-Module ExchangeOnlineManagement`; connect with modern auth/MFA (per global
  requirement GR-3). No stored credentials — the scripts never embed secrets.
