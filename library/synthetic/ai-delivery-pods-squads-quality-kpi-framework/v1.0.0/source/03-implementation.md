# Implementation

Follow these steps in order. They implement the **Assess → Design → Generate/Build → Validate →
Expand** model, pilot-first. Every artifact is named with the `<Purpose> – <Scope> – <Stage>`
convention and that exact name is reused in later steps, testing, and the scripts. Run everything on
a **single pilot squad** first; do not roll out program-wide until the Validate gates pass.

Throughout: KPI inputs are operational telemetry and **aggregate, PHI-free** validation pass/fail
signals only. **Never** feed real PHI, patient-level records, or synthetic-but-sensitive detail into
a KPI pipeline or dashboard feed.

---

## Stage 1 — Assess

**Goal:** capture the current delivery reality before changing anything.

1. **Confirm scope and sponsor.** With the executive sponsor (requirement S2), fix the **pilot
   squad** and its charter. Record it at the top of the assessment.

2. **Inventory the current structure.** List the teams/pods in the pilot scope today, the roles
   staffed, and the informal interfaces (how work arrives, how it hands off, how issues escalate).

3. **Inventory the telemetry.** For the pilot squad, confirm you can export a work-item history, a
   CI/CD history, a code-review history (S3), and the fidelity/privacy validation pass/fail
   signals (S4). Note any gaps.

4. **Inventory existing metrics.** List any KPIs/dashboards already in use and flag which are vanity
   metrics (raw counts, individual utilization, LOC, velocity-as-target).

5. **Produce `Delivery Assessment – Program – v1`** — a short document capturing the above: current
   structure, telemetry availability (with gaps), and existing-metric findings. **Gate to proceed:**
   telemetry for the pilot squad is available or has an owner committed to providing it.

---

## Stage 2 — Design

**Goal:** define the target structure, the KPI catalog, and the improvement cadence.

6. **Define the pod topology.** Using the config helper (`pod_capacity_planner.py`), model the target
   pods for the pilot squad: for each pod, its outcome ownership, its roles (data/platform engineer,
   ML/AI engineer, QA/validation, privacy liaison, product/clinical SME, pod lead), and its
   **interfaces** (intake contract, hand-off/deliverable contract, escalation path). Confirm each pod
   is staffable and not over-subscribed. Record as **`Pod Topology – Program – v1`**.

7. **Draft the candidate KPI set.** In a short workshop (S5), draft 6–10 candidate KPIs spanning:
   - **Productivity/flow:** delivery cycle time, throughput (items completed per period), work-in-
     progress, flow efficiency.
   - **Quality:** defect escape rate, rework rate, change-failure rate, fidelity validation
     first-pass rate, **privacy-gate first-pass rate**.

8. **Validate the KPI definitions.** Run `kpi_definition_validator.py` over the candidate catalog.
   Every KPI must have a **definition, data source, target, owner**, and must **pass the vanity-metric
   guard** (no raw output counts, individual utilization, LOC, or velocity-as-target). Fix or drop any
   KPI that fails. Record the passing set as **`KPI Catalog – Program – v1`**.

9. **Set targets.** For each KPI, set a **conservative starting target** and mark it "provisional —
   re-baseline during pilot". Targets are directional at this stage; the pilot produces the real
   baseline.

10. **Define the cadence.** Document **`KPI Review Cadence – Program – v1`**: who attends (sponsor +
    pod leads), frequency (e.g. every two weeks), and the standing agenda — review variance, pick the
    one or two largest gaps, agree concrete actions with owners, and record them. **Gate to proceed:**
    topology, catalog (validator-passed), and cadence are all agreed and signed off.

---

## Stage 3 — Generate/Build

**Goal:** instrument the KPIs and stand up the dashboard for the pilot squad.

11. **Wire the data sources.** Export the pilot squad's telemetry and validation pass/fail signals
    into the framework's input format (a per-KPI observations file). Use each tool's documented export
    path; verify field names against your version rather than assuming.

12. **Compute the rollup.** Run `kpi_rollup_generator.py` to aggregate the raw observations into
    per-KPI, per-period values, producing **`KPI Dashboard Feed – Program – v1`** (CSV/JSON). This is
    the single, portable feed the dashboard and the cadence consume.

13. **Stand up the dashboard.** Point your BI tool (or, if none, the cadence itself) at
    `KPI Dashboard Feed – Program – v1`. Confirm every catalog KPI renders against its target.

14. **Run the first variance report.** Run `kpi_variance_reporter.py` against the feed and the
    catalog targets to produce the target-vs-actual variance for the pilot period. This is the input
    to the first cadence review. **Gate to proceed:** every catalog KPI has real data flowing and a
    computed value; no feed field contains PHI.

---

## Stage 4 — Validate

**Goal:** pass the three framework gates before expanding. (Full procedures in `05-testing.md`.)

15. **Structure-defined gate.** `Pod Topology – Program – v1` exists, every pod has roles and all
    three interfaces (intake, hand-off, escalation), and no pod is over-subscribed per the capacity
    planner. **Pass/fail:** any pod missing an interface or over capacity = fail.

16. **KPIs-instrumented gate.** Every KPI in `KPI Catalog – Program – v1` passes the validator
    (definition/source/target/owner + vanity guard) **and** has a real value in
    `KPI Dashboard Feed – Program – v1`. **Pass/fail:** any KPI failing the validator or with no data
    = fail.

17. **Cadence-running gate.** At least one improvement review has run off the variance report, with
    actions recorded and owners assigned in `KPI Review Cadence – Program – v1`. **Pass/fail:** no
    completed review with recorded actions = fail.

18. **Privacy gate (non-negotiable).** No KPI observation, rollup, or dashboard feed contains real
    PHI or patient-level detail — only aggregate metrics and PHI-free pass/fail signals. **Pass/fail:**
    any real PHI present = fail and stop; remediate before proceeding.

**Rollback:** if any gate fails and cannot be remediated in place, revert to the prior version of the
affected artifact (`… – v1` → prior) and re-run the stage. Do not expand on a failed gate.

---

## Stage 5 — Expand

**Goal:** extend beyond the pilot, having proven the framework.

19. **Re-baseline targets.** Using the pilot's actuals, replace the provisional targets in
    `KPI Catalog – Program – v1` with evidence-based targets. Bump to `KPI Catalog – Program – v2`.

20. **Prune and add KPIs.** Drop any KPI the pilot showed to be noise or a de-facto vanity metric;
    add any genuinely missing outcome signal (re-run the validator on the changed set).

21. **Onboard the next squad.** Repeat Stages 2–4 for the next squad, reusing the topology pattern and
    the validated catalog. Version per squad/program as `… – v2`, `… – v3`.

22. **Institutionalize the cadence.** Make the improvement cadence a standing program ritual chaired
    by the sponsor, with the variance report as its standing input.
