# Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

> **Version 1.0.0** · Category: Purview · Solution code: PURVDSPM

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

You cannot reduce data-security risk you cannot see — and generative AI has made that blind spot
dangerous. Microsoft 365 Copilot can surface any content a user already has access to, so years of
over-shared, unlabeled files that "nobody ever found" are suddenly one prompt away. This solution
implements **Data Security Posture Management (DSPM)** in Microsoft Purview to make the risk visible and
reduce it: the DSPM posture and recommendations, the sensitive-data risk across your estate, and **DSPM
for AI** — visibility into what Copilot and other AI apps can access, which prompts and responses touch
sensitive data, and the controls to reduce oversharing before and during AI adoption.

This is a complete, deploy-it-today package written for a competent Purview / compliance administrator,
using only the Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph — no
third-party tooling. Every high-impact change is piloted in **simulation/test** before it is enforced.

## What you get
- A plain-language Solution Overview of what DSPM and DSPM for AI show, the availability/licensing caveat
  for these evolving features, and the boundary between technical method and legal/records determination.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — licensing, DSPM roles,
  auditing, the labels + DLP foundation, Copilot/AI in scope, the sharing signal, and pilot discipline.
- An Implementation Guide of precise, ordered portal and PowerShell steps: read the posture, assess
  sensitive-data and AI/Copilot exposure, act on recommendations, pilot each reduction in
  simulation/test, validate, expand to enforce, and review on a recurring cadence.
- Five PowerShell scripts for scope/health checking, controls discovery, AI/oversharing exposure
  reporting, recommendation tracking, and safe oversharing reduction (read-only or `-WhatIf` by default).
- Testing and Troubleshooting guides, with an explicit enforcement gate, for a confident, safe rollout.

## What this delivers
A measured posture baseline across your data-security controls, a sensitive-data risk assessment, a
DSPM-for-AI exposure report of what Copilot/AI can reach and what it has touched, a prioritized set of
oversharing targets, and a validated reduction workflow — auto-labeling in simulation, DLP for AI in
test, and sharing restriction — that improves posture on re-measure rather than merely adding policies.

## The deployment model
Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).

## Outcome
Data-security risk made visible and reduced — posture measured, recommendations actioned, and Copilot/AI
oversharing surfaced and controlled — so data is safer before and during AI adoption. Feature
availability is flagged to verify in your tenant; regulatory, records, and legal determinations remain
with your governance functions.


---


# 1. Solution Overview — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

## What this solution is
You cannot reduce data-security risk you cannot see. **Data Security Posture Management (DSPM)** in
Microsoft Purview is the place that *makes the risk visible* — it aggregates signals from your
sensitivity labels, Data Loss Prevention (DLP), auto-labeling, and Insider Risk configuration into a
single posture view, surfaces where **sensitive data** is exposed across the estate, and hands you
**recommendations** to close the gaps. **DSPM for AI** extends the same idea to generative AI: it shows
what Microsoft 365 Copilot and other AI apps can *access*, which **prompts and responses touch
sensitive data**, and gives you the **oversharing-reduction controls** (sensitivity labels, DLP, and
SharePoint access) to shrink that exposure before and during AI adoption.

This solution is a repeatable, self-guided way to **enable DSPM and DSPM for AI, read the posture, act
on the recommendations, and reduce Copilot/AI oversharing** — using only the Microsoft Purview portal,
Security & Compliance PowerShell (`Connect-IPPSSession`), and Microsoft Graph, with no third-party
tooling. Every high-impact change is **piloted in simulation/test first**.

## Why this matters
- **Risk is invisible by default.** Sensitive data is scattered across SharePoint, OneDrive, Teams, and
  Exchange, much of it unlabeled and over-shared. DSPM is the first view that quantifies it.
- **Generative AI changes the blast radius.** Copilot can surface any content a user already has access
  to. A file that was "technically shared with everyone but nobody ever found it" becomes one prompt
  away. DSPM for AI makes that exposure measurable *before* it becomes an incident.
- **Recommendations are only value once actioned.** DSPM proposes concrete fixes (turn on a label,
  extend DLP, restrict sharing). The worth is in working the recommendation queue, not admiring it.
- **Oversharing reduction is high-impact.** Broad-scope sharing changes, new DLP, and auto-labeling can
  disrupt real work if enforced blindly — so this solution pilots every reduction in
  simulation/test/disabled mode and validates before enforcing.

## What DSPM and DSPM for AI actually show
- **DSPM (posture & recommendations)** — an at-a-glance posture across data-security controls, trends of
  sensitive-data activity, and a prioritized **recommendations** list (e.g. label coverage gaps, DLP
  scope gaps, risky activity) with a status you work to completion.
- **Sensitive-data risk** — where labeled/unlabeled sensitive information lives and moves, so you can
  target labeling and DLP at the real exposure rather than guessing.
