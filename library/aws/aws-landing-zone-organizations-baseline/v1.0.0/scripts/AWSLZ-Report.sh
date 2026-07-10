#!/usr/bin/env bash
###############################################################################
# AWSLZ-Report.sh — posture report: accounts by OU, SCP attachments, logging, baseline (read-only).
#
# PURPOSE
#   Produces a governance-facing snapshot of the landing zone: accounts grouped
#   by OU, which SCP guardrails are attached where, the org CloudTrail / Config
#   status, and a quick account-baseline signal (password policy present). Feeds
#   the review before Expand. Read-only — reporting only.
#
# HOW TO RUN
#   ./AWSLZ-Report.sh                 # print to console
#   ./AWSLZ-Report.sh > lz-report.txt # capture for the review record
#   Prereqs: AWS CLI v2, authenticated as an assumed role with org read access.
#
# EXPECTED RESULTS
#   Sections: OUs + accounts, SCP attachments per OU, logging status, and a
#   password-policy check for the current account. Read-only.
#
# NOTES
#   White-label. Read-only. No credentials in script. Some per-account baseline
#   checks require running from / assuming into each account — VERIFY scope.
###############################################################################
set -uo pipefail

section() { printf '\n=== %s ===\n' "$1"; }
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text 2>/dev/null || echo "")

section "Accounts grouped by Organizational Unit"
if [[ -n "${ROOT_ID}" && "${ROOT_ID}" != "None" ]]; then
  for OU in $(aws organizations list-organizational-units-for-parent --parent-id "${ROOT_ID}" --query 'OrganizationalUnits[].Id' --output text 2>/dev/null); do
    NAME=$(aws organizations describe-organizational-unit --organizational-unit-id "${OU}" --query 'OrganizationalUnit.Name' --output text 2>/dev/null)
    printf '\nOU: %s (%s)\n' "${NAME}" "${OU}"
    aws organizations list-accounts-for-parent --parent-id "${OU}" \
      --query 'Accounts[].{Name:Name,Id:Id,Status:Status}' --output table 2>/dev/null || echo "  (no accounts / no access)"
  done
else
  echo "No org root readable."
fi

section "SCP guardrail attachments per OU"
if [[ -n "${ROOT_ID}" && "${ROOT_ID}" != "None" ]]; then
  for OU in $(aws organizations list-organizational-units-for-parent --parent-id "${ROOT_ID}" --query 'OrganizationalUnits[].Id' --output text 2>/dev/null); do
    NAME=$(aws organizations describe-organizational-unit --organizational-unit-id "${OU}" --query 'OrganizationalUnit.Name' --output text 2>/dev/null)
    ATT=$(aws organizations list-policies-for-target --target-id "${OU}" --filter SERVICE_CONTROL_POLICY --query 'Policies[].Name' --output text 2>/dev/null || echo "")
    printf '  %-20s : %s\n' "${NAME}" "${ATT:-<none>}"
  done
fi

section "Central logging status"
aws cloudtrail describe-trails \
  --query "trailList[?Name=='Trail-Org-CloudTrail'].{Name:Name,IsOrgTrail:IsOrganizationTrail,MultiRegion:IsMultiRegionTrail,S3:S3BucketName,KMS:KmsKeyId}" \
  --output table 2>/dev/null || echo "  Org trail not readable."
aws configservice describe-configuration-aggregators \
  --query "ConfigurationAggregators[?ConfigurationAggregatorName=='Config-Org-Aggregator'].ConfigurationAggregatorName" \
  --output text 2>/dev/null || echo "  Config aggregator not readable from here."

section "Account baseline signal (current account)"
if aws iam get-account-password-policy >/dev/null 2>&1; then
  echo "  IAM password policy: PRESENT"
else
  echo "  IAM password policy: MISSING — apply the account baseline."
fi
echo "  (Per-account baseline — default encryption, no root keys — check within each account; VERIFY scope.)"

section "Report complete"
echo "Review with cloud governance. Note: CloudTrail/Config/KMS/S3 are billable — verify current pricing."
