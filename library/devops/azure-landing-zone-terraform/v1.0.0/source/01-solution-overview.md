# 1. Solution Overview — Azure Landing Zone with Terraform

## What this solution is
An **Azure landing zone** is a pre-provisioned, governed environment — management groups, policy, RBAC,
networking, and logging — that workloads land into, rather than each team building a foundation from
scratch. This solution builds that landing zone **as code with Terraform**, so the whole foundation is
**versioned in Git, reviewed as pull requests, and deployed through a pipeline** with plan-before-apply
and drift detection. It is aligned to the Microsoft **Cloud Adoption Framework (CAF)** enterprise-scale
pattern, kept deliberately lean so a competent admin can own it.

## How the technology works
- **Terraform** describes the desired state of Azure resources in `.tf` files. `terraform plan` shows
  exactly what will change (**what-if**); `terraform apply` makes it so. Because the state is stored
  remotely and the code is in Git, the environment is reproducible and drift is detectable.
- **Providers** — the **AzureRM** provider manages most Azure resources; **AzAPI** covers newer/preview
  resources; the **azuread** provider handles directory objects. Provider versions are **pinned**.
- **Remote state backend** — Terraform state (the record of what it manages) lives in an **Azure Storage
  account** with a container and **blob lease locking**, versioned and access-controlled — never local.
- **Management groups** form a hierarchy under the Tenant Root Group; **Azure Policy** and **RBAC**
  assigned at a management group **inherit** to every subscription and resource beneath it.
- **CI/CD** — Azure DevOps Pipelines (or GitHub Actions) authenticates to Azure with **workload identity
  federation (OIDC)**, runs `plan` on pull requests, and runs `apply` only after a **manual approval**.

## What this solution builds (the components)
1. **Management group hierarchy + subscription vending**
   - A hierarchy under the tenant root: `mg-corp-root` → `mg-platform` (`mg-identity`, `mg-management`,
     `mg-connectivity`), `mg-landingzones` (`mg-corp`, `mg-online`), `mg-sandbox`, `mg-decommissioned`.
   - **Subscription vending** = a repeatable module that places a new subscription into the correct
     management group with its baseline policy, RBAC, and networking already inherited.
2. **Azure Policy guardrails as code**
   - Assignments for **allowed regions**, **required tags**, and a **security baseline**, scoped at
     management groups. Deployed **audit/`Disabled` first**, promoted to **`Deny`** after validation.
3. **Identity & RBAC baseline**
   - Least-privilege **role assignments** in code (platform admins, workload contributors, readers),
     targeting groups — not individuals.
4. **Hub-spoke networking & DNS**
   - A **connectivity hub** VNet (with room for a firewall/gateway) and **spoke** VNets **peered** to it,
     plus **private DNS** zones — the network landing pad for workloads.
5. **Logging baseline**
   - A central **Log Analytics workspace** and diagnostic-settings policy so activity is captured from
     the start.
6. **CI/CD pipeline with drift detection**
   - `plan` on PR → **manual approval** → `apply`; a **scheduled** `plan` reports drift.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand** — inventory the current estate and decide standards
> (Assess); author the Terraform modules and pin versions (Configure); `terraform plan`/apply against a
> **non-production** management-group scope or sandbox first (Pilot); prove the gates — plan is clean,
> policy is in **audit**, state locks, pipeline approval works (Validate); then promote policy to `Deny`
> and vend real subscriptions/workloads in waves behind the approval gate (Expand). Every change is a
> reviewed PR and an approved pipeline run.

## What is out of scope
- **Workload** architecture inside the landing zones (app design, PaaS/IaaS specifics) — this builds the
  **foundation**, not the applications.
- The **decision** of allowed regions, the exact tag taxonomy, the RBAC model, and the **production
  change-approval** process — the guide **encodes** your standard but the standard is yours to set.
- Deep **Azure Firewall / ExpressRoute / VPN** design — the hub is provisioned with room for these; the
  detailed connectivity design is a separate networking engagement.

## Authentication and connections used
- **Terraform** authenticates to Azure via the **Azure CLI** (local pilot) or **workload identity
  federation / OIDC** (pipeline) — no service-principal secrets in code.
- **State backend:** an Azure Storage account (`stiactftfstate*`) in a dedicated resource group, access
  controlled and versioned.
- **CI/CD:** Azure DevOps or GitHub, with a federated service connection scoped to the deployment target.

## Limitations (be honest with buyers)
- **Version sensitivity:** Terraform, AzureRM/AzAPI/azuread providers, and any ALZ modules change
  frequently. All versions here are **pinned and flagged "verify"** — confirm against the registries.
- **`apply` changes real cloud resources.** Everything is **plan/what-if first**, against **non-prod**
  first, and **approval-gated** — never run an unreviewed apply against production.
- **Policy `Deny` can block legitimate deployments.** Guardrails start in **audit**; promote to `Deny`
  only after validating nothing legitimate is blocked.
- **Subscription creation** (EA/MCA billing) and **tenant-root** management-group changes need elevated
  rights and are governance-sensitive — treat them under change control.
