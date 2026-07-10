# 5. Testing — MLOps on Azure Machine Learning

Validate the MLOps loop against the **non-production workspace** before you expand to production. Each test has an explicit **pass/fail gate**. Reference the scripts by name; they are read-only / plan-only except where noted. Run `AIMLOPS-Validate.ps1` after any fix to re-check the gates.

## Test 1 — Workspace and compute exist as code
- **How:** `powershell -ExecutionPolicy Bypass -File .\AIMLOPS-Validate.ps1 -Workspace mlw-platform-nonprod -ResourceGroup <rg> -ModelName churn-classifier`, or in Studio open **Compute**.
- **Pass:** `ML Workspace – Platform – NonProd` exists with its linked Storage/Key Vault/App Insights, and `Training Cluster – Platform – NonProd` is present and scales to zero when idle.
- **Fail:** Workspace or cluster missing → re-run Step 2's `infra.bicep` what-if and check your **R2** rights.

## Test 2 — A training run is reproducible and tracked
- **How:** Submit `Train-Eval Pipeline – Churn – NonProd` (Step 4) and open **Studio → Jobs**.
- **Pass:** The run recorded its **parameters, metrics (AUC/F1), and model artifact**, and its **lineage** links to the `churn-training-data` asset version and the pinned `train-env-sklearn:1` environment. Re-submitting with the same inputs reproduces the metrics within tolerance.
- **Fail:** No metrics/artifact logged → confirm the script calls `mlflow.log_*` and the tracking URI is the workspace. No lineage → confirm the run consumed the **registered data asset**, not a raw path.

## Test 3 — Registration is gated on the metric threshold
- **How:** Run the pipeline once with a threshold **above** the model's metric (e.g. `--min-auc 0.99 --register`), then once at the agreed threshold (`--min-auc 0.80 --register`).
- **Pass:** The above-threshold run **does not register** (fails the gate); the at-threshold run registers a new `churn-classifier` version labelled `Candidate`.
- **Fail:** A below-threshold run still registers → the gate is not enforced; check the `--min-auc` comparison in `train_register_pipeline.py`. (The threshold value and accept/reject remain the **data-science owner's** decision — the test only confirms the gate fires.)

## Test 4 — Model registry versioning and lineage
- **How:** `az ml model list --name churn-classifier -o table`; open a version in Studio.
- **Pass:** Each registered model is a distinct **version** with the run, data asset, and metrics attached, and a `stage` label (`Candidate`/`Staging`/`Production`) you can move on a gate.
- **Fail:** Versions overwrite instead of increment → you are re-registering with a fixed version; let Azure ML auto-version. Lineage empty → see Test 2.

## Test 5 — Managed online endpoint scores
- **How:** `az ml online-endpoint invoke --name churn-online-prod --request-file ./sample-request.json`.
- **Pass:** `Online Endpoint – Churn – Prod` returns a scored response from the **blue** deployment; the endpoint is keyless (`aad_token`) and has no public network access.
- **Fail:** `403`/auth error → the caller's identity lacks the endpoint invoke role (**R5**). `5xx` → check the deployment logs (`az ml online-deployment get-logs`) and the scoring script/environment.

## Test 6 — Blue/green rollback works
- **How:** Deploy `Deployment – Churn – Green` at 0% traffic, validate it, shift `green=100`, then shift back `blue=100`.
- **Pass:** Traffic moves without downtime and shifting back to **blue** restores the previous model — rollback is a traffic swap, not a rebuild.
- **Fail:** Swap causes errors → green's model/env is broken; keep traffic on blue and fix green before shifting.

## Test 7 — Drift/performance monitors fire and alert
- **How:** With production-data collection enabled, force a monitor run (or feed skewed sample data) and check **Studio → Monitoring** and the action group.
- **Pass:** `Monitor – Churn – Drift` and `Monitor – Churn – Perf` produce a result, and a threshold breach delivers an alert to `Action Group – MLOps – Alerts`.
- **Fail:** Monitor `NotStarted` → data collection not enabled or no baseline (**R8**). No alert → the action group is not attached or the threshold was not crossed. *Some monitoring features are in preview — verify availability.*

## Test 8 — Pipeline enforces the metric gate and approval
- **How:** Push a trivial change on a branch; open a PR; watch `MLOps Pipeline – Churn – CICD`.
- **Pass:** **Validate → Train+Evaluate → Register** run automatically and publish metrics; the **Deploy** stage **pauses at the `mlops-prod` approval gate** (**R7**) and only proceeds after an approver signs off.
- **Fail:** Deploy runs without pausing → the environment approval check is not attached to the Deploy stage; fix in the pipeline environment configuration.

## Exit criteria
All eight tests pass against the non-production workspace, a model is registered with lineage and clears the agreed metric gate, the endpoint scores and rolls back cleanly, the monitors fire and alert, and the pipeline pauses for approval — **only then** deploy the production workspace and enable scheduled retraining. The decision that the model is **good enough to ship** stays with the data-science owner.
