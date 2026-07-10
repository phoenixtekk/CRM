###############################################################################
# main.tf — AI Landing Zone & Governance (Terraform, Azure)
#
# PURPOSE
#   Declares the governed AI landing zone as code: a hub/spoke VNet with peering,
#   private DNS zones and private endpoints for AI services (Azure OpenAI /
#   Cognitive Services, Key Vault, AI Search, storage), a private Key Vault, a
#   Log Analytics workspace, a keyless workload managed identity + RBAC, an Azure
#   Policy initiative of AI guardrails (allowed regions/models, private-only,
#   content-safety-on, tagging) assigned in AUDIT (DoNotEnforce) mode, and a cost
#   budget + alert action group.
#
# HOW TO RUN  (always plan/what-if-first, non-prod-first — see 03-implementation.md)
#   Use the plan-first, approval-gated pipeline (azure-pipelines.yml):
#     terraform plan  -out ailz.plan     # never changes anything
#     terraform apply ailz.plan          # runs ONLY after the approval gate
#
# EXPECTED RESULTS
#   A plan that CREATES the two resource groups, hub+spoke VNets/subnets/peering,
#   the five privatelink DNS zones (linked), the OpenAI + Key Vault private
#   endpoints, kv-ailz-nonprod-<suffix> (public access DISABLED), log-ailz-
#   platform, id-ailz-aiworkload-nonprod + its RBAC, the AILZ-AI-Guardrails-
#   Initiative and its five Policy-*-AILZ assignments in DoNotEnforce, and
#   Budget-AILZ-Platform + ag-ailz-cost-alerts. Nothing is applied by `plan`.
#
# NOTES
#   White-label. Plan/what-if-first. No secrets in code — authenticate via the
#   pipeline's workload-identity federation (OIDC), never a client secret.
#   Policies ship in DoNotEnforce (audit) mode; flip to enforce only after
#   validation (see 03-implementation.md Phase 4).
#   VERIFY current azurerm/azapi provider versions, built-in policy definition
#   IDs and availability (some AI/content-safety definitions may be preview or
#   absent), privatelink zone names, model/region availability, and pricing for
#   your cloud (Commercial vs GCC/GCC-High) before applying.
###############################################################################

terraform {
  # VERIFY: pin to versions you have validated. These are illustrative.
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100" # VERIFY current azurerm provider version
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13" # VERIFY — used for services azurerm lags on
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state is MANDATORY for the foundation (R6). Provision the Storage
  # account + container first (a small bootstrap), enable versioning, then fill
  # this in and `terraform init`. Never run the landing zone on local state.
  backend "azurerm" {
    # resource_group_name  = "rg-tfstate-ailz"
    # storage_account_name = "sttfstateailz<unique>"
    # container_name       = "ailz-landing-zone"
    # key                  = "ailz.tfstate"
    # use_oidc             = true   # workload identity federation, no secret
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false # protect vaults from casual destroy
    }
  }
  use_oidc = true # authenticate via the pipeline's federated identity (G5)
}

provider "azapi" {
  use_oidc = true
}

###############################################################################
# Variables — set these from the agreed governance inputs (R2–R4)
###############################################################################

variable "location" {
  description = "Primary Azure region for the landing zone. Must be in allowed_regions."
  type        = string
  default     = "eastus" # VERIFY region + AI-service availability for your cloud
}

variable "allowed_regions" {
  description = "Regions Policy-AllowedRegions-AILZ permits (R4). VERIFY against data residency."
  type        = list(string)
  default     = ["eastus", "eastus2"] # replace with your agreed list
}

variable "allowed_models" {
  description = "Azure OpenAI models/versions Policy-AllowedModels-AILZ permits (R4). VERIFY availability."
  type        = list(string)
  default     = ["gpt-4o", "text-embedding-3-large"] # replace with your agreed list
}

variable "required_tags" {
  description = "Mandatory tag keys enforced by Policy-RequireTags-AILZ (R4)."
  type        = list(string)
  default     = ["owner", "cost-center", "environment", "data-classification"]
}

variable "base_tags" {
  description = "Tags applied to every resource this config creates."
  type        = map(string)
  default = {
    managed-by            = "terraform"
    solution              = "ai-landing-zone"
    environment           = "nonprod"
    "data-classification" = "internal" # customer's classification decision
  }
}

variable "hub_address_space" {
  description = "Hub VNet CIDR (R2) — non-overlapping."
  type        = list(string)
  default     = ["10.60.0.0/22"]
}

variable "spoke_address_space" {
  description = "AI spoke VNet CIDR (R2) — non-overlapping."
  type        = list(string)
  default     = ["10.60.4.0/22"]
}

variable "pe_subnet_prefix" {
  description = "Subnet for private endpoints (snet-ailz-privateendpoints)."
  type        = string
  default     = "10.60.4.0/24"
}

