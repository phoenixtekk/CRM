# 3. Implementation Guide

This guide runs the cutover-operations layer end to end following the house model — **Assess → Design →
Configure → Pilot → Validate → Expand** — **pilot-first**, with explicit pass/fail gates and a
documented rollback for every high-impact change. Every artifact is named with the convention
`<Purpose> – <Scope> – <Stage>` and that exact name is reused in testing, troubleshooting, and the
scripts.

**Prerequisites:** complete Section 2 (chosen/connected engine, discovery user set, both-vendor limit
model, read-only service identity, validation criteria, hypercare team + SLA, change window + rollback
authority) and the shared `global-requirements-google.md`.

> **Engine boundary.** Where a step says "configure the engine's concurrency" or "start the pre-stage
> pass," perform that action in your chosen engine (Google Workspace Migrate / GWMME / BitTitan /
> CloudM) **per that vendor's own documentation** — the exact console labels and throughput are the
> vendor's, and are **version-dependent (verify for your version)**. This guide owns the *orchestration*
> around those actions, not the engine internals.

---

## Stage A — Assess (profile the population and the limits)

### A1. Export and profile the discovery user set
1. Obtain the discovery export (Section 2.2) as CSV/JSON.
2. Run the assessment tool to profile it and flag missing attributes:
   ```
   python discovery-profile.py --input discovery-users.csv --report Discovery-Profile-Enterprise-Assess.json
   ```
   Optionally add `--google-directory` to enrich/confirm against the live Google directory (read-only,
   Admin SDK Directory scope).
3. **Artifact:** `Discovery Profile – Enterprise – Assess` (the JSON report). It lists user count, data
   volume distribution, delegate and shared-mailbox clusters, and any rows missing the attributes the
   batcher needs.

### A2. Confirm the throttling / API-limit model
1. In **Google Cloud console → APIs & Services → Quotas**, note the current quotas for the APIs your
   automation and engine use.
2. Review the current **Microsoft Graph** throttling guidance for the resources your engine reads, and
   your engine's documented concurrency guidance.
3. Record these as the input file for the throttle planner. **Confirm current numbers — they change.**

**Gate A (Assess → Design):** the discovery profile has no blocking missing-attribute rows for the
pilot population, and the current limit numbers for both vendors are recorded. If not, remediate the
export or gather the limits before proceeding.

---

## Stage B — Design (batch the waves, budget the throttle)

### B1. Build the wave batches
1. Run the wave batcher against the profiled set:
   ```
   python wave-batcher.py --input discovery-users.csv --max-users 500 --pilot-size 25 \
       --keep-clusters --out waves.csv --report Wave-Plan-Enterprise-Design.json
   ```
   - `--max-users` sizes each wave; `--pilot-size` carves the first, smallest **pilot** wave.
   - `--keep-clusters` keeps delegate groups and shared-mailbox members in the **same** wave.
2. **Artifacts:** one named wave per batch, e.g. `Migration Wave – Pilot – Pilot`,
   `Migration Wave – Finance – Wave 2`, `Migration Wave – Sales – Wave 3`. The pilot wave is always
   **first** and small.

### B2. Compute the throttle budget per wave
1. For each wave, compute concurrency + pacing from the recorded limits:
   ```
   python throttle-planner.py --waves waves.csv --limits limits.json \
       --window-hours 8 --report Throttle-Budget-Enterprise-Design.json
   ```
2. The planner outputs, per wave, a **recommended concurrent-worker count and pacing** that keeps the
   projected request rate under both the Microsoft Graph and Google quota ceilings for the wave's data
   volume and window — plus headroom for `Retry-After` backoff.
3. **Artifact:** `Throttle Budget – <Wave> – Design` (one row per wave in the report).

**Gate B (Design → Configure):** every wave fits its window inside the throttle budget with headroom,
delegate/shared-mailbox clusters are intact, and the pilot wave is the smallest and first. If a wave
cannot fit its window under the limits, split it, widen the window, or request a quota increase — do
**not** raise concurrency past the budget.

---

## Stage C — Configure (apply the budget, stage the artifacts)

### C1. Apply the throttle budget to the engine
1. In the engine, set the concurrency/pacing for the wave to the planner's recommended values (per the
   engine's own docs — **verify for your version**).
2. Stage the wave's user mapping (source → target) in the engine as the engine expects it (its project/
   mapping/CSV format).

### C2. Prepare validation and triage artifacts
1. Load the validation criteria (Section 2.5) as the config for the validation tool.
2. Initialize the hypercare tracker for the wave:
   ```
   python hypercare-triage.py init --wave "Migration Wave - Pilot - Pilot" \
       --sla-config sla.json --store hypercare.json
   ```
3. **Artifacts:** `Validation Criteria – Enterprise – Configure`, `Hypercare Tracker – Pilot – Pilot`.

**Gate C (Configure → Pilot):** engine concurrency matches the budget, the pilot mapping is staged,
validation criteria are loaded, and the hypercare tracker is initialized with the SLA.

