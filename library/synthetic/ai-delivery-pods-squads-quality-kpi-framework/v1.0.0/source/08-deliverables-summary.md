# Deliverables Summary

Everything the buyer receives, on one page.

## Documentation

- **Solution Overview** — the AI-delivery operating model: pods/squads, roles and interfaces, and
  the productivity + delivery-quality measurement approach, plus the Assess → Design → Generate/Build
  → Validate → Expand model.
- **Requirements Guide** — the six category-wide prerequisites plus six solution-specific ones
  (delivery teams, sponsorship, telemetry access, validation-evidence access, a small candidate KPI
  set, and a dashboard surface), each with how to verify and how to implement.
- **Implementation Guide** — exact ordered steps: assess current delivery, design the pod topology
  and KPI catalog, instrument the KPIs and dashboard feed, validate against the three gates, and
  expand — pilot-first, with every artifact named and every pass/fail gate stated.
- **Testing & Validation** — six procedures (structure-defined, KPI-definition/vanity-guard,
  instrumentation, variance/target, cadence-running, and the non-negotiable privacy gate), each with
  its expected pass/fail signal.
- **Troubleshooting** — the common failure modes (missing telemetry, vanity-metric creep, gamed
  metrics, off-target with no action, suspected PHI in the feed) and how to resolve each.
- **Best Practices** — durable practices for structure, measurement, improvement, and safety —
  including keeping the KPI set small and banning vanity metrics.
- **Executive Summary** — the outcome, approach, and why it is safe, for sponsors.

## The 5 Python tools

1. **`pod_capacity_planner.py`** — models the pod/squad topology (pods, roles, interfaces,
   allocations, demand) and reports whether each pod is staffable and within capacity, flagging
   missing interfaces and single-role points of failure. Produces `Pod Topology – Program – v1`
   inputs. Read-only unless `--out` is passed.

2. **`kpi_definition_validator.py`** — validates the KPI catalog: every KPI must have a definition,
   data source, target, owner, and direction, and must pass the **vanity-metric guard** (rejects raw
   output counts, lines of code, individual utilization, velocity-as-target). Gate for
   `KPI Catalog – Program – v1`.

3. **`kpi_rollup_generator.py`** — aggregates raw, PHI-free KPI observations into the portable
   `KPI Dashboard Feed – Program – v1` (CSV/JSON), rejecting any suspected-PHI column. Dry-run by
   default; writes only with `--out`.

4. **`kpi_variance_reporter.py`** — joins the dashboard feed to catalog targets and reports
   **direction-aware** target-vs-actual variance (a lower-is-better KPI is never "good" when it
   rises). The standing input to the improvement cadence.

5. **`kpi_privacy_check.py`** — the **privacy gate**: read-only scan of the observations/feed for
   patient-level column names and PHI-shaped cell patterns (MRN/SSN/email/phone/DOB/free-text),
   reporting counts only (never echoing values). PASS/FAIL blocks expansion.

All tools are Python 3.10+, standard-library-first, safe-by-default (no real PHI, dry-run/opt-in for
writes, no network calls, no hardcoded secrets), and self-documenting via `--help` and
`--emit-sample`.
