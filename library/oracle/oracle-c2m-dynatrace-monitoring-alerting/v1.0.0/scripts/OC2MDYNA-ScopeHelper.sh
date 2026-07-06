# OC2MDYNA-ScopeHelper.sh — build the in-scope C2M host / tier target list for pilot and expansion.
#
# PURPOSE
#     Produce a bounded, reusable scope for the monitoring work: the C2M hosts and their
#     tier (online WebLogic, thread pool worker, IWS, database) and environment, so the
#     pilot and each expansion wave run against a known set rather than "everything at
#     once". It reads a scope definition file and emits a clean, de-duplicated target list
#     the discovery, validation, and report scripts consume. Read-only — it only reads the
#     scope file. Placeholders are plain text (your-host) without angle brackets.
#
# HOW TO RUN
#     No tenant token needed — this only reads a local scope file:
#         ./OC2MDYNA-ScopeHelper.sh --scope pilot        # hosts/tiers tagged pilot
#         ./OC2MDYNA-ScopeHelper.sh --scope all          # full expansion set
#     Scope file (default ./oc2mdyna-scope.conf) lines:  HOST,TIER,ENV,SCOPE
#       e.g.   your-wls-01,online,prod,pilot
#
# EXPECTED RESULTS
#     Prints the resolved, de-duplicated target list for the requested scope: hosts with
#     their tier and environment, and a per-tier count. Use the output to drive OneAgent
#     install (Implementation Step 2) and to target discovery/validation/report runs. If
#     the scope file is missing it prints a template to create.
#
# NOTES
#     White-label, repeatable scoping — the same file drives pilot then each expansion wave,
#     so scope is explicit and auditable. Read-only. No live-system changes and no token
#     use. Host names and tiers are yours to fill from the WebLogic domain / OUAF worker
#     topology (and cross-checked against OC2MDYNA-Discovery.sh output).

set -u

SCOPE="pilot"
SCOPE_FILE="./oc2mdyna-scope.conf"
while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-pilot}"; shift 2 ;;
    --file)  SCOPE_FILE="${2:-$SCOPE_FILE}"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

echo "== OC2MDYNA ScopeHelper (scope=${SCOPE}) =="

if [ ! -f "$SCOPE_FILE" ]; then
  echo "NOTE: scope file not found: ${SCOPE_FILE}"
  echo "Create it with one line per target:  HOST,TIER,ENV,SCOPE"
  echo "Template:"
  echo "  # HOST,TIER,ENV,SCOPE   (TIER = online | worker | iws | db ; SCOPE = pilot | all)"
  echo "  your-wls-01,online,prod,pilot"
  echo "  your-worker-01,worker,prod,pilot"
  echo "  your-iws-01,iws,prod,all"
  echo "  your-db-01,db,prod,all"
  exit 1
fi

echo
echo "-- In-scope hosts (host -> tier / env) --"
awk -F, -v want="$SCOPE" '
  /^[[:space:]]*#/ { next }
  NF < 4 { next }
  {
    sc=$4; gsub(/[[:space:]]/,"",sc)
    host=$1; gsub(/[[:space:]]/,"",host)
    tier=$2; gsub(/[[:space:]]/,"",tier)
    env=$3;  gsub(/[[:space:]]/,"",env)
    if ((want=="all" || sc==want) && host!="") {
      key=host"|"tier"|"env
      if (!seen[key]++) { printf "  %-24s -> %-8s / %s\n", host, tier, env; cnt[tier]++ }
    }
  }
  END {
    print ""
    print "-- Per-tier count --"
    n=0
    for (t in cnt) { printf "  %-8s : %d\n", t, cnt[t]; n+=cnt[t] }
    printf "  %-8s : %d\n", "TOTAL", n
  }
' "$SCOPE_FILE"

echo
echo "Use this target list to drive OneAgent install and to target discovery/validation/report runs."
