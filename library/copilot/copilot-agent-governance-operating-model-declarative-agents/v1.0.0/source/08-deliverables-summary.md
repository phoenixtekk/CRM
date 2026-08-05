# Deliverables Summary

This solution is a complete, self-contained operating model for governing business-user-built
declarative agents (Agent Builder / Copilot Studio / SharePoint agents). Everything below is included
in the package.

## Documentation

| Document | What it gives you |
|---|---|
| **Solution Overview** | The problem, the explicit scope boundary (what this is and is NOT), the seven components of the model, how declarative agents are built/shared/approved/managed (verified against Microsoft Learn), how it plugs into Purview/Entra/Defender, and the Government note. |
| **Requirements** | Ten prerequisites (sponsor, licensing, the AI Administrator role, Entra group rights, system of record, data-governance posture, CAB interface, role-holders, Graph PowerShell, build-surface scope) — each with Description / Why / Verify / Implement-if-missing and exact roles/scopes. |
| **Implementation** | Thirteen ordered steps that stand up the whole model: baseline the estate, define the RACI, build the register/decision-record/retirement-log, create the six governance groups, set the Copilot Control System enforcement controls, publish the standards, stand up intake and the Agent Review Board with change classification, set the sharing policy and access review, define lifecycle and retirement, stamp the existing estate, pilot, and expand. |
| **Testing & Validation** | Eight PASS/FAIL governance gates that prove the model *functions* (build eligibility, org-wide sharing restriction, intake/approval, org-catalog admin approval, sensitive-data review, broadly-shared/ownerless detection, real retirement, scorecard trend) plus pilot exit criteria. |
| **Troubleshooting** | Organisational and technical failure modes with symptoms, causes, and fixes — from "users share agents around the gate" to "the copilotPackages API returns 403". |
| **Best Practices** | The habits that make the model stick: govern sharing not building, block early, never delete first, reassign before orphaning, keep the ARB fast, reuse existing Purview controls, shorter review intervals for agents. |
| **Executive Summary** | A one-page brief for the sponsor and stakeholders. |

## Governance artefacts (pre-named, ready to create)

- `AGBGOV – Agent Register` (SharePoint list)
- `AGBGOV – Agent Decision Record` (SharePoint list)
- `AGBGOV – Agent Retirement Log` (SharePoint list)
- `AGBGOV – Shared-Agent Access Review` (SharePoint list)
- `AGBGOV – Agent Governance RACI – Enterprise – v1.0`
- `AGBGOV – Agent Standards – Enterprise – v1.0`
- `AGBGOV – Agent Change Classification – Enterprise – v1.0`
- `AGBGOV – Agent Intake Request Form` + `AGBGOV – Agent Intake Queue`
- `AGBGOV – Agent Review Board – Enterprise – Fortnightly`
- Six Entra security groups: `AGBGOV – Agent Builders`, `AGBGOV – Agent Sharing – Org-Wide Approved`,
  `AGBGOV – Agent Owners`, `AGBGOV – Agent Business Sponsors`, `AGBGOV – Agent Data-Security
  Reviewers`, `AGBGOV – Agent Admins`

## PowerShell scripts (Microsoft Graph, read-only, cloud-aware)

All five accept `-Environment Global | USGov | USGovDoD` and are read-only by default; any Graph call
that is preview/licence-gated degrades gracefully to the Agent Registry CSV export.

| Script | Purpose |
|---|---|
| **AGBGOV-Discovery.ps1** | Governance baseline: current declarative agents, owners, and sharing posture — seeds the register. Graph `copilotPackages` path with automatic CSV-export fallback. |
| **AGBGOV-Validation.ps1** | Tests each agent against the seven governance gates (owner, sponsor, approval, data review, sharing justification, naming, review currency); PASS/FAIL per gate; optional pipeline exit code. |
| **AGBGOV-Report.ps1** | Trendable governance scorecard (coverage %, sharing exposure, ownerless, overdue reviews, sensitive-without-reviewer, optional intake-to-decision time). |
| **AGBGOV-Export-ApprovalEvidence.ps1** | Assembles a timestamped, audit-ready approval evidence pack from the decision record plus (optional) directory audit trail. |
| **AGBGOV-Review-SharedAgents.ps1** | Flags org-wide, large-group, and ownerless agents for periodic access review with recommended actions. |

## Scope boundary (what is intentionally delivered elsewhere)

- The **deep, repeatable agent inventory / sharing export and the Graph endpoint diagnostic** →
  sibling product *Copilot Agent Builder — Inventory, Sharing Governance & Export*.
- **Copilot data governance** (sensitivity labels, DLP for Microsoft 365 Copilot, audit/eDiscovery) →
  the Copilot data-governance / DLP guardrails solution.
- **SharePoint / OneDrive oversharing remediation** → the Copilot oversharing / SharePoint-permissions
  solution.
- **Building** agents (authoring instructions, knowledge, capabilities) → the maker's task in Agent
  Builder / Copilot Studio.

This model defines *when* those are invoked and *who* is accountable — it does not reproduce them.
