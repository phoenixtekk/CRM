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
