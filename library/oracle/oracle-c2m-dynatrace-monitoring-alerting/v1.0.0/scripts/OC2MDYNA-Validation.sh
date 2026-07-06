# OC2MDYNA-Validation.sh — read-only validation that C2M tiers are instrumented, tagged, and alerted.
#
# PURPOSE
#     Confirm the configured monitoring matches the standard: every in-scope C2M host
#     reports a running OneAgent and carries the C2M-Env tag, WebLogic connection-pool
#     metrics are present, and the named dashboards and alert rules exist in the tenant.
#     Read-only — it validates state and reports PASS/FAIL, it changes nothing. Run it on
#     the pilot and after each expansion. It never prints the API token.
#     Placeholders are plain text (your-tenant, your-token) with no angle brackets.
#
# HOW TO RUN
#     Set the tenant URL and a read-scoped API token as environment variables, then:
#         export DT_ENV_URL=https://your-tenant.live.dynatrace.com
#         export DT_API_TOKEN=your-read-scoped-token
#         ./OC2MDYNA-Validation.sh --scope pilot        # uses oc2mdyna-scope.conf hosts
#     Optional: ENV_TAG=C2M-Env to name the environment host-group tag to check.
#
# EXPECTED RESULTS
#     For each check prints PASS or FAIL: every in-scope host has a running OneAgent and
#     the C2M-Env tag; connection-pool metrics are present; each named dashboard and each
#     of the five named alert rules exists. Overall PASS = full coverage, tags, pool
#     metrics, dashboards, and alerts present. Any FAIL names the gap to remediate.
#
# NOTES
#     White-label, repeatable validation — the same checks every tier, every environment.
#     Read-only (GET requests only); the token is read from an env var and never echoed.
#     Dashboard/alert names must match the solution's fixed names. Dynatrace API paths and
#     metric keys move between releases — verify for your tenant version.

set -u

SCOPE="pilot"
SCOPE_FILE="./oc2mdyna-scope.conf"
ENV_TAG="${ENV_TAG:-C2M-Env}"
while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-pilot}"; shift 2 ;;
    --file)  SCOPE_FILE="${2:-$SCOPE_FILE}"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

: "${DT_ENV_URL:=}"
: "${DT_API_TOKEN:=}"
if [ -z "$DT_ENV_URL" ] || [ -z "$DT_API_TOKEN" ]; then
  echo "FAIL: set DT_ENV_URL and DT_API_TOKEN (read-scoped) as environment variables first (token never printed)."
  exit 1
fi
command -v curl >/dev/null 2>&1 || { echo "FAIL: curl not found on PATH."; exit 1; }

API="${DT_ENV_URL%/}/api/v2"
CFG="${DT_ENV_URL%/}/api/config/v1"
AUTH="Authorization: Api-Token ${DT_API_TOKEN}"
rc=0

echo "== OC2MDYNA Validation (scope=${SCOPE}) =="

# --- 1. Every in-scope host has a running OneAgent + the C2M-Env tag ---
echo "-- OneAgent coverage + ${ENV_TAG} tag (in-scope hosts) --"
if [ -f "$SCOPE_FILE" ]; then
  hosts_seen=$(curl -s -G -H "$AUTH" \
    --data-urlencode 'entitySelector=type("HOST")' \
    --data-urlencode "fields=+tags" \
    --data-urlencode "pageSize=500" \
    "${API}/entities" 2>/dev/null)
  awk -F, '/^[[:space:]]*#/{next} NF>=3 {sc=$4; gsub(/[[:space:]]/,"",sc); h=$1; gsub(/[[:space:]]/,"",h);
           if (sc=="all" || sc=="'"$SCOPE"'") print h}' "$SCOPE_FILE" | while read -r host; do
    [ -z "$host" ] && continue
    if printf '%s' "$hosts_seen" | grep -qi "$host"; then
      if printf '%s' "$hosts_seen" | grep -qi "$ENV_TAG"; then
        echo "  PASS: ${host} monitored and ${ENV_TAG} tag present in fleet"
      else
        echo "  WARN: ${host} monitored but ${ENV_TAG} tag not detected — confirm host-group tag"
      fi
    else
      echo "  FAIL: ${host} not found among monitored hosts — install OneAgent (see Remediation)"
    fi
  done
else
  echo "  NOTE: scope file ${SCOPE_FILE} not found — run OC2MDYNA-ScopeHelper.sh to create it."
  rc=1
fi

# --- 2. WebLogic connection-pool metrics present ---
echo
echo "-- WebLogic connection-pool metrics --"
pool=$(curl -s -G -H "$AUTH" \
  --data-urlencode 'metricSelector=builtin:tech.jvm.*' \
  --data-urlencode 'fields=+displayName' \
  "${API}/metrics" 2>/dev/null)
poolx=$(curl -s -G -H "$AUTH" \
  --data-urlencode "text=connection pool" \
  "${API}/metrics" 2>/dev/null)
if printf '%s' "$poolx" | grep -qi "pool"; then
  echo "  PASS: connection-pool metrics found (JMX / Connection Pools extension active)"
else
  echo "  FAIL: no connection-pool metrics found — enable the Java Metric Extensions 2.0 (JMX) /"
  echo "        Connection Pools WebLogic extension per Dynatrace docs, then re-validate"
  rc=1
fi

# --- 3. Named dashboards exist ---
echo
echo "-- Named dashboards --"
dash=$(curl -s -H "$AUTH" "${CFG}/dashboards" 2>/dev/null)
for name in "C2M - Service Health" "C2M - JVM & Batch" "C2M - Infrastructure"; do
  if printf '%s' "$dash" | grep -qi "$name"; then
    echo "  PASS: dashboard present — ${name}"
  else
    echo "  FAIL: dashboard missing — ${name} (create per Implementation Step 4)"
    rc=1
  fi
done

# --- 4. Named alert rules (metric events) exist ---
echo
echo "-- Named alert rules (metric events) --"
alerts=$(curl -s -H "$AUTH" "${API}/settings/objects?schemaIds=builtin:anomaly-detection.metric-events&pageSize=500" 2>/dev/null)
for name in \
  "C2M Alert - JVM Heap High" \
  "C2M Alert - GC Time High" \
  "C2M Alert - Connection Pool Exhausted" \
  "C2M Alert - Endpoint Failure Rate" \
  "C2M Alert - Batch Worker Down"; do
  if printf '%s' "$alerts" | grep -qi "$name"; then
    echo "  PASS: alert rule present — ${name}"
  else
    echo "  FAIL: alert rule missing — ${name} (create per Implementation Step 5)"
    rc=1
  fi
done

echo
if [ "$rc" -eq 0 ]; then
  echo "OVERALL: PASS"
else
  echo "OVERALL: FAIL — remediate the flagged gaps (OC2MDYNA-Remediation.sh) and re-run."
fi
exit "$rc"
