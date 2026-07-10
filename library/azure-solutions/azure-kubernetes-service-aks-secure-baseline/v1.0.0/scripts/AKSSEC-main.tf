###############################################################################
# AKSSEC-main.tf — AKS Secure Baseline (Terraform)
#
# PURPOSE
#   Deploy a private, hardened Azure Kubernetes Service cluster as code:
#     - Private API endpoint (no public IP), Azure CNI inside an existing subnet
#     - Microsoft Entra ID integration + Azure RBAC for Kubernetes (local accounts disabled)
#     - Azure Policy add-on (Gatekeeper) for admission guardrails
#     - OIDC issuer + workload identity, plus a user-assigned managed identity and
#       a federated credential for secretless pod-to-Azure auth
#
# HOW TO RUN  (ALWAYS plan first — never blind-apply; non-prod cluster first)
#   az login
#   terraform init
#   terraform plan  -out aksbaseline.plan        # <-- review the resource list (the gate)
#   terraform apply aksbaseline.plan             # only after review + approval
#   Rollback: terraform destroy   (destroys the NON-PROD stack this file created)
#
# EXPECTED RESULTS
#   A private AKS cluster with Entra+Azure RBAC, the policy add-on, OIDC/workload identity,
#   and a federated managed identity — ready for the kubectl RBAC/policy manifests
#   (AKSSEC-baseline.yaml) and Defender for Containers.
#
# NOTES
#   White-label. Plan/what-if first. Non-prod first. Feature/add-on/API versions marked
#   "verify" move between GA and preview — verify current availability in your region
#   before relying on them. Placeholder values (contoso, subnet IDs, group IDs) MUST be set.
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100" # verify current provider version
    }
  }
}

provider "azurerm" {
  features {}
}

# ---------------------------------------------------------------------------
# Variables — set these in terraform.tfvars (do NOT commit real IDs to source control)
# ---------------------------------------------------------------------------
variable "resource_group_name" {
  type        = string
  description = "Resource group, e.g. 'AKS RG - Baseline - NonProd' (no spaces recommended for RG names)"
  default     = "rg-aks-baseline-nonprod"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name (maps to 'AKS Cluster - Baseline - NonProd')"
  default     = "aks-baseline-nonprod"
}

variable "dns_prefix_private" {
  type    = string
  default = "aksbaseline"
}

variable "vnet_subnet_id" {
  type        = string
  description = "Resource ID of the EXISTING, CNI-sized subnet the cluster nodes/pods use"
  # example: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "Entra group object ID(s) for 'AKS Admins - Baseline - Prod' (Azure RBAC cluster admins)"
  # example: ["00000000-0000-0000-0000-000000000000"]
}

variable "kubernetes_version" {
  type        = string
  description = "AKS version — verify a currently supported version for your region"
  default     = null
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

# ---------------------------------------------------------------------------
# Resource group
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    solution = "AKS Secure Baseline"
    stage    = "NonProd"
  }
}

# ---------------------------------------------------------------------------
# User-assigned managed identity for WORKLOAD IDENTITY (secretless pod-to-Azure)
#   Grant this identity LEAST-PRIVILEGE access to the target Azure resource
#   (e.g. Key Vault Secrets User on ONE vault) OUTSIDE this file / after apply.
# ---------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-aks-workload-baseline-nonprod" # 'AKS Workload Identity - Baseline - NonProd'
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
}

# ---------------------------------------------------------------------------
# The private AKS cluster
# ---------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix_private
  kubernetes_version  = var.kubernetes_version

  # --- Private cluster networking: no public API endpoint ---
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false

  # --- Entra ID + Azure RBAC for Kubernetes; disable local (cluster-admin) accounts ---
  local_account_disabled = true
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  # --- Azure Policy add-on (Gatekeeper) for admission guardrails ---
  azure_policy_enabled = true

  # --- OIDC issuer + workload identity (secretless pod auth) ---
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # --- Azure CNI networking inside your VNet ---
  network_profile {
    network_plugin = "azure"
    network_policy = "azure" # verify: 'azure' / 'calico' / Cilium availability in your region
  }

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = var.vnet_subnet_id
    # Node hardening: keep the host OS patched and the pool on a supported image.
    os_sku         = "AzureLinux" # verify current node OS SKUs; hardened by default
    max_pods       = 30
  }

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.aks.tags
}

# ---------------------------------------------------------------------------
# Federated credential — ties the managed identity to the Kubernetes service
# account 'wi-app-baseline' in namespace 'app-baseline' (see AKSSEC-baseline.yaml).
# ---------------------------------------------------------------------------
resource "azurerm_federated_identity_credential" "workload" {
  name                = "fic-app-baseline"
  resource_group_name = azurerm_resource_group.aks.name
  parent_id           = azurerm_user_assigned_identity.workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:app-baseline:wi-app-baseline"
}

# ---------------------------------------------------------------------------
# Outputs — used by AKSSEC-baseline.yaml (client id) and the validation script
# ---------------------------------------------------------------------------
output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "workload_identity_client_id" {
  description = "Set this as azure.workload.identity/client-id on the wi-app-baseline ServiceAccount"
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}
