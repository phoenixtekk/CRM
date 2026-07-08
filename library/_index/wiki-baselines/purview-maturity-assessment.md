# Microsoft Purview Maturity Assessment

> **Version 1.0.0** · Category: Purview · Solution code: OPSMAT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview Maturity Assessment

**White-label · Purview Solutions**

Most organizations have some Microsoft Purview turned on, some half-configured, and some untouched —
and no shared, defensible picture of where the compliance and data-governance program actually stands
or what to do next. That gap shows up as stalled projects, duplicated effort, an unanswerable board
question ("how mature are we?"), and a budget ask with no evidence behind it.

This is a complete, run-it-in-order package for **assessing Microsoft Purview maturity**. It scores ten
Purview capability domains against a defined 0–5 maturity model, produces an evidence-backed scorecard
and an overall maturity band, and turns the gaps into a prioritized Now/Next/Later roadmap — so
leadership can see the current state, the target state, and the sequenced next steps. It is written for
an administrator with no prior assessment experience, and it scores from **tenant evidence read by
PowerShell**, not from a questionnaire.

## What you get
- A plain-language Solution Overview of the maturity model — 10 domains (Information Protection, DLP,
  Data Lifecycle & Records, Insider Risk, Communication Compliance, Audit, eDiscovery, DSPM, Data
  Governance, Compliance Manager) × 6 levels (Absent → Optimized).
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps — evidence discovery, rubric scoring, roadmap,
  executive readout, and an optional quick-win baseline piloted in simulation/test.
- Five PowerShell scripts: cross-domain discovery, the maturity-scoring engine, validation, safe
  quick-win remediation, and a scope/health helper.
- Testing and Troubleshooting guides for a confident, repeatable assessment.

## What this delivers
A named, reusable set of artifacts — the `Purview Maturity Model - 10 Domains x 6 Levels`, the
`Purview Maturity Scorecard` (a 0–5 score per domain with the evidence behind it and a weighted overall
band), and the `Purview Maturity Roadmap - 3 Horizons` — with any quick-win baseline piloted in
test/simulation before enforcement and a documented rollback. Regulatory, records, and legal
determinations are deferred to the relevant governance functions; the assessment provides the technical
method and evidence.

## The standard deployment model
**Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**

## Outcome
A defensible answer to "how mature is our Purview program, and what's next?" — scored per domain,
banded overall, and sequenced into a roadmap you can re-run each quarter to prove the trend.


---


# 1. Solution Overview — Microsoft Purview Maturity Assessment

## What a Purview maturity assessment is
Microsoft Purview is Microsoft's compliance and data-governance suite — sensitivity labels, Data Loss
Prevention (DLP), data lifecycle and records management, insider risk, communication compliance,
audit, eDiscovery, Data Security Posture Management (DSPM), and data governance (the Unified Catalog /
Data Map). Most organizations have some of these turned on, some half-configured, and some untouched —
with no shared picture of where the program actually stands or what to do next.

A **maturity assessment** fixes that. It scores each Purview capability domain against a defined
maturity model, produces a **scorecard** (one number per domain plus an overall band), and turns the
gaps into a **prioritized roadmap** — so leadership can see the current state, the target state, and
the sequenced next steps, and defend both to auditors and to the budget.

This solution delivers the assessment end to end: a repeatable maturity model, an evidence-based
scoring method (read tenant state with PowerShell, not opinion), the scorecard and roadmap, and — where
the assessment recommends a quick-win baseline — the configuration is **piloted in simulation/test
first**, validated, then enforced/expanded. It is written for an administrator with no prior Purview
assessment experience.

## The maturity model (the named object reused throughout)
The assessment scores **10 Purview capability domains** on a **6-level** scale (0–5). This model —
`Purview Maturity Model - 10 Domains x 6 Levels` — is used verbatim in the Implementation Guide,
Testing, Troubleshooting, and the scripts.

**Domains (D1–D10):**

| # | Domain | What it covers |
|---|---|---|
| D1 | Information Protection | Sensitivity labels, label policies, auto-labeling |
| D2 | Data Loss Prevention | DLP across Exchange, SharePoint, OneDrive, Teams, endpoint, cloud |
| D3 | Data Lifecycle & Records | Retention labels/policies, records management, disposition |
| D4 | Insider Risk Management | Insider risk policies, triage, privacy-by-design (HR/legal-gated) |
| D5 | Communication Compliance | Supervised communications policies (HR/legal-gated) |
| D6 | Audit | Unified audit log; Audit Standard vs Premium |
| D7 | eDiscovery | eDiscovery (Standard/Premium), holds, review sets |
| D8 | Data Security Posture (DSPM) | DSPM and DSPM for AI — posture recommendations and monitoring |
| D9 | Data Governance | Unified Catalog / Data Map, glossary, lineage, stewardship |
| D10 | Compliance Manager | Assessments, improvement actions, compliance score |

