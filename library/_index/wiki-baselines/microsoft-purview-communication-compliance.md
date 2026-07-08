# Microsoft Purview Communication Compliance

> **Version 1.0.0** · Category: Purview · Solution code: PURVCC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview Communication Compliance

Regulated and sensitive workplaces have a duty to monitor certain communications — for harassment and
threats, regulatory and conduct-rule breaches, and sensitive-data leaks. But monitoring done carelessly
becomes surveillance: over-broad scope, unrestricted reviewers, identifiable-by-default content, and no
HR/legal gate can breach privacy law and destroy employee trust. Microsoft Purview **Communication
Compliance** provides the detection and reviewer mechanics; this solution provides the discipline to run
it **responsibly** — configuring the **privacy and role-separation guardrails first**, piloting in
simulation, and keeping every outcome an HR/legal decision.

This is a complete, deploy-it-today package for implementing Communication Compliance across **Teams,
Exchange, and connected channels**, written for a competent Microsoft 365 / compliance administrator,
and built to be run **with** the organization's HR, privacy, and legal functions.

## What you get
- A plain-language **Solution Overview** of Communication Compliance — the detection dimensions
  (offensive language, regulatory conduct, sensitive-data leak), the reviewer/remediation workflow, and
  the **role-separation model** — including the important distinction from **Insider Risk Management**
  (this inspects communication *content*; Insider Risk scores risky *activity*).
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite: E5 / E5 Compliance
  licensing, the separated role groups, named HR/privacy/legal owners and a **lawful basis**, the
  privacy/pseudonymization decision, in-scope channels, and the classifiers.
- An **Implementation Guide** that configures the guardrails first, then builds a policy in a
  **pilot/simulation** scope, wires the reviewer and remediation workflow, validates, tunes, and expands
  — with pass/fail gates and rollback at every step.
- **Five PowerShell tools** (Security & Compliance PowerShell / Graph): readiness + role-separation +
  privacy assessment, a policy/classifier config helper, a reviewer-workflow/remediation setup helper, an
  alert/review rollup report, and a scope helper — **read-only or `-WhatIf` by default, no secrets**.
- **Testing** and **Best Practices** that prove separation, privacy, detection accuracy, and the
  reviewer workflow before anything goes broad.

## Why it matters
- **Both failure modes are expensive.** Under-monitoring misses harassment, leaks, and regulatory
  breaches; over-monitoring is itself a privacy and trust breach. The guardrails in this solution close
  both.
- **The value is the governance, not just the detection.** Role separation, minimized scope,
  pseudonymization, and an auditable reviewer trail are what make monitoring defensible — and this
  solution stands them up first.
- **Outcomes stay with HR/legal.** The tool surfaces and evidences candidate violations and routes them;
  whether something is a violation, and what happens to the person, is decided by HR, privacy, and legal
  — never by IT and never by the tool.
- **Pilot-first, always.** Monitoring is high-impact; the solution validates in simulation on a minimal,
  approved population before any broad rollout.

## The bottom line
Communication risk surfaced **responsibly** — policies tuned to real violations, reviewers actioning a
sustainable queue, privacy and role separation enforced and evidenced — **oversight without
surveillance, with HR, privacy, and legal in control.** A fraction of the cost of a consulting
engagement, self-guided and tested.

*Communication Compliance is licensing-dependent (Microsoft 365 E5 / E5 Compliance / Insider Risk
Management) and the Purview portal evolves; verify capability availability and portal paths against your
own licensing and tenant. Regulatory applicability and any employment/regulatory outcome are deferred to
your compliance, privacy, and legal functions.*


---


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


---


# 2. Requirements Guide — Microsoft Purview Communication Compliance

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the
PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a pilot
scope with change control) are in `global-requirements-purview.md` — this guide adds the
Communication-Compliance-specific detail. **Licensing and portal paths are plan-dependent and the
portal evolves — verify each against your own licensing and tenant.**

## 2.1 Microsoft 365 E5 / E5 Compliance licensing for Communication Compliance
**Description:** Communication Compliance requires **Microsoft 365 E5**, the **E5 Compliance** add-on,
or an equivalent (e.g. **Insider Risk Management** / Microsoft 365 E5 Insider Risk Management) SKU that
includes it. Some classifiers, connected sources, and channels have additional or preview requirements.
**Why:** The capability and its classifiers will not appear (or will be limited) without the entitling
plan; this is the most common blocker.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` shows the E5 / E5 Compliance / Insider
Risk entitlement; the **Communication Compliance** area is visible in the Purview portal
(`https://purview.microsoft.com`). Run `PURVCC-Discovery.ps1`, which reports the readiness signals it
can see. **Confirm exact entitlement with Microsoft licensing — do not assume.**
**Implement:** Assign/purchase the required licensing before starting; re-check the portal.

