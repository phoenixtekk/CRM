# 3. Operating Guide — Managing Microsoft Purview: Operations & Governance

This is the **operating** guide: how to stand up and then *run* the Purview program on a cadence. Work
through **Part A** once to establish the operating model, then run **Part B** as the recurring heartbeat.
Inventory, roles, and config come from **Security & Compliance PowerShell** (`Connect-IPPSSession`) and the
Microsoft Purview portal; triggered alerts come from **Microsoft Graph** (`/security/alerts_v2`). Every
config change is run **`-WhatIf` first** and only committed with `-Commit` under change control. Artifact
names follow the `<Purpose> – <Scope> – <Stage>` convention and are reused verbatim across docs, scripts,
and the portal.

> **Model:** Baseline → run the policy lifecycle (design → **simulate/test** → enforce → review) → work the
> Compliance Manager cadence → triage + roll up alerts → review roles → measure health → control every
> change. High-impact policy changes are **always piloted in simulation/test before enforcement**.

## Named operating artifacts
| Artifact | Name |
|---|---|
| Policy register (all in-scope policies + owners) | `Policy Register – Purview – Governance` |
| Known-good policy baseline (drift reference) | `Policy Baseline – Purview – <date>` |
| Change record | `Change Record – Purview – ChangeControl` |
| Compliance Manager improvement tracker | `Improvement Actions – Compliance Manager – Cadence` |
| Alert triage queue | `Alert Triage – Purview – Ops` |
| Alert rollup report | `Alert Rollup – Purview – Report` |
| Role & access review record | `Access Review – Purview Roles – Quarterly` |
| KPI dashboard | `KPI Dashboard – Purview – ProgramHealth` |
| Operating review calendar | `Review Calendar – Purview – Operating` |

---
# Part A — Stand up the operating model (once)

## Step 1 — Baseline the estate (Assess)
1. Confirm your least-privilege operations roles are in place (Requirement 2.2) and connect:
   `Connect-IPPSSession`.
2. Run `PURVOPS-Discovery.ps1` to inventory every DLP, sensitivity-label, label-policy, auto-labeling, and
   retention policy with its current **mode** (Enable / Test / Disable). It writes the `Policy Register –
   Purview – Governance`.
3. Review the register with stakeholders and record an **owner** for each policy family. Once the state is
   agreed as known-good, run `PURVOPS-Discovery.ps1 -SaveBaseline` to write `Policy Baseline – Purview –
   <date>` — the reference all future drift checks diff against (Requirement 2.4).

## Step 2 — Define the policy lifecycle + change control (Configure)
1. Adopt the lifecycle for every policy: **design → simulate/test → enforce → review.** New and changed
   DLP and auto-labeling policies are created/edited in **simulation or test** mode first
   (`TestWithNotifications` / `TestWithoutNotifications`), never straight to enforce.
2. Stand up the change record `Change Record – Purview – ChangeControl` and the approval path + change
   window (Requirement 2.9). Every live-policy edit becomes a change request → review → windowed change →
   recorded outcome → rollback plan.
3. Confirm the operational helper is safe by default: `PURVOPS-Remediation.ps1 -WhatIf` prints the intended
   change and makes **none**; only `-Commit` writes, and it stamps the change record.

## Step 3 — Wire alert triage + reporting (Configure)
1. Define the triage queue: categories (DLP / insider risk / information-protection / audit), severities,
   and SLAs (Requirement 2.7). This is `Alert Triage – Purview – Ops`.
2. Confirm the Graph security read scope is consented (Requirement 2.3), then run `PURVOPS-Report.ps1` to
   produce the first `Alert Rollup – Purview – Report` — alert volume by category, severity, and status.
3. Assign the **daily triage owner** and the **weekly rollup reviewer**.

## Step 4 — Set up the Compliance Manager cadence (Configure)
1. In the portal, **Compliance Manager → Improvement actions**, review the actions, owners, and score.
   **Export** the improvement actions to CSV (Compliance Manager has **no public API**, Requirement 2.5).
2. Run `PURVOPS-KpiReport.ps1 -ComplianceManagerCsv <export.csv>` to fold the improvement actions and
   compliance score into `Improvement Actions – Compliance Manager – Cadence` and the KPI dashboard.
3. Assign each open improvement action an owner and due date; agree the **monthly** burn-down forum.
   *(Determination of which regulatory obligations apply remains with compliance/legal — this cadence tracks
   and evidences the technical actions, not the regulatory determination.)*

## Step 5 — Schedule the role & access review (Configure)
1. Capture the approved role membership as the attestation baseline (Requirement 2.6):
   `PURVOPS-Validation.ps1 -SaveApprovedList` after the accountable owner confirms current membership is
   correct.
