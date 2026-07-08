# Solution Overview — Microsoft Purview Health Check

## What this solution delivers

Microsoft Purview is not a "set it and forget it" platform. DLP policies get paused for an incident
and never re-enabled; sensitivity labels stop at the pilot group and never widen; a retention policy
covers Exchange but nobody added SharePoint; the unified audit log is silently off; role groups
accumulate members who changed teams two reorganizations ago. None of this throws an error — it just
**drifts**, and the gap only becomes visible during an audit, a data-subject request, or a breach,
when it is far too late and far more expensive to fix.

This solution answers one question with **evidence**: **"Is our Microsoft Purview estate actually
healthy — configured to policy, covering what it should, and administered by the right people at
least privilege — or has it drifted?"** It is a **read-only health check** across three domains —
**Policy health, Coverage, and Roles** — that produces a **health scorecard**, a **prioritized
remediation register**, and a **remediation roadmap**, without changing anything in the tenant.

> **This is an *assessment*, not an implementation.** The health check **finds and prioritizes** the
> gaps; **closing** most of them is done through the matching capability solution (DLP, sensitivity
> labels, retention/records, insider risk, audit) under that solution's own pilot-in-simulation,
> validate, expand discipline. The one exception this solution will remediate directly is the single
> clearly-safe, reversible fix — **re-enabling the unified audit log** — and even that is offered
> `-WhatIf` first and only committed with an explicit switch. Everything else is a **planned**
> remediation routed to its owning capability and its stakeholders.

## The three health domains (the rubric)

Each check is scored **Healthy → At Risk → Gap** against named, evidenced criteria, and rolls up into
a per-domain and overall **health rating**.

1. **Policy health (P).** Do the Purview policies that should exist **exist, are they enabled, and are
   they healthy** — or are they **disabled**, in **error/unhealthy** state, or **stuck in
   simulation/test** long after the pilot should have ended? This covers **DLP** policies (mode +
   health), **sensitivity labels and label policies** (published, not orphaned), **retention /
   data-lifecycle** policies and labels, the **unified audit log** (on/off), and whether an
   **insider-risk** signal exists where the organization intends one.
2. **Coverage (C).** Do the policies that exist actually **reach the workloads and data in scope** —
   Exchange, SharePoint, OneDrive, Teams, and (for endpoint actions) **onboarded devices** — or are
   there **blind spots** where an in-scope workload has **no** DLP / retention / label coverage? This
   is where "we have DLP" quietly means "we have DLP on email only".
3. **Roles (R).** Are the Purview/compliance role groups administered at **least privilege** — with
   **no Global Administrator sprawl**, **no single-point-of-failure** role group (one member, no
   coverage), **no empty** role groups, and **no stale** members who no longer need access? Purview
   uses fine-grained role groups; drift here is a real, auditable risk.

## How it works (the assessment model)

The health check follows the standard Purview model, adapted for a read-first assessment:

1. **Assess (read-only).** Inventory the current state — DLP policies and their **mode**, sensitivity
   labels and label policies, retention/lifecycle policies and labels, unified-audit-log status,
   insider-risk policy presence, and compliance role-group membership — with the included **read-only**
   scripts. Nothing changes.
2. **Design (the scorecard).** Score each check against the rubric (**Healthy / At Risk / Gap**),
   record every gap in the **Remediation Register** with **severity** (High / Medium / Low) and an
   **owner**, and produce the overall **health rating** and remediation order.
3. **Remediate (plan first, simulation/test where it changes anything).** Generate the prioritized
   remediation plan (`-WhatIf` by default). Route each remediation to its **owning capability
   solution** (DLP, labels, retention, roles), where it is piloted in **simulation/test/report-only**
   before enforcement. The **only** fix this solution commits directly is **re-enabling the unified
   audit log** — offered `-WhatIf` first, committed only with an explicit switch, and trivially
   reversible.
4. **Validate.** Re-run the read-only validation gates to confirm each remediated item now reads
   **Healthy**, and re-score.
5. **Expand (operationalize).** Turn the health check into a **recurring** cadence so drift is caught
   early next time — the scripts are re-runnable read-only and produce a comparable scorecard each run.

## Important boundaries — read this first

- **Records, retention schedules, and legal/regulatory determinations are not ours to make.** The
  health check reports **technical** state (a retention policy exists / covers these workloads / is in
  this mode) and evidence. **Whether** a given retention schedule, records file plan, legal hold, or
  regulatory obligation is correct or complete is a **records / compliance / privacy / legal
  determination** — deferred to those functions (`global-requirements-purview.md` §5).
- **Insider Risk & Communication Compliance are HR/privacy-sensitive.** Where the health check reports
  on insider-risk configuration, it reports **presence and privacy posture** (e.g. anonymization on,
  role separation intact) only — never case contents, never a judgement about any person. Reviewing
  those surfaces respects **role separation** and **privacy-by-design**; outcomes are **HR/legal's**.
- **Remediation of DLP, labels, retention, and insider-risk is high-impact — pilot first.** This
  solution deliberately does **not** flip those into enforcement. It hands each gap to the owning
  capability solution, which pilots in **simulation/test/report-only**, validates, and only then
  enforces.
- **Purview is licensing-dependent and evolving.** Many checks (advanced DLP, auto-labeling, insider
  risk, Audit Premium, DSPM) require **Microsoft 365 E5 / E5 Compliance**; some capabilities are in
  preview and portal paths change. A capability that is **absent because it is unlicensed** is a
  **licensing** finding, not a drift finding — the health check flags the distinction and says
  **"verify against your licensing/tenant."**

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide (run the health check
  → score → build the register → remediate/validate), **Testing** (pass/fail gates), **Troubleshooting**,
  **Best Practices**, and a **Deliverables Summary** + **Executive Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Exchange Online / Graph): a **Discovery**
  inventory, a **Scope/health** coverage-and-role review, a **Validation** checker, a **Remediation**
  plan generator (`-WhatIf` first; commits only the safe audit-log re-enable), and a **Reporting**
  scorecard rollup — all **read-only or `-WhatIf` by default**, with **no credentials in code**.

> **Sources:** Microsoft Learn — *Data Loss Prevention* (policy modes/health, simulation), *Sensitivity
> labels & label policies*, *Data lifecycle management & records* (retention policies/labels),
> *Microsoft Purview Audit* (unified audit log status), *Insider Risk Management* (privacy/role
> separation), and *Permissions in the Microsoft Purview portal* (role groups). Purview is
> **licensing-dependent** (many advanced capabilities need Microsoft 365 E5 / E5 Compliance; some are
> in preview) and the portal is **evolving** — **verify capability availability and portal paths against
> your licensing/tenant** rather than assuming.
