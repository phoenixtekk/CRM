# 6. Troubleshooting — Anomaly Detection & Application Reliability with Endpoint Analytics

Work top-down: confirm **reliability data is flowing** (parent solution), then **read the right
signal**, then **classify** (bad app vs. bad rollout vs. environmental), then **route and verify**. Most
problems are one of: data not populated yet, a false anomaly treated as real, or a crash that can't be
pinned to a version because the version dimension isn't being read.

> **Feature, licensing, and navigation specifics — verify against current Microsoft documentation.**
> Report names, blade paths, anomaly-detection availability, data latency, and minimum device
> populations change over time and can differ by cloud (Commercial vs. GCC / GCC High / DoD). Confirm
> the specifics for your own tenant rather than trusting a snapshot.

## Reliability data is missing or delayed
- **Endpoint Analytics not fully enabled / data collection not deployed.** This is the **parent**
  solution's job. Confirm Endpoint Analytics is on and the data-collection policy is deployed and
  assigned to your devices; finish the parent solution before triaging here.
- **Reporting window hasn't filled.** Reliability signals are aggregate and delayed — a new tenant, a
  newly onboarded scope, or a recent policy change needs time to populate. *(Exact latency — verify
  against current Microsoft documentation.)* Wait a full reporting window and re-check.
- **Too few devices in scope.** Aggregate signals need a meaningful population; a handful of devices
  looks empty or noisy. Broaden the data-collection scope (parent solution) and re-check with
  `ENDPTREL-Discovery.ps1`.
- **Licensing/entitlement.** If Endpoint Analytics reports won't render at all, confirm the licensing
  that includes Endpoint Analytics for your devices *(verify against current Microsoft documentation)*.
- **Graph resource path moved.** `ENDPTREL-Discovery.ps1` reads the `userExperienceAnalytics*` /beta
  resources; if it reports "unavailable," the path may have changed — read the reports in the Intune
  admin center and verify the current Graph resource against Microsoft documentation.

## The anomaly view is empty or unavailable
- **Anomaly detection not available in this cloud/tenant.** It may be preview, or absent in your cloud
  (GCC / GCC High / DoD). *(Verify availability against current Microsoft documentation.)* Proceed with
  the application- and device-reliability portions, which don't require it, and adopt anomaly detection
  when available.
- **Below the minimum population/latency for anomalies.** Anomaly detection needs enough devices and
  history to establish a baseline. Let the scope and window fill.

## False anomalies (a signal that isn't real)
- **Transient / tiny-cohort variance.** A small cohort with high variance throws short-lived anomalies.
  Watch it across the next data refresh — a **false** signal **fades**; a **true** signal **persists**
  and has corresponding movement in the underlying report.
- **No underlying movement.** If an anomaly has no matching rise in Application reliability or restart
  analytics, treat it as suspect — don't route a remediation off the alert alone.
- **Reporting gap masquerading as a change.** A gap or late-reporting batch can look like a shift.
  Confirm data continuity before attributing the anomaly to a real change event.
- **Rule of thumb:** confirm **persistence + underlying movement + a plausible change event** before
  spending remediation effort. (Testing guide, Tests 6–7.)

## Can't attribute a crash to a specific app version
- **Version dimension not being read.** In Application reliability, drill into the **version** breakdown
  — a crash is only routable once you know whether one version is bad (bad rollout) or all are (bad
  app). If the version dimension isn't exposed for that app, note it and route on the app-level signal.
- **Signal too fresh.** A brand-new version needs enough installs/time to produce a stable per-version
  signal. Widen the window.
- **App identity ambiguity.** Similarly-named apps can split a signal. Confirm you're reading the right
  app (publisher/identifier) with `ENDPTREL-Test-Signal.ps1 -AppNameLike '<app>'`.

## Restart cause is unclear
- **Cohort not scoped.** Decide first whether the unexpected-restart rise is **fleet-wide** (suspect an
  OS update) or **single-model** (suspect a driver/firmware) — the total alone won't tell you. Filter
  the restart report by model.
- **No change-calendar correlation.** Line the trend's start time up against your update rings, driver
  pushes, and config changes. No correlation usually means it's environmental/noise or the window is too
  short.
- **Planned vs. unexpected mixed together.** Make sure you're trending **unexpected** restarts (stop-
  errors), not planned reboots (updates, user-initiated), which will otherwise mask the real signal.

## The fix shipped but the signal didn't recover
- **Fix didn't reach the affected cohort.** Confirm the app update/rollback, driver rollback, update-
  ring change, or the automated-fix companion's remediation actually targeted the population showing the
  signal (align with `Reliability – Review Scope` or a tighter cohort).
- **Reporting lag after the fix.** Recovery is also delayed — give it a reporting window, then re-read
  and re-run `ENDPTREL-Test-Signal.ps1` (expect NOT DETECTED at problem levels).
- **Wrong owner / wrong root cause.** If it truly won't recover, revisit the bad-app-vs-bad-rollout
  classification — you may have routed the wrong owner.

## Licensing & scope
- **Reports won't load / feature absent.** Verify the Endpoint Analytics entitlement and that anomaly
  detection is available for your cloud *(verify against current Microsoft documentation)*.
- **Review scope drifts from data collection.** Keep `Reliability – Review Scope` aligned with the
  population Endpoint Analytics is collecting, or you'll review a different set than what's reporting.
- **Reader vs. writer permissions.** Reading the reports needs read access (R6); creating
  `Reliability – Review Scope` needs `Group.ReadWrite.All` (R7). A "can read but can't create the group"
  symptom is a permissions split, not a data problem.

## Scripts
- **`ENDPTREL-Discovery.ps1`** *(read-only)* — first stop when data looks missing: reports whether the
  reliability signals return data, the scoped device count, and the top unreliable apps/devices.
- **`ENDPTREL-Validate.ps1`** *(read-only)* — the PASS/FAIL gate; an anomaly-detection **WARN** is
  acceptable (unavailable/preview), a data **FAIL** is not.
- **`ENDPTREL-Report.ps1`** *(read-only)* — if the export is empty, the underlying data is missing (see
  "Reliability data is missing or delayed"), not the script.
- **`ENDPTREL-Test-Signal.ps1`** *(read-only)* — use it both to confirm a bad app's signal is
  attributable and, after a fix, to prove it receded (DETECTED → NOT DETECTED).
- **`ENDPTREL-Set-ReviewScope.ps1`** *(state-changer — defaults to `-WhatIf`)* — if "nothing happened,"
  that's by design: it previews only until re-run with `-Commit`. Creating the group needs
  `Group.ReadWrite.All`.
- **General:** all reads use the `userExperienceAnalytics*` /beta Graph resources, which **change over
  time and vary by cloud** — a script reporting "unavailable / path moved" is a signal to verify the
  current resource against Microsoft documentation, not necessarily a tenant problem. Re-run the
  relevant script after each change to confirm the gate.