**Maturity levels (L0–L5):**

| Level | Name | Meaning |
|---|---|---|
| L0 | Absent | Capability not present or not licensed |
| L1 | Initial | Ad hoc, undocumented, no owner |
| L2 | Developing | Basic configuration piloted in test/simulation, limited scope |
| L3 | Defined | Standardized, documented, enforced at meaningful scope, owner assigned |
| L4 | Managed | Measured and reported, tuned on metrics, integrated (e.g. SIEM) and reviewed |
| L5 | Optimized | Automated, continuously improved, org-wide, evidence-driven |

## How it works
1. **Assess.** `PURVIEW-Discovery.ps1` reads the tenant's current Purview configuration across all ten
   domains (labels, DLP, retention, audit state, insider-risk/comms-compliance presence, eDiscovery,
   DSPM, catalog, Compliance Manager) — an evidence inventory, not a survey.
2. **Score.** `PURVIEW-MaturityScore.ps1` applies the model's per-domain rubric to that evidence and
   produces the `Purview Maturity Scorecard` — a 0–5 score per domain, an overall weighted band, and
   the specific signals behind each score.
3. **Roadmap.** The scorecard's gaps become the `Purview Maturity Roadmap - 3 Horizons`
   (Now / Next / Later), sequencing each domain from its current level to its agreed target level.
4. **Pilot the quick wins.** Where the roadmap calls for an immediate baseline (e.g. enable audit,
   publish a starter label, stand up a DLP policy in test mode), `PURVIEW-Remediation.ps1` applies it
   **in simulation/test/`-WhatIf` first** — never straight to enforce.
5. **Validate & expand.** `PURVIEW-Validation.ps1` confirms the baseline and re-checks the gates;
   `PURVIEW-MaturityScore.ps1` renders and exports the scorecard for the readout. Re-run the assessment on a
   cadence to show the maturity trend over time.

## What you can control
- The **domains in scope** and each domain's **target level** (not every org needs L5 everywhere).
- The **weighting** applied to each domain in the overall band (regulatory-driven orgs weight D3/D6/D7
  higher; IP-sensitive orgs weight D1/D2).
- The **evidence thresholds** in the rubric (what counts as L2 vs L3 for your tenant).
- Which quick-win baselines to pilot, and the pilot scope (`Purview - Pilot Users`).

## Benefits
- **A number, not a vibe.** Each domain gets a defensible 0–5 score backed by tenant evidence, so the
  program's state is measurable and comparable over time.
- **A sequenced next step.** The roadmap says exactly what to do first (close L0/L1 gaps), next (reach
  L3 on priority domains), and later (measurement and automation to L4/L5).
- **Defensible to auditors and to budget.** The scorecard and roadmap are evidence-based artifacts that
  justify both the current posture and the investment ask.
- **Repeatable.** Re-run the same model each quarter to show the maturity trend and prove progress.

## Limitations (be honest with buyers)
- **Licensing gates several domains.** Insider Risk, Communication Compliance, Audit Premium, DSPM, and
  advanced eDiscovery require Microsoft 365 E5 or the E5 Compliance add-on; some DSPM/AI features are in
  preview. Absent licensing caps a domain's *achievable* level — the Requirements Guide names it, and
  the assessment flags "verify your licensing/tenant" rather than inventing availability.
- **The assessment is technical, not regulatory.** It scores the *capability's maturity*. Whether a
  retention schedule, records file plan, legal hold, or insider-risk/communication-compliance case
  action is *correct for your obligations* is a **records / compliance / privacy / legal
  determination**, deferred to those functions. The assessment provides the technical method and
  evidence, not the determination.
- **Insider Risk and Communication Compliance are HR/privacy-sensitive.** Their scoring emphasizes
  privacy-by-design, pseudonymization where applicable, and strict role separation; outcomes are
  deferred to HR/legal.
- **Scores reflect configuration, not user behavior.** A domain at L3 is configured and enforced; it
  does not by itself prove users comply — that is what ongoing D6 Audit and D4/D5 monitoring measure.

## The standard deployment model
> **Assess (evidence discovery) → Score (rubric) → Design (target levels + roadmap) → Configure
> quick-win baseline → Pilot in simulation/test → Validate → Expand (enforce).** The house pattern:
> **Assess → Design → Configure → Pilot (simulate) → Validate → Expand**, with explicit pass/fail
> gates, any high-impact change piloted before enforcement, and a documented rollback.


---


# 2. Requirements Guide — Microsoft Purview Maturity Assessment

Verify **every** requirement before scoring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (read that
first — this guide adds the assessment-specific prerequisites and does not repeat the six).

