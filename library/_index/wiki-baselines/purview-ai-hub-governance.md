# Purview AI Hub Governance — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: AIHUB

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

## The problem
Generative AI is already in the workday — Microsoft 365 Copilot, Copilot Studio agents, and consumer
tools like ChatGPT reached through the browser. Every interaction is a data flow: a prompt can carry
sensitive content, and a response can surface data a user shouldn't see or move it somewhere it shouldn't
go. Most organizations have **no visibility** into this and **no policy** over it. Left unaddressed,
ungoverned AI usage is a compliance gap and a data-risk exposure — sensitive data can leave through a
channel no existing control is watching.

## The solution
A complete, self-guided configuration of **AI governance from the DSPM-for-AI experience** in Microsoft
Purview. It turns on **visibility** into AI interactions, ensures Copilot **honors your sensitivity
labels** (so AI only answers over content a user is entitled to and labeled output stays labeled), applies
a **DLP policy — piloted in test/simulation** — that keeps the most sensitive labeled content out of AI
processing, and enables the recommended **insider-risk and communication-compliance** detections for risky
AI usage, configured **privacy-by-design**. Optional endpoint/browser signals surface sensitive data going
into consumer AI sites. Everything is piloted on a small ring, validated, then enforced, using the Purview
portal, Security & Compliance PowerShell, and Microsoft Graph — no third-party tooling.

## How it works
The engagement follows one disciplined model: **Assess → Design → Configure → Pilot (simulate) → Validate
→ Expand (enforce).** Assess audit, labels, licensing, and onboarding; design which content Copilot honors,
which content is withheld from AI, and which risky patterns are detected; configure visibility plus a
**test-mode DLP** scoped to a **pilot ring** and the portal one-click detections; validate that AI honors
labels, the DLP policy simulates matches without blocking, and interactions are visible; then enforce and
widen scope. Because DLP over AI is high-impact, **simulation is the safety gate** — every scriptable write
is previewed with `-WhatIf` first. Five tools — read-only or `-WhatIf` by default — automate discovery,
configuration (audit enablement + a test-mode DLP-for-AI policy + mode changes), validation, reporting, and
a readiness/health check; the portal-driven detections come with exact portal steps.

## What is delivered
- Six implementation documents (Overview, Requirements, Implementation, Testing, Best Practices, Troubleshooting) plus this summary.
- Five PowerShell tools: posture assessment, a configuration/remediation helper (audit + test-mode DLP-for-AI + mode changes), effective-settings validation, activity/evidence reporting, and a readiness/health helper.
- A named, gated, reversible rollout with explicit pass/fail criteria and privacy-by-design guidance at every step.

## Business outcome
AI usage that is **visible, labeled, and governed** — Copilot answers only over content users are entitled
to, the most sensitive content is kept out of AI, risky patterns are surfaced for review, and consumer-AI
egress can be seen. The governance is configured, piloted, validated, and defensible — at a fraction of the
cost of a bespoke consulting engagement.

## Important boundaries
What AI usage is *acceptable*, which content must be *withheld* from AI, and the adjudication of any
flagged interaction are **determinations owned by your governance, compliance, privacy, HR, and legal
functions** — this solution provides the technical configuration, detection method, and evidence, not the
determination; insider-risk and communication-compliance **outcomes are deferred to HR/legal**. DSPM for AI
is **new, partly in preview, and actively evolving** — capability availability, portal paths, policy names,
and audit record types are **licensing-/tenant-dependent** and are flagged "verify your licensing/tenant,"
never assumed or invented. Much of DSPM for AI is portal-driven; the scripts cover what is reliably
scriptable and point to the portal for the rest.


---


# 1. Solution Overview — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

## What this solution is
Generative AI is now inside the workday — Microsoft 365 Copilot, Copilot Studio agents, and consumer
tools like ChatGPT reached through the browser. Each of those interactions is a **data-flow**: a prompt
can contain sensitive content, and a response can surface data a user shouldn't see or paste somewhere
it shouldn't go. Microsoft Purview's **AI Hub / Data Security Posture Management for AI (DSPM for AI)**
is the control point that gives you **visibility, policies, and controls** over those AI interactions.

This solution stands up **AI governance from the DSPM-for-AI experience** in the Microsoft Purview
portal: it turns on the **visibility** into AI interactions (via unified audit and the DSPM-for-AI
activity views), applies the recommended **protective policies** — sensitivity-label protection so
Copilot honors your labels, a **DLP policy (piloted in test/simulation)** that keeps the most sensitive
labeled content out of AI processing, and the recommended **insider-risk and communication-compliance**
detections for risky AI usage — and confirms the **endpoint/browser signals** that surface sensitive
data pasted into consumer AI sites. Everything is piloted on a small ring, validated, then expanded,
using the Purview portal, Security & Compliance PowerShell, and Microsoft Graph.

> **Preview / evolving.** DSPM for AI is a **new and actively evolving** area of Purview; some
> capabilities are **in preview** and portal paths, policy names, and audit record types change. Every
> capability here is **cited or flagged "verify your licensing/tenant"** — none is invented.

## Why this matters
- **You can't govern what you can't see.** DSPM for AI surfaces *which* AI apps are used, *how many*
  interactions occur, and *whether sensitive data* appears in prompts/responses — the baseline for any
  policy.
- **Labels should follow data into AI.** Copilot honors sensitivity labels and their encryption — so a
  user only gets AI answers over content they're already entitled to, and labeled output stays labeled.
- **The most sensitive content may not belong in AI at all.** A DLP policy can keep specific labeled
  content **out of AI processing** — configured in **test/simulation first**, because blocking AI over
  content is high-impact.
