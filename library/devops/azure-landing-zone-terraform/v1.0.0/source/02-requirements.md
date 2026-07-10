# 2. Requirements Guide — Azure Landing Zone with Terraform

Verify **every** requirement before you plan or apply. Each entry: **Description · Why required · How to
verify · How to implement if missing.** The category-wide prerequisites (a target subscription/tenant
with rights, the IaC toolchain, a Git repo, a CI/CD platform + service connection, a remote state
backend, secrets management, naming/tagging standards, and a non-production target + change control) are
defined once in `global-requirements-devops.md` — confirm those first. The items below are **specific to
building an Azure landing zone with Terraform**.

## 2.1 Elevated rights at the tenant-root / management-group scope
**Description:** The deploying identity can **create and manage management groups** and assign **policy
and RBAC at the management-group scope** — typically **Owner** (or **User Access Administrator** +
**Management Group Contributor**) elevated at the **root**.
**Why required:** Landing-zone deployment creates the management-group hierarchy and assigns
inherited policy/RBAC above the subscription level; subscription-only rights are not enough.
**How to verify:** `az account management-group list` succeeds; the identity can create a test child
management group. Run **`IACTF-Discovery.ps1`** (reports current hierarchy + your effective role).
**How to implement if missing:** In Entra, enable **"Access management for Azure resources"** for the
account (elevates a Global Admin to User Access Administrator at root), then assign the needed roles at
the target management group. Remove the elevation when finished.

## 2.2 Terraform + provider versions pinned (and available)
**Description:** A **pinned** Terraform CLI version and pinned **AzureRM / AzAPI / azuread** provider
versions (and any Azure landing-zone module versions) recorded in the repo.
**Why required:** IaC is version-sensitive — an unpinned provider upgrade can change plan behavior or
break a module mid-rollout.
**How to verify:** `terraform version` and the `required_providers` block match the pinned versions;
`terraform init` resolves them. *Verify current supported provider/module versions against the registry.*
**How to implement if missing:** Pin `required_version` and each provider `version` in `main.tf`
(examples are provided, flagged "verify"), commit the `.terraform.lock.hcl`, and record the versions.

## 2.3 Remote state backend provisioned (storage account + container + locking)
**Description:** An Azure **Storage account** (e.g. `stiactftfstate<unique>`) with a **container**
(`tfstate`), **blob versioning**, and **least-privilege access** — the Terraform backend.
**Why required:** Local state is unsafe and unshareable; remote state with blob-lease **locking** prevents
two applies corrupting state.
**How to verify:** The storage account/container exist and the deploy identity has **Storage Blob Data
Contributor** on them. Run **`IACTF-Validate.ps1`** (checks backend reachability before plan).
**How to implement if missing:** Create the resource group `rg-iactf-tfstate`, the storage account (with
versioning + TLS1.2 + public-blob disabled), and the `tfstate` container; grant the deploy identity data
access. (This one bootstrap step is done once, before the first `terraform init`.)

## 2.4 CI/CD service connection using workload identity federation (OIDC)
**Description:** A pipeline **service connection** to Azure that uses **workload identity federation
(OIDC)** rather than a stored secret, scoped to the deployment target.
**Why required:** Plan/apply must run through an **auditable pipeline** with a **secretless**,
least-privilege identity — not from a laptop with a personal login.
**How to verify:** A test pipeline authenticates to Azure via OIDC (no secret in variables). Run the
pipeline's `plan` stage.
**How to implement if missing:** In Azure DevOps/GitHub, create a **federated** service connection to the
app registration / managed identity, assign it the needed role at the target management group, and
reference it in `azure-pipelines.yml`.

## 2.5 Naming, tagging, and allowed-region standard defined
**Description:** The organization's **naming convention**, **required tags** (e.g. `owner`,
`costCenter`, `environment`), and **allowed Azure regions**.
**Why required:** These are encoded directly into the Terraform variables and the policy assignments
(required-tags, allowed-regions); without a decided standard the guardrails are arbitrary.
**How to verify:** A documented standard exists and maps to the `variables.tf` inputs and policy
parameters.
**How to implement if missing:** Decide and document the standard (this is a governance decision), then
set it in the Terraform variables and policy parameters. *The standard itself is the customer's decision.*

## 2.6 A non-production target scope to validate against
**Description:** A **non-production** management-group scope (or a **sandbox** subscription) where
`plan`/`apply` is proven before touching production.
**Why required:** Every change is validated with plan/what-if against non-prod and approved before prod —
this is the pilot target.
**How to verify:** A `mg-sandbox` (or non-prod subscription) exists and the deploy identity can apply
there.
**How to implement if missing:** Create the sandbox management group / obtain a non-prod subscription and
point the pilot Terraform workspace at it.

## 2.7 Microsoft Graph / Az PowerShell for the helper scripts
**Description:** The **Az PowerShell** module (and Azure CLI) on the operator's workstation for the
discovery/validation/report helpers.
**Why required:** The read-only helper scripts (`IACTF-Discovery.ps1`, `IACTF-Validate.ps1`,
`IACTF-Report.ps1`) use `Az`/`az` to inventory the estate and check policy compliance around the
Terraform run.
**How to verify:** `Get-Module -ListAvailable Az.Accounts` returns a version and `Connect-AzAccount`
succeeds; `az version` works.
**How to implement if missing:** `Install-Module Az -Scope CurrentUser`; install the Azure CLI; sign in
with `Connect-AzAccount` / `az login`.

---
## Checklist
- [ ] Category global requirements confirmed (`global-requirements-devops.md`)
- [ ] Elevated rights at the management-group / root scope — `IACTF-Discovery.ps1`
- [ ] Terraform + provider/module versions **pinned** — *verify current versions*
- [ ] Remote state backend (storage account + `tfstate` container + locking) — `IACTF-Validate.ps1`
- [ ] CI/CD service connection via **workload identity federation (OIDC)**
- [ ] Naming / tagging / allowed-region standard defined and mapped to variables
- [ ] Non-production target scope (`mg-sandbox` / sandbox subscription) available
- [ ] Az PowerShell + Azure CLI installed and signed in
