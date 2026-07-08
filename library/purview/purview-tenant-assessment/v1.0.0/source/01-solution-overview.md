# 1. Solution Overview — Microsoft Purview Tenant Assessment

## What this solution is
Most organizations turn on Microsoft Purview capabilities one at a time — a DLP policy here, a few
sensitivity labels there, retention when legal asks, Insider Risk after an incident — and nobody ever
steps back to answer the whole-estate question: *across every Purview capability we have enabled, what
is actually configured, where are the gaps, and what should we fix first?* This solution delivers that
**tenant-wide Purview assessment**. It inventories **every enabled Purview capability** — Information
Protection (sensitivity labels), Data Loss Prevention, Data Lifecycle & Records Management (retention),
Insider Risk Management, Communication Compliance, Audit, eDiscovery, Data Security Posture Management
(DSPM & DSPM for AI), Compliance Manager, the Unified Catalog / Data Governance data map, and the
classifiers & sensitive information types underneath them — reads their current configuration
read-only, scores each on coverage and maturity, produces a **prioritized findings register (P1/P2/P3)**
with recommendations, and — where a quick, safe win exists — remediates it **in simulation/test mode
first**, validates, then hands you a defensible baseline. It uses only the **Microsoft Purview portal**,
**Security & Compliance / Exchange Online PowerShell**, and **Microsoft Graph** — no third-party tooling.

## Why this matters
- **Nobody has the full picture.** Config accumulates across teams and years; without a single assessment you can't see that DLP covers email but not Teams, that a label taxonomy exists but was never published, or that a retention policy has been sitting **disabled** for a year. Gaps you can't see, you can't fix.
- **Drift is silent.** Policies get created in enforce mode without a pilot, labels get orphaned, an auto-labeling policy stays stuck in simulation, an Insider Risk policy runs with no reviewers. An assessment surfaces the drift as concrete, evidenced findings — not opinions.
- **Priorities beat activity.** A tenant can have fifty findings; what matters is *which three* to fix this quarter. This solution ranks findings **P1 (critical exposure / enforced-but-risky), P2 (coverage gap / drift), P3 (optimization)** so remediation follows risk, not whoever shouts loudest.
- **The controls are licensing-dependent and the portal evolves.** Many Purview capabilities require **Microsoft 365 E5** or the **E5 Compliance** add-on, and some (DSPM for AI, parts of the Unified Catalog) are in preview or actively changing. The assessment reports **what your tenant actually has enabled and licensed** — it never assumes a capability is present.

## How it works
1. **Preflight the scope.** Confirm licensing, least-privilege roles, and which Purview capabilities are actually enabled/visible in *your* tenant — so the assessment covers what exists, not a generic checklist.
2. **Inventory every enabled capability (read-only).** For each capability, read its configuration: labels & label policies, DLP policies and their mode, retention policies/labels and whether they're enabled, Insider Risk & Communication Compliance policy presence and reviewer/scope hygiene, Audit ingestion state, eDiscovery cases/holds, DSPM coverage, the Compliance Manager score, catalog/data-map state, and the SITs/classifiers in use.
3. **Score and find.** Each capability gets a coverage/maturity read; each concrete gap becomes a **finding** with capability, observation, evidence source, risk, recommendation, and a **priority**. Regulatory/records/legal judgments are recorded as findings **for the relevant governance function to decide** — never decided here.
4. **Prioritize.** Findings roll up into `Purview Assessment – Priorities – P1P2P3` and a per-capability `Purview Assessment – Capabilities – Scorecard` so the readout is a plan, not a data dump.
5. **Remediate the safe wins — simulation first.** Where a finding has a low-risk, high-value fix (e.g. move a bluntly-enforced DLP policy into **simulation/test**, take an auto-labeling policy to **simulation** before enforce, enable a retention policy left disabled, turn on unified audit), the remediation tool applies it **pilot-scoped and in simulation/test/`-WhatIf` first**, never straight to tenant-wide enforce.
6. **Validate and hand over.** Re-check that remediated findings pass their gate, produce the `Purview Assessment – Tenant – Readout`, and hand the register + scorecard to the compliance owners as the standing baseline to track.

