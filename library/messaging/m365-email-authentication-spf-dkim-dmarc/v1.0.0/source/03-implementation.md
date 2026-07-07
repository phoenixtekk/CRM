# Implementation

Follow these steps in order. They realize the house model — **Assess → Design → Configure → Pilot →
Validate → Expand** — pilot-first, with explicit pass/fail gates and a rollback at each DNS/auth change.
Every artifact is **named** with the convention `<Purpose> – <Scope> – <Stage>` and that exact name is
reused in testing, troubleshooting, and the scripts.

> **High-impact warning.** SPF, DKIM, and DMARC are DNS/authentication changes that affect **production
> mail deliverability**. A mis-scoped SPF record, an incorrect DKIM CNAME, or a premature `p=reject` can
> cause legitimate mail to be filtered or rejected. Lower DNS TTLs first, change one record at a time,
> and never advance a gate on assumption — advance it on aggregate-report evidence.

Artifacts produced (named once, reused throughout):

| Artifact | Name |
|---|---|
| SPF record | `SPF Record – <domain> – Prod` |
| DKIM signing config | `DKIM Signing – <domain> – Prod` |
| DKIM CNAMEs | `DKIM CNAME selector1/2 – <domain> – Prod` |
| DMARC monitor record | `DMARC Policy – <domain> – Monitor` |
| DMARC quarantine record | `DMARC Policy – <domain> – Quarantine` |
| DMARC enforce record | `DMARC Policy – <domain> – Reject` |
| Report mailbox | `DMARC RUA – <domain> – Prod` |
| Sender inventory | `Sender Inventory – <domain> – Baseline` |

---

## Phase 1 — Assess (inventory & baseline)

### Step 1.1 — Connect and confirm scope
1. On the admin workstation, connect: `Connect-ExchangeOnline` (GCC High: add
   `-ExchangeEnvironmentName O365USGovGCCHigh`). For DKIM CNAME targets you may also use Graph:
   `Connect-MgGraph -Scopes "Domain.Read.All"`.
2. List accepted domains: `Get-AcceptedDomain | Select-Object DomainName,DomainType,Default`. Record the
   in-scope domains and the tenant **initial domain** (`<tenant>.onmicrosoft.com`).

### Step 1.2 — Baseline current authentication posture (read-only)
1. Run the discovery script `Get-EmailAuthPosture.ps1` against all accepted domains. It reports, per
   domain: the current SPF `TXT` (and whether it exceeds 10 lookups / uses `~all` vs `-all`), the DKIM
   signing config state and whether the CNAMEs resolve, and the DMARC record/policy (if any). Save the
   output as the baseline for `Sender Inventory – <domain> – Baseline`.
2. From the M365 admin center and message trace, enumerate senders and reconcile against R1's inventory.

**Gate 1 (Assess):** A per-domain baseline exists and the sender inventory has **no known gaps** in the
categories of R1 (EXO, on-prem/hybrid, third-party). Unknowns are acceptable here — they will be closed
in Phase 4 from the reports — but every *known* system must be listed. Rollback: none (read-only).

---

## Phase 2 — Design

### Step 2.1 — Design the SPF record (`SPF Record – <domain> – Prod`)
1. Compose a **single** SPF `TXT` record per domain, in this order: `v=spf1`, then each authorized
   source, then the all-qualifier. For Exchange Online include `include:spf.protection.outlook.com`.
   Add each third-party sender's published `include:` (from R5) and any static on-prem egress IPs as
   `ip4:`/`ip6:`.
2. **Stay under the 10-DNS-lookup limit** (`include`, `a`, `mx`, `ptr`, `exists` each count). Count the
   nested lookups (the discovery/scope script estimates this). If over 10, consolidate: drop unused
   `include:`, replace an `include:` with the vendor's published `ip4:` ranges where they document them,
   or move a noisy sender to a sending **subdomain** with its own SPF.
3. Choose the final qualifier: publish with `~all` (soft fail) during pilot, tightening to `-all` (hard
   fail) once the inventory is proven complete. Never publish more than one `v=spf1` record per domain.

