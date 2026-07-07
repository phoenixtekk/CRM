# Testing & Validation

Run these tests at the gates called out in the Implementation guide. Each has an explicit
**pass/fail**. Do not advance a DMARC stage on a failed test.

---

## T1. SPF resolves as a single, scoped record

- **How:** `Resolve-DnsName -Type TXT <domain>` (or run `Get-EmailAuthPosture.ps1`).
- **Pass:** Exactly **one** `v=spf1` record; it includes `spf.protection.outlook.com` plus every
  inventoried sender; the estimated DNS lookup count is **≤ 10**; qualifier is `~all` (pilot) or `-all`
  (enforced).
- **Fail:** Two or more `v=spf1` records, missing a legitimate sender, `> 10` lookups (would `permerror`),
  or an unintended `+all`. → Fix per Implementation Step 3.1 / 2.1 before proceeding.

## T2. DKIM signing is enabled and valid

- **How:** `Get-DkimSigningConfig -Identity <domain> | fl Enabled,Status,Selector1CNAME,Selector2CNAME`;
  and `Resolve-DnsName -Type CNAME selector1._domainkey.<domain>`.
- **Pass:** `Enabled : True`, `Status : Valid`; both `selector1._domainkey` and `selector2._domainkey`
  CNAMEs resolve to the Microsoft-hosted targets.
- **Fail:** `Status` shows a CNAME-not-found error, or a selector doesn't resolve. → Republish the exact
  CNAME targets (Step 3.2) and wait for propagation.

## T3. A test message passes SPF and DKIM (and aligns)

- **How:** Send from an Exchange Online mailbox on `<domain>` to an external mailbox at a DMARC-honoring
  provider; open the raw message and read `Authentication-Results`.
- **Pass:** `spf=pass` for an aligned MAIL FROM, `dkim=pass header.d=<domain>` (note `d=` equals your
  custom domain, **not** `onmicrosoft.com`), and — once DMARC is published — `dmarc=pass`.
- **Fail:** `dkim=pass header.d=<tenant>.onmicrosoft.com` (DKIM not aligned — custom-domain DKIM not
  enabled), `spf=softfail/fail`, or `dmarc=fail`. → Enable custom-domain DKIM (Step 3.2) / fix SPF.

## T4. DMARC record is published and reports arrive

- **How:** `Resolve-DnsName -Type TXT _dmarc.<domain>`; check the `DMARC RUA – <domain> – Prod` mailbox.
- **Pass:** Exactly one `v=DMARC1` record with the intended `p=` and a valid `rua=`; aggregate report XML
  arrives at the RUA mailbox within 24–72h of publishing.
- **Fail:** No record, malformed tags, wrong/absent `rua=`, or no reports after 72h (check the mailbox
  and, for cross-domain reporting, the external-destination verification TXT). → Fix per Step 3.4 / R6.

## T5. All legitimate senders pass DMARC with alignment (enforcement gate)

- **How:** Run `Invoke-DmarcReportAnalysis.ps1` over the collected reports and reconcile against
  `Sender Inventory – <domain> – Baseline`.
- **Pass:** Every legitimate source in the inventory shows **DMARC pass with SPF- or DKIM-alignment**;
  the only failing sources are known-illegitimate/spoof traffic; **no unknown legitimate source** is
  failing.
- **Fail:** Any legitimate/unknown source is failing DMARC. → Remediate that source (SPF/DKIM/subdomain)
  and re-collect before advancing. **This is the gate that blocks `p=quarantine`/`p=reject`.**

## T6. Alignment validation report is green

- **How:** Run `Test-EmailAuthAlignment.ps1`.
- **Pass:** All four checks green — SPF scoped (≤10 lookups, all senders covered), DKIM valid, DMARC
  present, zero unaligned legitimate senders.
- **Fail:** Any check red. → Address the specific failure before enforcement.

## T7. Enforcement takes effect without dropping legitimate mail

- **How:** After moving to `p=quarantine` (ramping `pct=`) and then `p=reject`, keep running
  `Invoke-DmarcReportAnalysis.ps1` each report cycle; send legitimate test mail through each real sender.
- **Pass:** Spoofed/forged `From:<domain>` mail is quarantined/rejected by receivers; **all legitimate
  senders continue to be delivered** and show `dmarc=pass`.
- **Fail:** A legitimate sender's mail is quarantined/rejected. → Immediately step the policy back one
  stage (reject → quarantine → none), remediate the sender, then re-ramp.

## T8. DKIM rotation succeeds

- **How:** Run `Rotate-DkimSigningConfig -Identity <domain>`; re-test T2/T3.
- **Pass:** Signing continues (`Status : Valid`), new selector active, test message still `dkim=pass
  header.d=<domain>`.
- **Fail:** DKIM breaks after rotation (usually a selector CNAME not resolving). → Confirm both selector
  CNAMEs are published; Exchange Online rotates between the two published selectors.
