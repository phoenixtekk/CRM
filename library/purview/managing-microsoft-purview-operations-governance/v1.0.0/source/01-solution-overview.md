# 1. Solution Overview — Managing Microsoft Purview Going Forward: Operations & Governance

## What this solution is
Turning Microsoft Purview *on* — labels, DLP, retention, insider risk, audit — is a project with an
end date. **Running** Purview is not: policies drift as the business changes, alerts pile up if nobody
triages them, Compliance Manager improvement actions stall, role memberships accrete, and the
dashboards that once proved the program was healthy go stale. This solution is the **operating model**
for a Purview program that is already implemented — a repeatable way to *manage it going forward* so it
stays effective, tuned, and defensible year over year. It provides a **policy lifecycle**
(design → simulate → enforce → review), a **Compliance Manager** improvement-action cadence, **alert
triage and reporting** across DLP / sensitivity labels / insider risk / audit, periodic **role and
access reviews**, a light-weight **change-control** discipline, and the **KPIs and dashboards** that
demonstrate program health — all driven from the Microsoft Purview portal, Security & Compliance
PowerShell (`Connect-IPPSSession`), and Microsoft Graph, with no third-party tooling.

This is deliberately **distinct from an implementation project**. It assumes the foundation exists
(the separate *Implementing Microsoft Purview — Foundation, Roles & Onboarding* solution builds that)
and answers the question every compliance owner faces after go-live: *how do we operate this?*

## Why this matters
- **Policies silently drift.** A DLP or auto-labeling policy left in **simulation/test** mode never
  enforces; one flipped to enforce without review can block business. Without a lifecycle and a review
  cadence, nobody can say *which* policies are actually protecting data today.
- **Alerts are worthless if not triaged.** DLP, insider-risk, and audit signals generate a stream of
  alerts; an unowned queue means real incidents sit unseen and false positives never get tuned out.
- **Compliance Manager score decays.** Improvement actions have owners and due dates; without a monthly
  cadence they lapse, your compliance score drops, and audits find gaps that were "assigned" but never done.
- **Roles accrete.** People change jobs, projects end, but Compliance Administrator / Insider Risk /
  eDiscovery memberships stay. Stale privilege is an audit finding and a real risk — periodic access
  review is the control.
- **Change without control is how you break production.** A well-meaning edit to a live retention or DLP
  policy, made off-hours with no record, is the classic Purview outage. Lightweight change control makes
  every change reviewed, reversible, and logged.
- **If you can't measure it, you can't defend it.** Regulators and leadership ask "is the program
  working?" KPIs — policies in enforce vs test, alert volume and triage time, improvement-action burn-down,
  privileged-role count — turn that from an opinion into evidence.

## How it works
1. **Baseline the estate.** `PURVOPS-Discovery.ps1` inventories every DLP, sensitivity-label,
   auto-labeling, and retention policy with its current **mode** (Enable / Test / Disable) and compares it
   to a saved baseline to surface **drift** — new, removed, or mode-changed policies since the last review.
2. **Run the policy lifecycle.** Every policy moves through **design → simulate/test → enforce → review**
   on a schedule. New and changed policies are always piloted in **simulation/test** first; enforcement is
   a reviewed, recorded promotion; each live policy is re-reviewed on a cadence and can be rolled back.
3. **Work the Compliance Manager cadence.** Improvement actions are pulled (exported from the Compliance
   Manager portal — no public API), tracked against owners and due dates, and burned down monthly, with the
   compliance score trend recorded as a KPI.
4. **Triage alerts and roll them up.** A daily triage owner works the alert queue across DLP, labels,
   insider risk, and audit; `PURVOPS-Report.ps1` produces a periodic **rollup** — volume by category,
   severity, and status — so tuning and reporting are data-driven.
5. **Review roles and access.** On a quarterly cadence, `PURVOPS-Validation.ps1` enumerates every Purview
   compliance role group and its members and compares them to an approved list, flagging additions,
   departures, and privileged accounts for attestation.
6. **Measure and prove health.** `PURVOPS-KpiReport.ps1` composes the **KPI dashboard** from live
   telemetry (policy-mode distribution, alert volume, label/DLP coverage) plus the Compliance Manager
   export, and a periodic **program-health review** walks the dashboard with stakeholders.
7. **Control every change.** `PURVOPS-Remediation.ps1` performs operational config changes (e.g. promoting
   a policy from test to enforce, or rolling it back) **`-WhatIf` by default**, only writing with an
   explicit `-Commit`, and stamps each change into the change record.

## The operating cadences (the heartbeat of the program)
| Cadence | Activity | Runbook |
|---|---|---|
| **Daily** | Alert triage — work the DLP / insider-risk / audit alert queue | RB-03 |
| **Weekly** | Policy-drift check + alert rollup review | RB-01, RB-03 |
| **Monthly** | Compliance Manager improvement-action burn-down; KPI dashboard refresh | RB-02, RB-05 |
| **Quarterly** | Role & access review; live-policy review pass | RB-04, RB-01 |
| **Annually** | Full program-health review; scope/coverage reassessment | RB-05 |

## What you can control
- Which policy families are in the review scope (DLP, sensitivity/auto-labeling, retention) and the review interval.
- The alert categories, severities, and SLAs that define the triage queue and its response times.
- The Compliance Manager improvement-action owners, due-date policy, and score target.
- The approved Purview role membership and the access-review interval (e.g. quarterly).
- The KPI set and thresholds that define "healthy," and who attends the program-health review.
- The change-control approval path and change window for live-policy edits.

## What stays with your governance functions (be explicit with buyers)
This solution delivers the **technical operating method and the evidence** — not the compliance
*determinations*. **Retention schedules, records file plans, legal holds, and insider-risk /
communication-compliance case actions and outcomes** remain with your compliance, records, privacy, HR,
and legal teams. Insider-risk and communication-compliance operations are HR/privacy-sensitive: this
model emphasizes **privacy-by-design, pseudonymization where the feature supports it, and strict role
separation** between who investigates and who administers. We give you the runbooks, cadences, reviews,
and dashboards; the regulatory and case decisions stay with the accountable owners.

## Licensing reality (verify for your tenant)
Purview capabilities are heavily **licensing- and plan-dependent** and the portal is **actively
evolving**. Advanced DLP, auto-labeling simulation, insider risk, communication compliance, Audit
(Premium), and DSPM generally require **Microsoft 365 E5** or the **E5 Compliance** add-on; some features
are in preview. Compliance Manager improvement-action detail and premium templates are also plan-gated,
and Compliance Manager has **no supported public API** — its data is exported from the portal. Every step
below is flagged where availability depends on licensing; **confirm capability and portal paths for your
own tenant** before relying on them.

## The standard operating model
> Baseline the estate → run the policy lifecycle (design → **simulate/test** → enforce → review) →
> work the Compliance Manager cadence → triage alerts and roll them up → review roles and access →
> measure and prove health → control every change. High-impact policy changes are **always piloted in
> simulation/test before enforcement**, and every change is reversible and recorded.