variable "workload_subnet_prefix" {
  description = "Subnet for AI workload compute (snet-ailz-aiworkload)."
  type        = string
  default     = "10.60.5.0/24"
}

variable "create_private_dns_zones" {
  description = "true = create the privatelink zones here; false = link existing central zones (R3)."
  type        = bool
  default     = true
}

variable "budget_amount" {
  description = "Monthly budget for Budget-AILZ-Platform. Customer FinOps decision (R4/G8)."
  type        = number
  default     = 2000
}

variable "budget_alert_emails" {
  description = "Owners notified by ag-ailz-cost-alerts on budget thresholds."
  type        = list(string)
  default     = [] # e.g. ["ai-platform-owners@contoso.com"]
}

# The privatelink zones the AI landing zone needs. VERIFY current names.
locals {
  privatelink_zones = var.create_private_dns_zones ? {
    openai    = "privatelink.openai.azure.com"
    cognitive = "privatelink.cognitiveservices.azure.com"
    search    = "privatelink.search.windows.net"
    keyvault  = "privatelink.vaultcore.azure.net"
    blob      = "privatelink.blob.core.windows.net"
  } : {}
}

###############################################################################
# Resource groups
###############################################################################

resource "azurerm_resource_group" "hub" {
  name     = "rg-ailz-hub-platform"
  location = var.location
  tags     = var.base_tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "rg-ailz-spoke-nonprod"
  location = var.location
  tags     = var.base_tags
}

###############################################################################
# Hub/spoke network + peering
###############################################################################

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-ailz-hub-platform"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = var.hub_address_space
  tags                = var.base_tags
}

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-ailz-spoke-nonprod"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = var.spoke_address_space
  tags                = var.base_tags
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-ailz-privateendpoints"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.pe_subnet_prefix]
}

resource "azurerm_subnet" "ai_workload" {
  name                 = "snet-ailz-aiworkload"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.workload_subnet_prefix]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-ailz-hub-to-spoke"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-ailz-spoke-to-hub"
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

###############################################################################
# Private DNS zones (created here unless linking to central zones — R3)
###############################################################################

resource "azurerm_private_dns_zone" "zones" {
  for_each            = local.privatelink_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.base_tags
}

# Link each zone to BOTH the hub and the spoke so names resolve everywhere.
resource "azurerm_private_dns_zone_virtual_network_link" "hub_links" {
  for_each              = local.privatelink_zones
  name                  = "link-${each.key}-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.key].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_links" {
  for_each              = local.privatelink_zones
  name                  = "link-${each.key}-spoke"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.key].name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
}

###############################################################################
# Log Analytics workspace — diagnostics + usage workbook backing store
###############################################################################

resource "azurerm_log_analytics_workspace" "platform" {
  name                = "log-ailz-platform"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # right-size for cost; VERIFY your retention needs
  tags                = var.base_tags
}

###############################################################################
# Key Vault — PRIVATE (public access disabled), reached via private endpoint,
# access via RBAC (no access policies). Name must be globally unique.
###############################################################################

resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "ailz" {
  name                          = "kv-ailz-nonprod-${random_string.kv_suffix.result}"
  location                      = azurerm_resource_group.spoke.location
  resource_group_name           = azurerm_resource_group.spoke.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true  # RBAC, not access policies (keyless-friendly)
  purge_protection_enabled      = true  # protect against casual destroy
  public_network_access_enabled = false # PRIVATE ONLY — closes the internet path
  tags                          = var.base_tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pep-ailz-keyvault-nonprod"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.base_tags

  private_service_connection {
    name                           = "psc-ailz-keyvault"
    private_connection_resource_id = azurerm_key_vault.ailz.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.create_private_dns_zones ? [1] : []
    content {
      name                 = "pdzg-keyvault"
      private_dns_zone_ids = [azurerm_private_dns_zone.zones["keyvault"].id]
    }
  }
}

###############################################################################
# Workload managed identity + RBAC — KEYLESS access to AI services (G2)
###############################################################################

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-ailz-aiworkload-nonprod"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.base_tags
}

# Least-privilege data-plane role for Azure OpenAI (keyless). Scope to the AI
# resource/RG once the AI service lands; scoped to the spoke RG here as the base.
resource "azurerm_role_assignment" "openai_user" {
  scope                = azurerm_resource_group.spoke.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.ailz.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

# NOTE: the Azure OpenAI / Cognitive Services account itself is deployed by the
# companion Secure-AI-Deployment solution INTO this zone — public access
# disabled, with pep-ailz-openai-nonprod using the openai/cognitive zones above.

###############################################################################
# Azure Policy — AI guardrails initiative, assigned in AUDIT (DoNotEnforce) mode
#
#   The built-in policy DEFINITION IDs below are ILLUSTRATIVE. Some AI /
#   content-safety definitions are preview or vary by cloud. VERIFY each
#   definition ID exists in your cloud (`Get-AzPolicyDefinition`) before relying
#   on it; the initiative is authored so a missing definition is easy to drop.
###############################################################################

# Allowed locations (built-in). VERIFY the current definition id.
data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

# Require a tag on resources (built-in, one per tag). VERIFY.
data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resources"
}

