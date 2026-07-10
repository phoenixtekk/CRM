#!/usr/bin/env bash
# =============================================================================
# AWSSEC-Validate.sh — read-only validation that GuardDuty + Security Hub are
#                      correctly enabled with the standards and aggregation on.
#
# PURPOSE
#   Confirms the enablement is healthy in a given region: a GuardDuty detector
#   is enabled with org auto-enable, Security Hub is enabled, the CIS AWS
#   Foundations and AWS FSBP standards are on, and a finding aggregator exists.
#   Prints PASS/WARN per check. Read-only — changes nothing. Run in the pilot
#   region during Validate, and after each Expand wave.
#
# HOW TO RUN
#   Authenticate as your least-privilege role, then:
#     ./AWSSEC-Validate.sh us-east-1
#   Requires: AWS CLI v2, jq. Rights: read on guardduty, securityhub.
#
# EXPECTED RESULTS
#   A checklist:
#     [PASS] GuardDuty detector enabled
#     [PASS] Org auto-enable on
#     [PASS] Security Hub enabled
#     [PASS] CIS AWS Foundations standard enabled
#     [PASS] AWS FSBP standard enabled
#     [PASS] Finding aggregator configured
#   WARN items point to the matching Troubleshooting entry.
#
# NOTES
#   White-label. Read-only. Verify current standard ARNs/availability per
#   region/partition.
# =============================================================================
set -euo pipefail

REGION="${1:-$(aws configure get region)}"
check() { local ok="$1"; shift; if [[ "$ok" == "1" ]]; then echo "[PASS] $*"; else echo "[WARN] $*"; fi; }

command -v aws >/dev/null || { echo "ERROR: AWS CLI v2 not found." >&2; exit 1; }
command -v jq  >/dev/null || { echo "ERROR: jq not found." >&2; exit 1; }

echo "=== AWSSEC validation — region $REGION — $(date -u +%FT%TZ) ==="

# GuardDuty detector
DET="$(aws guardduty list-detectors --region "$REGION" --query 'DetectorIds[0]' --output text 2>/dev/null || echo 'None')"
if [[ "$DET" == "None" || -z "$DET" ]]; then
  check 0 "GuardDuty detector present (none found — Troubleshooting T1)."
else
  STATUS="$(aws guardduty get-detector --region "$REGION" --detector-id "$DET" --query 'Status' --output text)"
  [[ "$STATUS" == "ENABLED" ]] && check 1 "GuardDuty detector enabled ($DET)" || check 0 "GuardDuty detector status=$STATUS (T1)"
  AE="$(aws guardduty describe-organization-configuration --region "$REGION" --detector-id "$DET" --query 'AutoEnableOrganizationMembers' --output text 2>/dev/null || echo 'NONE')"
  [[ "$AE" == "ALL" || "$AE" == "NEW" ]] && check 1 "GuardDuty org auto-enable = $AE" || check 0 "GuardDuty org auto-enable = $AE (expected ALL/NEW — T1)"
fi

# Security Hub
if aws securityhub describe-hub --region "$REGION" >/dev/null 2>&1; then
  check 1 "Security Hub enabled"
  STDS="$(aws securityhub get-enabled-standards --region "$REGION" --query 'StandardsSubscriptions[].StandardsArn' --output text 2>/dev/null || echo '')"
  echo "$STDS" | grep -qi 'cis-aws-foundations' && check 1 "CIS AWS Foundations standard enabled" || check 0 "CIS AWS Foundations standard NOT enabled (T2)"
  echo "$STDS" | grep -qi 'aws-foundational-security-best-practices' && check 1 "AWS FSBP standard enabled" || check 0 "AWS FSBP standard NOT enabled (T2)"
  AGG="$(aws securityhub list-finding-aggregators --region "$REGION" --query 'FindingAggregators[0].FindingAggregatorArn' --output text 2>/dev/null || echo 'None')"
  [[ "$AGG" != "None" && -n "$AGG" ]] && check 1 "Finding aggregator configured" || check 0 "No finding aggregator (T4)"
else
  check 0 "Security Hub enabled (not enabled in $REGION — T2)"
fi

echo ""
echo "Validation complete for $REGION. Resolve any [WARN] before expanding."
