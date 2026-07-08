# 7. Best Practices — Microsoft Purview Managed Service

- **Operate, don't re-implement.** The managed service **runs** the capability solutions (DLP, labels,
  retention, insider risk, audit, governance, the health check) — it doesn't duplicate them. Keep a clean
  `Managed Service – Capability Map` so every change is routed to its owning solution and piloted there.
- **Baseline first, then watch for drift.** Capture `Managed Service – Monitoring Baseline` and score
  every monitoring sweep against it. Drift (a policy stuck in test, coverage decay, audit turned off) is
  what the service exists to catch early.
- **Define SLOs and cadences — and hold to them.** A managed service is only credible against measurable
  targets. Set `Managed Service – SLO Targets` and run the `Managed Service – Cadence Calendar` on
  schedule; a missed cadence is itself a finding.
- **Triage with severity and an owner.** Every item in `Managed Service – Triage Queue` gets a severity
  and a routed owner; High-severity items are escalated immediately. Findings without an owner rot.
- **Tune safely — pilot in the owning capability.** Never flip a high-impact change (DLP enforce, label/
  retention change, insider risk) directly from the managed service. Propose it, **pilot it in
  simulation/test in the owning solution**, validate, record it in `Managed Service – Tuning Log`, then
  enforce under change control — with a rollback.
- **Read-only by default; write under change control.** Monitoring and reporting are read-only; the only
  changes are safe, piloted, reversible, and logged. Run remediation `-WhatIf` first.
- **Respect the privacy line.** Report insider-risk / communication-compliance surfaces as **posture
  only** — presence and privacy guardrails, never case contents or a person's identity. Keep those roles
  separated.
- **Report to reconcile with the portal.** `Managed Service – Service Report` must match what the portal
  shows — the portal is authoritative. A regular, reconciled report is the assurance stakeholders buy.
- **Close the improvement loop.** Turn findings into planned, owned `Managed Service – Improvement
  Backlog` items; groom them each quarter. A falling drift/open-item trend is the proof the service works.
- **Route determinations to governance.** Records/retention/legal-hold/regulatory/insider-risk decisions
  go to compliance/records/privacy/legal — the service surfaces technical state and evidence, not the
  determination.
- **Onboard new workloads deliberately.** Use the New-Workload Onboarding runbook — extend coverage via
  the owning capability, then add the workload to the baseline so it's monitored from then on.
- **Verify licensing before promising a capability.** Advanced monitoring/alerting, insider risk, and
  premium reporting need E5 / E5 Compliance — **verify your licensing/tenant**; an unlicensed capability
  is out of scope, not a service gap.
