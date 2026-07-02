# Best Practices — Continuous Compliance Monitoring & Audit-Evidence Automation

These practices keep your continuous-compliance program **defensible, low-risk, and audit-ready** over
time. They focus on the two areas auditors and regulators scrutinize most: **evidence retention** and
**audit response**.

---

## Evidence retention

- **Retain the raw and the report.** Keep both the per-device Validation output *and* the finished
  Evidence/POA&M exports. The raw measurement is the primary record; the report is the derived
  artifact. An auditor may ask to see the underlying data.
- **Make evidence immutable where possible.** Store exports in a versioned or write-once (immutable /
  hold-enabled) location. If the destination cannot enforce immutability, restrict write access to the
  compliance operators and enable file versioning and backup.
- **Match retention to your framework, not convenience.** Set the retention period from your
  regulatory requirement and audit cycle (R4), not from disk space. When in doubt, keep longer.
- **Keep the full provenance chain.** Every export already carries collection timestamp, tenant,
  operator, control ID, expected value, observed value, and verdict — do not strip these fields when
  archiving or converting formats. They are what make the record credible.
- **Never store secrets in evidence.** Evidence is configuration state, not credentials. Do not place
  tokens, keys, or connection secrets in the output folder or the exports.
- **Timestamp and name consistently.** Keep the `CCAUDIT-<type>-<timestamp>` naming so files sort
  chronologically and map to a run. Do not overwrite prior exports — accumulate them.
- **Back up the baseline reference too.** `CCAUDIT-Baseline.json` is the expected state your evidence
  is measured against; version it under change control alongside the evidence so a past verdict can be
  reproduced.

## Cadence and drift handling

- **Measure on a fixed schedule** (for example weekly) plus **after any approved baseline change** —
  re-baseline immediately so expected state stays accurate and does not generate false drift.
- **Treat every Drift/Missing/Non-conformant row as an event.** Open a POA&M item, remediate under
  change control, and re-measure to close. Do not let drift rows accumulate unactioned.
- **Distinguish Missing from Drift.** "Missing" (baseline never applied to a newly enrolled device)
  is usually a targeting/enrollment fix; "Drift" (was compliant, changed) is a remediation. Handle
  them differently.
- **Remediate safely.** Always run Remediation in preview (-WhatIf) first, review the exact controls,
  and only `-Commit` inside a change window with a rollback recorded (G8). Never bulk-remediate
  authentication-impacting controls without a pilot.

## Scoping and change control

- **Pilot every change.** Validate the method on `CCAUDIT-Pilot-Devices` before the fleet; validate
  any baseline change on the pilot before re-baselining fleet-wide.
- **Keep scope explicit.** Drive measurement from named groups (`CCAUDIT-Pilot-Devices`,
  `CCAUDIT-Fleet-Devices`) so "who the baseline applies to" is unambiguous and Missing is meaningful.
- **Least privilege for the operator.** Read scopes for measurement; grant write scopes only for the
  remediation identity, and only when remediating.

## Audit response

- **Have a one-command evidence path.** When an auditor asks "prove control X is compliant across the
  fleet on date Y," you should be able to produce it from the retained exports (or a fresh run)
  without manual data gathering.
- **Lead with the current export, support with the trail.** Present the latest Evidence export as the
  point-in-time proof and the accumulated series as proof of *continuous* compliance over the period.
- **Map POA&M rows to remediation records.** For any failing control, show the POA&M item, the
  remediation change ticket, and the re-measurement that closed it — this demonstrates a working
  control process, which is often what the audit is really assessing.
- **Show the schedule.** Evidence that the measurement runs on a defined cadence (the scheduled task
  and its history) is itself audit evidence of continuous monitoring.
- **Keep the method documented and reproducible.** Retain this documentation set and the script
  versions used so a past result can be reproduced and the process explained to an assessor.
- **Rotate and review access.** Periodically review who can read the evidence destination and who holds
  the remediation write role; remove stale access.

## What to avoid

- Do not hand-edit evidence exports — it destroys their credibility. Re-run instead.
- Do not measure against an unapproved or stale baseline — verdicts become meaningless.
- Do not expose the output folder broadly — evidence is sensitive configuration state.
- Do not skip re-measurement after remediation — closure must be proven, not assumed.