## 2.1 Read access across the Purview compliance estate (least-privilege)
**Description:** An admin account with the least-privilege roles needed to **read** every domain the
model scores — for example **Global Reader** or **Compliance Administrator** for the portal, plus the
role groups that expose each solution (Information Protection Reader, DLP, Records Management, Insider
Risk, Communication Compliance, Audit, eDiscovery reader roles). The assessment is read-first; write
access is only needed for the optional quick-win baseline.
**Why:** Purview uses fine-grained role groups; a domain the account cannot read will score falsely as
`L0 Absent`. The score must reflect what exists, not what the account can see.
**Verify:** Purview portal → **Settings → Roles and scopes → Role groups**; confirm membership. Run
`PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck` — it reports which domains the account can read.
**Implement:** Add the account to **Global Reader** / **Compliance Administrator** and the per-solution
reader roles under change control. Reserve write roles for the remediation step only.

## 2.2 Licensing inventory (what caps each domain's achievable level)
**Description:** A confirmed record of the tenant's compliance licensing — E3 / Business Premium
baseline vs **Microsoft 365 E5** or the **E5 Compliance** add-on — because several domains
(D4 Insider Risk, D5 Communication Compliance, D6 Audit **Premium**, D8 DSPM, D7 advanced eDiscovery)
are **plan-gated** and some DSPM/AI features are **preview**.
**Why:** A domain that is absent only because it is *unlicensed* is a different finding from one that is
*licensed but unconfigured*. The scorecard distinguishes the two; the roadmap must not recommend
enforcing a capability the tenant cannot license.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; run `PURVIEW-Discovery.ps1` which
flags licensing signals per domain. Where a signal is ambiguous, the report marks it
**"verify your licensing/tenant."**
**Implement:** Record the current plan and add-ons. Do **not** assume E5 — confirm it. If a domain is
unlicensed, mark its ceiling and note the license as a roadmap dependency, not a config task.

## 2.3 The maturity model, target levels, and domain weighting agreed
**Description:** Agreement, before scoring, on the model to use (`Purview Maturity Model - 10 Domains x
6 Levels`), the **target level** for each domain (not every org needs L5 everywhere), and the
**weighting** each domain carries in the overall band.
**Why:** A score is only meaningful against a target. Regulatory-driven organizations weight
D3 (records), D6 (audit), and D7 (eDiscovery) higher; IP-sensitive ones weight D1/D2. Without agreed
targets and weights the roadmap has no destination.
**Verify:** A one-page model exists listing the ten domains, each domain's target level, and its
weight. Stakeholders (below) have signed off.
**Implement:** Adopt the model in this solution as the default, then adjust targets/weights with the
compliance, security, and records owners before scoring.

## 2.4 Evidence scope — workloads and data sources in scope
**Description:** The workloads the assessment reads for evidence — Exchange, SharePoint, OneDrive,
Teams, endpoints/devices, and (for D9) the broader data estate registered in the Data Map — and any
that are explicitly **out of scope** for this round.
**Why:** Domain scores key off configured scope; a DLP policy that covers only Exchange should not
score the same as one covering all five workloads. Excluding a workload silently would inflate scores.
**Verify:** Confirm the in-scope workloads with stakeholders; `PURVIEW-Discovery.ps1` reports per-domain
scope coverage.
**Implement:** Define the in-scope workloads and data sources before running discovery; record any
exclusions so the scorecard notes them.

## 2.5 Compliance, records, privacy & legal stakeholders engaged
**Description:** Named owners from **compliance, records management, privacy, security, HR, and legal**
who set the target levels, own the regulated domains, and receive the readout.
**Why:** Target levels and the roadmap's priorities are business/regulatory decisions, not technical
defaults. D4 Insider Risk and D5 Communication Compliance are HR/privacy-sensitive — their scoring and
any remediation require HR/legal involvement and strict role separation.
**Verify:** Named owners exist per regulated domain; the readout distribution list is agreed.
**Implement:** Identify the owners and capture their target levels before scoring; route D4/D5 findings
to HR/legal, never actioned by IT alone.

## 2.6 Security & Compliance PowerShell + Graph toolchain
**Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, using a modern-auth / MFA-capable
admin — the toolchain the assessment scripts run through.
**Why:** Discovery, scoring, validation, and reporting are delivered as PowerShell; the evidence is
read through these modules.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; run
`PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`.
**Implement:** Install `ExchangeOnlineManagement` and `Microsoft.Graph`; confirm modern-auth sign-in
before running the scripts. Never store credentials in the scripts.

