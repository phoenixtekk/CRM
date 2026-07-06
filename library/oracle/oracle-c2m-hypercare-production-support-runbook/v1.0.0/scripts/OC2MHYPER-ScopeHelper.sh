# OC2MHYPER-ScopeHelper.sh — render the on-call rota window and the day-2 build lane from the scope file.
#
# PURPOSE
#     Produce the bounded, reusable scope hypercare runs on: the current on-call rota window
#     (who is primary/secondary by layer) and the day-2 build lane (which lower environments
#     and controls further work flows through during hypercare). It reads one scope file and
#     emits a clean, de-duplicated list, so the rota and the day-2 lane are explicit and
#     auditable rather than remembered. Read-only — it only reads the scope file.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MHYPER-ScopeHelper.sh --scope rota      # current on-call window contacts by layer
#         ./OC2MHYPER-ScopeHelper.sh --scope day2      # day-2 build lane environments/controls
#     Scope file (default ./oc2mhyper-scope.conf) lines:  KIND,LAYER_OR_ENV,NAME,CONTACT_OR_CONTROL
#       rota lines:  rota,middleware,Primary Name,pager-or-email
#       day2 lines:  day2,UAT,config-change-name,change-ticket
#
# EXPECTED RESULTS
#     For --scope rota: the current window's primary/secondary per layer (application,
#     middleware, database, integration, infrastructure) with contacts. For --scope day2: the
#     lower environments and the day-2 controls flowing through change control. If the scope
#     file is missing it prints a template to create. Read-only — no live-system changes.
#
# NOTES
#     White-label, repeatable scoping — the same file drives the rota window and the day-2 lane
#     through hypercare, so both are explicit and auditable. Read-only. No live-system changes.
#     Names are yours to fill from the runbook (rota, escalation matrix, day-2 lane).

set -u

SCOPE="rota"
SCOPE_FILE="./oc2mhyper-scope.conf"

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-rota}"; shift 2 ;;
    --file)  SCOPE_FILE="${2:-$SCOPE_FILE}"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

echo "== OC2MHYPER ScopeHelper (scope=${SCOPE}) =="

if [ ! -f "$SCOPE_FILE" ]; then
  echo "NOTE: scope file not found: ${SCOPE_FILE}"
  echo "Create it with one line per entry:  KIND,LAYER_OR_ENV,NAME,CONTACT_OR_CONTROL"
  echo "Template:"
  echo "  # KIND,LAYER_OR_ENV,NAME,CONTACT_OR_CONTROL   (KIND = rota | day2)"
  echo "  rota,application,Primary Name,pager-or-email"
  echo "  rota,middleware,Secondary Name,pager-or-email"
  echo "  rota,database,Primary Name,pager-or-email"
  echo "  day2,UAT,config-change-name,change-ticket"
  echo "  day2,TEST,report-change-name,change-ticket"
  exit 1
fi

case "$SCOPE" in
  rota)
    echo
    echo "-- On-call rota (current window, by layer) --"
    awk -F, '
      /^[[:space:]]*#/ { next }
      NF < 4 { next }
      { kind=$1; gsub(/[[:space:]]/,"",kind) }
      kind=="rota" {
        layer=$2; gsub(/^[[:space:]]+|[[:space:]]+$/,"",layer)
        key=layer"|"$3
        if (!seen[key]++) printf "  %-14s %-24s %s\n", layer, $3, $4
      }
    ' "$SCOPE_FILE"
    ;;
  day2)
    echo
    echo "-- Day-2 build lane (environment -> control -> change ref) --"
    awk -F, '
      /^[[:space:]]*#/ { next }
      NF < 4 { next }
      { kind=$1; gsub(/[[:space:]]/,"",kind) }
      kind=="day2" {
        env=$2; gsub(/^[[:space:]]+|[[:space:]]+$/,"",env)
        key=env"|"$3
        if (!seen[key]++) printf "  %-8s %-28s %s\n", env, $3, $4
      }
    ' "$SCOPE_FILE"
    echo
    echo "-- Distinct lower environments in the day-2 lane --"
    awk -F, '
      /^[[:space:]]*#/ { next }
      NF < 4 { next }
      { kind=$1; gsub(/[[:space:]]/,"",kind) }
      kind=="day2" {
        env=$2; gsub(/[[:space:]]/,"",env)
        if (env != "" && !seenenv[env]++) print "  " env
      }
    ' "$SCOPE_FILE"
    ;;
  *)
    echo "Unknown scope: ${SCOPE} (use: rota | day2)"
    exit 2
    ;;
esac

echo
echo "Use this to drive the on-call rota and the day-2 build lane through hypercare (change control on every promotion)."
