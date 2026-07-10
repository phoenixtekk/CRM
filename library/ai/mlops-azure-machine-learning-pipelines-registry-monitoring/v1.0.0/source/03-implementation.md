# 3. Implementation — MLOps on Azure Machine Learning

Follow these steps in order. Everything is **pilot-first**: you build and prove the whole loop in a **non-production workspace** with registration and deploy **gated**, validate, then expand to production behind pipeline approval. Every object you create is named with the convention **`<Purpose> – <Scope> – <Stage>`** and that exact name is reused in later steps, testing, and the scripts. The worked example is a benign **customer-churn classifier**; substitute your own model. Placeholder tenant is `contoso.com` / `contoso.onmicrosoft.com`.

> Run every training run so it is **reproducible and tracked** (versioned data asset + pinned environment + MLflow). Never register or deploy to production without the metric gate **and** the pipeline approval. All examples use the Azure CLI `ml` extension and the `azure-ai-ml` SDK v2; the pipeline runs the same commands.

## Naming you will create (reuse these exact names)
| Object | Name |
|---|---|
| Non-prod workspace | `ML Workspace – Platform – NonProd` (`mlw-platform-nonprod`) |
| Prod workspace | `ML Workspace – Platform – Prod` (`mlw-platform-prod`) |
| Training compute cluster | `Training Cluster – Platform – NonProd` (`cpu-train-nonprod`) |
| Training environment (as code) | `Training Environment – Sklearn – v1` (`train-env-sklearn`) |
| Registered training data asset | `churn-training-data` (versioned) |
| Train + evaluate pipeline job | `Train-Eval Pipeline – Churn – NonProd` |
| Registered model | `churn-classifier` (versions `:1`, `:2`, …) |
| Model stage labels | `Candidate` → `Staging` → `Production` |
| Managed online endpoint | `Online Endpoint – Churn – Prod` (`churn-online-prod`) |
| Online deployment (blue/green) | `Deployment – Churn – Blue` / `Deployment – Churn – Green` |
| Managed batch endpoint | `Batch Endpoint – Churn – Prod` (`churn-batch-prod`) |
| Data-drift monitor | `Monitor – Churn – Drift` |
| Model-performance monitor | `Monitor – Churn – Perf` |
| Alert action group | `Action Group – MLOps – Alerts` |
| CI/CD pipeline | `MLOps Pipeline – Churn – CICD` |
| Pipeline prod environment (gate) | `mlops-prod` |

## Step 1 — Assess: inventory the current ML practice (read-only)
1. Sign in: `az login` (add `--tenant contoso.onmicrosoft.com` if you have several) and `az account set --subscription "<non-prod sub id>"`.
2. Run the discovery script from the `scripts/` folder:
   `powershell -ExecutionPolicy Bypass -File .\AIMLOPS-Discovery.ps1 -ResourceGroup <rg>`
   It reports any existing Azure ML workspaces, compute, registered models and versions, data assets, endpoints, and monitors. Save the output — it is your baseline and confirms **R3/R4**.
3. Confirm your identity has the rights from **R2** on the target resource group and that the `ml` extension + SDK are at supported versions (**R1**).

## Step 2 — Configure: provision the workspace and compute as code (non-prod first)
1. Clone the empty repo (Global Requirements G4) and add the provided files: `infra.bicep`, `train_register_pipeline.py`, `azure-pipelines.yml` at the root, and `AIMLOPS-Discovery.ps1` / `AIMLOPS-Validate.ps1` under `scripts/`. Add a `requirements.txt` pinning `azure-ai-ml`, `mlflow`, `azureml-mlflow`, `scikit-learn` (**R1**).
2. **Preview with what-if** (nothing is applied):
   `az deployment group what-if -g <rg> --template-file infra.bicep --parameters env=nonprod workspaceName=mlw-platform-nonprod`
3. Read the preview — it should create the workspace **`ML Workspace – Platform – NonProd`** plus its linked Storage, Key Vault, Application Insights, and Container Registry, and the training cluster **`Training Cluster – Platform – NonProd`** (scale-to-zero).
4. Deploy: `az deployment group create -g <rg> --template-file infra.bicep --parameters env=nonprod workspaceName=mlw-platform-nonprod`.
5. Set the workspace defaults so later commands are shorter: `az configure --defaults workspace=mlw-platform-nonprod group=<rg>`.
6. Commit to a **feature branch** and open a pull request — infrastructure and pipeline changes are reviewed, never pushed straight to `main`.

## Step 3 — Configure: register the data asset and define the environment as code
1. Register the training data as a **versioned data asset** (**R4**):
   `az ml data create --name churn-training-data --path ./data/churn --type uri_folder`
   Reuse the name `churn-training-data` everywhere; the run pins a specific version for reproducibility.
2. Create the **environment as code** so the run is reproducible: define `Training Environment – Sklearn – v1` from a conda file:
   `az ml environment create --name train-env-sklearn --version 1 --conda-file ./env/conda.yml --image mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu20.04`
   *Verify the current base image tag in your region.* Pin the environment version in the pipeline — never let it float.

## Step 4 — Configure: run the reproducible train + evaluate pipeline (registration in DRY-RUN)
1. Run the training pipeline in its default **plan / dry-run** mode — it trains and evaluates but does **not** register:
   `python train_register_pipeline.py --workspace mlw-platform-nonprod --resource-group <rg> --data-asset churn-training-data --min-auc 0.80`
   This submits the pipeline job **`Train-Eval Pipeline – Churn – NonProd`** (prep → train → evaluate), tracked in MLflow.
