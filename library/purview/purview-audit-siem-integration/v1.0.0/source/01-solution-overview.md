# 1. Solution Overview — Purview Audit → SIEM Integration

## What this solution is
Microsoft Purview's unified audit log holds the record of who did what across Exchange, SharePoint,
OneDrive, Teams, Entra ID, DLP, and more — but by default that signal stays **trapped in the portal**.
Your SOC can't correlate it with the rest of the estate, can't build detections on it, can't alert on
it, and can't retain it past the audit store's window. This solution builds the **pipeline** that gets
that signal out: it stands up continuous export of unified audit + activity data from Microsoft Purview
into your **SIEM** — via the **Office 365 Management Activity API** (content subscriptions, optionally
push-delivered by webhook) and/or the newer **Microsoft Graph Audit Log Query API**, or a **native
connector** where one exists — then pilots it on one content type, validates end-to-end that no events
are being dropped, and expands to full workload coverage. It uses only the **Microsoft Purview portal**,
**Exchange Online / Security & Compliance PowerShell**, **Microsoft Graph**, and the **Management
Activity API** — no third-party tooling beyond your SIEM's own connector.

> **Scope boundary — this is the *integration/pipeline*, not audit configuration itself.** Confirming and
> enabling unified audit logging, Audit Premium high-value events, retention policies, and building
> investigation runbooks is the companion **Purview Audit (Standard & Premium)** solution. This solution
> assumes audit is *on* and focuses end-to-end on **getting it into the SIEM reliably** — the app
> identity, subscriptions, delivery, connector, and the reconciliation that proves nothing is lost.

## Why this matters
- **Audit signal in a SIEM is where detection happens.** `MailItemsAccessed`, inbox-rule creation,
  privileged role adds, app consents, mass downloads, anonymous-link creation — these only become alerts
  when they land next to your identity, endpoint, and network telemetry and can be correlated.
- **The audit store is not a long-term archive.** Audit (Standard) retains most records ~180 days;
  streaming to a SIEM / data lake is how you keep audit evidence for the duration your compliance and
  legal functions require, independently of the audit store's retention.
