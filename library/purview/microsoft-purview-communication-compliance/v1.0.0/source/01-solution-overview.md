# 1. Solution Overview — Microsoft Purview Communication Compliance

## What this solution is
Communication Compliance is the Microsoft Purview capability that detects **policy-violating
communications** — harassment and threats, regulatory breaches, and sensitive-data leaks — across
**Teams chats and channels, Exchange email, and connected channels** (Viva Engage and, where
licensed/configured, third-party sources such as Bloomberg, or data brought in via Microsoft 365
data connectors). It scans messages against **trainable classifiers and conditions**, raises the
matches as **alerts**, and routes them into a **reviewer workflow** where designated reviewers triage,
tag, escalate, or remediate — all under a **privacy-by-design, role-separated** control model built
*with* HR, privacy, and legal so oversight never becomes surveillance.

This solution is a repeatable, deploy-it-today way to stand Communication Compliance up correctly:
configure the privacy and role-separation guardrails **first**, build detection policies in a
**pilot/simulation** scope, wire the reviewer and remediation workflow, tune out the noise, and only
then expand. It uses only the **Microsoft Purview portal**, **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **Communication Compliance vs Insider Risk Management.** These two Purview capabilities are often
> confused. **Communication Compliance inspects the _content_ of communications** (what was said, in a
> message) for offensive, regulatory, or sensitive-data violations. **Insider Risk Management scores
> _risky activity/behaviour_** (exfiltration signals, downloads, departing-employee data movement) —
> not message content. They are complementary, licensed separately in places, and governed by
> different role groups. This solution is about **communication content**; risky-activity detection is
> a separate solution.

## Why this matters
- Regulated and sensitive workplaces have a **duty to monitor** certain communications (financial
  services conduct rules, harassment/anti-retaliation obligations, data-handling policy) — but doing
  it manually doesn't scale and doing it carelessly creates a **privacy and employee-trust liability**.
- The risk is bidirectional: **under-monitoring** misses harassment, leaks, and regulatory breaches;
  **over-monitoring** (broad scope, unrestricted reviewers, identifiable-by-default, no HR/legal gate)
  turns a compliance control into surveillance and can itself breach privacy law and works-council
  agreements.
- The value is in the **guardrails and the workflow**, not just the policy: who can see what,
  pseudonymization where required, a defensible reviewer trail, and remediation that is consistent and
  auditable. Detection without a governed workflow produces alerts nobody can responsibly act on.
- **Outcomes are an HR/legal determination, not a technical one.** This solution surfaces and evidences
  potential violations and provides the reviewer mechanics; **whether a message _is_ a violation and
  what happens to the person is decided by HR, privacy, and legal** — never by IT and never by the tool.

## How it works
1. **Privacy & role separation are configured first.** The Communication Compliance **role groups**
   (Admin, Analysts, Investigators, Viewers) are populated so that the people who *build* policies are
   separated from the people who *review* content and from the people who *investigate* escalations —
   agreed with HR/legal. Privacy controls (pseudonymized usernames where required, minimum in-scope
   population) are turned on before any policy runs.
2. **A policy defines the scope and the reviewers.** A Communication Compliance policy names the
   **users/groups whose communications are in scope** (the supervised population), the **reviewers** who
   will triage its alerts, and the **communication channels** it inspects (Teams, Exchange, Viva Engage,
   connected sources).
3. **Conditions and classifiers define what to detect.** Rules attach **trainable classifiers**
   (offensive language: threat, harassment, discrimination, profanity; regulatory: money-laundering,
   stock manipulation, unauthorized disclosure, gifts & entertainment; and others), **sensitive
   information types** (for data-leak detection), keywords, and conditions (direction, attachments,
   message size) — plus a **sampling percentage**.
4. **The policy runs first in a pilot/simulation scope.** It is built narrow, validated, and tuned
   before any broad rollout — matching the category's Assess → Design → Configure → **Pilot
   (simulate/test)** → Validate → Expand model. High-impact monitoring is never switched on tenant-wide
   blind.
5. **Matches become alerts in the reviewer workflow.** Reviewers open the policy's alerts in the
   Communication Compliance area of the Purview portal, examine the flagged message in context, and take
   a **remediation action**: resolve, tag, escalate (to an investigator/legal), notify the user, or
   create a case — with every action recorded.
6. **The trail is auditable and reportable.** Policy configuration and reviewer actions are logged; the
   solution's reporting rolls up policy/rule inventory, reviewer assignments, role-group membership
   (the separation evidence), and Communication Compliance activity for oversight.
