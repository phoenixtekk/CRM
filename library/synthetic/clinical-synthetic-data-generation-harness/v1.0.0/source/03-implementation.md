# Implementation

Build the harness following the house model — **Assess → Design → Generate → Validate → Expand**,
**pilot-first**, with explicit pass/fail gates and a documented rollback. Every artifact is named
with the `<Purpose> – <Scope> – <Stage>` convention and that exact name is reused in Testing,
Troubleshooting, and the scripts.

All five Python tools ship in `scripts/`. Run each with `--help` first. Everything that writes is
**dry-run by default**; you opt in with `--apply` (or `--write`), and generation only ever writes to
the **isolated output directory** from Requirement R3.

---

## Stage 0 — Confirm prerequisites (gate to start)

1. Confirm the six global requirements and the six solution-specific requirements (R1–R6).
2. Confirm the **isolated output directory** (R3) exists inside the isolated environment and is
   empty of real PHI. This path is `--out-dir` everywhere below.

> **Gate to start:** do not proceed until R1 (target profile), R2 (reference stats), R3 (isolated
> out-dir), and R5 (consumer acceptance criteria) exist. Missing any of these means generation has
> no target, no reference to grade against, nowhere safe to write, or no definition of "good enough".

---

## Stage 1 — Assess (profile the scope)

1. Run the scope/assessment tool to profile inputs and produce the scope artifact:

   ```
   python scripts/scope_assessment.py \
       --target-model fhir \
       --profile ./config/target-profile.json \
       --reference ./config/reference-stats.json \
       --out-dir /isolated/synthetic-ehr \
       --report ./out/scope-report.json
   ```

2. Review the report: it lists the target model, in-scope domains, whether the reference covers each
   domain, and whether the out-dir is safe (isolated, empty of PHI signals). Resolve every **BLOCK**
   before continuing.
3. Save the result as **Synthetic EHR – Scope – Pilot**.

> **Assess gate:** the scope report must show **0 blocking issues** (target model resolved, all pilot
> domains have reference coverage, out-dir validated). Otherwise return to Requirements.

---

## Stage 2 — Design (entities, relationships, scenarios)

1. Scaffold and validate the harness configuration with the config/scenario helper:

   ```
   python scripts/scenario_config.py init \
       --target-model fhir \
       --domains patients,encounters,conditions,medications,labs,vitals \
       --out ./config/harness-config.json
   ```

2. Define the pilot **scenario suite** — the targeted cohorts your named consumers (R5) require
   (e.g. `diabetes-panel`, `sepsis-pathway`). Add each with:

   ```
   python scripts/scenario_config.py add-scenario \
       --config ./config/harness-config.json \
       --name diabetes-panel --size 200 \
       --require-condition E11 --require-lab HbA1c
   ```

3. Validate the finished config:

   ```
   python scripts/scenario_config.py validate --config ./config/harness-config.json
   ```

4. Record the config, reference stats, scenario suite, and consumer acceptance criteria together as
   **Synthetic EHR – Harness Design – Pilot**. Commit config + seed policy (R4) to version control.

> **Design gate:** `validate` must return **OK** — every scenario's required conditions/labs exist in
> the target profile (R1) and every consumer-required domain is covered.

---

## Stage 3 — Generate (the pilot dataset)

1. **Dry-run first** to preview volumes and see nothing is written:

   ```
   python scripts/generate_harness.py \
       --config ./config/harness-config.json \
       --seed 20260706 \
       --patients 500 \
       --out-dir /isolated/synthetic-ehr \
       --dataset-name "synthetic-ehr-pilot-v1"
   ```

   With no `--apply`, it prints the plan (record counts per domain, target model, seed, out-dir) and
   exits without writing.

2. **Generate for real** by adding `--apply`. The tool:
   - Writes **only** under `--out-dir` (refuses any other path, refuses a path with PHI signals).
   - Emits the dataset in the target model's shape plus a **run manifest** (seed, config hash, tool
     version, timestamp, record counts) so the run is reproducible (R4).

   ```
   python scripts/generate_harness.py --config ./config/harness-config.json \
       --seed 20260706 --patients 500 --out-dir /isolated/synthetic-ehr \
       --dataset-name "synthetic-ehr-pilot-v1" --apply
   ```

3. Save the output as **Synthetic EHR – Dataset – Pilot – v1** and keep its run manifest.

> **Reproducibility check:** re-running the exact command with the same `--seed` and config must
> produce an identical dataset (same manifest content hash). See Testing.

---

## Stage 4 — Validate (the pass/fail gates)

Run **both** validators against the pilot dataset. **Do not expand until both pass.**

1. **Plausibility & coverage** — grade the dataset against the reference (R2) and consumer criteria
   (R5):

   ```
   python scripts/plausibility_report.py \
       --dataset /isolated/synthetic-ehr/synthetic-ehr-pilot-v1 \
       --reference ./config/reference-stats.json \
       --config ./config/harness-config.json \
       --report ./out/plausibility-pilot.json
   ```

   Save as **Synthetic EHR – Plausibility Report – Pilot**.

2. **Schema & privacy** — confirm every record conforms to the target profile and that no direct
   identifiers, real-PHI patterns, or exact reference-record matches leaked in:

   ```
   python scripts/schema_privacy_validator.py \
       --dataset /isolated/synthetic-ehr/synthetic-ehr-pilot-v1 \
       --profile ./config/target-profile.json \
       --reference ./config/reference-stats.json \
       --report ./out/privacy-pilot.json
   ```

   Save as **Synthetic EHR – Privacy Validation – Pilot**.

> **Validate gates (both must pass):**
> - **Plausibility gate** — every pilot domain within tolerance of the reference **and** every
>   consumer-required scenario/domain covered at its threshold (R5).
> - **Privacy/schema gate** — **100%** schema conformance, **0** direct identifiers, **0** exact
>   matches to any reference record.
>
> If either fails: **rollback** — discard **Synthetic EHR – Dataset – Pilot – v1** from the isolated
> out-dir, return to Design, adjust config/reference, and regenerate. **Never** hand a dataset that
> failed a gate to an AI/QA consumer.
>
> **Determination is deferred:** the privacy validator produces technical evidence only. Acceptance
> of residual disclosure risk and any de-identification/IRB sign-off is the **privacy/compliance/legal**
> functions' decision (global §4), not this tool's.

---

## Stage 5 — Expand (only after the pilot passes)

1. With both pilot gates green and privacy sign-off recorded, widen scope **incrementally**: add
   domains/scenarios via `scenario_config.py`, increase `--patients`, and regenerate as
   **Synthetic EHR – Dataset – Expanded – v1**.
2. **Re-validate at every expansion** — rerun Stage 4 on each expanded dataset. Expansion does not
   inherit the pilot's pass; each new dataset must clear both gates.
3. Update the run manifests and version control on each expansion so every released dataset remains
   reproducible.

> **Expand discipline:** one change at a time, re-validate, keep manifests. A failed expansion rolls
> back to the last passing dataset — the pilot dataset is never overwritten in place.
