# 7. Best Practices — Azure AI Foundry & Azure OpenAI: Secure Enterprise Deployment

## Keep it clean
- **Private-by-default, always.** Create the resource with `publicNetworkAccess: Disabled` and a private endpoint from the first deploy — don't stand it up public "just to test" and plan to close it later. The window between the two is a real exposure, and the private path is easy to prove before you disable public access.
- **Keyless, no exceptions.** Set `disableLocalAuth: true` and authenticate every app and script with a **managed identity** and the least-privilege data-plane role. There is no such thing as a "temporary" key — a key is a portable secret that outlives the developer who created it. Regenerating keys is not a control; disabling them is.
- **Least privilege on the data plane.** App identities that only call models get **Cognitive Services OpenAI User**; only the identity/pipeline that *manages* deployments gets **Contributor**. Never grant Owner to a workload. One managed identity per app, scoped to the one resource it needs.
- **Custom subdomain at create time.** It's required for keyless + private endpoints and generally can't be added later — set `customSubDomainName` in the template so you never have to recreate a resource to fix it.
- **Quota is your bill-shock control.** Give every deployment an **explicit, deliberate TPM** and raise it consciously. An unbounded or over-large deployment is how a runaway loop or a launch spike becomes a five-figure invoice. Pilot small.
- **A content filter on every deployment.** Attach a RAI/content-filter policy to each deployment and set the thresholds deliberately — never ship a deployment with generation exposed and no guardrail. *Verify preview status of prompt-shield/protected-material features before relying on them.*
- **Everything through the pipeline.** After the bootstrap, never `az deployment`/`az stack` from a laptop against production. The what-if → approval → deploy path is the only production route, so every change — a new model, a TPM bump, a stricter filter — is reviewed and recorded.
- **What-if is a gate, not a formality.** Read every preview. An unexpected **delete** or **modify** on a resource you didn't intend to touch means **stop** and investigate before you approve.
- **Parameterize, never hard-code.** Subdomains, VNet/subnet and DNS-zone IDs, model/version, TPM, filter thresholds, workspace, and budget live in `.bicepparam` files — one per environment. The same `AIFOUNDRY-main.bicep` deploys non-prod and prod; only parameters differ.
- **Use deployment stacks for rollback.** Deploy as stacks with `denyDelete` so out-of-band portal edits are blocked, and keep `--action-on-unmanage` explicit so a rollback does exactly what you expect.
- **Observe every call.** Keep the diagnostic setting to Log Analytics on, and keep a budget with alerts. An AI platform you can't see is one you can't govern or cost-control.
- **Pin the toolchain.** Pin Bicep, the Azure CLI, and the Python SDK versions in the repo. The AI SDKs move fast; IaC that "worked last month" breaks on a silent update. *Verify current supported versions periodically.*

## Decisions that belong to the customer
- **Acceptable AI content and use** — the content-filter thresholds and what your organization permits are your **legal / trust-and-safety** decision; the platform enforces them, it does not define them (Global Requirement G7).
- **Data classification and grounding data** — what data may be sent to or grounded in the model is your **compliance** decision (Global Requirement G6). This platform is the model layer; grounding on private data is the sibling RAG solution.
- **Spend limits** — the budget amount, TPM ceilings, and alert thresholds are your **business** decision (Global Requirement G8).
- **Production change approval** — who approves production deploys and the soak period are your **change-control** decision; the pipeline provides the gate.
- **Government vs. commercial cloud** — sovereign-cloud requirements (which region/cloud, which DNS zone names, which features are available) are your **compliance** decision; *verify availability in your environment*.

## Where to go next
Once the secure platform is live, adjacent catalog areas extend it:
- **AI** — the **Enterprise RAG Platform (Azure AI Search + private data)** solution to ground the model on your own permission-trimmed data; the **Azure AI Content Safety & Responsible-AI Guardrails** solution to deepen the content-filter and add prompt-shield/jailbreak protections; the **MLOps (Azure Machine Learning)** solution for the model-training/registry side; and the **AI Landing Zone** solution for the org-wide governance and hub-spoke backbone this platform deploys *into*.
- **Copilot / Purview AI** — if instead you need to **govern Microsoft 365 Copilot** over your M365 data (a different job than building custom AI), those catalog areas cover Copilot readiness, data-oversharing control, and AI-interaction auditing. Complementary, not overlapping.
- **Security / Identity** — Conditional Access and PIM to harden the identities that manage this platform; **Key Vault** patterns for any unavoidable downstream secret.
- **DevOps** — the **Azure Landing Zone (Bicep/Terraform)** and **Intune-as-Code** solutions to bring the rest of the estate under the same code-and-pipeline discipline.
