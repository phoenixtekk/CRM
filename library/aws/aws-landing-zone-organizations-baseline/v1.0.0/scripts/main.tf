###############################################################################
# main.tf — AWS Landing Zone & Organizations Baseline (Terraform)
#
# PURPOSE
#   Declares the governed multi-account foundation as code: AWS Organizations
#   OU hierarchy, a Security OU with a Log-Archive account, an organization
#   CloudTrail + AWS Config aggregator delivering to a central encrypted log
#   bucket, and five preventive Service Control Policy (SCP) guardrails.
#
# HOW TO RUN  (always plan-first, non-prod-first — see 03-implementation.md)
#   Use the wrapper (plan-first, approval-gated):
#     ./AWSLZ-Deploy.sh plan       # never changes anything
#     ./AWSLZ-Deploy.sh apply      # re-plans, shows plan, requires typed confirm
#
# EXPECTED RESULTS
#   A plan that CREATES the OUs, core account(s), org CloudTrail, log bucket +
#   KMS key, Config aggregator, and the five SCPs — attached to the PILOT OUs
#   only (Workloads-NonProd, Sandbox) until validated. Nothing is applied by
#   `plan`.
#
# NOTES
#   White-label. Plan-first. No static credentials — authenticate via an assumed
#   role / permission set / OIDC (never root or static admin keys).
#   VERIFY current provider/CLI versions, feature availability, and pricing for
#   your AWS partition (Commercial vs GovCloud) before applying. SCP inheritance
#   and evaluation are order-sensitive — verify behavior. This is the Terraform
#   landing-zone path; if you use AWS Control Tower, treat these SCPs + baseline
#   as ADD-ONS to Control Tower's, not replacements.
###############################################################################

terraform {
  # VERIFY: pin to versions you have validated. These are illustrative, not
  # authoritative — check the current Terraform + AWS provider releases.
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # VERIFY current AWS provider version
    }
  }

  # Remote state is MANDATORY for the foundation (R6). Provision the S3 bucket +
  # DynamoDB lock table first (a small bootstrap), then fill this in and
  # `terraform init`. Never run the landing zone on local state.
  backend "s3" {
    # bucket         = "tfstate-<org>-landingzone"
    # key            = "landing-zone/terraform.tfstate"
    # region         = "us-east-1"        # VERIFY / your partition
    # dynamodb_table = "tfstate-lock"
    # encrypt        = true
  }
}

# The AWS provider authenticates via the environment's assumed role / OIDC.
# Do NOT put access keys here.
provider "aws" {
  # region is taken from the environment / -var; keep it in your allowed list.
  default_tags {
    tags = var.tags
  }
}

###############################################################################
# Variables
###############################################################################

variable "allowed_regions" {
  description = "Regions the SCP-RegionLockdown-Guardrail permits. VERIFY against data-residency needs (R4)."
  type        = list(string)
  default     = ["us-east-1", "us-west-2"] # replace with your agreed list
}

variable "tags" {
  description = "Tagging standard applied to all resources (R5)."
  type        = map(string)
  default = {
    ManagedBy   = "terraform"
    Solution    = "aws-landing-zone-baseline"
    Environment = "foundation"
  }
}

variable "log_archive_account_email" {
  description = "Unique email for the Log-Archive account (required if Terraform vends it)."
  type        = string
  default     = "" # set before applying if creating the account here
}

variable "exempt_account_ids" {
  description = "Management/security/break-glass account IDs to EXEMPT from broad SCP denies. Never lock these out."
  type        = list(string)
  default     = []
}

###############################################################################
# Organization + OU hierarchy
#   Assumes Organizations is already ALL-features (R1). Import the existing org
#   if present rather than recreating it.
###############################################################################

data "aws_organizations_organization" "this" {}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_prod" {
  name      = "Workloads-Prod"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_nonprod" {
  name      = "Workloads-NonProd"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

# The PILOT OUs SCPs attach to first (validate here before touching prod).
locals {
  pilot_ou_ids = [
    aws_organizations_organizational_unit.workloads_nonprod.id,
    aws_organizations_organizational_unit.sandbox.id,
  ]
}

###############################################################################
# Central, encrypted, tamper-resistant log bucket + CMK (in the Log-Archive
# account in a full build; shown here as the destination the org trail uses).
###############################################################################

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "org_logs" {
  description             = "kms-org-logs — CMK for central CloudTrail/Config logs"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  # NOTE: a real deployment adds a key policy granting CloudTrail/Config the
  # scoped encrypt permissions. VERIFY the current required key-policy statements.
}

resource "aws_kms_alias" "org_logs" {
  name          = "alias/kms-org-logs"
  target_key_id = aws_kms_key.org_logs.key_id
}

