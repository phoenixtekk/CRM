#!/usr/bin/env bash
# =============================================================================
# AWSSSO-Report.sh — read-only report of the group -> permission set -> account
#                    assignment matrix in IAM Identity Center.
#
# PURPOSE
#   Produces the authoritative view of who can reach what: every account
#   assignment, resolved to (Entra-provisioned group) -> (permission set) ->
#   (AWS account). Compare this matrix against the R6 entitlement decision so
#   no account/role is granted that the entitlement policy does not list.
#   Read-only — creates and changes nothing.
#
# HOW TO RUN
#   Authenticate as your least-privilege role (never root), then:
#     ./AWSSSO-Report.sh
#   Requires: AWS CLI v2, jq. Rights: read on sso-admin, identitystore,
#   organizations.
#
# EXPECTED RESULTS
#   A printed and saved matrix, one row per assignment:
#     ACCOUNT_ID | ACCOUNT_NAME | PERMISSION_SET | PRINCIPAL_TYPE | PRINCIPAL
#   Run after each Expand wave (Testing Gate 7) to confirm intent.
#
# NOTES
#   White-label. Read-only. Safe to run repeatedly.
# =============================================================================
set -euo pipefail

OUT="AWSSSO-Report-$(date +%Y%m%d-%H%M%S).txt"
log() { echo "$@" | tee -a "$OUT"; }

command -v aws >/dev/null || { echo "ERROR: AWS CLI v2 not found." >&2; exit 1; }
command -v jq  >/dev/null || { echo "ERROR: jq not found." >&2; exit 1; }

INSTANCE_ARN="$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text)"
ID_STORE="$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)"
[[ "$INSTANCE_ARN" == "None" || -z "$INSTANCE_ARN" ]] && { echo "IAM Identity Center not enabled." >&2; exit 1; }

log "=== AWSSSO Assignment Matrix — $(date -u +%FT%TZ) ==="
log "Instance: $INSTANCE_ARN"
printf '%-14s | %-22s | %-32s | %-9s | %s\n' "ACCOUNT_ID" "ACCOUNT_NAME" "PERMISSION_SET" "TYPE" "PRINCIPAL" | tee -a "$OUT"
log "$(printf '%.0s-' {1..110})"

# Resolve account names once
declare -A ACC_NAME
while read -r id name; do ACC_NAME["$id"]="$name"; done < <(aws organizations list-accounts --query 'Accounts[].[Id,Name]' --output text 2>/dev/null || true)

resolve_principal() {
  local ptype="$1" pid="$2"
  if [[ "$ptype" == "GROUP" ]]; then
    aws identitystore describe-group --identity-store-id "$ID_STORE" --group-id "$pid" --query 'DisplayName' --output text 2>/dev/null || echo "$pid"
  else
    aws identitystore describe-user --identity-store-id "$ID_STORE" --user-id "$pid" --query 'UserName' --output text 2>/dev/null || echo "$pid"
  fi
}

for PS_ARN in $(aws sso-admin list-permission-sets --instance-arn "$INSTANCE_ARN" --query 'PermissionSets[]' --output text); do
  PS_NAME="$(aws sso-admin describe-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$PS_ARN" --query 'PermissionSet.Name' --output text)"
  for ACC in $(aws sso-admin list-accounts-for-provisioned-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$PS_ARN" --query 'AccountIds[]' --output text 2>/dev/null || true); do
    aws sso-admin list-account-assignments --instance-arn "$INSTANCE_ARN" --account-id "$ACC" --permission-set-arn "$PS_ARN" --query 'AccountAssignments[].[PrincipalType,PrincipalId]' --output text 2>/dev/null | \
    while read -r PTYPE PID; do
      [[ -z "${PTYPE:-}" ]] && continue
      PRIN="$(resolve_principal "$PTYPE" "$PID")"
      printf '%-14s | %-22s | %-32s | %-9s | %s\n' "$ACC" "${ACC_NAME[$ACC]:-?}" "$PS_NAME" "$PTYPE" "$PRIN" | tee -a "$OUT"
    done
  done
done

log ""
log "Report written to: $OUT"
log "Compare against the R6 entitlement matrix (Testing Gate 7)."
