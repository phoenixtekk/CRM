# 7. Best Practices — VPN Tunnel Health Monitoring & Alerting in Microsoft Intune (Scheduled Connectivity Health Checks, Telemetry & Alerts)

Field-proven guidance for running a proactive, endpoint-side VPN tunnel health-monitoring practice that
stays trustworthy — and stays **read-only**.

## Keep monitoring and fixing separate
- **The health check observes; it never acts.** The single most important rule: the detection health
  check is **read-only** — it must never restart, reconnect, renew, or re-push a VPN. A monitor that
  "fixes while it checks" hides the real failure rate and can cause harm at scale. Keep all fixes out of
  this package.
- **Deploy it as detection-only.** Package the health check as a Proactive Remediations **detection**
  with **no remediation script** attached. "With issue" here means *"investigate this device's tunnel"*,
  not *"a fix will run."*
- **Send fixes to the products that own them.** When a signal goes red, route to the deployment or
  troubleshooting product (Triage runbook) — never bolt a fix onto the monitor. If you genuinely want
  automated remediation of a detected condition, author it deliberately as its own Proactive Remediation
  with the safety discipline of the **"Proactive Remediations at Scale"** product.

## Define "healthy" well
- **Pick stable, representative probe targets.** The internal `$TestRouteTarget` and `$TestDnsName`
  should be things that are *supposed* to be reachable through the tunnel and are themselves reliable —
  a flaky test target produces false reds and alert fatigue.
- **Check each VPN type on its own terms.** Set `$VpnType` correctly; a Windows Always On **device**
  tunnel and **user** tunnel are separate connections and are monitored separately. For third-party
  clients, confirm the exact adapter/service name against the **vendor's** documentation.
- **Tune the cert-expiry window to your renewal lead time.** The default 30-day warning should be at
  least as long as it takes you to renew/re-provision a VPN certificate. If renewal is slow, widen the
  window so the alert gives you room.

## Deploy & scope
- **Pilot ring first, every time.** Assign the monitor to `PILOT – VPN Health – Devices` and prove it
  (healthy passes, seeded breaks go red) before production — no exceptions.
- **Seed real failures in the pilot.** Deliberately break the tunnel/route/DNS/cert on pilot devices so
  you prove each signal catches its condition, and keep a healthy device as the negative control.
- **Widen in waves.** Fill `VPN Health – Windows – Production` gradually. Because the check is read-only
  there is no risk to the tunnels, but waves keep the telemetry and alert signal clean and interpretable.
- **Keep pilot and production distinguishable.** Use `VPNHEALTH – Tunnel Health – Detect – Pilot` and
  `… – Production` so you always know which assignment a result came from.

## Telemetry & alerting
- **Verify the data path before trusting the dashboard.** Whether Proactive Remediations output is
  natively queryable in Log Analytics — and via which table — is **verify-with-Microsoft**; confirm your
  health data actually lands in `LA – Endpoint – VPNHealth` and use that real table name in the KQL.
- **Alert on cohorts, not single devices.** One device dropping its tunnel for a minute is noise; a
  *cohort* of devices on the same gateway failing to establish is a signal. Set `ALERT – VPN Tunnel
  Health – Degraded` thresholds so a cohort — or a cert-expiry window — triggers, not every transient.
- **Roll up by VPN type and gateway.** The `VPN Tunnel Health – Fleet Rollup` view by type and gateway
  is what turns "some devices are unhealthy" into "gateway X for VPN type Y is the problem" — which points
  triage straight at the layer.
- **Watch the trend, not just the moment.** Export `VPNHEALTH-Report.ps1` regularly; a rising
  Unhealthy/Degraded count for one VPN type or gateway is an early cohort signal.

## Operate & govern
- **Name everything by intent and reuse verbatim.** Reuse `VPNHEALTH – Tunnel Health – Detect – Pilot`,
  `PILOT – VPN Health – Devices`, `VPN Health – Windows – Production`, `LA – Endpoint – VPNHealth`,
  `ALERT – VPN Tunnel Health – Degraded`, and `VPN Tunnel Health – Fleet Rollup` across the console,
  scripts, testing, and troubleshooting so results are auditable.
- **Version the health-check script.** Keep `VPNHEALTH-Detect-TunnelHealth.ps1` under version control
  with a changelog, especially the configuration block (probe targets, cert match, window), so you know
  exactly what "healthy" meant at any point.
- **Re-verify vendor and Microsoft specifics periodically.** VPN client detection surfaces, Proactive
  Remediations behavior, Log Analytics data paths, and Azure Monitor wiring all drift — re-confirm the
  flagged items against current documentation on a schedule, not once.
- **Retire deliberately.** When a VPN technology is decommissioned, unassign and archive its monitor
  rather than leaving a stale check reporting on tunnels that no longer exist.