## 2.2 Communication Compliance role groups populated with SEPARATION (with HR/legal)
**Description:** The four built-in role groups — **Communication Compliance Admin**,
**Communication Compliance Analysts**, **Communication Compliance Investigators**, and
**Communication Compliance Viewers** — populated so **policy-builders are separated from
content-reviewers from escalation-investigators**, agreed with HR, privacy, and legal. (There is also a
combined **Communication Compliance** role group that grants all of the above — avoid it for anything
but a tiny pilot precisely because it collapses the separation.)
**Why:** Role separation is the core privacy guardrail and the auditable evidence that oversight is
governed. Reviewers should be the agreed HR/compliance function, not whoever configured the policy.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` (or
`Get-RoleGroupMember 'Communication Compliance Analysts'` etc. via `Connect-IPPSSession`) shows the
intended, separated membership. `PURVCC-Discovery.ps1` prints the membership of each group as the
separation snapshot.
**Implement:** With HR/legal, decide who occupies each group; assign membership under change control;
**do not** place the same person in Admin *and* Analysts/Investigators unless HR/legal explicitly
accept it for a stated reason.

## 2.3 Named HR / privacy / legal stakeholders and a documented lawful basis
**Description:** Named owners in **HR, privacy, and legal** who approve the monitoring, the
**supervised population**, the reviewers, and the **lawful basis / notice / works-council agreement**
required in your jurisdiction(s).
**Why:** Monitoring communications is privacy-sensitive and, in some jurisdictions, requires employee
notice, works-council/union agreement, or a documented lawful basis **before** it is enabled. Outcomes
of any alert are an HR/legal determination.
**Verify:** Written approval of scope + reviewers + lawful basis on file; named approvers recorded.
**Implement:** Engage HR/privacy/legal, capture the lawful basis and notice obligations, and get scope +
reviewer sign-off before configuring. This is a gating prerequisite, not a formality.

## 2.4 Privacy controls decision (pseudonymization / minimum scope)
**Description:** A decision, with privacy, on the **privacy settings** for the review experience — in
particular whether **usernames are pseudonymized/anonymized** in Communication Compliance, and the
principle that the **in-scope population is the minimum the obligation requires**, not "everyone".
**Why:** Pseudonymization and minimized scope are data-minimization controls that reduce the privacy
footprint of monitoring; several regimes expect them.
**Verify:** Purview portal → `Settings → Communication Compliance` (Privacy) reflects the agreed
setting; the supervised population matches the approved scope. `PURVCC-Discovery.ps1` reports the
current privacy/scope signals it can read and flags an over-broad scope.
**Implement:** Set the agreed privacy option; scope policies to the approved population and an
**exclusion group** (`Comms Excluded – Privacy`) for anyone who must not be monitored.

## 2.5 In-scope communication channels enabled and connected
**Description:** The **channels** to inspect — **Teams** chats/channels, **Exchange** email, **Viva
Engage** — and any **connected sources** (third-party data brought in via Microsoft 365 data
connectors, e.g. Bloomberg, Instant Bloomberg) that are in scope and licensed.
**Why:** A policy only inspects the channels it covers and only what has been ingested; connected
sources require their connector to be configured first.
**Verify:** Confirm Teams/Exchange/Viva Engage are in use; for connected sources, the relevant **data
connector** is configured in the Purview portal and ingesting. **Connector availability and licensing
vary — verify against your tenant.**
**Implement:** Enable/confirm the native channels; stand up any required data connector before scoping a
policy to that source.

## 2.6 Trainable classifiers, sensitive info types, and keyword lexicons identified
**Description:** The **detection content** the policy will use — the built-in **trainable classifiers**
(offensive: threat, harassment, discrimination, profanity, adult/racy; regulatory: money-laundering,
stock manipulation, unauthorized disclosure, regulatory collusion, gifts & entertainment), the
**sensitive information types** for data-leak detection, and any **custom keyword dictionaries** the
compliance function requires.
**Why:** These are what the policy actually detects; the wrong or unavailable classifier means no (or
wrong) detections. Classifier availability is plan/tenant-dependent.
**Verify:** Purview portal → `Data classification → Classifiers` (trainable classifiers) and
`→ Sensitive info types` show the intended items as available. **Verify each is present in your
tenant** before relying on it.
**Implement:** Confirm the required classifiers/SITs exist; where a custom lexicon is needed, create the
**keyword dictionary** with the compliance function's approved terms.

## 2.7 Security & Compliance PowerShell (Connect-IPPSSession)
**Description:** A workstation with the **ExchangeOnlineManagement** module (providing
`Connect-IPPSSession`) and, for Graph-based reporting, **Microsoft Graph PowerShell**, used with a
modern-auth / MFA-capable admin that holds the appropriate Communication Compliance role.
**Why:** All five provided scripts run through Security & Compliance PowerShell and/or Graph; the
`SupervisoryReview*` cmdlets that back Communication Compliance are only available after
`Connect-IPPSSession`.
**Verify:** `Connect-IPPSSession` succeeds; `Get-SupervisoryReviewPolicyV2` returns without error
(empty is fine). `PURVCC-Discovery.ps1` performs this check.
**Implement:** `Install-Module ExchangeOnlineManagement`; sign in with the role-holding admin.

## 2.8 A pilot / simulation scope and change control
**Description:** A named **pilot population** (`Comms In-Scope – Pilot`) and a change-control path, so
the first policy runs **narrow and validated** before any broad rollout — consistent with the category
model (`global-requirements-purview.md` §6).
**Why:** Monitoring is high-impact and privacy-sensitive; policies must be tuned on a small, approved
group before expanding.
**Verify:** A named pilot group exists and is approved by HR/legal; a change window/approval path is
defined.
**Implement:** Define and approve the pilot group and change control before building the first policy.


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


# 3. Implementation Guide — Microsoft Purview Communication Compliance

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com` → **Communication Compliance**) and, where automated, via **Security &
Compliance PowerShell** (`Connect-IPPSSession`; the `SupervisoryReview*` cmdlets back Communication
Compliance) and **Microsoft Graph**. Artifact names follow the `<Purpose> – <Scope> – <Stage>`
convention from the Overview and are reused verbatim. **Portal paths and cmdlets are plan-dependent and
the portal evolves — verify against your tenant.**

