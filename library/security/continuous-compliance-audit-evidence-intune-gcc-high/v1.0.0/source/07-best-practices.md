# Best Practices — Continuous Compliance Monitoring & Audit-Evidence Automation (Government / GCC High)

These practices keep your continuous-compliance program **defensible, low-risk, and audit-ready** over
time on a **US sovereign-cloud (GCC High / DoD)** tenant. They focus on the areas assessors and
Authorizing Officials scrutinize most: **staying in the right cloud**, **evidence retention**, and
**audit / POA&M response**.

---

## Stay in the sovereign cloud

- **Always confirm US Gov before you trust a result.** Every scheduled and interactive run should
  verify the Graph host is `graph.microsoft.us` (GCC High) or `dod-graph.microsoft.us` (DoD) via
  `Get-MgContext`. A run that silently landed on `graph.microsoft.com` produced Commercial-cloud data
  and is not evidence.
- **Keep every artifact in-boundary.** Evidence, POA&M exports, staging folders, Log Analytics
  workspaces, and any dashboard must live inside your **Azure Government / GCC High** authorization
  boundary — never a Commercial-cloud store. This protects data residency and the ATO.
- **Do not design on unavailable features.** Re-check `gcc-high-parity-notes.md` before adding any
  control or integration. Notably: the **Intune Power BI / Data-Warehouse connector** and the
  **ServiceNow connector** are **not available** in GCC High — use this solution's exports plus **Log
  Analytics** and a **manual POA&M import** instead.

## Evidence retention

- **Retain the raw and the report.** Keep both the per-device Validation output *and* the finished
  Evidence/POA&M exports. The raw measurement is the primary record; the report is the derived artifact.
- **Make evidence immutable where possible.** Store exports in a versioned or write-once
  (immutable / hold-enabled) in-boundary location. If the destination cannot enforce immutability,
  restrict write access to the compliance operators and enable file versioning and backup.
- **Match retention and cadence to your ATO, not convenience.** Set the retention period and monitoring
  cadence from your **FedRAMP High / DoD IL** obligation and audit cycle (R4) — commonly **monthly**
  continuous monitoring with maintained POA&M — not from disk space. **Verify against your assessor.**
- **Keep the full provenance chain.** Every export already carries collection timestamp, tenant,
  operator, control ID, expected value, observed value, and verdict — do not strip these fields when
  archiving or converting formats. They are what make the record credible.
- **Never store secrets in evidence.** Evidence is configuration state, not credentials. Do not place
  tokens, keys, or connection secrets in the output folder or the exports.
- **Timestamp and name consistently.** Keep the `CCAUDITG-<type>-<timestamp>` naming so files sort
  chronologically and map to a run. Do not overwrite prior exports — accumulate them; the *series* is
  the proof of *continuous* monitoring.
- **Back up the baseline reference too.** `CCAUDITG-Baseline.json` is the expected state your evidence
  is measured against; version it under change control alongside the evidence so a past verdict can be
  reproduced.

## Cadence and drift handling

- **Measure on a fixed schedule** (at least your ATO cadence, for example monthly) plus **after any
  approved baseline change** — re-baseline immediately so expected state stays accurate and does not
  generate false drift.
- **Treat every Drift/Missing/Non-conformant row as an event.** Open a POA&M item, remediate under
  change control, and re-measure to close. Do not let drift rows accumulate unactioned.
- **Distinguish Missing from Drift.** "Missing" (baseline never applied to a newly enrolled device) is
  usually a targeting/enrollment fix; "Drift" (was compliant, changed) is a remediation. Handle them
  differently.
- **Remediate safely.** Always run Remediation in preview (-WhatIf) first, review the exact controls,
  and only `-Commit` inside a change window with a rollback recorded (G8). Never bulk-remediate
  authentication-impacting controls without a pilot. Remember that **update-, BIOS-, and DHA-based**
  controls cannot be remediated via Intune in GCC High yet — handle those out-of-band and note it.

## Scoping and change control

- **Pilot every change.** Validate the method on `CCAUDITG-Pilot-Devices` before the fleet; validate any
  baseline change on the pilot before re-baselining fleet-wide.
- **Keep scope explicit.** Drive measurement from named groups (`CCAUDITG-Pilot-Devices`,
  `CCAUDITG-Fleet-Devices`) so "who the baseline applies to" is unambiguous and Missing is meaningful.
- **Least privilege for the operator.** Read scopes for measurement; grant write scopes only for the
  remediation identity, and only when remediating.

## Audit & POA&M response

- **Have a one-command evidence path.** When an assessor asks "prove control X is compliant across the
  fleet on date Y," you should be able to produce it from the retained exports (or a fresh run) without
  manual data gathering.
- **Lead with the current export, support with the trail.** Present the latest Evidence export as the
  point-in-time proof and the accumulated series as proof of *continuous* compliance over the period —
  the FedRAMP continuous-monitoring story.
- **Map POA&M rows to remediation records (NIST 800-53 CA-5).** For any failing control, show the POA&M
  item, the remediation change ticket, and the re-measurement that closed it — this demonstrates a
  working control process, which is often what the assessment is really testing. Import the POA&M CSV
  into your FedRAMP POA&M workbook / GRC manually (no native ServiceNow connector in GCC High).
- **Show the schedule.** Evidence that measurement runs on a defined cadence (the scheduled task and its
  history) is itself audit evidence of continuous monitoring.
- **Keep the method documented and reproducible.** Retain this documentation set and the script versions
  used so a past result can be reproduced and the process explained to an assessor.
- **Rotate and review access.** Periodically review who can read the evidence destination and who holds
  the remediation write role; remove stale access.

## What to avoid

- Do not run against the **Commercial** cloud by accident — always confirm US Gov.
- Do not hand-edit evidence exports — it destroys their credibility. Re-run instead.
- Do not measure against an unapproved or stale baseline — verdicts become meaningless.
- Do not monitor a control whose enforcement mechanism is **not available in GCC High** as if Intune
  were enforcing it — flag it as out-of-band.
- Do not expose the output folder broadly, or store any artifact outside your Gov boundary.
- Do not skip re-measurement after remediation — closure must be proven, not assumed.
