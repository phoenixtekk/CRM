# OC2MBATCH-ScopeHelper.sh — build the in-scope batch-control and worker-node target list for pilot and expansion.
#
# PURPOSE
#     Produce a bounded, reusable scope for the batch work: the list of batch controls to
#     schedule (pilot subset first, then expansion) and the worker nodes they run on. It
#     reads a scope definition file and emits a clean, de-duplicated target list the other
#     scripts and the scheduler consume, so the pilot and each expansion wave run against a
#     known set rather than "everything at once". Read-only — it only reads the scope file.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MBATCH-ScopeHelper.sh --scope pilot      # controls/nodes tagged pilot
#         ./OC2MBATCH-ScopeHelper.sh --scope all        # full expansion set
#     Scope file (default ./oc2mbatch-scope.conf) lines:  CONTROL,POOL,NODE,SCOPE
#       e.g.   BILLING,BILLING,worker-a,pilot
#
# EXPECTED RESULTS
#     Prints the resolved, de-duplicated target list for the requested scope: batch
#     controls with their assigned pool, and the distinct worker nodes. Use the output to
#     drive the scheduler mapping (Implementation Step 4) and to target validation/report
#     runs. If the scope file is missing it prints a template to create.
#
# NOTES
#     White-label, repeatable scoping — the same file drives pilot then each expansion wave,
#     so scope is explicit and auditable. Read-only. No live-system changes. Object names
#     (controls, pools) are yours to fill from OC2MBATCH-Discovery.sh output.

set -u

SCOPE="pilot"
SCOPE_FILE="./oc2mbatch-scope.conf"

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-pilot}"; shift 2 ;;
    --file)  SCOPE_FILE="${2:-$SCOPE_FILE}"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

echo "== OC2MBATCH ScopeHelper (scope=${SCOPE}) =="

if [ ! -f "$SCOPE_FILE" ]; then
  echo "NOTE: scope file not found: ${SCOPE_FILE}"
  echo "Create it with one line per target:  CONTROL,POOL,NODE,SCOPE"
  echo "Template:"
  echo "  # CONTROL,POOL,NODE,SCOPE   (SCOPE = pilot | all)"
  echo "  BILLING,BILLING,worker-a,pilot"
  echo "  PAYMENT-UPLOAD,DEFAULT,worker-a,pilot"
  echo "  TODO-GENERATION,ONLINE,worker-b,all"
  exit 1
fi

echo
echo "-- In-scope batch controls (control -> pool) --"
awk -F, -v want="$SCOPE" '
  /^[[:space:]]*#/ { next }
  NF < 4 { next }
  {
    scope=$4; gsub(/[[:space:]]/,"",scope)
    if (want == "all" || scope == want) {
      key=$1"|"$2
      if (!seen_ctrl[key]++) printf "  %-24s -> pool %s\n", $1, $2
    }
  }
' "$SCOPE_FILE"

echo
echo "-- Distinct worker nodes in scope --"
awk -F, -v want="$SCOPE" '
  /^[[:space:]]*#/ { next }
  NF < 4 { next }
  {
    scope=$4; gsub(/[[:space:]]/,"",scope)
    node=$3; gsub(/[[:space:]]/,"",node)
    if ((want == "all" || scope == want) && node != "") {
      if (!seen_node[node]++) print "  " node
    }
  }
' "$SCOPE_FILE"

echo
echo "Use this target list to drive the scheduler mapping and to target validation/report runs."
