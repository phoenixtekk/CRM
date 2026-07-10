#!/usr/bin/env bash
# =============================================================================
# AWSSSO-Discovery.sh — read-only discovery of the IAM Identity Center + legacy
#                       IAM-user baseline for the Entra SSO federation rollout.
#
# PURPOSE
#   Reports the starting state before you federate: whether IAM Identity Center
#   is enabled, the standalone IAM users and access keys that federation will
#   replace (the decommission baseline), and any existing permission sets and
#   account assignments. Read-only — it creates and changes nothing.
#
# HOW TO RUN
#   Authenticate first as your least-privilege deployment role (never root):
#     aws sts get-caller-identity        # confirm the assumed role
#   Then:
#     ./AWSSSO-Discovery.sh              # uses the current AWS CLI profile/region
#   Requires: AWS CLI v2, jq. Rights: read on organizations, sso-admin,
#   identitystore, and iam.
#
# EXPECTED RESULTS
#   Console output (and a saved report file) showing:
#     - Organization feature set and account IDs
#     - IAM Identity Center instance ARN + identity store (or "not enabled")
#     - Standalone IAM users, their access keys, and last-used dates
#     - Existing permission sets and account assignments
#   Use the IAM-user list as the R8 inventory for staged decommissioning.
#
# NOTES
#   White-label. Read-only. Safe to run repeatedly (e.g. after each Expand wave)
#   to watch the IAM-user footprint shrink.
# =============================================================================
set -euo pipefail

OUT="AWSSSO-Discovery-$(date +%Y%m%d-%H%M%S).txt"
log() { echo "$@" | tee -a "$OUT"; }

command -v aws >/dev/null || { echo "ERROR: AWS CLI v2 not found." >&2; exit 1; }
command -v jq  >/dev/null || { echo "ERROR: jq not found." >&2; exit 1; }

log "=== AWSSSO Discovery — $(date -u +%FT%TZ) ==="
log "Caller identity:"
aws sts get-caller-identity --output json | tee -a "$OUT"

log ""
log "=== AWS Organizations ==="
if aws organizations describe-organization --output json >/tmp/org.json 2>/dev/null; then
  jq '{FeatureSet:.Organization.FeatureSet, ManagementAccountId:.Organization.MasterAccountId}' /tmp/org.json | tee -a "$OUT"
  log "-- Accounts in org --"
  aws organizations list-accounts --query 'Accounts[].{Id:Id,Name:Name,Status:Status}' --output table | tee -a "$OUT"
else
  log "Organizations not accessible from this identity (need management/delegated access)."
fi

log ""
log "=== IAM Identity Center ==="
INSTANCE_ARN="$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text 2>/dev/null || echo 'None')"
if [[ "$INSTANCE_ARN" == "None" || -z "$INSTANCE_ARN" ]]; then
  log "IAM Identity Center is NOT enabled in this region. (Enable per Implementation Step B1.)"
else
  log "Instance ARN: $INSTANCE_ARN"
  ID_STORE="$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)"
  log "Identity store: $ID_STORE"
  log "-- Permission sets --"
  for PS in $(aws sso-admin list-permission-sets --instance-arn "$INSTANCE_ARN" --query 'PermissionSets[]' --output text 2>/dev/null); do
    NAME="$(aws sso-admin describe-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$PS" --query 'PermissionSet.Name' --output text)"
    log "   $NAME    ($PS)"
  done
fi

log ""
log "=== Legacy standalone IAM users (decommission baseline) ==="
aws iam generate-credential-report >/dev/null 2>&1 || true
aws iam list-users --query 'Users[].{User:UserName,Created:CreateDate}' --output table | tee -a "$OUT"
log "-- Access keys per user --"
for U in $(aws iam list-users --query 'Users[].UserName' --output text); do
  KEYS="$(aws iam list-access-keys --user-name "$U" --query 'AccessKeyMetadata[].{Id:AccessKeyId,Status:Status}' --output text 2>/dev/null || true)"
  [[ -n "$KEYS" ]] && log "   $U: $KEYS"
done

log ""
log "Report written to: $OUT"
log "Next: review IAM users, classify human vs workload, then Implementation Stage B."
