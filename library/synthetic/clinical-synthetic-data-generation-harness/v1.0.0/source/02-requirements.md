# Requirements

This solution builds **on** the six category-wide requirements in
`global-requirements-synthetic.md` — a supported **Python** environment (§1), a **target clinical
data model** (§2), an **isolated non-production environment** (§3), **privacy/governance
stakeholders and policy** (§4), **AI/QA use cases and a pilot scope** (§5), and **read-only,
minimized reference access for fidelity** (§6). Confirm those first; do not duplicate them here.

The following are the **solution-specific** prerequisites for the generation harness. Each is
stated as Description / Why required / How to verify / How to implement if missing.

---

## R1. A confirmed target model **profile** (fields, cardinality, terminology bindings)

- **Description:** Beyond selecting FHIR / OMOP / native (global §2), a concrete **profile** of the
  in-scope resources/tables: the exact fields, their data types and cardinality, required vs.
  optional, and the terminology/value sets or concept vocabularies each coded field binds to.
- **Why required:** The harness generates and the validator checks **against this profile**. Without
  it, schema conformance is undefined and coded fields (conditions, meds, labs) cannot be made
  plausible.
- **How to verify:** Confirm the profile document exists and names, for each in-scope domain, the
  fields, types, cardinality, and code system/vocabulary + version.
- **How to implement if missing:** Capture the profile from your FHIR implementation guide, OMOP
  vocabulary release, or native schema; record the version. Store it as the
  **Synthetic EHR – Target Profile – Pilot** artifact.

## R2. Agreed **reference distributions** for the pilot domains

- **Description:** For each in-scope domain, the reference statistics the synthetic data must match —
  age/sex mix, condition prevalence, medication-to-condition linkage, lab reference ranges and
  out-of-range rates, vital-sign ranges — sourced from governed real stats (global §6) or agreed
  published reference distributions.
- **Why required:** Plausibility is measured against these; without them the plausibility report has
  nothing to grade against and fidelity claims are unfounded.
- **How to verify:** Confirm a reference-distributions file exists covering every pilot domain, with
  its source and access terms recorded.
- **How to implement if missing:** Agree the reference approach with the privacy stakeholders (global
  §6), extract or cite the distributions, and store them as **Synthetic EHR – Reference Stats – Pilot**.
  Never copy real records into this file — only aggregate statistics.

## R3. A designated **isolated output directory** for generated data

- **Description:** A specific, access-controlled **output path** inside the isolated environment
  (global §3) where — and **only** where — the harness writes generated datasets. Distinct from any
  real-PHI store, code repo, or shared drive.
- **Why required:** Safe-by-default generation depends on writing synthetic data to one controlled,
  isolated location; the tools refuse to write elsewhere by default.
- **How to verify:** Confirm the path exists, is inside the isolated environment, is access-controlled,
  and is empty of real PHI.
- **How to implement if missing:** Create the directory in the isolated environment, restrict access,
  and record it as the harness's `--out-dir`. Never point it at a production or PHI location.

## R4. A **reproducibility policy** (seed management and run manifests)

- **Description:** A decision on how random **seeds** and **run manifests** are managed so any dataset
  can be regenerated: where seeds are recorded, how config versions are pinned, and how each run's
  inputs (seed, config hash, tool versions) are captured.
- **Why required:** Reproducibility — a core promise of the harness — requires that seed + config are
  captured and re-runnable; without a policy, "the same dataset" cannot be reproduced for a bug or an
  audit.
- **How to verify:** Confirm a run-manifest convention is defined and that seeds/config are version
  controlled (not real data — configs and seeds only).
- **How to implement if missing:** Adopt the run-manifest emitted by the generation tool, commit
  configs and seeds to version control, and record the policy in the design artifact.

## R5. **Named AI/QA consumers** and their acceptance criteria

- **Description:** The specific downstream consumers of the synthetic data (a model-under-test, a QA
  suite, a pipeline) and **what "good enough" means to them** — which domains, which scenarios, and
  the fidelity/coverage thresholds they need.
- **Why required:** The pass/fail gates (Testing) are set from consumer needs; the scenario suite and
  coverage targets are meaningless without a consumer's acceptance criteria.
- **How to verify:** Confirm each consumer, the domains/scenarios they require, and their minimum
  fidelity/coverage thresholds are documented.
- **How to implement if missing:** Interview the AI/QA owners (global §5), record acceptance criteria,
  and fold them into the **Synthetic EHR – Harness Design – Pilot** artifact.

## R6. **Optional** analytics libraries for fidelity metrics

- **Description:** `pandas` and `numpy` for the fidelity/coverage computations. The included tools are
  standard-library-first and degrade gracefully, but richer distribution comparisons benefit from
  these libraries.
- **Why required:** Not strictly required — the tools run without them — but they make plausibility
  and coverage reporting faster and more expressive on larger pilot datasets.
- **How to verify:** `python -c "import pandas, numpy"` returns without error in the target
  environment.
- **How to implement if missing:** `pip install pandas numpy` in the isolated environment. If they
  cannot be installed, the tools still run with reduced-precision fallbacks (they say so on stdout).
