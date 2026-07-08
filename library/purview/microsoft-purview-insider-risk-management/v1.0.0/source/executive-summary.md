# Executive Summary — Microsoft Purview Insider Risk Management

## The problem

The most damaging data loss usually comes from **inside** — a departing employee taking files on their
way out, a well-meaning person leaking data by accident, or a user who repeatedly circumvents controls.
These events are hard to see because the people involved **already have legitimate access**. Left
unaddressed, they cost intellectual property, customer trust, and regulatory standing. Addressed
clumsily — with blanket employee surveillance — they cost something else: employee trust, and potentially
compliance with privacy and labour law.

## The solution

This solution implements **Microsoft Purview Insider Risk Management (IRM)** the responsible way. It
detects risky insider activity from signals your Microsoft 365 tenant already produces, using
Microsoft's policy templates — **Data theft by departing users**, **Data leaks**, and **Security policy
violations** — and it does so **with privacy guardrails and HR/legal in the loop**:

- **Privacy by design.** Usernames are **anonymized (pseudonymized)** for reviewers by default;
  identity is revealed only when justified, role-permitted, and **audited**. Policies are scoped to the
  **minimum** population needed.
- **Strict role separation.** The people who **build policies** (Admins), **triage and investigate**
  (Analysts/Investigators), and **audit the reviewers** (Auditors) are deliberately kept separate, using
  purpose-built role groups — so no one both defines risk and unmasks identity unchecked.
- **Determinations stay with HR/legal.** IRM produces **evidence and an audited case trail**; whether
  an alert reflects misconduct, and what the consequence is, is an **HR/legal determination** — never a
  technical default and never the administrator's call.

The result is a governed, defensible insider-risk program: detected, triaged into cases, evidence routed
to the right people — **without overreach**.

## How it works

We follow a repeatable model — **Assess → Design → Configure → Pilot → Validate → Expand** — that
configures the **privacy and role-separation guardrails first**, then turns on indicators, builds the
three policies from templates, wires the **HR connector** (the departing-user trigger) and, where used,
a **physical badging connector**, and runs **Insider Risk analytics** and a **pilot scope** before
anyone relies on alerts. Every high-impact change is piloted and reversible.

The solution ships as **self-guided documentation plus five PowerShell tools** (Security & Compliance
PowerShell / Graph) that assess role separation and privacy settings, validate policy prerequisites,
check connector/indicator readiness, produce a leadership rollup, and stage scope expansion — all
**read-only or preview-by-default**, with **no credentials in code**.

## Why it matters

- **See the inside threat** — departing-user theft, inadvertent leaks, repeat violations — instead of
  finding out after the damage is done.
- **Respect privacy and the law** — anonymization, minimal scope, and separated duties, engaged with
  HR/legal/privacy from the start.
- **Defensible evidence, clear ownership** — an audited alert→case trail, with the **determination in
  the right hands**.
- **A fraction of consulting cost** — the same disciplined method a specialist would use, delivered as
  a repeatable, tested runbook.

## Important boundaries

Insider Risk Management is **licensing-dependent** (Microsoft 365 E5 / E5 Compliance / IRM add-on; some
capabilities are additional or in preview) and the Purview portal is **evolving** — capability
availability should be **verified against your licensing and tenant**. IRM **monitors people**: in many
jurisdictions this requires notice, consultation, or a specific **lawful basis** before it is enabled —
that applicability is a **legal determination** for your organization, and this solution provides the
technical method and guardrails, not the legal decision. Investigative and disciplinary **outcomes
remain with HR/legal**.
