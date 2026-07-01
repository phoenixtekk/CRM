# 7. Best Practices — Workspace ONE to Intune Coexistence & Cutover Runbook

- **Never run a tenant-wide "require compliant device" during coexistence.** Scope every Conditional
  Access compliance/enrollment policy to the **current cohort group** and widen it one cohort at a
  time. This is the single most important guardrail against migration lockouts.
- **Pick one compliance authority and write it down.** Two compliance engines reporting to
  Conditional Access produce flapping compliant/non-compliant states. Let the target (Intune) own
  compliance for a cohort the moment it enrolls.
- **Cut over in cohorts, smallest and lowest-risk first.** A pilot cohort proves the guardrails and
  the cutover sequence before any high-impact group is touched.
- **Gate every cohort.** Apply the `Go/No-Go Checklist – Cohort – Validate` before and after each
  cutover; a cohort that fails a gate rolls back rather than limping forward.
- **Test the rollback on the pilot before you need it in production.** A rollback that has never been
  run is not a rollback. Prove it once on the pilot cohort.
- **Never double-target the same app, profile, or certificate.** Keep the source delivering until the
  cohort cuts over, then remove the source assignment as part of the cutover — not before, not after.
- **Remove the source assignment as part of cutover, not later.** A device left dual-managed is a
  device waiting to receive conflicting policy. Confirm Intune-only with the status report.
- **Assign once, repeat everywhere.** Build the `Coexistence Guardrails – Tenant – Configure` one
  time and reuse it verbatim per cohort; only the cohort group changes between waves.
- **Report before every gate.** Run `WS1COEX-Report.ps1` so go/no-go decisions are based on the live
  management state, not assumptions.
- **Defer Workspace ONE internals to VMware.** Perform source-console actions per VMware's
  documentation; this runbook flags them rather than guessing at a console that changes independently.
- **Communicate the window to users.** A short note about the cutover and what to expect dramatically
  reduces tickets during the coexistence period.
- **Document each cohort's result.** Record gate outcomes, the cutover date, and any rollback for
  audits and repeatability across the remaining waves.
