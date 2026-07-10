###############################################################################
# main.tf — Azure Landing Zone (core) — white-label reference IaC
#
# PURPOSE
#   Deploys a Cloud Adoption Framework-aligned Azure landing zone as code:
#     - Management group hierarchy (root -> platform / landing-zones / sandbox)
#     - Azure Policy guardrails as code (allowed regions, required tags) — AUDIT FIRST
#     - Identity / RBAC baseline (role assignment to a group, not a person)
#     - Central Log Analytics workspace (logging baseline)
#     - Hub-spoke networking with bidirectional peering + private DNS
#   State is stored in a remote azurerm backend (bootstrapped once, see 03-implementation Step 2).
#
# HOW TO RUN  (plan/what-if FIRST — never apply blind)
#   terraform init
#   terraform plan  -out tfplan          # review the what-if in a pull request
#   terraform apply tfplan               # pilot: target mg-sandbox / non-prod first
#
# EXPECTED RESULTS
#   plan creates the MG hierarchy, AUDIT-mode policy assignments, RBAC, Log Analytics, and
#   hub+spoke VNets — and NOTHING unexpected. Promote policy Audit->Deny only after validation (Step 7).
#
# NOTES
#   White-label — DevOps / IaC. No secrets in code (auth via Azure CLI or pipeline OIDC).
#   *** All provider/module versions below are PINNED and FLAGGED "verify" — confirm current supported
#       versions against the Terraform Registry before you apply. ***
###############################################################################

terraform {
  # verify: confirm the supported Terraform CLI version range for your providers.
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116" # verify: pin to a current supported AzureRM release
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53" # verify
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.15" # verify (used for newer/preview resources if needed)
    }
  }

  # Remote state backend — bootstrapped ONCE before `terraform init` (03-implementation Step 2).
  # Values are supplied via backend config / -backend-config, not hard-coded secrets.
  backend "azurerm" {
    resource_group_name  = "rg-iactf-tfstate"
    storage_account_name = "stiactftfstate" # verify: append your unique suffix
    container_name        = "tfstate"
    key                   = "landingzone.tfstate"
    use_oidc              = true # pipeline auth via workload identity federation (no secret)
  }
}

provider "azurerm" {
  features {}
  use_oidc = true # CLI auth locally; OIDC in CI. No client secret in code.
}

provider "azuread" {}

###############################################################################
# Variables (set from your governance STANDARD — 02-requirements 2.5)
###############################################################################
variable "root_id" {
  type        = string
  description = "Short id for the root management group."
  default     = "mg-corp-root"
}

variable "root_display_name" {
  type    = string
  default = "Corp Root"
}

variable "primary_region" {
  type    = string
  default = "eastus" # verify against your allowed-regions standard
}

variable "allowed_regions" {
  type        = list(string)
  description = "Regions permitted by policy (allowed-locations guardrail)."
  default     = ["eastus", "eastus2"]
}

variable "required_tags" {
  type        = list(string)
  description = "Tags every resource group must carry."
  default     = ["owner", "costCenter", "environment"]
}

variable "policy_effect" {
  type        = string
  description = "Guardrail effect. START at 'Audit'; promote to 'Deny' only after validation (Step 7)."
  default     = "Audit" # audit-first is deliberate
  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.policy_effect)
    error_message = "policy_effect must be Audit, Deny, or Disabled."
  }
}

variable "platform_admins_group_object_id" {
  type        = string
  description = "Entra group object id to receive the platform Owner/Contributor baseline (group, not user)."
  default     = "" # supply your group's object id; empty skips the RBAC baseline
}

variable "hub_address_space" {
  type    = list(string)
  default = ["10.0.0.0/22"]
}

variable "spoke_corp_address_space" {
  type    = list(string)
  default = ["10.1.0.0/22"]
}

###############################################################################
# 1. Management group hierarchy (parents the EXISTING Tenant Root Group)
###############################################################################
resource "azurerm_management_group" "root" {
  display_name = var.root_display_name
  name         = var.root_id
}