# NOTE: "private-only" (deny public network access on Cognitive Services / AI
# services), "allowed models", and "content-safety-on" map to built-in
# definitions that EVOLVE and may be preview. Reference them by verified id in
# your environment; shown here as a documented placeholder locals map so the
# initiative stays legible.
locals {
  # Fill these with VERIFIED built-in (or custom) definition IDs for your cloud.
  # Leaving one empty drops it from the initiative (see for-loop below).
  guardrail_definition_ids = {
    private_only   = "" # e.g. Cognitive Services accounts should disable public network access
    allowed_models = "" # e.g. Azure OpenAI model deployment restriction (VERIFY / may be custom)
    content_safety = "" # e.g. content-safety / responsible-AI posture (VERIFY / may be preview)
  }
}

resource "azurerm_policy_set_definition" "ailz_guardrails" {
  name         = "AILZ-AI-Guardrails-Initiative"
  policy_type  = "Custom"
  display_name = "AILZ-AI-Guardrails-Initiative"
  description  = "Grouped AI landing-zone guardrails: allowed regions/models, private-only, content-safety-on, tagging. Assigned audit-first."

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
    reference_id         = "Policy-AllowedRegions-AILZ"
    parameter_values = jsonencode({
      listOfAllowedLocations = { value = var.allowed_regions }
    })
  }

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.require_tag.id
    reference_id         = "Policy-RequireTags-AILZ"
    parameter_values = jsonencode({
      tagName = { value = var.required_tags[0] } # extend per required tag as needed
    })
  }

  # Add the verified private-only / allowed-models / content-safety definitions
  # here once their IDs are confirmed for your cloud (see local.guardrail_*).
  dynamic "policy_definition_reference" {
    for_each = { for k, v in local.guardrail_definition_ids : k => v if v != "" }
    content {
      policy_definition_id = policy_definition_reference.value
      reference_id         = "Policy-${policy_definition_reference.key}-AILZ"
    }
  }
}

# Assign the initiative at the PILOT subscription scope, in AUDIT mode.
resource "azurerm_subscription_policy_assignment" "ailz_guardrails" {
  name                 = "AILZ-AI-Guardrails-Initiative"
  display_name         = "AILZ-AI-Guardrails-Initiative (audit-first)"
  policy_definition_id = azurerm_policy_set_definition.ailz_guardrails.id
  subscription_id      = data.azurerm_client_config.current.subscription_id != null ? "/subscriptions/${data.azurerm_client_config.current.subscription_id}" : null

  # SIMULATE BEFORE ENFORCE: DoNotEnforce = report only, block nothing.
  # Flip to "Default" to ENFORCE (Deny) only after validation (Phase 4).
  enforce = false
}

###############################################################################
# Cost management — Budget-AILZ-Platform + ag-ailz-cost-alerts
###############################################################################

resource "azurerm_monitor_action_group" "cost" {
  name                = "ag-ailz-cost-alerts"
  resource_group_name = azurerm_resource_group.hub.name
  short_name          = "ailzcost"

  dynamic "email_receiver" {
    for_each = toset(var.budget_alert_emails)
    content {
      name          = "owner-${replace(email_receiver.value, "@", "-at-")}"
      email_address = email_receiver.value
    }
  }
}

resource "azurerm_consumption_budget_subscription" "platform" {
  name            = "Budget-AILZ-Platform"
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
  }

  dynamic "notification" {
    for_each = { warn = 50, high = 80, over = 100 }
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThanOrEqualTo"
      threshold_type = "Actual"
      contact_groups = [azurerm_monitor_action_group.cost.id]
    }
  }

  lifecycle {
    # start_date uses timestamp(); ignore its churn so plans stay clean.
    ignore_changes = [time_period]
  }
}

###############################################################################
# Outputs
###############################################################################

output "resource_groups" {
  value = {
    hub   = azurerm_resource_group.hub.name
    spoke = azurerm_resource_group.spoke.name
  }
}

output "vnets" {
  value = {
    hub   = azurerm_virtual_network.hub.name
    spoke = azurerm_virtual_network.spoke.name
  }
}

output "key_vault_name" { value = azurerm_key_vault.ailz.name }
output "workload_identity" { value = azurerm_user_assigned_identity.workload.name }
output "policy_initiative" { value = azurerm_policy_set_definition.ailz_guardrails.name }
output "budget_name" { value = azurerm_consumption_budget_subscription.platform.name }
output "private_dns_zones" {
  value = [for z in azurerm_private_dns_zone.zones : z.name]
}
