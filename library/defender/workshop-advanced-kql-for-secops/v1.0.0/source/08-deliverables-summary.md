# Deliverables Summary — Workshop: Advanced KQL for SecOps

Everything included in this workshop, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page framing: the "alert-limited, can’t-write-the-join" problem, the enablement solution (concepts + labs + runbook + knowledge-check), and the boundary (skills product; adjacent to the Threat Hunting hunt-library; queries the platforms, does not deploy them). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how KQL works (tabular pipeline, the two query surfaces, joins, aggregations, hunt→detection, workbooks), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (advanced-hunting access, telemetry flowing, a Sentinel workspace for the cross-tool labs, a cohort + least-privilege roles, a read-only posture, the toolchain) — layered on the shared `global-requirements-defender.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | The guided labs: assess readiness, create the cohort, load the KQL lab pack, run Labs 1–8 (fundamentals → filtering → aggregation → joins → cross-tool hunting → real hunt → alert-only detection → workbook), then capstone + knowledge-check, then operationalize — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Eight pass/fail gates covering both environment readiness (tables have data, Sentinel reachable) and skills landed (joins/aggregations unaided, alert-only detection, saved set + workbook, knowledge-check passes), referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (empty tables, schema drift, join errors, cross-tool confusion, detection not alert-only, connection/permission errors) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Write-readable-KQL, hunt-on-a-question, know-your-two-surfaces, turn-hunts-into-durable-coverage-carefully, run-it-as-a-program — plus where to go next in the catalog. |

## Lab pack + PowerShell helpers (5)

All helpers are **read-only**, authenticate **interactively** (no credentials in code), and use
**Microsoft.Graph** (security — advanced hunting via `runHuntingQuery`) and, for the Sentinel labs,
**Az**. Government-cloud tenants pass the matching environment — *verify endpoints for your cloud*.

| File | Type | What it does |
| --- | --- | --- |
| **`WSKQL-Labs.kql`** | KQL lab pack | The runnable, progressive query library — one labeled section per lab (fundamentals, filtering, aggregation, joins, cross-tool, real hunt, detection candidate, workbook query) plus the capstone. The core take-home artifact. |
| **`WSKQL-Discovery.ps1`** | Read-only | Inventories readiness: which Defender XDR tables have recent data, whether a Sentinel workspace is reachable, and the cohort-group membership. Changes nothing. |
| **`WSKQL-RunLab.ps1`** | Read-only | Runs a chosen lab query (`-Lab <n>`) from the pack via Graph and returns the rows — so learners can execute a lab from PowerShell as well as the portal. |
| **`WSKQL-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines and scores the knowledge-check `Check-KQLLab-Pilot`: readiness, lab queries resolve, detection alert-only, saved set + workbook present. |
| **`WSKQL-Report.ps1`** | Read-only | Reports cohort progress and lab-result summaries (rows returned per lab, knowledge-check scores); exports to CSV. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Learner cohort group:** `Grp-KQLWorkshop-Cohort`
- **Shared saved-query set:** `Hunt-KQLLab-Pilot`
- **Custom detection (capstone):** `Detect-KQLLab-Pilot` (alert-only)
- **Workbook (lab):** `Workbook-KQLLab-Pilot`
- **Knowledge-check:** `Check-KQLLab-Pilot`

## What this workshop deliberately does NOT do

- It does **not** deploy or reconfigure the platforms — onboarding Defender XDR, connecting Sentinel,
  and licensing the pillars are the **Defender XDR onboarding / Sentinel deployment / per-pillar**
  catalog solutions. This workshop **queries** them.
- It does **not** replace the **Threat Hunting hunt-library** solution — that delivers and operates a
  curated hunt *program*; this builds the *skill* and ships a *learning* lab pack (adjacent, not
  duplicate).
- It does **not** take response actions — labs are **read-only**, the capstone detection is
  **alert-only**, and any real finding routes to the SOC’s normal incident process.
- It does **not** decide **which detections to promote or acceptable false-positive rates** — those
  are security-leadership determinations; the workshop provides the skill, the labs, and the data.
- It does **not** invent schema, licensing, or preview facts — where availability may differ by
  tenant/cloud (Sentinel, table schemas, plan-gated features) it says **verify in your tenant**.

## How it is delivered

This workshop is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the
documentation as a formatted Word document and PDF, plus the KQL lab pack and all four PowerShell
helpers, in a single ZIP (`WSKQL-Complete-Solution.zip`) — yours to keep and re-run for every new
cohort.
