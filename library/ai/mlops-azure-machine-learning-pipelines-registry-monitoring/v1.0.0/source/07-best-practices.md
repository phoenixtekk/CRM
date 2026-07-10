# 7. Best Practices — MLOps on Azure Machine Learning

## Keep it clean
- **Reproducible or it didn't happen.** Every training run pins a **versioned data asset** and a **pinned environment**, and logs to MLflow. If a run reads a raw file path or a floating environment, you cannot reproduce or defend the model it produced.
- **The registry is the source of truth, not a folder.** Register every model; never hand-copy a `.pkl` to a server. Deploy **from a registered version**, and keep old versions — they are your rollback.
- **Gate on the metric, decide with a human.** The pipeline enforces the numeric threshold (**R6**), but **whether the model is acceptable is the data-science owner's call.** Keep the accept/reject decision human; keep the enforcement automated.
- **Approval before production, always.** No model reaches a production endpoint without the `mlops-prod` approval after the metrics are reviewed. Automated retraining is safe *because* it still stops at the gate.
- **Pilot in a non-production workspace.** Prove the whole loop — train, register, deploy, monitor — in non-prod before production. It is far cheaper to find a broken scoring script there.
- **Blue/green every deploy.** Deploy new models at **0% traffic**, smoke-test, then shift. Rollback is a traffic swap back to the previous deployment, not a rebuild.
- **Pin the toolchain.** Pin `azure-ai-ml`, `mlflow`, `azureml-mlflow`, and the CLI `ml` extension in `requirements.txt`. ML SDKs move fast; a silent upgrade breaks pipelines. *Verify current supported versions periodically.*
- **Keyless by default.** Managed identity + least-privilege data-plane roles for compute and endpoints (**R5**); no keys, no public network access. Secrets that are unavoidable live in the workspace Key Vault.
- **Scale to zero.** Set the training cluster's idle-scale-down so it costs nothing when not training (Global Requirements G8). Watch endpoint instance counts — real-time compute bills while it runs.
- **Monitor from day one.** Turn on data-drift and performance monitoring with alerts as part of go-live, not later. A model with no monitoring is a model you will trust long after it has quietly gone stale.
- **Everything through the pipeline.** After bootstrap, don't train/register/deploy to production from a laptop. The pipeline's Validate → Train → Register → approval → Deploy path is the only production route, so every change is reviewed and recorded.

## Decisions that belong to the customer
- **Model acceptance** — whether a model's metrics are good enough to register, promote, and ship — is the **data-science owner's** decision. The solution provides the reproducibility, the gate, and the evidence.
- **Production change approval**, who may approve a deploy, and the retrain cadence are the customer's **change-control** decisions.
- **Data classification, responsible-AI, and acceptable-use** determinations belong to the customer's compliance / legal / trust-and-safety functions (Global Requirements G6/G7) — the platform enforces controls once those choices are made.
- **Alert triage ownership** — who receives and acts on drift/performance alerts — is the customer's operations decision.

## Where to go next
Once the MLOps loop is live, adjacent catalog areas extend it:
- **AI** — the *AI Landing Zone (Governance, Private Networking & Cost)* solution wraps this workspace in a governed, private-by-default landing zone; *Azure OpenAI / RAG* solutions if you add generative models alongside the classical ones.
- **DevOps** — the *Azure Landing Zone (Bicep / Terraform)* solutions to put the workspace's subscription under management-group policy and CI/CD discipline.
- **Security / Identity** — Conditional Access and PIM solutions to harden who can approve deploys and access the workspace.
- **Data** — the *Microsoft Fabric / Data platform* solutions to feed governed, versioned data into the training pipeline upstream.
