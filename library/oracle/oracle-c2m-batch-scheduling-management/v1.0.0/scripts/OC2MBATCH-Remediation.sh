# OC2MBATCH-Remediation.sh — align worker thread-pool config to the standard set (DRY-RUN by default).
#
# PURPOSE
#     Bring a worker node's thread-pool configuration into line with the standard set
#     (DEFAULT, ONLINE, BILLING — the C2M Worker - Node - Threadpools set) when validation
#     flags a missing or mis-sized pool. DRY-RUN by default: it prints the exact change it
#     WOULD make (the threadpoolworker startup line / property edit) and changes nothing.
#     It applies only when explicitly asked, and only intended for a change window.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MBATCH-Remediation.sh                       # DRY-RUN: prints intended change only
#         ./OC2MBATCH-Remediation.sh --apply               # applies (change window only)
#     Override sizing:  DEFAULT_THREADS=5 ONLINE_THREADS=3 BILLING_THREADS=8 ./OC2MBATCH-Remediation.sh
#
# EXPECTED RESULTS
#     DRY-RUN prints the standard pool line and any drift from the current config, plus the
#     exact command/edit to apply — and exits without changing anything. With --apply it
#     writes the standard pools into threadpoolworker.properties (backing up the file first)
#     and prints the restart command the admin must run in the change window.
#
# NOTES
#     White-label, repeatable remediation — DRY-RUN by default so it is safe to run anywhere.
#     It never restarts a running worker itself; it prints the restart step for the admin to
#     perform under change control. Names/flags per the OUAF Server Administration Guide —
#     verify for your version.

set -u

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

DEFAULT_THREADS="${DEFAULT_THREADS:-5}"
ONLINE_THREADS="${ONLINE_THREADS:-3}"
BILLING_THREADS="${BILLING_THREADS:-8}"
STANDARD_LINE="DEFAULT=${DEFAULT_THREADS},ONLINE=${ONLINE_THREADS},BILLING=${BILLING_THREADS}"

echo "== OC2MBATCH Remediation =="
if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi

TPW_PROPS="${SPLEBASE}/etc/threadpoolworker.properties"

echo "Standard pool set (C2M Worker - Node - Threadpools): ${STANDARD_LINE}"
echo "Target config file: ${TPW_PROPS}"
echo

# --- Show current vs intended ---
echo "-- Current pool-related lines --"
if [ -f "$TPW_PROPS" ]; then
  grep -Ei "pool|threads|distThreadPool" "$TPW_PROPS" 2>/dev/null || echo "  (none matched)"
else
  echo "  (config file not present — pools may be set at startup via  threadpoolworker.sh -p ...)"
fi

echo
echo "-- Intended change --"
echo "  Ensure the worker offers:  threadpoolworker.sh -p ${STANDARD_LINE}"
echo "  Or set in ${TPW_PROPS}:"
echo "    ol.batchpoolworker.threadpools=${STANDARD_LINE}   # property name — verify for your version"

if [ "$APPLY" -eq 0 ]; then
  echo
  echo "DRY-RUN: no changes made. Re-run with --apply in a change window to write the config."
  exit 0
fi

# --- Apply (change window only) ---
echo
echo "APPLY: writing standard pools (backup first)..."
if [ -f "$TPW_PROPS" ]; then
  cp -p "$TPW_PROPS" "${TPW_PROPS}.bak.$(date +%Y%m%d%H%M%S)"
  echo "  backed up ${TPW_PROPS}"
fi
# append/replace the pool property (verify exact property key for your version before use)
{
  echo ""
  echo "# Set by OC2MBATCH-Remediation.sh on $(date)"
  echo "ol.batchpoolworker.threadpools=${STANDARD_LINE}"
} >> "$TPW_PROPS"
echo "  wrote pool line to ${TPW_PROPS}"
echo
echo "NEXT (admin, in the change window): restart the worker to pick up the pools, e.g.:"
echo "    threadpoolworker.sh -p ${STANDARD_LINE}"
echo "Then re-run OC2MBATCH-Validation.sh to confirm the pools are advertised."