- **DSPM for AI — data access** — visibility into what Microsoft 365 Copilot and other AI apps can
  reach, including where broad/organization-wide access ("oversharing") makes sensitive content
  reachable by AI.
- **DSPM for AI — sensitive interactions** — reports of **prompts and responses** that reference
  sensitive data (sourced from Purview auditing), so you can see AI's actual contact with sensitive
  content, not just its theoretical reach.
- **DSPM for AI — oversharing controls** — the one-click/recommended policies to reduce exposure:
  sensitivity-label coverage, DLP for AI (keeping labeled content out of AI processing), and SharePoint
  site-access/sharing restrictions.

> **Feature availability & licensing — verify in your tenant.** DSPM and DSPM for AI are newer and
> **actively evolving** capabilities. Which reports, recommendations, and one-click policies appear —
> and whether a capability is included or needs **Microsoft 365 E5 / the E5 Compliance add-on** (and in
> some cases **SharePoint Advanced Management** for site-access controls, or an AI/Copilot license) —
> **depends on your licensing and tenant**. Treat the specific blades and policy names in this guide as
> a current-state map to confirm against your own portal, never as guaranteed. This solution flags
> where to verify rather than asserting availability.

## The scope of "outcomes" (what this solution does and does not decide)
This solution delivers the **technical method and the evidence** — how to enable DSPM/DSPM for AI, read
the posture, and configure the reduction controls. It does **not** make **regulatory, records, or legal
determinations**. Which data must be retained or restricted, what an acceptable AI-exposure level is,
and any records/legal-hold obligations are **deferred to your compliance, records, privacy, and legal
functions**. You provide the configuration and the evidence; they own the determination.

## Naming convention (used in every doc and script)
Every artifact this solution creates or exports is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and portal so a reader can trace one artifact end to end.

| Artifact | Name |
|---|---|
| Posture & controls inventory export | `DSPM Posture – Estate – Discovery` |
| Sensitive-data risk assessment export | `Sensitive-Data Risk – Estate – Assess` |
| AI/Copilot data-access + prompts report | `AI Exposure – Copilot – Assess` |
| SharePoint/OneDrive oversharing export | `Oversharing Report – Sites – Assess` |
| Recommendation/action tracker export | `DSPM Recommendations – Estate – Tracker` |
| Pilot auto-labeling (simulation) policy | `Auto-Label Sensitive – Pilot – Simulation` |
| Pilot DLP-for-AI (test) policy | `DLP for AI – Pilot – Test` |
| Pilot oversharing-reduction scope | `Oversharing Reduction – Pilot – Stage1` |
| Broad oversharing-reduction scope | `Oversharing Reduction – Broad – Stage2` |
| Recurring posture-review cadence tag | `DSPM Posture Review – Estate – Recurring` |

## The standard deployment model
> Enable and read the posture → assess sensitive-data and AI/Copilot exposure → act on recommendations
> → pilot every reduction in **simulation/test**, validate, then **expand to enforce** → review on a
> recurring cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**


---


# 2. Requirements Guide — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

Verify **every** requirement before configuring. Each entry gives **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, stakeholders, pilot/change-control) are in
`global-requirements-purview.md` — this guide adds the DSPM/DSPM-for-AI-specific prerequisites.

> **Availability caveat.** DSPM and DSPM for AI are newer, evolving capabilities whose blades,
> reports, and one-click policies change and are **licensing-/tenant-dependent**. Where this guide names
> a portal path or a policy, **confirm it exists in your tenant** rather than assuming — several
> requirements below are "verify in your tenant" by design.

## 2.1 DSPM / DSPM-for-AI licensing (verify in your tenant)
**Description:** The compliance licensing DSPM and DSPM for AI require — commonly **Microsoft 365 E5** or
the **E5 Compliance** add-on for the full posture, recommendations, and AI reporting; some AI-exposure
and site-access controls may additionally require **SharePoint Advanced Management** and/or a
**Microsoft 365 Copilot** license.
**Why:** Most DSPM signals derive from advanced Purview features (auto-labeling, advanced DLP, Insider
Risk) that are plan-gated; the AI reports depend on AI/Copilot being licensed and in use.
**Verify:** In the Microsoft 365 admin center confirm the subscriptions/add-ons; in the Purview portal
(`https://purview.microsoft.com`) confirm **Data Security Posture Management** and **DSPM for AI** are
visible and their reports render. Run `PURVDSPM-ScopeConfig.ps1` (read-only) to enumerate the labels,
DLP, and auto-labeling features that will feed posture.
**Implement:** Assign/purchase the required licensing before starting; if a capability is absent, note it
as out of scope and proceed with the licensed subset.

