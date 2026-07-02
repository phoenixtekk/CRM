# Deliverables Summary — Continuous Compliance Monitoring & Audit-Evidence Automation

This package gives you everything needed to **monitor CIS/STIG baseline drift and automate audit
evidence** for Intune + Entra endpoints — a repeatable operations method you keep and reuse between
audits. Below is exactly what is included and what each piece is for.

## Documentation

| Document | What it gives you |
|---|---|
| **01-solution-overview.md** | The continuous-compliance model (baseline → measure → detect drift → evidence/POA&M → remediate/track), how it complements a one-time CIS/STIG build, and where evidence comes from. |
| **02-requirements.md** | Every prerequisite (existing baseline, Intune/Entra roles + Graph read access, reporting destination, evidence-retention needs, pilot scope) with Verify / Implement-if-missing. |
| **global-requirements-security.md** | Category-level prerequisites shared by all security solutions (tenant, Intune, roles, enrollment, pilot group, OS, network, change control). |
| **03-implementation.md** | Exact ordered steps: define the monitored control set, measure current vs. baseline, schedule drift detection, and generate audit-evidence + POA&M-ready gap exports — pilot then fleet-wide, with pass/fail gates. |
| **05-testing.md** | Formal pass/fail gates: control measured, drift detected, evidence exported, remediation closes the gap, scheduled cadence. |
| **06-troubleshooting.md** | Symptom → cause → fix for the common issues (connectivity/scopes, empty measurement, missed drift, export/retention, remediation). |
| **07-best-practices.md** | Evidence retention and audit-response practices for a defensible program. |
| **08-deliverables-summary.md** | This file. |
| **executive-summary.md** | One-page business summary for decision-makers. |

## PowerShell scripts (Microsoft Graph SDK)

All discovery/measurement scripts are **read-only**. The two scripts that can change state default to
**preview (-WhatIf)** and require an explicit `-Commit` to act.

| Script | Purpose | Changes state? |
|---|---|---|
| **CCAUDIT-Discovery.ps1** | Inventory the control state of your baseline (Intune profiles, compliance policies, Security Baselines, Entra CA / auth-method policies); can emit a baseline-reference template. | No — read-only |
| **CCAUDIT-Validation.ps1** | Measure per-device conformance of current state vs. the baseline reference; verdicts: Pass / Drift / Missing / Non-conformant. | No — read-only |
| **CCAUDIT-Report.ps1** | Produce the dated audit-evidence export and the POA&M-ready gap export from a validation run. | No — read-only |
| **CCAUDIT-Remediation.ps1** | Safely re-apply drifted settings to return controls to baseline. | Preview by default (-WhatIf); `-Commit` to act |
| **CCAUDIT-Set-ScopeTargeting.ps1** | Build/populate the pilot and fleet target groups (`CCAUDIT-Pilot-Devices`, `CCAUDIT-Fleet-Devices`). | Preview by default (-WhatIf); `-Commit` to act |

## Named objects you will create and reuse

- **`CCAUDIT-Pilot-Devices`** — Entra security group for the pilot scope.
- **`CCAUDIT-Fleet-Devices`** — Entra security group for fleet-wide scope.
- **`CCAUDIT-Baseline.json`** — the approved expected-state reference measured against.
- **Evidence exports** — `CCAUDIT-Evidence-<timestamp>.csv/json`.
- **POA&M exports** — `CCAUDIT-POAM-<timestamp>.csv`.

## Outcome

When deployed, you can prove endpoint compliance **on any day**, not just deployment day: drift is
detected automatically, audit evidence is exported on demand, and gaps arrive POA&M-ready — with a
method and scripts you own and reuse across audit cycles.

## Scope note

The specific **CIS Benchmark and DISA STIG rule IDs and official control text are deferred to CIS and
DISA**. This solution supplies the precise **monitoring and evidence method** on Intune + Entra; you
supply which of your deployed baseline objects encode each control.