## 2.7 A pilot scope and change control (for quick-win remediation only)
**Description:** A **pilot scope** (a Microsoft Entra security group, `Purview - Pilot Users`) and a
**change-control** process, needed only if the assessment proceeds to apply a quick-win baseline. Every
Purview policy the baseline touches supports a **simulation / test / disabled** mode that MUST be used
before enforcement.
**Why:** The assessment itself is read-only, but its recommended quick wins (a starter label, a DLP
policy in test, enabling audit) are configuration changes and follow the house pilot-first model.
**Verify:** Entra → **Groups** — `Purview - Pilot Users` exists; a change window/approver is named. Run
`PURVIEW-Set-ScopeTargeting.ps1` to create/confirm the group.
**Implement:** Build the pilot group with `PURVIEW-Set-ScopeTargeting.ps1`; agree change control before
`PURVIEW-Remediation.ps1` is run with `-Commit`.

---
## Checklist
- [ ] Least-privilege read access across all ten domains — `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`
- [ ] Licensing inventory captured (E3/BP vs E5 / E5 Compliance; preview flags) — `PURVIEW-Discovery.ps1`
- [ ] Maturity model adopted; per-domain target levels + weighting agreed
- [ ] Evidence scope (workloads/data sources) defined; exclusions recorded
- [ ] Compliance / records / privacy / HR / legal owners named; D4/D5 routed to HR/legal
- [ ] S&C PowerShell + Graph toolchain working — `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`
- [ ] Pilot group `Purview - Pilot Users` + change control (quick-win remediation only)


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


# 3. Implementation Guide — Microsoft Purview Maturity Assessment

Follow these steps **in order**. The assessment runs mostly in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and in **Security & Compliance PowerShell** / **Microsoft Graph**;
the optional quick-win baseline (Steps 7–9) makes changes and is **piloted in simulation/test first**.

> **Model:** Gather evidence across all ten domains (Assess), score against the rubric (Score), agree
> target levels and sequence the gaps (Design), apply any quick-win baseline in simulation/test
> (Configure → Pilot), validate, then expand/enforce. Pattern: Assess → Design → Configure → Pilot
> (simulate) → Validate → Expand.

The named objects below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Maturity model (rubric) | `Purview Maturity Model - 10 Domains x 6 Levels` |
| Scored output | `Purview Maturity Scorecard` |
| Roadmap | `Purview Maturity Roadmap - 3 Horizons` (Now 0–3 mo · Next 3–6 mo · Later 6–12 mo) |
| Pilot scope group | `Purview - Pilot Users` |
| Quick-win baseline (piloted in test) | `Sensitivity Label - Confidential - Baseline`, `DLP Policy - Baseline PII - Test`, unified audit enabled |

## Step 1 — Confirm the model, targets, and weighting (Design)
1. Adopt `Purview Maturity Model - 10 Domains x 6 Levels` (Solution Overview) as the default.
2. With the compliance, security, records, HR, and legal owners, set each domain's **target level**
   (L0–L5) and its **weight** in the overall band. Record this one-pager — it is Requirement 2.3.
3. Note any domain whose ceiling is capped by licensing (Requirement 2.2) so the roadmap treats the
   license as a dependency, not a config task.

## Step 2 — Verify read access and health (Assess)
1. Run `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`.
2. Confirm it reports successful `Connect-IPPSSession` / `Connect-MgGraph`, the account's roles, and
   which domains are **readable**. A domain the account cannot read must be fixed (Requirement 2.1)
   before scoring, or it will false-score as `L0 Absent`.
3. **Pass/fail:** all ten domains readable, or a documented reason (licensing/role) for each that is
   not.

## Step 3 — Gather evidence across all ten domains (Assess)
1. Run `PURVIEW-Discovery.ps1`. It inventories, per domain:
   - **D1** sensitivity labels + label/auto-labeling policies (`Get-Label`, `Get-LabelPolicy`,
     `Get-AutoSensitivityLabelPolicy`)
   - **D2** DLP policies and their mode (test vs enforce) (`Get-DlpCompliancePolicy`)
   - **D3** retention labels/policies and records config (`Get-ComplianceTag`,
     `Get-RetentionCompliancePolicy`)
   - **D4** insider-risk policy presence (portal signal — HR/legal-gated; presence only, no case data)
   - **D5** communication-compliance policy presence (portal signal — HR/legal-gated; presence only)
   - **D6** unified audit log on/off and Audit Premium signal (`Get-AdminAuditLogConfig` /
     `Get-OrganizationConfig` where available)
   - **D7** eDiscovery cases/holds presence (`Get-ComplianceCase`)
   - **D8** DSPM presence/recommendations signal (portal / Graph where available — flag preview)
   - **D9** Data Governance / Unified Catalog registration signal (Graph where available)
   - **D10** Compliance Manager assessments/score signal (portal / Graph where available)
2. Where an API or portal path is uncertain or plan-gated, the report marks the domain
   **"verify your licensing/tenant"** rather than asserting a value.
3. **Pass/fail:** the discovery output lists a signal (or an explicit "unreadable/unlicensed") for each
   of the ten domains.

