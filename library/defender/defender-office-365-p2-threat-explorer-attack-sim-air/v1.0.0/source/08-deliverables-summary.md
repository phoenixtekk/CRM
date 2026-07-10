# Deliverables Summary — Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & Automated Investigation

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page business framing: the "spam-blocked-then-blind" problem, the post-delivery detect/hunt/simulate/respond solution, and the boundary (post-delivery only; prevention is the companion solution; requires Plan 2). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how the technology works (Explorer/Real-time detections, Attack Simulation Training, AIR, email Advanced Hunting, remediation actions, Action center), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (Plan 2 licensing, the prevention layer already in place, hunt/simulate/remediate roles, a pilot group, a simulation + communications plan, a remediation/AIR-automation posture, the toolchain) — layered on the shared `global-requirements-defender.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | Exact, ordered build: assess Plan 2 readiness, create the pilot group, set AIR approval-required, save the Explorer view + KQL library, stage and pilot a simulation, hold AIR actions for approval, preview a gated remediation, build an alert-only custom detection, validate, then expand — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates from Plan-2-present and table-freshness through simulation-reported, hunting-returns-results, AIR-pending-not-auto-applied, remediation-preview-gated, and custom-detection-alert-only, referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (Explorer missing, sim blade absent, empty email tables, schema drift, AIR auto-deleting, no pending actions, remediation "won't act", sim not delivered, beta API empty, connection errors) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Hunt-on-a-question, simulate-to-measure-not-punish, automate-only-when-trusted, soft-before-hard, make-detections-durable, run-it-as-a-program — plus where to go next in the catalog. |

## PowerShell tools (5)

All tools are **read-only or preview-first**, authenticate **interactively** (no credentials in
code), and use **Microsoft.Graph** (security — advanced hunting via `runHuntingQuery`, and
attack-simulation **beta** reporting where available) and **Exchange Online / Security & Compliance**
where relevant, with **KQL** over the email tables. Government-cloud tenants pass the matching
environment — *verify endpoints for your cloud*.

| Script | Type | What it does |
| --- | --- | --- |
| **`DEFMDOP2-Discovery.ps1`** | Read-only | Inventories Plan 2 readiness: service-plan presence, email Advanced Hunting table freshness (`EmailEvents` etc.), pilot-group membership, and the Action center pending-actions posture. Changes nothing. |
| **`DEFMDOP2-Hunt.ps1`** | Read-only | Runs a curated email Advanced Hunting KQL library (post-delivery clicks, sender/subject campaign, bad-attachment hash) via Graph and returns matching recipients/clicks/attachments — the hunt that feeds a gated remediation preview. |
| **`DEFMDOP2-Report.ps1`** | Read-only | Reports post-delivery threat activity (delivered-then-detected phish/malware) and the Attack Simulation Training user-risk / repeat-offender picture; exports to CSV. |
| **`DEFMDOP2-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines: Plan 2 present, tables have data, pilot simulation reported, hunting resolves, AIR pending (not auto-applied), remediation preview gated, custom detection alert-only. |
| **`DEFMDOP2-Remediate.ps1`** | Preview-first (gated) | Turns a hunt-result CSV into a named remediation batch and **previews** it (`-WhatIf` default, changes nothing); execution is **double-gated** (`-Execute -Confirm`, plus `-IUnderstandHardDelete` for hard-delete) and routed through **Action center approval** — never unattended. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Pilot user group:** `Grp-MDO-Pilot-Users`
- **Explorer saved view:** `Explorer-PostDelivery-Pilot`
- **Simulations:** `Sim-CredHarvest-Pilot` (pilot), `Sim-CredHarvest-Org` (Expand)
- **Training assignment:** `Training-PhishAware-Pilot`
- **Custom detection rule:** `Detect-PostDeliveryPhish-Pilot` (alert-only during pilot)
- **Remediation batch:** `Remediation-PhishBatch-Pilot`

## What this solution deliberately does NOT do

- It does **not** configure anti-spam, anti-malware, anti-phishing, Safe Links, Safe Attachments, or
  mail-flow hygiene — that **prevention** layer is the companion *Microsoft 365 Mail Hygiene:
  Anti-Spam, EOP & Defender for Office 365* solution, which this one depends on and cross-references.
- It does **not** auto-remediate during the pilot — AIR runs **approval-required** and remediation is
  **preview-first and double-gated**; hard-delete is a named-approver-only action.
- It does **not** decide **who to simulate, acceptable click-rate, or the AIR automation level** —
  those are HR/security-leadership determinations; the solution provides the controls and the data.
- It does **not** invent licensing, feature, or schema facts — where availability may differ by
  tenant/cloud (Plan 2 features, attack-simulation beta API, hunting-table schema) it says **verify
  in your tenant**.

## How it is delivered

This solution is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the
documentation as a formatted Word document and PDF, plus all five PowerShell scripts, in a single ZIP
(`DEFMDOP2-Complete-Solution.zip`) — yours to keep and reuse on every rollout.