## 2.2 DSPM roles (least-privilege) and portal access
**Description:** Membership in the least-privilege Purview role group(s) that grant DSPM and DSPM-for-AI
access — typically an information-protection / DSPM-capable role group for reading posture, plus the
matching configuration role for changing labels, DLP, or auto-labeling. Confirm the **exact current
role-group names** in your portal.
**Why:** Purview uses fine-grained role groups; reading posture, working recommendations, and creating
policies each need the matching role, and separation of duties should be preserved.
**Verify:** Purview portal → **Settings / Roles & scopes → Role groups** — confirm your account's
membership; confirm you can open **Data Security Posture Management** and **DSPM for AI** without an
access error.
**Implement:** Assign the least-privilege role group under change control; reserve Global/Compliance
Administrator for the initial enablement only.

## 2.3 Purview auditing (unified audit log) turned on
**Description:** Purview **Audit** (the unified audit log) enabled tenant-wide, since DSPM-for-AI
prompt/response reporting and much of the activity signal is sourced from audit records.
**Why:** Without auditing on, AI-interaction and sensitive-activity reporting is empty or incomplete.
**Verify:** Purview portal → **Audit** shows searching is on; `PURVDSPM-ScopeConfig.ps1` reports whether
auditing is enabled. AI-interaction audit records should be present once Copilot/AI is used.
**Implement:** Turn on auditing (a one-time tenant action); allow time for records to accumulate before
expecting AI reports to populate.

## 2.4 A labels + DLP foundation to build posture on
**Description:** At least a **baseline of sensitivity labels and DLP** in place (or ready to create),
because DSPM posture and DSPM-for-AI reduction controls act *through* labels and DLP — DSPM measures and
recommends; labels/DLP are the levers.
**Why:** Recommendations such as "extend a label" or "protect sensitive data in Copilot" have no effect
without a label taxonomy and DLP to apply; oversharing reduction relies on them.
**Verify:** Purview portal → **Information Protection → Labels** and **Data Loss Prevention → Policies**
show your taxonomy and policies; `PURVDSPM-Discovery.ps1` inventories labels, label policies, DLP
policies, and auto-labeling policies.
**Implement:** Stand up a baseline label taxonomy and at least one DLP policy first (a dedicated
sensitivity/retention-labels or DLP solution covers this) so DSPM has levers to recommend.

## 2.5 Microsoft 365 Copilot / AI apps in scope (for DSPM for AI)
**Description:** Clarity on which AI is in scope — **Microsoft 365 Copilot**, Copilot experiences, and/or
other **enterprise AI apps** — and whether it is licensed and in use, so DSPM-for-AI reporting has data.
**Why:** DSPM for AI reports on the AI actually present; with no Copilot/AI usage there is nothing to
report yet, and the value is pre-adoption posture plus in-adoption monitoring.
**Verify:** Confirm Copilot/AI licensing and rollout status with the owning team; Purview portal →
**DSPM for AI** shows connected AI activity once present. `PURVDSPM-AIExposure.ps1` reports what AI
activity is visible.
**Implement:** Confirm the AI in scope with stakeholders; if Copilot is not yet deployed, use DSPM for AI
in its **pre-adoption** mode to reduce oversharing *before* turning Copilot on.

## 2.6 SharePoint/OneDrive access & sharing signal (for oversharing)
**Description:** The ability to read **site/file access and sharing** state — the "oversharing" that makes
content reachable by AI — and, for the strongest site-access controls, **SharePoint Advanced Management**
(verify licensing).
**Why:** Oversharing reduction targets broadly-shared and organization-wide-accessible content;
measuring and restricting it needs the sharing/access signal and the SharePoint controls.
**Verify:** `PURVDSPM-AIExposure.ps1` reports SharePoint/OneDrive sharing exposure from the signals
available to it; confirm whether SharePoint Advanced Management site-access reviews/restrictions are
available in your tenant.
**Implement:** Where the advanced site-access controls are unavailable, use the label + DLP-for-AI levers
plus manual site-owner sharing reviews as the reduction path.

## 2.7 Pilot scope and simulation/test discipline
**Description:** A named **pilot scope** (a ring of users/sites) and the intent to run every high-impact
reduction — auto-labeling, DLP for AI, sharing restriction — in **simulation/test/disabled** mode first
(as the category model requires, GR §6).
**Why:** Auto-labeling and DLP can misfire on real content; a broad sharing restriction can break
legitimate collaboration. Simulation/test surfaces the impact before anyone is affected.
**Verify:** Confirm the pilot ring, that auto-labeling **simulation mode** and DLP **test mode** are
available, and that a change window/approval exists.
**Implement:** Define the pilot and the change-control path before enforcing anything; the scripts default
to `-WhatIf` and create policies in simulation/test.


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


# 3. Implementation Guide — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

