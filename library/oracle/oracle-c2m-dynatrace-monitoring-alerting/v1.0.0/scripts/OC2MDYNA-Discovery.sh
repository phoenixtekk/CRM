# OC2MDYNA-Discovery.sh — read-only discovery of Dynatrace monitoring coverage for the C2M / WebLogic estate.
#
# PURPOSE
#     Capture current-state monitoring coverage before you instrument or dashboard C2M.
#     Confirms the Dynatrace tenant is reachable, then reports which hosts already run a
#     OneAgent and which C2M/WebLogic JVMs and processes Dynatrace already sees. Uses the
#     Dynatrace read APIs with a read-scoped token supplied via env var. Read-only — it
#     only queries the tenant and changes nothing. It never prints the token.
#     Tenant placeholders use plain text (your-tenant, your-token) without angle brackets.
#
# HOW TO RUN
#     Set the tenant URL and a read-scoped API token as environment variables first, then:
#         export DT_ENV_URL=https://your-tenant.live.dynatrace.com
#         export DT_API_TOKEN=your-read-scoped-token
#         ./OC2MDYNA-Discovery.sh
#     Optional: HOST_FILTER=C2M-Env to narrow entity queries to the C2M host group/tag.
#
# EXPECTED RESULTS
#     Prints: tenant reachability PASS/FAIL, the count of hosts reporting a running
#     OneAgent, and a list of monitored hosts and detected process groups (WebLogic /
#     thread pool worker JVMs) it can see. PASS = tenant reachable and at least the
#     expected C2M hosts appear. FAIL = tenant unreachable or token invalid — fix first.
#
# NOTES
#     White-label, repeatable coverage discovery. Read-only where it reads live systems:
#     it only issues GET requests to the Dynatrace API. The token is read from an env var
#     and never echoed. Dynatrace API paths/fields move between releases — verify against
#     the current Dynatrace documentation for your tenant version.

set -u

echo "== OC2MDYNA Discovery =="

# --- 0. Preconditions (no secrets printed) ---
: "${DT_ENV_URL:=}"
: "${DT_API_TOKEN:=}"
HOST_FILTER="${HOST_FILTER:-}"

if [ -z "$DT_ENV_URL" ] || [ -z "$DT_API_TOKEN" ]; then
  echo "FAIL: set DT_ENV_URL and DT_API_TOKEN (read-scoped) as environment variables first."
  echo "      export DT_ENV_URL=https://your-tenant.live.dynatrace.com"
  echo "      export DT_API_TOKEN=your-read-scoped-token   # never printed by this script"
  exit 1
fi
command -v curl >/dev/null 2>&1 || { echo "FAIL: curl not found on PATH."; exit 1; }

API="${DT_ENV_URL%/}/api/v2"
AUTH="Authorization: Api-Token ${DT_API_TOKEN}"

# --- 1. Tenant reachability / token validity (read-only) ---
echo "-- Tenant reachability --"
code=$(curl -s -o /dev/null -w '%{http_code}' -H "$AUTH" "${API}/entities/types" 2>/dev/null || echo "000")
if [ "$code" = "200" ]; then
  echo "  PASS: tenant reachable and token authenticates for read (HTTP 200)"
elif [ "$code" = "401" ] || [ "$code" = "403" ]; then
  echo "  FAIL: token rejected (HTTP ${code}) — check the read scopes on the API token"
  exit 1
else
  echo "  FAIL: tenant not reachable (HTTP ${code}) — check DT_ENV_URL / egress / ActiveGate"
  exit 1
fi

# --- 2. Hosts reporting a running OneAgent (read-only) ---
echo
echo "-- Monitored hosts (OneAgent) --"
SEL='type("HOST")'
[ -n "$HOST_FILTER" ] && SEL="${SEL},tag(\"${HOST_FILTER}\")"
hosts=$(curl -s -G -H "$AUTH" \
  --data-urlencode "entitySelector=${SEL}" \
  --data-urlencode "fields=+properties.monitoringMode,+properties.state" \
  --data-urlencode "pageSize=500" \
  "${API}/entities" 2>/dev/null)

if command -v python3 >/dev/null 2>&1; then
  printf '%s' "$hosts" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print("  (could not parse response — verify API path/fields for your version)"); sys.exit(0)
ents = d.get("entities", [])
print("  hosts seen: %d" % len(ents))
for e in ents[:100]:
    p = e.get("properties", {})
    print("   - %-30s mode=%s state=%s" % (e.get("displayName","?"), p.get("monitoringMode","?"), p.get("state","?")))
'
else
  echo "  (python3 not found — raw host count via grep)"
  printf '%s' "$hosts" | grep -o '"entityId"' | wc -l | sed 's/^/  entities in response: /'
fi

# --- 3. Detected C2M / WebLogic process groups (read-only) ---
echo
echo "-- Detected process groups (WebLogic / thread pool worker JVMs) --"
pgs=$(curl -s -G -H "$AUTH" \
  --data-urlencode 'entitySelector=type("PROCESS_GROUP")' \
  --data-urlencode "pageSize=500" \
  "${API}/entities" 2>/dev/null)
if command -v python3 >/dev/null 2>&1; then
  printf '%s' "$pgs" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print("  (could not parse response)"); sys.exit(0)
hits = [e.get("displayName","") for e in d.get("entities", [])]
c2m = [n for n in hits if any(k in n.lower() for k in ("weblogic","wls","threadpool","batch","ouaf","c2m","cm1"))]
print("  process groups seen: %d (likely C2M/WebLogic: %d)" % (len(hits), len(c2m)))
for n in c2m[:50]:
    print("   - %s" % n)
if not c2m:
    print("   (none matched C2M/WebLogic name hints — confirm names, or widen HOST_FILTER)")
'
else
  echo "  (python3 not found — inspect the process-group response manually)"
fi

echo
echo "Discovery complete. Compare the seen hosts/JVMs to OC2MDYNA-ScopeHelper.sh output and record gaps."
