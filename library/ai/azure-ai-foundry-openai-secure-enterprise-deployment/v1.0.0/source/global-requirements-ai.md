# Global Requirements — AI (category-level)

These requirements apply to every solution in the AI category (building and operating custom AI on Azure —
Azure OpenAI / AI Foundry, RAG, Azure ML / MLOps, AI landing zones, content safety). Published once at the
category level so listings stay small. Confirm before deploying any AI solution. Each entry: Description /
Why / Verify / Implement-if-missing.

> Custom AI touches sensitive data and can emit harmful or ungrounded output. Deploy private-by-default
> (no public endpoints, keyless auth), ground and permission-trim on your own data, put safety guardrails
> in front of generation, and pilot in non-production before production — content-acceptability and
> AI-use-policy decisions belong to the customer's legal / trust-and-safety / compliance functions, not
> this guide.

## G1. Azure subscription with AI service access and rights
Description: An Azure subscription with access to the required AI services (Azure OpenAI / AI Foundry, Azure AI Search, Azure Machine Learning, Azure AI Content Safety) and Contributor/Owner at the deployment scope.
Why: These solutions create and configure real, billable Azure AI resources.
Verify: `az account show` succeeds; the AI resource providers are registered and the region is available. *Azure OpenAI/model access and regions vary — verify current availability in your subscription.*
Implement: Obtain the subscription/role; request access to the gated AI services where required; pick a supported region.

## G2. Entra identity, managed identity, and RBAC
Description: Entra ID identities plus managed identities for keyless service-to-service auth.
Why: Keys leak; AI services should authenticate via managed identity + RBAC (least privilege).
Verify: Managed identities can be assigned and the needed data-plane roles exist (e.g. Cognitive Services OpenAI User, Search Index Data Reader).
Implement: Enable managed identity on the compute/app; assign least-privilege data-plane roles; store any unavoidable secret in Key Vault.

## G3. Private networking capability
Description: A VNet with the ability to create private endpoints and private DNS for the AI services.
Why: Public endpoints are a data-exfiltration surface; enterprise AI is private-by-default.
Verify: The VNet/subnets and Private DNS zones exist or can be created; public access can be disabled.
Implement: Provision the VNet, subnets, and Private DNS; plan private endpoints per service (see the AI landing-zone solution).

## G4. IaC + Python tooling and source control
Description: Terraform/Bicep, the Azure CLI, Python 3.x with the relevant Azure AI SDKs, and Git.
Why: AI platforms are delivered as versioned code (infra + pipelines + app), so they are reproducible and reviewable.
Verify: `az version`, `terraform version`/`az bicep version`, `python --version`, and `git --version` return supported builds. *Verify current SDK/provider versions — the AI SDKs move fast.*
Implement: Install and pin the toolchain; store all config in Git.

## G5. CI/CD platform
Description: A pipeline (GitHub Actions / Azure DevOps) with OIDC/workload-identity federation to Azure.
Why: Infra, model, and app deployments must run through an auditable, approval-gated pipeline — not a laptop.
Verify: The pipeline can authenticate to Azure via OIDC and run a plan/deploy step.
Implement: Configure the service connection with workload-identity federation; scope its rights.

## G6. Data source and classification (for data-grounded solutions)
Description: The private data to ground on (documents, databases) with a known permission/ACL model, and a sensitivity-classification position.
Why: RAG must respect source permissions (permission-trimming) and must not expose sensitive data through AI.
Verify: The data source, its access model, and applicable sensitivity labels are known. Run the solution's discovery script.
Implement: Inventory the data and its ACLs; align sensitivity labeling (see the Purview solutions). *Data-classification determinations are the compliance team's decision.*

## G7. Content-safety and responsible-AI posture
Description: An organizational position on acceptable AI content, safety thresholds, and responsible-AI review.
Why: Generative AI can emit harmful/ungrounded output and be jailbroken; the organization must define guardrails and review.
Verify: A responsible-AI / acceptable-use policy exists; content-safety is enabled where generation occurs.
Implement: Adopt an RAI/acceptable-use policy and enable content safety (see the content-safety solution). *Acceptable-content and RAI determinations are the customer's legal / trust-and-safety decision.*

## G8. Cost controls and quotas
Description: Budgets, alerts, and per-service quotas (e.g. Azure OpenAI TPM) appropriate to the workload.
Why: AI services bill on tokens/compute; unmanaged usage causes bill shock.
Verify: Budgets/alerts exist and quotas are set for the deployed services.
Implement: Set budgets, cost alerts, and quotas/rate limits before broad rollout. *Spend limits are the customer's business decision.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.
