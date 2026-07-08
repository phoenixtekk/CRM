# 7. Best Practices — Enterprise DLP Assessment & Strategy (Microsoft Purview)

Field-tested practices for running a DLP assessment that produces a roadmap people actually trust and act
on — rather than a shelf-ware report. These complement the Implementation and Testing guides.

## Discover before you design — always
- **Never propose a DLP policy before you know where the data is.** The whole point of this engagement is
  to replace "we think we should block credit cards" with "here is where card data rests and how it moves."
  Let Content Explorer and the simulation baseline speak before you rank anything.
- **Aim the scan.** An open-ended "scan everything" produces an unreadable map. Start from a **candidate-
  category shortlist** (Req 2.4) so the data map and the ranking are legible to compliance and legal.
- **Measure motion, not just rest.** Data at rest tells you *what* you hold; the monitor-only simulation
  policy and Activity Explorer tell you *how it leaves* — and external-sharing exposure is usually the
  single strongest prioritization signal.

## Keep the assessment non-enforcing and reversible
- **Exactly one Purview object** should come out of this engagement: the `DLP Baseline – All Locations –
  Simulation` policy. It enforces nothing and shows no tips. Treat **simulation mode as a measurement
  instrument**, not a control.
- **Confirm the mode every time.** After any change, re-run Discovery and verify the baseline reads
  `TestWithoutNotifications`. An assessment policy that drifts to enforce is a self-inflicted incident.
- **Make removal trivial.** The baseline should be deletable in one step with zero user impact — and you
  should test that (`-Remove -Commit`) so the rollback is proven, not assumed.

## Rank by exposure, not opinion
- **Weight external exposure heavily.** A category shared "anyone with the link" out of SharePoint is a
  higher priority than a higher-volume category that never leaves the tenant. Prevalence × external exposure
  × movement volume beats gut feel.
- **Record the weighting.** Whatever formula you use to rank, write it down and agree it with stakeholders —
  a ranking whose logic is opaque gets argued with instead of acted on.
- **Surface the gaps as first-class output.** A candidate category with **no built-in detector** is not a
  hole to hide — it is a **detector-to-build** backlog item (custom SIT / EDM / trainable) for the
  enforcement project. Naming it is part of the value.

## Right-size the roadmap for an enforcement project
- **Every roadmap step is simulation-first.** Carry the house model forward: each proposed rollout stage
  starts in simulation, has a pass/fail gate and a rollback, and names its detector, location, action, ring,
  and order — so the enforcement team can pick it up and run it.
- **Sequence by ring, not big-bang.** Recommend a `DLP Rollout Ring – Stage1` pilot for the first category/
  location, then expansion — never a tenant-wide enforce as step one.
- **Progress the action, don't start at block.** Recommend audit → policy tip → allow-with-justification →
  block per category, so the enforcement project can adopt without a wall of false positives.

## Respect the discovery's licensing and privacy boundaries
- **Verify licensing/tenant before promising depth.** Content Explorer, Activity Explorer, on-demand
  classification, trainable classifiers, and DSPM are E5 / E5-Compliance and some are preview — scope the
  assessment to what the plan actually provides and note the gap, don't assert a capability you can't run.
- **Guard the Content Explorer Content Viewer role.** It exposes actual item content — grant it deliberately,
  to as few people as possible, log who holds it, and remove it when the assessment ends.
- **Discovery is privacy-sensitive.** You are looking at where personal and sensitive data lives — keep the
  data map access-controlled, don't copy sensitive samples out of Purview, and involve privacy stakeholders
  in how the evidence is handled.

## Hand off cleanly and stay inside the boundary
- **Ratify before you enforce.** The roadmap is a recommendation until compliance/privacy/legal/records
  ratify scope and enforced actions. Flag every such decision **[to be ratified]** — don't let the
  assessment quietly become policy.
- **The determinations are theirs.** Which categories are in scope, which classifiers legally apply, and the
  enforced action per category are governance decisions — you provide the exposure evidence and the
  technical route, they own the destination.
- **The assessment feeds enforcement; it isn't enforcement.** The output is a data map, a movement report,
  a ranked exposure view, a detector-build backlog, and a ratified roadmap — the complete, de-risked input
  to a DLP *enforcement* engagement that will, as always, start in simulation.
