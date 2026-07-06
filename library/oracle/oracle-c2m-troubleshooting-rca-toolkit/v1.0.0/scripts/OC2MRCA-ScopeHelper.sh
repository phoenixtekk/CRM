# OC2MRCA-ScopeHelper.sh — bound the incident, select the Diagnostic Playbook branch, emit the target set.
#
# PURPOSE
#     Scope a C2M incident before any check runs: take the observed symptom, print the
#     matching Diagnostic Playbook branch and the layer-isolation ladder for it, and resolve
#     the target set (which tier / Managed Server(s) / node(s)) the other scripts run against
#     — so triage starts bounded ("SPLWeb login on node-a since the 09:15 deploy") instead of
#     "C2M is broken". Read-only — it only reads an optional scope/topology file and prints
#     guidance; it touches no live system.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MRCA-ScopeHelper.sh --symptom wontstart
#         ./OC2MRCA-ScopeHelper.sh --symptom login
#         ./OC2MRCA-ScopeHelper.sh --symptom batch
#         ./OC2MRCA-ScopeHelper.sh --symptom jms
#         ./OC2MRCA-ScopeHelper.sh --symptom iws
#         ./OC2MRCA-ScopeHelper.sh --symptom performance
#         ./OC2MRCA-ScopeHelper.sh --symptom outage
#     Optional topology file (default ./oc2mrca-topology.conf) lines:  TIER,SERVER,NODE
#       e.g.   web,SPLWeb,node-a
#
# EXPECTED RESULTS
#     Prints: the selected branch and its ladder (which layers to check, in order), the
#     scoping questions to answer (when it started / what changed / total vs partial), and —
#     if the topology file exists — the resolved target servers/nodes for the affected tier.
#     Use the output to drive OC2MRCA-Discovery.sh, OC2MRCA-Validation.py, and
#     OC2MRCA-Report.sql against the right target set.
#
# NOTES
#     White-label, repeatable scoping — the same symptom map every incident, so triage is
#     bounded and auditable. Read-only. No live-system changes. Tier/server/node names are
#     yours to fill from your topology; branch names match the Diagnostic Playbook (document 3).

set -u

SYMPTOM=""
TOPO_FILE="./oc2mrca-topology.conf"

while [ $# -gt 0 ]; do
  case "$1" in
    --symptom) SYMPTOM="${2:-}"; shift 2 ;;
    --file)    TOPO_FILE="${2:-$TOPO_FILE}"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

echo "== OC2MRCA ScopeHelper =="

if [ -z "$SYMPTOM" ]; then
  echo "Usage: OC2MRCA-ScopeHelper.sh --symptom wontstart|login|batch|jms|iws|performance|outage"
  exit 2
fi

# Map symptom -> Diagnostic Playbook branch + the ladder to walk + the tier to target.
BRANCH=""; LADDER=""; TIER=""
case "$SYMPTOM" in
  wontstart)
    BRANCH="A — C2M won't start"
    LADDER="Reachable(net) -> Up(server state/NodeMgr) -> Authenticated(DB/SSL) -> Resourced(heap/threads/pool) -> Correct(OUAF deploy/config)"
    TIER="service web" ;;
  login)
    BRANCH="A — can't log in"
    LADDER="Reachable(net) -> Up(SPLWeb up) -> Authenticated(data source connect + cert expiry) -> Resourced(pool/threads) -> Correct(app/security config)"
    TIER="web" ;;
  batch)
    BRANCH="B — batch fails / won't submit"
    LADDER="Up(worker+daemon) -> Authenticated/Resourced(DB + JDBC pool; stuck-thread top-of-stack) -> Correct(batch control/data)"
    TIER="service" ;;
  jms)
    BRANCH="C — JMS backs up"
    LADDER="Up(consumers attached?) -> Resourced(throughput / stuck txn / slow downstream) -> Correct(message/config, error queue)"
    TIER="service" ;;
  iws)
    BRANCH="D — IWS / integration errors"
    LADDER="Reachable/Up(enabled? deployed? URL resolves) -> Authenticated(401/403/SSL) -> Correct(service mapping/payload; XAI-via-IWS feature)"
    TIER="web service" ;;
  performance)
    BRANCH="E — performance stall (slow, not down)"
    LADDER="Resourced-JVM(stuck/hogging + GC; read top of thread dump) -> Resourced-DB(blocking/plan/tablespace/pool) -> Correct(one function vs baseline)"
    TIER="web service" ;;
  outage)
    BRANCH="F — outage (total)"
    LADDER="Reachable(net: listener/ports/LB) -> Up(servers down? disk full? unclean shutdown) -> Authenticated(DB/listener down) -> Restore smallest action"
    TIER="service web" ;;
  *)
    echo "Unknown --symptom '${SYMPTOM}'. Use: wontstart|login|batch|jms|iws|performance|outage"
    exit 2 ;;
esac

echo
echo "Symptom : ${SYMPTOM}"
echo "Branch  : ${BRANCH}   (see Diagnostic Playbook, document 3)"
echo "Ladder  : ${LADDER}"
echo
echo "-- Scope it before checking (answer these) --"
echo "  * When did it start, and what changed just before (deploy, patch, cert, data spike)?"
echo "  * Total (all tiers dark) or partial (one function/one server/one node)?"
echo "  * Which tier(s) and Managed Server(s)/node(s) show the symptom?"
echo "  * Capture the snapshot now:  ./OC2MRCA-Discovery.sh   (before any restart)"

echo
echo "-- Target set (tier -> servers/nodes) --"
if [ -f "$TOPO_FILE" ]; then
  for t in $TIER; do
    echo "  tier '${t}':"
    awk -F, -v want="$t" '
      /^[[:space:]]*#/ { next }
      NF < 3 { next }
      { tier=$1; gsub(/[[:space:]]/,"",tier)
        if (tier == want) printf "    server %-12s node %s\n", $2, $3 }
    ' "$TOPO_FILE"
  done
else
  echo "  NOTE: topology file not found: ${TOPO_FILE}"
  echo "  Create it with one line per server:  TIER,SERVER,NODE"
  echo "    # TIER,SERVER,NODE   (TIER = web | service | help)"
  echo "    web,SPLWeb,node-a"
  echo "    service,SPLService,node-a"
  echo "    web,SPLWeb,node-b"
fi

echo
echo "Now run the checks against this target set:"
echo "  ./OC2MRCA-Discovery.sh ; java weblogic.WLST OC2MRCA-Validation.py ; sqlplus user/pass@your-db @OC2MRCA-Report.sql"
