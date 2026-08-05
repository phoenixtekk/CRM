# Best Practices

These are the disciplines that keep the reporting layer trustworthy, cheap, and actually used. They
cover the two things that most often go wrong — alerting on the wrong signals, and letting the
dashboard drift away from reality — plus retention, least privilege, and cost.

## Alert vs. weekly review — the split that keeps the pager credible

The fastest way to make people ignore monitoring is to page them on things that could have waited.
Decide, for every condition, whether a human must act **now** or whether it belongs in a scheduled
review. Only two classes of condition earn a page.

| Condition | Route | Why |
|---|---|---|
| Install failure rate spikes to **> 2× the 7-day baseline** in a 6-hour window | **Page** (`ALERT – App Failure Rate – High`) | A live rollout is going wrong; every hour multiplies the blast radius. |
| **Error budget burn** — more than half the 30-day budget consumed in the first third of the window | **Page** | The SLO will be missed unless someone intervenes; earliest honest signal. |
| A single app creeps from 1% to 3% failures over two weeks | **Weekly review** | Real but not urgent; belongs on the Operations page agenda. |
| Version drift grows past 10% on one app | **Weekly review** | Schedule an update/supersedence; not a fire. |
| Adoption below target for a licensed app | **Monthly service review** | A value/cost conversation, not an incident. |
| Stale device rate rises | **Weekly review** | Investigate check-in health; rarely time-critical. |

Rule of thumb: **page on rate-of-change and budget burn; review on levels and trends.** Re-tune the
`ALERT – App Failure Rate – High` threshold after the first month against your real baseline — a
threshold that never fires is as useless as one that always does.

## Ownership — every KPI has a name next to it

A red number with no owner is decoration. Record the owner in `App Estate KPI Set – v1`.

| KPI | Owner (role) | Cadence |
|---|---|---|
| Install success / failure rate | Endpoint operations lead | Daily triage + weekly review |
| Failure rate by ring | Deployment/rollout owner | Weekly review |
| Detection mismatch rate | App packaging owner | Weekly review |
| Time-to-deploy (P50/P90) | Deployment/rollout owner | Weekly review |
| Version drift / patch currency | Patch/update owner | Weekly review |
| Uninstall success | Endpoint operations lead | Weekly review |
| App adoption / usage | App/service owner + finance liaison | Monthly service review |
| Stale device rate | Endpoint operations lead | Weekly review |
| SLO / error budget | Service owner | Monthly service review |

## The evidence pack — make every app-failure ticket actionable on first read

When a red number becomes a ticket in `App Estate Triage`, it must carry enough to act on without a
follow-up round-trip. Require these fields/attachments on the template:

1. **App name + AppId** and app type (Win32 / LOB / Store).
2. **Ring / assignment** the failure clusters in.
3. **Affected device list** — exported from the drill-down page (device, last check-in, install
   state, detection state).
4. **Install + detection state** for a representative device.
5. **Log excerpt** — the relevant lines from
   `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` /
   `AppWorkload.log`, or a **Collect diagnostics** package.
6. **KPI + target** the ticket is defending (e.g. "install success 92% vs 97% SLO").

A ticket with all six is picked up and worked; a ticket with two bounces back and wastes a day.

## Keep the dashboard honest

- **One source per KPI.** The single biggest cause of a distrusted dashboard is the same metric
  computed two ways that disagree by a few percent. The KPI table assigns exactly one source per
  metric — keep it that way, and never add a visual that recomputes a KPI from a different query.
- **Re-validate against the console monthly.** Repeat Testing Gate 2 for two or three apps each month.
  Microsoft changes report shapes and Graph beta endpoints; a quarterly drift check catches it before
  a leader does.
- **Label confidence on adoption.** Because Intune has no native per-app launch telemetry for Windows
  desktop apps, always show which source the adoption number came from and mark it "indicative" if
  it's assembled from Defender/M365/Endpoint-analytics signals rather than a definitive usage feed.
- **Version the KPI set.** If you change a definition or target, bump to `App Estate KPI Set – v2` and
  re-author the measures — never silently redefine a metric people are already tracking.

## Least privilege for the reporting identity

- The unattended export identity **`App Estate Reporting – Graph Export`** gets **read-only
  application scopes only** (`DeviceManagementApps.Read.All`,
  `DeviceManagementManagedDevices.Read.All`). A reporting pipeline never needs write.
- Prefer a **certificate** over a client secret, and set a **1-year** expiry with a renewal reminder.
- Grant storage access at the **container** level (`app-estate-exports`), not the whole account:
  **Storage Blob Data Contributor** to the writer, **Storage Blob Data Reader** to the Power BI
  refresh identity.
- Keep failing-device detail on need-to-know: **Viewer** on the Power BI workspace for consumers, full
  access only for the operations team.

## Data retention

- **Exports in storage:** keep 90 days of raw snapshots for reproducibility and trend backfill; expire
  older blobs with an Azure Storage **lifecycle management** rule to control cost.
- **KPI snapshots:** keep the appended trend CSV indefinitely — it's tiny and it's what the executive
  trend line and error-budget history read.
- **Log Analytics:** set the `law-endpoint-ops` retention to your compliance minimum (often 30–90
  days interactive), archiving longer if required. Ingestion and retention are the main cost lever
  (see below).

## Cost

- **Power BI Pro** per author/consumer, or **Premium/Fabric** capacity for broad read-only sharing —
  decide by audience size, not by feature envy.
- **Log Analytics** is billed by GB ingested and retention days. Send only the categories you alert
  on; app/audit categories are far cheaper than verbose device telemetry. Start narrow and add.
- **Azure Storage** for exports is negligible with a 90-day lifecycle rule.
- The whole pipeline is designed to be **read-only and low-volume** — a nightly export plus two Power
  BI refreshes — so it stays cheap by construction. The expensive mistake is over-collecting logs
  "just in case."

## Government cloud

Keep a **separate** Power BI report and dataset for a Government tenant — the commercial and
`app.powerbigov.us` services do not share workspaces, and feature parity lags. Author against the
Government Graph and storage endpoints from the start (Requirements R11) rather than trying to
re-point a commercial report later. Where a Graph report endpoint or Power BI feature you rely on is
not yet in your Government cloud, **verify for GCC High** against Microsoft's US-sovereign-cloud
documentation before promising the metric.
