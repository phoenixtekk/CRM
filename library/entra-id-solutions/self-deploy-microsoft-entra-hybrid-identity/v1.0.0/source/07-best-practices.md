# 7. Best Practices & Where to Go Next — Self-Deploy: Microsoft Entra Hybrid Identity

## Running the kit cleanly
- **Inspect, don't change.** This kit is read-only / inspection-first. Do not alter a production sync
  scope, source anchor, or authentication method while training — rehearse the pattern and execute for
  real in the **HYBID** implementation solution.
- **Break-glass first.** Confirm two excluded emergency-access accounts before you build even a
  report-only policy, and confirm they are excluded from every lab policy.
- **Pilot-scope any practice object.** If you create the `Hybrid Identity – Pilot – Lab` group and its
  report-only CA policy, scope only test users/devices, and tear them down when done.
- **Least-privilege reads.** Use a **Global Reader** operator and consent only to the read scopes the
  scripts request.
- **Use a lab forest for full hands-on.** A disposable AD forest + Entra Connect lets the team practice
  the AD-side labs (source anchor, sync scope) without any production risk.

## Hybrid-identity principles the team should carry forward
- **PHS as the resilient default and backup.** Prefer Password Hash Sync; keep it enabled as a backup
  even when PTA or federation is primary, so cloud sign-in survives an on-premises outage.
- **Modern source anchor.** Standardize on `ms-DS-ConsistencyGuid` to survive domain migrations and
  avoid duplicate/orphaned objects.
- **UPN hygiene is a prerequisite, not an afterthought.** Verified, routable UPNs before you sync;
  never `.local`.
- **Scope deliberately.** Sync only the OUs/domains you mean to; keep test and service objects out of
  the cloud.
- **Change auth methods with staged rollout.** Move a pilot group first, validate sign-in, then convert
  the domain — with a clear rollback point.
- **One active sync server; a staging server for failover.** Rehearse with staging mode before any real
  cutover (in HYBID).
- **Monitor continuously.** Run the health check on a cadence; last-sync time, sync errors, federated
  domains, and UPN issues are the early-warning signals.
- **Defer the decisions that are not yours.** Regulatory, records, legal, and data-classification
  determinations, and production change-approval sign-off, belong to the customer's compliance /
  security / operations functions — the kit supplies technical understanding and read-only tooling, not
  those decisions.

## Where to go next (adjacent catalog areas)
- **Production hybrid build-out** → *Hybrid Identity with AD & Entra Connect* (HYBID) — the
  implementation companion to this kit.
- **Source-anchor / duplicate-object remediation** → *Entra Connect source-anchor / ConsistencyGuid /
  domain consolidation*.
- **Cloud Sync provisioning problems** → *Entra Cloud Sync users-not-provisioning troubleshooting*.
- **Conditional Access baseline** → *Zero Trust Conditional Access baseline* (ENTZTCA) — for the CA side
  of hybrid CA.
- **The broader modernization journey** → *Self-Deploy — Identity Modernization with Entra*
  (EKIDMOD).
- **Governance & privileged access** → *Entra ID Governance — PIM & Access Reviews* (ENTPIM / ENTIGA).

Continue the enablement track with the other Entra self-deploys (Identity Fundamentals, MFA &
Conditional Access, Identity Modernization) to round out the team's coverage.
