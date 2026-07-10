#!/usr/bin/env bash
# =============================================================================
# AWSSEC-Discovery.sh — read-only baseline of GuardDuty + Security Hub state
#                       across accounts and regions (the R8 baseline).
#
# PURPOSE
#   Reports the starting point before you enable org-wide: whether a GuardDuty
#   detector exists per region, whether Security Hub is enabled, which standards
#   are on, and the current delegated-administrator registrations. Read-only —
#   it creates and changes nothing. Reconcile any pre-existing detectors/hubs
#   into the delegated-admin model before org-wide apply.
#
# HOW TO RUN
#   Authenticate first as your least-privilege role (never root):
#     aws sts get-caller-identity
#   Then (optionally pass a space-separated region list; defaults to the CLI region):
#     ./AWSSEC-Discovery.sh "us-east-1 us-west-2 eu-west-1"
#   Requires: AWS CLI v2, jq. Rights: read on guardduty, securityhub,
#   organizations.
#
# EXPECTED RESULTS
#   A printed and saved report per region: detector id + status, Security Hub
#   enablement, enabled standards, and delegated-admin accounts.
#
# NOTES
#   White-label. Read-only. Safe to run repeatedly (e.g. after each Expand wave).
#   Verify current standards/finding-types availability per region/partition.
# =============================================================================
set -euo pipefail

REGIONS="${1:-$(aws configure get region)}"
OUT="AWSSEC-Discovery-$(date +%Y%m%d-%H%M%S).txt"
log() { echo "$@" | tee -a "$OUT"; }

command -v aws >/dev/null || { echo "ERROR: AWS CLI v2 not found." >&2; exit 1; }
command -v jq  >/dev/null || { echo "ERROR: jq not found." >&2; exit 1; }

log "=== AWSSEC Discovery — $(date -u +%FT%TZ) ==="
aws sts get-caller-identity --output json | tee -a "$OUT"

log ""
log "=== Delegated administrators (management-account view) ==="
aws organizations list-delegated-administrators --query 'DelegatedAdministrators[].{Id:Id,Name:Name}' --output table 2>/dev/null | tee -a "$OUT" \
  || log "Organizations delegated-admin list not accessible from this identity."

for R in $REGIONS; do
  log ""
  log "=== Region: $R ==="

  log "-- GuardDuty --"
  DET="$(aws guardduty list-detectors --region "$R" --query 'DetectorIds[0]' --output text 2>/dev/null || echo 'None')"
  if [[ "$DET" == "None" || -z "$DET" ]]; then
    log "   GuardDuty: NO detector in $R."
  else
    STATUS="$(aws guardduty get-detector --region "$R" --detector-id "$DET" --query 'Status' --output text 2>/dev/null || echo '?')"
    log "   GuardDuty detector: $DET (status: $STATUS)"
    aws guardduty describe-organization-configuration --region "$R" --detector-id "$DET" \
      --query '{AutoEnable:AutoEnable,AutoEnableOrgMembers:AutoEnableOrganizationMembers}' --output json 2>/dev/null | tee -a "$OUT" || true
  fi

  log "-- Security Hub --"
  if aws securityhub describe-hub --region "$R" >/tmp/hub.json 2>/dev/null; then
    log "   Security Hub: ENABLED in $R."
    log "   Enabled standards:"
    aws securityhub get-enabled-standards --region "$R" --query 'StandardsSubscriptions[].{Standard:StandardsArn,Status:StandardsStatus}' --output table 2>/dev/null | tee -a "$OUT" || true
    aws securityhub list-finding-aggregators --region "$R" --query 'FindingAggregators' --output json 2>/dev/null | tee -a "$OUT" || true
  else
    log "   Security Hub: NOT enabled in $R."
  fi
done

log ""
log "Report written to: $OUT"
log "Next: reconcile any pre-existing detectors/hubs, then Implementation Stage B (plan-first)."
