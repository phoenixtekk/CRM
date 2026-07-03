# Executive Summary — Egress Filtering for M365/Intune Endpoints (Government / GCC High)

## The problem

Your users reach Microsoft 365, Intune, and Defender over a **filtered egress path** — a firewall,
secure web gateway, or SASE/SSE stack. Those cloud services only work if the **exact IP ranges, URLs,
and ports** they use are allowed through and, critically, if a specific set of endpoints is **not**
SSL-inspected. In **GCC High**, this is a sovereign-cloud problem: the endpoints, portals, and service
names are a **different published set** from the Commercial cloud. Configure it with Commercial values
— the intuitive mistake — and you get **silent failures**: broken sign-in, stalled Intune check-ins,
Defender devices that never onboard, and dropped Teams calls.

Two facts make this hard to get right and easy to get wrong:

1. **The GCC High endpoint set is separate.** It must be pulled from the **`USGovGCCHigh`** instance of
   Microsoft's IP/URL web service, and it points at `*.us` / `*.microsoft.us` endpoints — not `.com`.
2. **The data changes monthly.** Microsoft publishes additions **30 days in advance**. Any hardcoded
   list is a future outage waiting for the next update.

## The solution

A repeatable, novice-friendly method to **derive** the required GCC High set from Microsoft's own web
service, **build** a named allow-list and SSL-inspection bypass on your egress device from that derived
data, **validate** connectivity from a real endpoint, and **keep it current** automatically inside the
30-day window. It ships with five PowerShell scripts (discovery, validation, reporting, safe
remediation, and pilot scoping) that always query `USGovGCCHigh` and use the US Gov Graph environment,
plus a full document set with a **Commercial-vs-GCC-High** parity map and cited Gov references.

Delivery follows a gated model — **Assess → Configure → Pilot → Validate → Expand** — so nothing goes
fleet-wide until it is proven on a pilot with a documented rollback.

## Why it matters

- **No silent failures.** Right instance, right sovereign portals and service FQDNs, right no-inspect
  list — the configuration matches the cloud you actually run.
- **No future outage.** Nothing is hardcoded; the allow-list is machine-maintained from the live Gov
  data, and additions are caught inside their 30-day advance window.
- **Audit-ready.** Named objects, dated reports, and a change record suit a government compliance
  context.
- **Low risk.** Read-only discovery and validation; change-capable scripts default to preview
  (`-WhatIf`); pilot-first rollout with a rollback.

## What you get

Ten authored documents (overview, requirements, implementation, testing, troubleshooting, best
practices, deliverables, this summary, cited parity notes, and the shared Network global requirements),
five GCC High–targeted PowerShell scripts, and a clear set of named objects to build. Self-guided,
tested, and a fraction of the cost of a consulting engagement.

## Bottom line

Egress filtering for Microsoft 365, Intune, and Defender deployed **correctly on GCC High** — right
endpoints, right portals, parity gaps handled, SSL-inspection bypasses in place — **proven on a pilot
before you scale.**