2. Open **Azure ML Studio → Jobs** and confirm the run recorded its **parameters, metrics (AUC/F1), and the model artifact**, and that its **lineage** links back to `churn-training-data` and the pinned environment.
3. Note the evaluated metric. The registration gate compares it to **`--min-auc`** (the threshold from **R6**). **The accept/reject decision is the data-science owner's** — the pipeline only enforces the number.

## Step 5 — Configure: register the candidate model (gated on the metric)
1. Once the data-science owner accepts the metric, re-run with registration enabled:
   `python train_register_pipeline.py --workspace mlw-platform-nonprod --resource-group <rg> --data-asset churn-training-data --min-auc 0.80 --register`
   If the evaluated metric clears `--min-auc`, the pipeline registers **`churn-classifier`** as a new version and labels it **`Candidate`**; if it does not clear the threshold, **registration is skipped** and the run is marked failed-gate.
2. Confirm the version and its lineage: `az ml model list --name churn-classifier -o table` and open the model in Studio to see the **run, data asset, and metrics** attached (this is the registry lineage).
3. Promote Candidate → **Staging** by moving the label (a controlled action): `az ml model update --name churn-classifier --version <n> --set tags.stage=Staging`. *MLflow classic stages are deprecated; Azure ML uses versions + labels/tags — verify the current promotion mechanism in your workspace.*

## Step 6 — Pilot: deploy to a managed online endpoint (blue/green)
1. Create the endpoint (non-prod first): `az ml online-endpoint create --name churn-online-prod --auth-mode aad_token` — display name **`Online Endpoint – Churn – Prod`**, keyless (managed identity, **R5**), no public network access.
2. Deploy the Staging model as the **blue** deployment with a small instance count:
   `az ml online-deployment create --name blue --endpoint churn-online-prod --model churn-classifier:<n> --instance-count 1` — this is **`Deployment – Churn – Blue`**.
3. Send **0% live traffic** first, smoke-test with a sample payload (`az ml online-endpoint invoke --name churn-online-prod --request-file ./sample-request.json`), then shift traffic: `az ml online-endpoint update --name churn-online-prod --traffic "blue=100"`.
4. For a later model, deploy **`Deployment – Churn – Green`** alongside blue, validate at 0%, then swap traffic — your rollback is shifting traffic back to blue.
5. *(Optional)* Create the **batch endpoint** for scheduled/large scoring: `az ml batch-endpoint create --name churn-batch-prod` (**`Batch Endpoint – Churn – Prod`**) and a deployment referencing the same model version.

## Step 7 — Wire the CI/CD pipeline (train → register → approval → deploy)
1. In Azure DevOps (or GitHub), create the pipeline **`MLOps Pipeline – Churn – CICD`** from `azure-pipelines.yml`.
2. Confirm the **service connection** uses workload identity federation (Global Requirements G5) and the **`mlops-prod` environment** has the approval gate and reviewer group from **R7**.
3. The pipeline stages are: **Validate** (lint, `requirements.txt`, unit tests) → **Train+Evaluate** (submits the pipeline job, publishes metrics) → **Register** (labels the version `Candidate`/`Staging` if the metric gate passes) → **Approval** (manual gate on `mlops-prod`) → **Deploy** (blue/green to the managed endpoint). Merging to `main` runs Validate → Train → Register; **Deploy only runs after approval**.

## Step 8 — Configure: turn on drift and performance monitoring with alerts
1. Create the alert **`Action Group – MLOps – Alerts`**: `az monitor action-group create --name mlops-alerts --resource-group <rg> --short-name mlops --action email ops <ops@contoso.com>`.
2. Configure the **data-drift monitor** **`Monitor – Churn – Drift`** comparing the online endpoint's collected production data against the **baseline** (`churn-training-data`, **R8**), on a schedule, alerting the action group when drift crosses the threshold. *Enable production-data collection on the deployment first; model monitoring is configured via `az ml schedule` / the monitoring YAML — verify current availability, some monitoring features are in preview.*
3. Configure the **model-performance monitor** **`Monitor – Churn – Perf`** to track the production metric (once ground-truth labels are available) against the training baseline, alerting on decay.
4. Confirm both monitors appear under **Studio → Monitoring** and that a forced run reaches the action group (Testing Test 7).

## Step 9 — Validate, then Expand: production workspace behind approval
1. Run the validation script against non-prod: `powershell -ExecutionPolicy Bypass -File .\AIMLOPS-Validate.ps1 -Workspace mlw-platform-nonprod -ResourceGroup <rg> -ModelName churn-classifier` and clear every gate in the **Testing** guide.
2. Deploy the **production workspace**: `az deployment group create -g <prod-rg> --template-file infra.bicep --parameters env=prod workspaceName=mlw-platform-prod` (what-if first).
3. Let the pipeline run **Validate → Train → Register** against production, review the metrics and what the Register stage will label, **approve** the `mlops-prod` gate, and let **Deploy** roll out blue/green to **`Online Endpoint – Churn – Prod`** in the production workspace.
4. Enable the **scheduled retrain** trigger (pipeline schedule or new-data trigger) — every retrain still runs the same metric gate and approval before it can replace the Production model.
5. **Rollback** at any point: shift endpoint traffic back to the previous **blue** deployment and/or re-deploy the prior registered model version (`churn-classifier:<n-1>`). The registry keeps every version, so rollback is a redeploy, not a rebuild.

> Onboard the next model by pointing the same pipeline at a new training script, data asset, and threshold — it inherits the workspace, registry, endpoint pattern, gates, and monitoring automatically. That is the repeatable payoff of the MLOps foundation.
