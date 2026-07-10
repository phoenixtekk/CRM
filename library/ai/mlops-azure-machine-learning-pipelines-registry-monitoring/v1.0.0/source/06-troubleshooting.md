# 6. Troubleshooting — MLOps on Azure Machine Learning

Common failures during an Azure ML MLOps rollout, as **symptom → cause → fix**. Re-run `AIMLOPS-Validate.ps1` after any fix to re-check the gates.

## Tooling / SDK
**Symptom:** `az ml ...` fails with `az: 'ml' is not in the 'az' command group`, or Python raises `ModuleNotFoundError: azure.ai.ml`.
**Cause:** The CLI `ml` extension or the `azure-ai-ml` SDK is not installed / too old (**R1**).
**Fix:** `az extension add -n ml` (or `az extension update -n ml`); `pip install -U azure-ai-ml mlflow azureml-mlflow`. Pin them in `requirements.txt`. *Verify current supported versions.*

**Symptom:** Code written against the old SDK (v1 `Workspace.from_config()`, `Experiment`, `Run`) errors against this solution.
**Cause:** Mixing SDK v1 and v2 object models.
**Fix:** Use only the v2 `MLClient` surface shown in `train_register_pipeline.py`; do not import `azureml.core`.

## Workspace / infrastructure deploy
**Symptom:** `infra.bicep` fails with `AuthorizationFailed` on the workspace or role assignment.
**Cause:** The identity lacks Contributor (+ User Access Administrator for the role assignment) on the resource group (**R2**).
**Fix:** Have an Owner grant the roles; re-run the `what-if` then deploy.

**Symptom:** Workspace create fails referencing a missing Storage/Key Vault/App Insights/ACR, or a name conflict.
**Cause:** A linked resource name collided (they are globally scoped for some types) or a provider is unregistered.
**Fix:** The Bicep derives unique names via `uniqueString`; if a name still collides, adjust the prefix. Register providers: `az provider register --namespace Microsoft.MachineLearningServices` (and `Microsoft.Storage`, `Microsoft.KeyVault`, `Microsoft.ContainerRegistry`).

## Training run / reproducibility
**Symptom:** A training job fails with "cannot access data" or a storage `403`.
**Cause:** The compute/workspace managed identity lacks the data-plane role on the linked storage (**R5**).
**Fix:** Confirm the **Storage Blob Data Contributor** assignment from `infra.bicep` targeted the right identity; re-assign if the principal ID changed.

**Symptom:** Re-running the same pipeline produces different metrics, or a run has **no lineage**.
**Cause:** The run read a raw file path instead of the **registered data asset**, or the **environment version floated** instead of being pinned.
**Fix:** Point the input at `azureml:churn-training-data@latest` (or a pinned version) and reference the pinned `train-env-sklearn:1` environment — never an unpinned image (Best Practices).

**Symptom:** The job stays queued and never starts.
**Cause:** The training cluster is scaled to zero and is spinning up a node, or `maxNodeCount` / quota is exhausted.
**Fix:** Wait for scale-up (expected on first run), or raise the cluster max nodes / request quota (Global Requirements G8). This is normal cost-saving behaviour, not a failure.

## Registration / metric gate
**Symptom:** A model with a poor metric still got registered.
**Cause:** The pipeline was run with a threshold set too low, or the gate comparison was bypassed.
**Fix:** Confirm `--min-auc` is the value the **data-science owner** set (**R6**) and that the run used `--register` only after review. The script skips registration when the metric is below threshold or `NaN` — check the evaluate step actually logged the metric via MLflow.

**Symptom:** `--register` did nothing and the run "passed".
**Cause:** This is the **dry-run** path — without `--register` the script trains, evaluates, and prints the gate decision but registers nothing (by design).
**Fix:** Re-run with `--register` once the metric is accepted (Implementation Step 5).

**Symptom:** Registered versions overwrite each other instead of incrementing.
**Cause:** A fixed version was passed to registration.
**Fix:** Let Azure ML auto-version — do not hard-code a model version on register.

## Model promotion
**Symptom:** Setting an MLflow model "stage" (Staging/Production) errors or is ignored.
**Cause:** MLflow's classic model **stages are deprecated**; Azure ML promotes via **model versions + labels/tags**, not the old stage API.
**Fix:** Promote by moving the `stage` tag/label (`az ml model update ... --set tags.stage=Staging`). *Verify the current promotion mechanism in your workspace.*

## Endpoints
**Symptom:** `az ml online-endpoint invoke` returns `401/403`.
**Cause:** The endpoint is keyless (`aad_token`) and the caller's identity lacks the invoke role (**R5**).
**Fix:** Grant the caller the endpoint's data-plane invoke role; use `az ml online-endpoint invoke` with an authenticated context.

**Symptom:** A new deployment returns `5xx` after traffic shift.
**Cause:** The scoring script or environment in the new (green) deployment is broken.
**Fix:** Keep traffic on **blue** (rollback is a traffic swap), read `az ml online-deployment get-logs`, fix green, validate at 0%, then shift again (Testing Test 6).

**Symptom:** Deployment fails on quota / instance count.
**Cause:** Endpoint compute quota exhausted for the VM SKU.
**Fix:** Lower `--instance-count`, choose an available SKU, or request quota. Remember online compute bills while it runs.

## Monitoring
**Symptom:** A drift monitor stays `NotStarted` or produces no result.
**Cause:** Production-data collection is not enabled on the deployment, or there is no **baseline** dataset to compare against (**R8**).
**Fix:** Enable data collection on the online deployment and set the baseline to `churn-training-data`; force a monitor run. *Some model-monitoring features are in preview — verify availability.*

**Symptom:** Monitors run but no alert arrives.
**Cause:** The **action group** is not attached, or the threshold was never crossed.
**Fix:** Attach `Action Group – MLOps – Alerts` to the monitor and confirm the recipient; test with skewed sample data (Testing Test 7).

## CI/CD pipeline
**Symptom:** The Deploy stage runs without pausing for approval.
**Cause:** The Environment approval check (required reviewers) is not attached to the Deploy stage (**R7**).
**Fix:** Add required reviewers to the `mlops-prod` Environment and confirm the deploy job references `environment: 'mlops-prod'` — re-run (Testing Test 8).

**Symptom:** Pipeline auth fails with a token/credential error.
**Cause:** The service connection is not configured for workload identity federation, or the federated subject/scope is wrong (**G5**).
**Fix:** Reconfigure the service connection for OIDC/workload identity federation and scope it to the workspace resource group; never fall back to a stored secret.
