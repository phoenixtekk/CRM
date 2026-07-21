# 1. Solution Overview — Endpoint Analytics Deployment & Optimization in Microsoft Intune

## What this solution is
This solution turns on **Endpoint Analytics** — the **data plane Microsoft Intune uses to measure the
real endpoint experience** — and puts it to work end to end. Instead of learning about slow boots,
crashing apps, and struggling remote laptops only when the help desk gets buried, you get an
**objective, scored, benchmarked** view of how devices actually behave for the people using them, and
a **prioritized plan to improve it**.

Endpoint Analytics collects experience telemetry from your managed Windows devices, rolls it up into
a small set of **scores** (with the detailed **sub-signals** behind each), and compares those scores
against a **baseline** — your own historical baseline and the Microsoft-published "all organizations"
median. This package deploys that capability the standard, repeatable way — **Assess → Configure →
Pilot → Validate → Expand** — then teaches you to read each score, read the sub-signals under it, and
convert the worst offenders into a **remediation backlog** you can work down.

It delivers exactly what an endpoint team needs to run experience by data:

1. **Endpoint Analytics enabled** on the tenant, with a named **data-collection policy** assigned to a
   scoped device group so telemetry starts flowing.
2. **A baseline** — a pilot baseline first, then a fleet baseline — so every later number has
   something to be measured against.
3. **Every score interpreted** — Startup performance, Application + Device reliability, Work-From-
   Anywhere, and Resource performance — down to the sub-signals that explain *why* a score is low.
4. **A remediation backlog** — the low scores and their worst-contributing devices, apps, and drivers
   turned into a ranked, actionable list, plus a repeatable **review cadence** to keep improving.

## The four score areas (and what each measures)
Endpoint Analytics presents its data as a set of scores. Cover all four at a working level; the exact
score names, weightings, thresholds, and blades change over time, so treat the specifics as
**verify-against-current-Microsoft-documentation** and the concepts as durable.

- **Startup performance.** How long a device takes to become usable from power-on through to a
  responsive desktop — broken into phases (core boot, sign-in, and the time to a responsive desktop).
  The sub-signals point at what is slow: **Group Policy / configuration processing**, heavy **startup
  apps**, **disk type** (spinning vs. SSD), and outdated **drivers/firmware**. This is the flagship
  score most teams start with because slow logon is the most-felt pain.
- **Application reliability.** How reliably the apps people actually run stay up — surfacing apps with
  high **crash/hang rates**, the devices they crash on, and usage counts so you can tell a broadly
  painful app from a one-device fluke. *The deep reliability + anomaly analysis is the subject of the
  companion product — see "Where this fits" below.*
- **Work-From-Anywhere (WFA).** How ready your fleet is to be managed and secured from anywhere —
  a readiness roll-up over **cloud identity** (Entra-joined), **cloud management** (Intune/co-managed),
  **Windows edition/version currency**, **Autopilot** provisioning, and **TPM/hardware** readiness. It
  is less "how fast" and more "how modern and remote-ready."
- **Resource performance.** How hard devices are working — a spotlight on **CPU** and **RAM**
  pressure so you can spot under-spec'd or over-loaded machines that make the experience sluggish even
  when boot times look fine.

*Score names, exact sub-metrics, and thresholds evolve; confirm the current set in the Intune portal
and Microsoft documentation before quoting a specific number to stakeholders.*

## How baselining and benchmarking work
A raw score means little on its own — the value is in the comparison:

1. **Data collection starts the clock.** Once the data-collection policy is assigned and devices are
   reporting, Endpoint Analytics needs a **collection window** before scores populate (they do not
   appear instantly — see Troubleshooting). Confirm exact timing against current Microsoft docs.
2. **A baseline is captured.** Endpoint Analytics keeps a **baseline** you compare current scores
   against. You start with a **pilot baseline** (a small scoped group), then a **fleet baseline** once
   the whole managed estate is reporting. You can also compare against the **Microsoft-published
   "all organizations" median baseline** to see whether you are ahead of or behind the pack.
3. **Sub-signals explain the gap.** When a score sits below baseline, you drill into its sub-signals
   to find the *cause* — e.g. a low Startup score that is really a Group-Policy-processing problem, or
   a WFA score dragged down by devices still on a legacy Windows edition.