Follow these steps **in order**. Posture and reports are read in the **Microsoft Purview portal**
(`https://purview.microsoft.com`); inventory, exposure, and reduction are automated with Security &
Compliance PowerShell (`Connect-IPPSSession`) and Microsoft Graph. Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim. **Every
high-impact reduction is piloted in simulation/test first** — the scripts default to `-WhatIf` and to
simulation/test mode.

> **Model:** Enable and read the posture, assess sensitive-data and AI/Copilot exposure, act on
> recommendations, pilot each reduction in simulation/test, validate, then expand to enforce, and review
> on a recurring cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Portal-path caveat.** The DSPM and DSPM-for-AI blades are evolving; the paths below are the current
> map. If a blade or policy name differs in your tenant, use the closest equivalent and **confirm before
> acting** — do not assume a path that is not present.

## Step 0 — Confirm scope, licensing, roles, and connections (Assess)
1. Run `PURVDSPM-ScopeConfig.ps1` (read-only). It confirms your `Connect-IPPSSession`/`Connect-MgGraph`
   sign-in, reports whether **auditing** is on, and enumerates the licensing-dependent features (labels,
   DLP, auto-labeling, Insider Risk presence) that will feed posture — resolving Requirements 2.1–2.3.
2. In the Purview portal confirm **Data Security Posture Management** and **DSPM for AI** are visible
   (Requirement 2.1). Note any capability that is absent so you scope around it.
3. Confirm the **pilot ring** and the change window (Requirement 2.7) before any configuration.

**Pass/fail:** Sign-in succeeds, auditing is on, DSPM and DSPM for AI are visible, pilot scope agreed.
**Rollback:** None — read-only.

## Step 1 — Inventory the controls that feed posture (Assess)
1. Run `PURVDSPM-Discovery.ps1` (read-only). It inventories **sensitivity labels**, **label policies**,
   **DLP policies/rules**, and **auto-labeling policies** via S&C PowerShell and writes the export
   `DSPM Posture – Estate – Discovery`.
2. Review the export against Requirement 2.4 — this is your baseline of the levers DSPM will recommend
   extending. A thin taxonomy or narrow DLP scope is itself the first finding.

**Pass/fail:** The export lists your labels, label policies, DLP policies, and auto-labeling policies.
**Rollback:** None — read-only.

## Step 2 — Read the DSPM posture and sensitive-data risk (Assess)
1. Purview portal → **Data Security Posture Management** → **Overview**. Read the posture summary and the
   **sensitive-data activity** trends. This is the estate-level "where is the risk" view.
2. Open **Recommendations**. Each recommendation (label-coverage gap, DLP-scope gap, risky activity,
   etc.) has a status — this is the queue you will work in Step 6.
3. Run `PURVDSPM-Discovery.ps1 -IncludeSensitiveTypes` to append the **sensitive information types**
   in scope to `Sensitive-Data Risk – Estate – Assess`, giving a portable record of what "sensitive"
   means in your tenant to accompany the portal view.

**Pass/fail:** Posture overview renders; a recommendations list is present; the risk export is written.
**Rollback:** None — read-only.

## Step 3 — Turn on / open DSPM for AI (Assess)
1. Purview portal → **DSPM for AI** → **Overview**. If prompted, complete the one-time **get-started /
   enablement** so AI reporting begins (this may enable audit collection for AI interactions — confirm it
   aligns with Requirement 2.3).
2. Confirm the AI in scope (Requirement 2.5) is reflected — Microsoft 365 Copilot and any other AI apps
   Purview can see. If Copilot is not yet deployed, you are in **pre-adoption** posture mode: the goal is
   to reduce oversharing *before* enabling Copilot.

**Pass/fail:** DSPM for AI overview loads; in-scope AI is reflected (or pre-adoption mode confirmed).
**Rollback:** Enablement is non-destructive; no policy is enforced by opening the blade.

## Step 4 — Assess AI/Copilot data-access and sensitive interactions (Assess)
1. In **DSPM for AI → Reports**, review the AI **data-access / oversharing** view (what AI can reach) and
   the **sensitive interactions** view (prompts/responses referencing sensitive data). These are the two
   exposure questions: *what can AI reach* and *what has AI actually touched*.
2. Run `PURVDSPM-AIExposure.ps1` (read-only). It reports the AI-interaction activity available from
   **Purview auditing** and the **SharePoint/OneDrive oversharing** signal, writing
   `AI Exposure – Copilot – Assess` and `Oversharing Report – Sites – Assess`.
3. Cross-read the two: broadly-shared sites holding **unlabeled sensitive** content are the priority
   oversharing targets, because Copilot can surface them to anyone with access.

**Pass/fail:** Both reports are written; you can name the top oversharing targets.
**Rollback:** None — read-only.

## Step 5 — Capture the recommendation/action baseline (Design)
1. Run `PURVDSPM-Tracker.ps1` (read-only) to snapshot the current DSPM recommendations and the DLP /
   auto-labeling policy states into `DSPM Recommendations – Estate – Tracker` — the before-state you will
   drive to completion and re-measure against.
