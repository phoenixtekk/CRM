# Solution Overview

## What this is

A **hospital twin** is a simulated hospital environment — patients, encounters, clinical
workflows, and operational event dynamics — driven entirely by **synthetic (artificial)
clinical data**, in which AI solutions are plugged in and evaluated against defined scenarios
**before** they are trusted anywhere near real patients or production systems. It is the
digital-twin **test harness** that lets AI, QA, and architecture teams assess a clinical AI
solution safely, repeatably, and at low cost.

This solution gives a competent data/platform engineer the exact, ordered steps to design and
build such a twin, wire a synthetic data feed into it, define evaluation scenarios and AI
plug-in points, run a pilot evaluation, and then expand fidelity — plus five Python tools that
do the assessment, simulation, reporting, validation, and configuration work.

The twin is **not** a production system, not a data warehouse, and not a de-identification
service. It is a controlled simulation used for evaluation. Real Protected Health Information
(PHI) is **never** placed into the twin or its AI test runs (see the Synthetic global
requirements and the boundary note below).

## How it works

The twin is composed of four layers, built in order:

1. **Entity & state model** — the simulated population and its objects: patients, encounters,
   conditions, medications, labs/vitals, orders, and the operational units (beds, service lines,
   queues) the twin represents. Modeled against a **target clinical data model** — typically
   **FHIR R4** resources, **OMOP CDM** tables, or the source system's own schema — chosen with
   the AI/QA teams (global requirement #2).
2. **Synthetic data feed** — the source of the population and its records. Either **generated**
   by a synthetic-data engine (e.g. a Synthea-style generator or a commercial platform, integrated
   at the pattern level) or **replayed** from a previously generated, governed synthetic dataset.
   The feed is what makes the twin populated and clinically plausible without real PHI.
3. **Event & workflow dynamics** — the simulation clock that advances the twin: admissions,
   transfers, order placement, result availability, discharges, and the timing/queueing that make
   a scenario behave like a hospital rather than a static table dump.
4. **Scenario & AI plug-in harness** — named, versioned **scenarios** (a defined starting state +
   an event sequence + expected/acceptable AI behavior) and the **plug-in point** where an AI
   solution under test is invoked (via a local adapter/callable or an isolated test endpoint) and
   its outputs are captured for evaluation.

An **evaluation run** feeds a scenario's events through the twin, invokes the AI at its plug-in
point, records the AI's responses, and scores them against the scenario's expected behavior and
against fidelity/coverage/privacy gates. The result is an evidence-backed judgment of whether the
AI is ready for broader (still non-production) adoption — never an automatic production
authorization, which remains a human decision.

## Target model

The twin models against whatever clinical standard the AI use cases require:

- **FHIR R4** — resource-oriented (Patient, Encounter, Condition, MedicationRequest, Observation,
  etc.); natural when the AI consumes FHIR.
- **OMOP CDM** — analytic, table-oriented (person, visit_occurrence, condition_occurrence,
  measurement, drug_exposure); natural for population/analytic AI.
- **Native source schema** — when the AI is tied to a specific EHR/source system's shape.

The tools in this solution are **model-agnostic**: they operate on a normalized internal
representation and can emit/ingest FHIR- or OMOP-shaped records. The chosen target is recorded
once in the twin's scope config and reused everywhere.

## The deployment model — Assess → Design → Generate/Build → Validate → Expand

Every Synthetic solution, including this one, follows the same pilot-first model with explicit
pass/fail gates and a documented rollback:

- **Assess** — profile the AI use cases, the target model, the available synthetic data source,
  the isolated environment, and governance. Produce a readiness assessment
  (`Twin Readiness – Pilot – v1`). Gate: readiness accepted.
- **Design** — design the twin's entities, workflows, event dynamics, and the scenario/AI
  plug-in contract. Produce the twin design (`Hospital Twin Design – Pilot – v1`).
- **Generate/Build** — stand up the twin in the isolated environment, wire the synthetic feed,
  and implement the scenario suite (`Twin Scenario Suite – Pilot – v1`). Gate: twin runs and a
  scenario executes end-to-end.
- **Validate** — run the pilot evaluation: fidelity/coverage of the twin, privacy validation of
  the synthetic data, and the scenario-based AI evaluation. Produce the fidelity report
  (`Twin Fidelity Report – Pilot – v1`) and the evaluation record. Gate: all pass/fail gates met.
- **Expand** — only after the pilot passes, add service lines, scenarios, and fidelity depth
  (`Hospital Twin Design – Cardiology – v1`, etc.), re-validating at each step.

**Rollback:** the twin lives only in the isolated non-production environment; if a gate fails,
stop, retain the evidence, and either refine the twin/scenario or defer the AI — nothing has
touched production or real PHI, so rollback is discarding the run and its synthetic artifacts.

## Benefits

- **Safe** — clinical AI is exercised against realistic dynamics with **zero** real-patient risk;
  no real PHI enters the twin.
- **Repeatable** — scenarios are versioned and deterministic (seeded), so an AI can be re-tested
  identically across versions and regressions caught.
- **Evidence-based** — every evaluation yields a scored record and a fidelity/coverage report you
  can show to architecture, QA, and governance.
- **Low cost & self-guided** — a fraction of a bespoke consulting build; a competent engineer can
  run the pilot from these steps and tools.

## Limitations (read before relying on results)

- A twin is a **model of** a hospital, not the hospital. Passing in the twin is **necessary but
  not sufficient** for production trust; it does not by itself authorize production use.
- **Fidelity is bounded** by the synthetic data source and the modeled dynamics. Claims of realism
  are only as strong as the reference distributions used to validate them (global requirement #6).
- The twin does **not** make regulatory or de-identification determinations. HIPAA/HITRUST
  de-identification, IRB/privacy sign-off, and disclosure-risk acceptance are **deferred** to the
  organization's privacy, compliance, and legal functions — this solution supplies technical
  method and evidence only.
- Vendor synthetic-data/AI frameworks are integrated at the **pattern** level; version-specific
  console internals must be verified against the vendor's own documentation and your version.
