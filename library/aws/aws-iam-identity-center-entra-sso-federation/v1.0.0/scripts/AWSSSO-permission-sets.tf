# =============================================================================
# AWSSSO-permission-sets.tf — Terraform (AWS provider) for the IAM Identity
#   Center permission sets and account assignments that map Entra groups to
#   least-privilege access.
#
# PURPOSE
#   Declares the five named permission sets and the group -> permission set ->
#   account assignments as code, so access is auditable, reviewable, and
#   reproducible. Groups are provisioned into IAM Identity Center by Entra SCIM
#   first; this config looks them up by display name and assigns access.
#
# HOW TO RUN (PLAN-FIRST, always)
#   1. Configure the AWS provider to ASSUME your least-privilege role (never
#      root, never static admin keys) and a remote backend (S3 + DynamoDB lock).
#   2. terraform init
#   3. terraform plan   -var-file=pilot.tfvars     # REVIEW before applying
#   4. terraform apply  -var-file=pilot.tfvars     # pilot: sandbox scope only
#      (Add production account IDs in a later var-file and re-plan/apply per
#       Expand wave, after change approval.)
#
# EXPECTED RESULTS
#   Terraform creates: SSO-Admin – Sandbox – Pilot, SSO-ReadOnly – AllAccounts –
#   Prod, SSO-PowerUser – Workloads – Prod, SSO-Billing – Management – Prod,
#   SSO-BreakGlass – Management – Emergency, and the assignments you list.
#
# NOTES
#   White-label. Plan-first / pilot-first. Verify current AWS provider version
#   and IAM Identity Center feature availability for your partition.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # verify current provider version
    }
  }
  # backend "s3" { ... }   # configure your remote state (Global Requirements G5)
}

variable "aws_region"        { type = string }
variable "assume_role_arn"   { type = string, description = "Least-privilege deployment role to assume (never root)." }
variable "session_admin"     { type = string, default = "PT1H" }
variable "session_standard"  { type = string, default = "PT4H" }

# Account IDs (leave production maps empty for the pilot; fill per Expand wave).
variable "sandbox_account_id"    { type = string }
variable "management_account_id" { type = string }
variable "readonly_account_ids"  { type = list(string), default = [] }
variable "workload_account_ids"  { type = list(string), default = [] }

# Entra-provisioned group display names (must match the SCIM-synced names).
variable "grp_admin_pilot"   { type = string, default = "AWS-SSO-Admin-Sandbox-Pilot" }
variable "grp_readonly"      { type = string, default = "AWS-SSO-ReadOnly-AllAccounts" }
variable "grp_poweruser"     { type = string, default = "AWS-SSO-PowerUser-Workloads" }
variable "grp_billing"       { type = string, default = "AWS-SSO-Billing-Management" }
variable "grp_breakglass"    { type = string, default = "AWS-SSO-BreakGlass-Emergency" }

provider "aws" {
  region = var.aws_region
  assume_role { role_arn = var.assume_role_arn }
}

