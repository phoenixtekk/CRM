# Executive Summary — Anomaly Detection & Application Reliability with Endpoint Analytics

Reliability problems hide in aggregate. One line-of-business app crashes on a few hundred devices; an
OS update quietly raises restart rates; a driver regresses on a single hardware model. None of it shows
up as a single dramatic outage — it shows up as a **slow rise in tickets** that nobody connects to a
cause until it's widespread. Microsoft Intune's **Endpoint Analytics** already surfaces these through
**application reliability**, **device reliability / restart analytics**, and **anomaly detection** — but
the signals only help if someone knows how to **read them and act**.

This solution operationalizes the reliability side of Endpoint Analytics:

- **Application reliability** → read crashes and hangs **by app and version**, and **separate a bad app
  from a bad rollout** so you fix the right thing.
- **Device reliability & restart analytics** → turn "random reboots" into an attributable cause — an OS
  update fleet-wide, a driver on one hardware model.
- **Anomaly detection** → catch a fleet-wide regression **early**, read what the anomaly is telling you,
  and rule out false signals before spending effort.
- **Triage and close the loop** → route each confirmed signal to the responsible app / driver / update
  owner, and hand scriptable fixes to the automated-fix companion — then verify the signal recovers.

It is deliberately scoped to the reliability + anomaly deep-dive and the triage practice that connects
it to its two neighbors: the **flagship Endpoint Analytics** solution as the **parent** (which enables
Endpoint Analytics and gets devices reporting) and **"Proactive Remediations at Scale"** as the
**automated-fix companion** (which ships the scriptable fix at scale). This product does not reproduce
either — it reads the signals and routes the work.

Built the standard repeatable way — **Assess → Configure → Pilot → Validate → Expand** — with exact,
click-by-click Endpoint Analytics steps (navigation flagged to verify against current Microsoft
documentation, because Microsoft changes it), five ready-to-run PowerShell scripts (Microsoft Graph;
read-only by default, with a single `-WhatIf`-gated state-changer), and testing/troubleshooting guides
with clear pass/fail gates.

**Outcome:** a reliability practice built on Endpoint Analytics that catches app crashes, restart
spikes, and fleet-wide anomalies early — and routes each to the right fix **before** it becomes a ticket
wave — run by your own team, without a consulting engagement.
