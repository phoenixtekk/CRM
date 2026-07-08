# Executive Summary — Purview Audit → SIEM Integration

## The problem
Microsoft Purview's unified audit log records who did what across the Microsoft 365 estate — but by
default that signal stays **trapped in the portal**. The SOC can't correlate it with identity, endpoint,
and network telemetry; can't build detections or alerts on it; and can't retain it past the audit store's
window. An audit trail nobody's SIEM can see is a compliance gap and a detection blind spot. And the
dangerous failure isn't "no data" — it's **silent partial loss**: a subscription stops, a webhook expires,
a content type was never subscribed, and detections quietly go dark for months.

## The solution
A complete, self-guided build of the **audit-to-SIEM pipeline**. It exports the unified audit log into
your SIEM via the **Office 365 Management Activity API** (content subscriptions, push webhook or poll),
the newer **Microsoft Graph Audit Log Query API**, or a **native connector** (Microsoft Sentinel, the
Splunk Add-on, vendor connectors) — piloted on one content type, then **reconciled against the source
audit log** to prove nothing is lost, then expanded to full workload coverage. Five safe-by-default
PowerShell tools (read-only or `-WhatIf` until you commit; certificate app-only auth, no secrets) do the
assessment, subscription configuration, blob validation, reconciliation, and pipeline reporting.

## What you get
- **The right export path** — native connector, Management Activity API, or Graph query API — chosen for
  your SIEM and tenant, not by default.
- **A least-privilege app identity** — certificate app-only, `ActivityFeed.Read` (`ReadDlp` for DLP),
  admin-consented — with no secret in code.
- **Content subscriptions per workload** — Entra, Exchange, SharePoint, General, DLP — piloted one at a
  time then expanded, mapped to the SOC's detection use-cases.
- **Proof it's lossless** — reconciliation of SIEM ingestion against the source audit log, so silent
  partial loss surfaces as a gate, not a missed alert.
- **A monitored pipeline** — a stopped subscription, an expired webhook, or a lapsed certificate is a
  first-class alert, because a dark feed blinds the SOC.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot → Validate →
Expand** — starting one content type end-to-end into the SIEM and reconciling it clean before expanding,
with pass/fail gates and documented rollback (stop the subscription; the source audit log is never touched).

## Boundaries
This solution builds the **pipeline**; enabling and configuring audit itself (ingestion, Premium
high-value events, retention) is the companion **Purview Audit** solution — no export path can ship what
audit isn't capturing, and **audit is not retroactive**. Export surface and limits are
**licensing-/tenant-dependent and evolving** (Management API bandwidth, Graph query API availability,
which native connectors exist) — cited or flagged **"verify your licensing/tenant,"** never assumed.
**Detection content is the SOC's; retention adequacy, legal-hold, and regulatory determinations are
deferred to compliance, records, privacy, and legal.**

## The bottom line
Audit signal **out of the portal and into the SIEM** — reliably, least-privilege, and reconciled — so an
incident finds **answers in your SIEM, not gaps**.
