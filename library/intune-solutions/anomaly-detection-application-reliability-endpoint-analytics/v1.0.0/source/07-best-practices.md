# 7. Best Practices — Anomaly Detection & Application Reliability with Endpoint Analytics

Field-proven guidance for running the reliability side of Endpoint Analytics as a durable practice.

## Read the signals the right way
- **Never act on a single data point.** Reliability signals are aggregate and delayed — confirm a
  trend across a data refresh before you route a fix. *(Exact data latency — verify against current
  Microsoft documentation.)*
- **Always check the version dimension first** for an app problem. One bad version with a clean prior
  version is a **bad rollout**; all versions crashing across a broad, mixed population is a **bad app**.
  The version breakdown is the fastest way to route the right owner.
- **Scope restart trends before blaming a cause.** A model-scoped restart spike is a driver/firmware
  lead; a fleet-wide spike right after an OS update is an update lead. Read the cohort, not just the
  total.
- **Treat an anomaly as a lead, not a verdict.** Read the metric, the cohort, and the start time, then
  cross-check it against the underlying report. Confirm it's real (persists + has underlying movement)
  before spending remediation effort.

## Separate a bad app from a bad rollout — every time
- **Common factor is the app → bad app.** Broad, mixed population, all versions. Fix/update/roll back
  the app; owner is the app owner.
- **Common factor is the change event → bad rollout.** Concentrated in the population that got a new
  version/config, started right after. Pause/stage/roll back the deployment; owner is the deployment
  owner.
- **When in doubt, widen the window and narrow the cohort** — more time confirms the trend, a tighter
  cohort confirms the common factor.

## Route to the right owner and close the loop
- **One handoff, one label.** Use `Reliability Handoff – <App|Driver|Update> – <Version>` so every fix
  is traceable from signal to owner to recovery.
- **Attach the evidence.** The report row/export (`Reliability Review – <YYYY-MM>.csv`), the affected
  cohort, and the start time — owners fix faster with the specifics.
- **Verify recovery before closing.** The loop is closed only when the **same** signal recovers, not
  when the fix ships. Re-read the report and re-run `ENDPTREL-Test-Signal.ps1`.

## Hand scriptable fixes to the automated-fix companion
- **Don't fix fleet-wide problems by hand.** Where the remediation is scriptable — clear a bad cache,
  reset a service, roll back a driver, repair a config — hand it to **"Proactive Remediations at
  Scale"** (the automated-fix companion) with the exact detect/remediate conditions.
- **This product decides *what* and *who*; the companion decides *how* at scale.** Keep that division —
  it's what makes the two solutions compose instead of overlap.
- **Target the fix at the affected cohort**, not the whole fleet, unless the problem is genuinely
  fleet-wide.

## Lean on the parent for the data, not this product
- **Data problems are the parent's job.** Empty/thin reliability data, scope, and licensing belong to
  the **parent** Endpoint Analytics solution — don't try to fix data collection from inside the
  reliability practice; fix it upstream and return.
- **Keep the review scope aligned with data collection.** `Reliability – Review Scope` should mirror
  the population Endpoint Analytics is collecting, so you review exactly what's reporting.

## Make it a cadence, and measure it
- **Run a standing reliability review** (`Reliability Review – Weekly` to start, monthly once steady)
  against `Reliability – Review Scope`, working the read-triage-route-verify loop every time.
- **Keep the monthly export** (`Reliability Review – <YYYY-MM>.csv`) as the trend record.
- **Track corrections-per-review over time.** A downward trend means you're catching regressions early
  and preventing ticket waves — the whole point of the practice.
- **Rehearse on the pilot first.** Prove the loop on `Reliability – Pilot` before widening to the
  fleet.

## Respect national-cloud differences
- **Verify Government parity.** For GCC / GCC High / DoD tenants, portal URLs and feature availability
  (including whether anomaly detection is present) can differ — verify against Microsoft's US-sovereign-
  cloud documentation rather than assuming Commercial behavior.
