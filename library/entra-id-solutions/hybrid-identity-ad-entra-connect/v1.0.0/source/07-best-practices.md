# 7. Best Practices — Hybrid Identity with Active Directory & Microsoft Entra Connect

- Treat the identity plane as high risk. Rehearse every change in staging mode, validate on a pilot
  scope, and only then expand — this is the single most important practice.
- Keep break-glass accounts ready. Two cloud-only emergency admins, excluded from broad policies,
  before you touch sync, auth methods, or hybrid join.
- Prefer password hash sync. PHS is the simplest, most resilient method and keeps cloud sign-in
  working if the on-premises servers are down; keep it enabled as a backup even under PTA/federation.
- Fix UPN and domain hygiene first. A verified public routable domain and no duplicate
  UPN/proxyAddress values prevent the most common sync errors and broken sign-ins.
- Scope synchronization deliberately. Use OU/domain filters so test, service, and stale objects stay
  out of the cloud; name your scopes with the `<Purpose> - <Scope> - <Stage>` convention and reuse them.
- Run one active sync server, one in staging. The staging server is your rehearsal surface and your
  failover; never run two active exporters.
- Don't reach for federation by default. AD FS is a large ongoing commitment (certificates, a farm,
  its own outage surface); choose PHS or PTA unless a requirement forces federation.
- Monitor sync health continuously. Check `HYBID-Report.ps1` and the `Hybrid management` blade for
  errors and export latency; chase duplicate-attribute and large-delete safeguards promptly.
- Respect the export deletion threshold. Keep the accidental-deletion safeguard on so a bad filter
  change cannot mass-delete cloud objects; investigate before overriding it.
- Document the design. Record the auth method, sync scopes, writeback settings, and hybrid-join
  configuration for audits and repeatability.
