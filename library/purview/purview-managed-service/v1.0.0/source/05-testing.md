# 5. Testing Guide — Microsoft Purview Managed Service

Run these gates after the operating model is configured and piloted on `Managed Service - Pilot Scope`
(Implementation Steps 3–4), and again when you expand to the full service scope. Each gate has an explicit
**pass/fail** signal. The service is largely **read-and-coordinate**; the gates confirm the cadence runs,
findings are triaged with severity and an owner, tuning is piloted safely in the owning capability, and
the SLOs are met. The **portal is authoritative**.

## Gate 1 — Monitoring baseline captured
**Do:** Run `OPSMANAGED-Discovery.ps1`; confirm `Managed Service – Monitoring Baseline` records DLP
policies + modes, labels + policies, retention, audit status, alert-policy presence, IRM presence/posture,
and role groups.
**Pass:** The baseline is complete and reconciles with a portal spot-check.
**Fail:** A surface is empty when the portal shows objects → a **read-access** finding; fix access and
re-baseline.

## Gate 2 — Capability-to-owner map complete
**Do:** Review `Managed Service – Capability Map`.
**Pass:** Every in-scope capability maps to its **owning solution** and a named owner; nothing the service
operates is unowned.
**Fail:** An operated capability has no owner → assign one before running the tuning cadence.

## Gate 3 — Cadence calendar and runbooks defined
**Do:** Review `Managed Service – Cadence Calendar` and `Managed Service – Run Book`.
**Pass:** Daily/weekly/monthly/quarterly cadences are defined, and the Alert Triage, DLP Tuning, Health
Monitoring, and New-Workload Onboarding runbooks exist with steps and a change/rollback discipline.
**Fail:** A cadence or runbook is missing → complete it before piloting.

## Gate 4 — Monitoring sweep returns actionable signals
**Do:** Run `OPSMANAGED-Monitor.ps1`.
**Pass:** Recent DLP/alert/activity is pulled into `Managed Service – Triage Queue` with severity and
workload; the audit log is confirmed on.
**Fail:** No signals when the portal shows activity → confirm audit is on and the read roles are present
(**verify in tenant**).

## Gate 5 — Triage assigns severity and an owner
**Do:** Review a cycle's `Managed Service – Triage Queue`.
**Pass:** Every item has a **severity** and is **routed to its owning capability** with an owner; High-
severity items are escalated per the path (Requirement 2.7).
**Fail:** An item lacks severity/owner, or a High item wasn't escalated → fix the triage runbook.

## Gate 6 — Tuning is piloted safely in the owning capability
**Do:** Exercise the **DLP Tuning** runbook on one low-risk item; confirm it was **piloted in
simulation/test in the owning DLP solution**, validated, recorded in `Managed Service – Tuning Log`, then
enforced under change control (or rolled back).
**Pass:** The change was piloted first, evidenced in the tuning log, and reversible — **no** high-impact
change was flipped on directly from the managed service.
**Fail:** A DLP/label/retention/insider-risk change was made without piloting in its owning capability →
stop; that belongs to the owning solution, piloted first.

## Gate 7 — Sensitive surfaces reported as posture only
**Do:** Review how insider-risk / communication-compliance surfaces appear in the baseline/report.
**Pass:** The service reports **presence + privacy posture only** — no case contents, no person's
identity.
**Fail:** Any case detail or identity beyond authorized role scope appears → stop; the review breached the
privacy boundary (Requirement 2.2).

## Gate 8 — SLOs met on the pilot
**Do:** Run `OPSMANAGED-Report.ps1`; compare against `Managed Service – SLO Targets`.
**Pass:** The pilot cycle met the SLO targets (e.g. High-severity items triaged within the target window;
monitoring ran on cadence).
**Fail:** An SLO was missed → adjust cadence/severity/capacity and re-pilot.

## Gate 9 — Service report reconciles and is owned
**Do:** Produce `Managed Service – Service Report`.
**Pass:** The report (health counts, activity/alert volume, SLO adherence, open backlog) reconciles with
the portal and lands with the named service owner/audience.
**Fail:** The rollup diverges from the portal, or has no audience → reconcile (portal is authoritative)
and route it.

## Gate 10 — Improvement loop closes
**Do:** Review `Managed Service – Improvement Backlog` across two cycles.
**Pass:** Findings become planned, owned backlog items; closed items drop off; a falling drift/open-item
trend is visible. Determination items remain pending their governance owner (expected).
**Fail:** Findings don't turn into owned work → fix the review cadence.

---
### Exit criteria (all must be true to call the service operational)
- [ ] Monitoring baseline captured and reconciled (Gate 1)
- [ ] Capability-to-owner map complete (Gate 2)
- [ ] Cadence calendar + runbooks defined (Gate 3)
- [ ] Monitoring sweep returns actionable signals (Gate 4)
- [ ] Triage assigns severity + owner; High items escalated (Gate 5)
- [ ] Tuning piloted safely in the owning capability (Gate 6)
- [ ] Sensitive surfaces reported posture only (Gate 7)
- [ ] SLOs met on the pilot (Gate 8)
- [ ] Service report reconciles and is owned (Gate 9)
- [ ] Improvement loop closes; determinations routed to governance (Gate 10)
