# 8. Deliverables Summary — Azure Landing Zone with Bicep

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What an Azure landing zone is — management groups, Azure Policy as Bicep, RBAC baseline, deployment stacks, hub-spoke networking/DNS; how Bicep and what-if work; benefits and limitations |
| 2. Requirements | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (DevOps) | Category-wide prerequisites, published once |
| 3. Implementation | Exact, ordered steps — scaffold repo, deploy hierarchy, assign policy in audit, RBAC baseline, hub-spoke network, CI/CD, then prod + deny |
| 5. Testing | Validation procedures with pass/fail gates |
| 6. Troubleshooting | Field issues → cause → fix |
| 7. Best Practices | Field-proven recommendations and where to go next |

## IaC and automation artifacts
| File | What it does |
|---|---|
| `IACBICEP-Discovery.ps1` | Read-only estate discovery — existing management groups, policy assignments, custom roles, standing Owner assignments, and VNet address ranges (the address-overlap check) |
| `main.bicep` | The core landing-zone template — management-group hierarchy, policy/initiative assignments, custom-role + RBAC baseline, and hub-spoke network with private DNS, toggled by `deployHierarchy` / `deployPolicy` / `deployNetwork` parameters |
| `IACBICEP-Validate.ps1` | What-if / read-only validation — confirms the hierarchy, guardrail assignment (in Audit), custom-role assignment, and hub-spoke peering/DNS against the pass/fail gates |
| `azure-pipelines.yml` | CI/CD pipeline (Azure DevOps; GitHub Actions notes inline) — Validate → What-If → **approval gate** → Deploy (deployment stack), what-if-first and approval-gated |
| `IACBICEP-Report.ps1` | Governance posture report — policy compliance, non-compliant resources, RBAC/standing-Owner summary, and drift against the deployed stack |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five IaC / automation artifacts (`main.bicep`, `azure-pipelines.yml`, and three PowerShell scripts) in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand** — what-if-first, approval-gated, with deployment-stack rollback.

**Delivered as a Complete Solution Package (PDF + Word + scripts).**

## Outcome
A Microsoft-native, versioned Azure foundation expressed entirely as Bicep in Git — management groups, policy guardrails, least-privilege identity, and hub-spoke connectivity — governed and repeatable, proven on a non-production scope before it reaches production.
