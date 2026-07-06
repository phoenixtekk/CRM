# Best Practices

Durable practices for running an AI-delivery pod/squad structure and an engineering-quality KPI
framework that stays honest over time.

## Structure

- **Keep pods small and end-to-end.** A pod should own a slice of outcome it can deliver without
  constant cross-team dependency. If a pod can't ship without three other teams, the boundary is
  wrong — redraw it.
- **Write the interfaces down.** The intake contract, the hand-off/deliverable contract, and the
  escalation path are the parts that fail silently. Capture them in `Pod Topology – Program – v1`
  and review them when hand-offs go wrong.
- **Name a privacy liaison in every pod.** Because the work runs on synthetic data in isolated
  environments, someone in each pod owns the privacy posture and the privacy gate — it is not a
  central afterthought.
- **Don't over-subscribe pods.** Use the capacity planner every time demand or staffing changes;
  a chronically over-capacity pod produces bad quality metrics that no cadence can fix.

## Measurement

- **Keep the set small (6–10) and outcome-tied.** Every KPI must plausibly connect to "AI delivery
  is faster and safer". If you can't state the outcome a metric serves, drop it.
- **Ban vanity metrics explicitly.** Raw output counts, individual utilization, lines of code, and
  velocity-as-a-target reward the wrong behavior. Keep the exclusion list in the catalog and run the
  validator on every catalog change.
- **Pair every productivity KPI with a quality KPI.** Throughput without defect-escape, or cycle
  time without rework, invites gaming. The pairing is what keeps "fast" honest.
- **Treat privacy-gate first-pass rate as a first-class quality KPI.** It is the metric that makes
  the safety boundary visible; never let a speed metric out-rank it.
- **Never measure individuals.** KPIs are team/pod-level. Individual metrics erode trust and drive
  local optimization that hurts the system.
- **Define once, source once.** Each KPI has exactly one written definition and one data source.
  Duplicate or ambiguous definitions are how dashboards start to lie.

## Improvement

- **Variance drives action, not reporting.** The cadence exists to pick the one or two biggest gaps
  and do something about them, with a named owner. A review that only "notes" variance is theater.
- **Re-baseline targets from real history.** Provisional targets are placeholders; replace them with
  evidence from the pilot and revisit them each quarter.
- **Prune ruthlessly.** If a KPI hasn't driven a decision in a couple of cycles, it is probably
  noise — retire it. A smaller, trusted set beats a large, ignored one.
- **Keep the human context.** Numbers show *where* to look; the pod's judgment explains *why*. Pair
  every flagged variance with a short narrative before acting.

## Safety & governance

- **Aggregate in, aggregate out.** Only aggregate metrics and PHI-free pass/fail signals enter the
  pipeline. Run the privacy checker on the feed as a standing gate, not just once.
- **Version every artifact.** Topology, catalog, cadence, and feed all carry `– v1`, `– v2`… so a
  bad change can be rolled back cleanly.
- **Defer the determinations.** The framework produces evidence (pass rates, variance); whether a
  privacy posture is legally acceptable stays with privacy/compliance/legal. Don't let a green
  dashboard be mistaken for a compliance sign-off.
