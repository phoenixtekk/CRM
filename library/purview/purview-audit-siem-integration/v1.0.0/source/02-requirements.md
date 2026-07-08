# 2. Requirements Guide — Purview Audit → SIEM Integration

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C PowerShell
+ Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot & change control) are
in `global-requirements-purview.md` — this guide adds the **export/pipeline-specific** detail.

> **Licensing/tenant boundary.** Export **surface** and **limits** are plan- and tenant-dependent and
> evolving: Management Activity API bandwidth scales with your subscription (higher with Audit Premium /
> E5), the **Graph Audit Log Query API** availability/GA status varies, and which **native connectors**
> your SIEM offers changes over time. Where this guide flags "verify your licensing/tenant," do so before
> relying on a path. This solution assumes **unified audit logging is already on** — see the companion
> Purview Audit solution to enable and configure it.

## 2.1 Unified audit logging already enabled (assumed input)
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** for the tenant, and the events you
intend to export (e.g. mailbox high-value events, DLP events) must actually be generated. This solution
exports what audit captures; it does not capture it.
**Why:** No export path can ship records that were never written; audit is not retroactive (GR §6).
**Verify:** `Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled` (via
`Connect-ExchangeOnline`); `AUDSIEM-Discovery.ps1` reports the state and flags it if off.
**Implement:** Enable and configure audit first (companion **Purview Audit (Standard & Premium)**
solution) before wiring export.

## 2.2 Export path decided (native connector vs. Management API vs. Graph)
**Description:** A decision on **how** audit will reach the SIEM: a **native connector** (e.g. Microsoft
Sentinel's Office 365 / Microsoft 365 connectors, the Splunk Add-on for Microsoft Office 365, or a
vendor connector for QRadar/Elastic), the raw **Office 365 Management Activity API** (most control; push
or poll), or the **Microsoft Graph Audit Log Query API** (newer, query-based).
**Why:** Effort, latency, coverage, and cost differ per path; picking one drives every step below.
**Verify:** Confirm which connector your SIEM offers and whether it is already ingesting; confirm the
Graph Audit Log Query API's availability in your tenant if you plan to use it.
**Implement:** Prefer a **native connector where available** (lowest effort); use the Management Activity
API when you need control the connector doesn't give, or when no connector exists. **Verify your
licensing/tenant** for the Graph path before standardizing on it.

## 2.3 Entra app registration for the Management Activity API (if using it)
**Description:** An **Entra app registration** — `Audit Feed – Management API – AppReg` — with the
application permission **`ActivityFeed.Read`** (Office 365 Management APIs), plus **`ActivityFeed.ReadDlp`**
if you will export DLP events, **admin-consented**.
**Why:** The Management Activity API authorizes per app identity; without the granted+consented permission,
subscription and content calls fail with authorization errors (GR §2).
**Verify:** Entra admin center → `App registrations → <app> → API permissions` shows the `ActivityFeed.*`
application permissions **granted for the tenant**; `AUDSIEM-Discovery.ps1` (read-only) can list current
subscriptions with the app to prove auth works.
**Implement:** Register the app, add the Office 365 Management APIs → Application permissions
`ActivityFeed.Read` (`ActivityFeed.ReadDlp` for DLP), and grant admin consent — under change control.

## 2.4 Certificate app-only authentication (no secrets in code)
**Description:** The app authenticates **app-only with a certificate** — `Audit Feed – App-Only –
Certificate` — uploaded to the app registration, private key available on the run host by thumbprint. **No
client secret is stored in scripts.**
**Why:** Certificate credentials avoid a long-lived secret in code/config and are the supported app-only
pattern; this solution's rule (and GR) is **never hardcode credentials/secrets**.
**Verify:** The certificate's public key is on the app registration (`Certificates & secrets`), and
`Get-Item Cert:\CurrentUser\My\<thumbprint>` (or LocalMachine) returns it with a private key on the run host.
**Implement:** Create/obtain a certificate, upload the `.cer` to the app, install the private key on the
collection host, and record the thumbprint (not the key) in your runbook.

## 2.5 Export/read roles (least-privilege)
**Description:** The identities involved need least-privilege roles: the **app** needs only the
`ActivityFeed.*` application permission (2.3); the **admin** running reconciliation needs **View-Only
Audit Logs / Audit Logs** (or the Purview **Audit Reader** role group) to run `Search-UnifiedAuditLog` /
the Graph query for the source-of-truth comparison; and configuring the app/consent needs the appropriate
Entra admin role. Reserve Global Administrator for consent/registration only.
**Why:** Purview and Entra both use fine-grained roles; over-granting the app or the operator is an
unnecessary risk (GR §2).
**Verify:** App shows only `ActivityFeed.*`; the reconciliation admin can run `Search-UnifiedAuditLog`;
`AUDSIEM-Reconcile.ps1` reports a permissions error if the audit-read role is missing.
**Implement:** Grant the app only `ActivityFeed.*`; assign the operator **Audit Reader** and the least
Entra role needed for app management, under change control.

## 2.6 SIEM ingestion endpoint and its identity
**Description:** The **SIEM/target** that will ingest the feed (Microsoft Sentinel, Splunk, QRadar,
Elastic, a data lake, …) with a defined ingestion endpoint — for **webhook push** an HTTPS endpoint the
Management Activity API can reach (that will pass the API's **validation handshake**), or for **poll** a
collector (connector/add-on/scheduled job) that retrieves and forwards blobs.
**Why:** Export is only useful if something ingests it; webhook and poll each have setup and monitoring
requirements.
**Verify:** The SIEM connector/collector is identified and reachable; for webhook, the endpoint answers the
validation POST; `AUDSIEM-Validate.ps1` can enumerate available content blobs the collector should be
consuming.
**Implement:** Stand up the SIEM connector/collector (native connector, Splunk Add-on, or your own webhook
receiver) and confirm reachability before starting subscriptions.

## 2.7 Detection use-cases and retention target (from SOC / compliance)
**Description:** A short statement — from your **SOC** and **compliance/records/legal** functions — of the
**detection use-cases** the export must support (which audit events map to which alerts) and **how long**
audit must be retained in the SIEM/lake beyond the audit store.
**Why:** These are governance/SOC determinations, not technical defaults (GR §5): they decide which content
types matter most and drive the `Audit-to-Detection – Use-Case – Map` and retention config — the solution
configures to them, it does not decide them.
**Verify:** You can name the priority detection use-cases and the required SIEM-side retention, with owners.
**Implement:** Capture the use-case map and retention target with named approvers before expanding coverage.

## 2.8 A pilot scope and change window
**Description:** A limited **pilot** — typically **one content type** (`Audit.AzureActiveDirectory`) over a
bounded window — to validate end-to-end delivery and reconciliation before enabling all content types, plus
an agreed change window (GR §6).
**Why:** Starting subscriptions and (especially) webhook delivery is tenant-impacting and can generate
volume/cost; validate one path small first.
**Verify:** A named pilot scope (`Audit SIEM Pilot – Entra Feed – Stage1`) and change approval exist.
**Implement:** Define the pilot content type, reconciliation window, and change window before starting any
subscription.
