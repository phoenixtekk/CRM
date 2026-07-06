# Best Practices

Durable practices for running privacy-conscious test environments. These keep the work **safe by
design and defensible on review** as scope grows.

## Keep the determination separate from the method
- Engineering produces **metrics + evidence**; privacy/compliance/legal makes the **determination**.
  Never let a green k-anonymity number stand in for a regulatory sign-off. Wire the sign-off into the
  release gate so the two cannot be conflated.

## Define "safe" as a number before you generate
- Agree **Risk Threshold – Pilot – v1** (minimum k, minimum l, max disclosure-risk) *before* building
  the pipeline. A threshold set after seeing results is not a control.

## Classification is the highest-leverage decision
- Most re-ID risk hides in **misclassified quasi-identifiers** (dates, geography, rare categories).
  Treat the classification as a reviewed artifact, not a script output — the scanner suggests, the
  privacy stakeholder decides.

## Never let real PHI touch the shared environment
- The minimized source extract stays in the **privacy-controlled zone**; only *released* de-identified
  or synthetic datasets enter the isolated test environment. If a re-identification key exists, it is
  held **outside** that environment under the privacy function's custody.

## Default to suppression; pseudonymize only with a documented need
- Suppress direct identifiers by default. Only pseudonymize where a governed re-linkage requirement is
  written down, and then segregate the key. A key stored beside the data defeats the exercise.

## Treat the fidelity/privacy trade-off explicitly
- Stronger generalization lowers re-ID risk and lowers utility. Use the pilot to find an acceptable
  point on that curve, and record the choice. Don't over-generalize into uselessness or under-
  generalize into exposure by accident.

## Watch for memorization on the synthesis route
- A synthesizer that memorizes real records fails privacy even though "no real data was copied."
  Always run membership/attribute-inference checks on synthetic output, not just on de-identified
  output.

## Make every released dataset traceable
- Version the classification, pipeline config, thresholds, and evidence record together. Any released
  test dataset should be reproducible from — and justified by — its captured evidence.

## Re-run the gates on every expansion
- Expansion never inherits the pilot's PASS. Each new domain/cohort gets its own classification, risk
  assessment, and evidence record.

## Roll back cleanly on failure
- On any gate failure, **do not release** — retain the failing evidence (it documents the hold),
  tighten the policy, and repeat. Because only released datasets enter the environment, a held
  candidate carries zero exposure.

## Defer version-specific vendor behavior
- Where a commercial synthesizer or de-identification platform is used, integrate it at the pattern
  level and **verify version-specific behavior against the vendor's documentation** rather than
  assuming console internals.
