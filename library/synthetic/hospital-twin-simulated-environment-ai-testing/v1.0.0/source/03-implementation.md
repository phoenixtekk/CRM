# Build Guide — Implementation

Build the hospital twin by following the house deployment model **Assess → Design →
Generate/Build → Validate → Expand**, pilot-first, with explicit pass/fail gates. Every artifact
is **named** with the `<Purpose> – <Scope> – <Stage>` convention and that exact name is reused in
testing, troubleshooting, and the tools. Do all of this in the **isolated non-production
environment** (global requirement #3). **Never** load real PHI into the twin.

The five Python tools referenced below live in `scripts/`; run any with `--help`. All are
safe-by-default (dry-run where they write).

---

## Stage 1 — Assess

**Goal:** confirm readiness and produce the `Twin Readiness – Pilot – v1` assessment.

1. **Confirm the six global requirements** and the six solution-specific requirements
   (`02-requirements.md`) are met. Record the target model (FHIR/OMOP/native), the pilot AI use
   cases, and the named pilot service line.
2. **Run the readiness assessment tool** against your environment and inputs:
   ```
   python scripts/twin_readiness_assess.py --model fhir --use-cases sepsis-alert \
       --output "Twin Readiness - Pilot - v1.json"
   ```
   It profiles the declared inputs (Python env, target model, synthetic source reachability, AI
   plug-in contract presence, scenario count, reference profile presence, gates presence) and
   writes a readiness score with any blockers. It is **read-only** and writes only the report.
3. **Resolve blockers.** Any `BLOCKER` in the readiness report must be cleared before Stage 2.

**GATE 1 (readiness):** `Twin Readiness – Pilot – v1` shows no blockers and readiness ≥ the agreed
threshold. If not, stop and remediate.

---

## Stage 2 — Design

**Goal:** produce `Hospital Twin Design – Pilot – v1` and the AI plug-in contract.

4. **Define the entity & state model.** List the twin's entities against the target model
   (Patient/person, Encounter/visit, Condition, Medication, Observation/labs+vitals, Order), and
   the operational units for the pilot service line (beds, queues, service line). Keep the pilot
   **narrow** — one service line, one or two AI use cases.
5. **Design the event & workflow dynamics.** Define the events the simulation clock emits
   (admit → order → result → medicate → transfer → discharge) and their timing/queueing. Decide
   the clock granularity (e.g. 1 simulated hour per tick) and the pilot horizon (e.g. 7 simulated
   days).
6. **Author the AI plug-in contract** (`Twin AI Plug-In Contract – Pilot – v1`): input shape,
   output shape, and the isolated invocation mechanism (local callable/adapter or isolated
   endpoint). The twin's harness calls the AI through this contract only.
7. **Initialize and validate the scope config** with the config helper built into the readiness
   tool:
   ```
   python scripts/twin_readiness_assess.py --init-config --model fhir \
       --service-line "pilot-medsurg" --population 500 --seed 42 \
       --out "Twin Scope Config - Pilot - v1.json"
   python scripts/twin_readiness_assess.py --validate-config "Twin Scope Config - Pilot - v1.json"
   ```
   Fill in the AI plug-in contract reference and the in-scope domains, then re-validate until it
   passes. This `Twin Scope Config – Pilot – v1` is read by every later tool.

---

## Stage 3 — Generate / Build

**Goal:** stand up the twin, wire the synthetic feed, implement the scenario suite; prove one
scenario runs end-to-end.

8. **Wire the synthetic data feed** (`Synthetic Feed Binding – Pilot – v1`). Generate or load the
   pilot population from your synthetic source into the target model. Confirm **no real PHI** is
   present — the source is a synthetic generator or a governed synthetic dataset only.
9. **Load the population into the twin.** Point the simulator at the scope config and the feed:
   ```
   python scripts/twin_simulator.py --config "Twin Scope Config - Pilot - v1.json" \
       --feed "Synthetic Feed Binding - Pilot - v1" --dry-run
   ```
   `--dry-run` (default) plans the run and reports population/event counts **without** writing the
   run log. Review the plan.
10. **Author the scenario suite** (`Twin Scenario Suite – Pilot – v1`). For each pilot use case,
    write a scenario file: a starting state selector, an ordered event sequence, and the
    expected/unacceptable AI behavior. Keep them versioned alongside the scope config.
11. **Execute one scenario end-to-end** with the scenario runner + AI plug-in harness, using a
    built-in mock AI adapter first to prove the wiring, then the real AI adapter:
    ```
    python scripts/twin_scenario_runner.py --config "Twin Scope Config - Pilot - v1.json" \
        --scenario "Twin Scenario Suite - Pilot - v1/sepsis-alert.json" \
        --ai-adapter mock --commit
    ```
    `--commit` writes the evaluation record (default is dry-run). The harness advances the twin
    through the scenario's events, invokes the AI at each plug-in point, and captures its outputs.

**GATE 2 (end-to-end):** the twin runs, the scenario executes, and the AI plug-in is invoked and
captured — proven by a non-empty `Twin Evaluation Record – Pilot – v1`. If not, stop
(see `06-troubleshooting.md`).

---

## Stage 4 — Validate

**Goal:** run the pilot evaluation and clear the fidelity, privacy, and scenario gates.

12. **Fidelity & coverage.** Compare the twin's synthetic population and events to the reference
    profile:
    ```
    python scripts/twin_fidelity_report.py --config "Twin Scope Config - Pilot - v1.json" \
        --reference "Twin Reference Profile - Pilot - v1.json" \
        --out "Twin Fidelity Report - Pilot - v1.html"
    ```
    Produces the `Twin Fidelity Report – Pilot – v1` with per-metric distances vs. thresholds and
    a scenario-coverage summary.
13. **Privacy validation.** Run the disclosure-risk checks on the synthetic data feeding the twin:
    ```
    python scripts/twin_privacy_validate.py --config "Twin Scope Config - Pilot - v1.json" \
        --dataset "Synthetic Feed Binding - Pilot - v1" \
        --out "Twin Privacy Validation - Pilot - v1.json"
    ```
    It runs technical checks (exact-match/uniqueness against any reference, quasi-identifier
    k-anonymity, and a real-PHI leakage guard) and reports PASS/FAIL **per check**. The
    **acceptance** of residual disclosure risk is **deferred to the privacy office** — the tool
    supplies evidence, not the determination.
14. **Scenario-based AI evaluation.** Run the full scenario suite against the **real** AI adapter
    and score it:
    ```
    python scripts/twin_scenario_runner.py --config "Twin Scope Config - Pilot - v1.json" \
        --scenario-suite "Twin Scenario Suite - Pilot - v1" --ai-adapter real --commit \
        --out "Twin Evaluation Record - Pilot - v1.json"
    ```

**GATE 3 (acceptance):** all three gates in `Twin Acceptance Gates – Pilot – v1` are met —
fidelity within threshold, every privacy check PASS (with privacy-office acceptance of residual
risk), and the scenario pass-rate ≥ threshold. **Rollback if any gate fails:** stop, retain the
evidence, refine the twin/scenario or defer the AI; nothing has touched production or real PHI, so
rollback is discarding the run's synthetic artifacts.

---

## Stage 5 — Expand

**Goal:** grow the twin only after the pilot passes.

15. **Add scope incrementally.** Clone the pilot design to a new service line — e.g.
    `Hospital Twin Design – Cardiology – v1` with `Twin Scope Config – Cardiology – v1` — adding
    entities, scenarios, and fidelity depth.
16. **Re-validate at each step.** Re-run fidelity, privacy, and scenario gates for the new scope
    (`Twin Fidelity Report – Cardiology – v1`, etc.). Never expand past a failing gate.
17. **Record the twin's provenance.** Keep every scope config, scenario suite, evaluation record,
    and report versioned so any AI evaluation is reproducible and auditable.

**Production note:** passing the twin authorizes **further evaluation**, not production use.
Production authorization for clinical AI is a human decision by the accountable owners, informed by
— not replaced by — the twin's evidence.
