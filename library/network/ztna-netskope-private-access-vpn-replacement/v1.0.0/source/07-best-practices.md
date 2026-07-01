# 7. Best Practices — Zero Trust Network Access (ZTNA) with Netskope Private Access

- Publish the app, not the network. Map each private app to its exact host(s)/port(s) and grant that
  app alone — never a subnet. This per-app model is the whole point of ZTNA.
- Default-deny, then grant. Every user should reach only the apps an explicit policy grants; nothing
  is reachable by default. Audit for any over-broad rule that recreates VPN-style network access.
- Gate on identity and posture together. Bind each `Access Policy` to an Entra entitlement group and
  a device-posture condition (managed/compliant or certificate) so only healthy, known devices reach
  sensitive apps.
- Name everything `<Purpose> – <Scope> – <Stage>` and reuse the names verbatim — `Publisher – <Site> – Pilot`,
  `Private App – <App> – Pilot`, `Access Policy – <App or Role> – Pilot`, `Access Group – <App or Role> – Pilot`.
  Consistent names make access auditable and the rollout repeatable.
- Build the app inventory first. The number-one cause of broken cutovers is an app nobody published.
  Derive the inventory from VPN routes, DNS, and app owners before you publish.
- Coexist before you cut over. Run ZTNA and the VPN side by side so a failed app reach falls back to
  the VPN; never retire the VPN until the apps are proven.
- Pilot, gate, then expand in waves. Prove every entitled app on a small pilot, pass the gate, then
  widen entitlement in waves — assign once to a group, repeat everywhere.
- Keep a rollback ready. Access changes are disruptive; the fall-back is always "re-enable VPN and
  remove from the ZTNA `Access Group`" until the issue is fixed.
- Place publishers for performance and resilience. Put a `publisher` close to the apps in each
  segment and add a second per site before you cut over, so no single connector is a chokepoint.
- Report continuously. Run `NSZTNA-Report.ps1` on a schedule to audit who is entitled to what, verify
  posture, and catch any lingering VPN dependency after cutover.
- Defer console specifics to the vendor. Netskope screens and menus change; follow the named step and
  confirm the exact control in the official Netskope documentation and your tenant.
