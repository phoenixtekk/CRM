# 1. Solution Overview — MLOps on Azure Machine Learning

## What MLOps on Azure ML is
**MLOps** is the practice of building, shipping, and operating machine-learning models with the same discipline as software: everything is in source control, every result is reproducible, every change is reviewed and approved, and the running system is monitored. **Azure Machine Learning (Azure ML)** is Microsoft's managed platform for that lifecycle — a **workspace** that holds your compute, data, environments, jobs, models, and endpoints, all reachable from the `azure-ai-ml` Python SDK (v2), the Azure CLI `ml` extension, and the Azure ML Studio portal.

This solution assembles those pieces into a working MLOps loop. Instead of a model trained by hand in a notebook, you get: the **workspace and compute defined as code (Bicep)**; a **reproducible training + evaluation pipeline** whose runs are tracked by **MLflow**; a **model registry** that versions every model with its lineage; **CI/CD** that runs **train → register → deploy behind an approval**; **managed endpoints** for real-time and batch scoring; and **monitoring** that watches for data drift and model-performance decay and raises alerts.

## How the technology works
- **Workspace** — the top-level Azure ML resource. It brings together a linked **Storage account** (data and artifacts), **Key Vault** (secrets), **Application Insights** (telemetry), and optionally a **Container Registry** (custom environments). You create it once, as code.
- **Compute as code** — training runs on a **compute cluster** (auto-scaling VMs that scale to zero when idle) and endpoints run on managed compute. Both are declared as code so they are reproducible and cost-controlled.
- **Environment as code** — an **environment** is a versioned, containerized definition of the exact Python/Conda dependencies a job runs in. Pinning it is what makes a run reproducible months later.
- **Jobs and pipelines** — a **command job** runs one script; a **pipeline job** chains steps (prep → train → evaluate → register) into a repeatable graph. Each run records its inputs, code, parameters, metrics, and outputs.
- **MLflow tracking** — Azure ML is MLflow-compatible. Your training code calls `mlflow.log_metric`/`log_param`/`log_model`, and the workspace stores that run's metrics, parameters, and the model artifact — so every model is traceable to the exact run, data, and code that produced it (**lineage**).
- **Model registry** — registered models are **versioned** (`churn-classifier:1`, `:2`, …). Promotion between stages (**Candidate → Staging → Production**) is done with labels/tags and is the controlled gate before a model can be deployed. *MLflow's classic model "stages" are deprecated in newer MLflow; Azure ML uses model versions plus labels/registries — verify the current promotion mechanism in your workspace.*
- **Managed endpoints** — a **managed online endpoint** serves real-time scoring over HTTPS with blue/green deployments; a **managed batch endpoint** scores large datasets on a schedule or on demand. Neither is exposed publicly by default (private-by-default per the Global Requirements).
- **Model monitoring** — Azure ML **model monitoring** compares live production data against the training baseline and computes **data-drift** and **model-performance** signals on a schedule, firing alerts (via an Azure Monitor action group) when a signal crosses a threshold. *Model monitoring features move quickly and some are in preview — verify current availability in your tenant.*

## What the MLOps foundation contains
1. **Workspace + compute + environment as code** — `infra.bicep` provisions the workspace and its linked resources and a training compute cluster; the environment is defined and versioned from the SDK.
2. **Reproducible train + evaluate pipeline** — a Python pipeline (SDK v2 + MLflow) that prepares data, trains, evaluates against a held-out set, and **conditionally registers** the model — with registration defaulting to a **plan/dry-run** until explicitly enabled.
3. **Model registry with versioning, lineage, and stage promotion** — every model version carries the run, data asset, and metrics that produced it; promotion Candidate → Staging → Production is a labelled, gated action.
4. **CI/CD train→register→deploy with approvals** — an `azure-pipelines.yml` (GitHub Actions equivalent noted) that trains, registers, and then deploys to the managed endpoint **only after a human approves** the environment gate.
5. **Managed endpoints + drift/performance monitoring** — an online (and optional batch) endpoint with blue/green rollout, plus data-drift and model-performance monitors wired to alerts.

## What you can control
- **Model and data** — which training script, data asset, and evaluation metric/threshold define "good enough" (the threshold is a data-science decision the pipeline enforces, not decides).
- **Compute shape and cost** — VM SKU, min/max nodes, and scale-to-zero idle time on the training cluster.
- **Promotion policy** — which metric gate a model must clear to move Candidate → Staging → Production, and who approves it.
- **Deployment strategy** — online vs. batch, blue/green split, and the approval reviewers on the production gate.
- **Monitoring thresholds** — which features to watch for drift, the performance metric to track, the schedule, and the alert recipients.
- **Rollout scope** — a non-production workspace first, production only after validation and approval.

## What is out of scope / limitations (be honest with buyers)
- This is the **MLOps platform and process**, not the data science. It does not choose your algorithm, engineer your features, or decide whether a model's accuracy is acceptable — **model-acceptance decisions belong to the data-science owner**; the solution supplies reproducibility, versioning, gates, and monitoring.
- **Model monitoring, registries, and some endpoint features may be in preview or vary by region and by Azure environment (Commercial vs. Government)** — *verify current availability in your tenant.* The SDK/CLI/MLflow and API versions used are marked to verify.
- It does not label or classify your training data, nor make the **data-classification, responsible-AI, or acceptable-use determinations** — those belong to the customer's compliance / legal / trust-and-safety functions (Global Requirements G6/G7).
- It secures the platform (private endpoints, managed identity, no keys) but does not replace application-level security review of the model's consumers.
- Retraining and production deployment are **approval-gated by design** — nothing retrains or ships to production without a human gate.

## Authentication and connections used
- **Azure CLI (`az` + the `ml` extension) / `azure-ai-ml` SDK v2** authenticated with **`DefaultAzureCredential`** (your signed-in identity locally; a managed identity or OIDC federation in CI/CD) — no stored keys.
- **Managed identity + RBAC** on the workspace and endpoints for keyless access to Storage, Key Vault, and the registry (Global Requirements G2) — with the **AzureML Data Scientist** / endpoint roles scoped least-privilege.
- **MLflow tracking URI** set to the Azure ML workspace, so tracking flows into the workspace with no separate MLflow server.
- A **CI/CD service connection** using **workload identity federation (OIDC)** — no secret — scoped to the workspace resource group (Global Requirements G4/G5).

## The standard deployment model
> **Assess** the current ML practice (where models live, how they're trained/deployed, what's tracked) → **configure** the workspace, compute, environment, training pipeline, registry, and endpoints as code → **pilot** by training and deploying in a **non-production workspace** with registration/deploy gated → **validate** with the testing gates (reproducible run, registered version with lineage, endpoint scoring, monitor firing) → **expand** to the production workspace behind pipeline approval, then turn on scheduled retraining and monitoring. The repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, reproducible-and-tracked, approval-gated, with a documented rollback (blue/green swap-back and prior model version).
