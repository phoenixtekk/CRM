#!/usr/bin/env python3
# =============================================================================
# train_register_pipeline.py — reproducible train -> evaluate -> (gated) register
# for the "MLOps on Azure Machine Learning" solution.
#
# PURPOSE
#   Submits a reproducible Azure ML pipeline job (prep -> train -> evaluate) using
#   the azure-ai-ml SDK v2 and MLflow tracking, then CONDITIONALLY registers the
#   trained model in the workspace registry with lineage. Registration is a
#   metric gate: the model registers only when --register is passed AND the
#   evaluated metric clears --min-auc. Without --register the script runs a
#   safe DRY-RUN (train + evaluate + print the gate decision, no registration).
#
#   The accept/reject decision and the threshold value are the DATA-SCIENCE
#   OWNER's — this script only enforces the number they set.
#
# HOW TO RUN
#   # 1) Dry-run: train + evaluate, print gate decision, DO NOT register
#   python train_register_pipeline.py --workspace mlw-platform-nonprod \
#       --resource-group <rg> --data-asset churn-training-data --min-auc 0.80
#
#   # 2) Gated register: register a new version ONLY if metric >= threshold
#   python train_register_pipeline.py --workspace mlw-platform-nonprod \
#       --resource-group <rg> --data-asset churn-training-data --min-auc 0.80 --register
#
#   Auth uses DefaultAzureCredential (your 'az login' locally; managed identity /
#   OIDC federation in CI/CD — no keys). Requires: azure-ai-ml, mlflow,
#   azureml-mlflow, scikit-learn (pin these in requirements.txt, R1).
#
# EXPECTED RESULTS
#   A pipeline job named 'Train-Eval Pipeline – Churn – NonProd' visible under
#   Studio -> Jobs, with parameters/metrics/model logged to MLflow and lineage
#   back to the data asset + environment. With --register and a passing metric,
#   a new 'churn-classifier' version labelled stage=Candidate.
#
# NOTES
#   White-label. Registration defaults OFF (dry-run) and is metric-gated when on.
#   *Verify current azure-ai-ml / mlflow versions and the model-promotion
#    mechanism (MLflow classic stages are deprecated; Azure ML uses versions +
#    labels/tags).*
# =============================================================================
from __future__ import annotations

import argparse
import sys

MODEL_NAME = "churn-classifier"
PIPELINE_DISPLAY_NAME = "Train-Eval Pipeline – Churn – NonProd"
TRAIN_ENV = "train-env-sklearn:1"          # pinned environment (reproducibility)
COMPUTE = "cpu-train-nonprod"              # 'Training Cluster – Platform – NonProd'
CANDIDATE_LABEL = "Candidate"


