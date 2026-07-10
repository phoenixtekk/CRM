# 8. Deliverables Summary — MLOps on Azure Machine Learning

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What MLOps on Azure ML is — workspace/compute/environment as code, reproducible pipelines + MLflow, model registry with versioning/lineage/stage promotion, managed endpoints, drift/performance monitoring; how the technology works; scope and limitations |
| 2. Requirements | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (AI) | Category-wide prerequisites, published once |
| 3. Implementation | Exact, ordered steps — provision workspace/compute as Bicep, register data + environment, run the reproducible train+evaluate pipeline, register on the metric gate, deploy blue/green to a managed endpoint, wire CI/CD, turn on monitoring, then prod behind approval |
| 5. Testing | Validation procedures with pass/fail gates |
| 6. Troubleshooting | Field issues → cause → fix |
| 7. Best Practices | Field-proven recommendations and where to go next |

## Automation artifacts
| File | What it does |
|---|---|
| `AIMLOPS-Discovery.ps1` | Read-only discovery — existing Azure ML workspaces, compute, registered models and versions, data assets, endpoints, and monitors; your pre-deployment baseline (**R3/R4**) |
| `infra.bicep` | The core infrastructure-as-code template — the Azure ML workspace and its linked Storage / Key Vault / Application Insights / Container Registry, the scale-to-zero training compute cluster, and managed-identity role assignments; deployed what-if-first for non-prod then prod |
| `train_register_pipeline.py` | The reproducible **train → evaluate → register** pipeline in Python (`azure-ai-ml` SDK v2 + MLflow) — prep/train/evaluate steps, MLflow tracking and lineage, and a **metric-gated register that defaults to a dry-run** (registers only with `--register` and only if the evaluated metric clears the threshold) |
| `azure-pipelines.yml` | CI/CD pipeline (Azure DevOps; GitHub Actions notes inline) — Validate → Train+Evaluate → Register → **approval gate** → Deploy (blue/green), metric-gated and approval-gated |
| `AIMLOPS-Validate.ps1` | Read-only / plan-only validation + posture — confirms the workspace and compute, a registered model version with lineage, endpoint health and traffic split, and monitor status against the Testing guide's pass/fail gates (also surfaces the registry and monitoring report) |

> Note on the five artifacts: this solution's automation spans the right languages for each job — **Bicep** for infrastructure, **Python (SDK v2 + MLflow)** for the training/registration pipeline, **YAML** for CI/CD, and **PowerShell** for read-only discovery and validation. The validation script also carries the registry/endpoint/monitoring reporting, so a separate report script is not needed.

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five automation artifacts (`infra.bicep`, `train_register_pipeline.py`, `azure-pipelines.yml`, and two PowerShell scripts) in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand** — reproducible-and-tracked, metric-gated, approval-gated, with blue/green and prior-version rollback.

**Delivered as a Complete Solution Package (PDF + Word + scripts).**

## Outcome
An MLOps foundation on Azure Machine Learning where every model is **reproducible, versioned, approved, and monitored** in production — proven in a non-production workspace before it reaches production, with model-acceptance decisions kept where they belong, with the data-science owner.