---

## Stage D — Pilot (run the pilot wave end to end: pre-stage → delta → cutover)

Run the **three-pass sequence** on `Migration Wave – Pilot – Pilot`. Each transition has a gate.

### D1. Pre-stage pass (no user impact)
1. Start the engine's **pre-stage** (bulk historical copy) for the pilot wave, days ahead of the change
   window. No mail-flow or DNS change happens here.
2. Monitor throttling: confirm the observed request rate stays within the budget and that `Retry-After`
   backoff is not sustained (the throttle planner's `--observe` mode can sample engine/API logs if you
   feed it a rate file).
3. **Gate D1:** pre-stage completes with the engine reporting no unrecoverable errors and throttling
   within budget. If throttling is sustained, lower concurrency to the budgeted value and re-run — do
   not push higher.

### D2. Delta pass(es) (incremental catch-up)
1. Run one or more **delta** passes to catch items created since pre-stage. No user impact yet.
2. **Gate D2:** the last delta completes cleanly and the residual delta size is small enough to finish
   inside the cutover window.

### D3. Cutover (final delta + mail-routing/DNS switch — **change window, high-impact**)
1. **Readiness check** — before touching mail flow, confirm the wave is safe to cut over:
   ```
   python cutover-readiness.py --wave "Migration Wave - Pilot - Pilot" \
       --waves waves.csv --checks readiness.json --report Cutover-Readiness-Pilot-Pilot.json
   ```
   It verifies target accounts exist and are licensed, delegates/shared-mailbox members are all in
   this wave (no split cluster), the pre-stage/delta completed, and coexistence routing is in place.
2. **Go/No-Go gate (Gate D3):** readiness report is all-green and the rollback approver (Section 2.7)
   authorizes. If any check is red, **No-Go** — remediate and re-check.
3. On **Go**, in the change window: run the engine's **final delta**, then switch **mail routing / DNS**
   for the wave per the coexistence design (this is the high-impact change).
4. **Rollback (if the gate fails after the switch):** revert the mail-routing/DNS change to the
   pre-cutover state (restore the prior MX/routing per the change record), leave users on the source,
   and reschedule. Because pre-stage/delta only *copied* data, reverting routing returns the wave to
   the coexistence state with no data loss; document the failure and its cause before retrying.

---

## Stage E — Validate (prove the pilot wave is done)

1. Run the post-migration validation against the pilot wave:
   ```
   python validate-migration.py --wave "Migration Wave - Pilot - Pilot" \
       --source-manifest source-counts.csv --criteria validation-criteria.json \
       --report Validation-Report-Pilot-Pilot.json --html Validation-Report-Pilot-Pilot.html
   ```
   It checks, per user and per wave: **item counts** by folder/label vs. source, **permissions/sharing**
   parity, **mail flow** (test message routes to the target; old address resolves under coexistence),
   **delegate** access, and **calendar/free-busy**.
2. **Artifact:** `Validation Report – Pilot – Pilot`.
3. **Gate E (Validate → Expand):** the Validation Report passes against the agreed criteria (variances
   within tolerance, permissions/mail/delegates/calendar all green). Only a **passing pilot** unlocks
   expansion. Log any failures into the hypercare tracker and resolve before declaring the pilot done.

---

## Stage F — Expand (roll the proven runbook wave by wave)

1. For each subsequent wave (`Migration Wave – Finance – Wave 2`, …), repeat **C → D → E** using the
   already-computed throttle budget and the proven runbook. Do not change concurrency past the budget.
2. **Hypercare each wave.** During the post-cutover window, log every reported issue:
   ```
   python hypercare-triage.py add --wave "Migration Wave - Finance - Wave 2" \
       --summary "Delegate access missing" --severity S2 --owner ops --store hypercare.json
   python hypercare-triage.py report --store hypercare.json --report Hypercare-Report-Finance-Wave2.json
   ```
   The tracker enforces the SLA per severity and reports breaches.
3. **Per-wave gate:** a wave is **not** "done" until its Validation Report passes **and** its hypercare
   queue has no open SLA-breaching issues. Only then start the next wave.
4. **Expansion pacing:** run waves at a cadence the hypercare team's SLA can absorb — do not start a new
   wave while the previous wave's hypercare queue is breaching.

---

## Artifact register (named, reused everywhere)
| Artifact | Created in | Reused in |
|---|---|---|
| `Discovery Profile – Enterprise – Assess` | A1 | B1, testing |
| `Migration Wave – <Scope> – <Stage>` | B1 | C, D, E, F, testing, triage |
| `Throttle Budget – <Wave> – Design` | B2 | C1, D1 |
| `Validation Criteria – Enterprise – Configure` | C2 | E |
| `Hypercare Tracker – <Wave> – <Stage>` | C2 | F |
| `Cutover Readiness – <Wave> – <Stage>` | D3 | Gate D3 |
| `Validation Report – <Wave> – <Stage>` | E | Gate E, audit |
