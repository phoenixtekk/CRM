# Executive Summary — Insider Risk Readiness Assessment (Microsoft Purview)

## The problem
Insider risk — data walking out with a departing employee, a disgruntled user exfiltrating records, a
security-policy violation on a managed device — is real, and **Microsoft Purview Insider Risk Management
(IRM)** is built to surface it. But IRM is the most **privacy- and HR-sensitive** capability in Purview: it
examines what named people do. Switched on carelessly — every indicator enabled, real usernames visible to
everyone, one over-broad policy scoped to the whole tenant on day one — it becomes an employee-surveillance
liability, a works-council/privacy problem, and a flood of un-triageable alerts that no one can lawfully act
on. The groundwork that makes IRM defensible — privacy posture, role separation, connectors, scope — is
exactly what teams skip in the rush to turn it on.

## The solution
An **Insider Risk Readiness Assessment**: the disciplined groundwork **before** IRM is deployed against any
named user, using only the Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph.
It confirms **licensing**; establishes **privacy-by-design** (anonymization **on** so triage is
pseudonymized, and only the **minimum** indicators enabled); stands up **strict role separation** — Insider
Risk Management **Admins**, **Analysts**, **Investigators**, and **Auditors** as **different people**, kept
separate from HR and Legal; prepares and health-checks the **connectors** (HR, Entra, DLP, Defender for
Endpoint) that feed the signals; and **scopes** narrowly — proving IRM has signal with a tenant **Analytics**
scan (aggregated, **anonymized**, **no policy**) before creating a single **disabled/minimal** readiness
policy against a small priority-user group. Everything is done in the **least-exposing mode first**. The
result: the capability is licensed, private, role-separated, connected, and scoped — proven ready and
defensible — **without ever running against an individual**.

## What it delivers
- A configured **privacy-by-design posture** — anonymization on, minimum indicators, documented and signed off
  by the privacy stakeholder.
- **Strict role separation** across Admins / Analysts / Investigators / Auditors, with the all-powerful
  super-group minimized and HR/Legal kept out of the de-anonymizing Investigator role.
- **Prepared, health-checked connectors** (HR / Entra / DLP / Defender) so the intended template has signal —
  and no unnecessary connector over-collecting.
- An **Analytics-first** validation (aggregated, anonymized insight, no named-user policy) and a **disabled/
  minimal** readiness policy scoped to a priority-user group you control.
- A **pseudonymized readiness scorecard** — counts and gate status, no personal data — to hand to HR, privacy,
  and legal, who own the decision to deploy.
- **Five PowerShell tools** (readiness discovery, scaffold config, validation, pseudonymized report, scope
  helper) — read-only or `-WhatIf` by default, no credentials in code, and honest about IRM's limited
  scriptable surface (they direct you to the portal for the portal-only steps rather than inventing a cmdlet).

## Business outcomes
- **IRM deployed responsibly, not recklessly** — privacy and role separation are in place *before* anyone is
  monitored, which is what makes the capability defensible to employees, privacy officers, and works councils.
- **Least-exposing by design** — analytics and pseudonymized data before policies; a disabled/minimal pilot
  before any expansion; nothing operating against an individual during the assessment.
- **Auditable readiness** — every gate (licensing, privacy, roles, connectors, scope) is validated with
  evidence, giving a defensible posture and a clean handoff.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
IRM is licensing-/plan-dependent — it typically requires **E5 / E5 Compliance / an Insider Risk Management
add-on** (verify your tenant) — and it is **largely portal-configured** with a limited PowerShell/Graph
surface, so the tooling reports what it can and directs you to the portal for the rest. This solution provides
the technical **readiness** and the evidence; the decision to **deploy** IRM, the **lawfulness of
monitoring** in your jurisdiction, whether to **open a case**, what a risk signal **means** for a person, and
any **HR/disciplinary/legal action** are **HR, privacy, and legal determinations**, captured alongside the
delivered evidence. The assessment operates against **no** individual.
