# OC2MDYNA-Report.sh — read-only monitoring coverage / health snapshot for the C2M estate.
#
# PURPOSE
#     Produce one coverage and health snapshot of C2M monitoring in Dynatrace — hosts
#     monitored and C2M-Env-tagged, C2M/WebLogic JVMs seen, whether connection-pool
#     metrics exist, and which named dashboards and alert rules are present — to attach to
#     a change record and reuse as a regression baseline. Reads only; changes nothing.
#     It never prints the API token. Placeholders are plain text (your-tenant, your-token).
#
# HOW TO RUN
#     Set the tenant URL and a read-scoped API token as environment variables, then:
#         export DT_ENV_URL=https://your-tenant.live.dynatrace.com
#         export DT_API_TOKEN=your-read-scoped-token
#         ./OC2MDYNA-Report.sh                       # prints to screen
#         ./OC2MDYNA-Report.sh --out oc2mdyna-report.txt   # also writes a text file
#
# EXPECTED RESULTS
#     A sectioned report (Tenant, Hosts & tags, Detected JVMs, Metrics, Dashboards,
#     Alert rules, Findings) to screen and, if --out is given, to a file. A clean estate
#     shows all hosts monitored and tagged, pool metrics present, all three dashboards and
#     all five alert rules present, and zero findings. Exit 0 on success.
#
# NOTES
#     White-label, repeatable: capture a report before and after every change so a
#     green-to-green comparison proves you did not regress coverage. Strictly read-only
#     (GET requests only); the token is read from an env var and never echoed. Dynatrace
#     API paths/fields move between releases — verify for your tenant version.

set -u

OUT_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT_FILE="${2:-}"; shift 2 ;;
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

lines=""
findings=0
emit() { echo "$1"; lines="${lines}${1}
"; }
finding() { emit " * FINDING: $1"; findings=$((findings+1)); }

emit "===================================================================="
emit " OC2MDYNA Report — C2M monitoring coverage (read-only)"
emit "===================================================================="
emit " Tenant : ${DT_ENV_URL}"
emit " Date   : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
emit ""

# --- Tenant ---
code=$(curl -s -o /dev/null -w '%{http_code}' -H "$AUTH" "${API}/entities/types" 2>/dev/null || echo "000")
emit "--- Tenant ---"
if [ "$code" = "200" ]; then
  emit " Reachable: yes (HTTP 200)"
else
  emit " Reachable: NO (HTTP ${code})"; finding "tenant not reachable or token invalid"
fi

# --- Hosts & tags ---
emit ""
emit "--- Hosts & C2M-Env tags ---"
hosts=$(curl -s -G -H "$AUTH" \
  --data-urlencode 'entitySelector=type("HOST")' \
  --data-urlencode "fields=+tags,+properties.state" \
  --data-urlencode "pageSize=500" "${API}/entities" 2>/dev/null)
hcount=$(printf '%s' "$hosts" | grep -o '"entityId"' | wc -l | tr -d ' ')
emit " Hosts monitored: ${hcount}"
if printf '%s' "$hosts" | grep -qi "C2M-Env"; then
  emit " C2M-Env tag: present in fleet"
else
  emit " C2M-Env tag: NOT detected"; finding "C2M-Env host-group tag not found on monitored hosts"
fi

# --- Detected JVMs ---
emit ""
emit "--- Detected process groups (WebLogic / worker JVMs) ---"
pgs=$(curl -s -G -H "$AUTH" \
  --data-urlencode 'entitySelector=type("PROCESS_GROUP")' \
  --data-urlencode "pageSize=500" "${API}/entities" 2>/dev/null)
pcount=$(printf '%s' "$pgs" | grep -o '"entityId"' | wc -l | tr -d ' ')
emit " Process groups seen: ${pcount}"

# --- Metrics (connection pool) ---
emit ""
emit "--- Metrics ---"
poolx=$(curl -s -G -H "$AUTH" --data-urlencode "text=connection pool" "${API}/metrics" 2>/dev/null)
if printf '%s' "$poolx" | grep -qi "pool"; then
  emit " Connection-pool metrics: present"
else
  emit " Connection-pool metrics: MISSING"; finding "connection-pool metrics absent (enable JMX/Connection Pools extension)"
fi

# --- Dashboards ---
emit ""
emit "--- Dashboards ---"
dash=$(curl -s -H "$AUTH" "${CFG}/dashboards" 2>/dev/null)
for name in "C2M - Service Health" "C2M - JVM & Batch" "C2M - Infrastructure"; do
  if printf '%s' "$dash" | grep -qi "$name"; then
    emit " present : ${name}"
  else
    emit " MISSING : ${name}"; finding "dashboard missing: ${name}"
  fi
done

# --- Alert rules ---
emit ""
emit "--- Alert rules (metric events) ---"
alerts=$(curl -s -H "$AUTH" "${API}/settings/objects?schemaIds=builtin:anomaly-detection.metric-events&pageSize=500" 2>/dev/null)
for name in \
  "C2M Alert - JVM Heap High" \
  "C2M Alert - GC Time High" \
  "C2M Alert - Connection Pool Exhausted" \
  "C2M Alert - Endpoint Failure Rate" \
  "C2M Alert - Batch Worker Down"; do
  if printf '%s' "$alerts" | grep -qi "$name"; then
    emit " present : ${name}"
  else
    emit " MISSING : ${name}"; finding "alert rule missing: ${name}"
  fi
done

# --- Findings ---
emit ""
emit "--- Findings ---"
if [ "$findings" -eq 0 ]; then
  emit " None. Coverage is clean against the report checks."
fi

if [ -n "$OUT_FILE" ]; then
  printf '%s' "$lines" > "$OUT_FILE" && echo "" && echo "Report written to ${OUT_FILE}"
fi

exit 0
