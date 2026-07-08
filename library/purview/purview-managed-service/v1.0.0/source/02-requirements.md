# 2. Requirements Guide — Microsoft Purview Managed Service

Verify **every** requirement before standing up the operating model. Each entry: **Description · Why ·
Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md`
(licensing, least-privilege roles, S&C PowerShell/Graph toolchain, in-scope data, compliance/records/
privacy/legal stakeholders, and a pilot scope with change control) — this guide adds the **managed-
service-specific** prerequisites and does not repeat the six.

## 2.1 Microsoft 365 + Purview licensing for the capabilities being operated
**Description:** Licensing that covers the capabilities the service will run — labels + baseline DLP in
**E3 / Business Premium**; **advanced DLP/alerts, auto-labeling, insider risk, Audit Premium, premium
Compliance Manager reporting** in **E5 / E5 Compliance**.
**Why:** The service operates whatever the tenant is licensed for; monitoring/alerting depth is plan-
gated.
**Verify:** M365 admin center → **Billing → Licenses**; run `OPSMANAGED-Discovery.ps1` to see what the
tenant exposes. **Verify your licensing/tenant** — availability evolves.
**Implement:** Confirm the plan for each operated capability; where a capability is unlicensed, record it
as out of scope (a licensing decision), not a service gap.

## 2.2 Least-privilege operational roles with privacy role separation
**Description:** The **least-privilege roles** the service operators need to monitor, triage, and tune —
e.g. read roles for monitoring, **Compliance Administrator / DLP / Information Protection / Records
Management** for tuning within change control — with HR/privacy-sensitive roles (Insider Risk,
Communication Compliance) held by **separate** owners and used posture-only for monitoring.
**Why:** Purview uses fine-grained role groups; a managed service expects least privilege and separation
of duties, especially on HR/privacy-sensitive surfaces.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership and separation.
**Implement:** Assign least-privilege operational roles under change control; keep privacy-sensitive
roles separate; the service reads those surfaces as **posture only**.

## 2.3 A defined service scope and SLO/cadence targets
**Description:** An agreed **service scope** (which Purview capabilities and workloads the service
operates) and the **SLO / cadence targets** — what runs daily/weekly/monthly/quarterly, and the response
targets for triage (e.g. High-severity DLP alert triaged within N business hours).
**Why:** A managed service is only meaningful against a defined scope and measurable targets; without
them, "operated" can't be evidenced.
**Verify:** A one-page service definition lists the in-scope capabilities, the cadences, and the SLO
targets, signed off by the service owner.
**Implement:** Agree the scope, cadences, and SLOs with stakeholders before running the model.

## 2.4 The owning capability solutions identified (this service coordinates, not re-implements)
**Description:** Identification of the **capability solutions** that own each configuration the service
operates — DLP, sensitivity labels, retention/records, insider risk, audit, data governance, and the
health check — so tuning/remediation is **routed** to the owning solution (and piloted in simulation/test
there), not performed ad hoc here.
**Why:** The managed service **operates and coordinates**; the actual high-impact changes belong to the
owning capability, piloted first. Avoiding duplicate/conflicting changes is essential.
**Verify:** Each in-scope capability maps to its owning solution and a named owner.
**Implement:** Record the capability-to-owner map before running the tuning cadence.

## 2.5 Monitoring & alert configuration available
**Description:** The **alert / activity signals** the service watches — DLP alerts, alert policies,
**Activity explorer**, and the **unified audit log** — configured and readable so monitoring and triage
have data.
**Why:** Monitoring and triage read alert/activity/audit data; without it there is nothing to operate.
**Verify:** Purview → **Data Loss Prevention → Alerts** and **Audit** return data; alert policies exist;
run `OPSMANAGED-Monitor.ps1`.
**Implement:** Enable audit logging and configure the relevant alert policies (in their owning capability)
before running the monitoring cadence.

## 2.6 Change control and a rollback discipline for tuning
**Description:** A documented **change-control / rollback** process for any tuning the service coordinates
— switching a DLP policy from audit to enforce, adjusting a rule, turning auto-labeling out of
simulation, or enabling a policy — performed in the owning capability, piloted in simulation/test first.
**Why:** Operational tuning touches production, high-impact policies; every change needs an approver, a
pilot, and a rollback.
**Verify:** A change ticket template exists with approver, pilot scope, and rollback; the service records
each change in the tuning log.
**Implement:** Adopt the change process; run remediation `-WhatIf` first; make changes in the owning
capability under change control.

## 2.7 Stakeholder reporting and escalation path
**Description:** A named **service owner**, a **reporting audience** (compliance/security leadership), and
an **escalation path** for High-severity findings and determinations — so the service report lands with
someone and incidents/decisions are routed.
**Why:** A managed service that reports to nobody and can't escalate changes nothing; determinations must
reach the right governance function.
**Verify:** The service owner, report audience, escalation path, and the compliance/records/privacy/legal
routing for determinations are named.
**Implement:** Establish the reporting/escalation model before the first service review.

---
## Checklist
- [ ] M365 + Purview licensing for each operated capability (E3/Business Premium; **E5 / E5 Compliance** for advanced) — `OPSMANAGED-Discovery.ps1`
- [ ] Least-privilege operational roles + privacy role separation (posture-only on HR/privacy surfaces)
- [ ] Service scope + SLO/cadence targets defined and signed off
- [ ] Capability-to-owning-solution map (this service coordinates, not re-implements)
- [ ] Monitoring/alert/audit signals configured and readable — `OPSMANAGED-Monitor.ps1`
- [ ] Change control + rollback discipline for tuning (piloted in owning capability)
- [ ] Service owner, reporting audience, escalation path, and determination routing named
