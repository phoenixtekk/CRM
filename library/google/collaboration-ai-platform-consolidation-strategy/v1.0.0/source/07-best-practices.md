# 7. Best Practices — Collaboration & AI Platform Consolidation Strategy & Roadmap

Program-grade practices for consolidating a two-ecosystem collaboration-and-AI estate onto one
platform. These reduce risk, prevent the slide into permanent coexistence, and keep the consolidation
paying for itself.

## Strategy discipline

- **Decide the target once, ratify it high.** Executive-ratify that Google Workspace + Gemini is the
  target platform (`Consolidation Strategy – Platform – Design`, R1) before mapping or committing a
  wave. Ambiguity about the target is the single biggest cause of permanent coexistence.
- **Map the estate before you sequence.** Author `Consolidation Estate Map – Platform – Design` first —
  it is what surfaces the redundant systems and the decommission candidates. You cannot retire what you
  have not mapped.
- **Name everything with the convention.** `<Purpose> – <Scope> – <Stage>`, reused verbatim across
  artifacts, waves, roles, groups, and scripts, so discovery, validation, reporting, and the estate map
  cross-reference cleanly.
- **Justify every decommission against the three drivers.** Sustainability, security, cost efficiency —
  state which one(s) each retirement serves. A system with no driver for retiring is a retained
  exception, recorded as such.

## Ending coexistence (the whole point)

- **Coexistence is a phase, not a destination.** Write it into the strategy: every legacy system retires
  on a schedule when its exit criteria pass. A transformation that never decommissions has failed even
  if every migration "succeeded."
- **Every legacy system gets written exit criteria (R6).** Data migrated + verified, no active
  users/dependencies, target capability validated in production, governance cleared, rollback window
  elapsed. A decommission gate with no written criteria is a guess.
- **Gate the retirement, don't just hope.** No legacy system is turned off until its decommission gate
  (§05) is PASS. `GWCONSOL-Report.ps1` produces the decommission-readiness view so the gate is decided
  on evidence.
- **Retire in dependency order (R8).** Map what still depends on each system; retire in the order that
  respects real coupling. Decommissioning something a live workflow needs is how consolidation breaks
  production.

## Sequencing & the wave gate

- **Consolidate in waves, never big-bang.** Wave 0 baseline → Collaboration → AI → Identity &
  Management → Decommission & Sustain. Each wave moves a bounded slice off legacy.
- **The pilot gate is non-negotiable.** No wave expands to broad scope until its pilot acceptance gate
  (§05) is PASS. A bounded pilot catches breakage before the fleet feels it.
- **Keep cohorts intact in a wave scope.** Scope a wave to groups of users who work together so the
  coexistence window between platforms is short for any given team.
- **Run the per-wave preflight.** `GWCONSOL-Validation.ps1` (target-state conformance) and
  `GWCONSOL-Report.ps1` (cost/savings + decommission readiness) before every Configure; preview fixes
  with `GWCONSOL-Remediation.ps1` (default `-WhatIf`).

## Cost efficiency

- **Baseline the cost of running both (R9).** Duplicate licences, contracts, operations, support — the
  full run-rate of coexistence. Without the baseline you cannot show the program paying for itself.
- **Tie every saving to a retirement.** Each cost line in `Consolidation Cost Model – Platform – Run`
  maps to the legacy system whose decommission removes it, so savings land on the roadmap schedule, not
  in a vague "eventually."
- **Reharvest licences as systems retire.** Duplicate M365/Copilot licences freed by decommission are
  reclaimed promptly (licence-reduction KPI) — a licence left assigned to a retired system is pure waste.
- **Mind the contracts, not just the consoles.** A system can be technically retired while its contract
  keeps billing; align decommission timing with renewal/true-up windows to capture the saving.

## Sustainability & long-term platform health

- **Fewer systems is the sustainability win.** Every retired legacy system removes operational load,
  patch burden, audit scope, and a skill set to maintain. Track the shrinking footprint, not just the
  dollar savings.
- **One governed estate beats two weak ones.** Consolidation removes the "weaker of two" security
  posture; the target platform is the single governed surface once legacy retires.
- **Keep the artifacts current as living documents.** The strategy, estate map, roadmap, and cost model
  are updated with every completed migration and every retained-exception decision — not at the end.
- **Revisit retained exceptions on a cadence.** A system kept "for now" is a future decommission
  candidate; re-justify or retire each retained exception on the operating-model cadence so coexistence
  keeps shrinking.

## Change control & rollback

- **Approved window + tested back-out per decommission (R11).** Every retirement is
  irreversible-by-intent; keep the legacy system warm and the rollback ready until the exit criteria are
  provably met.
- **Governance clears before the gate (R10).** Retention holds and eDiscovery obligations are an
  exit-criterion, not an afterthought. A system under legal hold cannot be retired, full stop.
- **Communicate each cutover.** A short note per wave/decommission — what changes, the new experience,
  who to contact — sharply reduces tickets and resistance.

## Operating model

- **Assign the roles before you retire anything.** `Consolidation Sponsor` (with decommission
  authority), `Consolidation Owner`, `Estate Analyst`, `Migration Coordinator`, `Governance Liaison` —
  a consolidation with no empowered owner never ends coexistence.
- **Measure what matters.** Keep the KPI dashboard (`GWCONSOL-Report.ps1`) live: coexistence footprint,
  decommission progress, realized savings, licence reduction, target-state conformance, open
  exit-criteria blockers.
- **Report progress as convergence.** Leadership should see the coexistence footprint trending to zero
  and realized savings tracking the model — that is what proves the consolidation is working.
