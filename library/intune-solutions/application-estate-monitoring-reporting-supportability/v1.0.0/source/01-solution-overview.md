# Solution Overview

## The problem this solves

You can see whether **one** app installed on **one** device. What you cannot see is whether the
**application estate as a whole** is healthy: which apps fail most often, whether failures cluster in
one deployment ring, how long an app takes to reach 95% of its target population, how far behind the
approved version the fleet has drifted, whether anyone is actually using the app you licensed, and —
when something breaks — who owns the number and what evidence support must attach to the ticket.

Most organizations answer those questions by exporting a CSV from the Intune console every few weeks,
pasting it into a spreadsheet, and arguing about which number is right. The export is manual, the
definitions change every time, and nothing raises its hand when the failure rate doubles overnight.

This solution builds the **monitoring, reporting, and supportability layer** for application
management. It fixes a KPI set with explicit healthy ranges, defines a delivery SLO, builds a
**scheduled Microsoft Graph export → storage → Power BI** pipeline, ships a **three-view dashboard**
(executive, operations, per-app drill-down), defines **what alerts versus what waits for the weekly
review**, and puts an **operational review and triage model** around it so a number that goes red
lands on a named owner's queue with the evidence already attached.

## What this solution is NOT

- It is **not** app packaging or deployment authoring. It assumes apps are already being deployed.
- It is **not** per-incident app-install troubleshooting. When a specific install fails, this layer
  tells you *which* app, ring, and device to look at, and hands the evidence to the troubleshooter.
- It is **not** software licensing or spend reporting. Entitlement counts, cost per seat, renewal
  timelines, and reharvesting are a different discipline with a different data model. This layer
  measures **deployment health and supportability**, not money.

## The measurement model

Every metric in this solution answers one of four questions. Keeping them separate is what stops a
dashboard from becoming a wall of numbers nobody acts on.

| Question | Metric family | Example |
|---|---|---|
| Did the app arrive? | **Delivery** | Install success rate, failure rate, pending rate |
| Did it arrive fast enough? | **Velocity** | Time-to-deploy (P50/P90), ring completion time |
| Is it the right version? | **Currency** | Version drift %, patch currency, supersedence lag |
| Is anyone using it? | **Value** | App adoption / active usage, uninstall success |

A fifth family, **Data quality**, sits underneath all of them: detection mismatch rate and stale
check-in rate tell you whether the other four numbers can be trusted at all.

## The KPI set

The solution defines one authoritative KPI set, named **`App Estate KPI Set – v1`**, and every
dashboard visual, alert rule, and script output traces back to it. Each KPI has one — and only one —
source of truth, so the same question always returns the same number.

| KPI | Definition | Healthy range | Source |
|---|---|---|---|
| **Install success rate** | `installed ÷ (installed + failed)` for Required assignments | ≥ 97% | Graph `deviceStatuses` |
| **Failure rate by app** | `failed ÷ applicable` per app | ≤ 3% | Graph `deviceStatuses` |
| **Failure rate by ring** | Same, grouped by deployment ring group | ≤ 3%, and no ring > 2× another | Graph + group membership |
| **Detection mismatch rate** | Devices reporting install success but not detected | ≤ 1% | Graph install state vs. detected app inventory |
| **Time-to-deploy (P50 / P90)** | Hours from assignment creation to 50% / 90% of target installed | P50 ≤ 24 h, P90 ≤ 96 h | Export history (trend) |
| **Version drift %** | Devices not on the approved version ÷ devices with the app | ≤ 10% | Graph `detectedApps` |
| **Patch currency (n-1)** | Devices on the current or previous approved version | ≥ 95% | Graph `detectedApps` |
| **Uninstall success rate** | `installed→removed` success for Uninstall assignments | ≥ 95% | Graph `deviceStatuses` |
| **App adoption / usage** | Devices with a launch/active signal in 30 days ÷ devices with the app installed | ≥ 70% (review below) | Usage telemetry (see below) |
| **Stale device rate** | Devices whose last check-in is > 7 days | ≤ 5% | Graph `managedDevices` |

> **Honest caveat on adoption:** Intune does **not** report per-app *launch* telemetry for Windows
> desktop applications. Adoption is therefore assembled from whichever signal your estate actually
> has — Microsoft 365 Apps usage reports, Defender for Endpoint software inventory, Windows
> Update-for-Business / Endpoint analytics app reliability data, or the vendor's own portal. The
> solution tells you how to wire whichever source you have and how to label the KPI's confidence.
> Do not present an adoption number whose source you cannot name.

## The SLO for application delivery

A KPI tells you where you are. An **SLO** tells you what you promised. The solution defines the app
delivery SLO as three commitments, published to the business and tracked on the executive view:

