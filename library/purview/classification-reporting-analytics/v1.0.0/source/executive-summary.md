# Executive Summary — Classification Reporting & Analytics (Microsoft Purview)

Leadership keeps asking two questions that most organizations cannot answer with evidence: **"What is
classified, where is it, and how much of our estate is covered?"** and **"What are people actually doing
with our sensitive and labeled content?"** Microsoft Purview already holds the answers in **Content
Explorer** and **Activity Explorer** — but only if the reporting surfaces are enabled, scoped to the
right people under least privilege, and read into repeatable dashboards. This solution is a repeatable,
self-guided implementation that stands that reporting up end to end, using only the Microsoft Purview
portal, Security & Compliance PowerShell, and Exchange Online PowerShell — no third-party tooling.

It is **read-and-report by design.** It does not decide your classification scheme, create sensitivity or
retention labels, or author DLP policy — those are separate Purview solutions, and where they carry
regulatory or records weight their determinations stay with compliance, records, privacy, and legal.
Here you make the *existing* classification signal **visible, measurable, and dashboard-ready**. The only
governed changes it makes — enabling unified audit log ingestion and granting the scoped viewer roles —
are **previewed with `-WhatIf` and applied only with `-Commit`** under change control, and piloted on a
small analyst subset before the full audience.

## What you get
- A plain-language **Solution Overview** of what the reporting delivers — the coverage view (Content
  Explorer) and the behavior/trend view (Activity Explorer) — with the availability/licensing caveat for
  these evolving, plan-gated surfaces, and the boundary between reporting and enforcement.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite — compliance
  licensing, the two least-privilege Content Explorer viewer role groups, a named analyst group with role
  separation, audit ingestion, the classification signal to report on, and a pilot scope + change control.
- An **Implementation Guide** of precise, ordered portal and PowerShell steps: baseline readiness, confirm
  the signal, design the analyst group and dashboard, enable audit + the scoped viewer roles (pilot
  first), open the explorers, produce the pilot reports, validate against pass/fail gates, expand to the
  full audience, and schedule the exports and health checks.
- **Five PowerShell scripts** — Discovery, Configure (audit + viewer roles, `-WhatIf`/`-Commit`),
  Validate, Report (coverage + activity CSV exports), and ScopeHealth — read-only or `-WhatIf` by default,
  with no credentials in code.
- **Testing and Troubleshooting** guides with explicit pass/fail gates, where an empty/baseline estate and
  audit-ingestion lag are treated as expected states, not failures.

## What this delivers
A **coverage report** of what carries each sensitivity label, retention label, sensitive information type,
and trainable classifier, and where; an **activity report** of label lifecycle, DLP matches, and egress
over a rolling window; **dashboards** (Excel or Power BI at the buyer's choice) fed by repeatable CSV
exports; and the **least-privilege, audited role model** underneath — every step read-only or previewed
before commit, changing no content.

## The deployment model
Assess → Design → Configure → Pilot (simulate/limited scope) → Validate → Expand — with explicit pass/fail
gates and a documented rollback (revoke the viewer role membership).

## Outcome
Classification made **visible, measurable, and defensible** in Microsoft Purview — coverage and activity
reported, dashboards standing, and access least-privilege and audited — so leadership can see what is
classified and where, and prove the classification program is working. Feature availability is flagged to
verify in your tenant; regulatory, records, and legal determinations arising from the reports remain with
your governance functions. This solution delivers the technical method and the evidence, not the ruling.
