# Solution Overview

## What this is

The **Clinical Synthetic Data Generation Harness** is a self-guided build for a repeatable
system that produces **clinically plausible, privacy-conscious synthetic Electronic Health
Record (EHR) data** — patients, encounters, conditions, medications, laboratory results, and
vital signs — against a chosen **target data model** (**FHIR**, **OMOP CDM**, or a native
source schema). It exists so AI and QA teams get **realistic test data** without ever touching
real Protected Health Information (PHI).

The harness is **seeded and reproducible**: the same configuration and random seed produce the
same dataset, every time, so a defect is reproducible and a model evaluation is comparable
across runs. It is **safe by default**: generation writes only to an **isolated, non-production
output directory** you designate, and no real PHI is ever placed into the shared harness.

This solution does **not** make regulatory determinations. It gives the technical method and the
evidence (schema conformance, plausibility metrics, privacy checks); the **de-identification /
disclosure-risk determination and any IRB or privacy-office sign-off are deferred** to the
organization's privacy, compliance, and legal functions.

## How it works

The harness is built from five cooperating parts, each backed by one of the included Python
tools:

1. **Scope & target-model assessment** — decide the target model (FHIR / OMOP / native), the
   in-scope domains and fields, the AI/QA use cases, and the isolated output location. Produces
   a profiled scope you can review before generating anything.
2. **The generation harness** — a seeded, deterministic generator that emits synthetic patients
   and their linked encounters, conditions, medications, labs, and vitals, shaped by
   configurable **reference distributions** and **scenario** definitions, written only to the
   isolated output directory.
3. **Plausibility & coverage report** — quantifies how clinically plausible and how complete the
   generated dataset is (age/sex distributions, condition prevalence, lab ranges, coverage of
   required domains and scenarios) against the agreed reference.
4. **Schema & privacy validator** — checks that every record conforms to the target model's
   structure and that no real-PHI patterns, no direct identifiers, and no exact reference-record
   matches have leaked in.
5. **Scenario / config helper** — scaffolds and validates the configuration and scenario files
   that drive the harness, so runs are reproducible and reviewable.

### Target model (FHIR / OMOP / native)

The harness is **target-model aware**. You pick one target and the tools adapt:

- **FHIR** — records emit as FHIR resource shapes (`Patient`, `Encounter`, `Condition`,
  `MedicationRequest`, `Observation` for labs and vitals). Terminology bindings are referenced
  at the pattern level; **verify code systems and value sets against your FHIR version** and the
  server you will load into.
- **OMOP CDM** — records map to OMOP tables (`person`, `visit_occurrence`,
  `condition_occurrence`, `drug_exposure`, `measurement`). Concept mappings are referenced at
  the pattern level; **verify concept IDs against your OMOP vocabulary version**.
- **Native** — records emit against the source system's own schema you supply, when neither
  standard applies.

Terminology, concept, and vocabulary specifics are **version-dependent** — the harness treats
them as configuration you confirm against your environment, never as invented internals.

## Benefits

- **Realistic test data on demand** — high-fidelity records shaped to real-world distributions,
  produced in minutes, not procured over months.
- **No real-PHI risk** — the shared harness never contains real PHI; privacy exposure is
  designed out, not managed after the fact.
- **Reproducible** — seed + config fully determine output, so evaluations and bug reports are
  comparable and repeatable.
- **Scenario-driven** — targeted cohorts (e.g. a sepsis pathway, a diabetes panel) can be
  generated on demand to exercise specific AI/QA use cases.
- **Extensible** — new domains, scenarios, and target models are added by configuration, not by
  rewriting the harness.

## Limitations (read before relying on output)

- **Plausible, not real.** Synthetic data approximates real-world distributions; it does not
  reproduce every real correlation. Model performance on synthetic data **indicates** but does
  not **guarantee** real-world performance.
- **Fidelity is bounded by the reference.** Plausibility is only as good as the reference
  statistics or distributions you agree in Requirement 6. Without a reference, plausibility
  claims are unfounded.
- **Not a de-identification tool.** This generates artificial data; it does not de-identify real
  data, and it does not make HIPAA/HITRUST determinations — those are deferred to privacy/legal.
- **Vendor and version specifics deferred.** Where a step depends on a FHIR server, OMOP
  vocabulary, or a synthetic-data engine (e.g. Synthea or a commercial platform), consult that
  vendor's documentation and **verify against your version**.

## The deployment model: Assess → Design → Generate → Validate → Expand

Every build in this category follows the same pilot-first model with explicit pass/fail gates:

1. **Assess** — confirm the six global requirements, pick the target model, profile the scope
   and use cases, and designate the isolated output. Artifact: **Synthetic EHR – Scope – Pilot**.
2. **Design** — define entities, relationships, reference distributions, and the pilot scenario
   suite. Artifact: **Synthetic EHR – Harness Design – Pilot**.
3. **Generate** — run the seeded harness to produce the pilot dataset into the isolated output.
   Artifact: **Synthetic EHR – Dataset – Pilot – v1**.
4. **Validate** — run the plausibility/coverage report and the schema/privacy validator against
   the pass/fail gates. Artifacts: **Synthetic EHR – Plausibility Report – Pilot** and
   **Synthetic EHR – Privacy Validation – Pilot**. **Do not expand until both gates pass.**
5. **Expand** — only after the pilot passes, widen domains, scenarios, and volume, re-validating
   at each step. Artifact: **Synthetic EHR – Dataset – Expanded – v1**.

A documented **rollback** applies throughout: if a gate fails, discard the failing dataset from
the isolated output and return to Design — never promote a dataset that failed a plausibility or
privacy gate to any AI/QA consumer.