### Step 2.2 — Design the DKIM rollout (`DKIM Signing – <domain> – Prod`)
1. Retrieve the exact CNAME targets: `Get-DkimSigningConfig -Identity <domain> | fl *CNAME*` (this
   returns `Selector1CNAME` / `Selector2CNAME`, e.g.
   `selector1-<domainGUID>._domainkey.<tenant>.onmicrosoft.com`). These become `DKIM CNAME selector1/2 –
   <domain> – Prod`.
2. For each third-party sender that will DKIM-sign as your domain (R5), note the vendor selector/CNAME to
   publish.

### Step 2.3 — Design the DMARC rollout
1. Provision/confirm the RUA mailbox `DMARC RUA – <domain> – Prod` (e.g. `dmarc-reports@<domain>`).
2. Plan the three DMARC records (monitor → quarantine → reject) and the `pct=` ramp for the enforcement
   step. Decide `sp=` (subdomain policy) and `adkim`/`aspf` alignment mode (default relaxed `r`).

**Gate 2 (Design):** A written SPF string (≤10 lookups), the two DKIM CNAME targets, the RUA
destination, and the three planned DMARC records are all documented and reviewed under change control.

---

## Phase 3 — Configure (publish SPF & DKIM, DMARC at monitor)

### Step 3.1 — Publish/scope SPF (`SPF Record – <domain> – Prod`)
1. In the domain's DNS zone, create/replace the single SPF `TXT` record with the string from Step 2.1,
   using `~all` for now. Remove any duplicate/legacy `v=spf1` records.
2. Verify: `Resolve-DnsName -Type TXT <domain>` shows exactly one `v=spf1` record; the scope helper
   confirms lookups ≤ 10. **Rollback:** restore the previous TXT value (kept from Gate-1 baseline).

### Step 3.2 — Enable Exchange Online DKIM (`DKIM Signing – <domain> – Prod`)
1. Publish the two CNAMEs from Step 2.2 in DNS: `selector1._domainkey.<domain>` and
   `selector2._domainkey.<domain>` → the `Selector1CNAME`/`Selector2CNAME` targets. Wait for DNS
   propagation.
2. Enable signing — safe to dry-run first with the config script's `-WhatIf`, then apply:
   `Set-DkimSigningConfig -Identity <domain> -Enabled $true`. If the config object doesn't exist yet,
   create it: `New-DkimSigningConfig -DomainName <domain> -Enabled $true` (this generates the CNAME
   targets to publish, then re-run enable after DNS is live).
3. Verify: `Get-DkimSigningConfig -Identity <domain>` shows `Enabled : True` and `Status : Valid` and no
   "CNAME not found" error. Send a test message to an external mailbox and confirm the header shows
   `dkim=pass header.d=<domain>`. **Rollback:** `Set-DkimSigningConfig -Identity <domain> -Enabled
   $false` (Exchange Online falls back to signing with the `onmicrosoft.com` domain).
4. **Rotation:** to rotate keys on schedule or after a suspected compromise, run
   `Rotate-DkimSigningConfig -Identity <domain>` (this moves signing to the alternate selector and
   generates fresh 2048-bit keys behind the CNAMEs). The config script includes a guarded `-Rotate`
   path.

### Step 3.3 — Align on-prem/hybrid & third-party senders
1. **On-prem/hybrid:** if on-prem-origin mail egresses via Exchange Online, it is already SPF/DKIM
   covered. If it egresses **directly** to the internet, add its public IP(s) to the SPF record and, if
   possible, route it through Exchange Online (or a subdomain) so it can be DKIM-aligned; otherwise it
   will rely on aligned SPF only.
2. **Third-party:** for each platform (R5), enable domain authentication in the vendor console and
   publish the CNAME/TXT they provide so they sign with `d=<domain>` and/or add their `include:` to SPF.