## Step 4 — Score each domain against the rubric (Score)
1. Run `PURVIEW-MaturityScore.ps1`. It applies the model's per-domain rubric to the discovery evidence
   and emits the `Purview Maturity Scorecard`. The rubric, applied uniformly to every domain:

   | Level | Evidence signal (generalized) |
   |---|---|
   | L0 Absent | Capability not present / not licensed |
   | L1 Initial | Present but ad hoc — objects exist with no policy scope, owner, or documentation |
   | L2 Developing | Basic config piloted in **test/simulation**, limited scope (one workload / pilot group) |
   | L3 Defined | Standardized and **enforced** at meaningful scope, documented, owner assigned |
   | L4 Managed | Measured/reported, tuned on metrics, integrated (e.g. audit→SIEM), reviewed on a cadence |
   | L5 Optimized | Automated, continuously improved, org-wide, evidence-driven |

2. Each domain gets a 0–5 score **with the specific signal behind it** (e.g. "D2 = L2: one DLP policy,
   Exchange-only, in Test mode"). The overall band is the **weighted average** of the ten domain
   scores, mapped to the same L0–L5 labels.
3. Domains capped by licensing are scored against their **achievable** ceiling and flagged, so the
   overall band is not unfairly depressed by an unlicensable capability.
4. **Pass/fail:** every domain has a score and an evidence sentence; the overall band is computed.

## Step 5 — Build the roadmap (Design)
1. From the scorecard, sequence each domain's gap (current → target) into
   `Purview Maturity Roadmap - 3 Horizons`:
   - **Now (0–3 mo):** close `L0`/`L1` gaps and quick wins — enable audit, publish a baseline label,
     stand up a DLP policy in **test** mode, turn on Compliance Manager.
   - **Next (3–6 mo):** raise priority domains to **L3** — enforce after a clean pilot, document, assign
     owners.
   - **Later (6–12 mo):** reach **L4/L5** — measurement, SIEM integration, automation, org-wide scope.
2. Mark D4/D5 items as **HR/legal-gated** and any regulated retention/records/hold item as a
   **compliance/records/legal determination** — the roadmap lists the technical step, not the
   determination.
3. **Pass/fail:** every below-target domain appears in exactly one horizon with a named owner.

## Step 6 — Executive readout (Design)
1. Run `PURVIEW-MaturityScore.ps1 -EvidencePath .\purview-evidence.json -CsvPath .\scorecard.csv` to
   render and export the scorecard (per-domain scores + overall band); pair it with the roadmap
   horizons for the readout deck.
2. Present current state, target state, and the sequenced next steps to the stakeholders from
   Requirement 2.5. Get sign-off on the roadmap before any configuration.

> Steps 7–10 are **optional** — run them only when the roadmap's *Now* horizon calls for a quick-win
> baseline and change control (Requirement 2.7) is approved. The assessment itself ends at Step 6.

## Step 7 — Prepare the pilot scope (Configure)
1. Run `PURVIEW-Set-ScopeTargeting.ps1` to create/confirm the Entra group `Purview - Pilot Users` and
   add the agreed pilot members.
2. **Pass/fail:** the group exists and contains the pilot users.

## Step 8 — Apply the quick-win baseline in SIMULATION/TEST (Configure → Pilot)
1. Run `PURVIEW-Remediation.ps1` **without** `-Commit` first (default `-WhatIf`) to preview exactly what
   it would create/enable. Review the plan.
2. Run `PURVIEW-Remediation.ps1 -Commit` to apply only the approved quick wins, all in
   **non-enforcing** mode:
   - **Enable the unified audit log** (D6) if off — low-risk, read-enabling, reversible.
   - Publish `Sensitivity Label - Confidential - Baseline` and its label policy scoped to
     `Purview - Pilot Users` (D1) — no auto-labeling on yet.
   - Create `DLP Policy - Baseline PII - Test` in **Test mode** (audit only, policy tips) scoped to the
     pilot (D2) — **not** enforce.
   - Turn on **Compliance Manager** (D10) if not initialized.
3. The script **never** enables enforce, auto-labeling out of simulation, insider-risk actions, or any
   retention-deletion policy — those are roadmap *Next/Later* items requiring their own change and
   (for D3/D4/D5) a records/HR/legal determination.
4. **Pass/fail:** the named baseline objects exist in **test/simulation/disabled** mode, scoped to the
   pilot only.
5. **Rollback:** disable/delete the baseline label policy, set `DLP Policy - Baseline PII - Test` off,
   and (if it was off before) leave audit as-is per the change ticket. `PURVIEW-Remediation.ps1` records
   what it created so it can be reverted.

## Step 9 — Validate the baseline (Validate)
1. Run `PURVIEW-Validation.ps1`. It confirms the baseline objects exist, are in **test/non-enforcing**
   mode, and are scoped to `Purview - Pilot Users`, and re-checks the domain gates.
2. Complete the Testing Guide against the pilot.
3. **Pass/fail:** validation reports every expected baseline object present and non-enforcing.

## Step 10 — Re-assess and expand (Validate → Expand)
1. Re-run `PURVIEW-Discovery.ps1` → `PURVIEW-MaturityScore.ps1` to show the scorecard moving (the quick
   wins should lift D1/D2/D6/D10 from L0/L1 toward L2).
2. Expansion (enforcing DLP, auto-labeling out of simulation, records/retention, insider risk) is the
   roadmap's *Next/Later* work — each is its own piloted, change-controlled project, with regulated
   determinations deferred to the relevant governance function.
3. Schedule the next assessment (e.g. quarterly) to track the maturity trend.

---
### Order of operations
`Model + targets → health/read check → cross-domain discovery → score (rubric) → roadmap (3 horizons) → readout → [optional] pilot scope → quick-win baseline in test → validate → re-assess/expand`


---


# 5. Testing Guide — Microsoft Purview Maturity Assessment

Run these after each stage: discovery and scoring (Implementation Steps 3–4), the roadmap and readout
(Steps 5–6), and — if the quick-win baseline is applied — the pilot (Steps 8–9) and re-assessment
(Step 10). The assessment tests verify the **method produced defensible, evidence-backed output**; the
baseline tests verify the quick wins landed **non-enforcing and scoped to the pilot**.

## Test 1 — Read access and health confirmed
**Do:** Run `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`.
**Expected:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; the account's roles are listed; all
ten domains report **readable** (or a documented licensing/role reason for any that are not). No domain
silently unreadable.

## Test 2 — Cross-domain evidence gathered
**Do:** Run `PURVIEW-Discovery.ps1`.
**Expected:** A signal (or an explicit "unreadable/unlicensed / verify your licensing-tenant") for each
of the ten domains D1–D10 — no domain missing from the inventory.

## Test 3 — Scorecard is complete and evidence-backed
**Do:** Run `PURVIEW-MaturityScore.ps1`; open the `Purview Maturity Scorecard`.
**Expected:** Every domain has a 0–5 score **and** a one-line evidence sentence behind it (e.g.
"D2 = L2: one DLP policy, Exchange-only, Test mode"). The overall band equals the weighted average of
the ten scores. Licensing-capped domains are flagged, not silently zeroed.

## Test 4 — Scores match the rubric (spot-check)
**Do:** Pick two domains — one configured, one absent — and compare their score to the rubric in
Implementation Step 4.
**Expected:** The absent domain scores `L0`; the configured domain's level matches its evidence (e.g.
enforced + documented + owned = `L3`; test-mode pilot only = `L2`). No score exceeds what the evidence
supports.

