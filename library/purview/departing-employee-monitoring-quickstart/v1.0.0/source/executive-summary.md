# Executive Summary — Departing-Employee Data-Theft Monitoring Quickstart

## The problem

The single riskiest moment for your data is when an employee **decides to leave**. Between the
resignation and the last day, a departing user — with full, legitimate access — copies files to a USB
stick, syncs a folder to personal cloud storage, or emails a customer list to a private address. It
rarely looks like an attack, because it isn't one: it is someone who already has the keys, on the way
out. Studies consistently find that a large share of insider data loss clusters around departures — and
most organizations have **no visibility** into it until the person, and the data, are gone. Addressed
clumsily — with blanket employee surveillance — it costs something else: employee trust, and potentially
compliance with privacy and labour law.

## The solution

This is a **focused quickstart** that delivers the **one** Microsoft Purview capability built for exactly
this risk: a **Data theft by departing users** insider-risk policy — configured end to end, **the
responsible way**. It detects exit-time exfiltration from signals your Microsoft 365 tenant already
produces, and does so **with privacy guardrails and HR/legal in the loop**:

- **Privacy by design.** Usernames are **anonymized (pseudonymized)** for reviewers by default; identity
  is revealed only when justified, role-permitted, and **audited**. The policy is scoped to the
  **minimum** population — actual and imminent **leavers**, not the whole company.
- **Strict role separation.** The people who **build the policy** (Admins), **triage and investigate**
  (Analysts/Investigators), and **audit the reviewers** (Auditors) are deliberately kept separate, using
  purpose-built role groups — so no one both defines risk and unmasks identity unchecked.
- **Determinations stay with HR/legal.** The policy produces **evidence and an audited case trail**;
  whether an alert reflects misconduct, and what the consequence is, is an **HR/legal determination** —
  never a technical default and never the administrator's call.

The result is a governed, defensible monitoring capability: exit-time theft detected, triaged into cases,
evidence routed to the right people — **without overreach**.

## How it works

We follow a repeatable model — **Assess → Design → Configure → Pilot → Validate → Expand** — that
configures the **privacy and role-separation guardrails first**, then turns on the exfiltration
indicators, wires the **HR connector** (the leaver trigger that keeps the policy narrow), builds the one
policy from Microsoft's template, and validates it against a **sanctioned test** in a pilot scope before
anyone relies on alerts. Every high-impact change is piloted and reversible.

The solution ships as **self-guided documentation plus five PowerShell tools** (Security & Compliance
PowerShell / Graph) that assess role separation and privacy settings, check HR-connector and indicator
readiness, validate the policy prerequisites, produce a leadership rollup, and stage scope expansion —
all **read-only or preview-by-default**, with **no credentials in code**.

## Why it matters

- **Catch theft on the way out** — the highest-probability data-loss moment — instead of finding out
  after the person and the files are gone.
- **Respect privacy and the law** — anonymization, minimal (leaver-only) scope, and separated duties,
  engaged with HR/legal/privacy from the start.
- **Defensible evidence, clear ownership** — an audited alert→case trail, with the **determination in the
  right hands**.
- **A fast, focused win** — one capability, delivered and validated, at a fraction of consulting cost;
  a foundation you can later grow into a full insider-risk program.

## Important boundaries

Insider Risk Management is **licensing-dependent** (Microsoft 365 E5 / E5 Compliance / IRM add-on; some
capabilities are additional or in preview) and the Purview portal is **evolving** — capability
availability should be **verified against your licensing and tenant**. The policy **monitors people**: in
many jurisdictions this requires notice, consultation, or a specific **lawful basis** before it is
enabled — that applicability is a **legal determination** for your organization, and this solution
provides the technical method and guardrails, not the legal decision. Investigative and disciplinary
**outcomes remain with HR/legal**.