2. With compliance/records/privacy/legal stakeholders (GR §5), agree which recommendations to act on and
   what an acceptable AI-exposure level is. **The determination is theirs**; you provide the evidence and
   will implement the agreed technical changes.

**Pass/fail:** Tracker baseline written; the agreed action set is recorded.
**Rollback:** None — read-only.

## Step 6 — Act on recommendations and pilot oversharing reduction (Configure → Pilot)
Work the agreed set. Every high-impact lever is piloted in **simulation/test** on the pilot ring first.

1. **Auto-labeling (simulation).** Run
   `PURVDSPM-Reduce-Oversharing.ps1 -Action AutoLabel -Scope "Oversharing Reduction – Pilot – Stage1"`
   (defaults to `-WhatIf`; add `-Commit` to create it). With `-Commit` it creates the auto-labeling
   policy `Auto-Label Sensitive – Pilot – Simulation` in **simulation mode** — it labels *nothing* yet,
   it only shows what it *would* label. This closes label-coverage recommendations without risk.
2. **DLP for AI (test).** Run
   `PURVDSPM-Reduce-Oversharing.ps1 -Action DlpForAI -Scope "Oversharing Reduction – Pilot – Stage1"`
   with `-Commit` to create the DLP policy `DLP for AI – Pilot – Test` in **test/disabled** mode, scoped
   to keep the agreed sensitivity-labeled content out of AI processing. **Verify the Copilot/AI DLP
   location name in your portal** — the script parameterizes it and does not assume it (see the script's
   notes).