> **Model:** Configure the **privacy + role-separation guardrails first**, design the policy, build it
> in a **pilot/simulation** scope, validate detection + reviewer workflow + privacy, tune, then expand.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
> **Outcomes are deferred to HR/legal at every step** — this guide configures the mechanism, not the
> verdict.

---

## Step 1 — Confirm readiness and capture the separation baseline (Assess)
1. Confirm licensing (Requirement 2.1): the **Communication Compliance** area is visible in the Purview
   portal. **Verify entitlement with Microsoft licensing — do not assume.**
2. Run `PURVCC-Discovery.ps1` (read-only). It reports the readiness signals it can see, the membership
   of each Communication Compliance role group (the **role-separation snapshot**,
   `Comms Role Separation – Evidence`), any existing `SupervisoryReview` policies/rules, and privacy/scope
   signals — and flags an over-broad scope or collapsed separation.
3. **Pass/fail gate:** licensing present, the four role groups exist, and you have a clear picture of
   current membership and any existing policies. **Do not proceed** until HR/legal have approved scope,
   reviewers, and the lawful basis (Requirement 2.3). Fail → resolve before configuring.

## Step 2 — Configure privacy and role separation FIRST (Configure — guardrails)
1. Portal → `Settings → Communication Compliance` (Privacy): set the agreed **privacy option** — if your
   privacy stakeholders require it, enable **pseudonymized/anonymized usernames** in the review
   experience (Requirement 2.4).
2. Portal → `Settings → Roles & scopes → Permissions`: populate the role groups with **separation**
   (Requirement 2.2):
   - **Communication Compliance Admin** → the program owners / IT config staff who *build* policies.
   - **Communication Compliance Analysts** → the agreed HR/compliance **reviewers** who triage alerts.
   - **Communication Compliance Investigators** → the compliance/legal **escalation** handlers.
   - **Communication Compliance Viewers** → oversight (reports only, no content).
   Avoid the combined **Communication Compliance** role group except for a tiny pilot; it collapses the
   separation.
3. Define the **exclusion group** `Comms Excluded – Privacy` for anyone who must never be monitored, and
   the pilot supervised group `Comms In-Scope – Pilot` (the **minimum** approved population).
4. **Pass/fail gate:** privacy setting matches the privacy stakeholders' decision; membership is
   separated (no one is silently both builder and reviewer unless HR/legal accepted it). Re-run
   `PURVCC-Discovery.ps1` and confirm the evidence snapshot reflects the intended separation.
   **Rollback:** remove any mistaken role-group membership; separation errors are corrected here before
   any policy exists.

