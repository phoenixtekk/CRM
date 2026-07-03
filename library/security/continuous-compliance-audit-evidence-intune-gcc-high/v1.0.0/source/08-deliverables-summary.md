# Deliverables Summary — Continuous Compliance Monitoring & Audit-Evidence Automation (Government / GCC High)

This package gives you everything needed to **monitor CIS/STIG baseline drift and automate audit
evidence** for Intune + Entra endpoints **on a GCC High (US sovereign-cloud) tenant** — a repeatable
operations method you keep and reuse between audits, with the correct **US Gov portals and endpoints**
and the **Commercial-vs-GCC High parity gaps** called out. Below is exactly what is included and what
each piece is for.

## Documentation

| Document | What it gives you |
|---|---|
| **01-solution-overview.md** | The continuous-compliance model (baseline → measure → detect drift → evidence/POA&M → remediate/track), **why GCC High is a different solution not a re-login**, a **Commercial vs GCC High — what's different** section, and where evidence comes from. |
| **02-requirements.md** | Every prerequisite (existing GCC High baseline, Intune/Entra roles + **US Gov Graph** read access, in-boundary reporting destination, evidence-retention needs, pilot scope) with Verify / Implement-if-missing. |
| **global-requirements-security.md** | Category-level prerequisites shared by all security solutions (tenant, Intune, roles, enrollment, pilot group, OS, network, change control). |
| **03-implementation.md** | Exact ordered steps using the **GCC High portals** (`intune.microsoft.us`, `entra.microsoft.us`), with **inline parity caveats** where they matter: define the monitored control set, measure current vs. baseline, detect drift, and generate audit-evidence + POA&M-ready gap exports — pilot then fleet-wide, with pass/fail gates. |
| **05-testing.md** | Formal pass/fail gates: **correct cloud**, control measured, drift detected, evidence exported, remediation closes the gap, scheduled cadence. |
| **06-troubleshooting.md** | Symptom → cause → fix for the common issues, including **GCC-High-specific gotchas** (wrong cloud, unavailable features, US Gov consent). |
| **07-best-practices.md** | Staying in the sovereign cloud, evidence retention, and audit/POA&M response for a defensible FedRAMP High / DoD IL program. |
| **gcc-high-parity-notes.md** | The cited **Commercial-vs-GCC High parity reference** (portals/endpoints, reporting/analytics, remediation/update tooling, identity, FedRAMP/POA&M context, licensing) with Microsoft citations. |
| **08-deliverables-summary.md** | This file. |
| **executive-summary.md** | One-page business summary for decision-makers. |

## PowerShell scripts (Microsoft Graph SDK, US Gov endpoints)

All discovery/measurement scripts are **read-only**. The two scripts that can change state default to
**preview (-WhatIf)** and require an explicit `-Commit` to act. **All default to
`-Environment USGov`** (pass `-Environment USGovDoD` on a DoD/IL5 tenant).

| Script | Purpose | Changes state? |
|---|---|---|
| **CCAUDITG-Discovery.ps1** | Inventory the control state of your baseline (Intune profiles, compliance policies, Security Baselines, Entra CA / auth-method policies) from **US Gov Graph**; can emit a baseline-reference template. | No — read-only |
| **CCAUDITG-Validation.ps1** | Measure per-device conformance of current state vs. the baseline reference; verdicts: Pass / Drift / Missing / Non-conformant. | No — read-only |
| **CCAUDITG-Report.ps1** | Produce the dated audit-evidence export and the POA&M-ready gap export from a validation run. | No — read-only |
| **CCAUDITG-Remediation.ps1** | Safely re-apply drifted settings to return controls to baseline. | Preview by default (-WhatIf); `-Commit` to act |
| **CCAUDITG-Set-ScopeTargeting.ps1** | Build/populate the pilot and fleet target groups (`CCAUDITG-Pilot-Devices`, `CCAUDITG-Fleet-Devices`). | Preview by default (-WhatIf); `-Commit` to act |

## Named objects you will create and reuse

- **`CCAUDITG-Pilot-Devices`** — Entra security group for the pilot scope.
- **`CCAUDITG-Fleet-Devices`** — Entra security group for fleet-wide scope.
- **`CCAUDITG-Baseline.json`** — the approved expected-state reference measured against.
- **Evidence exports** — `CCAUDITG-Evidence-<timestamp>.csv/json`.
- **POA&M exports** — `CCAUDITG-POAM-<timestamp>.csv`.

## Outcome

When deployed, you can prove endpoint compliance **on any day**, not just deployment day — from inside
your **GCC High / DoD** boundary: drift is detected automatically, audit evidence is exported on demand,
and gaps arrive POA&M-ready for FedRAMP continuous monitoring — with a method and scripts you own and
reuse across audit cycles.

## Scope note

The specific **CIS Benchmark and DISA STIG rule IDs and official control text are deferred to CIS and
DISA** (Microsoft points GCC High/DoD admins to the DISA STIGs library on `public.cyber.mil`). This
solution supplies the precise **monitoring and evidence method** on Intune + Entra in the US sovereign
cloud; you supply which of your deployed baseline objects encode each control. Feature availability is
doc-confirmed against Microsoft's *Intune Government Service overview* — **re-verify for GCC High/DoD**
before relying on any single row (see `gcc-high-parity-notes.md`).