### Step 3.4 — Publish DMARC at monitor (`DMARC Policy – <domain> – Monitor`)
1. Create the `_dmarc.<domain>` `TXT` record:
   `v=DMARC1; p=none; rua=mailto:dmarc-reports@<domain>; fo=1; adkim=r; aspf=r`.
   (Add `sp=none` explicitly if the subdomain policy should differ.)
2. Verify: `Resolve-DnsName -Type TXT _dmarc.<domain>` returns exactly one `v=DMARC1` record.
   **Rollback:** delete the `_dmarc` record (returns the domain to no-DMARC).

**Gate 3 (Configure):** SPF resolves as one record ≤10 lookups; DKIM `Status : Valid` and a test message
shows `dkim=pass`; the DMARC monitor record resolves and reports begin arriving at the RUA mailbox.

---

## Phase 4 — Pilot (monitor with aggregate reports)

1. Let `DMARC Policy – <domain> – Monitor` (`p=none`) run and collect **aggregate reports** for a
   representative window (typically **2–4 weeks**, long enough to capture monthly/low-frequency senders
   like billing).
2. Parse the reports with `Invoke-DmarcReportAnalysis.ps1`: it aggregates by source IP/organization and
   reports, per source, message volume and whether it **passes DMARC with alignment** (SPF-aligned,
   DKIM-aligned, or failing). Reconcile every source against `Sender Inventory – <domain> – Baseline`.
3. For each source that is **failing DMARC**: identify it, decide if it is legitimate, and remediate
   (add to SPF, enable the vendor's DKIM, or move it behind Exchange Online / a subdomain). Repeat until
   the reports show **all legitimate mail passing and aligned** and any remaining failures are known
   illegitimate/spoof traffic.

**Gate 4 (Pilot) — the enforcement gate:** The aggregate reports show **100% of legitimate senders
passing DMARC with alignment**, with **no unknown legitimate sources** still failing. Do **not** advance
to quarantine/reject until this holds. Rollback: none needed (`p=none` takes no action on mail).

---

## Phase 5 — Validate

1. Run `Test-EmailAuthAlignment.ps1` to produce the alignment validation report: SPF resolves ≤10
   lookups and covers all inventoried senders; DKIM `Status : Valid` with resolving CNAMEs and a passing
   test signature; DMARC record present; and the report-derived source list has zero unaligned
   legitimate senders.
2. Confirm with an external check (send to an external provider and read the Authentication-Results
   header: `spf=pass`, `dkim=pass header.d=<domain>`, `dmarc=pass`).

**Gate 5 (Validate):** The validation report is green on all four checks (SPF scoped, DKIM valid, DMARC
present, all legit senders aligned). This is the go/no-go for enforcement.

---

## Phase 6 — Expand (roll DMARC to enforcement)

1. **Tighten SPF** to `-all` (hard fail) now that the inventory is proven complete (`SPF Record –
   <domain> – Prod`). Verify and watch the next report cycle.
2. **Quarantine (`DMARC Policy – <domain> – Quarantine`):** update `_dmarc.<domain>` to
   `p=quarantine; pct=25; …` then ramp `pct=` 25 → 50 → 100 across report cycles, watching for any new
   legitimate failures. Keep `rua=` unchanged. **Rollback:** revert to `p=none` (or lower `pct=`).
3. **Reject (`DMARC Policy – <domain> – Reject`):** once quarantine at `pct=100` is clean, update to
   `p=reject; pct=100; rua=mailto:dmarc-reports@<domain>`. **Rollback:** revert to `p=quarantine`.
4. **Steady state:** keep `Invoke-DmarcReportAnalysis` running on a schedule; new sources or spoof spikes
   surface in the reports. Rotate DKIM per policy with `Rotate-DkimSigningConfig`.

**Gate 6 (Expand):** `_dmarc.<domain>` is at `p=reject; pct=100`, reports remain clean (no legitimate
mail rejected), and ongoing monitoring is scheduled. Full rollback path at any step: step the policy
back one stage (reject → quarantine → none) — the record change is immediate and reversible.
