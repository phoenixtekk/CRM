# Executive Summary

**Outcome.** This solution makes a Microsoft 365 email domain **impossible to spoof and reliably
deliverable**. It implements the three standards that together authenticate outbound mail — **SPF**,
**DKIM**, and **DMARC** — and then advances DMARC to full **enforcement (`p=reject`)** so that any
message forging the organization's domain is quarantined or rejected by receiving mail systems, while
legitimate mail authenticates cleanly and lands in the inbox.

**The problem it solves.** A domain without enforced authentication can be spoofed by attackers to send
convincing phishing and business-email-compromise messages *as* the organization, and its own
legitimate mail is more likely to be filtered as spam. Publishing the records is easy; doing it
**without breaking legitimate mail** — across Exchange Online, hybrid/on-premises servers, and dozens of
third-party senders (marketing, CRM, ticketing, billing, scanners) — is where most efforts stall or
cause an outage.

**Approach — why it is low-risk.** The work follows a disciplined, evidence-based path: **Assess →
Design → Configure → Pilot → Validate → Expand**. Every legitimate sender is inventoried first; SPF is
scoped to stay within the hard 10-lookup limit; Exchange Online DKIM signing is enabled with
Microsoft-managed keys; and DMARC is published in **monitoring mode (`p=none`)** so that **aggregate
reports** reveal exactly which systems send as the domain before any enforcement. Enforcement is only
switched on — and then ramped `none → quarantine → reject` — once the reports prove that 100% of
legitimate mail passes and aligns. Every change is a single DNS/authentication record with an immediate
rollback (step the policy back one stage), so production mail flow is never exposed to guesswork.

**What's included.** A complete implementation guide (inventory, SPF, DKIM, DMARC rollout with pass/fail
gates and rollback), a requirements guide, testing and validation procedures, best practices for
reaching `p=reject` safely, and **five PowerShell tools** (Exchange Online PowerShell / Microsoft Graph)
for posture discovery, DKIM enable/rotate, DMARC aggregate-report analysis, alignment validation, and
SPF/scope health — all **read-only or `-WhatIf` by default**, with no credentials stored in code.

**Bottom line.** A Microsoft 365 domain that can't be spoofed and stays in the inbox — SPF scoped, DKIM
signing on, DMARC enforced on real report data, and third-party senders aligned — delivered through a
self-guided, tested process at a fraction of bespoke consulting cost.
