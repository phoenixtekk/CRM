# 1. Solution Overview — Migration Wave Orchestration, Throttling Management & Post-Migration Validation

## What this solution is
A migration **plan** is not a migration **execution**. This solution is the **tool-agnostic cutover
operations layer** that sits over whatever migration engine the organization has chosen — Google
Workspace Migrate, Google Workspace Migration for Microsoft Exchange (GWMME), BitTitan MigrationWiz,
CloudM Migrate, or another. It does not move data itself; it **orchestrates** the people-and-timing
work around the engine so that cutovers finish clean, with evidence:

- **Wave batching** — turn a flat user list from Microsoft 365 into ordered, sized, dependency-aware
  migration waves (keeping delegates, shared mailboxes, and team members together).
- **Throttling & API-limit management** — plan concurrency and pacing against both the **Microsoft
  Graph** throttling model and the **Google Workspace Admin SDK / API** quotas, so waves finish
  inside their windows without tripping 429/`RESOURCE_EXHAUSTED` throttling on either side.
- **Pre-stage → delta → cutover sequencing** — run the standard three-pass pattern (bulk pre-stage of
  historical data, one or more incremental deltas, then a final delta + cutover at the change window)
  with explicit go/no-go gates.
- **Post-migration validation** — after each wave, verify **item counts, folder/label structure,
  permissions and sharing, mail flow, delegates, and calendar/free-busy** against the source, and
  produce an evidence report per user and per wave.
- **Hypercare issue triage** — track, categorize, and SLA the issues raised in the days after each
  cutover, so the tail of a migration is managed, not fire-fought.

## How it relates to the other migration solutions (positioning)
This solution is deliberately scoped to **cutover operations and validation**, and it complements —
does not duplicate — the other migration solutions in the catalog:

- The **program/plan solution** (M365 → Google Workspace Migration Program & Wave Plan) owns the
  **program-level strategy**: discovery baseline, the overall wave *plan*, tooling strategy,
  coexistence design, and the multi-month operating model. It decides *what* the waves are and *why*.
- The **per-service migration solutions** (Exchange Online → Gmail, SharePoint/OneDrive → Google
  Drive, Teams → Google Chat/Meet) and the **tool-specific solutions** (Google Workspace Migrate,
  GWMME, BitTitan, CloudM) own the **data-movement mechanics** — the engine that actually copies mail,
  files, and chats.
- **This solution** is the hands-on **execution and evidence toolkit** that runs *between* them: it
  takes the plan's waves and the engine's capabilities and turns them into a repeatable cutover
  runbook — batch, throttle-budget, sequence, validate, triage — that any engine can be driven by.
  It is **engine-agnostic on purpose**: the same wave, throttle, validation, and hypercare discipline
  applies whether the bytes are moving through Google's tool or a third party's.

If you are running only one small wave with one engine, the tool's own docs may be enough. This
solution earns its place at **enterprise scale** (tens of thousands of users, many waves, two vendors'
rate limits, and an auditor who wants proof the data arrived).

## How it works — the cutover-operations model
The solution is organized around five operating capabilities, each backed by a Python tool and a named
artifact convention (`<Purpose> – <Scope> – <Stage>`, e.g. `Migration Wave – Finance – Pilot`):

1. **Wave design.** From the discovery user set (exported from Microsoft 365 / Entra ID), build waves
   that (a) fit a target size per wave, (b) keep **dependency clusters together** — a manager and
   their delegates, a shared mailbox and its members, a department that shares Drive content — and
   (c) sequence a **pilot wave first**. Each wave is a named artifact
   (`Migration Wave – <Dept> – <Stage>`) reused everywhere downstream.
2. **Throttling / API-limit budgeting.** For each wave, compute a **throttle budget**: how many
   concurrent migration workers and what pacing keep you under the **Microsoft Graph** per-app/
   per-tenant throttling limits (read side) and the **Google Admin SDK / Drive / Gmail API** quotas
   (write side), plus the practical throughput of the chosen engine. The budget is the input to the
   engine's concurrency settings and to the wave schedule. (Exact current limits differ by API and by
   tenant/licensing — the tool reads Google quota where the API exposes it and applies documented
   Microsoft Graph throttling guidance; **verify current numbers for your tenant and engine version**.)
3. **Sequencing (pre-stage → delta → cutover).** Each wave runs the three-pass pattern with gates:
   **pre-stage** (bulk historical copy, no user impact, runs days ahead), **delta** (incremental
   catch-up passes), then **cutover** (final delta + mail-routing/DNS switch at the change window).
   Each transition has a documented **pass/fail gate** and a **rollback**.