data "aws_ssoadmin_instances" "this" {}
locals {
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

# --- Look up the SCIM-provisioned Entra groups by display name --------------
data "aws_identitystore_group" "admin_pilot" {
  identity_store_id = local.identity_store_id
  alternate_identifier { unique_attribute { attribute_path = "DisplayName", attribute_value = var.grp_admin_pilot } }
}
data "aws_identitystore_group" "readonly" {
  identity_store_id = local.identity_store_id
  alternate_identifier { unique_attribute { attribute_path = "DisplayName", attribute_value = var.grp_readonly } }
}
data "aws_identitystore_group" "poweruser" {
  identity_store_id = local.identity_store_id
  alternate_identifier { unique_attribute { attribute_path = "DisplayName", attribute_value = var.grp_poweruser } }
}
data "aws_identitystore_group" "billing" {
  identity_store_id = local.identity_store_id
  alternate_identifier { unique_attribute { attribute_path = "DisplayName", attribute_value = var.grp_billing } }
}
data "aws_identitystore_group" "breakglass" {
  identity_store_id = local.identity_store_id
  alternate_identifier { unique_attribute { attribute_path = "DisplayName", attribute_value = var.grp_breakglass } }
}

# --- Permission sets (name uses the <Purpose> – <Scope> – <Stage> convention) -
resource "aws_ssoadmin_permission_set" "admin_pilot" {
  name             = "SSO-Admin – Sandbox – Pilot"
  description      = "Administrative access, sandbox/non-production only, pilot."
  instance_arn     = local.instance_arn
  session_duration = var.session_admin
}
resource "aws_ssoadmin_permission_set" "readonly" {
  name             = "SSO-ReadOnly – AllAccounts – Prod"
  description      = "Read-only across assigned accounts."
  instance_arn     = local.instance_arn
  session_duration = var.session_standard
}
resource "aws_ssoadmin_permission_set" "poweruser" {
  name             = "SSO-PowerUser – Workloads – Prod"
  description      = "Power-user (no IAM/billing) on workload accounts."
  instance_arn     = local.instance_arn
  session_duration = var.session_standard
}
resource "aws_ssoadmin_permission_set" "billing" {
  name             = "SSO-Billing – Management – Prod"
  description      = "Billing/cost access scoped to the management account."
  instance_arn     = local.instance_arn
  session_duration = var.session_standard
}
resource "aws_ssoadmin_permission_set" "breakglass" {
  name             = "SSO-BreakGlass – Management – Emergency"
  description      = "Emergency administrative access; tiny, monitored group."
  instance_arn     = local.instance_arn
  session_duration = var.session_admin
}

# --- Managed-policy attachments (least privilege) ---------------------------
resource "aws_ssoadmin_managed_policy_attachment" "admin_pilot" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin_pilot.arn
}
resource "aws_ssoadmin_managed_policy_attachment" "readonly" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
}
resource "aws_ssoadmin_managed_policy_attachment" "poweruser" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  permission_set_arn = aws_ssoadmin_permission_set.poweruser.arn
}
resource "aws_ssoadmin_managed_policy_attachment" "billing" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
  permission_set_arn = aws_ssoadmin_permission_set.billing.arn
}
resource "aws_ssoadmin_managed_policy_attachment" "breakglass" {
  instance_arn       = local.instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.breakglass.arn
}

# --- Assignments: PILOT (sandbox account only) ------------------------------
resource "aws_ssoadmin_account_assignment" "pilot_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_pilot.arn
  principal_id       = data.aws_identitystore_group.admin_pilot.group_id
  principal_type     = "GROUP"
  target_id          = var.sandbox_account_id
  target_type        = "AWS_ACCOUNT"
}
resource "aws_ssoadmin_account_assignment" "pilot_readonly" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  principal_id       = data.aws_identitystore_group.readonly.group_id
  principal_type     = "GROUP"
  target_id          = var.sandbox_account_id
  target_type        = "AWS_ACCOUNT"
}

# --- Assignments: EXPAND (production; empty lists = nothing applied) ---------
resource "aws_ssoadmin_account_assignment" "prod_readonly" {
  for_each           = toset(var.readonly_account_ids)
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  principal_id       = data.aws_identitystore_group.readonly.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}
resource "aws_ssoadmin_account_assignment" "prod_poweruser" {
  for_each           = toset(var.workload_account_ids)
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.poweruser.arn
  principal_id       = data.aws_identitystore_group.poweruser.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}
resource "aws_ssoadmin_account_assignment" "prod_billing" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.billing.arn
  principal_id       = data.aws_identitystore_group.billing.group_id
  principal_type     = "GROUP"
  target_id          = var.management_account_id
  target_type        = "AWS_ACCOUNT"
}
resource "aws_ssoadmin_account_assignment" "prod_breakglass" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.breakglass.arn
  principal_id       = data.aws_identitystore_group.breakglass.group_id
  principal_type     = "GROUP"
  target_id          = var.management_account_id
  target_type        = "AWS_ACCOUNT"
}

output "permission_set_arns" {
  value = {
    admin_pilot = aws_ssoadmin_permission_set.admin_pilot.arn
    readonly    = aws_ssoadmin_permission_set.readonly.arn
    poweruser   = aws_ssoadmin_permission_set.poweruser.arn
    billing     = aws_ssoadmin_permission_set.billing.arn
    breakglass  = aws_ssoadmin_permission_set.breakglass.arn
  }
}