- **There are several export paths and they are evolving.** The **Management Activity API** (poll or
  webhook), the **Graph Audit Log Query API** (newer), and **native connectors** (e.g. Microsoft
  Sentinel's Office 365 / Microsoft 365 connectors, the Splunk Add-on) each have different effort,
  latency, and coverage profiles. Choosing right — and confirming what your tenant/licensing supports —
  matters more than any single cmdlet. **Verify your licensing/tenant.**
- **A pipeline you don't reconcile is a pipeline you don't trust.** The failure mode isn't "no data" —
  it's *silent partial loss*: a subscription stops, a webhook expires, a content type was never
  subscribed, blobs age out un-collected. This solution reconciles SIEM ingestion against the source
  audit log so gaps surface as a gate, not as a missed detection six months later.

## How it works
1. **Assess the export surface.** Read-only discovery reports whether unified audit ingestion is on,
   which Management Activity API **content subscriptions** already exist, whether an app identity with
   the right permissions is in place, and whether a native connector is already ingesting — so you know
   the real starting point, not the assumed one.
2. **Choose the path.** Decide per environment: native connector (lowest effort where available),
   Management Activity API (most control, push or poll), or Graph Audit Log Query API (newer, query-based).
   The choice is driven by your SIEM, latency needs, and tenant support — not by defaults.
3. **Stand up the identity.** For the Management Activity API, an **Entra app registration** with
   `ActivityFeed.Read` (and `ActivityFeed.ReadDlp` for DLP events), admin-consented, authenticating
   **app-only with a certificate** — never a client secret in code.
4. **Subscribe to content, pilot-first.** Start **one** content type (typically `Audit.AzureActiveDirectory`)
   in a bounded pilot, optionally with a **webhook** for push delivery, and confirm the SIEM receives blobs
   before expanding to the rest.
5. **Reconcile.** Compare what the SIEM ingested for a window against the source unified audit log
   (`Search-UnifiedAuditLog` / Graph Audit Log Query) — record counts by workload — so any drop, lag, or
   missing content type is caught explicitly.
6. **Validate and expand.** A pipeline scorecard confirms every gate — ingestion on, subscriptions
   enabled, delivery current, coverage per workload, reconciliation clean — then export expands to full
   scope and the read-only checks run on a cadence to catch drift.

## The export stack this solution configures
- **Unified audit log** — the single source of user/admin activity across the M365 estate (assumed on).
- **Office 365 Management Activity API** — `manage.office.com/api/v1.0/{tenant}/activity/feed`; content
  **subscriptions** per content type, blobs retrieved by **poll** or delivered by **webhook**; app-only
  cert auth with `ActivityFeed.Read` / `ActivityFeed.ReadDlp`.
- **Content types** — `Audit.AzureActiveDirectory`, `Audit.Exchange`, `Audit.SharePoint`,
  `Audit.General`, `DLP.All`.
- **Microsoft Graph Audit Log Query API** — `/security/auditLog/queries` (newer, query/result model) —
  an alternative retrieval path; **verify availability/GA status in your tenant**.
- **Native SIEM connectors** — e.g. **Microsoft Sentinel** Office 365 & Microsoft 365 connectors, the
  **Splunk Add-on for Microsoft Office 365**, and vendor connectors (QRadar, Elastic) that consume the
  Management Activity API for you — lowest-effort where supported.
- **Delivery model** — webhook (push) vs. scheduled poll with checkpointing; both must be monitored.

## What you can control
- The **export path** (native connector / Management Activity API / Graph) per environment.
- Which **content types** (workloads) stream, and in what order they are piloted then expanded.
- **Push vs. poll** delivery and the collection cadence / checkpoint.
- The **pilot scope** (one content type, a bounded window) validated before full coverage.
- The **reconciliation window and tolerance** used to prove the pipeline is lossless.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across
the docs, scripts, and portal/SIEM. The standard set:

| Artifact | Name |
|---|---|
| Entra app registration for the feed | `Audit Feed – Management API – AppReg` |
| App-only authentication certificate | `Audit Feed – App-Only – Certificate` |
| Entra content subscription | `Audit Export – Entra – Subscription` |
| Exchange content subscription | `Audit Export – Exchange – Subscription` |
| SharePoint content subscription | `Audit Export – SharePoint – Subscription` |
| General content subscription | `Audit Export – General – Subscription` |
| DLP content subscription | `Audit Export – DLP – Subscription` |
| Push-delivery webhook | `Audit Feed – Blob Notification – Webhook` |
| SIEM ingestion connector | `Audit Ingestion – SIEM – Connector` |
| Pilot validation scope | `Audit SIEM Pilot – Entra Feed – Stage1` |
| Source↔SIEM reconciliation report | `Audit Pipeline – Coverage – Report` |
| Audit-event → detection use-case map | `Audit-to-Detection – Use-Case – Map` |

## Limitations (be honest with buyers)
- **This is the pipeline, not the audit config.** If unified audit ingestion is off, or the events you
  want (e.g. `MailItemsAccessed`, a Premium high-value event) aren't being generated, no export path can
  ship what was never captured — configure audit first (companion solution). **Audit is not retroactive.**
- **Export paths and their limits are licensing-/tenant-dependent and evolving.** Management Activity API
  bandwidth, the availability/GA status of the Graph Audit Log Query API, and which native connectors are
  offered vary by plan and change over time — **verify your licensing/tenant** before standardizing.
- **The Management Activity API is near-real-time, not instant.** Content is published in blobs with
  inherent latency (typically minutes, can be longer under load); it is an activity feed, not a live tap.
- **SIEM-side ingestion, parsing, and cost are yours.** This solution delivers the source feed and proves
  it flows; the connector configuration, field parsing, detection rules, and ingestion cost inside your
  SIEM are owned by your SOC/SIEM team (we provide the use-case map and reconciliation, not the SIEM licence).
- **Detection content and case actions are deferred.** Which alerts to build and how to respond are SOC
  determinations; **retention adequacy and any legal-hold/regulatory obligations are deferred to your
  compliance, records, privacy, and legal functions** — this solution provides the technical method and
  the evidence, not the determination.

## The standard deployment model
> Assess the current export surface → design the path, identity, and content-type coverage → configure the
> app, subscriptions, and delivery → **pilot** one content type end-to-end into the SIEM → validate by
> reconciling SIEM ingestion against the source audit log → expand to full workload coverage and schedule
> the drift checks. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