4. **Post-migration validation.** After cutover, validate the wave against the source: item counts by
   folder/label, permission/sharing parity, mail-flow (test messages route correctly and old address
   still resolves during coexistence), delegate access, and calendar/free-busy. Output is a per-wave
   **Validation Report** artifact — the evidence the wave is genuinely done.
5. **Hypercare triage.** For the hypercare window after each cutover, log every user-reported issue
   into a triage tracker (category, severity, SLA, owner), so the post-cutover tail is measured and
   closed against an SLA rather than absorbed as noise.

## Reference model — one wave, end to end
```
        DISCOVERY SET (users, delegates, shared mbx, groups — from M365/Entra)
                                   │
                    ┌──────────────▼───────────────┐
                    │  WAVE BATCHER (tool #2 helper)│  keep clusters together, size, order
                    └──────────────┬───────────────┘
                                   │  Migration Wave – <Dept> – <Stage>
                    ┌──────────────▼───────────────┐
                    │  THROTTLE BUDGET (tool #4)    │  Graph limits ⨯ Google quotas ⨯ engine
                    └──────────────┬───────────────┘
                                   │  concurrency + pacing → engine config
          PRE-STAGE ──► DELTA(s) ──► CUTOVER  (engine moves data; gates between each)
                                   │
                    ┌──────────────▼───────────────┐
                    │  READINESS CHECK (tool #3)    │  is this wave safe to cut over?
                    └──────────────┬───────────────┘
                                   │  GO / NO-GO gate
                    ┌──────────────▼───────────────┐
                    │  VALIDATION REPORT (tool #5)  │  counts · permissions · mail · delegates
                    └──────────────┬───────────────┘
                                   │  evidence
                    ┌──────────────▼───────────────┐
                    │  HYPERCARE TRIAGE (tool #6*)  │  issues logged, SLA'd, closed
                    └──────────────────────────────┘
```
*(The five Python tools are: assessment/discovery, wave batcher, cutover-readiness checker, throttle/
API-limit budget planner, and the validation-report + hypercare-triage helpers — see the Deliverables
Summary for the exact five.)*

## Benefits
- **Cutovers finish clean, with evidence.** Every wave produces a Validation Report — item counts,
  permissions, mail flow, delegates, calendar — so "done" is proven, not asserted.
- **No throttling surprises.** Concurrency and pacing are budgeted against both vendors' real limits
  before a wave starts, not discovered mid-cutover when a 429 storm stalls the move.
- **Repeatable.** The pilot wave proves the runbook; later waves execute the same batch → throttle →
  sequence → validate → triage pattern, so the team stops re-learning the same lessons.
- **Engine-agnostic.** The discipline outlives any one tool — swap engines and the wave, throttle,
  validation, and hypercare layers still apply.
- **Auditable.** Named artifacts and per-wave evidence give security/compliance and the business a
  clean trail that data arrived and access was preserved.

## Limitations and boundaries
- **This is not a migration engine.** It does not copy mail, files, or chats. It orchestrates and
  validates around the engine the organization has chosen; the actual data movement is the engine's
  job (and its own solution/docs).
- **Tool internals are deferred to the vendor.** Deep console screens, exact throughput per SKU,
  licensing, and support for Google Workspace Migrate / GWMME / BitTitan / CloudM live in each
  vendor's own documentation. This solution drives them at the **playbook level** (mappings, CSVs,
  wave schedules, validation) and via their documented API/CSV interfaces where one exists — it does
  **not** invent private console paths or version-specific behavior. Where behavior is version- or
  preview-dependent, the guidance says **"verify for your version."**
- **Current rate limits change.** Microsoft Graph throttling and Google API quotas are adjusted by the
  vendors over time and vary by license/tenant. The throttle planner applies documented models and
  reads live Google quota where exposed, but the operator must **confirm current numbers** for their
  tenant and engine before committing a wave schedule.
- **Coexistence and DNS are high-impact.** Mail-routing and DNS cutover changes affect production mail
  flow; they are made under change control with the rollback documented in the Implementation Guide.

## Deployment model
This solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
**pilot-first**, with explicit pass/fail gates and a documented rollback for every high-impact change
(mail routing, DNS, cutover):
- **Assess** — export and profile the discovery user set; confirm engine, admin access on both sides,
  and validation criteria.
- **Design** — batch the waves, choose sizes/order, and compute the throttle budget per wave.
- **Configure** — apply the throttle budget to the engine, stage the wave's mappings, and prepare the
  validation and triage artifacts.
- **Pilot** — run the **pilot wave** (pre-stage → delta → cutover) end to end; prove the runbook.
- **Validate** — run the Validation Report and clear the gate; only then expand.
- **Expand** — roll the proven runbook wave-by-wave across the estate, triaging hypercare each time.