- **Risky AI usage is an insider-risk and compliance signal.** Recommended detections flag risky prompts/
  responses for review — with **privacy-by-design and role separation**, and outcomes deferred to HR/legal.
- **Consumer AI is the quiet leak.** Sensitive data pasted into ChatGPT/other sites via the browser is a
  common exfiltration path; endpoint/browser signals surface it.

## What DSPM-for-AI governance configures (the levers)
| Lever | What it does | Where it is set |
|---|---|---|
| **AI visibility / audit** | Capture AI interactions (Copilot and more) for reporting and eDiscovery | Unified **audit** + DSPM-for-AI activity/reports in the Purview portal |
| **Sensitivity-label protection for Copilot** | Copilot honors labels + encryption (answers only over entitled content; output inherits labels) | Sensitivity labels + label policies (Copilot honors them) |
| **DLP for AI (protect labeled content)** | Keep specific labeled content out of AI processing | A **DLP policy** with the AI/Copilot scope — **piloted in test** first |
| **Insider risk for risky AI usage** | Detect risky AI interactions for review (privacy-by-design) | Insider Risk Management policy (portal one-click recommendation) |
| **Communication compliance for AI** | Detect sensitive/risky prompts and responses | Communication Compliance policy (portal one-click recommendation) |
| **Endpoint / browser signals** | Surface sensitive data going into consumer AI sites | Endpoint DLP + the Purview browser extension / device onboarding |

## Naming convention (used in every doc and script)
| Artifact | Name |
|---|---|
| Pilot ring group | `grp-ai-pilot@contoso.com` |
| DLP policy — protect labeled content from AI (pilot, test mode) | `AI-DLP-ProtectLabeled-Sim` |
| DLP rule | `AI-DLP-Rule-HighlyConfidential` |
| Insider-risk policy (portal recommendation) | `AI-IRM-RiskyAIUsage` |
| Communication-compliance policy (portal recommendation) | `AI-CC-PromptResponse` |
| Sensitivity label Copilot must honor | `Highly Confidential` |

## What you can control
- **Whether AI interactions are captured** (audit) and visible in DSPM-for-AI reports.
- **Which labeled content Copilot honors**, and which labeled content is **kept out of AI** (DLP).
- **Which risky AI patterns are detected** for insider-risk / communication-compliance review.
- **Whether consumer-AI data egress is surfaced** via endpoint/browser signals.
- **Rollout order** — pilot ring → broad — and rollback (set DLP back to simulation / disable a policy).

## Limitations (be honest with buyers)
- **DSPM for AI is new, partly preview, and evolving.** Capability availability, portal paths, policy
  names, and audit record types change — this solution flags each; **verify your licensing/tenant**.
- **Much of DSPM for AI is portal-driven ("one-click" recommendations).** Insider-risk and communication-
  compliance AI policies are configured in the portal; PowerShell coverage is limited. This solution
  scripts what is reliably scriptable (audit enablement, a test-mode DLP policy, discovery/validation/
  reporting) and gives exact portal steps for the rest — it does not invent cmdlets.
- **DLP over AI is high-impact — pilot in test/simulation.** A DLP policy that keeps content out of AI
  changes what Copilot can answer over; always run it in **test/simulation** first (this solution enforces
  that), then enforce.
- **Insider risk & communication compliance are HR/privacy-sensitive.** Configure with **privacy-by-
  design**, pseudonymization where applicable, and strict **role separation**; **outcomes are deferred to
  HR/legal** — this solution provides the technical method, not the case decision.
- **Endpoint/browser signals require onboarding.** Surfacing consumer-AI egress needs onboarded devices
  and the Purview browser extension — **verify device onboarding and extension support in your tenant**.
- **Determinations are deferred.** What AI usage is *acceptable*, which content must be *withheld* from
  AI, and any regulatory applicability are **governance/compliance/legal determinations** — this solution
  provides the configuration method and evidence.

## The standard deployment model
> Assess AI-governance readiness (audit, labels, licensing, onboarding) → design which content Copilot
> honors, which is withheld from AI, and which risky patterns are detected → configure visibility + a
> **test-mode DLP** scoped to a **pilot ring** and the portal one-click detections → validate that AI
> honors labels, the DLP policy simulates matches without blocking, and interactions are visible →
> **expand** (enforce DLP, widen scope) → operate (reports, review, evidence).
> Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**


---


# 2. Requirements Guide — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for governing AI interactions from the DSPM-for-AI experience; they
build on the shared **Global Requirements — Microsoft Purview Solutions** (licensing, least-privilege
roles, Security & Compliance PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal
stakeholders, and a pilot scope with change control). Read the Global Requirements first; this guide does
not repeat them.

> **Determination note.** What AI usage is *acceptable*, which content must be *withheld* from AI, which
> risky patterns warrant review, and any regulatory applicability are **governance, compliance, privacy,
> and legal determinations** owned by those functions — not technical defaults. Insider-risk and
> communication-compliance **outcomes are deferred to HR/legal**. This solution provides the
> **configuration method and evidence**; confirm the intent and case-handling with the accountable owner.

---

## 2.1 Licensing for DSPM for AI and the underlying controls
- **Description:** DSPM for AI has **free/included** visibility capabilities and **premium** capabilities
  that require **Microsoft 365 E5** or the **E5 Compliance** add-on (advanced DLP, insider risk,
  communication compliance, Audit Premium). Microsoft 365 **Copilot** governance assumes Copilot is
  licensed. Some DSPM-for-AI capabilities are **in preview**. **Verify your licensing/tenant** — Microsoft's
  licensing tables and the preview notes are the authority; do not assume a capability is included.
