# Requirements — AI Landing Zone & Governance (Private Networking, Content Safety, Cost)

These are the **solution-specific** prerequisites for building the governed AI landing zone. The
**category baseline** — an Azure subscription with AI-service access and Contributor/Owner rights,
Entra identity + managed identity + RBAC, private-networking capability, the IaC + Python toolchain
and Git, a CI/CD platform with OIDC federation, a data source + classification position, a content-
safety / responsible-AI posture, and cost controls/quotas — is covered once in
**`global-requirements-ai.md`** (**G1–G8**). Read that first; the items below layer on top of it and
are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. Elevated deploy scope and role (Owner + User Access Administrator)

- **Description:** The deployment identity has **Owner** (or **Contributor + User Access
  Administrator**) at the target **subscription** (pilot) and, for the Expand stage, the target
  **management group**, plus **Resource Policy Contributor** for policy assignments.
- **Why required:** The landing zone creates **RBAC role assignments** and **policy assignments with
  remediation identities**, both of which require rights beyond plain Contributor.
- **How to verify:** `Get-AzRoleAssignment -SignInName <you>` shows Owner/UAA at the scope; or run
  `AILZ-Discovery.ps1`, which reports your effective role at the target scope. *Verify the exact roles
  required for policy remediation in your tenant.*
- **How to implement if missing:** Have an existing Owner grant the role at the subscription (pilot)
  and management group (expand). Never use a personal admin account for the pipeline — use a
  workload-identity-federated service principal (G5).

## R2. A hub/spoke network design decision (and address plan)

- **Description:** A short, written decision on the **hub/spoke topology** and a **non-overlapping IP
  address plan** — the hub VNet CIDR, the AI spoke CIDR, and the subnet ranges for private endpoints
  and the AI workload.
- **Why required:** Private endpoints consume IPs from a subnet; peering requires non-overlapping
  address space; DNS is centralized in the hub. Getting the address plan wrong is expensive to unwind
  after workloads land.
- **How to verify:** The CIDRs are documented, non-overlapping with existing/peered networks, and
  large enough for growth. `AILZ-Discovery.ps1` lists existing VNets and their address spaces to check
  for overlap.
- **How to implement if missing:** Agree the topology and address plan with networking; set the CIDRs
  in `main.tf` variables. If you already run a platform hub (e.g. an enterprise-scale landing zone),
  peer the AI spoke to it rather than creating a new hub. *Verify alignment with your existing
  connectivity model.*

## R3. Private DNS strategy for the AI services

- **Description:** A decision on **where the private DNS zones live** (in this hub, or an existing
  central private-DNS subscription) for each AI service you will make private — Azure OpenAI
  (`privatelink.openai.azure.com`), Cognitive/Content-Safety
  (`privatelink.cognitiveservices.azure.com`), AI Search (`privatelink.search.windows.net`), Key Vault
  (`privatelink.vaultcore.azure.net`), and blob storage (`privatelink.blob.core.windows.net`).
- **Why required:** Private endpoints only work if the service hostname resolves to the private IP;
  that requires the correct private DNS zone **linked to the VNet**. Duplicating zones that already
  exist centrally causes resolution conflicts.
- **How to verify:** Confirm whether central private DNS zones already exist. `AILZ-Discovery.ps1`
  lists private DNS zones in scope.
- **How to implement if missing:** Create the zones in the hub (this package does), **or** link the AI
  spoke/hub to your existing central zones and disable zone creation in `main.tf`. *Verify the current
  privatelink zone names for each service — they occasionally change.*

## R4. Allowed models, regions, and tagging standard (the guardrail inputs)

- **Description:** The written inputs the policy initiative enforces: the **allowed Azure regions**,
  the **allowed AI models / model versions**, and the **required tags** (e.g. owner, cost-center,
  environment, data-classification).
- **Why required:** The `Policy-AllowedRegions-AILZ`, `Policy-AllowedModels-AILZ`, and
  `Policy-RequireTags-AILZ` assignments **enforce the lists you set** — they do not choose them. The
  region list must match data-residency needs; the model list gates which models teams may deploy.