4. **Improvement is measured against the baseline.** After you act on the backlog, the score should
   move toward (and past) baseline — that delta is your proof the work paid off.

## The improvement loop
This is the operating rhythm the solution installs:

> **Baseline → interpret each score → drill to sub-signals → build a prioritized remediation backlog →
> remediate → re-measure against the baseline → repeat on a review cadence.**

Two of those steps have **dedicated companion products** so this flagship stays focused on deploying,
baselining, and interpreting rather than re-teaching the deep specialties:

## Where this fits — the Endpoint Analytics cluster (pointers, not repetition)
This is the **flagship** of a three-product Endpoint Analytics cluster. It covers all four scores at a
working level and hands off the two deep specialties to its siblings — **use those for depth; this
guide does not reproduce them**:

- **Proactive Remediations at Scale — Detection & Remediation Script Packs for Microsoft Intune (#2).**
  Endpoint Analytics surfaces *what* to fix; **Proactive Remediations** is the **engine that fixes it
  at scale** — authoring, packaging, scoping, and scheduling the detection/remediation script pairs
  that clear items off your backlog automatically. When this guide says "remediate the backlog item,"
  the *how* of building the script pack lives there.
- **Anomaly Detection & Application Reliability with Endpoint Analytics (#3).** This flagship reads the
  Application/Device reliability score at a working level; the **reliability and anomaly deep-dive**
  — interpreting crash/hang patterns, using anomaly detection to catch a bad app/update/driver rollout
  early, and running a reliability investigation to root cause — lives in that companion product.

Buy this one to **stand up, baseline, and operationalize** Endpoint Analytics; add #2 to **remediate
at scale** and #3 to **go deep on reliability and anomalies**.

## The standard deployment model
This solution uses **one** model so the process is repeatable across the catalog:

> **Enable Endpoint Analytics on the tenant, assign a named data-collection policy to a scoped pilot
> group, let devices report and establish a baseline, interpret each score and its sub-signals, turn
> the low scores into a prioritized remediation backlog, then expand from pilot to the whole fleet —
> improving on a review cadence.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**

## Benefits
- **Experience becomes measurable** — objective, scored, benchmarked numbers replace "it feels slow"
  and ticket volume as your signal.
- **You know *why*, not just *what*** — the sub-signals under each score point at the actual lever
  (policy, app, driver, disk, hardware, edition) so remediation is targeted.
- **A prioritized backlog, not a data dump** — the worst-scoring devices/apps/drivers become a ranked
  list your team can work down.
- **Proof of improvement** — every change is re-measured against the baseline, so you can show
  stakeholders the score moved.
- **Fleet-scale and repeatable** — assign the data-collection policy once to a group; add devices to
  the group and they start contributing. The same playbook runs on the next wave and the next project.
- **Composable with the cluster** — pairs with Proactive Remediations (#2) to fix at scale and with
  the reliability/anomaly deep-dive (#3) without re-buying overlapping content.

## Limitations (be honest with buyers)
- **Windows-focused.** Endpoint Analytics scores are centered on **managed Windows devices**; it is not
  a cross-platform experience score for iOS/Android/macOS. Confirm current platform support against
  Microsoft documentation.
- **Scores are not instant.** After you enable data collection there is a **collection window** before
  scores populate and a baseline forms — plan for it; don't declare failure on day one.
- **Licensing and feature availability can vary.** Endpoint Analytics availability and the specific
  features/scores you see depend on your licensing and tenant configuration — **verify against current
  Microsoft documentation** for your plan, and note that **national clouds (GCC, GCC High, DoD)** can
  differ in feature parity, rollout timing, and portal endpoints.
- **It measures and prioritizes; it does not fix by itself.** Turning a score up requires action —
  policy changes, driver updates, hardware refresh, or **Proactive Remediations (#2)** script packs.
  This product builds the backlog; remediation-at-scale is the sibling's job.
- **Data collection depends on connectivity and endpoints.** Devices must be able to reach the required
  Microsoft service endpoints to submit analytics data; blocked endpoints mean blank scores.
