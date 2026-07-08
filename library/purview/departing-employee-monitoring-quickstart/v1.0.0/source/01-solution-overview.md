# Solution Overview — Departing-Employee Data-Theft Monitoring Quickstart (Microsoft Purview)

## What this solution delivers

The single riskiest moment for your data is when an employee **decides to leave**. Between the
resignation and the last day, a departing user — with full, legitimate access — copies files to a USB
stick, syncs a folder to personal OneDrive, or emails a customer list to a private address. It rarely
looks like an attack, because it isn't one: it is someone who already has the keys, on the way out the
door. Most organizations have **no visibility** into it until the person is gone.

This is a **focused quickstart**: it delivers the **one** Microsoft Purview capability that catches
exactly this — a **Data theft by departing users** insider-risk policy — end to end, without the scope
of a full insider-risk program. You get the departing-user policy, the **HR connector** that tells
Purview who is leaving (the trigger), and the **alert → case review flow** that routes evidence to the
right people — configured, **piloted in a limited scope** first, validated against pass/fail gates, and
operable.

It walks a competent-but-novice administrator through:

1. **Configure the privacy guardrails and role separation FIRST** — anonymization (pseudonymization) of
   usernames in the reviewer experience, and the split between who *builds* the policy (Admins), who
   *triages/investigates* (Analysts/Investigators), and who *audits the reviewers* (Auditors). This is
   deliberately step one, not an afterthought.
2. **Wire the trigger** — the **Microsoft 365 HR connector** that imports resignation/termination dates
   so Purview knows who is a leaver (or, with no HR feed, the **Entra account-deletion** trigger as a
   coarser fallback).
3. **Build the one policy** — `IRM-DepartingUser-DataTheft` from Microsoft's **Data theft by departing
   users** template, scoped to a named pilot group, with the exfiltration indicators it needs.
4. **Operate the review flow** — triage the alert queue, escalate a real signal into a **case**, and
   hand any investigative or disciplinary **outcome to HR/legal**. The tooling gives you the technical
   evidence and an audited trail; **it does not make the employment decision**.

The result: a **blind spot** (no visibility into exit-time data theft) becomes a **governed,
defensible, privacy-respecting monitoring capability** — proven in a pilot before it drives real cases.

## This is HR/privacy-sensitive by design — read this first

A departing-user policy watches **people's activity**, so it carries employee-privacy, works-council,
labour-law, and data-protection obligations that a DLP or retention project does not. Three
non-negotiable principles run through every step:

- **Privacy by design.** Insider Risk Management **anonymizes (pseudonymizes) usernames by default** in
  the reviewer experience — reviewers see coded identifiers, not names, until there is a justified,
  role-gated, **audited** reason to reveal identity. Keep anonymization **on** unless HR/legal/privacy
  have agreed otherwise **in writing**. Scope the policy to the **minimum** population needed — realistically,
  the pool of actual and imminent leavers, not the whole company.
- **Strict role separation.** The person who **defines** what counts as risky (Admin) must not be the
  same person who **decides who did it** (Investigator), and both are watched by an independent
  **Auditor**. Purview provides purpose-built role groups precisely so these duties can be separated —
  this solution configures them that way and treats any overlap as a finding.
- **Determinations belong to HR/legal.** The policy produces **signals, alerts, evidence, and an audited
  case trail**. Whether an alert reflects misconduct, and what the consequence is, is an
  **HR/legal/privacy determination** — never a technical default and never the administrator's call. The
  tooling stops at "here is the evidence, routed to the right reviewers"; the outcome is theirs.

> **Deploy this with your HR, legal, privacy, and (where applicable) works-council / employee-relations
> stakeholders — not around them.** Several regions require notice, consultation, or a lawful basis
> before monitoring employee activity. Confirm your obligations before you enable the policy. This
> solution provides the technical method and the guardrails; the **applicability and lawful basis are a
> legal determination** (see `global-requirements-purview.md` §5).

## How the pieces fit — the departing-user model

- **The policy template.** Microsoft's **Data theft by departing users** template pre-selects the
  detections that matter for a leaver: exfiltration to removable media, to personal cloud, by email to
  external/personal recipients, and downloads/prints of sensitive content. You build one policy from it:
  `IRM-DepartingUser-DataTheft`.
- **The trigger (why this template needs a connector).** Unlike a general data-leak policy, the
  departing-user template does **not** score everyone all the time. A user only comes **into scope for
  detection** once there is a **triggering event**: a **resignation/termination date** from the **HR
  connector**, or an **Entra account deletion**. No trigger, no scoring — which is exactly what keeps the
  policy narrow and privacy-respecting.
- **Indicators** are the individual risky activities the policy watches — SharePoint/OneDrive download,
  file copied to USB or personal cloud, file printed, email sent to an external/personal recipient.
  Indicators are a **global** switch (Settings → Policy indicators) that the policy draws from; several
  **device** indicators require **device onboarding** first.
- **The HR connector** brings in the signal Purview does not natively have — who is leaving and when. It
  is a **CSV/API data connector** configured in the portal; the upload credential lives in the connector
  app, **never in a script**.
- **Risk scoring → alerts.** A leaver's scored exfiltration activity that exceeds thresholds raises an
  **alert** in a queue, with a severity.
- **Alerts → cases → HR/legal.** An analyst **triages** each alert (confirm / dismiss). A confirmed,
  meaningful alert is escalated into a **case** — the container with the user's scored activity, notes,
  and case actions. Cases are where **Investigators** work and where the **HR/legal hand-off** happens.

The design principle throughout: **detect the minimum, reveal the minimum, and separate who does what** —
visibility with guardrails, not surveillance.

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (simulation/limited scope) → Validate → Expand.**

- **Assess** — confirm licensing (E5 / E5 Compliance / IRM add-on), the IRM role groups and their
  separation, portal access, the exfiltration indicators, the HR-connector feed, and **the HR/legal/
  privacy sign-off**.
- **Design** — agree the anonymization posture, the pilot scope, the indicators, and the trigger **with
  HR/legal**. Name every object.
- **Configure** — set privacy + role separation **first**, turn on the indicators, wire the HR
  connector, then build the one policy from the template.
- **Pilot** — scope the policy to a named pilot group and validate detection with a **sanctioned test**
  before you rely on alerts.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — widen scope deliberately (e.g. to the standing leaver population) only after the gate
  passes and HR/legal confirm the review flow.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting**, **Best Practices**, a **Deliverables Summary**, and an **Executive
  Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Graph): a role-separation + privacy
  **discovery** assessment, an **HR-connector / indicator readiness** checker, a **policy-from-template
  plan** helper, an **alert/case rollup** report, and a **scope helper** — all **read-only or `-WhatIf`
  by default**; **no credentials in code**.

> **Sources:** Microsoft Learn — *Insider risk management* (policy templates → *Data theft by departing
> users*, indicators, triggers, the *Microsoft 365 HR connector*, settings/privacy, roles/permissions,
> alerts and cases). Insider Risk Management is **licensing-dependent** (Microsoft 365 E5 / E5 Compliance
> / Insider Risk Management add-on; some capabilities are additional or in preview) and the Purview
> portal is **evolving** — **verify capability availability against your licensing/tenant** rather than
> assuming.
