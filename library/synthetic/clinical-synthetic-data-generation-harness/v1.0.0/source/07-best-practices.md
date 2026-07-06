# Best Practices

Durable practices for keeping the synthetic clinical-data harness safe, plausible, and maintainable
over time.

## Privacy & safety

- **Keep the harness real-PHI-free — by design, not by discipline.** Only aggregate reference
  statistics (R2) ever enter the harness; never a real record. If a real value could reach the
  harness, the pipeline is wrong — fix the source, don't scrub the output.
- **Write only to the isolated output directory (R3).** Keep the safe-by-default write guard on;
  never disable it to "just get data out." A synthetic dataset outside the isolated environment is a
  governance problem even though it is artificial.
- **Defer determinations, produce evidence.** The tools give schema/plausibility/privacy evidence;
  de-identification, disclosure-risk acceptance, and IRB/privacy sign-off belong to
  privacy/compliance/legal (global §4). Record their sign-off alongside the dataset.
- **Treat any identifier hit or exact-match as an incident** (T5/T6) — purge, investigate the source,
  and only then regenerate.

## Reproducibility

- **Version-control configs and seeds, never data.** The `<config, seed>` pair is the reproducible
  source of truth; the dataset is a derived artifact you can always regenerate.
- **Keep every run manifest.** Seed + config hash + tool version + record counts make a dataset
  auditable and a bug reproducible. Name datasets and manifests with the
  `<Purpose> – <Scope> – <Stage>` convention and keep them together.
- **Pin the target-model version.** FHIR version, OMOP vocabulary release, or native schema version
  are part of reproducibility — record them; a vocabulary bump can silently change conformance.

## Plausibility & fidelity

- **Grade against an agreed reference, always.** Plausibility without a reference is an opinion.
  Re-confirm the reference stays representative of the population your consumers care about.
- **Prefer plausible over perfect.** Synthetic data indicates real-world behavior; don't over-fit the
  harness to a single reference sample — that risks memorizing and leaking it (T6).
- **Add clinical guardrails as invariants.** Encode impossible-value checks (age ≥ 0, systolic ≥
  diastolic, meds linked to a plausible condition) as validator rules, not one-off reviews.

## Maintainability & extensibility

- **Extend by configuration, not by forking the generator.** New domains, scenarios, and target
  models are config and reference additions — keep the harness generic.
- **Change one thing, then re-validate.** Every config/reference/scope change reruns both Stage 4
  gates. Expansion never inherits the pilot's pass (T-series applies per dataset).
- **Scenario suites are living assets.** As consumer use cases evolve (R5), grow the scenario suite;
  retire scenarios no consumer needs so coverage stays meaningful.
- **Keep vendor/version specifics external.** Where a FHIR server, OMOP vocabulary, or synthetic-data
  engine (e.g. Synthea or a commercial platform) is involved, reference its documentation and verify
  against your version — don't hard-code assumed internals into the harness.

## Governance

- **Pilot-first, gate-driven, rollback-ready.** Never skip the pilot, never promote a dataset past a
  failed gate, always keep the last passing dataset intact so a bad expansion can roll back.
- **Log releases.** Record which dataset (by name + manifest hash) went to which consumer, when, and
  under whose privacy sign-off — so a later question about a dataset has a traceable answer.
