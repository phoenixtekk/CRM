# 1. Solution Overview — Anomaly Detection & Application Reliability with Endpoint Analytics

## What this solution is
This solution operationalizes the **reliability side of Microsoft Intune's Endpoint Analytics**. Where
the flagship **"Endpoint Analytics Deployment & Optimization in Microsoft Intune"** solution (referred
to throughout as the **parent** product) covers turning Endpoint Analytics on, getting devices
reporting, and reading the startup-performance and productivity scores, **this** product goes deep on
three reliability signals and — most importantly — on **what to do with them**:

1. **Application reliability** — crashes and hangs broken down **by application and version**, so you
   can see which app (and which build of it) is failing on your fleet and how many users it affects.
2. **Device reliability & restart analytics** — restart causes and **unexpected-restart trends**, so a
   spike in reboots stops being a mystery and becomes an attributable event (an OS update, a driver, a
   bad configuration).
3. **Anomaly detection** — an early-warning signal that flags when a metric **regresses across a slice
   of the fleet** (a device model, an app version, an OS build), so a bad app rollout or a driver
   regression is caught while it's small instead of after it becomes a wave of tickets.

The heart of the product is not the reports themselves — it's the **triage-and-close-the-loop
practice** wrapped around them: how to read each signal, how to **separate a bad app from a bad
rollout**, how to route the problem to the responsible **app / driver / update owner**, and how to hand
a scriptable fix to the **"Proactive Remediations at Scale"** solution (referred to as the **automated-
fix companion**) so the loop actually closes.

> **Feature, licensing, and navigation accuracy.** Endpoint Analytics reliability reports and anomaly
> detection evolve, and some capabilities are in preview or vary by cloud. This guide describes the
> **concepts and the practice** with confidence, but flags every **exact blade name, navigation path,
> licensing requirement, and feature-availability claim** as **"verify against current Microsoft
> documentation"** — because Microsoft changes those. Never treat a flagged specific as settled without
> checking your own tenant.

## How it works
1. **Endpoint Analytics is already collecting data.** Enabling Endpoint Analytics, deploying the data-
   collection policy, and getting devices to report are covered by the **parent** product — this
   solution **assumes that groundwork is done** and starts from "the reliability data is flowing."
2. **Application reliability aggregates crash/hang telemetry by app + version.** Each managed app gets
   a reliability signal built from how often it crashes or hangs and how many devices/users that
   affects. A version dimension lets you see a specific build regress.
3. **Device reliability / restart analytics aggregates restart events.** Restarts are classified
   (planned vs. unexpected / stop-error) and trended over time so an abnormal rise is visible.
4. **Anomaly detection watches for regressions.** Rather than making you eyeball every chart, anomaly
   detection surfaces when a metric moves abnormally for a **cohort** — a hardware model, an app
   version, an OS build — which is exactly the shape of a bad rollout or a driver regression.
5. **You triage and route.** For each signal you decide: is this a **bad app** (fix or roll back the
   app/version) or a **bad rollout / environmental** cause (an update or driver hitting a device
   model)? Then you route it to the owner and, where the fix is scriptable, hand it to the
   **automated-fix companion**.
6. **A review cadence keeps it honest.** A short, repeatable **reliability review** turns these signals
   into a habit — the difference between "we have the data" and "we catch regressions early."

## The three signals, and how to read them

### Application reliability (bad app vs. bad rollout)
- **Bad app:** a single application (or a single **version** of it) shows elevated crashes/hangs across
  a broad, mixed population of devices — many models, many OS builds. The common factor is the *app*.
  → Fix, update, or roll back the **app/version**; route to the **app owner**.
- **Bad rollout:** crashes/hangs spike **right after** a new app version or configuration was deployed,
  concentrated in the population that received it. The common factor is the *change event*.
  → Pause/stage the rollout, roll back the version, route to the **deployment owner**.

### Device reliability & restart analytics
- **Unexpected-restart trend rising** across the fleet, or across a **single device model**, usually
  means an **update or driver** rather than an app. A model-scoped spike points at a **driver/firmware**
  regression on that hardware; a fleet-wide spike right after an OS update points at the **update**.
  → Route to the **hardware/driver owner** or the **update owner**; hand the mitigation (roll back a
  driver, block an update ring, apply a config) to the **automated-fix companion** where scriptable.

