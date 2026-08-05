# Sales Content — Application Estate Monitoring, Reporting & Supportability (Microsoft Graph & Power BI)

**Solution code:** APPRPT · **Category:** Intune Solutions · **Version:** v1.0.0 · **Branding:** off (white-label)

| Tier | SKU | Price |
|---|---|---|
| Commercial | `PTK-APPRPT-COMM-001` | $2,495.00 |
| Non-Profit | `PTK-APPRPT-NPO-001` | $1,497.00 |
| Government | `PTK-APPRPT-GOV-001` | $2,120.75 |

## The hook

Stop guessing whether your applications are actually being delivered. You can see whether one app
installed on one device — but not the estate: which apps fail most, whether failures cluster in one
deployment ring, how far the fleet has drifted from the approved version, whether anyone uses what you
license, and who owns the number when something breaks. Today that answer is a manual CSV pasted into
a spreadsheet — different every time, stale the moment it's made, and silent when the failure rate
doubles overnight. This package replaces it with a living monitoring, reporting, and supportability
layer built on Microsoft Graph and Power BI.

## Run it yourself — simpler, cheaper, proven

- **Simpler** — exact, ordered steps with full navigation paths; every object (app registration,
  storage container, Power BI dataset, scheduled task, alert rule) is named and reused verbatim
  through testing and troubleshooting.
- **Cheaper** — one fixed price versus an open consulting meter that runs into thousands per day; the
  pipeline is read-only and low-volume by design, so it stays cheap to operate.
- **Proven** — a pilot-first method (Assess → Configure → Pilot → Validate → Expand) with a hard trust
  gate: the export must match the Intune console before any number reaches a leader's screen.

## What's inside

- **Solution Overview** — the measurement model (delivery / velocity / currency / value), the *App
  Estate KPI Set* with healthy ranges, the delivery **SLO and error budget**, five data sources, the
  pipeline diagram, and the supportability model.
- **Requirements** — 11 items with Description / Why / Verify / Implement-if-missing, exact Graph
  scopes (delegated and application), Power BI Pro licensing, storage, Log Analytics, and the US
  Government endpoint table.
- **Implementation** — the ordered build of the Graph → Power BI pipeline and the **three-view
  dashboard** (executive / operations / per-app drill-down), scheduled refresh, nightly export, Azure
  Monitor alerting, and the ownership + triage model.
- **5 PowerShell scripts** — install-status extractor, top-N failure report, version-drift/patch-
  currency reporter, KPI-snapshot generator, and the scheduled-export bootstrap. Commercial or US
  Government clouds via one `-Environment` parameter.
- **Testing & Troubleshooting** — 10 pass/fail gates plus the pipeline's own failure modes.

## The repeatable way

Every solution follows the same repeatable shape, so each deployment feels familiar and low-risk — buy
once, reuse the pipeline and the review cadence for the next wave and the next project.

## The bottom line

A trustworthy, automatically-refreshed picture of how well your applications are delivered, kept
current, and used — alerting on the two conditions that can't wait, and wrapped in an ownership model
so every red number lands on a named owner's queue with the evidence already attached.

## Discounted tiers

- **Non-Profit (40% off):** same complete package; eligibility (e.g. 501(c)(3)) verified before the
  discount applies.
- **Government (15% off):** verified public-sector buyers; GCC High / DoD endpoints built into every
  step and script; eligibility (government email domain / SAM.gov entity) verified before the discount
  applies.
