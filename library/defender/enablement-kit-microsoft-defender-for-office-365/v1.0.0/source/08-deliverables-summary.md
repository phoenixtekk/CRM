# Deliverables Summary — Enablement Kit: Microsoft Defender for Office 365

Everything included in this enablement kit, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page framing: the "email-security bought and under-driven" problem, the enablement solution (concepts + labs + runbook + knowledge-check), and the boundary (skills product; read-only/preview-first; inspects but does not reconfigure the prevention stack; cross-references the Plan 2 implementation and Mail Hygiene solutions). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how MDO works (prevention vs post-delivery, Threat Explorer, the protection stack, Attack Simulation Training, AIR, email advanced hunting), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (Plan 1-vs-2 feature availability, the prevention stack to inspect, a consented lab user group, a simulation/communications note, split read/hunt vs instructor roles, a read-only/preview/approval posture, the toolchain) — layered on the shared `global-requirements-defender.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | The guided labs: assess readiness, create the cohort + lab user group, load the KQL lab pack, run Labs 1–8 (console/email-security model → Threat Explorer → inspect the protection stack → benign simulation → email hunting → AIR held for approval → alert-only detection → reporting/user-risk), then capstone + knowledge-check, then hand off to the implementation solution — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates covering environment readiness (Plan 2 features, protection stack, email tables) and skills landed (simulation reported, email hunting returns, AIR pending-not-auto-applied, alert-only detection, knowledge-check), referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (Explorer missing, sim blade absent, empty email tables, schema drift, AIR auto-deleting, no pending actions, sim not delivered, detection not alert-only, beta API empty, connection errors) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Hunt-on-a-question, understand-the-stack-then-let-the-right-solution-change-it, simulate-to-measure-not-punish, automate-only-when-trusted, turn-hunts-into-durable-coverage, run-it-as-a-program — plus where to go next in the catalog. |

## Lab pack + PowerShell helpers (5)

All helpers are **read-only or preview-first**, authenticate **interactively** (no credentials in
code), and use **Microsoft.Graph** (security — advanced hunting via `runHuntingQuery`; attack-sim
**beta** reporting where available) and, where used, **Exchange Online / Security & Compliance**.
Government-cloud tenants pass the matching environment — *verify endpoints for your cloud*.

| File | Type | What it does |
| --- | --- | --- |
| **`WSMDO-Labs.kql`** | KQL lab pack | The runnable, progressive email query library — one labeled section per hunting lab (post-delivery clicks, sender/subject campaign, bad-attachment hash, delivered-then-detected) plus the capstone candidate. The core take-home artifact. |
| **`WSMDO-Discovery.ps1`** | Read-only | Inventories readiness: Plan 2 presence, email-table freshness (`EmailEvents` etc.), lab-group membership, and the Action center pending posture. Changes nothing. |
| **`WSMDO-RunLab.ps1`** | Read-only | Runs a chosen email hunting-lab query (`-Lab <n>`) from the pack via Graph and returns the rows — so learners can execute a lab from PowerShell as well as the portal. |
| **`WSMDO-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines and scores the knowledge-check `Check-MDOLab-Pilot`: readiness, email tables have data, hunting resolves, AIR pending, detection alert-only. |
| **`WSMDO-Report.ps1`** | Read-only | Reports cohort progress, per-lab email-data availability, and (where the API allows) the attack-simulation user-risk picture; exports to CSV as enablement kit evidence. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Learner cohort group:** `Grp-MDOEnablement Kit-Cohort`
- **Lab user group:** `Grp-MDO-LabUsers-Pilot`
- **Explorer saved view:** `Explorer-MDOLab-Pilot`
- **Shared saved-query set:** `Hunt-MDOLab-Pilot`
- **Simulation (lab):** `Sim-MDOLab-Pilot`
- **Training assignment:** `Training-MDOLab-Pilot`
- **Custom detection (capstone):** `Detect-MDOLab-Pilot` (alert-only)
- **Knowledge-check:** `Check-MDOLab-Pilot`

## What this enablement kit deliberately does NOT do

- It does **not** configure the prevention stack — anti-spam/-malware/-phishing, Safe Links, Safe
  Attachments, and mail-flow hygiene are the **Mail Hygiene** solution. This enablement kit **inspects** them.
- It does **not** perform the operational post-delivery rollout — turning the features on org-wide,
  tuning AIR automation, and running gated production remediation is the **Defender for Office 365
  (Plan 2)** implementation solution. This enablement kit builds the **skill**.
- It does **not** execute production remediation — AIR stays **approval-required**, remediation is
  **previewed only**, Explorer take-action is **not** performed against production, and the capstone
  detection is **alert-only**.
- It does **not** decide **who to simulate, acceptable click-rate, or the AIR automation level** —
  those are security-leadership / HR-legal determinations; the enablement kit provides the skill, the labs,
  and the data.
- It does **not** invent plan, feature, or schema facts — where availability may differ by plan
  (P1/P2) or cloud (GCC/GCC High) it says **verify in your tenant**.

## How it is delivered

This enablement kit is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the
documentation as a formatted Word document and PDF, plus the email KQL lab pack and all four
PowerShell helpers, in a single ZIP (`WSMDO-Complete-Solution.zip`) — yours to keep and re-run for
every new cohort.
