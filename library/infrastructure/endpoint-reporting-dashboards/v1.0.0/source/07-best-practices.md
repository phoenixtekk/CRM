# 7. Best Practices — Endpoint Reporting & Dashboards

- **Define the KPI and its single source first.** The most important practice: one authoritative
  source per KPI means the same question always returns the same number. Disagreement starts when two
  people pull the same KPI two different ways.
- **Validate before you distribute.** Reconcile every KPI against the console on the pilot scope
  before broad distribution — the pilot gate is what makes the numbers trustworthy.
- **Automate the pull, don't hand-build it.** Use the Graph `exportJobs` so the figures are
  reproduced by the same code every cycle, not re-derived in a spreadsheet.
- **Name everything consistently.** Use `<Purpose> – <Scope> – <Stage>` for groups, the export app,
  the report definition, and the distribution schedule, and reuse the names verbatim so the objects
  are findable and auditable.
- **Keep pilot and fleet scopes separate** until the pilot reconciles; never report a number you have
  not validated against its source.
- **Store secrets outside the code.** The export app's client secret/certificate lives in an
  environment secret or secrets vault — never in the script or a config committed to source.
- **Use read-only access for reporting.** Discovery, validation, and the KPI report only need read
  scopes; do not grant write permissions to a reporting identity.
- **Cover the whole fleet.** If any devices are still managed by Configuration Manager, include the
  SSRS reports so the consolidated view is complete, not just the Intune slice.
- **Timestamp and archive exports.** Keep dated export files so an auditor can see the exact data
  behind a past report.
- **Document the cadence and tolerances.** Record the distribution schedule and the reconciliation
  tolerance used in validation, so the process is repeatable by the next operator.