## Test 5 — Roadmap covers every gap
**Do:** Review `Purview Maturity Roadmap - 3 Horizons` against the scorecard.
**Expected:** Every domain below its target appears in exactly one horizon (Now / Next / Later) with a
named owner; D4/D5 items are marked HR/legal-gated; regulated retention/records/hold items are marked
as compliance/records/legal determinations, not IT tasks.

## Test 6 — Readout renders
**Do:** Run `PURVIEW-MaturityScore.ps1 -EvidencePath .\purview-evidence.json -CsvPath .\scorecard.csv`.
**Expected:** A readable scorecard (per-domain scores + overall band) printed and exported to CSV —
suitable, alongside the `Purview Maturity Roadmap - 3 Horizons`, for the stakeholder readout.

> Tests 7–9 apply only if the quick-win baseline (Implementation Steps 7–9) was run.

## Test 7 — Baseline created non-enforcing and pilot-scoped
**Do:** Run `PURVIEW-Validation.ps1` (or inspect the objects in the portal).
**Expected:** `Sensitivity Label - Confidential - Baseline` + its label policy, and
`DLP Policy - Baseline PII - Test`, exist scoped to `Purview - Pilot Users`; the DLP policy is in
**Test mode** (not enforce); no auto-labeling is turned on out of simulation.

## Test 8 — Audit enabled (if it was off)
**Do:** After remediation, run `PURVIEW-Discovery.ps1` and check the D6 signal (or Purview → **Audit**).
**Expected:** The unified audit log reports **on**; searches begin returning events (allow time to
populate).

## Test 9 — Re-assessment shows movement
**Do:** Re-run `PURVIEW-Discovery.ps1` → `PURVIEW-MaturityScore.ps1`.
**Expected:** The domains touched by the quick wins (typically D1/D2/D6/D10) move up from L0/L1 toward
L2; no domain regresses; the overall band reflects the change.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Assessment pass** | Tests 1–6 pass — every domain readable or documented, scored with evidence, roadmapped with owners, readout rendered |
| **Baseline pass** | Tests 7–8 pass — quick-win objects present, **non-enforcing**, pilot-scoped; audit on |
| **Trend pass** | Test 9 passes — re-assessment shows the intended domains moving up, none regressing |