def parse_args(argv=None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Reproducible train->evaluate->(gated)register for Azure ML.")
    p.add_argument("--workspace", required=True, help="Azure ML workspace name (e.g. mlw-platform-nonprod).")
    p.add_argument("--resource-group", required=True, help="Resource group of the workspace.")
    p.add_argument("--subscription-id", default=None, help="Subscription ID (default: from az context).")
    p.add_argument("--data-asset", default="churn-training-data",
                   help="Registered data asset name (R4). A specific version is pinned for reproducibility.")
    p.add_argument("--data-version", default=None, help="Data asset version to pin (default: latest at submit time).")
    p.add_argument("--metric", default="auc", help="Evaluation metric name to gate on (data-science owner's choice).")
    p.add_argument("--min-auc", type=float, default=0.80,
                   help="Acceptance threshold (R6). The model registers only if the metric >= this. "
                        "The VALUE and the accept/reject decision are the data-science owner's.")
    p.add_argument("--register", action="store_true",
                   help="Enable metric-gated registration. WITHOUT this flag the script is a safe dry-run.")
    p.add_argument("--experiment", default="churn-mlops", help="MLflow experiment name.")
    return p.parse_args(argv)


def get_ml_client(args):
    """Build an MLClient with keyless DefaultAzureCredential (az login / MI / OIDC)."""
    try:
        from azure.ai.ml import MLClient
        from azure.identity import DefaultAzureCredential
    except ImportError as e:  # pragma: no cover
        sys.exit(f"ERROR: install the SDK first — pip install azure-ai-ml mlflow azureml-mlflow ({e})")

    cred = DefaultAzureCredential()
    if args.subscription_id:
        return MLClient(cred, args.subscription_id, args.resource_group, args.workspace)
    # Resolve subscription from the current CLI context when not supplied.
    return MLClient.from_config(cred) if False else MLClient(
        cred, _current_subscription(), args.resource_group, args.workspace
    )


def _current_subscription() -> str:
    import json
    import subprocess
    try:
        out = subprocess.check_output(["az", "account", "show", "-o", "json"], text=True)
        return json.loads(out)["id"]
    except Exception as e:  # pragma: no cover
        sys.exit(f"ERROR: could not resolve subscription — pass --subscription-id ({e})")


def build_pipeline_job(ml_client, args):
    """
    Define the prep -> train -> evaluate pipeline as code. The command steps below
    reference scripts you keep in ./src (prep.py, train.py, evaluate.py). Each step
    runs in the PINNED environment on the training cluster, and the training script
    logs params/metrics/model to MLflow so every run is reproducible and traceable.
    """
    from azure.ai.ml import Input, command
    from azure.ai.ml.dsl import pipeline

    data_input = Input(
        type="uri_folder",
        path=f"azureml:{args.data_asset}:{args.data_version}" if args.data_version
        else f"azureml:{args.data_asset}@latest",
    )

    train_step = command(
        name="train",
        display_name="Train – Churn – NonProd",
        command="python src/train.py --data ${{inputs.data}} --model_out ${{outputs.model}}",
        environment=f"azureml:{TRAIN_ENV}",
        compute=COMPUTE,
        inputs={"data": data_input},
        outputs={"model": None},
    )

    evaluate_step = command(
        name="evaluate",
        display_name="Evaluate – Churn – NonProd",
        command=("python src/evaluate.py --data ${{inputs.data}} --model ${{inputs.model}} "
                 "--metric_out ${{outputs.metrics}}"),
        environment=f"azureml:{TRAIN_ENV}",
        compute=COMPUTE,
        inputs={"data": data_input, "model": None},
        outputs={"metrics": None},
    )

    @pipeline(name="train_eval_churn", display_name=PIPELINE_DISPLAY_NAME, experiment_name=args.experiment)
    def _pl():
        t = train_step()
        e = evaluate_step(model=t.outputs.model)
        return {"model": t.outputs.model, "metrics": e.outputs.metrics}

    return _pl()


def evaluated_metric(ml_client, job_name: str, metric: str) -> float:
    """
    Read the gating metric from the completed run via MLflow. In a real pipeline the
    evaluate step logs e.g. mlflow.log_metric('auc', value); here we fetch it back.
    """
    try:
        import mlflow
        tracking_uri = ml_client.workspaces.get(ml_client.workspace_name).mlflow_tracking_uri
        mlflow.set_tracking_uri(tracking_uri)
        run = mlflow.get_run(job_name)
        return float(run.data.metrics.get(metric))
    except Exception as e:
        print(f"WARNING: could not read metric '{metric}' from MLflow ({e}). "
              f"Treating as gate-fail so nothing registers on uncertainty.")
        return float("nan")


def main(argv=None) -> int:
    args = parse_args(argv)
    ml_client = get_ml_client(args)

    print(f"Submitting pipeline '{PIPELINE_DISPLAY_NAME}' to workspace '{args.workspace}' ...")
    job = ml_client.jobs.create_or_update(build_pipeline_job(ml_client, args))
    print(f"  Job: {job.name}  (Studio -> Jobs).  Streaming to completion ...")
    ml_client.jobs.stream(job.name)
    completed = ml_client.jobs.get(job.name)
    if completed.status != "Completed":
        print(f"GATE-FAIL: job status is '{completed.status}'. Nothing registered.")
        return 1

    metric_value = evaluated_metric(ml_client, job.name, args.metric)
    passed = metric_value == metric_value and metric_value >= args.min_auc  # NaN-safe
    print(f"\nEvaluated {args.metric} = {metric_value}  |  threshold ({args.metric} >= {args.min_auc}): "
          f"{'PASS' if passed else 'FAIL'}")
    print("  (Threshold and accept/reject are the data-science owner's decision — this only enforces it.)")

    if not args.register:
        print("\nDRY-RUN: --register not supplied. No model was registered.")
        print("Re-run with --register once the data-science owner accepts the metric.")
        return 0

    if not passed:
        print("\nGATE-FAIL: metric below threshold — registration SKIPPED by design.")
        return 2

    from azure.ai.ml.entities import Model
    from azure.ai.ml.constants import AssetTypes
    model = Model(
        name=MODEL_NAME,
        path=f"azureml://jobs/{job.name}/outputs/model",
        type=AssetTypes.MLFLOW_MODEL,
        description="Churn classifier — registered via metric-gated MLOps pipeline.",
        tags={"stage": CANDIDATE_LABEL, "gating_metric": args.metric, "gating_value": str(metric_value),
              "source_job": job.name, "data_asset": args.data_asset},
    )
    registered = ml_client.models.create_or_update(model)
    print(f"\nREGISTERED: {registered.name}:{registered.version}  label stage={CANDIDATE_LABEL}")
    print("Promote Candidate -> Staging -> Production on a controlled gate (see Implementation Step 5).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
