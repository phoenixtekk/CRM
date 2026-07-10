# 2. Requirements — MLOps on Azure Machine Learning

The category-wide prerequisites (an Azure subscription with AI-service access and rights, Entra identity + managed identity + RBAC, private-networking capability, IaC + Python tooling and source control, a CI/CD platform with OIDC, a data source with a known permission model, a content-safety / responsible-AI posture, and cost controls/quotas) are covered once in **Global Requirements — AI** and are **not repeated here**. Confirm those first. Below are the prerequisites **specific to standing up MLOps on Azure Machine Learning**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Azure ML CLI extension and `azure-ai-ml` SDK v2 at supported versions
**Description:** The Azure CLI **`ml` extension** and the Python **`azure-ai-ml`** SDK (v2) plus **`mlflow`** and **`azureml-mlflow`**, at versions that support pipelines, model monitoring, and managed endpoints.
**Why required:** The pipeline, registry, endpoint, and monitoring steps are all driven by the v2 SDK/CLI; the v1 SDK and older CLI use a different, incompatible object model.
**How to verify:** `az extension show -n ml` and `python -c "import azure.ai.ml, mlflow; print(azure.ai.ml.__version__, mlflow.__version__)"` return current builds; `az version` is current. *Verify current supported SDK/CLI/MLflow versions — the Azure AI SDKs move fast.*
**How to implement if missing:** `az extension add -n ml` (or `az extension update -n ml`); `pip install -U azure-ai-ml mlflow azureml-mlflow`. Pin the versions in `requirements.txt` in the repo.

## R2. Rights to create the Azure ML workspace and its linked resources
**Description:** The identity has **Contributor** (plus **User Access Administrator** for role assignments) on the target resource group so it can create the workspace and its linked Storage, Key Vault, Application Insights, and Container Registry.
**Why required:** `infra.bicep` provisions the workspace and every linked resource and assigns managed-identity roles; without these rights the deploy fails.
**How to verify:** `az role assignment list --assignee <you> --resource-group <rg>` shows Contributor; a `what-if` of `infra.bicep` completes without an authorization error.
**How to implement if missing:** Have an Owner grant Contributor + User Access Administrator at the resource group. *Elevating scope is the customer's governance decision.*

## R3. Non-production Azure ML workspace to pilot in
**Description:** A separate **non-production workspace** (or a clearly separate resource group) to run the first training, registration, endpoint, and monitoring cycle before touching production.
**Why required:** The model pilots end-to-end in non-production first; deploying an unproven pipeline straight to a production workspace is exactly what MLOps exists to prevent.
**How to verify:** A workspace named `ML Workspace – Platform – NonProd` (`mlw-platform-nonprod`) exists or can be created by `infra.bicep` with the non-prod parameters.
**How to implement if missing:** Deploy `infra.bicep` with `env=nonprod` first (Implementation Step 2); only after validation deploy `env=prod`.

## R4. A registered data asset (training data) with a known permission model
**Description:** The training dataset registered as an **Azure ML data asset** (a versioned `uri_folder`/`uri_file`/`mltable` pointing at the linked Storage), with the source's ACL/sensitivity understood.
**Why required:** Reproducibility depends on the training run referencing a **versioned data asset**, not an ad-hoc file path; and the data's permissions/sensitivity must be respected (Global Requirements G6).
**How to verify:** `az ml data list -w <workspace> -g <rg>` shows the asset (e.g. `churn-training-data`); the discovery script reports data assets and their versions.
**How to implement if missing:** Register the asset: `az ml data create --name churn-training-data --path <path> --type uri_folder -w <workspace> -g <rg>`. *Data-sensitivity classification is the compliance team's decision.*

## R5. Managed identity and least-privilege data-plane roles for compute and endpoints
**Description:** The workspace, compute cluster, and endpoints use **managed identity** with least-privilege data-plane roles — e.g. **AzureML Data Scientist** for the training identity and **Storage Blob Data Contributor** on the linked storage — so jobs and endpoints authenticate without keys.
**Why required:** Keys leak; keyless managed-identity auth is the private-by-default posture (Global Requirements G2). Missing roles cause jobs to fail reading data or writing artifacts.
**How to verify:** The endpoint/compute has a system- or user-assigned identity (`az ml online-endpoint show ... --query identity`); the identity holds the data-plane roles on the storage/registry.
**How to implement if missing:** Enable the identity in `infra.bicep`/at endpoint creation and assign the roles (the Bicep includes the role assignments; adjust the principal IDs).

## R6. Model evaluation metric and acceptance threshold defined (by the data-science owner)
**Description:** A named **evaluation metric** (e.g. AUC, F1, RMSE) and a **numeric acceptance threshold** the candidate model must clear before it can be registered/promoted — decided by the data-science owner and encoded as a pipeline parameter.
**Why required:** The pipeline's registration gate compares the evaluated metric to the threshold; without an agreed threshold the gate is meaningless. **The value and the accept/reject decision are the data-science owner's** — the pipeline only enforces the number.
**How to verify:** The threshold is set in the pipeline parameters (e.g. `min_auc=0.80`) and recorded in the repo; a run below it does **not** register.
**How to implement if missing:** Have the data-science owner set the metric and threshold; encode it as a parameter. *Model acceptance is deferred to the data-science owner — this guide provides the gate, not the verdict.*

## R7. Pipeline approval gate and reviewer group for register/deploy
**Description:** A named group of approvers and a configured **environment approval** (Azure DevOps *Environment* checks, or a GitHub *Environment* with required reviewers) that the **register-to-production** and **deploy** stages must pass.
**Why required:** No model is promoted to production or deployed to a production endpoint without human approval after the metrics are reviewed — this is the control that makes automated retraining safe.
**How to verify:** The `mlops-prod` environment in the pipeline platform lists required reviewers; a test run pauses at the gate before deploy.
**How to implement if missing:** Create the environment, add the reviewer group, and reference it from the register/deploy stages (shown in `azure-pipelines.yml`). *Who may approve a production model deploy is the customer's change-control decision.*

## R8. Monitoring baseline dataset and an alert action group
**Description:** A **baseline (reference) dataset** — typically the training/validation data asset — for the drift monitor to compare production data against, plus an **Azure Monitor action group** to receive alerts (email/Teams/webhook).
**Why required:** Data-drift monitoring is defined as "production vs. baseline"; without a registered baseline there is nothing to compare to, and without an action group the alerts have nowhere to go.
**How to verify:** The baseline data asset exists (R4) and an action group (`Action Group – MLOps – Alerts`) is created (`az monitor action-group show`).
**How to implement if missing:** Register the baseline asset and create the action group (`az monitor action-group create ...`); reference both when configuring the monitor (Implementation Step 8). *Who receives and triages alerts is the customer's operations decision.*