---


# 6. Troubleshooting Guide — Microsoft Purview Maturity Assessment

Use `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck` for connectivity/role/readability, `PURVIEW-Discovery.ps1`
for the raw evidence, `PURVIEW-MaturityScore.ps1` to re-score, `PURVIEW-Validation.ps1` to confirm the
quick-win baseline, and `PURVIEW-Remediation.ps1` (default `-WhatIf`) for safe baseline fixes.

## A. A domain scores L0 Absent but you know it is configured
| Symptom | Cause | Remediation |
|---|---|---|
| Domain shows `L0` / "unreadable" | The assessment account lacks the reader role for that solution | Run `-HealthCheck`; add the missing per-solution reader role (Requirement 2.1), then re-run Discovery + Score |
| A whole domain missing from Discovery | Cmdlet not available (module/plan) | Confirm licensing (Requirement 2.2); some cmdlets (`Get-InsiderRiskPolicy`, `Get-SupervisoryReviewPolicyV2`) require the feature to be licensed/enabled — flagged "verify your licensing/tenant" |
| D8/D9/D10 always L0 | These are portal/preview-surfaced, not fully cmdlet-readable | Verify DSPM, Data Map, and Compliance Manager in the Purview portal and set those scores manually per the rubric |

## B. Scores look too high or too low
- **Too high:** the rubric caps automated scoring at `L3` for most domains — `L4 Managed` and
  `L5 Optimized` require *measured/reported/automated* evidence the scripts cannot infer. Confirm L4/L5
  manually; do not let a script assert them.
- **Too low from licensing:** a domain absent only because it is unlicensed should be scored against its
  **achievable ceiling** and flagged, not counted as a failure. Record the license as a roadmap
  dependency (Requirement 2.2).
- **Overall band skewed:** check the weighting. Equal weights treat a regulated org's D3/D6/D7 the same
  as everything else — apply your agreed weights (`-Weights @{ D3=2; D6=2; D7=2 }`).

## C. Health check fails to connect
- `Connect-IPPSSession` FAIL: install/update `ExchangeOnlineManagement`; ensure the account is
  modern-auth/MFA-capable and not blocked by conditional access on the workstation.
- `Connect-MgGraph` WARN: install `Microsoft.Graph`; the group-builder and some D8/D9 signals use Graph.
  The core scorecard runs on S&C PowerShell alone.

## D. Evidence file not found when scoring
- `PURVIEW-MaturityScore.ps1` needs the JSON from Discovery. Run
  `PURVIEW-Discovery.ps1 -JsonPath .\purview-evidence.json` first, then
  `PURVIEW-MaturityScore.ps1 -EvidencePath .\purview-evidence.json`.

## E. Quick-win remediation "did nothing"
- That is the **safe default**. `PURVIEW-Remediation.ps1` runs in `-WhatIf` (preview) unless you pass
  `-Commit`. Review the `WOULD:` plan, get readout sign-off and change control, then re-run with
  `-Commit`.
- If `-Commit` reports `SKIP`, the object likely already exists or the account lacks write access —
  check the message and confirm Compliance Administrator write roles.

## F. Baseline DLP shows as enforcing (it must not)
- The baseline is created with `-Mode TestWithNotifications` (audit only). If `PURVIEW-Validation.ps1`
  reports the DLP policy in an `Enable*` (enforce) mode, something enforced it outside this solution —
  set it back with `Set-DlpCompliancePolicy '<name>' -Mode TestWithNotifications`. Enforcement is a
  separate, change-controlled roadmap step, never part of the baseline.

## G. Insider Risk / Communication Compliance (D4/D5) findings
- The assessment reads **presence only** — never case content. If a score or roadmap item implies a
  case action, stop: those are **HR/legal determinations** with strict role separation and
  privacy-by-design. Route the finding to HR/legal; do not action it from IT.

## H. Regulated retention/records/hold items (D3/D7)
- The scorecard measures whether the *capability* exists and is enforced — not whether a retention
  schedule, records file plan, or legal hold is *correct for your obligations*. That is a
  **records/compliance/legal determination**. The roadmap lists the technical step; the owning function
  makes the call.

