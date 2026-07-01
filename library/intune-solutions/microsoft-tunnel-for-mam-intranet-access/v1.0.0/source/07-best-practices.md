# 7. Best Practices — Microsoft Tunnel for MAM

- Pilot before you expand. Validate one managed app reaching one internal resource on
  `Tunnel MAM Users – Pilot – Ring1` before assigning `Tunnel MAM Users – Production – Broad` — the
  single most important practice.
- Prefer split tunneling. Route only the internal subnets the apps must reach; leave internet and
  Microsoft 365 traffic direct. It keeps performance high and exposure low.
- Get DNS right first. Most "the app connects but the page won't load" issues are DNS — make sure the
  server configuration's DNS servers and suffixes resolve the internal names from the gateway host.
- Match the certificate to the FQDN. The TLS certificate subject/SAN must match the public gateway
  FQDN and chain to a CA the devices trust; track its expiry and renew ahead of time.
- Keep the app list intentional. Only supported Tunnel-for-MAM apps can tunnel (Microsoft Edge and
  Intune App SDK / wrapped LOB apps); confirm each LOB app is SDK-enabled before adding it.
- Configure iOS and Android separately. The two platforms have distinct app-config and client
  requirements; test each on real devices, not just one.
- Name objects consistently. Use `<Purpose> – <Scope> – <Stage>` for every group, server config,
  site, and MAM config, and reuse the names verbatim — it makes audits and rollback obvious.
- Size and patch the host. Follow Microsoft's CPU/RAM/throughput sizing, keep the Linux host and
  container engine patched, and monitor the gateway container's resource use.
- Watch health continuously. Check Microsoft Tunnel Gateway → Health status and run
  `TUNMAM-Report.ps1` on a cadence; chase unhealthy servers before users notice.
- Keep a rollback ready. To revert, remove the broad group from the Tunnel (MAM) configurations
  rather than deleting the gateway — pilot stays working while you investigate.
- Document the design. Record the address pool, DNS servers, split routes, ports, site membership,
  and target FQDN for repeatability and audits.
