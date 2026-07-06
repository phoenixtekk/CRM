# Troubleshooting

Common failure modes when evaluating and integrating partner digital-twin / synthetic-data
capabilities, and how to resolve them. All work stays in the **isolated non-production
environment**; **never** load real PHI into the shared harness/twin/AI test environment.

## Gate A — no candidate clears the selection threshold

- **Symptom:** `vendor_evaluation_scorecard.py` reports every candidate BELOW-THRESHOLD.
- **Likely causes:** thresholds/weights set too strict; or several candidates scored 0 on
  criteria only because **evidence was missing** (shown in the `missing` column).
- **Resolution:** First close the *missing-evidence* gaps — request the sample output, schema,
  or export terms and re-score (missing evidence is scored as 0 by design). If genuine scores
  are still low, revisit the candidate set with governance rather than lowering the agreed
  threshold post-hoc.

## Scorecard weights don't sum to 1.0

- **Symptom:** `NOTE: weights sum to X; normalizing to 1.0` on stderr.
- **Cause:** the `--criteria` file weights don't total 1.0.
- **Resolution:** The tool normalizes automatically, but fix the criteria file so the agreed
  weights are explicit and auditable — selection defensibility depends on the agreed weights.

## Contract file invalid (before any data)

- **Symptom:** `CONTRACT INVALID` with messages like "type not in …" or "reference to unknown
  entity".
- **Causes:** a field type outside the allowed set (`string, integer, number, boolean, date,
  datetime`); a reference pointing at an entity not declared in the contract.
- **Resolution:** Correct the interface-contract JSON. Every referenced entity must be declared,
  and every field must use an allowed type. Re-run `integration_contract_validator.py --contract
  ...` until you get `CONTRACT OK`.

## Gate B FAIL — missing fields or broken references

- **Symptom:** `GATE B: FAIL` listing missing required fields, wrong types, or
  `…has no matching <Entity>.<key>`.
- **Cause:** the vendor's native output isn't fully mapped to the target model, or referential
  integrity is broken in the mapping.
- **Resolution:** Fix the **data-out adapter** (not the harness): map the missing/renamed
  fields, coerce types, and ensure foreign keys resolve. Re-run against `Vendor Output – Pilot
  – v1`. Do **not** relax the contract to make output pass — that erodes portability.

## Gate C FAIL — vendor-native shape leaking into the harness

- **Symptom:** `adapter_conformance_checker.py` reports `vendor-native leak: [...]` or lost/
  drifted in-scope fields.
- **Cause:** the adapter is passing vendor-native keys straight through, or dropping/renaming
  in-scope fields — the classic lock-in defect.
- **Resolution:** Make the data-out adapter emit **only** target-model keys; strip vendor-native
  keys (and anything prefixed to look native). Restore any lost in-scope fields. Keep the
  adapter thin — no business logic. Re-run until `GATE C: PASS`.

## Gate D — fidelity below tolerance or coverage gaps

- **Symptom:** an in-scope distribution is outside the agreed tolerance, or a required
  scenario/domain isn't present.
- **Causes:** vendor configuration/seed doesn't match the reference population; scenario suite
  under-specified; or the reference itself is unrepresentative.
- **Resolution:** Re-configure the vendor generation/scenario parameters toward the reference,
  or expand the scenario suite for the missing coverage. If the **reference** is the problem,
  agree a better reference or reference distributions with governance (global Requirement 6)
  before asserting fidelity.

## Gate E FAIL — exact matches or below-k records

- **Symptom:** `privacy_validation_check.py` reports exact QI-matches against the reference or
  QI groups below k.
- **Causes:** the vendor output memorized/reproduced real records; or quasi-identifier
  combinations are too granular (e.g. full ZIP + exact DOB).
- **Resolution:** Quarantine the output. Reduce granularity (generalize QIs), regenerate, and
  re-run. Escalate any exact match to privacy/governance. Remember: a PASS is **evidence** —
  the disclosure-risk **acceptance is deferred** to privacy/compliance/legal, never inferred
  from a green result.
- **Also:** ensure `--reference` points at a **read-only, minimized, governed** copy — never
  load real PHI into the shared harness to run this check.

## Gate F FAIL — low portability score or export won't re-load

- **Symptom:** `portability_lockin_assessor.py` reports a score below the minimum, a MISSING
  criterion, or `test export … FAILED to re-load`.
- **Causes:** vendor code not isolated to the two adapters; output only available in a
  proprietary format; no documented exit; or the exit was never actually exercised.
- **Resolution:** Improve **adapter isolation** (Gate C), obtain an open export path, and
  document the exit/rollback in `Portability & Exit Plan – <Vendor Capability> – Design`. Then
  exercise a real export with `--data` + `--export-out` and confirm it re-loads **without vendor
  tooling**. A score that has never produced a working export does not pass.

## A gate passes but the vendor still feels "sticky" across programs

- **Symptom:** integrations work but each new program re-wires the vendor differently.
- **Cause:** the contract + adapter pattern isn't being reused; no central register.
- **Resolution:** Reuse the exact `Integration Contract` + adapter pattern on every expansion
  and maintain the **vendor register** linking each capability to its contract, adapters,
  exit plan, and latest validation (Implementation Stage 5). Consistency across programs is a
  governance practice, not an automatic outcome.

## Version drift after a vendor upgrade

- **Symptom:** a previously passing integration starts failing Gate B/C after the vendor updates.
- **Cause:** the vendor changed its native output shape or export behavior.
- **Resolution:** Vendor capabilities are integrated at the **pattern level** — re-verify the
  changed behavior against **the vendor's documentation for that version**, update the adapter
  only, and re-run Gates B–F. Record the verified version. Do not hard-code assumptions about a
  vendor's internals.
