# Requirements

These are the **solution-specific** prerequisites for implementing SPF, DKIM, and DMARC on a Microsoft
365 domain. They build on the shared **Global Requirements — Microsoft 365 / Exchange Messaging
Solutions** (`global-requirements-messaging.md`): a Microsoft 365 tenant with Exchange Online (GR-1),
least-privilege admin access (GR-2), the EXO V3 / Graph toolchain (GR-3), DNS control for the mail
domains (GR-4), on-prem Exchange/AD/AAD-Connect access for hybrid (GR-5), and a pilot scope + change
control (GR-6). Verify those first, then confirm the additional items below.

---

## R1. A complete inventory of legitimate senders for each domain

- **Description:** A documented list of **every** system that sends mail *as* each in-scope domain:
  Exchange Online mailboxes, on-premises/hybrid Exchange, and third-party senders (marketing/ESP
  platforms, CRM/ERP notifications, ticketing/help-desk, monitoring/alerting, billing, scan-to-email
  MFPs/printers, application relay hosts).
- **Why required:** DMARC enforcement (`p=reject`) will cause any *un-inventoried* legitimate sender that
  isn't aligned to be quarantined or rejected. You cannot safely scope SPF or reach enforcement without
  knowing every source. This is the single most important input to the whole rollout.
- **How to verify:** Cross-check the message-trace/aggregate-report data against the list. The provided
  `Get-EmailAuthPosture` discovery script and, once DMARC monitoring is live, the aggregate-report
  parser (`Invoke-DmarcReportAnalysis`) surface every IP/service seen sending as your domain — reconcile
  those against the documented inventory until there are no unknowns.
- **How to implement if missing:** Build the inventory from message trace, procurement/vendor lists,
  and (after publishing `p=none`) the DMARC aggregate reports over 2–4 weeks. Treat "unknown source in
  reports" as a gate that blocks enforcement.

## R2. Accepted domains configured and verified in Exchange Online

- **Description:** Each in-scope sending domain is an **accepted domain** in Exchange Online and is a
  **verified** custom domain in the Microsoft 365 admin center.
- **Why required:** DKIM signing is enabled **per accepted domain**; SPF and DMARC records are published
  on the domain's DNS zone. An unverified/unconfigured domain cannot be DKIM-signed by Exchange Online.
- **How to verify:** `Get-AcceptedDomain` lists the domain; the M365 admin center **Settings > Domains**
  shows it as *Healthy/Verified*.
- **How to implement if missing:** Add and verify the domain (M365 admin center **Settings > Domains >
  Add domain**), then confirm it appears via `Get-AcceptedDomain`.

## R3. Note the tenant initial (onmicrosoft) domain and Domain GUID

- **Description:** The tenant's initial domain (`<tenant>.onmicrosoft.com`, or `.onmicrosoft.us` in
  Government clouds) and each custom domain's **Domain GUID**, which appear in the DKIM CNAME targets
  (`selector1-<domainGUID>._domainkey.<initialDomain>`).
- **Why required:** The two DKIM **CNAME** records you publish must point at the exact Microsoft-hosted
  targets derived from the initial domain and Domain GUID. Getting these wrong is the most common cause
  of DKIM enable failing.
- **How to verify:** `Get-DkimSigningConfig -Identity <domain> | Format-List *CNAME*` returns the exact
  `Selector1CNAME` / `Selector2CNAME` targets to publish (available after the config object exists).
- **How to implement if missing:** Retrieve the CNAME targets from `Get-DkimSigningConfig` (or the EAC
  DKIM pane, which displays "Publish these two CNAME records") and hand them to whoever controls DNS.

## R4. DNS zone access with support for TXT and CNAME (and DMARC subdomain records)

- **Description:** Beyond generic DNS control (GR-4), confirm the provider supports **TXT** records
  (for SPF and DMARC), **CNAME** records at `selector1._domainkey` / `selector2._domainkey` (for DKIM),
  and a TXT record at the `_dmarc` subdomain (and, if used, `<sub>._domainkey` / `_dmarc.<sub>` for
  subdomains). Note the zone's TTLs.
