# 7. Best Practices — Microsoft Tunnel Gateway: Deployment, VPN Configuration & Ongoing Operations

## Keep-it-clean guidance
- **Configure the control plane before you install the host.** Create the Site and Server
  Configuration first so the server joins a Site that already has routing waiting for it — cleaner than
  installing a server with nowhere to land.
- **Default to split tunnel.** Route only the internal include-route CIDRs through the Tunnel; let
  internet and SaaS traffic go direct. It lowers gateway load, improves user experience, and shrinks
  the blast radius. Reserve full tunnel for cases where policy genuinely requires all egress via
  corporate.
- **Do not overlap the client address pool with internal ranges.** The IP address range the gateway
  hands to clients must not collide with any include-route subnet, or routing breaks in confusing ways.
- **Treat the TLS certificate as a first-class operational asset.** Track its expiry, rotate it well
  before it lapses, and make sure clients trust the issuing chain (deploy the internal root via a
  Trusted certificate profile if you used an internal CA). An expired or untrusted cert is the single
  most common "everything suddenly broke" cause — monitor it (Test 2, and the health check script).
- **Deploy the Defender client app before the VPN profile.** The connection profile has nothing to
  drive if the client app is not yet installed on the device.
- **Pilot with report-only Conditional Access.** Never enforce "require compliant device" on the
  Tunnel before you have watched report-only results — a misconfigured CA policy locks out the very
  devices you are testing. Move to On only after report-only is clean.
- **Build high availability in deliberately.** Put two or more servers in one Site behind an **L4/TCP
  passthrough** load balancer (the gateway terminates TLS itself — never terminate TLS at the LB),
  point the Site FQDN at the VIP, and validate failover (Test 8) before you rely on it.
- **Upgrade with a rolling strategy.** Upgrade one server at a time so the Site stays up; if you enable
  automatic upgrades, set a maintenance window and confirm each server returns healthy afterward.
- **Monitor continuously, not reactively.** Watch server health (CPU, memory, latency, throughput,
  connection count) and certificate expiry in Intune and via `TUNGW-HealthCheck.sh`; the ops runbook in
  the Troubleshooting Guide turns these signals into actions.
- **Keep the naming convention.** `<Purpose> – <Scope> – <Stage>` across the Site, Server
  Configuration, profiles, CA policy, and groups keeps the deployment auditable and repeatable across
  waves.
- **Respect the version-drift flags.** Distros, container runtimes, ports, sizing, and the
  client-platform matrix change — re-verify the **[verify current Microsoft guidance]** items before
  each new rollout rather than trusting a stale value.

## Where to go next (adjacent catalog areas)
- **Unenrolled / BYOD app access?** Use the catalog's **"Microsoft Tunnel for MAM — Mobile Access to
  Intranet Resources"** (and its GCC High variant) — the app-level tunnel for unmanaged devices. This
  gateway solution is device-tunnel for enrolled devices; the MAM product covers the BYOD app case.
- **Certificate-based client authentication?** Pair this with the Intune **SCEP/PKCS certificate**
  solutions to issue client certificates and deploy the trusted root, then set the VPN profile to
  certificate auth.
- **Windows/macOS internal access where native Tunnel client support is unavailable?** Use the
  platform's supported native VPN / Always On VPN approach or an alternative access method for those
  endpoints, and revisit the **[verify current Microsoft guidance]** matrix periodically — do not force
  an unsupported Tunnel client.
- **Tightening device access?** Combine with the **Conditional Access**, **Device Compliance**, and
  **Defender for Endpoint** solutions to make "compliant + healthy device" the gate for the Tunnel.
- **Zero-touch onboarding of the client fleet?** Pair with the **Autopilot / enrollment** solutions so
  new devices arrive enrolled, Defender-equipped, and Tunnel-ready.