## Step 3 — Design the pilot policy (Design)
1. With HR/compliance, decide the **detection intent** for the pilot: e.g. **offensive language /
   harassment** monitoring for a business unit, or **regulatory conduct** monitoring for a
   trading/advice desk, or **sensitive-data leak** detection.
2. Choose the **classifiers, sensitive info types, keywords, and conditions** (Requirement 2.6) and a
   **sampling percentage** appropriate to the review capacity.
3. Confirm the **channels** in scope (Teams / Exchange / Viva Engage / connected sources — Requirement
   2.5) and the **reviewers** (from the Analysts group) who will triage this policy's alerts.
4. Record the design as the policy `Comms Policy – Pilot – Simulation` with reviewers
   `Comms Reviewers – Pilot`.

## Step 4 — Build the pilot policy in SIMULATION/TEST (Configure — policy, pilot-first)
1. Preferred (portal): Communication Compliance → `Policies → Create policy` (a template such as
   *Detect inappropriate text* or a **custom** policy). Set:
   - **Users/groups to supervise** = `Comms In-Scope – Pilot`; **exclude** `Comms Excluded – Privacy`.
   - **Reviewers** = the approved Analysts (`Comms Reviewers – Pilot`).
   - **Channels** = the approved subset.
   - **Conditions** = the chosen classifiers / SITs / keyword dictionary / conditions and **sampling %**.
2. Or automate the create with `PURVCC-Configuration.ps1` — it composes the
   `New-SupervisoryReviewPolicyV2` + `New-SupervisoryReviewRule` call for `Comms Policy – Pilot –
   Simulation`. **It runs with `-WhatIf` by default** and prints exactly what it would create; add
   `-Commit` only after HR/legal sign-off to apply.
3. **Keep the pilot narrow.** Build it against `Comms In-Scope – Pilot` only, and treat the initial run
   as a **test/tuning** phase — you are validating detection and workflow, not enforcing outcomes.
4. **Pass/fail gate:** the policy exists, scoped to the pilot group, with the intended reviewers,
   classifiers/conditions, and the exclusion applied. Fail → correct scope/conditions.
   **Rollback:** disable or delete `Comms Policy – Pilot – Simulation`; because scope is the pilot group,
   blast radius is contained.

## Step 5 — Wire the reviewer workflow and remediation (Configure — workflow)
1. Confirm each pilot reviewer can open **Communication Compliance → Alerts** and see **only** this
   policy's alerts (their access is bounded by the Analysts role and the policy assignment). Use
   `PURVCC-ReviewerWorkflow.ps1` (`-WhatIf` default) to set/verify the policy's **reviewers** and the
   role-group membership that enforces separation; add `-Commit` to apply.
2. Agree the **remediation actions** reviewers will use in the portal on an alert: **resolve**, **tag**
   (compliant / questionable / non-compliant), **notify the user**, **escalate** to an Investigator, or
   **create/escalate to a case** (eDiscovery/legal). Configure any **notice templates** the workflow
   uses.
3. Document the **escalation path** to Investigators/legal and the **evidence** an escalation carries.
   **Remediation outcomes are HR/legal's determination** — reviewers surface and route; they do not
   adjudicate.
4. **Pass/fail gate:** a pilot reviewer can triage a test alert end-to-end (open → examine in context →
   tag/resolve/escalate) and an Investigator can receive an escalation; a Viewer sees reports but **no**
   content. Fail → fix role membership / reviewer assignment.

## Step 6 — Validate in the pilot (Pilot → Validate)
1. Generate representative test communications within the pilot group (e.g. sample messages that should
   and should not match) and let the policy process them.
