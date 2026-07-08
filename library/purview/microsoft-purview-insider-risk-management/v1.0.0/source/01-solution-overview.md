# Solution Overview — Microsoft Purview Insider Risk Management

## What this solution delivers

Most catastrophic data loss does not come from an outside attacker — it comes from **someone who
already has access**: an employee packing up their OneDrive on the way out the door, a well-meaning
person emailing a customer list to a personal account, or a user who keeps circumventing the controls
you put in place. **Microsoft Purview Insider Risk Management (IRM)** is the compliance-side capability
that detects these patterns from the signals your tenant already produces — and does it **with privacy
guardrails and HR/legal in the loop**, so you manage risk without turning the workplace into a
surveillance program.

This solution walks a competent-but-novice administrator through a **complete, repeatable IRM
deployment**:

1. **Configure the privacy-by-design guardrails and role separation first** — anonymization
   (pseudonymization) of usernames, and the strict split between the people who *build policies*
   (Admins), the people who *triage and investigate* (Analysts/Investigators), and the people who
   *audit the reviewers* (Auditors). This is deliberately **step one**, not an afterthought.
2. **Build policies from Microsoft's templates** — **Data theft by departing users**, **Data leaks**,
   and **Security policy violations** — naming every policy, indicator, and scope, and always
   **piloting in analytics/limited scope before you rely on alerts**.
3. **Wire the triggering events and connectors** — the **HR connector** (resignation / termination /
   job-level signals) and, where used, the **physical badging connector** — plus the **indicators**
   (Office, device/endpoint, cloud, Defender) that give a policy something to detect.
4. **Operate the alert → case workflow** — triage the alert queue, escalate real signals into
   **cases**, and hand **investigative and disciplinary outcomes to HR/legal**. IRM gives you the
   technical evidence and the audited workflow; **it does not make the employment decision**.

Together these turn a **blind spot** (no visibility into departing-user data theft, inadvertent
leaks, or repeat policy violations) into a **governed, defensible, privacy-respecting insider-risk
program** — proven in analytics and a pilot scope before it drives real cases.

## Insider Risk Management is HR/privacy-sensitive by design — read this first

IRM is not a normal Purview workload. It looks at **people's activity**, so it carries employee-privacy,
works-council, labour-law, and data-protection obligations that a DLP or retention project does not.
This solution is built around three non-negotiable principles, and every step reflects them:

- **Privacy by design.** IRM **anonymizes (pseudonymizes) usernames by default** in the analyst
  experience — reviewers see coded identifiers, not names, until there is a justified,
  role-gated, **audited** reason to reveal identity. You keep anonymization **on** unless HR/legal/privacy
  have explicitly agreed otherwise in writing. Scope policies to the **minimum** population needed.
- **Strict role separation.** The person who **defines** what counts as risky (Admin) must not be the
  same person who **decides who did it** (Investigator), and both are watched by an independent
  **Auditor**. Purview provides purpose-built role groups precisely so these duties can be separated —
  this solution configures them that way and treats any overlap as a finding.
- **Determinations belong to HR/legal.** IRM produces **signals, alerts, evidence, and an audited
  case trail**. Whether an alert reflects misconduct, and what the consequence is, is an
  **HR/legal/privacy determination** — never a technical default and never made by the administrator.
  The tooling stops at "here is the evidence, routed to the right reviewers"; the outcome is theirs.

> **Deploy this with your HR, legal, privacy, and (where applicable) works-council / employee-relations
> stakeholders — not around them.** Several regions require notice, consultation, or a lawful basis
> before monitoring employee activity. Confirm your obligations before you enable a single policy.
> This solution provides the technical method and the guardrails; the **applicability and lawful basis
> are a legal determination** (see `global-requirements-purview.md` §5).

## The IRM model — how the pieces fit

- **Policy templates** are Microsoft-provided starting points that pre-select the right detections for
  a scenario. The three this solution builds: **Data theft by departing users**, **Data leaks**, and
  **Security policy violations**. (Others exist — data leaks by priority/risky users, risky AI usage,
  risky browser usage, patient-data misuse, forensic evidence — noted where relevant; the three above
  are the core.)
- **Indicators** are the individual risky activities a policy can watch — e.g. downloading from
  SharePoint, copying files to USB or personal cloud, printing, emailing to an external/personal
  recipient, or a Defender for Endpoint alert. Indicators must be **turned on globally** before a
  policy can use them, and several (device/endpoint indicators, healthcare, physical) have their own
  prerequisites.
- **Triggering events** are what makes a user *in scope* for a policy's detection window. For **data
  theft by departing users** the trigger is a **resignation/termination date** (from the HR connector)
  or an **Entra account deletion**; for **data leaks** it is a **DLP policy match** (or exfiltration
  activity); for **security policy violations** it is a **Defender for Endpoint** alert. No trigger,
  no scoring.
- **Connectors** bring in signals Purview does not natively have: the **HR connector** (the leaver /
  job-change dates that drive departing-user policies) and the **physical badging connector**
  (badge-in/out, used to correlate after-hours or post-resignation building access). These are
  **CSV/API data connectors**, set up in the portal.
- **Risk scoring → alerts.** Scored activity that exceeds thresholds raises **alerts** in a queue,
  with a severity. **Analytics** (an opt-in, aggregate, no-policy scan) lets you see where risk
  concentrates **before** you commit to policies.
- **Alerts → cases.** An analyst **triages** each alert (confirm / dismiss / resolve). A confirmed,
  meaningful alert is escalated into a **case** — the investigation container with the user's scored
  activity, notes, and case actions (notify, escalate to eDiscovery / Communication Compliance,
  resolve). Cases are where **Investigators** work and where the **HR/legal hand-off** happens.

The design principle across all of it: **detect the minimum, reveal the minimum, and separate who
does what** — visibility with guardrails, not surveillance.

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (analytics / limited scope) → Validate → Expand (enforce).**

- **Assess** — confirm licensing (E5 / E5 Compliance / IRM add-on), the IRM role groups and their
  separation, portal access, the in-scope indicators/connectors, and **the HR/legal/privacy sign-off**.
- **Design** — agree the anonymization posture, the policy scope (which users), the templates, the
  indicators, and the triggers **with HR/legal**. Name every object.
- **Configure** — set global privacy + role separation **first**, turn on indicators, build the three
  policies from templates, wire the HR (and physical) connector.
- **Pilot** — run **Insider Risk analytics** and/or a **limited-scope** policy first; tune thresholds
  and exclusions before you rely on alerts.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — widen scope only after the gate passes and HR/legal confirm the workflow.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** + **Executive
  Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Graph): an IRM readiness +
  role-separation + privacy-settings **assessment**, a **policy-from-template configuration helper**,
  a **connector/indicator readiness checker**, an **alert/case rollup report**, and a **scope/config
  helper** — read-only or `-WhatIf` by default; **no credentials in code**.

> **Sources:** Microsoft Learn — *Insider risk management* (overview, settings, policies, policy
> templates, indicators, HR connector, analytics, alerts, cases, roles/permissions). Insider Risk
> Management is **licensing-dependent** (Microsoft 365 E5 / E5 Compliance / Insider Risk Management
> add-on; some capabilities are additional or in preview) and the portal is **evolving** — **verify
> capability availability against your licensing/tenant** rather than assuming.