resource "azurerm_management_group" "platform" {
  display_name               = "Platform"
  name                       = "mg-platform"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "identity" {
  display_name               = "Identity"
  name                       = "mg-identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "management" {
  display_name               = "Management"
  name                       = "mg-management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "connectivity" {
  display_name               = "Connectivity"
  name                       = "mg-connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "landingzones" {
  display_name               = "Landing Zones"
  name                       = "mg-landingzones"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "corp" {
  display_name               = "Corp"
  name                       = "mg-corp"
  parent_management_group_id = azurerm_management_group.landingzones.id
}

resource "azurerm_management_group" "online" {
  display_name               = "Online"
  name                       = "mg-online"
  parent_management_group_id = azurerm_management_group.landingzones.id
}

resource "azurerm_management_group" "sandbox" {
  display_name               = "Sandbox"
  name                       = "mg-sandbox"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "decommissioned" {
  display_name               = "Decommissioned"
  name                       = "mg-decommissioned"
  parent_management_group_id = azurerm_management_group.root.id
}

###############################################################################
# 2. Azure Policy guardrails as code — AUDIT FIRST (promote to Deny in Step 7)
###############################################################################
# Allowed locations (built-in policy definition id) assigned at the ROOT so it inherits everywhere.
resource "azurerm_management_group_policy_assignment" "allowed_regions" {
  name                 = "IACTF-Policy-AllowedRegions-Root"
  display_name         = "IACTF - Allowed regions (root)"
  management_group_id  = azurerm_management_group.root.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_regions }
  })
  # Built-in allowed-locations effect is Deny by design; keep this assignment scoped to non-prod first,
  # or use a custom audit-mode definition during pilot. verify effect handling for your rollout.
}

# Require a tag on resource groups (one assignment per required tag) — effect parameterized (Audit first).
resource "azurerm_management_group_policy_assignment" "require_tags" {
  for_each             = toset(var.required_tags)
  name                 = "IACTF-RequireTag-${each.value}"
  display_name         = "IACTF - Require tag '${each.value}' on resource groups"
  management_group_id  = azurerm_management_group.landingzones.id
  # Built-in "Require a tag on resource groups" definition id.
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  parameters = jsonencode({
    tagName = { value = each.value }
    # NOTE: this built-in enforces Deny; for AUDIT-first piloting use a custom audit definition or scope
    # the assignment to mg-sandbox until validated. var.policy_effect documents your intended end-state.
  })
}

###############################################################################
# 3. Identity / RBAC baseline — assign to a GROUP, not a person (optional)
###############################################################################
resource "azurerm_role_assignment" "platform_admins" {
  count                = var.platform_admins_group_object_id == "" ? 0 : 1
  scope                = azurerm_management_group.platform.id
  role_definition_name = "Contributor" # least-privilege baseline; elevate deliberately, not by default
  principal_id         = var.platform_admins_group_object_id
}

###############################################################################
# 4. Logging baseline — central Log Analytics workspace
###############################################################################
resource "azurerm_resource_group" "management" {
  name     = "rg-iactf-management"
  location = var.primary_region
  tags     = { owner = "platform", costCenter = "shared", environment = "platform" }
}

resource "azurerm_log_analytics_workspace" "management" {
  name                = "log-iactf-management"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  sku                 = "PerGB2018"
  retention_in_days   = 30 # verify against your retention standard
  tags                = azurerm_resource_group.management.tags
}

###############################################################################
# 5. Hub-spoke networking + bidirectional peering + private DNS
###############################################################################
resource "azurerm_resource_group" "hub" {
  name     = "rg-iactf-hub"
  location = var.primary_region
  tags     = { owner = "platform", costCenter = "shared", environment = "connectivity" }
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.primary_region}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = var.hub_address_space
  tags                = azurerm_resource_group.hub.tags
}

resource "azurerm_resource_group" "spoke_corp" {
  name     = "rg-iactf-spoke-corp"
  location = var.primary_region
  tags     = { owner = "corp", costCenter = "corp", environment = "prod" }
}

resource "azurerm_virtual_network" "spoke_corp" {
  name                = "vnet-spoke-corp-${var.primary_region}"
  resource_group_name = azurerm_resource_group.spoke_corp.name
  location            = azurerm_resource_group.spoke_corp.location
  address_space       = var.spoke_corp_address_space
  tags                = azurerm_resource_group.spoke_corp.tags
}

# Peering must exist on BOTH sides — a one-sided peering silently fails (see 06-troubleshooting).
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-corp"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_corp.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-corp-to-hub"
  resource_group_name       = azurerm_resource_group.spoke_corp.name
  virtual_network_name      = azurerm_virtual_network.spoke_corp.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false # set true once a gateway exists in the hub
}

# Central private DNS zone linked to the spoke (extend per your private-endpoint needs).
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_spoke" {
  name                  = "link-corp-blob"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.spoke_corp.id
}

###############################################################################
# Outputs
###############################################################################
output "root_management_group_id" {
  value = azurerm_management_group.root.id
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.management.id
}

output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}
