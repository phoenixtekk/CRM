# 7. Best Practices — Automatic Sensitivity Labeling at Scale (Microsoft Purview)

- **Simulate before you label — always.** Every service-side auto-labeling policy is created in
  **simulation** (`TestWithoutNotifications`) and reviewed for precision **before** it ever touches
  content. Simulation is the single control that makes labeling at scale safe: you see exactly what
  *would* be labeled, measure the false-positive rate, and tune — with **zero** impact on users. The
  configuration helper defaults to `-WhatIf` for the same reason.
- **Start with a few high-precision conditions.** A rule with one strong sensitive-information type at a
  sensible `-MinCount` and confidence beats a broad rule that fires everywhere. Precision first, coverage
  second — you can always widen conditions once the match set is trusted.
- **Recommend before you auto-apply (client-side).** Configure client-side auto-labeling to
  **recommend** first so users are prompted, not surprised. Switch to silent **auto-apply** only after
  the recommended behavior is trusted and the false-positive rate is low.
- **Enforce by location, not all at once.** After simulation is accepted, enforce on a **pilot location
  subset** first, validate that enforced labels match the accepted simulation, and only then expand to
  `All`. Staged expansion keeps the blast radius small and the rollback cheap.
- **Respect encryption as high-impact.** Where the applied label **encrypts**, applying it at scale
  changes access to content and is hard to reverse cleanly. Confirm in simulation exactly which items
  would be encrypted, and treat the first enforcement window with extra care.
- **Decide existing-label behavior deliberately (§2.8).** By default the service will not lower a
  higher-priority label a user set manually — but the behavior is configurable and
  **tenant/version-sensitive**. Make it a conscious decision with the data owner and **verify it in the
  simulation match set** before enforcing, so deliberate manual classification is never silently
  overwritten.
- **The classification determination is the data owner's, not yours.** *Which* content is sensitive and
  *which* label it carries is a compliance/records/data-owner call. You provide the technical method to
  apply the label accurately and the evidence that it does — you do not decide the scheme.
- **Keep the levers healthy.** Auto-labeling precision is entirely a function of the sensitive
  information types, keywords, and trainable classifiers behind each rule. A thin or noisy taxonomy caps
  how precisely you can label; invest in the SITs/classifiers before blaming the policy.
- **Allow for scan latency and limits.** Service-side simulation and enforcement scan large volumes over
  time — results are **not** instantaneous and item/throughput limits apply. **Verify current limits for
  your tenant** and give the scan time before concluding a policy is broken.
- **Keep the rollback one command away.** Every enforced policy should be one change
  (`-BackToSimulation -Commit`) from returning to simulation. Note that rolling back **stops new
  labeling but does not un-label** already-labeled content — make sure that is understood before you
  enforce.
- **Report on a cadence.** Run the read-only `Discovery → SimulationReport → Reporting → ScopeHealth`
  chain regularly so labeling coverage and policy health stay visible as data and adoption drift, not
  measured once at go-live.
- **Verify availability, never assume it.** Automatic labeling (client- and service-side), adaptive
  scopes for location targeting, and some cmdlet parameters are licensing-dependent and evolving. When a
  path, mode value, or parameter differs from this guide, confirm it in your tenant and use the current
  equivalent — do not force a path that is not there.
