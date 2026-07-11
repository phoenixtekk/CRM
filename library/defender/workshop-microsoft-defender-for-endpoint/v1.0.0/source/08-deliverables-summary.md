# Deliverables Summary — Workshop: Microsoft Defender for Endpoint

Everything included in this workshop, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page framing: the "onboarded-but-under-driven EDR" problem, the enablement solution (concepts + labs + runbook + knowledge-check), and the boundary (skills product; read-only/preview-first; uses an onboarded MDE, does not deploy it). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how MDE works (EDR model, incident graph & alert story, device timeline, ASR, Live Response, response actions, endpoint advanced hunting), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (MDE onboarded with devices reporting, P1-vs-P2 plan, a pilot lab device group, split read/hunt vs instructor roles, a read-only posture, the toolchain) — layered on the shared `global-requirements-defender.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | The guided labs: assess readiness, create the cohort + lab device group, load the KQL lab pack, run Labs 1–8 (console/EDR model → investigate an incident → device timeline → endpoint hunting → ASR audit → read-only Live Response → response-action walkthrough → alert-only detection), then capstone + knowledge-check, then operationalize — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates covering environment readiness (MDE onboarded, P2 features) and skills landed (investigate an incident, ASR audit-only, Live Response read-only, alert-only detection, knowledge-check), referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (no devices/empty tables, schema drift, P1-vs-P2 feature gaps, ASR not auditing, Live Response unavailable, detection not alert-only, connection errors) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Investigate-don’t-triage, roll-out-ASR-safely, respond-deliberately-through-approvals, turn-hunts-into-durable-coverage, run-it-as-a-program — plus where to go next in the catalog. |

## Lab pack + PowerShell helpers (5)

All helpers are **read-only or preview-first**, authenticate **interactively** (no credentials in
code), and use **Microsoft.Graph** (security — advanced hunting via `runHuntingQuery`).
Government-cloud tenants pass the matching environment — *verify endpoints for your cloud*.

| File | Type | What it does |
| --- | --- | --- |
| **`WSMDE-Labs.kql`** | KQL lab pack | The runnable, progressive endpoint query library — one labeled section per hunting lab (encoded-PowerShell, process→network correlation, per-device rollup, ASR audit events, logon anomalies) plus the capstone candidate. The core take-home artifact. |
| **`WSMDE-Discovery.ps1`** | Read-only | Inventories readiness: onboarded device count, endpoint-table freshness, and whether Live Response / advanced features are enabled. Changes nothing. |
| **`WSMDE-RunLab.ps1`** | Read-only | Runs a chosen hunting-lab query (`-Lab <n>`) from the pack via Graph and returns the rows — so learners can execute a lab from PowerShell as well as the portal. |
| **`WSMDE-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines and scores the knowledge-check `Check-MDELab-Pilot`: readiness, lab queries resolve, ASR audit-only, detection alert-only. |
| **`WSMDE-Report.ps1`** | Read-only | Reports cohort progress and per-lab data availability (rows returned per lab); exports to CSV as workshop evidence. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Learner cohort group:** `Grp-MDEWorkshop-Cohort`
- **Pilot lab device group:** `Grp-MDE-LabDevices-Pilot`
- **Shared saved-query set:** `Hunt-MDELab-Pilot`
- **ASR lab config (audit):** `ASR-Lab-AuditOnly-Pilot`
- **Custom detection (capstone):** `Detect-MDELab-Pilot` (alert-only)
- **Knowledge-check:** `Check-MDELab-Pilot`

## What this workshop deliberately does NOT do

- It does **not** onboard or tune MDE — that is the **MDE onboarding accelerator** and **optimization**
  catalog solutions. This workshop **uses** an onboarded MDE.
- It does **not** execute production response — Live Response uses **read-only** commands, ASR lab
  rules run in **audit**, the capstone detection is **alert-only**, and response actions are
  **taught and gated**, not fired against production.
- It does **not** decide **which ASR rules to enforce, which detections to promote, or acceptable
  false-positive rates** — those are security-leadership determinations; the workshop provides the
  skill, the labs, and the data.
- It does **not** invent plan, feature, or schema facts — where availability may differ by plan
  (P1/P2) or cloud (GCC/GCC High) it says **verify in your tenant**.

## How it is delivered

This workshop is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the
documentation as a formatted Word document and PDF, plus the endpoint KQL lab pack and all four
PowerShell helpers, in a single ZIP (`WSMDE-Complete-Solution.zip`) — yours to keep and re-run for
every new cohort.
