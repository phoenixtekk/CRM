# Best Practices

Durable practices for building, running, and expanding the hospital twin.

## Safety & privacy (non-negotiable)

- **Never load real PHI into the twin.** The twin and its AI test runs are fed only by a synthetic
  generator or a governed synthetic dataset. Where real data is touched at all (e.g. building a
  reference profile), it stays **read-only, minimized, and under the org's privacy controls** —
  never copied into the twin. Keep the `twin_privacy_validate.py` real-PHI leakage guard in every
  pipeline.
- **Keep the environment isolated.** Run everything in the segregated non-production environment
  with no path to production PHI stores. Access-control the twin's artifacts like the sensitive
  test material they are.
- **Defer the determinations.** The tools give technical method and evidence. De-identification
  claims, disclosure-risk acceptance, and IRB/privacy sign-off belong to privacy/compliance/legal —
  cite that boundary in every report you hand over.

## Design

- **Start narrow, pilot-first.** One service line, one or two AI use cases, a small population.
  Prove the pilot end-to-end before adding scope; breadth without a passing pilot is wasted work.
- **Model against a real standard.** Pin the target model (FHIR/OMOP/native) once in the scope
  config and generate/validate against it — don't invent an ad-hoc schema the AI won't see in
  reality.
- **Separate the AI behind a thin adapter.** The twin calls the AI only through the plug-in
  contract. This keeps the AI swappable, keeps the twin model-agnostic, and prevents the twin from
  depending on any one model's internals.

## Scenarios & evaluation

- **Every scenario has an unacceptable outcome, not just an expected one.** The point of the twin
  is to *catch* bad AI behavior; a scenario with no failure condition tests nothing.
- **Version scenarios with the config.** Keep the scenario suite, scope config, reference profile,
  and gates versioned together so any evaluation is reproducible and diffable across AI versions.
- **Seed everything.** Use the config's seed so populations and event sequences are deterministic;
  reproducibility is what makes the twin a regression harness, not a one-off demo.
- **Score against agreed gates, not vibes.** Fidelity, privacy, and scenario gates are numeric and
  owner-accepted before the run — decide thresholds up front so results are not negotiated after
  the fact.

## Fidelity

- **Validate realism against a reference, or state the limit.** Fidelity claims are only as strong
  as the reference profile. Where no reference is available, say so and treat the twin as a
  *functional* harness, not a *statistically representative* one.
- **Refine iteratively.** Treat fidelity as a dial you turn up over successive versions
  (`– v1`, `– v2`), re-validating each time, rather than chasing perfection before the first
  evaluation.

## Operations & governance

- **Keep provenance.** Retain every scope config, scenario suite, evaluation record, and report,
  versioned, so an AI's twin evidence is auditable.
- **Passing the twin ≠ production authorization.** State this explicitly in every evaluation
  record. Production trust is a human decision informed by the twin, plus real-world monitoring
  after any controlled rollout.
- **Pin your tool/vendor versions.** Synthetic-data and AI frameworks change; record the versions
  used and re-verify vendor-specific behavior against your version's documentation before relying
  on it.