- **Why required:** DKIM specifically requires CNAME support at the `_domainkey` labels; some DNS
  editors mangle long TXT values or reject underscore labels. Low TTLs make staged DMARC changes and
  rollback faster.
- **How to verify:** Create a throwaway test TXT/CNAME and confirm it resolves (`nslookup -type=txt`,
  `Resolve-DnsName`). The provided validation script performs live DNS lookups of each record.
- **How to implement if missing:** If the current provider can't host the required records (rare), move
  the zone or use the provider's advanced-DNS mode; lower TTLs (e.g. 300–3600s) before starting the
  DMARC ramp.

## R5. DKIM signing keys / alignment method from each third-party sender

- **Description:** For each third-party platform that sends as your domain, the vendor's method to make
  its mail **DMARC-aligned** — typically DKIM keys/selectors to publish as CNAMEs in your zone (so the
  platform signs with `d=<yourdomain>`), and/or the SPF `include:` to add. Some platforms use a
  dedicated sending subdomain.
- **Why required:** A third-party sender only passes DMARC for your domain when it produces an **aligned**
  SPF or DKIM result. Missing platform DKIM setup is the usual reason a legitimate marketing/CRM stream
  fails DMARC at enforcement.
- **How to verify:** After configuring, aggregate reports show that source passing DMARC with an aligned
  `d=` or aligned SPF; the validation script flags sources seen without alignment.
- **How to implement if missing:** From each vendor's documentation, enable domain authentication on
  their side and publish the CNAME/TXT records they provide. (Vendor consoles are deferred to the
  vendor's own docs — the pattern is: publish their keys, verify in their console, confirm alignment in
  the reports.)

## R6. A DMARC aggregate-report (RUA) destination

- **Description:** A mailbox or DMARC-reporting endpoint to receive the aggregate (RUA) XML reports —
  either an internal mailbox you can parse or a hosted DMARC analytics service. If reporting to a
  domain other than the checked domain, that receiver must publish the `external destination
  verification` record (`<yourdomain>._report._dmarc.<reportdomain>` TXT = `v=DMARC1`).
- **Why required:** The entire monitor→enforce journey is driven by these reports; you cannot safely
  tighten policy without them.
- **How to verify:** Reports arrive at the RUA address within 24–72h of publishing `p=none`; the parser
  script (`Invoke-DmarcReportAnalysis`) ingests them.
- **How to implement if missing:** Provision a dedicated mailbox (e.g. `dmarc-reports@<domain>`) or a
  reporting service, and — for cross-domain reporting — publish the external-destination verification
  TXT record.

## R7. Exchange Administrator role and (hybrid) on-prem transport insight

- **Description:** The **Exchange Administrator** role is sufficient for `Get/Set/New-DkimSigningConfig`,
  `Rotate-DkimSigningConfig`, and reading connectors/message trace. For **hybrid**, add read access to
  on-premises Exchange transport (send connectors, the outbound path/IP or smart host) so on-prem-origin
  mail can be brought into SPF/DKIM alignment.
- **Why required:** DKIM cmdlets and mail-flow inspection require these roles; hybrid on-prem mail that
  egresses directly (not via Exchange Online) needs its own SPF entry and DKIM/alignment plan.
- **How to verify:** `Get-DkimSigningConfig` succeeds; you can enumerate on-prem send connectors and the
  outbound public IP(s).
- **How to implement if missing:** Have a Global Admin assign **Exchange Administrator**; obtain on-prem
  Exchange admin read access for the hybrid transport review.

---

> **Government cloud note (per the house Commercial-vs-Government rule).** In **GCC High / DoD**, the
> initial domain is `*.onmicrosoft.us`, admin portals are on `*.office365.us` (e.g.
> `admin.exchange.office365.us`), and you connect with `Connect-ExchangeOnline -ExchangeEnvironmentName
> O365USGovGCCHigh` (or `O365USGovDoD`). The SPF include and DKIM CNAME targets follow the sovereign
> cloud's values — **verify the exact include host and CNAME targets in your tenant/cloud** rather than
> assuming the Commercial `spf.protection.outlook.com` / `onmicrosoft.com` values.
