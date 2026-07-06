# Troubleshooting

Common failure modes when standing up the pod/squad structure and the KPI framework, and how to
resolve each. Symptoms map to the gates in `05-testing.md`.

---

## The capacity planner flags a pod as over capacity

**Symptom:** `pod_capacity_planner.py` reports `over_capacity=True` / RESULT: FAIL for a pod in
`Pod Topology – Program – v1`.

**Likely causes & resolution:**
- The pod owns too broad a slice — split the outcome so each pod is end-to-end and self-sufficient.
- Demand is temporarily spiked — re-run with the sustainable demand, not a one-off surge; if the
  spike is real, staff the pod or defer scope.
- Capacity is under-recorded — confirm the capacity unit and the allocations are right (the planner
  is only as good as the numbers you feed it).
- Do **not** "fix" this by raising the recorded capacity to make the flag disappear — that just hides
  the over-subscription and it will resurface as poor quality metrics.

---

## The planner flags missing interfaces or single-person core roles

**Symptom:** `MISSING interfaces` or `single-person core roles (SPOF risk)` in the planner output.

**Resolution:** Every pod needs all three interfaces (intake, hand-off, escalation) written down —
add the missing contract to the topology. For SPOF roles (a core role staffed by exactly one
person), cross-train or add coverage; at minimum, record the risk and a mitigation. This is the
**structure-defined gate (T1)** — it must pass before instrumenting KPIs.

---

## The KPI validator rejects a KPI as a vanity metric

**Symptom:** `kpi_definition_validator.py` prints `VANITY: …` for a candidate KPI.

**Resolution:** This is working as designed. Raw output counts, lines of code, individual
utilization, and velocity-as-target are excluded because they reward the wrong behavior. **Redefine**
the metric around an outcome (e.g. replace "commits per sprint" with "delivery cycle time" or
"throughput of completed items") or **drop** it. Re-run the validator until zero vanity flags remain.
Do not edit the guard to smuggle a vanity metric through.

---

## A KPI has no data in the feed

**Symptom:** `kpi_rollup_generator.py` produces a feed missing a catalog KPI, or the instrumentation
test (T3) shows a null value.

**Likely causes & resolution:**
- The data source isn't wired — confirm the telemetry export (S3) or validation signal (S4) for that
  KPI is actually flowing into the observations file.
- Field-name mismatch — the tool's export column names differ from what you mapped; verify against
  your tool version's documentation (don't assume console internals).
- The KPI can't be sourced at all — if no data source exists, the KPI is aspirational; drop it from
  `KPI Catalog – Program – v1` until a source exists, rather than leaving a permanent blank.

---

## The rollup or privacy check aborts on a suspected-PHI column

**Symptom:** `kpi_rollup_generator.py` aborts with "suspected-PHI column", or `kpi_privacy_check.py`
returns FAIL.

**Resolution:** **Stop.** A KPI feed must contain only aggregate, PHI-free metrics. Remove the
offending column or value **at the source** (you are almost certainly exporting raw records instead
of aggregates), then re-export and re-run. This is the **non-negotiable privacy gate (T6)** —
expansion is blocked until it passes. Remember the checker is a technical screen; whether any residual
posture is *acceptable* remains a determination for privacy/compliance/legal.

---

## Variance looks "green" but the team knows quality is slipping

**Symptom:** `kpi_variance_reporter.py` shows KPIs on target, yet defects or privacy issues are rising
in reality.

**Likely causes & resolution:**
- **Direction handled wrong** — confirm each KPI's `direction`. A lower-is-better KPI (cycle time,
  defect escape) must be flagged when it *rises*; the reporter is direction-aware, so a green status
  on a rising bad metric means the direction is mis-set in the catalog.
- **Gaming** — a productivity KPI with no paired quality KPI invites shortcuts. Ensure every
  productivity KPI is paired with a quality KPI (see Best Practices); add the missing pairing.
- **Wrong or stale target** — provisional targets not re-baselined can read "green" while masking
  regression. Re-baseline from real history at Stage 5.

---

## The cadence produces reports but nothing changes

**Symptom:** reviews happen, but the same variances persist cycle after cycle (cadence-running gate
T5 technically passes, but improvement stalls).

**Resolution:** The cadence exists to drive **action**, not reporting. Enforce the standing agenda:
pick the one or two largest gaps, agree a concrete action, assign a named owner, and check it next
cycle. If actions aren't being done, escalate to the sponsor (S2) — an un-actioned cadence is a
sponsorship problem, not a metrics problem.

---

## Too many KPIs; the dashboard is ignored

**Symptom:** the catalog has grown well past 6–10 and no one looks at the dashboard.

**Resolution:** Prune. The validator prints a NOTE when the set exceeds ten. Retire any KPI that
hasn't driven a decision in the last couple of cycles. A small, trusted set beats a large, ignored
one. Bump the catalog version after pruning.
