# Solution Overview

## What this is

This solution implements **email authentication** for a Microsoft 365 domain: it publishes and scopes
**SPF**, enables **DKIM** signing in Exchange Online (and aligns on-premises/hybrid and third-party
senders), and rolls **DMARC** from monitoring to enforcement (`p=none` → `p=quarantine` → `p=reject`)
using real **aggregate report** data. The outcome is a domain that receivers can authenticate — so
attackers can no longer spoof it and legitimate mail is far less likely to be filtered.

Email authentication is three cooperating DNS-based mechanisms plus the concept of **alignment**:

- **SPF (Sender Policy Framework)** — a DNS `TXT` record listing the hosts/services authorized to send
  mail *for the envelope (MAIL FROM / Return-Path) domain*. Receivers check the connecting IP against
  the record. SPF authenticates the **envelope** domain, not the visible `From:` header.
- **DKIM (DomainKeys Identified Mail)** — a cryptographic signature added to the message header. The
  receiver retrieves the public key from DNS (a selector record) and verifies the signature, proving
  the message was signed by the signing domain and was not altered in transit. In Exchange Online the
  public keys are published as **CNAME** records that point back to Microsoft-hosted keys, so key
  material and rotation are managed by the service.
- **DMARC (Domain-based Message Authentication, Reporting & Conformance)** — a DNS `TXT` record at
  `_dmarc.<domain>` that (a) tells receivers what to do with mail that fails authentication (`p=none`,
  `quarantine`, or `reject`), and (b) requests **aggregate (RUA)** and optionally **forensic (RUF)**
  reports. DMARC only passes when SPF *or* DKIM passes **and** is **aligned** with the `From:` header
  domain.
- **Alignment** — DMARC's core requirement. **SPF alignment**: the SPF-authenticated MAIL FROM domain
  matches the `From:` domain (relaxed alignment allows a shared organizational domain). **DKIM
  alignment**: the `d=` signing domain of a passing DKIM signature matches the `From:` domain. A message
  can pass raw SPF/DKIM yet still **fail DMARC** if neither result aligns with `From:` — which is exactly
  what breaks many third-party senders until they are configured correctly.

## How it works — the Exchange Online model

For mail sent **from Exchange Online** for your accepted domain:

- **SPF:** Microsoft 365 mail leaves through Microsoft's outbound IPs, represented by the SPF include
  `include:spf.protection.outlook.com`. You publish a single SPF `TXT` record per domain that includes
  that plus every other legitimate sender, ending in `-all` (hard fail) once the inventory is complete.
- **DKIM:** Exchange Online supports 2048-bit DKIM signing per accepted domain. You enable it and publish
  **two CNAME records** — `selector1._domainkey` and `selector2._domainkey` — that point to
  `selector1-<domainGUID>._domainkey.<initialDomain>.onmicrosoft.com` (and `selector2-…`). Microsoft
  hosts the keys behind those CNAMEs and rotates between the two selectors; `Rotate-DkimSigningConfig`
  triggers a rotation. Until you enable custom-domain DKIM, Exchange Online still signs with the
  tenant's `onmicrosoft.com` domain, which does **not** align to your custom `From:` domain for DMARC.
- **DMARC:** You publish `_dmarc.<domain>` and use the aggregate reports to confirm all legitimate mail
  authenticates and aligns **before** tightening the policy.

For **on-premises / hybrid** senders and **third-party** senders (marketing platforms, ticketing
systems, ERP/CRM notifications, scanners/MFPs, help-desk tools), each source must be brought into
alignment: added to SPF where it sends as your domain, DKIM-signed by that platform with your domain as
`d=` (using keys the platform provides), or routed so that an aligned identifier is present. Sources that
cannot be aligned are candidates to move behind Exchange Online or a subdomain, or to accept that they
will fail DMARC (which is why you never enforce before reading the reports).

## Reference model — the monitor→enforce journey

```
Assess      Inventory every legitimate sender for each domain (EXO, on-prem/hybrid, 3rd-party).
Design      Plan the SPF record (< 10 DNS lookups), DKIM selectors, and the DMARC rollout stages.
Configure   Publish/scope SPF; enable EXO DKIM (CNAMEs); publish DMARC at p=none with rua=.
Pilot       Collect aggregate reports (typically 2–4 weeks); confirm all legit sources pass+align.
Validate    Every source authenticates and aligns; no legitimate mail is failing DMARC.
Expand      Move DMARC p=none → p=quarantine (pct ramp) → p=reject; keep monitoring reports.
```

The DMARC policy is deliberately advanced in stages — **`p=none` (monitor) → `p=quarantine` →
`p=reject`** — often with the `pct=` tag used to quarantine/reject only a percentage first. Each step is
gated on the aggregate reports showing no legitimate mail failing, so enforcement never silently drops
real business mail.

## Benefits

- **Anti-spoofing:** at `p=reject`, receivers honoring DMARC reject mail that forges your `From:` domain,
  neutralizing direct-domain spoofing and much exact-domain phishing.
- **Deliverability:** authenticated, aligned mail is trusted by receivers and less likely to be
  junked; DMARC enforcement is a positive reputation signal.
- **Visibility:** aggregate reports reveal *every* IP/service sending as your domain — including
  shadow IT and abuse — which is valuable even before enforcement.
- **Evidence-based:** enforcement is driven by real report data, not guesswork, so the cutover is low
  risk.

## Limitations & constraints

- **DMARC only covers the visible `From:` domain**, not display-name spoofing, look-alike/cousin
  domains, or compromised-account (already-authenticated) mail — those need anti-phishing controls
  (e.g. Defender for Office 365 anti-phish, spoof intelligence), which are complementary, not replaced.
- **SPF has a hard limit of 10 DNS lookups**; exceeding it yields a `permerror` and SPF fails. Nested
  `include:` chains from many third-party senders are the usual cause — this solution scopes and
  flattens/consolidates to stay under the limit.
- **Forwarding breaks SPF** (the forwarder's IP isn't in your record) and can break DKIM if the body is
  altered; DMARC survives forwarding only when a still-aligned DKIM signature remains — a reason to rely
  on DKIM alignment, not SPF alone.
- **Receiver-dependent:** DMARC is only enforced by receivers that implement it (most large mailbox
  providers do). It is not a guarantee against all abuse.
- **Version/plan/cloud dependencies:** exact anti-phish/spoof-intelligence features depend on **EOP vs
  Defender for Office 365** plan; **Government (GCC/GCC High/DoD)** clouds use different portal URLs
  (e.g. `admin.exchange.office365.us`) and the tenant's initial domain is `*.onmicrosoft.us` — verify in
  your tenant/version/cloud.

## Deployment model

This solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
pilot-first, with explicit pass/fail gates and a documented rollback at every DNS/authentication change.
SPF, DKIM, and DMARC changes are **high-impact to production mail**: a mis-scoped SPF record or a
premature `p=reject` can cause legitimate mail to be filtered or rejected. Every change here is staged,
verified against aggregate-report evidence, and reversible.
