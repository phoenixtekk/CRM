# Deliverables Summary

What the buyer gets — one page. Everything is self-guided and safe by default: no real PHI, isolated
non-production use, Python automation. Regulatory/de-identification determinations are deferred to
your privacy/compliance/legal functions.

## Documentation

- **Solution Overview** (`01-solution-overview.md`) — the hospital-twin concept: what it simulates
  (patients, encounters, workflows, events), how synthetic data drives it, how AI plugs in for
  evaluation, the target model, benefits/limitations, and the Assess→Design→Generate/Build→
  Validate→Expand model.
- **Requirements Guide** (`02-requirements.md`) — the six solution-specific prerequisites (AI
  plug-in contract, synthetic data source, scenario definitions, reference profile, pass/fail gates,
  scope config), each with verify/implement steps, on top of the six category-wide requirements.
- **Build Guide** (`03-implementation.md`) — exact ordered steps to design, build, wire, run a
  pilot evaluation, and expand the twin, with every artifact named and the three acceptance gates.
- **Testing & Validation** (`05-testing.md`) — six tests (build integrity, end-to-end scenario,
  fidelity/coverage, privacy, AI evaluation, reproducibility), each with pass/fail.
- **Troubleshooting** (`06-troubleshooting.md`) — common failure modes and resolutions.
- **Best Practices** (`07-best-practices.md`) — durable practices for safety, design, scenarios,
  fidelity, and governance.
- **Executive Summary** (`executive-summary.md`) — the outcome, approach, and why it is safe.

## The 5 Python tools (`scripts/`)

All are Python 3.10+, standard-library-first, `--help`-documented, and **safe-by-default**
(dry-run where they write; no real PHI to shared locations; no invented network endpoints).

1. **`twin_readiness_assess.py`** — *Assessment/profiling.* Profiles your inputs (Python env,
   target model, synthetic-source reachability, AI plug-in contract, scenarios, reference profile,
   gates) and writes a readiness score with blockers → `Twin Readiness – Pilot – v1`.
2. **`twin_simulator.py`** — *Twin/event simulator engine.* Loads the synthetic population against
   the scope config and advances the simulation clock (admit → order → result → medicate →
   transfer → discharge), emitting the event stream the twin runs on. Dry-run by default.
3. **`twin_scenario_runner.py`** — *Scenario runner + AI plug-in harness.* Runs a scenario (or the
   whole suite) through the twin, invokes the AI at each plug-in point (mock or real adapter),
   captures outputs, and scores them → `Twin Evaluation Record – Pilot – v1`. Dry-run by default.
4. **`twin_fidelity_report.py`** — *Fidelity/behavior report.* Compares the twin's synthetic
   population and events to the reference profile, per-metric vs. threshold, plus scenario coverage
   → `Twin Fidelity Report – Pilot – v1` (HTML).
5. **`twin_privacy_validate.py`** — *Privacy/validation check.* Runs disclosure-risk checks on the
   synthetic feed (exact-match/uniqueness, quasi-identifier k-anonymity, real-PHI leakage guard),
   PASS/FAIL per check → `Twin Privacy Validation – Pilot – v1`. Acceptance deferred to the privacy
   office.

The **scope/config helper** is built into the toolset: `twin_readiness_assess.py --init-config`
generates and `--validate-config` checks the `Twin Scope Config – Pilot – v1` record that every
tool reads, so no separate script is needed.
