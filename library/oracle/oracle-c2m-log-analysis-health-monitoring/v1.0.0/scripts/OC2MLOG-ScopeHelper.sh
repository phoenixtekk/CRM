# OC2MLOG-ScopeHelper.sh — build the in-scope log-source / host / signal target list for pilot and expansion.
#
# PURPOSE
#     Produce a bounded, reusable scope for the monitoring work: which log sources (OUAF,
#     WebLogic server/domain, batch), on which hosts, with which early-warning signals, to
#     bring under monitoring first (pilot subset) and then in full (expansion). It reads a
#     scope definition file and emits a clean, de-duplicated target list the other scripts and
#     the monitoring cadence consume, so pilot and each expansion wave run against a known set
#     rather than "everything at once". Read-only — it only reads the scope file.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MLOG-ScopeHelper.sh --scope pilot      # sources/hosts/signals tagged pilot
#         ./OC2MLOG-ScopeHelper.sh --scope all        # full expansion set
#     Scope file (default ./oc2mlog-scope.conf) lines:  LAYER,SOURCE,HOST,SIGNALS,SCOPE
#       e.g.   weblogic,server-log,host-a,oom+pool+stuck,pilot
#
# EXPECTED RESULTS
#     Prints the resolved, de-duplicated target list for the requested scope: log sources with
#     their layer and signals, and the distinct hosts. Use the output to target the discovery,
#     validation, and report runs and to drive the monitoring cadence. If the scope file is
#     missing it prints a template to create.
#
# NOTES
#     White-label, repeatable scoping — the same file drives pilot then each expansion wave, so
#     scope is explicit and auditable. Read-only. No live-system changes. Sources/hosts are
#     yours to fill from OC2MLOG-Discovery.sh output; signals from C2M Health - Signals -
#     EarlyWarning.

set -u

SCOPE="pilot"
SCOPE_FILE="./oc2mlog-scope.conf"

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-pilot}"; shift 2 ;;
    --file)  SCOPE_FILE="${2:-$SCOPE_FILE}"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

echo "== OC2MLOG ScopeHelper (scope=${SCOPE}) =="

if [ ! -f "$SCOPE_FILE" ]; then
  echo "NOTE: scope file not found: ${SCOPE_FILE}"
  echo "Create it with one line per target:  LAYER,SOURCE,HOST,SIGNALS,SCOPE"
  echo "  LAYER  = ouaf | weblogic | batch"
  echo "  SIGNALS= plus-joined subset of: error+oom+pool+stuck+batch+disk"
  echo "  SCOPE  = pilot | all"
  echo "Template:"
  echo "  # LAYER,SOURCE,HOST,SIGNALS,SCOPE"
  echo "  ouaf,spl-system-log,host-a,error+disk,pilot"
  echo "  weblogic,server-log,host-a,oom+pool+stuck,pilot"
  echo "  batch,threadpoolworker,host-b,batch+error,all"
  exit 1
fi

echo
echo "-- In-scope log sources (layer / source -> signals) --"
awk -F, -v want="$SCOPE" '
  /^[[:space:]]*#/ { next }
  NF < 5 { next }
  {
    scope=$5; gsub(/[[:space:]]/,"",scope)
    if (want == "all" || scope == want) {
      layer=$1; src=$2; sig=$4
      gsub(/[[:space:]]/,"",layer); gsub(/[[:space:]]/,"",src); gsub(/[[:space:]]/,"",sig)
      key=layer"|"src
      if (!seen[key]++) printf "  %-10s %-22s -> signals: %s\n", layer, src, sig
    }
  }
' "$SCOPE_FILE"

echo
echo "-- Distinct hosts in scope --"
awk -F, -v want="$SCOPE" '
  /^[[:space:]]*#/ { next }
  NF < 5 { next }
  {
    scope=$5; gsub(/[[:space:]]/,"",scope)
    host=$3; gsub(/[[:space:]]/,"",host)
    if ((want == "all" || scope == want) && host != "") {
      if (!seen_h[host]++) print "  " host
    }
  }
' "$SCOPE_FILE"

echo
echo "-- Signals in scope (union) --"
awk -F, -v want="$SCOPE" '
  /^[[:space:]]*#/ { next }
  NF < 5 { next }
  {
    scope=$5; gsub(/[[:space:]]/,"",scope)
    if (want == "all" || scope == want) {
      sig=$4; gsub(/[[:space:]]/,"",sig)
      n=split(sig, a, /\+/)
      for (i=1;i<=n;i++) if (a[i]!="" && !seen_s[a[i]]++) list=list (list==""?"":", ") a[i]
    }
  }
  END { print "  " (list==""?"(none)":list) }
' "$SCOPE_FILE"

echo
echo "Use this target list to drive OC2MLOG-Discovery/Validation/Report runs and the monitoring cadence."