2. Run the Testing Guide (`05-testing.md`). Confirm: matches raise **alerts**; reviewers can **action**
   them; **non-matching** messages don't alert (false-positive check); **privacy** controls are in
   effect (pseudonymization if enabled; excluded users not monitored); and **separation** holds
   (Viewers can't see content).
3. Run `PURVCC-Report.ps1` for the **alert/review rollup** (`Comms Review Rollup – Report`) and the
   separation evidence.
4. **Pass/fail gate:** detection is accurate enough to be useful, reviewers can work the queue, privacy
   and separation controls verified. Fail → **tune** (Step 7) and re-validate.

## Step 7 — Tune (Validate)
1. Reduce noise: adjust **classifiers/conditions**, tighten **keywords**, and set an appropriate
   **sampling percentage**; refine the in-scope population if too broad.
2. Use `PURVCC-Set-Scope.ps1` (`-WhatIf` default) to adjust the policy's scope/reviewers/conditions;
   `-Commit` to apply. Re-validate after each change.
3. **Pass/fail gate:** false positives are at a level reviewers can sustain and true violations are
   still caught. Iterate until the gate passes.

## Step 8 — Expand to the broad scope (Expand — enforce)
1. With HR/legal approval, create/clone the tuned policy as `Comms Policy – Broad – Enforce` scoped to
   `Comms In-Scope – Broad` (still excluding `Comms Excluded – Privacy`), with the production reviewer
   set. Use `PURVCC-Configuration.ps1 -Commit` or the portal.
2. **Expand deliberately** — widen scope in rings if the population is large, so review load and any
   privacy concerns scale gracefully.
3. Stand up the **maintenance cadence**: periodic review of scope, reviewers (joiners/leavers),
   classifiers, channels, and the separation evidence snapshot. Re-run `PURVCC-Report.ps1` on a schedule.
4. **Pass/fail gate:** broad policy detecting, production reviewers actioning, privacy + separation
   enforced, and a recurring review scheduled. **Rollback:** the broad policy can be disabled without
   touching the pilot; scope can be narrowed at any time.

---

### What this guide does NOT decide
- Whether a flagged message **is** a violation, and **what happens to the person** — an **HR/privacy/legal
  determination**. This guide configures detection, the reviewer workflow, and the guardrails, and
  produces the evidence; the verdict and any employment/regulatory action are made by those functions.
- **Regulatory applicability** (which conduct rules apply, retention of review records, legal hold on a
  case) — deferred to compliance/records/legal.


---


# 5. Testing Guide — Microsoft Purview Communication Compliance

Run these after configuring the guardrails (Step 2) and the pilot policy (Steps 4–5), and again after
each tuning change and before expanding. Every test here is **safe and read-only or contained to the
pilot group**; the point is to prove detection, the reviewer workflow, **privacy**, and **role
separation** all work before any broad rollout. Use test communications inside the **pilot** population
only. **Outcomes remain HR/legal's determination — these tests validate the mechanism.**

## Test 1 — Role separation is in place (the core guardrail)
**Do:** Run `PURVCC-Discovery.ps1`; review the `Comms Role Separation – Evidence` snapshot of each role
group's membership.
**Expected:** Policy-builders (Admin) are separated from reviewers (Analysts) and investigators
(Investigators); Viewers are oversight-only. No one is silently both Admin **and** Analyst/Investigator
unless HR/legal explicitly accepted it. **Fail** → correct membership (Implementation Step 2) before
proceeding.

## Test 2 — Privacy controls are in effect
**Do:** In the Purview portal → `Settings → Communication Compliance` confirm the agreed **privacy
option** (pseudonymized usernames if your privacy stakeholders required it). Open an alert as a reviewer.
**Expected:** The review experience reflects the agreed privacy setting (e.g. usernames pseudonymized);
the supervised population matches the approved scope and **excludes** `Comms Excluded – Privacy`.
**Fail** → set the privacy option / fix scope.

## Test 3 — In-scope population is minimized and exclusions hold
**Do:** Run `PURVCC-Discovery.ps1` (or `PURVCC-Report.ps1`) and inspect the policy's supervised
users/groups and exclusions.
**Expected:** Scope equals the approved `Comms In-Scope – Pilot` (not "everyone"); `Comms Excluded –
Privacy` members are not monitored. **Fail** → tighten scope.

## Test 4 — Policy exists and is correctly composed
**Do:** Run `PURVCC-Report.ps1`; review the policy/rule inventory for `Comms Policy – Pilot – Simulation`.
**Expected:** The policy is scoped to the pilot group, has the intended **reviewers**, the chosen
**classifiers / sensitive info types / keywords / conditions**, the expected **channels**, and a
**sampling percentage**. **Fail** → correct via `PURVCC-Configuration.ps1` / `PURVCC-Set-Scope.ps1`.

## Test 5 — A violating message raises an alert (true positive)
**Do:** From a pilot user, send a test communication that should match (e.g. sample offensive-language
or sensitive-info content matching the policy's conditions). Allow processing time.
**Expected:** An **alert** appears for the policy in Communication Compliance → Alerts, visible to the
assigned reviewers. **Fail** → check classifier/condition selection and channel coverage.

## Test 6 — A clean message does NOT alert (false-positive check)
**Do:** From a pilot user, send an ordinary, non-violating message.
**Expected:** No alert is raised. If clean messages alert, the policy is too broad. **Fail** → tune
classifiers/keywords/conditions (Implementation Step 7).

## Test 7 — Reviewer can work an alert end-to-end
**Do:** As an **Analyst** reviewer, open the test alert; examine the flagged message in context; apply a
**remediation action** — tag (compliant/questionable/non-compliant), resolve, notify, or **escalate**.
**Expected:** The reviewer can triage and action the alert; the action is recorded. **Fail** → check
Analysts role membership and reviewer assignment.

## Test 8 — Escalation reaches an Investigator; Viewer sees no content
**Do:** Escalate the test alert to an **Investigator**; separately, sign in as a **Viewer**.
**Expected:** The Investigator receives the escalation with context; the Viewer sees reports/dashboards
but **no message content**. **Fail** → correct Investigator/Viewer role membership.

## Test 9 — Activity and audit trail are captured
**Do:** Run `PURVCC-Report.ps1` for the `Comms Review Rollup – Report`; confirm reviewer actions and
policy configuration are reflected (Communication Compliance activity is recorded in the unified audit
log).
**Expected:** Policy configuration changes and reviewer actions are traceable — the defensible,
auditable trail. **Fail** → confirm auditing is enabled in the tenant.

## Test 10 — Safe automation defaults
**Do:** Run `PURVCC-Configuration.ps1`, `PURVCC-ReviewerWorkflow.ps1`, and `PURVCC-Set-Scope.ps1` with
no action switch.
**Expected:** Each runs in **`-WhatIf`** mode and only *describes* the change; nothing is modified until
`-Commit` is supplied. Discovery and Report scripts are read-only. **Fail** → stop; do not run with
`-Commit` until the dry-run output is correct and HR/legal have signed off.

---
**Gate to expand:** Tests 1–4 (guardrails), 5–6 (accuracy), 7–8 (workflow + separation), and 9–10
(evidence + safety) all pass in the pilot → proceed to broad rollout (Implementation Step 8). Any fail →
tune and re-test. Expansion is an HR/legal-approved decision, not a technical one.


---


# 6. Troubleshooting Guide — Microsoft Purview Communication Compliance

Field issues and how to resolve them. **Symptom → Likely cause → Resolution.** Confirm the basics
first: correct licensing, the right Communication Compliance role, and a successful
`Connect-IPPSSession`. Portal paths and cmdlets are plan-dependent and evolve — **verify against your
tenant.**

## Communication Compliance area isn't visible in the Purview portal
**Likely cause:** Missing E5 / E5 Compliance / Insider Risk Management licensing, or the admin lacks a
Communication Compliance role.
**Resolution:** Confirm entitlement in the M365 admin center (Requirement 2.1) — **verify with Microsoft
licensing, don't assume**. Ensure your account is in a Communication Compliance role group (Requirement
2.2). Sign out/in after a licence or role change.

## `Get-SupervisoryReviewPolicyV2` / `SupervisoryReview*` cmdlets are not recognised
**Likely cause:** Not connected via `Connect-IPPSSession`, an outdated ExchangeOnlineManagement module,
or Communication Compliance not entitled/enabled.
**Resolution:** `Import-Module ExchangeOnlineManagement`; `Update-Module ExchangeOnlineManagement`;
`Connect-IPPSSession` (Security & Compliance PowerShell — **not** `Connect-ExchangeOnline`). If the
cmdlets still don't appear, confirm licensing/enablement. `PURVCC-Discovery.ps1` performs this check.

## A role group is missing or empty
**Likely cause:** Communication Compliance not yet initialized in the tenant, or membership never set.
**Resolution:** The four groups (Admin / Analysts / Investigators / Viewers) appear once Communication
Compliance is available; populate them with **separation** in `Settings → Roles & scopes → Permissions`
(Implementation Step 2). If a group is genuinely absent, confirm licensing/enablement.

## The same person is both a policy-builder and a reviewer (separation warning)
**Likely cause:** One identity added to **Communication Compliance Admin** *and* **Analysts/
Investigators**, or the combined **Communication Compliance** role group is in use.
**Resolution:** This is the guardrail the solution exists to enforce. Remove the overlap so builders,
reviewers, and investigators are distinct — or obtain **explicit HR/legal acceptance** for a stated
reason. Avoid the combined role group outside a tiny pilot. `PURVCC-Discovery.ps1` flags the overlap.

## `PURVCC-Configuration.ps1` didn't create anything
**Likely cause:** It ran in the default **`-WhatIf`** mode (by design), or the policy name already
exists.
**Resolution:** Review the planned actions it printed; re-run with **`-Commit`** *after HR/legal
sign-off* to apply. If the policy already exists, adjust it with `PURVCC-Set-Scope.ps1` instead, or
choose a new name.

## `-Commit` fails: classifier or sensitive-info-type not found
**Likely cause:** A named trainable classifier or SIT isn't available in your tenant (plan-dependent or
different display name).
**Resolution:** In `Data classification → Classifiers` / `→ Sensitive info types`, confirm the exact
name exists (Requirement 2.6). Correct the `-Classifiers` / `-SensitiveInfoTypes` values to match, then
re-run. **Verify availability against your tenant — don't assume a classifier is present.**

