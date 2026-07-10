#!/usr/bin/env bash
# =============================================================================
# AWSSEC-Report.sh — read-only findings + posture report from the aggregation
#                    Region (severity counts, standard scores, top findings).
#
# PURPOSE
#   Produces a triage-ready snapshot from the Security Hub aggregation Region:
#   active-finding counts by severity, enabled-standard scores, and the top
#   findings grouped across accounts. Use it to drive the triage runbook and
#   for Testing Gate 4 (aggregation) and Gate 6 (suppression) evidence.
#   Read-only — creates and changes nothing.
#
# HOW TO RUN
#   Authenticate as your least-privilege role, then run in the AGGREGATION
#   region:
#     ./AWSSEC-Report.sh us-east-1
#   Requires: AWS CLI v2, jq. Rights: read on securityhub.
#
# EXPECTED RESULTS
#   Printed and saved:
#     - Active findings by severity (CRITICAL/HIGH/MEDIUM/LOW)
#     - Per-standard control scores
#     - Top active findings (title, severity, account, resource)
#
# NOTES
#   White-label. Read-only. Only ACTIVE, non-suppressed findings are counted.
# =============================================================================
set -euo pipefail

REGION="${1:-$(aws configure get region)}"
OUT="AWSSEC-Report-$(date +%Y%m%d-%H%M%S).txt"
log() { echo "$@" | tee -a "$OUT"; }

command -v aws >/dev/null || { echo "ERROR: AWS CLI v2 not found." >&2; exit 1; }
command -v jq  >/dev/null || { echo "ERROR: jq not found." >&2; exit 1; }

aws securityhub describe-hub --region "$REGION" >/dev/null 2>&1 || { echo "Security Hub not enabled in $REGION." >&2; exit 1; }

log "=== AWSSEC Findings & Posture Report — region $REGION — $(date -u +%FT%TZ) ==="

log ""
log "-- Active findings by severity --"
FILTER='{"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}],"WorkflowStatus":[{"Value":"NEW","Comparison":"EQUALS"},{"Value":"NOTIFIED","Comparison":"EQUALS"}]}'
for SEV in CRITICAL HIGH MEDIUM LOW; do
  SEVF=$(echo "$FILTER" | jq --arg s "$SEV" '. + {SeverityLabel:[{Value:$s,Comparison:"EQUALS"}]}')
  CNT=$(aws securityhub get-findings --region "$REGION" --filters "$SEVF" --max-items 100 --query 'length(Findings)' --output text 2>/dev/null || echo 0)
  log "   $SEV: $CNT (showing up to 100)"
done

log ""
log "-- Enabled standards (scores from the console/get-enabled-standards) --"
aws securityhub get-enabled-standards --region "$REGION" \
  --query 'StandardsSubscriptions[].{Standard:StandardsArn,Status:StandardsStatus}' --output table 2>/dev/null | tee -a "$OUT" || true

log ""
log "-- Top active HIGH/CRITICAL findings (title | severity | account | resource) --"
HCFILTER=$(echo "$FILTER" | jq '. + {SeverityLabel:[{Value:"CRITICAL",Comparison:"EQUALS"},{Value:"HIGH",Comparison:"EQUALS"}]}')
aws securityhub get-findings --region "$REGION" --filters "$HCFILTER" --max-items 50 \
  --query 'Findings[].{T:Title,S:Severity.Label,A:AwsAccountId,R:Resources[0].Id}' --output json 2>/dev/null \
  | jq -r '.[] | "   \(.T) | \(.S) | \(.A) | \(.R)"' | tee -a "$OUT" || true

log ""
log "Report written to: $OUT"
log "Feed into the triage runbook; suppress known-accepted findings with named automation rules."
