# Global Requirements — DevOps (category-level)

These requirements apply to every solution in the DevOps category (Infrastructure-as-Code, pipelines,
policy-as-code). They are published once at the category level so individual listings stay small.
Confirm these before deploying any IaC/automation solution. Each entry: Description / Why / Verify /
Implement-if-missing.

> Infrastructure-as-code changes real cloud resources. Everything runs plan/what-if first, through a
> reviewed pipeline, against a non-production target before production — never an unreviewed apply
> against prod. State and pipeline credentials are treated as secrets.

## G1. Target cloud subscription/tenant with sufficient rights
Description: An Azure subscription (and Entra tenant) where resources will be created, with Owner or an equivalent scoped role at the deployment scope.
Why: Landing-zone and policy deployments create management groups, role assignments, and resources that need elevated rights.
Verify: `az account show` succeeds; the identity holds Owner/User Access Administrator at the target scope.
Implement: Obtain a subscription and the required role assignment (or a service principal / workload identity with those rights).

## G2. IaC tooling installed and versioned
Description: The required toolchain — Terraform CLI, Bicep CLI / Azure CLI, and Git — at pinned versions.
Why: IaC is version-sensitive; provider/module/CLI drift breaks reproducibility.
Verify: `terraform version`, `az bicep version`, `az version`, and `git --version` return supported builds. *Verify current provider/module versions.*
Implement: Install and pin the toolchain versions; record them in the repo.

## G3. Source control repository
Description: A Git repository (Azure Repos or GitHub) to hold the IaC and pipeline definitions.
Why: Code review, history, and CI/CD all depend on version control; IaC not in Git defeats the purpose.
Verify: The repo exists and the operator can clone/push.
Implement: Create the repository and set branch protection before authoring infrastructure code.

## G4. CI/CD platform and service connection
Description: A pipeline platform (Azure DevOps Pipelines or GitHub Actions) with a secure connection to the cloud (workload identity federation preferred over secrets).
Why: Plan/apply must run through an auditable pipeline with least-privilege, not from a laptop.
Verify: A pipeline can authenticate to the subscription via OIDC/workload identity or a scoped service principal.
Implement: Configure the service connection using workload identity federation; scope its rights to the deployment target.

## G5. Remote state / deployment backend
Description: A secure remote backend for state (e.g. Azure Storage for Terraform state) or Azure deployment stacks for Bicep.
Why: Local state is unsafe and unshareable; remote state with locking prevents corruption and drift.
Verify: The state storage account/container (or deployment-stack scope) exists and is access-controlled.
Implement: Provision the state backend with encryption, versioning, and least-privilege access before first apply.

## G6. Secrets management
Description: A secrets store (Azure Key Vault) for any credentials the pipeline needs; no secrets in code.
Why: Committed secrets leak; IaC repos are frequently shared and reviewed.
Verify: No secrets in the repo (scanning enabled); pipeline pulls secrets from Key Vault / secure variables.
Implement: Move all secrets to Key Vault / pipeline secret store; enable secret scanning on the repo.

## G7. Naming, tagging, and region standards
Description: An organizational naming convention, required tags, and allowed regions.
Why: Consistent naming/tagging is needed for governance, cost management, and policy enforcement.
Verify: A documented standard exists and is encoded in the IaC modules/policy.
Implement: Define the standard and encode it as policy-as-code and module defaults.

## G8. Change-control and non-production target
Description: A non-production subscription/scope to validate against, and a change-approval process for production.
Why: Every change is validated with plan/what-if against non-prod and approved before prod apply.
Verify: A non-prod target exists; the pipeline requires approval before prod stages.
Implement: Provision a non-prod scope and add manual approval gates to the production pipeline stages. *Production change approval is the customer's operational decision.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.
