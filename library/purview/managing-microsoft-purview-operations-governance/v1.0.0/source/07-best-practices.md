# 7. Best Practices — Managing Microsoft Purview: Operations & Governance

Field-tested practices for running Purview as an operated, measured program. They assume the operating
model in the Operating Guide is in place; the goal here is to keep it **effective, tuned, and defensible**
over time.

## Policy lifecycle & change control
- **Never edit a live enforcing policy without change control.** The classic Purview outage is a
  well-intentioned off-hours edit to a live DLP or retention policy. Every change: request → review →
  windowed change → recorded outcome → rollback plan. Use `PURVOPS-Remediation.ps1 -WhatIf` first, always.
- **Simulation/test before enforce — no exceptions.** New and changed DLP and auto-labeling policies run in
  `TestWithNotifications` / `TestWithoutNotifications` (auto-labeling simulation) until results are clean.
  Promotion to enforce is a reviewed, recorded event, not a default.
- **Re-baseline deliberately, not reflexively.** Only run `-SaveBaseline` after an *approved* change set, so
  the baseline always represents a known-good, attested state — otherwise drift detection normalizes away
  the very changes you want to catch.
- **Treat unexpected drift as an incident.** A policy that moved test → enforce, or enforce → disabled,
  without a matching change record is a control failure — investigate who/what/when before re-baselining.
- **Retire dead policies.** Disabled or superseded policies clutter the estate and confuse reviews; remove
  them through change control rather than leaving them "just in case."

## Alert triage & reporting
- **Own the queue or it owns you.** A named daily triage owner and a weekly rollup reviewer are the
  difference between a working control and a dashboard of ignored red. SLAs by severity make triage
  measurable.
- **Tune relentlessly.** The weekly rollup exists to find recurring false-positive sources; feed each one
  back into policy tuning (through RB-01 change control). A falling false-positive rate is a KPI, not a nicety.
- **Reconcile, don't trust blindly.** Periodically reconcile the scripted rollup against the Purview/Defender
  portal views for the same window; alerting surfaces and APIs evolve, and silent gaps are the worst kind.
- **Insider risk & communication compliance: role-separate and privacy-by-design.** Keep *administrators*
  (who configure policy) separate from *investigators/reviewers* (who see case content). Use
  pseudonymization where the feature supports it. Operations **triages and routes**; **case outcomes are
  HR/legal determinations** — never adjudicated by the ops function.

## Compliance Manager cadence
- **Improvement actions need owners and due dates, or they rot.** The monthly burn-down is where the
  compliance score is actually earned. Chase overdue actions; reassign when owners change.
- **Score is a trend, not a target to game.** Track the trajectory. A one-time spike from bulk-marking
  actions "implemented" without evidence is a finding waiting to happen — evidence each completion.
- **Remember the API gap.** Compliance Manager has **no supported public API**; the export is manual by
  design. Build the monthly export into the calendar so the KPI never goes stale silently.
- **Regulatory applicability is compliance's call.** The cadence evidences *technical* actions; *which*
  obligations apply, and the records/retention schedule behind them, remain with compliance, records, and legal.

## Role & access reviews
- **Quarterly, against an approved baseline, attested by the accountable owner.** A list of members is not a
  review; the diff against approved membership plus an attestation is.
- **Least privilege is a living state.** People change roles and projects end — memberships must follow.
  Flag and justify every account holding multiple sensitive role groups.
- **Preserve separation of duties.** Do not let the access-review process quietly re-merge administrator and
  investigator duties for HR/privacy-sensitive capabilities.

## KPIs & program health
- **Measure what proves the program works, not what's easy to count.** Good defaults: % policies enforced vs
  test, alert volume + mean triage time vs SLA, improvement-action burn-down, compliance-score trend,
  privileged-role count, policy-drift incidents. Each with a threshold and an owner.
- **A KPI without a forum is decoration.** The quarterly program-health review must *act* on the dashboard —
  decide tuning, scope, and remediation, and record the decisions.
- **Reassess scope annually.** New workloads, new regulations (flagged by compliance), and new Purview
  capabilities change what "healthy coverage" means — set next year's targets deliberately.

## Automation & safety
- **Read-only or `-WhatIf` by default; `-Commit` is the exception.** All five scripts lean read-only; the one
  that writes gates every change behind an explicit flag and a change record.
- **No secrets in code — ever.** Scripts use interactive modern-auth (`Connect-IPPSSession` /
  `Connect-MgGraph`) or a managed identity; never hardcode credentials, tokens, or app secrets.
- **Verify licensing and portal paths for *your* tenant.** Purview is heavily plan-gated and evolving —
  confirm each capability and path before relying on it, and flag "verify your licensing/tenant" in your own
  runbooks where availability is uncertain.
- **Schedule the read-only chain; keep writes human-gated.** Discovery, reporting, validation, and KPI runs
  can be scheduled; policy promotions and role removals stay behind change control and human approval.

## Operating discipline (the short version)
> Pilot before you enforce. Record before you change. Triage before it triages you. Attest before you
> assume. Measure before you claim. Re-baseline only what's approved.