## Policy created but no alerts appear
**Likely cause:** Processing latency; wrong channel coverage; the sampling percentage is low; test
messages fell outside the conditions; or the supervised population is wrong.
**Resolution:** Allow processing time. Confirm the in-scope **channels** (Teams/Exchange/Viva Engage/
connected sources — Requirement 2.5) and that the test user is in the supervised group and **not** in
`Comms Excluded – Privacy`. Check that test content actually matches the classifiers/conditions, and
that sampling isn't suppressing it. `PURVCC-Report.ps1` shows the effective rule.

## Too many alerts / reviewers overwhelmed (false positives)
**Likely cause:** Classifiers/conditions too broad, keyword lexicon too loose, sampling too high, or
scope too wide.
**Resolution:** Tune with `PURVCC-Set-Scope.ps1` (`-WhatIf` first): tighten classifiers/keywords, lower
the sampling percentage, or narrow the supervised population; re-validate (Testing Guide Test 6). This
is expected iterative tuning — do it in the pilot before expanding.

## A reviewer can't see alerts, or sees the wrong policy's alerts
**Likely cause:** Reviewer not in **Communication Compliance Analysts**, or not assigned as a reviewer on
the policy.
**Resolution:** Add them to the Analysts group and set them as a policy **reviewer** with
`PURVCC-ReviewerWorkflow.ps1` (`-WhatIf` then `-Commit`). Reviewer visibility is bounded by the policies
they're assigned to.

