# 8. Deliverables Summary — Intune-as-Code (Graph & Terraform, CI/CD)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Intune-as-code is — baseline export, policy-as-code repo, CI/CD (validate→plan→review→deploy), dev→prod promotion, backup/restore, drift detection; how Terraform Graph and plan work; benefits and limitations |
| 2. Requirements | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (DevOps) | Category-wide prerequisites, published once |
| 3. Implementation | Exact, ordered steps — export tenant, register SPN, scaffold repo, plan/apply to dev/pilot, wire pipeline, promote to prod, schedule drift/backup |
| 5. Testing | Validation procedures with pass/fail gates |
| 6. Troubleshooting | Field issues → cause → fix |
| 7. Best Practices | Field-proven recommendations and where to go next |

## IaC and automation artifacts
| File | What it does |
|---|---|
| `IACINTUNE-Discovery.ps1` | Read-only baseline **export** — reads existing device configuration, compliance, and app-protection policies from Microsoft Graph to JSON (your starting point and first backup) |
| `main.tf` | The core **Terraform** — defines the scoped starter set (`Windows Baseline – Corporate – Config`, `Compliance Minimum – Corporate – Compliance`, `App Protection – Mobile – MAM`) via the Microsoft Graph provider, assigned to the pilot group; includes `versions.tf`-style pinned provider + backend guidance |
| `IACINTUNE-Validate.ps1` | Read-only / plan validation — confirms the coded policies exist, are pilot-scoped, and that a fresh `terraform plan` shows no drift, against the pass/fail gates |
| `azure-pipelines.yml` | CI/CD pipeline (Azure DevOps; GitHub Actions notes inline) — Validate → Plan → **approval gate** → (pre-apply backup) → Apply, plan-first and approval-gated, with dev/prod workspaces |
| `IACINTUNE-Report.ps1` | **Backup / restore / drift** report — exports the tenant to a timestamped backup, checks for drift via `terraform plan`, and supports a restore dry run |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five IaC / automation artifacts (`main.tf`, `azure-pipelines.yml`, and three PowerShell scripts) in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand** — plan-first, approval-gated, with backup/restore as rollback.

**Delivered as a Complete Solution Package (PDF + Word + scripts).**

## Outcome
An Intune tenant managed like software — every policy exported, versioned, reviewed, and promoted through CI/CD with backup and drift detection — proven against a dev tenant / pilot group before it reaches production.
