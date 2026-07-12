# 8. Deliverables Summary — Microsoft Defender for Cloud

## Documentation (source/)
1. **executive-summary.md** — what the complete solution is, the four-phase lifecycle, the outcome, the
   boundary (posture remediation cross-references the CSPM & Secure Score Remediation solution), and
   effort.
2. **01-solution-overview.md** — what Defender for Cloud is (CSPM + CWPP), how the technology works, the
   four phases mapped to the standard deployment model (Assess → Configure → Pilot → Validate → Expand),
   scope, out of scope, and the connections/authentication used.
3. **02-requirements.md** — the solution-specific prerequisites (MG hierarchy, deployment identity,
   providers, plan/cost decisions, Servers agents, export/SIEM, alert tuning + response workflow, pilot
   subscription for labs, attendee access, multicloud inputs, PoC RG + criteria, change control), each
   with Description / Why / Verify / Implement-if-missing; references the category-level
   `global-requirements-defender.md`.
4. **03-implementation.md** — the ordered, click-by-click build across the four phases (Architect →
   Protect → Enable the team → Prove value) and Expand, with every object named `<Purpose> – <Scope> –
   <Stage>` and reused verbatim.
5. **05-testing.md** — per-phase validation with explicit pass/fail gates, including the enablement
   knowledge-check and the PoC scorecard gates.
6. **06-troubleshooting.md** — symptom → cause → fix for the common failures across all four phases.
7. **07-best-practices.md** — keep-it-clean guidance and where to go next in the catalog.
8. **08-deliverables-summary.md** — this document.
9. **global-requirements-defender.md** — the category-level prerequisites (published once, referenced by
   the requirements guide).

## Scripts (scripts/)
Seven consolidated artifacts. PowerShell uses `Az` modules and is **read-only** except the single
preview-gated deploy/enable script and the PoC helper; the reference IaC is Bicep; the lab/hunting pack
is KQL.

1. **MDCFULL-Discovery.ps1** — read-only estate readiness: MG hierarchy, per-subscription Defender plan
   tiers, provider registration, Log Analytics workspaces, AWS/GCP connectors, agent coverage, and
   resource counts (cost drivers). Writes a JSON snapshot.
2. **MDCFULL-Validate.ps1** — read-only validation across the lifecycle: plans enabled + inheritance,
   providers, Servers MDE/agent coverage, continuous export, the notify-only response workflow, and (with
   `-PoC`) the PoC recommendation/Secure Score/alerts/compliance.
3. **MDCFULL-Report.ps1** — coverage, cost, and alert reporting with a saveable baseline for
   drift tracking (`-Mode Coverage|Cost|Alerts`).
4. **main.bicep** — the **reference architecture** skeleton: enables Defender for Cloud plans at
   **management-group** scope (via the built-in plan-configuration policy initiative) so subscriptions
   inherit protection. Deploy **what-if first**; a reference to adapt, not a blind apply.
5. **MDCFULL-Deploy.ps1** — the only change script: **`-WhatIf`-gated and cost-gated**. Wraps `main.bicep`
   as a management-group deployment (`-ManagementGroupId`) and enables workload plans per subscription
   (`-SubscriptionId -Plans …`) via `Az.Security`. Preview by default; `-Apply` to change.
6. **MDCFULL-LabPack.kql** — the read-only ARG/KQL lab and hunting pack (recommendations by impact,
   Secure Score by control, security-alert triage, advanced-hunting alerts, unhealthy-resource drill-down,
   Secure-Score trend, and the workload-alert validation query). Save the marked queries under the
   runbook names.
7. **MDCFULL-PoC.ps1** — the guided proof-of-concept helper (`-Action Assess|TestSignal|Scorecard|
   Teardown`): benign signal only (sample alerts + a benign misconfigured test resource + EICAR),
   scored against your criteria, with a **`-WhatIf`-gated teardown that disables the paid plan to stop
   billing**.

## Package
Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the eight guides compiled to a Word
document and PDF, plus all seven scripts (five PowerShell, one Bicep, one KQL) in a single ZIP, yours to
keep and reuse on every wave and every project.