- **How to verify:** The lists are documented and owned by cloud governance. `AILZ-Report.ps1` shows
  which values the assignments are currently enforcing.
- **How to implement if missing:** Facilitate a short session to agree the lists and set them in the
  `main.tf` variables. *Which regions/models are allowed and which tags are mandatory are governance
  and data-residency decisions — the solution enforces what you set, it does not decide for you. Model
  and region availability differ by cloud — verify current availability.*

## R5. Resource-provider registration for the AI + networking services

- **Description:** The Azure **resource providers** for the services in the zone are **registered** on
  the subscription — e.g. `Microsoft.CognitiveServices`, `Microsoft.Network`, `Microsoft.KeyVault`,
  `Microsoft.OperationalInsights`, `Microsoft.PolicyInsights`, `Microsoft.CostManagement`, and (where
  used) `Microsoft.MachineLearningServices` / `Microsoft.Search`.
- **Why required:** `terraform apply` / `what-if` fails if a required provider isn't registered on the
  subscription.
- **How to verify:** `Get-AzResourceProvider -ListAvailable | Where-Object RegistrationState -eq
  'Registered'`; or run `AILZ-Discovery.ps1`, which flags any unregistered provider the zone needs.
- **How to implement if missing:** `Register-AzResourceProvider -ProviderNamespace <ns>` for each
  missing provider (registration can take a few minutes). *Azure OpenAI / some AI services are
  access-gated — verify your subscription has been granted access and the region is available.*

## R6. Terraform remote state ready and encrypted (foundation-critical)

- **Description:** The **remote state backend** — an **Azure Storage account + container**, encrypted,
  versioned (blob versioning), with access via RBAC/OIDC — from category **G4–G5**, provisioned
  **before** the landing-zone apply.
- **Why required:** The landing zone is foundational; losing or corrupting its state is a serious
  incident. Remote, locked, versioned, encrypted state is mandatory here, not optional.
- **How to verify:** The state storage account/container exist, are encrypted and versioned, and the
  `backend "azurerm"` block in `main.tf` points at them. `terraform init` succeeds.
- **How to implement if missing:** Provision the Storage account + container first (a small
  bootstrap), enable versioning, configure the backend, and `terraform init`. Never run the landing
  zone on local state.

## R7. The IaC toolchain, pinned, with OIDC to Azure

- **Description:** **Terraform CLI** (pinned), the **azurerm/azapi providers** (pinned), **Az
  PowerShell** modules, and **Git**, on the workstation/CI, authenticating to Azure via
  **workload-identity federation (OIDC)** — never a stored client secret (category G2, G5).
- **Why required:** Version drift breaks reproducibility of a foundation everything else depends on;
  OIDC removes long-lived secrets from the pipeline.
- **How to verify:** `terraform version`, `az version` / `Get-Module Az -ListAvailable`, and `git
  --version` return the pinned/supported builds; the pipeline's Azure service connection uses
  **workload identity federation** (no secret). *Verify current provider/module versions — the Azure
  providers and Az modules move fast.*
- **How to implement if missing:** Install and **pin** the toolchain (`required_version`,
  `required_providers`), and configure the pipeline's Azure service connection for OIDC. For **GCC /
  GCC-High**, set the correct Azure environment/endpoints — *verify cloud-specific configuration and
  service availability*.

## R8. A pilot (non-production) scope and change control

- **Description:** A **non-production** target for the pilot — a dedicated pilot subscription, resource
  group, or management group — and a **change-approval** process for promoting to production.
- **Why required:** The whole method is **non-prod-first with policies in audit mode**; you need a
  safe scope to apply into and observe before enforcing guardrails and expanding.
- **How to verify:** A non-prod scope exists and the pipeline's approval gate (environment check) is
  configured. `AILZ-Discovery.ps1` confirms the target scope.
- **How to implement if missing:** Designate a pilot scope and configure the Azure Pipelines
  **Environment approval** so `apply` cannot run without a human approver. Production apply is the
  customer's change-approval decision.
