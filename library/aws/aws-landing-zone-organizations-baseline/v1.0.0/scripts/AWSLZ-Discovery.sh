#!/usr/bin/env bash
###############################################################################
# AWSLZ-Discovery.sh — inventory current AWS Organizations / landing-zone state (read-only).
#
# PURPOSE
#   Discovers the starting reality before any change: the org feature set,
#   existing OUs and accounts (and their placement), existing SCPs, whether an
#   organization CloudTrail and AWS Config exist, and whether a Log-Archive
#   account is present. Read-only — it only calls describe/list APIs.
#
# HOW TO RUN
#   ./AWSLZ-Discovery.sh
#   Prereqs: AWS CLI v2, authenticated as an ASSUMED ROLE (never root) with org
#   read access. GovCloud: export AWS_REGION / partition endpoints accordingly.
#
# EXPECTED RESULTS
#   Printed sections for org feature set, OUs, accounts, SCPs, CloudTrail, and
#   Config. PASS = caller identity resolves and the inventory completes.
#
# NOTES
#   White-label. Read-only. No credentials in script. VERIFY feature availability
#   for your partition.
###############################################################################
set -euo pipefail

section() { printf '\n=== %s ===\n' "$1"; }

section "Caller identity (must be an assumed role, NOT root)"
aws sts get-caller-identity --output table || { echo "Cannot resolve identity — authenticate first."; exit 1; }

section "Organization feature set (expect ALL for SCPs — R1)"
aws organizations describe-organization \
  --query 'Organization.{Id:Id,FeatureSet:FeatureSet,MasterEmail:MasterAccountEmail}' \
  --output table 2>/dev/null || echo "Organizations not enabled / no access — enable ALL features (R1)."

section "Organizational Units (top level)"
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text 2>/dev/null || echo "")
if [[ -n "${ROOT_ID}" && "${ROOT_ID}" != "None" ]]; then
  aws organizations list-organizational-units-for-parent --parent-id "${ROOT_ID}" \
    --query 'OrganizationalUnits[].{Name:Name,Id:Id}' --output table || true
else
  echo "No org root readable."
fi

section "Accounts in the organization"
aws organizations list-accounts \
  --query 'Accounts[].{Name:Name,Id:Id,Status:Status,Email:Email}' --output table 2>/dev/null || true
echo "Look for a Log-Archive and a Security-Tooling account (R3)."

section "Service Control Policies (existing)"
aws organizations list-policies --filter SERVICE_CONTROL_POLICY \
  --query 'Policies[].{Name:Name,Id:Id,AwsManaged:AwsManaged}' --output table 2>/dev/null \
  || echo "Cannot list SCPs — confirm ALL-features + permissions."

section "Organization CloudTrail (expect Trail-Org-CloudTrail after build)"
aws cloudtrail describe-trails \
  --query 'trailList[].{Name:Name,IsOrgTrail:IsOrganizationTrail,MultiRegion:IsMultiRegionTrail,S3:S3BucketName}' \
  --output table 2>/dev/null || echo "No trails readable."

section "AWS Config recorders (current account)"
aws configservice describe-configuration-recorders \
  --query 'ConfigurationRecorders[].{Name:name,RoleARN:roleARN}' --output table 2>/dev/null \
  || echo "No Config recorder in this account/region."

section "Discovery complete"
echo "Next: review 03-implementation.md, set main.tf variables, then ./AWSLZ-Deploy.sh plan"