resource "aws_s3_bucket" "log_archive" {
  bucket = "org-log-archive-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.org_logs.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_archive" {
  bucket                  = aws_s3_bucket.log_archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# NOTE: attach a bucket policy allowing the ORGANIZATION CloudTrail to write,
# and (optionally) S3 Object Lock for stronger tamper resistance. VERIFY the
# current CloudTrail delivery bucket-policy requirements for org trails.

###############################################################################
# Organization CloudTrail  — Trail-Org-CloudTrail
###############################################################################

resource "aws_cloudtrail" "org" {
  name                          = "Trail-Org-CloudTrail"
  s3_bucket_name                = aws_s3_bucket.log_archive.id
  is_organization_trail         = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true
  kms_key_id                    = aws_kms_key.org_logs.arn
  depends_on                    = [aws_s3_bucket_policy_placeholder]
}

# Placeholder so the graph is explicit that a bucket policy must exist first.
# Replace with a real aws_s3_bucket_policy granting cloudtrail.amazonaws.com.
resource "null_resource" "aws_s3_bucket_policy_placeholder" {}

###############################################################################
# AWS Config org aggregator — Config-Org-Aggregator
#   Per-account recorders are set by the account baseline; this aggregates them.
###############################################################################

resource "aws_config_configuration_aggregator" "org" {
  name = "Config-Org-Aggregator"
  organization_aggregation_source {
    all_regions = true
    # role_arn = "<the Config aggregator role>"  # VERIFY / provide the role
  }
}

###############################################################################
# Service Control Policies (preventive guardrails)
#   Attached to the PILOT OUs only (local.pilot_ou_ids). Extend to remaining OUs
#   at Expand, after validation — and EXEMPT the management/security accounts.
###############################################################################

# 1) Deny an account leaving the organization.
resource "aws_organizations_policy" "deny_leave_org" {
  name    = "SCP-DenyLeaveOrg-Guardrail"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "DenyLeaveOrg", Effect = "Deny",
      Action = ["organizations:LeaveOrganization"], Resource = "*"
    }]
  })
}

# 2) Deny root-user actions (bounded to the root principal).
resource "aws_organizations_policy" "deny_root" {
  name    = "SCP-DenyRootActions-Guardrail"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "DenyRoot", Effect = "Deny", Action = "*", Resource = "*",
      Condition = { StringLike = { "aws:PrincipalArn" = "arn:aws:iam::*:root" } }
    }]
  })
}

# 3) Region lockdown — deny actions outside the allowed regions (with the usual
#    global-service exemptions). VERIFY the exempt global services for your needs.
resource "aws_organizations_policy" "region_lockdown" {
  name    = "SCP-RegionLockdown-Guardrail"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "RegionLockdown", Effect = "Deny", Resource = "*",
      NotAction = [
        "iam:*", "sts:*", "organizations:*", "cloudfront:*",
        "route53:*", "support:*", "waf:*", "budgets:*"
      ],
      Condition = { StringNotEquals = { "aws:RequestedRegion" = var.allowed_regions } }
    }]
  })
}

# 4) Protect the security services — deny disabling CloudTrail/Config/GuardDuty.
resource "aws_organizations_policy" "protect_security" {
  name    = "SCP-ProtectSecurityServices-Guardrail"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "ProtectSecurity", Effect = "Deny", Resource = "*",
      Action = [
        "cloudtrail:StopLogging", "cloudtrail:DeleteTrail",
        "config:StopConfigurationRecorder", "config:DeleteConfigurationRecorder",
        "config:DeleteConfigRule", "guardduty:DeleteDetector",
        "guardduty:DisassociateFromMasterAccount"
      ]
    }]
  })
}

# 5) Require encryption — deny creating unencrypted EBS volumes (example).
resource "aws_organizations_policy" "require_encryption" {
  name    = "SCP-RequireEncryption-Guardrail"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "RequireEbsEncryption", Effect = "Deny",
      Action = ["ec2:CreateVolume"], Resource = "*",
      Condition = { Bool = { "ec2:Encrypted" = "false" } }
    }]
  })
}

# Attach all five SCPs to the PILOT OUs only (validate before extending to prod).
locals {
  scp_ids = [
    aws_organizations_policy.deny_leave_org.id,
    aws_organizations_policy.deny_root.id,
    aws_organizations_policy.region_lockdown.id,
    aws_organizations_policy.protect_security.id,
    aws_organizations_policy.require_encryption.id,
  ]
  scp_attachments = { for pair in setproduct(local.scp_ids, local.pilot_ou_ids) :
    "${pair[0]}:${pair[1]}" => { policy_id = pair[0], target_id = pair[1] } }
}

resource "aws_organizations_policy_attachment" "pilot" {
  for_each  = local.scp_attachments
  policy_id = each.value.policy_id
  target_id = each.value.target_id
}

###############################################################################
# Outputs
###############################################################################

output "ou_ids" {
  value = {
    Security          = aws_organizations_organizational_unit.security.id
    Infrastructure    = aws_organizations_organizational_unit.infrastructure.id
    WorkloadsProd     = aws_organizations_organizational_unit.workloads_prod.id
    WorkloadsNonProd  = aws_organizations_organizational_unit.workloads_nonprod.id
    Sandbox           = aws_organizations_organizational_unit.sandbox.id
  }
}

output "log_archive_bucket" { value = aws_s3_bucket.log_archive.id }
output "org_trail_name"     { value = aws_cloudtrail.org.name }
output "scp_names" {
  value = [
    aws_organizations_policy.deny_leave_org.name,
    aws_organizations_policy.deny_root.name,
    aws_organizations_policy.region_lockdown.name,
    aws_organizations_policy.protect_security.name,
    aws_organizations_policy.require_encryption.name,
  ]
}