## A Viewer can see message content
**Likely cause:** The person is in Analysts/Investigators, not **Viewers**.
**Resolution:** Viewers get reports/dashboards only — no content. Move oversight-only people to the
**Communication Compliance Viewers** group. `PURVCC-Discovery.ps1` shows the membership.

## Usernames aren't pseudonymized in the review experience
**Likely cause:** The privacy/anonymization option isn't enabled.
**Resolution:** `Settings → Communication Compliance` → enable the pseudonymization/anonymized-usernames
option (Requirement 2.4) if your privacy stakeholders require it. Confirm reviewers now see pseudonyms
(Testing Guide Test 2).

## Connected-source (third-party) messages aren't inspected
**Likely cause:** The data connector for that source isn't configured or isn't ingesting.
**Resolution:** Stand up the relevant **data connector** in the Purview portal and confirm it's
ingesting before scoping a policy to that source (Requirement 2.5). **Connector availability/licensing
vary — verify against your tenant.**

## `Search-UnifiedAuditLog` returns nothing in `PURVCC-Report.ps1`
**Likely cause:** Unified auditing disabled, activity outside the `-DaysBack` window, or a different
record type in your tenant.
**Resolution:** Confirm unified auditing is enabled; widen `-DaysBack`. The **authoritative** alert and
review metrics live in the Communication Compliance area of the Purview portal — the audit-log rollup is
supplementary evidence.

## "Is this a violation? What do we do about the person?"
**Not a tool question.** Communication Compliance surfaces and evidences candidate violations and routes
them through reviewers; **whether a message is a violation and what happens to the employee is an
HR/privacy/legal determination.** Escalate through the Investigator/legal path with the evidence — do
not have IT adjudicate outcomes.


---


# 7. Best Practices — Microsoft Purview Communication Compliance

- **Configure the guardrails before the policy.** Set privacy options and populate the role groups with
  **separation** *first* — before any policy processes a single message. Detection stood up without
  governed reviewers and minimized scope is a privacy liability, not a control.
- **Separate builders, reviewers, and investigators.** Keep **Admin** (builds policies), **Analysts**
  (review content), **Investigators** (escalation), and **Viewers** (reports only) as distinct people.
  Avoid the combined **Communication Compliance** role group outside a tiny pilot — it collapses the
  separation you are trying to prove.
- **Reviewers are HR/compliance, not IT.** The people who read flagged content should be the agreed
  human-resources / compliance function. IT configures the mechanism; it does not review employees'
  messages.
- **Minimize the supervised population.** Scope to the **minimum the obligation requires**, never
  "everyone", and maintain `Comms Excluded – Privacy` for anyone who must not be monitored. Narrow scope
  is both a privacy control and a review-load control.
- **Pseudonymize where privacy requires it.** Turn on anonymized/pseudonymized usernames in the review
  experience when your privacy stakeholders call for it — reviewers can still triage without seeing
  identities until an escalation genuinely needs them.
