# Executive Summary — Microsoft Purview Health Check

## The problem

Microsoft Purview is not "set it and forget it." Over time, DLP policies get paused for an incident and
never re-enabled; sensitivity labels stop at the pilot group and never widen; a retention policy covers
email but nobody added SharePoint; the unified audit log is quietly off; role groups fill with people
who changed teams two reorganizations ago. None of this throws an error — it just **drifts**. The gap
becomes visible only during an audit, a data-subject request, or a breach — the moment it is most
expensive and least forgiving to discover.

## The solution

This solution is a **read-only health check** of your Microsoft Purview estate across three domains:

- **Policy health** — do the policies that should exist actually exist, and are they **enabled and
  healthy** — or **disabled**, **unhealthy**, or **stuck in test** long after the pilot ended (including
  whether the **unified audit log** is on)?
- **Coverage** — do those policies actually reach the **workloads in scope** (Exchange, SharePoint,
  OneDrive, Teams, endpoints) — or does "we have DLP" quietly mean "on email only"?
- **Roles** — are the compliance role groups administered at **least privilege**, with no **Global Admin
  sprawl**, no **single-point-of-failure**, and no **stale** members?

It produces a **health scorecard** (each check rated **Healthy → At Risk → Gap**), a **prioritized
remediation register** (every gap with a **severity** and a named **owner**), and a **remediation
roadmap** — without changing anything in the tenant.

## How it works

We follow a repeatable model — **Assess → Design → Configure → Pilot → Validate → Expand** — adapted for
a read-first assessment. We **read** the estate (nothing changes), **score** it against what the
organization *intended* to run, and **prioritize** the gaps by severity and owner. Fixes are then routed
to the capability solution that owns them (DLP, labels, retention, roles), where they are **piloted in
simulation/test/report-only** before enforcement. The **only** fix this solution applies directly is the
single safe, reversible one — **re-enabling the unified audit log** — and even that is offered as a
preview first and committed only on an explicit switch.

The solution ships as **self-guided documentation plus five PowerShell tools** (Security & Compliance
PowerShell / Exchange Online / Graph): an estate **inventory**, a **coverage + least-privilege role**
review, a **validation** checker, a **remediation-plan** generator, and a **scorecard** rollup — all
**read-only or `-WhatIf` by default**, with **no credentials in code**.

## Why it matters

- **Catch drift before an audit does** — find the disabled policy, the coverage blind spot, and the role
  sprawl on your schedule, not a regulator's.
- **Evidence, not opinion** — a scored, defensible picture of estate health and a register you can
  actually work down.
- **Prioritized and owned** — every gap has a severity and an owner, so the highest-risk items get fixed
  first instead of everything staying red.
- **Safe by design** — read-only, with high-impact fixes piloted in their owning solutions; the health
  check finds, it does not flip.
- **A fraction of consulting cost** — the same disciplined method a specialist would use, delivered as a
  repeatable, re-runnable check you can schedule.

## Important boundaries

The health check reports **technical** state and evidence — it does **not** make **records, retention-
schedule, legal-hold, or regulatory determinations**; those are **compliance / records / privacy /
legal** decisions, and such findings are flagged **"determination required"** and routed accordingly. On
**Insider Risk** and **Communication Compliance** it reports **posture only** (that the capability exists
and its privacy guardrails are on) — never case contents or any person's identity. Purview is
**licensing-dependent** (many advanced capabilities need Microsoft 365 E5 / E5 Compliance; some are in
preview) and the portal is **evolving** — a capability that is absent because it is **unlicensed** is a
licensing decision, not a drift gap, and capability availability and paths should be **verified against
your licensing and tenant**.