### Anomaly detection (catch the regression early)
- An anomaly is the system telling you **"this metric just moved abnormally for this cohort."** Read
  **which metric** (crashes, restarts, a specific reliability measure), **which cohort** (model / app
  version / OS build), and **when it started** — the start time almost always lines up with a change.
- **True signal vs. false signal:** a true anomaly correlates with a real change event and persists; a
  false signal is transient (a one-off, a reporting gap, a tiny cohort with high variance) and fades on
  the next data refresh. The practice below shows how to tell them apart before you spend effort.

## The triage-and-close-the-loop practice
This is the repeatable model the whole solution is built around:

> **Read the signal → classify (bad app vs. bad rollout vs. environmental) → confirm it's real (not a
> false anomaly) → route to the responsible owner → hand a scriptable fix to the automated-fix
> companion → verify the signal recovers → record it.**

Every step in the Implementation guide serves this loop, and the review cadence runs it on a schedule.

## Where this sits relative to the other Endpoint Analytics products
- **Parent — "Endpoint Analytics Deployment & Optimization in Microsoft Intune":** turns Endpoint
  Analytics on, deploys data collection, and covers startup performance and the productivity/score
  side. **Do that first.** This solution does **not** re-teach enabling Endpoint Analytics — it points
  you back to the parent for the groundwork and picks up at reading reliability data.
- **Automated-fix companion — "Proactive Remediations at Scale — Detection & Remediation Script Packs
  for Microsoft Intune":** where a reliability problem has a **scriptable** fix (clear a bad cache,
  reset a service, remove a bad driver, repair a config), this solution **hands the fix off** to the
  companion's detection/remediation script model rather than reproducing it here.

This product is deliberately scoped to the **reliability + anomaly deep-dive** and the triage practice
that connects the signals to those two neighbors.

## Benefits
- **Catch regressions early** — anomaly detection flags a bad rollout, a driver regression, or an
  update raising restarts **while it's small**, before it becomes a ticket wave.
- **Separate a bad app from a bad rollout** — a clear, repeatable classification so you fix the *right*
  thing instead of guessing.
- **Attributable restarts** — restart analytics turns "random reboots" into an owner and a cause.
- **Right fix, right owner** — every signal routes to the app/driver/update owner and, where
  scriptable, straight into the automated-fix companion.
- **A durable practice, not a one-off** — the review cadence makes reliability a standing habit, and
  the practice is reusable on every future rollout.

## Limitations (be honest with buyers)
- **Endpoint Analytics must already be enabled and collecting data** — this solution starts from data
  flowing; enabling it is the **parent** product's job.
- **Reliability data is aggregated and delayed** — signals populate over a period (often measured in
  days) and need a minimum device population before they're meaningful; brand-new tenants or tiny
  cohorts will look empty or noisy. *(Exact data-latency and minimum-device thresholds vary — verify
  against current Microsoft documentation.)*
- **Coverage is platform- and OS-dependent** — application reliability and restart analytics apply to
  the supported Windows client population; exact OS build and device-eligibility requirements **must be
  verified against current Microsoft documentation.**
- **Anomaly detection is an evolving capability** — availability, exact behavior, and whether it is in
  preview or GA **vary and must be verified against current Microsoft documentation**; treat its output
  as a lead to confirm, not a verdict.
- **This product interprets and routes — it does not deploy the fix.** The scriptable remediation lives
  in the automated-fix companion; the OS/driver/app change lives with its owner.
- **National-cloud differences** — Government (GCC / GCC High / DoD) portal URLs and feature parity can
  differ; where a step names a portal or a feature, **verify the Government equivalent against
  Microsoft's US-sovereign-cloud documentation.**

## The standard deployment model
This solution uses the same repeatable model as the rest of the catalog so repeat buyers recognize the
pattern:

> **Confirm reliability data is flowing → stand up a named review scope → read application reliability
> and separate bad-app from bad-rollout → read device reliability / restart analytics → use anomaly
> detection to catch a regression → triage and route (hand scriptable fixes to the automated-fix
> companion) → establish a review cadence — piloted on a small scope first, then expanded.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
