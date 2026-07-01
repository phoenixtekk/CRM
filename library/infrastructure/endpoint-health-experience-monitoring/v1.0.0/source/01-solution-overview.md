# 1. Solution Overview — Endpoint Health & Digital Experience Monitoring

## What endpoint health and digital experience monitoring is
Digital experience monitoring (DEX) measures how technology actually *feels* to the people using it
— not just whether a server is up, but whether a laptop boots quickly, apps stay responsive, and
hardware is healthy. `Microsoft Intune Endpoint analytics` is the built-in DEX capability in Intune:
it collects telemetry from enrolled Windows devices and turns it into scores and recommendations for
startup performance, application reliability, work-from-anywhere readiness, and resource performance.
This solution stands that capability up end to end, and treats a dedicated DEX platform (such as
Nexthink or Tanium) as an optional path for organizations needing deeper telemetry.

## Why it matters
Reactive support is expensive and invisible until users complain. By the time a slow-booting laptop
or a crash-prone app generates a ticket, productivity is already lost. Endpoint analytics flips this:
degradations surface as falling scores and named recommendations *before* the call, so you fix the
trend instead of the symptom.

## How it works
1. You enable `Endpoint analytics` in the Intune admin center and choose the data sources (Intune
   enrolled devices, and optionally Configuration Manager devices).
2. Enrolled Windows devices send device-performance telemetry; Intune aggregates it into an
   **Endpoint analytics score** (0–100) with sub-scores.
3. `Startup performance` scores boot and sign-in time and breaks it down (core boot, group policy,
   sign-in) so you can see what is slow.
4. `Application reliability` scores app crashes and hangs per app and per device, surfacing the
   least reliable apps in your fleet.
5. `Work from anywhere` reports modern-management readiness (cloud identity, cloud management,
   Windows, and Autopilot eligibility).
6. `Resource performance` scores CPU and RAM (spike time) so you can spot under-resourced devices.
7. `Proactive remediations` run script packages (detection + remediation) on a schedule to fix
   common issues automatically and report on what they found.
8. A **baseline** lets you compare your scores against your own history or a tenant/industry median,
   so you measure improvement over time.

## What you can see and control
- The overall **Endpoint analytics score** and its startup, reliability, work-from-anywhere, and
  resource sub-scores, trended over time.
- Per-device and per-model breakdowns so you can target the worst offenders.
- The list of **model scores** to see whether a specific hardware model drags the fleet down.
- **Recommended software** and configuration changes Intune surfaces to raise the score.
- **Proactive remediation** packages (detect + fix) scoped to groups, with run history and output.
- A **baseline** you set once so every later report is measured against it.

## Where a dedicated DEX platform fits (optional)
Endpoint analytics covers the most valuable signals for most organizations at no extra cost. A
dedicated DEX platform (Nexthink, Tanium, or similar) adds deeper real-time telemetry, richer
sentiment/experience scoring, and broader OS coverage where that is required. This solution treats
such a platform as an **optional integration path**: decide whether you need it, license it, then
follow the **vendor's own documentation** to deploy its collector and dashboards. We do not
reproduce vendor-specific setup here — the repeatable core is Endpoint analytics.

## Limitations (be honest with buyers)
- Endpoint analytics primarily covers **Windows** enrolled (and Configuration Manager-attached)
  devices; macOS/mobile experience monitoring needs a dedicated DEX platform.
- Scores require a **data-collection period** — a fresh tenant shows limited data until devices have
  reported for several days (the baseline period).
- It measures **performance and reliability signals**, not deep root-cause forensics; complex issues
  may still need device logs.
- Some sub-scores depend on **diagnostic data** being enabled and devices checking in regularly.
- A dedicated DEX platform is a **separate licensed product** — its setup, cost, and capabilities are
  the vendor's, not part of this solution.

## Object naming convention (used throughout)
Every object you create is named `<Purpose> – <Scope> – <Stage>` so it is self-documenting and
repeatable. Examples reused verbatim later: `Endpoint Analytics – Pilot Devices – Monitoring`,
`Endpoint Analytics – All Windows – Monitoring`, `Proactive Remediation – Restart Stale Devices – Pilot`.

## The repeatable deployment model
> Enable Endpoint analytics → onboard devices and set a baseline → interpret scores → wire proactive
> remediations → pilot → validate → expand. The repeatable way: **Assess → Configure → Pilot →
> Validate → Expand.**
