# Deliverables Summary — Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page business framing: the blind-spots + alert-fatigue problem, the ATT&CK-mapped tuned-detection solution, and the boundary (tunes/maps detections, depends on flowing telemetry, leadership sets priority). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how the technology works (rule types, ATT&CK mapping, tuning, watchlists, automation rules, detection-as-code), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (telemetry flowing, authoring/triage roles, Content hub templates, enrichment data, agreed detection priority + false-positive tolerance, a detection-as-code repo, toolchain) — layered on the shared `global-requirements-sentinel-solutions.md` (G1–G7). |
| **Implementation** (`03-implementation.md`) | Exact, ordered build: map coverage + rank gaps, import watchlists, enable a small high-value rule set in low-impact posture, pilot + measure, tune to tolerance, validate, then promote/export/repeat — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates from telemetry-present and a baseline coverage map through enrichment, low-impact pilot, false-positive-within-tolerance, gap-now-covered, and rules-exported-as-code, referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (rule never fires, false-positive flood, missing template, empty MITRE view, watchlist errors, NRT limits, over-tuning, incident flood on promotion, PowerShell/export errors) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Detect-against-a-map, tune-for-trust, pilot-before-trust, enrich-for-precision, detections-as-code, run-it-as-a-program — plus where to go next in the catalog. |

## PowerShell tools (5)

All tools are **read-only or export-only**, authenticate **interactively** (no credentials in code),
and use the **Az** modules (`Az.Accounts`, `Az.SecurityInsights`, `Az.OperationalInsights`),
**Microsoft.Graph** where needed, and **KQL** (via `Invoke-AzOperationalInsightsQuery`) for the
reporting. Government-cloud tenants pass the matching environment — *verify endpoints for your cloud*.

| Script | Type | What it does |
| --- | --- | --- |
| **`SENTRULE-Discovery.ps1`** | Read-only | Inventories the detection surface: enabled analytics rules (with type and MITRE tags), available rule templates from installed Content hub solutions, existing watchlists, and which expected detection tables have recent data. Changes nothing. |
| **`SENTRULE-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as pass/fail lines: watchlists present + referenced, pilot rules enabled with entity mappings, each pilot rule still in low-impact posture (flags premature incident creation), false-positive rate within tolerance, and targeted gaps covered. |
| **`SENTRULE-Report.ps1`** | Read-only | Per-rule tuning report via KQL: alert volume per rule over the window and, from incident dispositions, the **benign / false-positive rate**, plus the top entities driving each rule — the data that decides when a rule is tuned enough to trust. Exports to CSV. |
| **`SENTRULE-Coverage.ps1`** | Read-only | Builds the **MITRE ATT&CK coverage matrix and gap list** from the tactics/techniques of enabled rules, ranks gaps, and exports the matrix to CSV — the map that drives what to enable next. |
| **`SENTRULE-Export.ps1`** | Export-only | **Detection-as-code** export: serializes enabled analytics rules to ARM/JSON (and notes the Sentinel Repositories path) for versioning, review, and reuse across workspaces — write-to-file only, never imports/overwrites live rules. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Watchlists:** `WL-VIPUsers-Tenant`, `WL-AuthorizedAdminIPs-Tenant`, `WL-TerminatedUsers-Tenant`,
  `WL-HighValueAssets-Tenant`
- **Pilot analytics rules:**
  - `Rule-BruteForce-Entra-Pilot` — **T1110** Brute Force (Credential Access), scheduled
  - `Rule-AtypicalTravel-Entra-Pilot` — **T1078** Valid Accounts, scheduled/ML
  - `Rule-NewAdminRole-Entra-Pilot` — **T1098** Account Manipulation (Persistence), NRT
- **Suppression automation rule:** `AR-Suppress-KnownScanners-Pilot`
- **MITRE coverage workbook:** `Workbook-MITRECoverage-Tenant`
- **Detection-as-code repo connection:** `Repo-Detections-Main`

## What this solution deliberately does NOT do

- It does **not** connect data sources or size the workspace — that is the companion *Deploy Microsoft
  Sentinel: Workspace, Data Connectors & Ingestion* solution, which this layer depends on.
- It does **not** let an untrusted rule create incidents — rules pilot in **low-impact posture** and are
  promoted only after the false-positive rate meets the agreed tolerance.
- It does **not** decide your **risk tolerance, alerting priorities, or which techniques are in scope** —
  those are security-leadership determinations; the solution measures coverage/noise to inform them.
- It does **not** claim MITRE ATT&CK coverage is a guarantee — a covered technique means a rule targets
  it, not that every variant is caught.
- It does **not** invent template, NRT, or ATT&CK-mapping facts — where availability may differ by
  tenant/cloud it says **verify in your tenant**.

## How it is delivered

This solution is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation
as a formatted Word document and PDF, plus all five PowerShell scripts, in a single ZIP
(`SENTRULE-Complete-Solution.zip`) — yours to keep and reuse on every rollout.