## I. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession
Get-Label | Select-Object DisplayName, Priority
Get-DlpCompliancePolicy | Select-Object Name, Mode, Enabled
Get-RetentionCompliancePolicy | Select-Object Name, Enabled, Mode
Get-ComplianceCase | Select-Object Name, Status
(Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
```
For DSPM, Data Map, and Compliance Manager, verify in the Purview portal (these are portal/preview-
surfaced — Requirement 2.2).

## J. When to escalate
If a domain is licensed, the account holds the reader role, `-HealthCheck` shows it readable, and the
score still does not match a known-good configuration, capture the output of
`PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`, `PURVIEW-Discovery.ps1`, and
`PURVIEW-MaturityScore.ps1`, and open a Microsoft support case for the affected solution.


---


# 7. Best Practices — Microsoft Purview Maturity Assessment

- **Score from evidence, not opinion.** Drive every domain score from what `PURVIEW-Discovery.ps1`
  actually reads in the tenant, and attach the signal to the score. A maturity number nobody can trace
  to configuration is a survey, not an assessment.
- **Set targets before you score.** Not every organization needs L5 in every domain. Agree each
  domain's target level and weight (`Purview Maturity Model - 10 Domains x 6 Levels`) with the
  compliance, security, and records owners first — a score without a target has no meaning.
- **Separate "unlicensed" from "unconfigured."** A domain absent because it is not licensed is a
  budget/roadmap dependency; one licensed but unconfigured is a config task. Flag licensing-capped
  domains and score them against their achievable ceiling, so the overall band is honest.
- **Flag, don't invent.** Purview is plan-gated and the portal evolves. Where a signal or a portal path
  is uncertain, mark the domain **"verify your licensing/tenant"** rather than asserting a level.
- **Keep the assessment read-only; gate the quick wins.** The scorecard and roadmap require no changes.
  Only run `PURVIEW-Remediation.ps1` after the readout is signed off, always `-WhatIf` first, and only
  ever into **test/simulation/disabled** mode — never straight to enforce.
- **Pilot every quick win.** Baseline objects (`Sensitivity Label - Confidential - Baseline`,
  `DLP Policy - Baseline PII - Test`) go to `Purview - Pilot Users` in non-enforcing mode; enforcement
  is a separate, change-controlled roadmap step.
- **Defer the determinations.** Retention schedules, records file plans, legal holds, and insider-risk
  / communication-compliance case actions are **records / compliance / privacy / legal** decisions.
  Score and roadmap the *technical capability*; route the *determination* to the owning function.
- **Treat D4/D5 as HR/privacy-sensitive.** Score Insider Risk and Communication Compliance on
  presence and privacy-by-design (pseudonymization, role separation) — read only presence, never case
  content, and route findings to HR/legal.
- **Weight for your risk profile.** Regulated organizations weight D3 (records), D6 (audit), and
  D7 (eDiscovery) higher; IP-sensitive ones weight D1/D2. Make the weighting explicit so the overall
  band reflects real priorities.
- **Re-run on a cadence.** The single most valuable output is the **trend**. Re-run the same model each
  quarter; a rising overall band is the proof the program is improving and the budget is working.
- **Document the model, the scores, and the rollback.** Record the domains, targets, weights, each
  score's evidence, the roadmap owners, and the baseline rollback — so the assessment is repeatable and
  defensible under change control and audit.


---


# 8. Deliverables Summary — Microsoft Purview Maturity Assessment

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a Purview maturity assessment is — the 10-domain × 6-level model, scorecard, roadmap — benefits, limitations |
| 2. Requirements Guide | Every assessment-specific prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact ordered steps — evidence discovery, rubric scoring, roadmap, readout, optional pilot baseline |
| 5. Testing Guide | Validation procedures with pass/fail gates (assessment, baseline, trend) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PURVIEW-Discovery.ps1` | Reads the tenant's Purview configuration across all ten domains (D1–D10) as scoring evidence; flags licensing/preview signals and unreadable domains (read-only) |
| `PURVIEW-MaturityScore.ps1` | Applies the `Purview Maturity Model - 10 Domains x 6 Levels` rubric to the discovery evidence and emits the `Purview Maturity Scorecard` — per-domain 0–5 score, evidence sentence, weighted overall band (read-only) |
| `PURVIEW-Validation.ps1` | Confirms the optional quick-win baseline objects exist, are **non-enforcing**, and are scoped to `Purview - Pilot Users`; re-checks domain gates (read-only) |
| `PURVIEW-Remediation.ps1` | Applies only the approved quick-win baseline (enable audit, baseline label, DLP in **Test** mode, Compliance Manager) in simulation/test — default `-WhatIf`; changes only with `-Commit`; never enforces |
| `PURVIEW-Set-ScopeTargeting.ps1` | `-HealthCheck` reports connectivity, roles, and per-domain readability; without it, builds/updates the `Purview - Pilot Users` Entra group |

## What the buyer receives
- The assessment documentation set as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable maturity model, scorecard, and roadmap following the house model:
  **Assess → Design → Configure → Pilot (simulate) → Validate → Expand**, with pass/fail gates, any
  quick win piloted in test before enforcement, and a documented rollback.

## Outcome
A defensible, evidence-based picture of where the Microsoft Purview program stands — a 0–5 score per
domain, a weighted overall maturity band, and a sequenced Now/Next/Later roadmap — with quick wins
piloted and validated, and regulatory/records/legal determinations deferred to the relevant governance
functions. Re-run the same model to prove the trend over time.