- **Why required:** The recommended AI policies (DLP, insider risk, communication compliance) are plan-gated.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm the DSPM-for-AI experience and the
  specific policy pages are available in the Purview portal (`IPRMS`/`AIHUB-Readiness.ps1` licensing signal).
- **How to implement if missing:** Assign/purchase the required plan for the pilot users before configuring.

## 2.2 Least-privilege roles for the AI-governance controls
- **Description:** The controls span several role groups: **Compliance Administrator / DLP** (the DLP
  policy), **Insider Risk Management** roles (risky-AI-usage policy — with strict role separation),
  **Communication Compliance** roles (prompt/response detection), **Information Protection** (labels the
  Copilot honors), and **Audit** roles (visibility). Assign the **least-privilege** role for each control
  to the person who owns it; reserve Global Administrator for where it is genuinely required.
- **Why required:** Each policy type is gated by its own role; insider-risk/communication-compliance
  additionally require **role separation** for privacy.
- **How to verify:** Purview → **Roles & scopes / Permissions** confirms the memberships per control.
- **How to implement if missing:** Assign the least-privilege roles under change control; keep insider-risk/
  communication-compliance roles separated from general admin.

## 2.3 Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **ExchangeOnlineManagement** (`Connect-IPPSSession` for the DLP and
  audit cmdlets) and **Microsoft Graph PowerShell** (licensing/service signals), with a modern-auth /
  MFA-capable admin.
- **Why required:** The scriptable parts (audit enablement, the test-mode DLP policy, discovery, validation,
  reporting) run through these.
- **How to verify:** `Connect-IPPSSession` then `Get-DlpCompliancePolicy` succeeds; `Connect-MgGraph`
  succeeds for the SKU read.
- **How to implement if missing:** Install the modules; confirm modern-auth sign-in. See the Global Requirements.

## 2.4 Unified audit enabled (AI visibility depends on it)
- **Description:** **Unified audit logging** must be **enabled** so AI interactions (Copilot and more) are
  captured and visible in DSPM-for-AI reports and available to eDiscovery.
- **Why required:** Without audit, there is no visibility into AI interactions — the foundation of the
  whole solution.
- **How to verify:** `Get-AdminAuditLogConfig` shows `UnifiedAuditLogIngestionEnabled = True` (the provided
  `AIHUB-Discovery.ps1` / `AIHUB-Readiness.ps1` report it); AI activities appear in the audit search.