- **Get the lawful basis first.** In many jurisdictions monitoring communications requires employee
  notice, works-council/union agreement, or a documented lawful basis **before** enabling. Confirm it
  with legal — the tool does not substitute for that.
- **Always pilot in simulation/test first.** Build the first policy against `Comms In-Scope – Pilot`,
  tune it, and validate the reviewer workflow before expanding. Monitoring is high-impact; never switch
  it on tenant-wide blind.
- **Always dry-run automation.** `PURVCC-Configuration.ps1`, `PURVCC-ReviewerWorkflow.ps1`, and
  `PURVCC-Set-Scope.ps1` default to **`-WhatIf`**. Read every line of the planned change; run `-Commit`
  only after the output is right and HR/legal have signed off.
- **Tune for signal, not volume.** Trainable classifiers are probabilistic — expect false positives and
  reduce them with better conditions, tighter keyword lexicons, and a sensible **sampling percentage**.
  A queue reviewers can't sustain gets ignored, which defeats the control.
- **Outcomes belong to HR/legal.** The tool surfaces candidate violations and routes them; **whether a
  message is a violation and what happens next is HR/privacy/legal's determination.** Reviewers tag,
  resolve, escalate — they do not adjudicate employment or regulatory outcomes.
- **Keep the separation evidence current.** Re-run `PURVCC-Discovery.ps1` / `PURVCC-Report.ps1` on a
  cadence; role-group membership drifts as people join and leave, and the membership snapshot is your
  auditable proof that oversight stayed governed.
- **Distinguish this from Insider Risk.** Communication Compliance inspects **message content**; Insider
  Risk scores **risky activity**. Don't try to make one do the other — route behaviour-based signals to
  Insider Risk Management and keep this focused on communications.
- **Verify licensing and classifier availability against your tenant.** E5 / E5 Compliance / Insider Risk
  entitlement, specific classifiers, connected sources, and portal paths are plan-dependent and evolve —
  confirm, never assume.
- **Maintain the channels.** As Teams/Viva Engage usage and connected sources change, revisit which
  channels each policy covers so coverage doesn't silently drift.


---


# 8. Deliverables Summary — Microsoft Purview Communication Compliance

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, the responsible-oversight model, and what's in the box |
| 1. Solution Overview | What Communication Compliance is, how it works, the detection dimensions, the role-separation model, limitations, the CC-vs-Insider-Risk distinction, and the naming convention |
| 2. Requirements Guide | Every CC-specific prerequisite with Verify / Implement-if-missing (licensing, role separation, HR/legal + lawful basis, privacy controls, channels, classifiers, toolchain, pilot) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + Security & Compliance PowerShell steps — guardrails first, pilot-in-simulation policy, reviewer/remediation workflow, validate, tune, expand; outcomes deferred to HR/legal |
| 5. Testing Guide | Validation procedures with pass/fail gates (separation, privacy, detection accuracy, reviewer workflow, evidence, safe defaults) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven, privacy-first recommendations |

## PowerShell scripts
| Script | Purpose | Default safety |
|---|---|---|
| `PURVCC-Discovery.ps1` | Readiness + **role-separation** + privacy/scope assessment; prints the separation evidence snapshot and any existing policies | **Read-only** |
| `PURVCC-Configuration.ps1` | Policy + classifier/condition config helper — composes the `SupervisoryReview` policy/rule for the pilot | **`-WhatIf`** (needs `-Commit`) |
| `PURVCC-ReviewerWorkflow.ps1` | Reviewer-workflow / remediation setup — sets policy reviewers and the role-group membership that enforces separation | **`-WhatIf`** (needs `-Commit`) |
| `PURVCC-Report.ps1` | Alert/review **rollup report** — policy/rule inventory, reviewer assignments, role membership, and CC activity from the audit log | **Read-only** |
| `PURVCC-Set-Scope.ps1` | Scope/config helper — adjust a policy's supervised users, reviewers, and conditions | **`-WhatIf`** (needs `-Commit`) |

All scripts run through **Security & Compliance PowerShell** (`Connect-IPPSSession`) and/or **Microsoft
Graph** with interactive modern-auth; **no credentials or secrets are embedded**. The three
configuration scripts are **safe-by-default** (`-WhatIf`) and only change the tenant when `-Commit` is
supplied — after HR/legal sign-off.

## Artifacts this solution creates (naming convention)
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

## Outcome
Communication risk surfaced **responsibly** — policies tuned to real violations, reviewers actioning a
sustainable queue, and **privacy plus role separation enforced and evidenced** — oversight without
surveillance, with **HR, privacy, and legal in control of every outcome**.
