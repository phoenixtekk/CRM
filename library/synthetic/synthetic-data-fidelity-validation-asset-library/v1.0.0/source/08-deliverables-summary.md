# Deliverables Summary

What the buyer receives — a self-guided package to measure synthetic-data fidelity and build a
reusable validation asset library, safe by default (no real PHI written to a shared harness;
reference inputs are aggregate-only; privacy determinations deferred to the org).

## Documentation

- **Solution Overview** — the fidelity model (statistical fidelity vs utility vs privacy),
  coverage/edge cases, the reusable-asset approach, and the Assess → Design → Generate/Build →
  Validate → Expand deployment model.
- **Requirements Guide** — the six solution-specific prerequisites (synthetic dataset under test,
  governed aggregate-only Reference Profile source, field manifest, tolerances/coverage targets,
  utility task, versioned asset store), each with how to verify and implement, on top of the six
  category-wide requirements.
- **Implementation Guide** — exact ordered steps to build the assets, measure a pilot dataset,
  apply pass/fail gates, and promote the suite for reuse; every artifact named consistently.
- **Testing & Validation** — eight procedures (aggregate-only profile, manifest mapping, fidelity,
  utility, coverage, privacy signals, evidence report, reusability) each with pass/fail.
- **Troubleshooting** — common failure modes and resolutions.
- **Best Practices** — durable practices for a growing validation library.
- **Executive Summary** — the outcome, approach, and why it is safe.

## The 5 Python tools (`SYNFID-Scripts.zip`)

All are Python 3.10+, standard-library-first, argparse `--help`, safe-by-default (`--dry-run`
where they write), no hardcoded secrets, no network calls, no real PHI.

1. **`synfid_profile.py` — Reference Profile builder.** Computes an **aggregate-only**
   statistical fingerprint (per-field distributions, category frequencies, correlations,
   missingness) from a read-only, minimized reference, producing the reusable **Reference
   Profile**. Emits no row-level data.

2. **`synfid_coverage.py` — Coverage / edge-case checker & scenario runner.** Checks a synthetic
   dataset against a **Coverage Specification** (required cohorts, value ranges, combinations, and
   minimum representation) and reports gaps; can enumerate the scenario slices the dataset must
   exercise.

3. **`synfid_fidelity.py` — Fidelity & utility metric suite.** Computes distribution distances,
   category-frequency divergence, and correlation-preservation (synthetic vs Reference Profile),
   plus an optional **TSTR-style utility gap** — the core "is it faithful/useful enough" report.

4. **`synfid_privacy.py` — Privacy / disclosure-signal check.** Reports technical
   disclosure-risk signals (exact-match and nearest-neighbor indicators) as inputs for the privacy
   office. Reports signals only — **never a de-identification determination**.

5. **`synfid_config.py` — Scope & config helper.** Scaffolds and validates the **Validation
   Suite** config, drafts a **Field Manifest** from a dataset's columns, and checks manifest ↔
   dataset mapping — the tool that makes the assets reusable.

## The reusable assets you build with them

Field Manifest, Reference Profile (aggregate-only), Fidelity Metric Suite config, Coverage
Specification, Validation Suite, and per-dataset **Evidence Reports** — versioned in your asset
store so every synthetic dataset ships with evidence of quality and no team re-invents validation.
