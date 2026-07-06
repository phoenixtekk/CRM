# Testing & Validation

These procedures validate the framework before it is trusted and expanded. They map to the three
framework gates plus the non-negotiable privacy gate. Run every test on the **pilot squad** and
record the result in `Delivery Assessment – Program – v1` (or a linked validation record). Each test
states its expected **pass/fail** signal.

Throughout, remember the safety boundary: KPI inputs are operational telemetry and **aggregate,
PHI-free** validation pass/fail signals only. Any test that would require patient-level data to run
is out of scope by design.

---

## T1 — Structure-defined test (topology completeness)

**Purpose:** confirm `Pod Topology – Program – v1` is complete and staffable.

**Procedure:**
1. For each pod, confirm it has: an outcome it owns, at least the core roles, and all three
   interfaces (intake contract, hand-off/deliverable contract, escalation path).
2. Run `pod_capacity_planner.py` on the topology and confirm no pod is over-subscribed (allocated
   demand ≤ capacity) and no role is single-points-of-failure beyond the agreed threshold.

**Expected result / pass-fail:** **Pass** = every pod has an owned outcome, core roles, and all
three interfaces, and no pod exceeds capacity. **Fail** = any pod missing an interface, missing a
core role, or over capacity.

---

## T2 — KPI-definition test (vanity-metric guard)

**Purpose:** confirm `KPI Catalog – Program – v1` contains only well-formed, non-vanity KPIs.

**Procedure:**
1. Run `kpi_definition_validator.py` over the catalog.
2. Confirm every KPI has a definition, a data source, a target, and an owner.
3. Confirm the vanity-metric guard flags **zero** KPIs (no raw output counts, individual
   utilization, lines of code, or velocity-as-target).

**Expected result / pass-fail:** **Pass** = validator reports every KPI complete and zero vanity
flags. **Fail** = any missing field or any vanity flag. Remediate the flagged KPI (redefine or drop)
and re-run.

---

## T3 — Instrumentation test (data actually flows)

**Purpose:** confirm every catalog KPI has real data in the feed.

**Procedure:**
1. Run `kpi_rollup_generator.py` on the pilot observations to (re)build
   `KPI Dashboard Feed – Program – v1`.
2. Confirm every KPI in the catalog appears in the feed with a non-null value for the current period.
3. Confirm counts reconcile against a manual spot-check of one KPI (e.g. recompute cycle time for a
   handful of items by hand).

**Expected result / pass-fail:** **Pass** = every catalog KPI has a value in the feed and the
spot-check reconciles within tolerance. **Fail** = any KPI missing a value, or the spot-check
diverges materially (investigate the data source mapping).

---

## T4 — Variance & target test

**Purpose:** confirm targets are set and variance is computed correctly.

**Procedure:**
1. Run `kpi_variance_reporter.py` against `KPI Dashboard Feed – Program – v1` and the catalog targets.
2. Confirm each KPI shows actual, target, variance, and a direction-aware status (a lower-is-better
   KPI like cycle time must not be flagged "good" when it rises).

**Expected result / pass-fail:** **Pass** = variance and status are correct for both
higher-is-better and lower-is-better KPIs, verified on at least one of each. **Fail** = any
direction handled incorrectly or any target missing.

---

## T5 — Cadence-running test

**Purpose:** confirm the improvement loop actually runs and produces action, not just reporting.

**Procedure:**
1. Hold the first review per `KPI Review Cadence – Program – v1`, using the T4 variance report as
   input.
2. Confirm the review selected the one or two largest gaps, agreed concrete actions, and assigned
   owners, all recorded.

**Expected result / pass-fail:** **Pass** = at least one completed review with recorded actions and
owners. **Fail** = review not held, or held with no recorded actions/owners.

---

## T6 — Privacy gate (non-negotiable)

**Purpose:** confirm no real PHI is present anywhere in the KPI pipeline.

**Procedure:**
1. Run `kpi_privacy_check.py` over the observations file and `KPI Dashboard Feed – Program – v1`.
2. Confirm the checker finds no patient-level identifiers, free-text clinical detail, or fields that
   look like PHI — only aggregate metrics and PHI-free pass/fail signals.
3. Confirm the validation inputs (S4) were the aggregate pass/fail signals, not underlying records.

**Expected result / pass-fail:** **Pass** = zero suspected-PHI findings; inputs confirmed aggregate.
**Fail** = any suspected PHI or patient-level field present → **stop**, remove it, and re-run before
proceeding. A privacy-gate failure blocks expansion unconditionally.

---

## Overall acceptance

The framework is validated for the pilot when **T1–T6 all pass**. Only then proceed to Stage 5
(Expand). Any failed gate triggers the documented rollback (revert the affected `… – v1` artifact and
re-run its stage). Determinations about whether the privacy posture is *legally acceptable* remain
with the organization's privacy, compliance, and legal functions — these tests provide technical
evidence, not a determination.