- **How to implement if missing:** Enable it (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled
  $true` — the config helper does this gated behind `-Commit`); allow ingestion latency before expecting data.

## 2.5 A sensitivity-label taxonomy that Copilot can honor
- **Description:** For label-based AI protection to mean anything, a **sensitivity-label taxonomy** (and,
  for the withhold-from-AI control, a specific label such as `Highly Confidential`) must exist and be
  published. Copilot honors labels and their encryption — content the user isn't entitled to won't surface
  in AI answers, and labeled output stays labeled.
- **Why required:** The DLP "protect labeled content from AI" rule and the Copilot label-honoring behaviour
  key off existing labels.
- **How to verify:** `Get-Label` returns the taxonomy including the label the DLP rule targets; labels are
  published in a label policy.
- **How to implement if missing:** Build/publish the taxonomy first (the labels solution); return here once
  the target label exists.

## 2.6 A pilot ring and the pilot-in-simulation commitment
- **Description:** A named **pilot ring** (`grp-ai-pilot@contoso.com`) to receive the DLP-for-AI policy and
  detections **first**, and an explicit commitment that the DLP policy runs in **test/simulation** and the
  detections are validated before broad enforcement. DLP over AI is **high-impact** — simulation-first is
  mandatory.
- **Why required:** A DLP policy that withholds content from AI changes what Copilot can answer over;
  simulation surfaces false positives before they block real work.
- **How to verify:** Confirm the pilot group, a change window, and an approver.
- **How to implement if missing:** Create the pilot group and agree change control before configuring anything.

## 2.7 Endpoint / browser onboarding for consumer-AI signals (if in scope)
- **Description:** To surface sensitive data going into **consumer AI sites** (e.g. ChatGPT via the browser),
  target devices must be **onboarded** to endpoint DLP and the **Purview browser extension** installed on
  supported browsers. This is optional scope — include it if consumer-AI egress is a concern.
- **Why required:** Consumer-AI egress signals come from endpoint/browser telemetry, which requires onboarding.
- **How to verify:** Purview → **Settings → Device onboarding** shows onboarded devices; confirm the browser
  extension deployment; **verify current browser/extension support for your tenant**.
- **How to implement if missing:** Onboard devices and deploy the extension before expecting consumer-AI
  signals; this can follow the Copilot-governance pilot.

## 2.8 A privacy-by-design and case-handling decision (insider risk / communication compliance)
- **Description:** A decision, from your **HR, privacy, and legal** stakeholders, on how the risky-AI-usage
  insider-risk policy and the prompt/response communication-compliance policy are run — **pseudonymization**
  where applicable, **role separation**, who reviews, and how outcomes are handled. These are HR/privacy-
  sensitive controls.
- **Why required:** Insider-risk and communication-compliance data is sensitive; the configuration must be
  privacy-by-design and the **outcomes are HR/legal determinations**, not technical ones.
- **How to verify:** Confirm the review workflow, pseudonymization setting, role separation, and named
  reviewers with HR/privacy/legal.
- **How to implement if missing:** Get the privacy-by-design model and case-handling signed off before
  enabling the detections.


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


# 3. Implementation Guide — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

Follow these steps in order. This guide assesses AI-governance readiness, turns on visibility, applies
the recommended protective policies — with the **DLP-for-AI policy piloted in test/simulation** and the
insider-risk / communication-compliance detections configured via the portal one-click recommendations —
validates, then expands. Artifact names are fixed — use the exact names in §1. **DLP over AI is
high-impact, so the DLP policy runs in TEST/simulation on a pilot ring first.** Scriptable writes default
to `-WhatIf`; add `-Commit` to apply.

> Model: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).** DSPM for AI is
> new and partly **preview** — verify current portal paths, policy names, audit record types, licensing,
> and onboarding/extension support for your tenant as you go; nothing here is invented. Insider-risk and
> communication-compliance **outcomes are deferred to HR/legal**.

## Step 1 — Assess current state (read-only)
1. Run `AIHUB-Discovery.ps1`. It reports whether **unified audit** is enabled, whether **AI-interaction
   activity** (Copilot and related record types) is present in the audit log, which **sensitivity labels**
   exist (that Copilot can honor), any existing **DLP policies** and their mode, and endpoint/extension
   readiness signals. No changes are made.
2. In the Purview portal open **DSPM for AI** and review the **Overview / recommendations** and **Activity
   explorer / reports** — note which recommended policies are already in place and which are recommended.
3. Record gaps against the Requirements checklist. Do **not** proceed past: audit disabled, missing roles,
   no target label, or no pilot/privacy decision — remediate first.

## Step 2 — Turn on AI visibility (audit)
1. Ensure unified audit is enabled (Req 2.4). If not, `AIHUB-Config.ps1 -EnableAudit -WhatIf`, review, then
   `-Commit` (runs `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`). Allow ingestion
   latency before expecting AI activity.
2. In DSPM for AI, confirm the **Activity explorer / AI reports** begin to populate for pilot users' AI
   interactions. **Pass/fail:** `AIHUB-Discovery.ps1` shows audit enabled and AI-interaction events appear
   over time.

## Step 3 — Design the AI-governance policy set
1. With the accountable owner, decide: which **label** Copilot must honor and which label's content must be
   **withheld from AI** (the DLP target — e.g. `Highly Confidential`); which **risky AI patterns** the
   insider-risk / communication-compliance detections should flag; whether **consumer-AI egress** (endpoint/
   browser) is in scope (Req 2.7); and the **privacy-by-design** model for the HR-sensitive detections
   (Req 2.8).

## Step 4 — Confirm Copilot honors sensitivity labels
1. Confirm the target labels exist and are published (Req 2.5). Copilot honors labels and their encryption
   natively — a user only gets AI answers over content they are entitled to, and labeled content's
   protection is respected.
2. **Pass/fail:** as a pilot user, confirm Copilot does **not** surface content the user isn't entitled to,
   and that summarizing labeled/encrypted content behaves per the label's rights (validated in Testing).

## Step 5 — Configure the DLP-for-AI policy in TEST/simulation (pilot ring)
1. Create the protective DLP policy in **test/simulation**, scoped to the pilot ring:
   `AIHUB-Config.ps1 -CreateDlpForAI -PolicyName "AI-DLP-ProtectLabeled-Sim" -RuleName
   "AI-DLP-Rule-HighlyConfidential" -TargetLabel "Highly Confidential" -PilotGroup "grp-ai-pilot@contoso.com"
   -WhatIf`. It shows the `New-DlpCompliancePolicy` (**Mode = TestWithoutNotifications**) and
   `New-DlpComplianceRule` (condition: content labeled `Highly Confidential`) it would create — **without
   making changes**. Review, then `-Commit`.
2. **The AI/Copilot-specific scope and action are configured/confirmed in the portal.** The exact DLP
   location/action that governs AI/Copilot processing is **portal-driven and evolving** — after creating the
   policy, open it in **DSPM for AI → Policies / DLP** and confirm the AI scope and the protect action.
   **Verify the current AI DLP action for your tenant**; the script creates the policy in test mode and
   flags this.
3. **Pass/fail:** `Get-DlpCompliancePolicy "AI-DLP-ProtectLabeled-Sim"` shows **Mode = Test\*** (never
   Enable during pilot) scoped to the pilot ring. **Rollback:** `AIHUB-Config.ps1 -SetDlpMode -PolicyName …
   -Mode TestWithoutNotifications -Commit` (or `Remove-DlpCompliancePolicy`).

## Step 6 — Configure the recommended insider-risk and communication-compliance detections (portal)
1. In **DSPM for AI → Recommendations**, turn on the recommended **insider-risk** policy for risky AI usage
   (name it `AI-IRM-RiskyAIUsage`) and the **communication-compliance** policy for prompts/responses
   (`AI-CC-PromptResponse`). Configure them **privacy-by-design**: pseudonymization where applicable, strict
   **role separation**, and the named reviewers agreed in Req 2.8.
2. These are **portal-configured** (PowerShell coverage is limited) — follow the portal wizard. **Outcomes
   are deferred to HR/legal**: you are enabling detection and review, not deciding cases.
3. **Pass/fail:** the policies appear enabled in their respective solutions with the agreed privacy settings;
   `AIHUB-Discovery.ps1` notes their presence where readable.

## Step 7 — (Optional) Configure consumer-AI egress signals (endpoint/browser)
1. If in scope (Req 2.7): confirm devices are onboarded and the Purview **browser extension** is deployed,
   then enable the recommended endpoint/browser signals in DSPM for AI to surface sensitive data going into
   **consumer AI sites**. Keep any blocking action in **audit/simulation** first.
2. **Verify current browser/extension support for your tenant.** **Pass/fail:** consumer-AI activity begins
   to surface in the reports for onboarded pilot devices.

## Step 8 — Validate on the pilot
1. Run `AIHUB-Validation.ps1` (read-only): confirms audit enabled, the DLP policy is in **Test** (not Enable),
   scoped to the pilot ring, and the target label exists.
2. Complete the Testing Guide: AI interactions are visible; Copilot honors labels; the DLP policy **simulates**
   matches on labeled content **without blocking**; the detections raise reviewable signals (privacy-by-design);
   consumer-AI egress surfaces if in scope.
3. **Gate:** visibility works, Copilot honors labels, the DLP policy simulates cleanly (acceptable false-
   positive rate), and detections/reports work — before enforcing or widening scope.

## Step 9 — Expand and enforce
1. Once the pilot passes and the DLP false-positive rate is acceptable, move the DLP policy from **test** to
   **enforce** for the pilot ring first, then widen scope: `AIHUB-Config.ps1 -SetDlpMode -PolicyName
   "AI-DLP-ProtectLabeled-Sim" -Mode Enable -WhatIf` then `-Commit`. Widen the insider-risk/communication-
   compliance scope per the agreed rollout.
2. **Gate:** re-validate after each scope increase (`AIHUB-Validation.ps1`); confirm a documented rollback
   (set DLP back to test / disable a policy) per control.

## Step 10 — Operate: reports, review, and evidence
1. Run `AIHUB-Report.ps1 -CsvFolder <path>` to export **AI-interaction activity** and the **DLP-for-AI match
   summary** as evidence for the governance owner.
2. Run `AIHUB-Readiness.ps1` on a cadence to catch **audit turned off, a DLP-for-AI policy left in test after
   expansion (or flipped to enforce prematurely), missing onboarding, or licensing/preview changes**.
3. Operate the insider-risk / communication-compliance **review** with role separation; **case outcomes are
   HR/legal determinations** — this solution provides the detections and evidence, not the decisions.

---
### Order of operations
`Assess → Enable audit (visibility) → Design the policy set → Confirm Copilot honors labels → DLP-for-AI in
TEST on the pilot ring → Insider-risk + communication-compliance detections (portal, privacy-by-design) →
(optional) consumer-AI egress signals → Validate → Expand/enforce → Operate (reports, review, evidence)`


---


# 5. Testing & Validation Guide — Purview AI Hub Governance (DSPM for AI)

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not enforce the DLP-for-AI policy or widen scope until the relevant tests pass —
because DLP over AI is high-impact, the **test/simulation pilot** is your safety gate. Checks use the
Purview portal (DSPM for AI), Security & Compliance PowerShell, and Graph; the provided scripts automate
the read-only ones.

> **Reminder:** you are validating that AI governance *behaves as designed* (visibility on, labels honored,
> DLP simulates without blocking, detections raise reviewable signals) — not deciding *what AI usage is
> acceptable* or *adjudicating cases*; those are governance/HR/legal determinations from §2.

## Test 1 — AI visibility is on
- **How:** `AIHUB-Discovery.ps1` (or `Get-AdminAuditLogConfig`), then DSPM for AI → Activity explorer/reports.
- **Pass:** unified audit is enabled and AI-interaction activity (Copilot and related) appears for pilot
  users (allow ingestion latency).
- **Fail:** audit off → `AIHUB-Config.ps1 -EnableAudit -Commit`; no activity → allow latency, confirm pilot
  users are actually using AI, and **verify the current AI audit record types for your tenant**.

## Test 2 — Copilot honors sensitivity labels (entitlement)
- **How:** as a pilot user, ask Copilot to summarize/return content the user is **not** entitled to (labeled/
  encrypted content outside their rights).
- **Pass:** Copilot does **not** surface content the user isn't entitled to; labeled output retains its label/
  protection.
- **Fail:** Copilot surfaces content the user shouldn't see → confirm the labels are published and the content
  is actually labeled/encrypted (Req 2.5); **verify current Copilot label-honoring behaviour for your tenant.**

## Test 3 — The DLP-for-AI policy is in simulation (never enforcing during pilot)
- **How:** `AIHUB-Validation.ps1` (or `Get-DlpCompliancePolicy "AI-DLP-ProtectLabeled-Sim"`).
- **Pass:** the policy **Mode** is a **Test\*** (simulation) mode — it is **not** `Enable` — and it is scoped
  to `grp-ai-pilot@contoso.com` only.
- **Fail:** the policy is `Enable` during the pilot → set it back to test immediately (`AIHUB-Config.ps1
  -SetDlpMode -Mode TestWithoutNotifications -Commit`); a training/pilot DLP policy must never enforce.

## Test 4 — The DLP-for-AI policy simulates matches on the right content
- **How:** with pilot content labeled `Highly Confidential`, exercise the AI flow the policy governs; review
  the simulation matches in the portal and via `AIHUB-Report.ps1`.
- **Pass:** the policy **matches** the labeled content in simulation (a would-be protect action is recorded)
  **without blocking** real work; ordinary content is not matched.
- **Fail (false negatives):** labeled content isn't matched → confirm the rule condition targets the correct
  label and the AI scope/action is set in the portal (Step 5). **Fail (false positives):** ordinary content
  matches → tighten the condition and re-simulate.

## Test 5 — Risky-AI detections raise reviewable signals (privacy-by-design)
- **How:** in Insider Risk Management and Communication Compliance, confirm `AI-IRM-RiskyAIUsage` and
  `AI-CC-PromptResponse` are enabled and generate reviewable signals for the pilot; confirm pseudonymization
  and role separation are applied.
- **Pass:** the detections produce signals a designated reviewer can triage, with the agreed privacy settings;
  reviewers are role-separated from general admin.
- **Fail:** no signals (confirm the policy scope/conditions) or privacy settings not applied (correct per
  Req 2.8). **Outcomes are HR/legal determinations** — you are validating detection, not adjudicating.

## Test 6 — (If in scope) consumer-AI egress is surfaced
- **How:** on an onboarded pilot device with the Purview browser extension, paste sample sensitive content
  into a consumer AI site; review DSPM-for-AI / endpoint reports.
- **Pass:** the activity is surfaced in the reports (in audit/simulation) for the onboarded device.
- **Fail:** nothing surfaces → confirm device onboarding and extension deployment (Req 2.7); **verify current
  browser/extension support for your tenant.**

## Test 7 — Enforcement change is deliberate and reversible
- **How:** after the pilot passes, move the DLP policy to `Enable` for the pilot ring
  (`AIHUB-Config.ps1 -SetDlpMode -Mode Enable -Commit`) and confirm with `AIHUB-Validation.ps1`.
- **Pass:** the policy enforces only for the intended scope; a documented rollback (set back to test / disable)
  is confirmed.
- **Fail:** enforcement leaked beyond the intended scope → correct the scope and re-validate before widening.

## Test 8 — Reports and evidence are complete
- **How:** `AIHUB-Report.ps1 -CsvFolder <path>`; review the exported AI-interaction activity and DLP-for-AI
  match summary.
- **Pass:** the report reflects AI interactions and DLP simulation/enforcement matches for the pilot scope —
  the evidence the governance owner needs.
- **Fail:** a gap → confirm audit/latency and the policy scope, then re-export.

---
### Exit criteria (all must be true before enforcing / widening scope)
`AI visibility on · Copilot honors labels · DLP-for-AI in simulation (never Enable) during pilot · DLP
simulates the right matches, acceptable false-positive rate · risky-AI detections raise reviewable signals
(privacy-by-design, role-separated) · consumer-AI egress surfaced if in scope · enforcement deliberate and
reversible · reports/evidence complete · outcomes deferred to HR/legal`


---


# 6. Troubleshooting Guide — Purview AI Hub Governance (DSPM for AI)

Symptom → likely root cause → fix. Use **`AIHUB-Discovery.ps1`** (posture), **`AIHUB-Readiness.ps1`**
(licensing / audit / pilot sanity), **`AIHUB-Validation.ps1`** (audit + DLP mode/scope), and
**`AIHUB-Report.ps1`** (AI activity + DLP matches) to confirm before and after each fix. DSPM for AI is
**new, partly preview, and evolving** — portal paths, policy names, and audit record types change, and
much of the experience is **portal-driven**; where flagged, **verify against current Microsoft guidance /
your tenant** rather than assuming. The DSPM-for-AI portal reports are the authoritative view; the scripts
supplement them.

## A. Visibility / setup

### No AI-interaction activity appears
- **Audit disabled.** AI visibility depends on unified audit. **Fix:** `AIHUB-Readiness.ps1`; if off,
  `AIHUB-Config.ps1 -EnableAudit -Commit` (Req 2.4); allow ingestion latency.
- **No AI usage yet / record type differs.** **Fix:** confirm pilot users are actually using AI; the AI
  audit **record type/operations evolve** — **verify the current AI record type for your tenant** and widen
  the report window (`AIHUB-Report.ps1 -Days 30`).

### The DSPM-for-AI experience or a recommended policy isn't available
- **Licensing / preview.** Some capabilities need E5 / E5 Compliance and some are **in preview**. **Fix:**
  `AIHUB-Readiness.ps1` licensing signal; confirm the plan and the capability's preview status — **verify
  your licensing/tenant**.

## B. Copilot / label protection

### Copilot surfaces content the user shouldn't see
- **Content not labeled/encrypted, or labels not published.** Copilot honors labels/encryption only where
  they're applied. **Fix:** confirm the content is actually labeled and the labels are published (Req 2.5);
  **verify current Copilot label-honoring behaviour for your tenant** (Test 2).

### Labeled output loses its label after AI processing
- **Label inheritance gap.** **Fix:** confirm the label policy and Copilot integration; **verify current
  behaviour** — this area evolves.

## C. DLP-for-AI policy

### The DLP-for-AI policy isn't matching labeled content in simulation
- **Rule condition wrong, or AI scope/action not set in the portal.** **Fix:** confirm the rule targets the
  correct sensitivity label; then open the policy in **DSPM for AI** and confirm the **AI/Copilot scope +
  protect action** — this part is **portal-driven and evolving**, so the scripted skeleton alone won't
  match. **Verify the current AI DLP action for your tenant** (Step 5).

### The DLP-for-AI policy is blocking real work
- **Enforcing during the pilot, or matching too broadly.** **Fix:** `AIHUB-Validation.ps1` — if `Mode` is
  `Enable` during the pilot, set it back to test immediately (`AIHUB-Config.ps1 -SetDlpMode -Mode
  TestWithoutNotifications -Commit`); if the condition is too broad, tighten it and re-simulate. A pilot
  DLP-for-AI policy must **never** enforce.

### Enforcement leaked beyond the pilot ring
- **Scope too wide.** **Fix:** confirm the policy scope targets `grp-ai-pilot@contoso.com` only (portal);
  correct and re-validate before widening.

## D. Insider-risk / communication-compliance detections

### No risky-AI signals are generated
- **Policy not enabled / conditions not met / roles.** **Fix:** confirm `AI-IRM-RiskyAIUsage` and
  `AI-CC-PromptResponse` are enabled in their solutions with the intended scope; confirm the reviewer holds
  the right role. These are **portal-configured** (limited cmdlets).

### Privacy settings aren't applied (pseudonymization / role separation)
- **Configured without privacy-by-design.** **Fix:** re-configure per Req 2.8 — turn on pseudonymization
  where applicable and separate reviewer roles from general admin. **Outcomes are HR/legal determinations**
  — you configure detection and review, not the case decision.

## E. Consumer-AI egress

### Sensitive data pasted into consumer AI sites isn't surfaced
- **Devices not onboarded / extension missing.** **Fix:** confirm device onboarding and the Purview browser
  extension deployment (Req 2.7); **verify current browser/extension support for your tenant** (Test 6).

## F. Drift / operations

### Audit, a policy, or a detection changed unexpectedly
- **Config drift, or a preview capability changed.** **Fix:** run `AIHUB-Discovery.ps1` / `AIHUB-Readiness.ps1`
  on a cadence; reconcile audit state, DLP-for-AI mode/scope, and the detections against the signed-off
  design; re-check the DSPM-for-AI recommendations for new/changed items.

### A DLP-for-AI policy is stranded in test after expansion (or enforcing prematurely)
- **Rollout not completed / enforced too early.** **Fix:** `AIHUB-Readiness.ps1` flags a pilot/sim-named
  policy in the wrong mode; move it deliberately (`AIHUB-Config.ps1 -SetDlpMode …`) once the pilot passes,
  and re-validate.

---
## Escalation checklist
1. `AIHUB-Readiness.ps1` — licensing signal, audit on, DLP-for-AI in the right mode, onboarding/preview reminders?
2. `AIHUB-Discovery.ps1` — is AI activity appearing? do labels exist? is there an AI/Copilot DLP policy?
3. `AIHUB-Validation.ps1` — audit on, DLP in Test (never Enable during pilot), scoped to the pilot ring, target label present?
4. Portal (DSPM for AI) — Copilot honors labels, the AI DLP scope/action is set, and the insider-risk/comms-compliance detections are enabled privacy-by-design?
5. Still stuck → capture the exact behaviour and **verify the current Microsoft DSPM-for-AI guidance / your
   tenant** (portal paths, policy names, audit record types, preview status) before a broad change. What AI
   usage is acceptable, which content is withheld from AI, and case outcomes remain governance/HR/legal
   determinations — this guide fixes the *technical configuration*, not the *decision*.


---


# 7. Best Practices — Purview AI Hub Governance (DSPM for AI)

Field-tested practices for governing AI usage from DSPM for AI — getting visibility and control **without
breaking legitimate AI productivity** and **without over-collecting** in HR-sensitive areas. These
complement the Implementation and Testing guides.

## Start with visibility, then control
- **See before you block.** Turn on audit and read the DSPM-for-AI reports **first**. Understand which AI
  apps are used and whether sensitive data appears before you enforce anything — visibility is cheap and
  reversible; enforcement is not.
- **Let labels do the heavy lifting.** Copilot honors sensitivity labels and encryption natively. A good
  label taxonomy already keeps AI from surfacing content users aren't entitled to — invest there before
  adding AI-specific DLP.
- **Withhold from AI only what truly must be.** Keeping content out of AI processing is powerful but reduces
  AI usefulness. Reserve the DLP-for-AI "protect labeled content" control for the **most sensitive** label
  (e.g. `Highly Confidential`), not broadly.

## Rollout discipline (DLP over AI is high-impact — simulate first)
- **Simulation is mandatory, not optional.** A DLP-for-AI policy runs in **TestWithoutNotifications** on the
  pilot ring until the match quality is proven. `AIHUB-Validation.ps1` asserts the policy is **not** `Enable`
  during the pilot — treat any `Enable` during pilot as a stop-and-fix.
- **`-WhatIf` before every commit.** The scriptable writes (audit enablement, the DLP policy, mode changes)
  preview with `-WhatIf` and change nothing until `-Commit`. Read the preview.
- **Enforce the pilot ring first, then widen.** Move to `Enable` for `grp-ai-pilot@contoso.com` before the
  broad scope, and re-validate after each increase.
- **Verify the AI DLP action in the portal.** The exact DLP location/action that governs AI/Copilot is
  **portal-driven and evolving** — confirm it in DSPM for AI after creating the policy; **verify the current
  action for your tenant**. Don't assume a scripted skeleton is the whole control.

## Privacy-by-design for the HR-sensitive detections
- **Pseudonymize and separate roles.** Insider-risk and communication-compliance data is sensitive. Turn on
  **pseudonymization** where applicable and keep reviewer roles **separated** from general admin — enforce
  this in configuration, not just policy.
- **Detection is not adjudication.** These policies raise **reviewable signals**; the **outcome** (is this a
  violation? what action?) is an **HR/legal determination**. Build the review workflow with HR/legal and keep
  the decision with them.
- **Minimize collection.** Scope the detections to the risky patterns that matter; don't collect everything
  because you can.

## Operating the program
- **Re-baseline on a cadence.** DSPM for AI is **new and evolving** — new AI apps, new record types, and
  changed portal paths appear. Run `AIHUB-Discovery.ps1` / `AIHUB-Report.ps1` regularly and re-check the
  DSPM-for-AI recommendations.
- **Watch for drift.** `AIHUB-Readiness.ps1` flags audit turned off, a DLP-for-AI policy stranded in test after
  expansion (or flipped to enforce prematurely), missing onboarding, or a licensing/preview change.
- **Document a rollback per control.** Each control is reversible: set DLP back to test, disable a detection,
  turn a signal off. Know the exact command/portal step before you enforce.
- **Communicate before you restrict.** Surprise AI restrictions generate tickets and shadow-AI. Tell users what
  is changing and why before enforcing.

## Security & safety hygiene
- **No credentials in code.** Scripts authenticate interactively via `Connect-IPPSSession` / `Connect-MgGraph`;
  never embed secrets. Store exported evidence securely — it may describe sensitive AI usage.
- **Read-only or `-WhatIf` by default.** Discovery/validation/reporting/readiness scripts are read-only; the
  config script defaults to `-WhatIf` and requires `-Commit` for any write. Keep it that way.
- **Verify licensing/preview/tenant before relying on a capability.** DSPM for AI mixes free, premium, and
  preview features and the portal evolves — flag, don't assume; don't invent portal paths, policy names, or
  audit record types.


---


# 8. Deliverables Summary — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

## What you receive
A complete, self-guided package to govern AI interactions from the **DSPM-for-AI** experience in
Microsoft Purview — visibility into AI usage, sensitivity-label protection Copilot honors, a **DLP-for-AI
policy piloted in test/simulation**, and the recommended **insider-risk / communication-compliance**
detections for risky AI usage — piloted on a ring, validated, then enforced, using the Purview portal,
Security & Compliance PowerShell, and Microsoft Graph.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The DSPM-for-AI levers (visibility/audit, label protection for Copilot, DLP-for-AI, insider-risk/communication-compliance detections, endpoint/browser signals), the naming convention, and the deployment model — with the preview/evolving caveats. |
| **Requirements Guide** | Solution-specific prerequisites (DSPM-for-AI/E5 licensing, least-privilege roles per control, S&C PowerShell + Graph, unified audit enabled, a label taxonomy Copilot can honor, a pilot ring + simulation commitment, optional endpoint/browser onboarding, and a privacy-by-design/case-handling decision) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: assess → enable audit (visibility) → design the policy set → confirm Copilot honors labels → DLP-for-AI in **test** on the pilot ring → insider-risk + communication-compliance detections (portal, privacy-by-design) → optional consumer-AI egress signals → validate → expand/enforce → operate. Each step named, gated, reversible; `-WhatIf`/simulation first. |
| **Testing & Validation Guide** | 8 pass/fail tests — visibility on, Copilot honors labels, DLP in simulation (never Enable), DLP simulates the right matches, risky-AI detections raise reviewable signals, consumer-AI egress surfaced, enforcement deliberate/reversible, and reports complete. |
| **Best Practices** | Visibility-before-control, simulate-first rollout discipline, privacy-by-design for HR-sensitive detections, operating the program, and safety guidance. |
| **Troubleshooting Guide** | The common failure modes (no AI activity, Copilot surfaces content it shouldn't, DLP not matching or blocking too much, detections silent, consumer-AI not surfacing, preview/portal drift) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell) and/or `Connect-MgGraph`;
read-only or `-WhatIf` by default, writes gated behind `-Commit`. No credentials in code. Much of DSPM
for AI is **portal-driven** — the scripts cover what is reliably scriptable and point to the portal for
the rest; no cmdlets are invented.

| Script | Role | Default |
|---|---|---|
| `AIHUB-Discovery.ps1` | **Posture assessment** — report unified-audit state, presence of AI-interaction activity in the audit log, the sensitivity-label taxonomy (that Copilot honors), existing DLP policies + mode, and endpoint/extension readiness signals. | Read-only |
| `AIHUB-Config.ps1` | **Configuration / remediation helper** — enable unified audit, create the DLP-for-AI policy in **TestWithoutNotifications** scoped to the pilot ring (condition: a target label), and change a DLP policy's mode (test ↔ enforce). Portal one-click detections (insider risk / comms compliance) are flagged with exact portal steps. | `-WhatIf` |
| `AIHUB-Validation.ps1` | **Effective-settings validation** — confirm audit enabled, the DLP-for-AI policy is in a **Test** mode (never Enable during pilot), scoped to the pilot ring, and the target label exists. | Read-only |
| `AIHUB-Report.ps1` | **Activity / evidence** — export AI-interaction activity from the audit log and the DLP-for-AI match summary over N days to CSV. | Read-only |
| `AIHUB-Readiness.ps1` | **Scope/health helper** — licensing signal, audit on, endpoint/extension onboarding reminder, DLP-for-AI pilot-scope sanity (stranded-in-test or premature-enforce), and preview flag. | Read-only |

## Outcomes
- **Visibility** into AI usage across the tenant, captured and reportable as evidence.
- **Sensitivity-label protection** Copilot honors, plus a **DLP-for-AI** control that keeps the most
  sensitive labeled content out of AI — piloted in **simulation** before enforcement.
- **Risky-AI detections** (insider risk / communication compliance) configured **privacy-by-design** with
  role separation — raising reviewable signals, outcomes deferred to HR/legal.
- Optional **consumer-AI egress** signals for onboarded devices.
- Repeatable read-only tooling to report AI activity and catch drift over time.

## Explicitly out of scope (deferred)
- **What AI usage is acceptable, which content must be withheld from AI, and case adjudication** —
  governance/compliance/privacy/legal and HR determinations; this solution provides the detection method,
  configuration, and evidence, not the decisions.
- **The label taxonomy, broad DLP program, full insider-risk / communication-compliance programs, and
  eDiscovery** — assumed to exist or covered by separate Purview solutions; this solution configures the
  **AI-specific** governance over them.
- Any capability your **licensing/tenant** does not include or that is **in preview** — verify before
  relying on it; DSPM for AI is new and evolving.
