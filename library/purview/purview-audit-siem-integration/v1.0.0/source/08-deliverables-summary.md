# 8. Deliverables Summary — Purview Audit → SIEM Integration

## What you receive
A complete, self-guided package to build and operate a **reliable audit-to-SIEM pipeline** from Microsoft
Purview — export the unified audit log into your SIEM via the Office 365 Management Activity API / Graph
Audit Log Query API / a native connector, piloted on one content type, validated by reconciliation against
the source, then expanded — using only the Microsoft Purview / Entra portals, Exchange Online / Security &
Compliance PowerShell, Microsoft Graph, and the Management Activity API.

## Documents
| Document | What it gives you |
|---|---|
| **Solution Overview** | What the pipeline delivers, the export stack (Management API, Graph query API, native connectors), the artifact naming convention, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **Requirements Guide** | Every export/pipeline prerequisite (source-on precondition, path choice, app registration + `ActivityFeed.*`, certificate app-only auth, least-privilege roles, SIEM endpoint, use-cases/retention, pilot) with how to **verify** and **implement** — referencing the category global requirements. |
| **Implementation Guide** | Exact ordered steps: assess the surface, choose the path, stand up the app identity, start the pilot subscription (webhook or poll), confirm blobs flow to the SIEM, **reconcile** against the source, expand to full coverage, and monitor the pipeline — each object named, with pass/fail gates and rollback. |
| **Testing & Validation Guide** | Ten tests from source-on through app auth, subscription state, webhook handshake, blob availability, end-to-end SIEM ingestion, **reconciliation (no silent loss)**, detections firing, full-coverage regression, and scheduled drift checks. |
| **Troubleshooting Guide** | The common failure modes — auth/consent errors, subscription won't start, webhook validation fails, blobs missing, SIEM shortfall, reconciliation gaps, expired webhook/cert — with causes and fixes. |
| **Best Practices** | Path selection, identity/secret hygiene, delivery reliability (webhook renewal, poll checkpointing, latency), reconcile-always, coverage/cost, and governance boundaries. |
| **Executive Summary** | A one-page brief for decision-makers. |

## PowerShell tools (5)
All are **safe by default** — read-only or `-WhatIf` unless you pass `-Commit`. Management Activity API
calls authenticate **app-only with a certificate**; **no credentials or secrets are stored in code.**

| Script | Purpose | Default mode |
|---|---|---|
| **AUDSIEM-Discovery.ps1** | Assess the export surface: unified audit ingestion state, existing Management API subscriptions, app-identity auth check, and native-connector confirmation. | Read-only |
| **AUDSIEM-Configure-Subscription.ps1** | Start/stop Management Activity API content subscriptions, optionally with a push **webhook**; the only state-changing tool. | `-WhatIf` (writes only with `-Commit`) |
| **AUDSIEM-Validate.ps1** | List available content blobs and counts per content type for a window — confirm the API is publishing what the SIEM should be collecting. | Read-only |
| **AUDSIEM-Reconcile.ps1** | Count source audit records for a window (`Search-UnifiedAuditLog` / Graph Audit Log Query) by workload, to compare against the SIEM's ingested count — catch silent partial loss. | Read-only |
| **AUDSIEM-Report.ps1** | Pipeline health scorecard: ingestion on, subscriptions enabled, blob recency per content type, webhook/cert status flags — the `Audit Pipeline – Coverage – Report`. | Read-only |

## Outcomes
- A **chosen, documented export path** (native connector / Management Activity API / Graph) fit to your SIEM
  and tenant.
- A **least-privilege app identity** (certificate app-only, `ActivityFeed.*`) where the API path is used.
- **Content subscriptions** for the in-scope workloads, piloted then expanded, delivering to the SIEM.
- **Reconciliation** proving the SIEM receives what the source recorded — no silent loss.
- **Pipeline monitoring** so a stopped subscription, expired webhook, or lapsed certificate is an alert, not
  a missed detection.

## Boundaries
Export surface and limits are **licensing-/tenant-dependent and evolving** — capabilities and paths are
cited or flagged **"verify your licensing/tenant,"** never assumed. This solution builds the **pipeline**;
enabling/configuring audit itself is the companion Purview Audit solution. **Detection content is the SOC's;
retention adequacy, legal-hold, and regulatory determinations are deferred to compliance, records, privacy,
and legal** — the solution provides the technical method and the evidence, not the determination.