1. **Availability** — 97% of Required assignments reach *Installed and Detected* on in-scope devices.
2. **Timeliness** — 90% of in-scope devices install a new Required app within **96 hours** of
   assignment (measured after the ring's scheduled availability time, not the authoring time).
3. **Currency** — 95% of devices with a managed app are on the current or previous approved version.

The **error budget** is the inverse: at a 97% availability objective, 3% of applicable installs may
fail in a rolling 30-day window. Burning more than half the budget in the first third of the window
is itself an alert condition (see Alerting) — it is the earliest honest signal that a rollout is
going wrong.

## Where the data lives

Five sources, in order of how much you should rely on them:

1. **Microsoft Graph — `deviceAppManagement`** (`mobileApps`, `.../deviceStatuses`,
   `.../userStatuses`, `mobileAppRelationships`). The authoritative per-device install and detection
   state. This is the backbone of the pipeline.
2. **Microsoft Graph — `deviceManagement`** (`managedDevices`, `detectedApps`,
   `managedDevices/{id}/detectedApps`, `reports/exportJobs`). Fleet inventory, installed application
   versions (the basis for version drift), and the asynchronous **export jobs** API that produces the
   same payloads the console's report pages show.
3. **Intune admin center reports** — the on-screen views you validate the pipeline against:
   **Intune admin center > Reports > Device management > App install status**, and per app at
   **Intune admin center > Apps > All apps > (app) > Monitor > Device install status**.
4. **Log Analytics / Azure Monitor** — Intune **diagnostic settings** stream operational logs
   (`DeviceComplianceOrg`, `Devices`, `AuditLogs`, and where available `Apps` / `AppWorkload`
   categories) into a workspace where they can be queried with KQL, retained, and alerted on.
5. **Intune Data Warehouse** (OData feed, `reports/dataWarehouseFeeds`) — a historical, daily-refreshed
   model useful for long-run trend analysis. It is the slowest-moving source; treat it as a
   supplement for trends, not the live operational picture.

> **Choose one per KPI.** The most common cause of a distrusted dashboard is the same KPI computed
> from two sources that disagree by a few percent because they count "applicable" differently. The
> KPI table above assigns exactly one source to each metric. Keep it that way.

## The pipeline

```
Entra app registration  ──►  Scheduled export (Graph, app-only auth)
  App Estate Reporting          │
      – Graph Export            ▼
                          Storage: Azure Storage container  app-estate-exports
                                 (or the on-prem folder C:\AppEstateReporting\Exports)
                                        │
                                        ▼
                          Power BI dataset  App Estate Reporting – Dataset – v1
                                 (scheduled refresh, 2× daily)
                                        │
                                        ▼
                          Power BI report  App Estate Reporting – Report – v1
                            Page 1 Executive · Page 2 Operations · Page 3 App Drill-down
                                        │
                                        ▼
                          Alerts (Azure Monitor)  ──►  Action group  AG – Endpoint Operations
                          Weekly review           ──►  Triage queue
```

Every object in that diagram is created by name in the Implementation section and the exact same name
is reused in Testing, Troubleshooting, and the scripts.

## The supportability model

Reporting without ownership produces dashboards nobody reads. This solution pairs each KPI with:

- **A named owner** — the role accountable for the number moving in the right direction.
- **A cadence** — daily triage, weekly operational review, or monthly service review.
- **A trigger** — the threshold at which it becomes work.
- **An evidence pack** — the exact artifacts support attaches to an app-failure ticket, so the ticket
  is actionable on first read instead of bouncing back for more information.

## Deployment model

The solution follows the standard model: **Assess → Configure → Pilot → Validate → Expand.** You
build the pipeline against a small set of apps first, prove the numbers match the console, and only
then widen it to the whole estate and turn on alerting.

## Government cloud

US Government tenants (GCC, GCC High, DoD) use **different service endpoints** for Graph, the admin
portals, and Power BI. Every step and every script in this solution is written to target either
cloud; the endpoint substitution table and the parity caveats are in Requirements (R11) and
Implementation (Step 0). Nothing in the method changes — only the URLs and one script parameter.

## What is in this solution

- **This overview** — the measurement model, KPI set, SLO, data sources, pipeline, supportability model.
- **Requirements** (`02-requirements.md`) — licensing, roles, Graph scopes, Power BI, Azure, network.
- **Implementation** (`03-implementation.md`) — the exact ordered build of the pipeline and dashboard.
- **Testing** (`05-testing.md`) — the pass/fail gates that prove the numbers are trustworthy.
- **Troubleshooting** (`06-troubleshooting.md`) — what to do when the pipeline or dashboard misbehaves.
- **Best practices** (`07-best-practices.md`) — retention, least privilege, cost, and review discipline.
- **Deliverables summary** (`08-deliverables-summary.md`) and the **executive summary**.
- **Five PowerShell scripts** — install-status extractor, top-N failure report, version-drift report,
  KPI snapshot generator, and the scheduled-export bootstrap.
