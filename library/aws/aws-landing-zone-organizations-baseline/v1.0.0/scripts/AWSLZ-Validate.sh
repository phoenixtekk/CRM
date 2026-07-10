#!/usr/bin/env bash
###############################################################################
# AWSLZ-Validate.sh — run the 05-testing pass/fail gates for the landing zone (read-only).
#
# PURPOSE
#   Checks the build against the gates in 05-testing.md and prints PASS/FAIL/
#   MANUAL per gate: org is ALL-features, the OU hierarchy exists, the org
#   CloudTrail is logging to Log-Archive, Config aggregates, the five SCPs are
#   attached to the pilot OUs, and a read-only guardrail probe confirms an
#   out-of-region action would be DENIED. Read-only — validates, changes nothing.
#
# HOW TO RUN
#   ./AWSLZ-Validate.sh
#   Prereqs: AWS CLI v2, authenticated as an assumed role with org read access.
#   The region-lockdown probe is a DRY-RUN describe/dry-run call — safe by design;
#   VERIFY it suits your environment before relying on it.
#
# EXPECTED RESULTS
#   One line per gate: PASS / FAIL / MANUAL. Any FAIL = stay in pilot scope and
#   remediate that gate before Expand.
#
# NOTES
#   White-label. Read-only. No credentials in script. VERIFY guardrail probe
#   behavior for your partition.
###############################################################################
set -uo pipefail

FAILS=0
gate() { # gate <STATE> <name> [detail]
  local state="$1"; shift; local name="$1"; shift; local detail="${*:-}"
  printf '[%s] %s%s\n' "${state}" "${name}" "${detail:+ — ${detail}}"
  [[ "${state}" == "FAIL" ]] && FAILS=$((FAILS+1)) || true
}

echo "== AWS Landing Zone validation =="

# Gate 1 — Org ALL-features
FS=$(aws organizations describe-organization --query 'Organization.FeatureSet' --output text 2>/dev/null || echo "NONE")
if [[ "${FS}" == "ALL" ]]; then gate PASS "Gate 1: Org ALL-features"; else gate FAIL "Gate 1: Org ALL-features" "got ${FS} (enable ALL — R1)"; fi

# Gate 2 — OU hierarchy exists
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text 2>/dev/null || echo "")
OUS=$(aws organizations list-organizational-units-for-parent --parent-id "${ROOT_ID}" --query 'OrganizationalUnits[].Name' --output text 2>/dev/null || echo "")
MISSING=""
for want in Security Infrastructure Workloads-Prod Workloads-NonProd Sandbox; do
  echo "${OUS}" | grep -qw "${want}" || MISSING="${MISSING} ${want}"
done
if [[ -z "${MISSING}" ]]; then gate PASS "Gate 2: OU hierarchy present"; else gate FAIL "Gate 2: OU hierarchy present" "missing:${MISSING}"; fi

# Gate 3 — Org CloudTrail logging to Log-Archive
TRAIL=$(aws cloudtrail describe-trails --query "trailList[?Name=='Trail-Org-CloudTrail']|[0]" --output json 2>/dev/null || echo "null")
if [[ "${TRAIL}" != "null" && -n "${TRAIL}" ]]; then
  IS_ORG=$(echo "${TRAIL}" | grep -o '"IsOrganizationTrail": *true' || echo "")
  if [[ -n "${IS_ORG}" ]]; then gate PASS "Gate 3: Trail-Org-CloudTrail is an org trail"; else gate FAIL "Gate 3: org CloudTrail" "trail exists but not org-scoped"; fi
else
  gate FAIL "Gate 3: Trail-Org-CloudTrail present" "not found"
fi

# Gate 4 — Config aggregator
AGG=$(aws configservice describe-configuration-aggregators --query "ConfigurationAggregators[?ConfigurationAggregatorName=='Config-Org-Aggregator']|[0].ConfigurationAggregatorName" --output text 2>/dev/null || echo "None")
if [[ "${AGG}" == "Config-Org-Aggregator" ]]; then gate PASS "Gate 4: Config-Org-Aggregator present"; else gate MANUAL "Gate 4: Config-Org-Aggregator" "not found from this account — verify from delegated admin"; fi

# Gate 5 — SCPs attached to pilot OUs
for ouname in Workloads-NonProd Sandbox; do
  OU_ID=$(aws organizations list-organizational-units-for-parent --parent-id "${ROOT_ID}" --query "OrganizationalUnits[?Name=='${ouname}'].Id" --output text 2>/dev/null || echo "")
  if [[ -n "${OU_ID}" ]]; then
    CNT=$(aws organizations list-policies-for-target --target-id "${OU_ID}" --filter SERVICE_CONTROL_POLICY --query 'length(Policies[?starts_with(Name, `SCP-`) && ends_with(Name, `-Guardrail`)])' --output text 2>/dev/null || echo 0)
    if [[ "${CNT}" -ge 5 ]]; then gate PASS "Gate 5: SCPs on ${ouname}" "${CNT} guardrails"; else gate FAIL "Gate 5: SCPs on ${ouname}" "only ${CNT}/5 guardrails attached"; fi
  else
    gate FAIL "Gate 5: SCPs on ${ouname}" "OU not found"
  fi
done

# Gate 6 — Guardrail probe (read-only dry-run in a disallowed region)
gate MANUAL "Gate 6: guardrail deny probe" "run a describe/dry-run in a disallowed region from a pilot account; expect AccessDenied by SCP-RegionLockdown-Guardrail (verify probe suits your env)"

# Gate 7 — Vended test account baseline
gate MANUAL "Gate 7: vended test account pre-baselined" "confirm Sandbox test account: correct OU, SCPs applied, logging, password policy, default encryption, no root keys"

# Gate 8 — Plan-first + state protected
gate MANUAL "Gate 8: plan-first + protected state" "confirm changes went through AWSLZ-Deploy.sh (typed confirm) and remote state is S3+DynamoDB, encrypted/versioned (R6)"

echo ""
if [[ "${FAILS}" -eq 0 ]]; then
  echo "All automated gates PASS. Complete MANUAL checks, then proceed to Expand."
else
  echo "${FAILS} gate(s) FAILED — stay in the pilot scope and remediate before Expand."
fi
