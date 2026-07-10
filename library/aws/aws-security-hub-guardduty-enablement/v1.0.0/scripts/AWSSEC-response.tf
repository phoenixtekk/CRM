# =============================================================================
# AWSSEC-response.tf — Terraform (AWS provider) for the GATED automated-response
#   path: high-severity Security Hub findings -> EventBridge -> SNS (-> Lambda).
#
# PURPOSE
#   Declares the response scaffolding as code, but SHIPS DISABLED. Two gates
#   control it:
#     enable_response    (default false) — turns the EventBridge rule ON so
#                                          high/critical findings NOTIFY via SNS.
#     enable_auto_action (default false) — additionally routes to a Lambda that
#                                          performs an approved automated action.
#   Pilot: keep both false (rule created but DISABLED). Validate notification by
#   setting only enable_response=true. Activate automated action (per finding
#   type, after approval) with enable_auto_action=true — NEVER on first rollout.
#
# HOW TO RUN (PLAN-FIRST, always)
#   1. Configure the AWS provider to ASSUME your least-privilege role in the
#      Security account; use remote state.
#   2. terraform init
#   3. terraform plan   -var-file=pilot.tfvars    # both gates false = disabled
#   4. terraform apply  -var-file=pilot.tfvars
#      Later: -var 'enable_response=true'  (notify-only, validate)
#             -var 'enable_auto_action=true' (per approved finding type ONLY)
#
# EXPECTED RESULTS
#   SNS topic + subscription, an EventBridge rule (DISABLED unless
#   enable_response), and an optional Lambda (created only if enable_auto_action).
#
# NOTES
#   White-label. GATED and disabled by default. Whether automated remediation
#   may act on production is the customer's operational/change decision. Keep the
#   Lambda least-privilege and fully logged. Verify current finding schema/fields.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" } # verify current version
  }
  # backend "s3" { ... }
}

variable "assume_role_arn"    { type = string }
variable "aws_region"         { type = string }
variable "notify_email"       { type = string, description = "R7 notification endpoint (must confirm the SNS subscription email)." }

# --- GATES (both default OFF) ----------------------------------------------
variable "enable_response"    { type = bool, default = false, description = "true = EventBridge rule ENABLED (notify via SNS)." }
variable "enable_auto_action" { type = bool, default = false, description = "true = also route to the Lambda automated action. Per approved finding type ONLY." }

# Only high/critical findings trigger the path.
variable "severity_labels"    { type = list(string), default = ["CRITICAL", "HIGH"] }

provider "aws" {
  region = var.aws_region
  assume_role { role_arn = var.assume_role_arn }
}

# --- SNS notification target: SecFindings-Notify – Org – Prod ----------------
resource "aws_sns_topic" "notify" {
  name = "SecFindings-Notify-Org-Prod"
}
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notify.arn
  protocol  = "email"
  endpoint  = var.notify_email
}

# --- EventBridge rule: SecFindings-HighSeverity – Org – Response -------------
# Created but DISABLED unless enable_response = true.
resource "aws_cloudwatch_event_rule" "high_sev" {
  name        = "SecFindings-HighSeverity-Org-Response"
  description = "High/critical Security Hub findings -> notify (and optional gated action)."
  state       = var.enable_response ? "ENABLED" : "DISABLED"
  event_pattern = jsonencode({
    source        = ["aws.securityhub"]
    "detail-type" = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = { Label = var.severity_labels }
        RecordState = ["ACTIVE"]
      }
    }
  })
}

# Always target SNS (notify).
resource "aws_cloudwatch_event_target" "to_sns" {
  rule      = aws_cloudwatch_event_rule.high_sev.name
  target_id = "notify-sns"
  arn       = aws_sns_topic.notify.arn
}
resource "aws_sns_topic_policy" "allow_events" {
  arn = aws_sns_topic.notify.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "SNS:Publish"
      Resource  = aws_sns_topic.notify.arn
    }]
  })
}

# --- Optional Lambda automated action: SecFindings-AutoRespond – Org – Gated -
# Created ONLY when enable_auto_action = true.
data "aws_iam_policy_document" "lambda_assume" {
  count = var.enable_auto_action ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service", identifiers = ["lambda.amazonaws.com"] }
  }
}
resource "aws_iam_role" "auto_respond" {
  count              = var.enable_auto_action ? 1 : 0
  name               = "SecFindings-AutoRespond-Org-Gated"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume[0].json
  # Attach a LEAST-PRIVILEGE policy scoped to the specific approved action only.
}
resource "aws_lambda_function" "auto_respond" {
  count         = var.enable_auto_action ? 1 : 0
  function_name = "SecFindings-AutoRespond-Org-Gated"
  role          = aws_iam_role.auto_respond[0].arn
  runtime       = "python3.12" # verify current supported runtime
  handler       = "handler.main"
  filename      = "auto_respond.zip" # supply your reviewed, least-privilege action code
  # source_code_hash = filebase64sha256("auto_respond.zip")
  timeout       = 30
}
resource "aws_cloudwatch_event_target" "to_lambda" {
  count     = var.enable_auto_action ? 1 : 0
  rule      = aws_cloudwatch_event_rule.high_sev.name
  target_id = "auto-respond-lambda"
  arn       = aws_lambda_function.auto_respond[0].arn
}
resource "aws_lambda_permission" "allow_events" {
  count         = var.enable_auto_action ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_respond[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.high_sev.arn
}

output "response_enabled"    { value = var.enable_response }
output "auto_action_enabled" { value = var.enable_auto_action }
output "sns_topic_arn"       { value = aws_sns_topic.notify.arn }