## The capabilities this solution assesses
| # | Capability | What the assessment reads |
|---|---|---|
| 1 | **Information Protection** | Sensitivity labels, label policies (published scope), auto-labeling policies + their mode |
| 2 | **Data Loss Prevention (DLP)** | DLP policies + rules, per-workload coverage (Exchange, SharePoint, OneDrive, Teams, Endpoint), policy **mode** (enforce vs test) |
| 3 | **Data Lifecycle & Records Management** | Retention policies & retention labels, **enabled** state, label-policy publication, disposition |
| 4 | **Insider Risk Management** | Policy presence, template/scope, reviewer assignment hygiene (privacy-by-design) |
| 5 | **Communication Compliance** | Policy presence, reviewer groups, scope hygiene |
| 6 | **Audit (Standard/Premium)** | Unified audit ingestion state, retention policies, licensing tier |
| 7 | **eDiscovery (Standard/Premium)** | Compliance cases, hold policies, case hygiene |
| 8 | **Data Security Posture Management (DSPM & DSPM for AI)** | Coverage/enablement (portal-driven; flagged where preview) |
| 9 | **Compliance Manager** | Overall compliance score and improvement-action posture |
| 10 | **Unified Catalog / Data Governance** | Data map/catalog enablement and coverage (flagged where evolving) |
| 11 | **Classifiers & Sensitive Info Types** | Custom SITs, trainable classifiers, EDM schemas in use across the above |

> **Not every capability is enabled or licensed in every tenant.** The assessment reports each as
> **enabled / not enabled / not licensed / portal-only — review manually**, and flags anything it cannot
> read reliably as **"verify your licensing/tenant"** rather than asserting a value.

## What you get out of it
- A **complete, evidenced inventory** of every enabled Purview capability's current configuration.
- A **prioritized findings register** (P1/P2/P3) with a recommendation per finding.
- A **per-capability scorecard** showing coverage/maturity at a glance.
- **Safe remediation of the quick wins** — applied in simulation/test/pilot first, with rollback.
- An **executive readout** the compliance owners can act on and track quarter over quarter.

## Limitations (be honest with buyers)
- **This is an assessment, not a full build-out.** It baselines what exists and safely fixes quick wins; standing up a capability from scratch (e.g. a full DLP program or a records file plan) is a separate implementation engagement. Findings point to those.
- **Capabilities are license-gated and some are preview.** Insider Risk, Communication Compliance, Audit Premium, DSPM for AI, auto-labeling, and parts of the Unified Catalog require **E5 / E5 Compliance** (or are in preview). Where a capability isn't licensed/enabled, the assessment records that fact — it doesn't fabricate a reading. **Verify your licensing/tenant.**
- **Some capabilities are portal-driven with limited/no stable PowerShell surface** (notably Insider Risk configuration, DSPM, Compliance Manager scoring, and the evolving Unified Catalog). For those, the tools read what is reliably readable and otherwise flag **"portal-only — review manually"** with the exact portal location — they never invent a cmdlet.
- **Regulatory, records, and legal determinations are not ours to make.** Whether a retention duration is *correct*, whether a DLP rule *satisfies* a regulation, whether an Insider Risk case *warrants* action — these are **deferred to your compliance, records, privacy, and legal functions**. The assessment provides the technical finding and evidence, not the determination.
- **Insider Risk & Communication Compliance are HR/privacy-sensitive.** The assessment reviews them for **configuration hygiene and role separation only** (privacy-by-design), never case content.

## Naming convention (used in every doc and script)
Every artifact this assessment produces is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Prioritized findings register | `Purview Assessment – Tenant – Findings` |
| Priority matrix (P1/P2/P3) | `Purview Assessment – Priorities – P1P2P3` |
| Per-capability coverage/maturity scorecard | `Purview Assessment – Capabilities – Scorecard` |
| Remediation pilot scope | `Purview Assessment – Remediation Pilot – Stage1` |
| Executive readout | `Purview Assessment – Tenant – Readout` |

## The standard deployment model
> Assess what every enabled capability actually is → design the prioritized findings and target state →
> configure the safe quick-win fixes → **pilot them in simulation/test/`-WhatIf`** on a limited scope
> first → validate the findings clear → expand/track the rest as a governed backlog.
> Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**
