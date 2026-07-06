# Deliverables Summary

What the buyer gets — a self-guided framework for evaluating, integrating, and keeping
portable any partner digital-twin / synthetic-data capability, plus five Python tools that
operationalize the gates.

## Documentation

- **Solution Overview** — the integration model for external twin/synthetic-data capabilities:
  evaluation, integration patterns (data-in / data-out / interface contract), the target-model
  contract, portability, and the Assess → Design → Generate/Build → Validate → Expand model.
- **Requirements Guide** — the six solution-specific prerequisites (candidate vendor set,
  target-model contract, isolated adapter boundaries, weighted evaluation criteria, privacy
  reference/threshold, exit/rollback), each with how to *verify* and *implement*, on top of the
  six category-wide requirements.
- **Implementation Guide** — the exact ordered steps: evaluate candidates, design the contract
  and two adapters, run a pilot integration, and pass Gates A–F before expanding. Every
  artifact named with the `<Purpose> – <Scope> – <Stage>` convention.
- **Testing & Validation** — the five pass/fail gates (contract, adapter, fidelity/coverage,
  privacy, portability) with expected results and rollback.
- **Best Practices** — durable practices for low-lock-in, consistently governed partner
  integration.
- **Troubleshooting** — common failure modes and resolutions.
- **Executive Summary** — outcome, approach, and why it is safe.

## The 5 Python tools

1. **`vendor_evaluation_scorecard.py`** — scores candidate vendors against agreed weighted
   criteria (fidelity, privacy, interoperability, portability, support, cost), ranks them, and
   flags missing evaluation evidence. Produces the `Vendor Evaluation – Candidate Set – Assess`
   scorecard.
2. **`integration_contract_validator.py`** — validates a target-model **interface contract**
   file, and validates vendor output against it (required entities/fields, types,
   identifier/reference rules). The Gate B tool.
3. **`adapter_conformance_checker.py`** — checks the **data-in / data-out** adapters for
   lossless round-trip of in-scope fields and detects vendor-native shape leaks past the
   adapter boundary. The Gate C tool.
4. **`privacy_validation_check.py`** — checks vendor-produced synthetic output for exact
   real-record matches and computes uniqueness / k-anonymity signals on the agreed
   quasi-identifiers against a read-only reference. The Gate E tool (evidence only; acceptance
   deferred to privacy/compliance).
5. **`portability_lockin_assessor.py`** — scores the anti-lock-in / portability criteria (open
   target model, exportable artifacts, adapter isolation, documented + exercised exit, exit
   cost) and produces a lock-in risk rating with a documented exit path. The Gate F tool.

*(Gate D — fidelity/coverage — is run as a documented comparison against the reference, per
Testing; the criteria/weights, contract, and integration config that the tools above read are
plain JSON files you author during Implementation Stage 0.)*

All tools are **standard-library-first**, run on **Python 3.10+**, are **safe by default**
(read-only or `--dry-run` for anything that writes), make **no network calls**, and never
require or write real PHI. They produce **evidence** for human decision-makers, not approvals.
