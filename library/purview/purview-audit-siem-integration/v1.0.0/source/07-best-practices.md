# 7. Best Practices — Purview Audit → SIEM Integration

Operating principles for a **reliable, defensible** audit-to-SIEM pipeline. They extend the category
global requirements and reflect the Assess → Design → Configure → Pilot → Validate → Expand model.

## Path selection
- **Prefer a native connector where one exists.** Microsoft Sentinel's Office 365 / Microsoft 365
  connectors and the Splunk Add-on for Microsoft Office 365 manage subscriptions and collection for you —
  far less to build and monitor than the raw API. Use the **Management Activity API** directly only when you
  need control the connector can't give, or no connector exists.
- **Treat the Graph Audit Log Query API as evolving.** It is the newer, query-based path — **verify its
  availability/GA status in your tenant** and confirm supportability before standardizing automation on it.
- **Don't double-feed a content type.** If a native connector already ingests `Audit.Exchange`, don't also
  run a Management API subscription for it into the same SIEM — you'll pay twice and confuse reconciliation.

## Identity & secrets
- **App-only, certificate, least-privilege.** Grant the app only `ActivityFeed.Read` (add
  `ActivityFeed.ReadDlp` only if exporting DLP). Authenticate with a **certificate**, never a client secret
  in code. Store the thumbprint in the runbook; keep the private key on the collection host only.
- **Rotate the certificate before it expires** and track its expiry as a monitored item — a lapsed cert
  silently kills the feed.
- **Scope the operator too.** The reconciliation operator needs only **Audit Reader** to read the source;
  don't run reconciliation as Global Admin.

## Delivery reliability
- **Webhooks expire — renew them.** Management Activity API webhook subscriptions have an expiration; put
  renewal on a schedule and alert if a webhook goes stale. A webhook that silently expired is the classic
  "why did detections stop?" incident.
- **Checkpoint your poll.** If polling, track the last-collected blob/time so a collector restart doesn't
  re-ingest or skip. Handle the API's paging and `NextPageUri` fully — never assume one page is all the data.
- **Design for latency, not instantaneity.** The feed is near-real-time (minutes, sometimes longer under
  load). Align detections and reconciliation windows to the feed's latency; don't alert on "missing" events
  that are merely still in flight.
- **Handle blob retention.** Content blobs are only available for a limited window at the API — if your
  collector is down long enough, un-collected blobs age out and are lost. Monitor collector uptime and alert
  on gaps.

## Reconcile, always
- **Reconcile SIEM ingestion against the source.** The dangerous failure is *silent partial loss*, not total
  outage. Compare source audit counts (`Search-UnifiedAuditLog` / Graph Audit Log Query) to SIEM-ingested
  counts per workload on a cadence, within a latency-aware tolerance. A pipeline you don't reconcile is a
  pipeline you can't trust.
- **Make pipeline health a first-class alert.** Alert on: a subscription flipping disabled, a webhook near
  expiry, a content type with no recent blobs, a certificate nearing expiry, a reconciliation shortfall. A
  dark feed blinds the SOC — treat it with the same urgency as a down detection.

## Coverage & cost
- **Subscribe deliberately, driven by use-cases.** Map content types to detection use-cases with the SOC and
  subscribe to what earns its ingestion cost. High-volume content types (SharePoint file operations) can be
  large — confirm the SIEM's ingestion budget before turning them on tenant-wide.
- **Pilot one content type first.** Validate the whole chain (subscribe → deliver → ingest → reconcile) on
  `Audit.AzureActiveDirectory` before expanding, so you debug the pipeline once, not five times.
- **Set SIEM-side retention to the compliance target,** independent of the audit store's window — export is
  how you keep audit evidence long-term. The **retention duration is a compliance/records determination**,
  not a technical default.

## Governance & boundaries
- **Detection content is the SOC's; determinations are governance's.** This solution delivers the feed and
  proves it flows; which alerts to build and how to respond are SOC decisions, and **retention adequacy,
  legal-hold, and regulatory obligations are deferred to compliance, records, privacy, and legal.**
- **Change-control the pipeline.** Starting/stopping subscriptions, changing delivery, and altering coverage
  are tenant-impacting — do them under change control with the pilot-first discipline and a documented
  rollback (stop the subscription; the source audit log is never touched).
- **Document the pipeline.** Keep the path, app identity, content types, delivery model, SIEM endpoint, and
  reconciliation window in the runbook so the pipeline is operable by someone other than its author.
