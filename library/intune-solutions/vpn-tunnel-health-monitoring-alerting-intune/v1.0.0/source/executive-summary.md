# Executive Summary — VPN Tunnel Health Monitoring & Alerting in Microsoft Intune (Scheduled Connectivity Health Checks, Telemetry & Alerts)

Most teams find out a VPN tunnel is unhealthy the same way every time: a wave of **"I can't connect"**
tickets. By then the outage is live — a client certificate expired overnight, a gateway stopped
answering, a routing change quietly broke traffic to the one subnet that mattered, or DNS stopped
resolving through the tunnel. There was **no proactive signal**.

This solution builds that signal. It turns VPN tunnel health into a **proactive, ongoing, fleet-wide
monitoring practice deployed through Microsoft Intune** — across **Microsoft Tunnel**, **Windows Always
On VPN** (device and user tunnel), and **third-party client VPNs** (e.g. Cisco Secure Client). It is the
**endpoint-side health-monitoring layer**:

- **Define "healthy"** → concrete, checkable signals with pass/fail thresholds: VPN adapter/profile
  present, tunnel established, gateway reachable, key routes and DNS resolving **through** the tunnel,
  and the auth certificate valid and **not near expiry**.
- **Deploy scheduled, read-only checks** → the health check ships as an Intune **Proactive Remediations
  detection** script that runs on a schedule and reports each device's tunnel health. It is **read-only
  by contract** — it never restarts, reconnects, renews, or re-pushes a tunnel. This is monitoring, not
  remediation.
- **Roll up into telemetry** → results feed Intune reporting and (where wired) a **Log Analytics**
  workspace, with **KQL** for a fleet health rollup by VPN type and gateway.
- **Alert on degradation** → an **Azure Monitor** alert turns a cert nearing expiry, a cohort failing to
  establish, or an unreachable gateway into a notification — **before** the ticket wave.
- **Triage to the fix** → a runbook maps each red signal to the responsible layer and **points to the
  product that owns the fix** — it never fixes the tunnel itself.

The boundaries are deliberate and explicit: this product **defers Microsoft Tunnel gateway-server health
to the "Microsoft Tunnel Gateway" product**, **defers VPN deployment to the deployment products**
(Microsoft Tunnel, Always On VPN, Cisco Secure Client), **defers reactive break/fix to the "Endpoint
Network Connectivity Troubleshooting Toolkit"**, and **uses the "Proactive Remediations at Scale"
detection model as its engine** without reproducing any of them.

Built the standard repeatable way — **Assess → Configure → Pilot → Validate → Expand** — with exact,
click-by-click Intune/Azure steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (a read-only device health check, three read-only
Graph tools, and one deploy script that defaults to `-WhatIf` and only ever deploys the monitoring
package), and testing/troubleshooting guides with clear pass/fail gates. Everything version- and
vendor-specific — Proactive Remediations behavior, Log Analytics data paths, Azure Monitor alert wiring,
per-vendor VPN detection, and national-cloud endpoints — is flagged **verify-with-Microsoft/vendor**.

**Outcome:** a proactive VPN tunnel health-monitoring practice run through Intune — scheduled checks,
fleet telemetry, and alerts that tell you a tunnel is failing **before your users do**, across whichever
VPN technologies you run — operated safely by your own team, without a consulting engagement.
