# 1. Solution Overview — Proactive Remediations at Scale (Detection & Remediation Script Packs for Microsoft Intune)

## What this solution is
This solution turns Microsoft Intune's **Proactive Remediations** engine (part of **Endpoint
Analytics**) into a disciplined, fleet-wide **detect-and-fix practice**. Instead of fixing the same
recurring endpoint problem one help-desk ticket at a time — a stopped service, a drifted registry
value, a stale scheduled task, a missing setting — you deploy a **script pair**: a **detection**
script that runs on a schedule and decides *"is this device affected?"*, and a **remediation**
script that runs **only on the devices that are** to put them right. The result is reported back to
the console as a success/failure trend, so you can *prove* the fix landed and held.

The heart of this package is not just "how to click Create" — it is **how to author detect/remediate
PowerShell pairs that are safe to run unattended on thousands of machines**, and the **governance**
that keeps a reusable library of those pairs trustworthy over time. Automated remediation is
powerful; done carelessly it is an **auto-outage generator**. This solution goes deep on the safety
discipline — idempotent detection, minimal remediation, a **dry-run/preview default**, a strict
**exit-code contract**, correct **run context** (system vs. user), logging, rollback thinking, and
**pilot rings** — so the automation only ever helps.

> **Where this sits.** Proactive Remediations lives inside **Endpoint Analytics**. The companion
> solution **"Endpoint Analytics Deployment & Optimization in Microsoft Intune"** covers turning
> Endpoint Analytics *on* and reading its Startup / Reliability / Work-From-Anywhere scores — this
> package is the **remediation engine that plugs into it** and assumes Endpoint Analytics is already
> enabled. This document does **not** re-teach Endpoint Analytics onboarding; see that parent
> solution for it (referenced, not reproduced).

## How it works — the detect/remediate model
1. **You author two scripts.** A **detection** script inspects the device for one specific,
   well-defined condition and signals the result **only through its exit code** — a non-zero exit
   means *"issue found, run the remediation"*; an exit of zero means *"healthy, do nothing."*
2. **Intune runs detection on a schedule.** You package the pair as a **remediation** (the console
   object) and assign it to a group of devices with a recurrence (for example, once daily). The
   detection runs on every targeted device on that cadence.
3. **Remediation runs only where needed.** On any device whose detection exited non-zero, Intune
   runs the paired **remediation** script to apply the fix. Devices that were already healthy are
   never touched.
4. **Re-detection proves the fix.** On the next scheduled cycle, detection runs again; a device that
   was remediated should now report healthy, which is your evidence the fix worked and **held**.
5. **The console reports the trend.** Endpoint Analytics shows per-remediation columns —
   detection status, remediation status, and the scripts' output — aggregated across the fleet so
   you can watch "with issue" shrink toward zero.

## Why safety is the whole game
A detection script that runs read-only is low-risk. A **remediation** script *changes state on every
affected machine at once* — so a subtle bug doesn't cause one bad outcome, it causes **thousands,
simultaneously**. The discipline that prevents that is the core of this solution:

- **Idempotent detection** — detection must reach the *same* verdict every run and must not itself
  change the device. It only *observes* and reports via exit code.
- **Minimal remediation** — the fix changes the **smallest possible** thing to resolve exactly the
  detected condition, then stops. No "while I'm here" extras.
- **Dry-run / preview first** — a remediation is built and proven in a **preview mode** (it logs
  *what it would change* without changing it) before it is ever allowed to act. The included
  remediation **template defaults to a preview** for exactly this reason.
- **Exit-code contract** — detection uses `exit 0` (healthy) / `exit 1` (issue) and nothing else to
  communicate; remediation uses `exit 0` to report success. Misreading this contract is the most
  common cause of "it says failed but the device is fine" (and vice-versa).
- **Correct run context** — you choose whether the pair runs as **system** (machine-wide, no user
  needed) or in the **logged-on user's** context, because a script targeting the user hive run as
  system silently does nothing.
- **Pilot rings + rollback** — every pair is proven on a **small pilot ring** before it widens, and
  you keep the ability to unassign or reverse it. Nothing goes fleet-wide unproven.

## The governed script-pack library concept
Ad-hoc scripts pasted into the console rot: nobody knows which version is live, who approved it, or
what it does. This solution treats your detect/remediate pairs as **governed, reusable assets** — a
**script-pack library** with:
- **A naming convention** so every pack is identifiable at a glance (see Implementation).
- **Versioning** — each pack carries a version and a changelog, so you know exactly what is
  deployed.
- **Review & approval** — a remediation is reviewed by a second admin and proven in preview + pilot
  before it is approved to act in production.
- **Reuse** — a proven pack (e.g. "restart a stopped service", "correct a registry value") is kept
  and re-applied to the next recurring issue, so the practice compounds instead of restarting.

## The standard deployment model
This solution uses **one** repeatable model so the process is recognizable across the catalog:

> **Author an idempotent detection script and a minimal, preview-first remediation script; package
> them as a named Intune remediation; scope to a small pilot ring; schedule; read the detection and
> remediation status/output; then wave to production behind guardrails — and register every proven
> pair in a versioned, reviewed script-pack library.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**

## Benefits
- **Fix problems before users notice** — recurring issues are detected and remediated on a schedule,
  fleet-wide, instead of arriving as tickets.
- **Eliminate repetitive toil** — the same fix stops being a manual, per-device task; it becomes a
  script pack that runs itself.
- **Safe by construction** — idempotent detection, minimal preview-first remediation, exit-code
  discipline, and pilot rings keep auto-remediation from becoming auto-outage.
- **Provable outcomes** — re-detection and the console's success/failure trend give you evidence the
  fix worked and held, not just a hope.
- **A compounding asset** — a governed, versioned library of reusable packs means each solved problem
  makes the next one faster.
- **Plugs into Endpoint Analytics** — reuses the analytics surface you already enabled; the scores
  tell you *where* to point a remediation next.

## Limitations (be honest with buyers)
- **Licensing & availability gate the feature.** Proactive Remediations is part of Endpoint
  Analytics and requires specific licensing and enrollment prerequisites — **verify current
  licensing and feature availability against Microsoft's documentation** (Requirements §R1). It does
  not cover every platform.
- **Endpoint Analytics must be enabled first** — this package assumes the parent solution's
  onboarding is done; it does not re-do it.
- **Remediation power is a risk surface** — a poorly authored remediation can do harm at scale. The
  safety discipline in this guide is mandatory, not optional; it is not a substitute for reviewing
  your own scripts.
- **Scheduling is periodic, not instant** — detection runs on a recurrence, so remediation is
  "eventually", not real-time. Exact scheduling behavior and cadence limits should be **verified
  against current Microsoft documentation**.
- **Output visibility has limits** — the console captures script output within size limits and on a
  reporting delay; very large output is truncated (see Troubleshooting).
- **Not for app-install failures** — remediating failed application deployments is a different domain
  handled by a separate app-troubleshooting solution; this package is for endpoint state/config
  remediations, not app delivery.