3. **Sharing/site-access restriction.** Where the site-access controls are available (Requirement 2.6),
   restrict the top oversharing targets from `Oversharing Report – Sites – Assess` — do this on the
   pilot sites first via site owners / the portal, and record the change. The script's `-Action
   SharingReview` produces the prioritized site list to act on; it does **not** silently change sharing.

**Pass/fail:** Pilot auto-label policy is in **simulation**, DLP for AI is in **test/disabled**, and the
pilot sharing list is produced — nothing is enforced yet.
**Rollback:** Delete the pilot policies (they are simulation/test and enforce nothing); no content was
changed.

## Step 7 — Validate the pilot (Validate)
1. Let simulation/test run the agreed window. In the portal review the auto-labeling **simulation
   results** (what it would label) and the DLP **test** matches (what it would block/flag) for
   false positives.
2. Re-run `PURVDSPM-AIExposure.ps1` and `PURVDSPM-Tracker.ps1`; compare against
   `DSPM Recommendations – Estate – Tracker` — the actioned recommendations should show progress and the
   pilot oversharing signal should be lower.
3. Confirm with stakeholders that the simulated outcomes match intent (no legitimate collaboration
   broken). See Testing (doc 5) for the explicit gates.

**Pass/fail:** Simulation/test results reviewed, acceptable false-positive rate, recommendations show
movement. **Rollback:** If results are wrong, adjust the policy conditions and re-simulate — enforce
nothing until the gate passes.

## Step 8 — Expand and enforce (Expand)
1. Only after the pilot gate passes: turn the auto-labeling policy from **simulation** to **on**, and the
   DLP-for-AI policy from **test** to **enforce**, and widen scope to
   `Oversharing Reduction – Broad – Stage2`. Do this as a deliberate, change-controlled step —
   `PURVDSPM-Reduce-Oversharing.ps1 -Action Enforce -Commit` performs the mode change on the named
   policies (still gated behind `-Commit`).
2. Apply the broad sharing/site-access restrictions to the remaining oversharing targets under change
   control.
3. Stand up the recurring review: tag the cadence `DSPM Posture Review – Estate – Recurring` and schedule
   the read-only `ScopeConfig → Discovery → AIExposure → Tracker` chain (e.g. monthly) so posture stays
   measured as data and AI usage change.

**Pass/fail:** Policies enforced at broad scope, oversharing reduced on re-measure, recurring review
scheduled. **Rollback:** Return the enforced policy to simulation/test (or delete it) and restore prior
sharing on any site where enforcement caused an issue; the tracker export is the before-state to restore
toward.


---


# 5. Testing Guide — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

Run these after each stage. Every test is safe (read-only or simulation/test); the simulation and test
reviews are the **gates** before any enforcement. Pass/fail is explicit.

## Test 1 — Environment, licensing, roles, and auditing
**Do:** Run `PURVDSPM-ScopeConfig.ps1`; open **DSPM** and **DSPM for AI** in the Purview portal.
**Expected:** Sign-in succeeds; auditing reports as **on**; both DSPM blades load without an access
error; the licensing-dependent features are enumerated. Any absent capability is noted, not assumed.
**Gate:** Do not proceed until DSPM and DSPM for AI are visible and auditing is on.

## Test 2 — Controls inventory is complete
**Do:** Run `PURVDSPM-Discovery.ps1`; compare against **Information Protection → Labels** and **DLP →
Policies** in the portal.
**Expected:** `DSPM Posture – Estate – Discovery` lists every sensitivity label, label policy, DLP
policy, and auto-labeling policy shown in the portal — the baseline of levers DSPM will recommend.

## Test 3 — Posture and recommendations render
**Do:** Open **DSPM → Overview** and **Recommendations**; run `PURVDSPM-Discovery.ps1
-IncludeSensitiveTypes`.
**Expected:** The posture overview and sensitive-data trends display; a recommendations list is present;
`Sensitive-Data Risk – Estate – Assess` records the in-scope sensitive information types.

## Test 4 — DSPM for AI reports populate
**Do:** Open **DSPM for AI → Reports**; run `PURVDSPM-AIExposure.ps1`.
**Expected:** The AI data-access and sensitive-interaction views render (or, pre-adoption, show the
oversharing exposure with no AI activity yet); `AI Exposure – Copilot – Assess` and `Oversharing Report
– Sites – Assess` are written. *Note:* AI-interaction reporting depends on auditing being on (Test 1)
and on Copilot/AI usage having occurred.

## Test 5 — Oversharing targets are identifiable
**Do:** Cross-read `Oversharing Report – Sites – Assess` with the AI data-access view.
**Expected:** You can name the top oversharing targets — broadly-shared sites holding unlabeled
sensitive content — as the priority reduction set.

## Test 6 — Recommendation baseline captured
**Do:** Run `PURVDSPM-Tracker.ps1`.
**Expected:** `DSPM Recommendations – Estate – Tracker` snapshots the current recommendations and the
DLP / auto-labeling policy states — the before-state to re-measure against.

## Test 7 — Reduction helper makes no change in dry-run
**Do:** Run `PURVDSPM-Reduce-Oversharing.ps1 -Action AutoLabel -WhatIf` and `... -Action DlpForAI
-WhatIf`; then re-run `PURVDSPM-Discovery.ps1`.
**Expected:** The dry-run prints the intended policy it *would* create; the discovery inventory is
unchanged — `-WhatIf` created nothing. **This is the gate that proves the helper is safe by default.**

## Test 8 — Pilot policies are created in simulation/test only
**Do:** Run the helper with `-Commit` for the pilot (`Auto-Label Sensitive – Pilot – Simulation`, `DLP
for AI – Pilot – Test`); inspect them in the portal.
**Expected:** The auto-labeling policy is in **simulation** mode (labels nothing) and the DLP policy is
in **test/disabled** mode (enforces nothing). Neither changes content.
**Gate:** If either landed in an enforcing state, stop and correct before continuing.

## Test 9 — Simulation/test results are acceptable (enforcement gate)
**Do:** Let the pilot run the agreed window; review auto-labeling **simulation results** and DLP **test**
matches in the portal for false positives; confirm with stakeholders.
**Expected:** Simulated labels/blocks match intent with an acceptable false-positive rate and no
legitimate collaboration would be broken.
**Gate:** **Do not enforce (Step 8 of implementation) until this passes.**

## Test 10 — Recommendations move and oversharing drops on re-measure
**Do:** After acting on the agreed set, re-run `PURVDSPM-Tracker.ps1` and `PURVDSPM-AIExposure.ps1`;
compare to the baseline.
**Expected:** Actioned recommendations show progress/closed status and the pilot oversharing signal is
lower — evidence the posture actually improved, not just that a policy exists.

## Test 11 — Rollback works
**Do:** On a pilot policy, exercise the documented rollback (return to simulation/test or delete).
**Expected:** The policy reverts with no residual content change; the tracker export confirms the
before-state is restorable.


---


# 6. Troubleshooting Guide — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

Field issues and fixes. Most stem from **licensing/availability** (these features are evolving and
plan-gated), **auditing being off**, or the AI simply **not having been used yet**. When a portal path
differs from this guide, confirm the current equivalent rather than assuming.

## DSPM or DSPM for AI blade is not visible
- **Likely cause:** Licensing (Requirement 2.1) or role membership (Requirement 2.2).
- **Fix:** Confirm the subscription/add-ons in the M365 admin center; confirm your account is in a
  DSPM-capable role group in Purview → Roles & scopes. Run `PURVDSPM-ScopeConfig.ps1` to enumerate what
  your session can see. If the capability is genuinely absent for your plan, scope around it and note it.

## `PURVDSPM-ScopeConfig.ps1` reports the S&C session as FAIL
- **Cause:** Not connected to Security & Compliance PowerShell.
- **Fix:** `Connect-IPPSSession` with a modern-auth/MFA admin (GR §3). Re-run. For the auditing check and
  `Search-UnifiedAuditLog`, also connect Exchange Online (`Connect-ExchangeOnline`).

## DSPM for AI reports are empty
- **Cause 1 — auditing off:** Prompt/response and AI-interaction reporting is sourced from the unified
  audit log. **Fix:** Turn auditing on (Requirement 2.3); `PURVDSPM-ScopeConfig.ps1` shows
  `UnifiedAuditLogIngestionEnabled`. Allow time for records to accumulate.
- **Cause 2 — no AI usage yet:** With no Copilot/AI activity there is nothing to report. **Fix:** This is
  expected pre-adoption — use the oversharing signal (`PURVDSPM-AIExposure.ps1` sharing events) to reduce
  exposure before enabling Copilot.
- **Cause 3 — wrong audit RecordType/Operations:** The record types/operations that surface AI
  interactions evolve. **Fix:** Confirm the current values in Purview → Audit and pass them via
  `-AiRecordTypes` / `-SharingOperations`.

## `Search-UnifiedAuditLog` returns nothing or errors
- **Cause:** Not connected to Exchange Online, auditing off, or the window predates auditing being on.
- **Fix:** `Connect-ExchangeOnline`; confirm auditing on; widen `-Days` within the retained window. Note
  audit data has ingestion latency — very recent activity may not appear yet.

## Auto-labeling or DLP cmdlet fails as "not recognized" / access denied
- **Cause:** Auto-labeling / advanced DLP is unlicensed, or the role lacks configuration rights.
- **Fix:** Confirm licensing (Requirement 2.1) and the configuration role (Requirement 2.2). Reading is
  possible with a lower role than creating; `PURVDSPM-Discovery.ps1` will warn where a feature isn't
  readable.

## `PURVDSPM-Reduce-Oversharing.ps1 -Action DlpForAI` stops asking for `-DlpAiLocation`
- **This is intentional.** The DLP location that scopes a policy to Microsoft 365 Copilot / AI is
  licensing-dependent and evolving, so the script will not assume it. **Fix:** Confirm the exact location
  name in Purview → DLP (or use the DSPM-for-AI one-click "protect sensitive data in Copilot" policy in
  the portal if present), then pass it via `-DlpAiLocation`.

## A pilot policy landed in an enforcing state
- **Cause:** Wrong mode or a manual portal change.
- **Fix:** `PURVDSPM-Reduce-Oversharing.ps1` creates auto-labeling in **simulation**
  (`TestWithoutNotifications`) and DLP in **test** by design. If a policy is enforcing before the gate,
  return it to test/simulation (Set-*Policy -Mode TestWithoutNotifications) and re-validate. Never enforce
  before Testing Test 9 passes.

## Simulation/test shows too many false positives
- **Cause:** Conditions too broad (sensitive-info-type confidence, label scope).
- **Fix:** Tighten the auto-labeling rule conditions / DLP rule and **re-simulate** — do not enforce.
  The whole point of simulation/test is to tune before anyone is affected.

## Recommendations don't change after acting
- **Cause:** Posture re-evaluation latency, or the action didn't address the specific recommendation.
- **Fix:** Allow the portal time to re-evaluate; re-run `PURVDSPM-Tracker.ps1` and compare policy state to
  the baseline. Confirm the change you made maps to the recommendation you intended to close (record the
  mapping in the tracker's Notes column).

## Enforcement broke legitimate collaboration
- **Cause:** A sharing restriction or DLP-for-AI block was too broad.
- **Fix:** Execute the documented rollback — return the policy to test/simulation (or delete it) and
  restore the prior sharing on the affected site. Use `DSPM Recommendations – Estate – Tracker` as the
  before-state, tune conditions, re-simulate, then re-expand.

## Escalation boundary
Regulatory, records-retention, and legal questions — what *must* be restricted or retained, what
AI-exposure level is acceptable, legal-hold implications — are **not** resolved here. Capture the
technical evidence (the exports and tracker) and route the determination to your compliance, records,
privacy, and legal functions (GR §5).


---


# 7. Best Practices — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

- **Reduce oversharing *before* you turn on Copilot.** The safest AI adoption is one where the data was
  already tidied. Use DSPM for AI's pre-adoption posture to shrink broad access first — a file Copilot
  can't reach can't be surfaced by a prompt.
- **Always pilot in simulation/test.** Auto-labeling runs in **simulation** and DLP runs in **test**
  precisely so you can see impact before anyone is affected. `-WhatIf` is the default on the reduction
  helper for the same reason — read every intended action before you `-Commit`, and enforce only after
  the gate passes.
- **Work the recommendation queue; don't admire the dashboard.** DSPM's value is realized only when
  recommendations move to done. Snapshot the queue, agree the action set with stakeholders, act, then
  re-measure — the trend line, not the screenshot, is the outcome.
- **Fix the biggest exposure first.** Prioritize broadly-shared sites holding **unlabeled sensitive**
  content — that intersection is where AI exposure is highest. Start there, not with the easiest tickets.
- **Let compliance/records/privacy/legal own the determination.** You provide the technical method and
  the evidence; *what* must be restricted or retained and *what* AI-exposure level is acceptable are
  their calls. Capture the agreed set before configuring.
- **Verify availability, never assume it.** DSPM and DSPM for AI are evolving and licensing-dependent.
  When a blade, report, or one-click policy isn't where this guide says, confirm it in your tenant and
  use the closest current equivalent — don't force a path that isn't there.
- **Keep auditing on.** DSPM-for-AI prompt/response reporting is only as complete as the unified audit
  log feeding it. If AI reports look empty, check auditing and confirm AI usage has actually occurred.
- **Confirm the Copilot/AI DLP location in your portal.** The DLP-for-AI location name evolves; the
  reduction helper parameterizes it rather than assuming it. Verify the exact location before you enforce
  a DLP-for-AI policy so it scopes where you intend.
- **Labels and DLP are the levers — keep them healthy.** DSPM measures and recommends, but acts through
  your label taxonomy and DLP. A thin taxonomy caps how much posture you can improve; invest there.
- **Preserve separation of duties.** Read posture with a least-privilege role; keep configuration rights
  separate. Reserve Global/Compliance Administrator for the initial enablement only.
- **Make posture review recurring.** Data and AI usage drift. Schedule the read-only `ScopeConfig →
  Discovery → AIExposure → Tracker` chain under `DSPM Posture Review – Estate – Recurring` so the estate
  stays measured, not measured once.
- **Keep an easy rollback.** Every enforced policy should be one change from returning to simulation/test.
  Keep the tracker export as the before-state so any enforcement can be safely reverted.


---


# 8. Deliverables Summary — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What DSPM and DSPM for AI show (posture, sensitive-data risk, AI/Copilot data access, sensitive prompts/responses, oversharing controls), the availability/licensing caveat, the outcome-vs-determination boundary, and the naming convention |
| 2. Requirements Guide | Every DSPM/DSPM-for-AI prerequisite with Verify / Implement-if-missing (licensing, DSPM roles, auditing, labels+DLP foundation, Copilot/AI in scope, sharing signal, pilot discipline) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell steps: confirm scope, inventory controls, read posture & risk, open DSPM for AI, assess AI exposure, baseline recommendations, pilot reduction in simulation/test, validate, expand/enforce, recurring review |
| 5. Testing Guide | Validation procedures with explicit pass/fail and the enforcement gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for measuring and reducing posture safely |

## PowerShell scripts
All are safe-by-default (read-only, or `-WhatIf` / simulation-test unless `-Commit`), use
`Connect-IPPSSession` and/or `Connect-MgGraph`, and store **no** credentials.
| Script | What it does |
|---|---|
| `PURVDSPM-ScopeConfig.ps1` | Read-only scope/health helper: confirms sign-in, reports whether **auditing** is on, and enumerates the licensing-dependent features (labels, DLP, auto-labeling, Insider Risk presence) feeding posture. Resolves Requirements 2.1–2.3 |
| `PURVDSPM-Discovery.ps1` | Read-only inventory of sensitivity labels, label policies, DLP policies/rules, and auto-labeling policies (and, with `-IncludeSensitiveTypes`, the sensitive info types). Writes `DSPM Posture – Estate – Discovery` and `Sensitive-Data Risk – Estate – Assess` |
| `PURVDSPM-AIExposure.ps1` | Read-only DSPM-for-AI exposure report: AI/Copilot interaction activity from Purview auditing plus SharePoint/OneDrive oversharing signal. Writes `AI Exposure – Copilot – Assess` and `Oversharing Report – Sites – Assess` |
| `PURVDSPM-Tracker.ps1` | Read-only recommendation/action tracker: snapshots DSPM recommendations and DLP / auto-labeling policy states. Writes `DSPM Recommendations – Estate – Tracker` |
| `PURVDSPM-Reduce-Oversharing.ps1` | Oversharing-reduction helper (label / DLP-for-AI / sharing-review / enforce). Defaults to `-WhatIf`; with `-Commit` creates auto-labeling in **simulation** and DLP for AI in **test**, produces the prioritized sharing list, and (Enforce) flips named policies from simulation/test to on — never silently |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/test) →
  Validate → Expand (enforce).**

## Outcome
Data-security risk made **visible and reduced**: posture measured across the estate, recommendations
actioned to completion, and Copilot/AI oversharing surfaced and controlled through labels, DLP for AI,
and sharing restriction — every high-impact change piloted in simulation/test before enforcement — so
data is safer before and during AI adoption. Regulatory, records, and legal determinations remain with
the organization's governance functions; this solution delivers the technical method and the evidence.
