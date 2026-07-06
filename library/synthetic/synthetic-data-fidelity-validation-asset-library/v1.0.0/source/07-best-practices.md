# Best Practices

Durable practices for building and growing a fidelity & validation asset library.

## Keep fidelity, utility, and privacy as three separate verdicts
Never collapse them into one number. A dataset can pass statistical fidelity and still fail
utility (a worse model) or coverage (missing the rare cohort), and can be high-fidelity yet
high-disclosure-risk. Report and gate each axis independently.

## Utility is the acceptance test, not statistical fidelity
Statistical distances are necessary but not sufficient. Where an AI use case exists, make a
TSTR-style utility gap the primary acceptance gate — it measures the thing you actually care
about: does the model behave the same on synthetic data.

## Build the Reference Profile once, aggregate-only, in-place
Compute the profile inside the governed environment and export only aggregate statistics. Never
copy row-level real data into the harness. Hash the profile so every Evidence Report is traceable
to the exact reference it was measured against.

## Parameterize what changes; freeze the method
Reusability comes from separating the fixed *method* (metrics, tolerances, coverage rules) from
the per-dataset *parameters* (dataset path, dates, reference profile). If validating a new
dataset requires editing the metric code, refactor the difference into config.

## Set tolerances with the AI/QA owners, before measuring
Agree "faithful enough" thresholds up front and record them in the Validation Suite config.
Thresholds chosen after seeing the results are not gates — they are rationalizations.

## Coverage is spec-driven, not discovered
Enumerate the required cohorts/edge cases from the AI use case and check the dataset against that
spec. Do not infer coverage from whatever the generator happened to produce.

## Version every asset; grow the library deliberately
Commit the Field Manifest, Reference Profile, metric suite, coverage spec, Validation Suite, and
every Evidence Report to a version-controlled store. Each shipped dataset should be traceable to
the gates it passed and the asset versions used.

## Make failures actionable
A FAIL should name the specific gate and field/cohort so the generation team knows exactly what
to fix. Route privacy signals to the privacy office as signals — never let a tool imply a
de-identification determination.

## Re-validate when anything upstream changes
A new generator version, a schema change, a shifted reference, or a new AI use case invalidates
prior evidence. Re-run the suite and issue a fresh Evidence Report; do not rely on stale proof.

## Defer legal/regulatory calls explicitly
HIPAA/HITRUST de-identification, IRB/privacy sign-off, and disclosure-risk acceptance belong to
privacy/compliance/legal. The library supplies the technical method and evidence; keep that
boundary visible in every report.
