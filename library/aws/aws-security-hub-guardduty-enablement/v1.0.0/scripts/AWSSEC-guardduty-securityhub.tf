# =============================================================================
# AWSSEC-guardduty-securityhub.tf — Terraform (AWS provider) for org-wide
#   GuardDuty + Security Hub enablement via the delegated administrator.
#
# PURPOSE
#   Declares, as code: the GuardDuty organization configuration with auto-enable,
#   Security Hub with auto-enable, the CIS AWS Foundations and AWS FSBP standards,
#   and the finding aggregator pointing at your aggregation Region. Run from the
#   delegated-admin (Security) account.
#
# HOW TO RUN (PLAN-FIRST, always)
#   1. Configure the AWS provider to ASSUME your least-privilege role in the
#      Security (delegated-admin) account, plus a remote backend (S3 + lock).
#   2. terraform init
#   3. terraform plan   -var-file=pilot.tfvars    # REVIEW; pilot scope first
#   4. terraform apply  -var-file=pilot.tfvars    # after approval
#      (Org-wide auto-enable + more Regions in a later var-file, per Expand wave.)
#
# EXPECTED RESULTS
#   GuardDuty detector + org auto-enable, Security Hub enabled with CIS + FSBP,
#   and a finding aggregator linking the in-scope Regions.
#
# NOTES
#   White-label. Plan-first / pilot-first. Standard ARNs, control availability,
#   protection plans, and pricing change and vary by Region/partition — VERIFY
#   current values before enabling at scale. The automated-response path is in a
#   SEPARATE, gated file: AWSSEC-response.tf.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # verify current provider version
      configuration_aliases = [aws.agg]
    }
  }
  # backend "s3" { ... }   # configure remote state (Global Requirements G5)
}

variable "assume_role_arn"    { type = string, description = "Least-privilege role in the Security (delegated-admin) account." }
variable "aggregation_region" { type = string }
variable "auto_enable_org"    { type = bool,   default = false, description = "Pilot=false; set true org-wide in Expand." }

# Enable CIS AWS Foundations + AWS FSBP. Verify current standard ARNs per region.
variable "enable_cis"  { type = bool, default = true }
variable "enable_fsbp" { type = bool, default = true }

provider "aws" {
  alias  = "agg"
  region = var.aggregation_region
  assume_role { role_arn = var.assume_role_arn }
}

data "aws_region" "agg" { provider = aws.agg }
data "aws_partition" "current" {}

# --- GuardDuty --------------------------------------------------------------
resource "aws_guardduty_detector" "this" {
  provider = aws.agg
  enable   = true
  # Add datasources / feature blocks (S3, EKS, Malware, etc.) per your R6 selection.
}

resource "aws_guardduty_organization_configuration" "this" {
  provider    = aws.agg
  detector_id = aws_guardduty_detector.this.id
  # Pilot: NEW-only or none; Expand: ALL. Controlled by auto_enable_org.
  auto_enable_organization_members = var.auto_enable_org ? "ALL" : "NEW"
}

# --- Security Hub -----------------------------------------------------------
resource "aws_securityhub_account" "this" {
  provider = aws.agg
}

resource "aws_securityhub_organization_configuration" "this" {
  provider    = aws.agg
  auto_enable = var.auto_enable_org
  depends_on  = [aws_securityhub_account.this]
}

# Finding aggregator — one Region collects all findings (link all Regions).
resource "aws_securityhub_finding_aggregator" "this" {
  provider     = aws.agg
  linking_mode = "ALL_REGIONS"
  depends_on   = [aws_securityhub_account.this]
}

# Standards. ARNs are region-scoped; verify current ARNs for your region/partition.
resource "aws_securityhub_standards_subscription" "cis" {
  count         = var.enable_cis ? 1 : 0
  provider      = aws.agg
  standards_arn = "arn:${data.aws_partition.current.partition}:securityhub:${data.aws_region.agg.name}::standards/cis-aws-foundations-benchmark/v/1.4.0"
  depends_on    = [aws_securityhub_account.this]
}

resource "aws_securityhub_standards_subscription" "fsbp" {
  count         = var.enable_fsbp ? 1 : 0
  provider      = aws.agg
  standards_arn = "arn:${data.aws_partition.current.partition}:securityhub:${data.aws_region.agg.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.this]
}

output "guardduty_detector_id"  { value = aws_guardduty_detector.this.id }
output "aggregation_region"     { value = var.aggregation_region }
output "org_auto_enable"        { value = var.auto_enable_org }
