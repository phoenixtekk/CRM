# Implementation

Follow these ordered steps to evaluate a digital-twin / synthetic-data vendor, define the
integration contract and adapters, run a pilot integration, and validate it against the
pass/fail gates before expanding. The flow follows the house model **Assess → Design →
Generate/Build → Validate → Expand**, is **pilot-first**, and names every artifact with the
`<Purpose> – <Scope> – <Stage>` convention so later steps, testing, and scripts reuse the
exact names.

> Do this work in the **isolated non-production environment** (global Requirement 3). **Never**
> place real PHI into the shared harness/twin/AI test environment. Every writing tool defaults
> to **dry-run**. Version-specific vendor steps: **verify against the vendor's documentation**.

## Stage 0 — Preconditions

1. Confirm the six global requirements and the six solution-specific requirements are met.
   Record gaps; a missing evaluation artifact or reference is itself an input to scoring.
2. Author the working config — three small JSON files the tools read:
   - the **evaluation criteria + weights** file (Requirement 4; input to the scorecard),
   - the **target-model interface contract** file (Requirement 2; validated by
     `integration_contract_validator.py`),
   - the **integration config** (target model, adapter paths, environment = non-prod).
   Name the config bundle `Integration Config – Pilot – v1`. Validate the contract file up
   front with `integration_contract_validator.py --contract ...` before proceeding.

## Stage 1 — Assess (evaluate candidate vendors)

3. For each candidate in the vendor set (Requirement 1), gather the evaluation inputs: a sample
   of output, its schema/interface doc, data-handling doc, and export/exit terms. Store them
   read-only under the candidate's evaluation folder.
4. Score every candidate with the scorecard tool (`vendor_evaluation_scorecard.py`) against the
   agreed weighted criteria. Produce **`Vendor Evaluation – Candidate Set – Assess`** (a
   ranked scorecard with per-criterion scores, the portability sub-score, and any missing-
   evidence flags).
5. **Gate A — Selection.** Review the ranked scorecard with technical + governance
   stakeholders. Select the vendor(s) that clear the agreed thresholds (Requirement 4).
   Failing all thresholds → do not proceed; revisit the candidate set. Record the decision on
   the `Vendor Evaluation – Candidate Set – Assess` artifact.

## Stage 2 — Design (contract + adapters + exit)

6. Author the **interface contract** for the selected vendor against the target model
   (FHIR / OMOP / native): declare entities, required fields, identifier/reference rules, and
   interface conventions. Validate the contract file itself with the contract validator
   (`integration_contract_validator.py --contract ...`). Produce
   **`Integration Contract – <Vendor Capability> – Design`**.
7. Specify the **two adapter boundaries**:
   - **data-in adapter** — how your seeds / reference stats map to the vendor's inputs,
   - **data-out adapter** — how the vendor's native output maps to the target-model contract.
   Keep all vendor-specific code in these two modules only (Requirement 3).
8. Capture the **exit path and rollback** for this vendor (export formats, artifact ownership,
   revert plan). Produce **`Portability & Exit Plan – <Vendor Capability> – Design`**. This
   feeds the portability assessor and the Validate gates.

## Stage 3 — Generate/Build (run the pilot integration)

9. Implement the two thin adapters per the Design. Do not reference the vendor's native shape
   anywhere outside them.
10. Run the vendor capability to produce pilot output in the isolated environment — either:
    - **synthetic generation** (emit a synthetic dataset against the target model), or
    - **twin/scenario execution** (run the hospital-twin/scenario and capture its output).
    Route the result through the **data-out adapter** into the target-model contract. Produce
    **`Vendor Output – Pilot – v1`** (target-model-shaped, in the isolated environment only).

## Stage 4 — Validate (the pass/fail gates)

Run each gate on `Vendor Output – Pilot – v1`. Record results in **`Integration Validation –
Pilot – v1`**. Any failed gate **blocks expansion** and triggers the rollback from step 8.

11. **Gate B — Contract conformance.** Run `integration_contract_validator.py` with the
    `Integration Contract – <Vendor Capability> – Design` against the vendor output.
    **Pass:** all required entities/fields present, identifier/reference rules satisfied, no
    contract violations. **Fail:** any missing required field or broken reference.
12. **Gate C — Adapter conformance.** Run `adapter_conformance_checker.py` on the data-in and
    data-out adapters with paired input/output fixtures. **Pass:** round-trip is lossless for
    in-scope fields and no vendor-native shape leaks past the adapter. **Fail:** field loss,
    type drift, or a native-shape leak.
13. **Gate D — Fidelity/coverage.** Compare the output to the reference (global Requirement 6)
    as a documented procedure (see Testing, Test 3): in-scope column distributions vs. the
    read-only reference and the required scenario/domain coverage matrix. **Pass:** in-scope
    distributions and required scenario coverage meet the agreed thresholds. **Fail:** below
    threshold on a required metric or coverage gap.
14. **Gate E — Privacy/validation.** Run `privacy_validation_check.py` with the agreed quasi-
    identifiers and disclosure-risk threshold (Requirement 5). **Pass:** no exact real-record
    matches, uniqueness/k-anonymity signals within the agreed threshold. **Fail:** any signal
    over threshold. *(Evidence only — acceptance is deferred to privacy/compliance.)*
15. **Gate F — Portability/lock-in.** Run `portability_lockin_assessor.py` against the
    `Portability & Exit Plan` and the contract. **Pass:** portability score at/above the agreed
    minimum, exit path documented and exercised (a test export succeeds). **Fail:** score below
    minimum or no working export.
16. **Gate summary.** All of Gates B–F must pass to proceed. Attach the tool outputs to
    `Integration Validation – Pilot – v1` and obtain the governance sign-off recorded there.

## Stage 5 — Expand

17. With the pilot passing all gates, extend the **same** contract + adapter pattern to the
    next domain, program, or a second vendor. Reuse the exact artifact names, incrementing the
    scope/stage (e.g. `Vendor Output – Cardiology – v1`, `Integration Contract – <Second
    Vendor> – Design`). Re-run Gates B–F for each expansion.
18. Maintain a **vendor register** linking each integrated capability to its contract,
    adapters, portability/exit plan, and latest validation — so partner capabilities stay
    consistently governed and portable across programs.
