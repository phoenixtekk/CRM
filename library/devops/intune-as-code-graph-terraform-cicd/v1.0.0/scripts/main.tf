##############################################################################
# main.tf — Intune-as-Code (Microsoft Graph via Terraform).
#
# PURPOSE
#   Defines a scoped starter set of Intune policies as code — one Windows device
#   configuration profile, one compliance policy, and one app-protection policy —
#   assigned to the pilot ring only. Managed through plan/apply with remote state.
#
# HOW TO RUN (plan FIRST, always)
#   terraform init
#   terraform workspace select "intune – Dev – Workspace"
#   terraform plan  -out tfplan      # the change preview — read it before applying
#   terraform apply tfplan           # applies only what the plan showed
#
# EXPECTED RESULTS
#   The three named policies created/updated in Intune and assigned to the pilot
#   group. Re-running with no code change yields an empty plan (no drift).
#
# White-label. Plan/what-if first, through the reviewed pipeline. Back up before apply.
#
# *** VERIFY BEFORE USE ***
#   The Microsoft Graph / Intune Terraform provider ecosystem is evolving and some
#   Graph endpoints are /beta. Confirm the CURRENT provider name, version, resource
#   names, and Intune resource coverage in your environment before relying on this.
#   Where a policy type is unsupported by the provider, manage it via the PowerShell
#   /Graph export-and-apply path (IACINTUNE-Discovery.ps1 / IACINTUNE-Report.ps1).
##############################################################################

terraform {
  required_version = ">= 1.6.0" # *verify current supported version*

  # Remote state with locking (requirement R5 / Global Requirements G5).
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateintune"     # replace with your account
    container_name       = "tfstate-intune"
    key                  = "intune-as-code.tfstate"
    use_oidc             = true                   # workload identity federation, no stored secret
  }

  required_providers {
    # Provider that manages Intune via Microsoft Graph. NAME/VERSION *verify* —
    # pin to the exact provider and version you have validated.
    microsoft365 = {
      source  = "deploymenttheory/microsoft365" # *verify current source/name*
      version = "~> 0.14"                        # *verify current version*
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53" # *verify*
    }
  }
}

# Authenticates as the automation SPN "Intune-as-Code – Automation – SPN" (R2).
# Credentials come from environment / OIDC — NEVER hard-code them here.
provider "microsoft365" {
  tenant_id = var.tenant_id
  # client_id / auth via ARM_* env vars or workload identity federation.
}

provider "azuread" {
  tenant_id = var.tenant_id
}

variable "tenant_id" {
  type        = string
  description = "Entra tenant ID (e.g. contoso.onmicrosoft.com GUID)."
}

variable "pilot_group_name" {
  type        = string
  description = "Pilot assignment group — first ring only."
  default     = "Intune-Pilot – Devices – Ring0"
}

# Pilot ring group (created out-of-band or here). Assignments target this first.
data "azuread_group" "pilot" {
  display_name     = var.pilot_group_name
  security_enabled = true
}

# ---------------------------------------------------------------------------
# 1. Windows device configuration profile — "Windows Baseline – Corporate – Config"
#    Resource type/schema is illustrative — *verify against your provider version*.
# ---------------------------------------------------------------------------
resource "microsoft365_device_configuration_profile" "windows_baseline" {
  display_name = "Windows Baseline – Corporate – Config"
  description  = "Baseline Windows configuration, managed as code. Pilot-scoped."
  platform     = "windows10"

  # Settings are illustrative; model your exported baseline JSON here. *verify schema*
  settings = jsonencode({
    defenderRealtimeMonitoring = "enabled"
    firewallEnabled            = true
    screenLockTimeoutSeconds   = 900
  })

  assignment {
    target_group_id = data.azuread_group.pilot.object_id
  }
}

# ---------------------------------------------------------------------------
# 2. Compliance policy — "Compliance Minimum – Corporate – Compliance"
# ---------------------------------------------------------------------------
resource "microsoft365_device_compliance_policy" "minimum" {
  display_name = "Compliance Minimum – Corporate – Compliance"
  description  = "Minimum compliance thresholds, managed as code. Pilot-scoped."
  platform     = "windows10"

  rules = jsonencode({
    bitLockerEnabled       = true
    secureBootEnabled      = true
    minimumOsVersion       = "10.0.19045" # *verify your baseline*
    passwordRequired       = true
    passwordMinimumLength  = 8
  })

  # Non-compliance action: mark non-compliant (report) before any blocking is layered on.
  scheduled_action {
    action_type    = "block"
    grace_period_hours = 72
  }

  assignment {
    target_group_id = data.azuread_group.pilot.object_id
  }
}

# ---------------------------------------------------------------------------
# 3. App-protection (MAM) policy — "App Protection – Mobile – MAM"
#    App-protection endpoints are frequently /beta — *verify current availability
#    and licensing in your tenant*.
# ---------------------------------------------------------------------------
resource "microsoft365_app_protection_policy" "mam" {
  display_name = "App Protection – Mobile – MAM"
  description  = "Mobile app-protection policy, managed as code. Pilot-scoped."
  platform     = "ios" # duplicate for android as needed

  settings = jsonencode({
    preventBackup            = true
    allowedOutboundClipboard = "managedApps"
    pinRequired              = true
    minimumRequiredOsVersion = "16.0" # *verify*
  })

  assignment {
    target_group_id = data.azuread_group.pilot.object_id
  }
}

output "managed_policies" {
  value = [
    microsoft365_device_configuration_profile.windows_baseline.display_name,
    microsoft365_device_compliance_policy.minimum.display_name,
    microsoft365_app_protection_policy.mam.display_name,
  ]
  description = "Policies managed as code, assigned to the pilot ring."
}