7. **The population and policies are maintained.** Scope, reviewers, and conditions are reviewed on a
   cadence as the organization, regulations, and channels change.

## The detection dimensions (what a policy can look for)
- **Offensive language / conduct** — trainable classifiers for **threat, harassment, discrimination,
  profanity**, and adult/racy content, for harassment and hostile-workplace monitoring.
- **Regulatory / conduct-rule** — classifiers for **money-laundering, stock manipulation, unauthorized
  disclosure, regulatory collusion, gifts & entertainment**, and customizable keyword lexicons, for
  financial-services and regulated-industry obligations.
- **Sensitive-data leak** — **sensitive information types** and sensitivity-label conditions to catch
  regulated data (PII, PCI, health) leaving via message or attachment.
- **Conditions** — message **direction** (inbound/outbound/internal), **attachments**, size, domains,
  and a **sampling percentage** to control review volume.

## The role-separation model (configured with HR/legal)
| Role group | Who | Can |
|---|---|---|
| **Communication Compliance Admin** | Program owners / IT config | Create and configure policies; **not** intended to review message content day-to-day |
| **Communication Compliance Analysts** | Front-line reviewers (often HR/compliance) | Triage and act on alerts, see message content for their policies; **cannot** change policy or export |
| **Communication Compliance Investigators** | Escalation handlers (compliance/legal) | Everything Analysts can, plus access to more message context and case/eDiscovery escalation |
| **Communication Compliance Viewers** | Oversight | Read reports/dashboards; **no** access to message content |
> Separation is the point: the person who *builds* the net should not silently be the person who *reads*
> what it catches, and reviewers should be the agreed HR/compliance function — not IT. Membership is
> the auditable evidence that oversight is governed.

## What you can control
- The **supervised population** (in-scope users/groups) — kept as **narrow and justified** as the
  obligation requires, not "everyone".
- The **reviewers** for each policy and the **role-group membership** that enforces separation.
- The **channels** inspected (Teams, Exchange, Viva Engage, connected sources).
- The **classifiers, sensitive info types, keywords, and conditions**, and the **sampling percentage**.
- Whether usernames are **pseudonymized** in the review experience (privacy control).
- The **pilot scope** validated first, before any broad rollout.

## Limitations (be honest with buyers)
- **Heavily licensing-dependent.** Communication Compliance requires **Microsoft 365 E5 / E5 Compliance
  (or Insider Risk Management)** licensing; some classifiers/channels and connected sources have
  additional requirements or are in preview. **Verify availability against your licensing and tenant** —
  do not assume a classifier or channel is present.
- **Not a legal determination engine.** It surfaces candidate violations; **HR/privacy/legal decide**
  whether something is a violation and what the outcome is. The tool provides method and evidence only.
- **Privacy and works-council obligations are real.** In some jurisdictions monitoring communications
  requires employee notice, works-council/union agreement, or a documented lawful basis — **confirm the
  legal basis before enabling**. This solution enforces the technical guardrails; it does not replace
  that legal work.
- **Classifiers are probabilistic.** Trainable classifiers produce false positives/negatives; policies
  must be **tuned in a pilot** and reviewed. Sampling percentage trades coverage for review load.
- **Portal-driven review.** Reviewer triage and most remediation actions happen in the Purview portal;
  PowerShell/Graph configure and inventory policies but do not replace the human review experience.
- **No secrets in automation.** The provided scripts use interactive modern-auth sign-in; they never
  embed credentials.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Pilot detection policy (simulation) | `Comms Policy – Pilot – Simulation` |
| Broad detection policy (enforced) | `Comms Policy – Broad – Enforce` |
| Supervised in-scope population (pilot) | `Comms In-Scope – Pilot` |
| Supervised in-scope population (broad) | `Comms In-Scope – Broad` |
| Excluded / out-of-scope (privacy) group | `Comms Excluded – Privacy` |
| Reviewer assignment record | `Comms Reviewers – Pilot` |
| Alert/review rollup report | `Comms Review Rollup – Report` |
| Role-separation evidence snapshot | `Comms Role Separation – Evidence` |

## The standard deployment model
> Configure privacy + role separation → design the policy (scope, reviewers, classifiers/conditions) →
> build it in a **pilot/simulation** scope → validate detection, reviewer workflow, and privacy controls
> → tune → expand to the broad scope and stand up the maintenance cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** —
> outcomes deferred to HR/legal at every step.
