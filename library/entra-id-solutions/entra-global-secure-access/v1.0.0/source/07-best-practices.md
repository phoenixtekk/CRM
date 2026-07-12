# 7. Best Practices — Entra Global Secure Access (Internet & Private Access)

## Rollout & change safety
- **Pilot-first, always.** Prove the four gates on `ENTGSA-Pilot` and a handful of devices before you
  touch the wider fleet. Traffic capture changes how a device reaches the network — a mis-scoped profile
  can break work for everyone at once.
- **Keep the VPN as a fallback** until each app's Private Access path is validated, then **retire the VPN
  route app-by-app**. A big-bang VPN cutover is the classic way to strand users.
- **Conditional Access in Report-only first.** Ship `ENTGSA – CA – *` policies as **report-only**, read
  the Insights, then enforce. Always **exclude break-glass** accounts from every GSA CA policy.
- **One change at a time.** Enable a profile, or publish an app, or tighten a filter — not all three in
  one window. When something breaks you want one variable to unwind.

## Private Access (ZTNA)
- **Publish the app, not the network.** Define tight **application segments** (specific FQDNs/IPs and
  ports) so users reach only what they need — that is the whole point of ZTNA over VPN. Never publish a
  whole subnet when a handful of hosts will do.
- **Two connectors per location.** Run connectors in pairs in a **connector group** for HA, positioned
  with clean internal line-of-sight and DNS to the apps they serve.
- **Get DNS right up front.** Most Private Access failures are name-resolution mismatches — plan
  **Private DNS / DNS suffixes** so clients resolve private FQDNs through GSA and connectors resolve them
  internally.
- **Assign by group, review access.** Assign published apps to groups (start with `ENTGSA-Pilot`), and
  fold private-app access into your **access reviews** so entitlement doesn't sprawl.

## Internet Access (SWG)
- **Filter minimally, then tighten.** Start `ENTGSA – WebFilter – Baseline` with a small, uncontroversial
  block set (malicious, adult) and add categories/FQDNs in **measured steps**, watching the logs for false
  blocks. Over-filtering on day one erodes trust fast.
- **Let policy follow identity.** Attach the security profile through **Conditional Access** so filtering
  can differ by user/role/risk — not a single flat policy for everyone.

## Conditional Access & CAE
- **Condition network access on identity + device.** Require **MFA** and (for managed fleets) **compliant
  device** for GSA traffic and published apps, so a stolen token from an unmanaged device gets nowhere.
- **Enable Continuous Access Evaluation** so revocation and risk changes cut access in near-real-time,
  not at the next token refresh.
- **Use compliant-network** (from the Microsoft profile) to require that M365 access comes **through** GSA.

## Logging & operations
- **Send traffic logs to Log Analytics** and keep them — they are your audit trail and incident-response
  surface. Run `ENTGSA-Report.ps1` regularly and review blocked/denied flows.
- **Watch connector health.** Schedule `ENTGSA-ConnectorHealth.ps1`; a silently dead connector looks like
  "the app is down" to users.
- **No secrets in automation.** Scripts authenticate interactively via `Connect-MgGraph` / `Connect-AzAccount`
  with least read scopes — never embed credentials or tokens.

## Where to go next (adjacent catalog areas)
- **Migrate & Protect Applications with Entra** — migrate app **authentication** (AD FS → Entra SSO) and
  publish on-prem **web** apps for browser SSO via Application Proxy. GSA Private Access publishes
  **network** access; that solution publishes **web SSO** — run both for full app coverage.
- **Zero Trust — Conditional Access Baseline** — the full CA policy set that this solution plugs GSA into.
- **Entra ID Governance — Access Reviews & Entitlement Management** — govern who is entitled to each
  published private app over time.
- **Microsoft Sentinel** solutions — build detections and hunting on the GSA traffic logs you just enabled.