2. Schedule the **quarterly** review that will diff live membership against that approved list and produce
   `Access Review – Purview Roles – Quarterly`.

## Step 6 — Stand up the KPI dashboard + review calendar (Configure)
1. Agree the KPI set and thresholds (Requirement 2.8). Run `PURVOPS-KpiReport.ps1` to compose `KPI Dashboard
   – Purview – ProgramHealth` from live telemetry (policy-mode distribution, alert volume, label/DLP
   coverage) plus the Compliance Manager export.
2. Publish `Review Calendar – Purview – Operating` with the daily/weekly/monthly/quarterly/annual cadences
   and named owners, and schedule the recurring **program-health review**.

---
# Part B — Run the program (recurring heartbeat)

## RB-01 — Policy lifecycle & change control (weekly drift + quarterly review)
1. **Weekly:** run `PURVOPS-Discovery.ps1 -CompareBaseline` — it diffs the live estate against `Policy
   Baseline – Purview – <date>` and reports **drift**: new, removed, or mode-changed policies. Investigate
   every drift item; an unexpected mode change (e.g. a policy silently moved test → enforce, or enforce →
   disabled) is a change-control event.
2. **To promote a piloted policy to enforce:** confirm its simulation/test results are clean, raise a change
   request, then `PURVOPS-Remediation.ps1 -Action PromotePolicy -PolicyName "<name>" -WhatIf` to preview,
   and `-Commit` in the change window. **Pass:** mode is now `Enable` and the change is recorded.
   **Rollback:** `-Action RollbackPolicy -PolicyName "<name>" -Commit` returns it to test/disabled.
3. **Quarterly:** re-review every *live* policy against its business intent; retire or re-scope as needed
   (each edit through change control). Re-baseline (`-SaveBaseline`) after the approved change set.

## RB-02 — Compliance Manager improvement cadence (monthly)
1. Export improvement actions from Compliance Manager and run `PURVOPS-KpiReport.ps1 -ComplianceManagerCsv
   <export.csv>` to refresh `Improvement Actions – Compliance Manager – Cadence`.
2. In the monthly forum, burn down actions: confirm completed ones, chase overdue ones, reassign as needed.
   Record the compliance-score trend as a KPI. **Pass:** overdue actions trending down, score stable/up.

## RB-03 — Alert triage & incident rollup (daily triage, weekly rollup)
1. **Daily:** the triage owner works `Alert Triage – Purview – Ops` — for each alert, classify
   (true/false positive), action or escalate within its SLA, and note tuning needed. Insider-risk and
   communication-compliance alerts follow the **role-separated, privacy-by-design** handling; case
   **outcomes are deferred to HR/legal** — operations triages and routes, it does not adjudicate.
2. **Weekly:** run `PURVOPS-Report.ps1` to refresh `Alert Rollup – Purview – Report`. Review volume by
   category/severity, mean triage time against SLA, and recurring false-positive sources to feed policy
   tuning (via RB-01 change control). **Pass:** high-severity alerts within SLA; false-positive rate falling.

## RB-04 — Role & access review (quarterly)
1. Run `PURVOPS-Validation.ps1 -ApprovedListCsv <approved.csv>` to diff live Purview role-group membership
   against the approved baseline (Requirement 2.6), producing `Access Review – Purview Roles – Quarterly`.
2. The accountable owner attests each membership: confirm, or remove departed/role-changed members under
   change control. Flag any highly privileged account (e.g. multiple sensitive role groups) for
   justification. Re-save the approved list (`-SaveApprovedList`) after attestation.
   **Pass:** zero unexplained additions; all privileged memberships attested.

## RB-05 — KPI dashboard & program-health review (monthly refresh, quarterly/annual review)
1. **Monthly:** run `PURVOPS-KpiReport.ps1` to refresh `KPI Dashboard – Purview – ProgramHealth`.
2. **Quarterly:** walk the dashboard in the program-health review — policies enforced vs test, alert volume
   and triage time, improvement-action burn-down, compliance-score trend, privileged-role count — against
   thresholds. Decide tuning and scope changes; feed them back through RB-01.
3. **Annually:** reassess scope and coverage (new workloads, new regulations flagged by compliance) and set
   next year's targets. **Pass:** KPIs within threshold or with an owned remediation plan.

---
### Order of operations
`Baseline → define lifecycle + change control → wire triage/reporting → set CM cadence → schedule access
review → stand up KPIs → then run the heartbeat: weekly drift · daily triage / weekly rollup · monthly CM +
KPI · quarterly access + policy review · annual program review — every change -WhatIf-first and recorded.`
