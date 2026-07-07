# Deliverables Summary

This solution delivers a complete, self-guided **adoption, change-management, and training program**
for an enterprise Microsoft 365 → Google Workspace transformation, plus five Python tools that
instrument and operate it against real Google APIs (read-only / dry-run by default).

## Documentation

- **Solution Overview** — the OCM model: sponsor, champion network, the
  awareness → training → reinforcement arc, role-based learning paths, hypercare/floorwalking, and
  adoption measurement; the wave-aligned reference design and named artifacts.
- **Requirements Guide** — the solution-specific prerequisites (wave schedule, exec sponsorship, comms
  channels, training/LMS capacity, read-only measurement access, champion mandate, Gemini licensing),
  each with verify/implement steps, building on the shared `global-requirements-google.md`.
- **Implementation Guide** — ordered steps across Assess → Design → Configure → Pilot → Validate →
  Expand: build the champion network, run the comms/awareness campaign, deliver role-based training,
  stand up hypercare, and measure adoption — pilot-first, with pass/fail gates and rollback/hold.
- **Testing & Validation** — six procedures (T1–T6), each with an explicit pass/fail, culminating in
  the pilot scale-out gate.
- **Troubleshooting** — common failure modes (access, measurement, coverage, completion, hypercare,
  adoption trend) and their resolutions.
- **Best Practices** — durable practices for sponsorship, champions, training, hypercare, measurement
  hygiene, and sustaining adoption after cutover.
- **Executive Summary** — the outcome, approach, and why it is safe/governed.

## Python tools (`scripts/`) — read-only or `--dry-run` by default

1. **`adoption_metrics_report.py`** — *Assessment / report generator.* Reads the **Admin SDK Reports
   API** (Workspace usage) read-only to compute per-app active-usage (Gmail, Drive, Docs, Meet, Chat,
   Gemini where reported), optionally per OU/wave and **vs. a baseline**, and prints a `TREND` signal.
   Produces the adoption baseline and per-wave adoption reports. No writes.

2. **`champion_roster_planner.py`** — *Scope/config helper.* Turns BU champion nominations + the wave
   schedule into wave-aligned `Champion Cohort – <BU> – Wave N` assignments, checks coverage against a
   target ratio, and flags any wave `UNDER_RATIO`. Writes a plan file only — changes nothing in the
   tenant.

3. **`training_completion_tracker.py`** — *Validation / gate.* Joins an LMS/roster completion export to
   a wave roster, computes per-role completion, applies the go-live completion gate
   (`GATE: PASS/FAIL`), and lists stragglers. Read-only over its inputs.

4. **`hypercare_theme_analyzer.py`** — *Guardrail / analysis.* Analyzes hypercare ticket exports into
   ranked themes and checks floorwalker staffing against the hypercare plan (`STAFFING: OK/SHORT`), so
   the top pain points feed back into comms/training. Read-only.

5. **`adoption_config_check.py`** — *Policy/guardrail check.* Verifies the measurement setup is
   **safe**: ADC present, Reports/Directory APIs reachable, and **no write scopes** in use — the
   read-only guardrail for the whole program. No writes.

**Safety:** every tool is safe-by-default (read-only or `--dry-run` unless `--apply` is passed where
supported), uses **Application Default Credentials** / the environment, and contains **no hardcoded
credentials, service-account keys, or secrets**.
