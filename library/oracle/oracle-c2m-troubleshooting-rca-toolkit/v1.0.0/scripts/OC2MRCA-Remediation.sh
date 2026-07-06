# OC2MRCA-Remediation.sh — preview the smallest safe service-restoration action (DRY-RUN by default).
#
# PURPOSE
#     Once the failing layer is isolated, preview the SMALLEST safe, reversible restore for it
#     and print the exact command the admin runs under change control. DRY-RUN by default: it
#     prints only what it WOULD do and changes nothing. It covers the safe restores only —
#     an orderly single-server restart, a JDBC data-source re-sync (suspend/resume, i.e. a
#     reset without config change), and a JMS re-sync (pause/resume consumption) — never a
#     config edit, never a product change, never a full-stack bounce by itself. It does not
#     restart a running server on its own even with --apply; it emits the precise WLST/OS
#     step for the admin to run in the change window.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MRCA-Remediation.sh --action restart --target SPLService     # DRY-RUN preview
#         ./OC2MRCA-Remediation.sh --action datasource --target C2M-DS       # DRY-RUN preview
#         ./OC2MRCA-Remediation.sh --action jms --target C2M-Queue           # DRY-RUN preview
#         ./OC2MRCA-Remediation.sh --action restart --target SPLService --apply   # change window only
#     Actions: restart | datasource | jms      Target: server / data-source / destination name.
#     Admin URL for the emitted WLST steps:  ADMIN_URL=t3://your-admin-host:7001
#
# EXPECTED RESULTS
#     DRY-RUN prints the isolated layer, the smallest safe restore for it, and the EXACT
#     command(s) to apply (with the "capture snapshot + backup first" and "re-validate after"
#     reminders) — and exits without changing anything. With --apply it prints the same steps
#     framed as a change-window runbook to execute; it still does not perform a live restart
#     itself. Always re-run OC2MRCA-Validation.py afterwards to confirm the restore.
#
# NOTES
#     White-label, repeatable remediation — DRY-RUN by default so it is safe to run anywhere.
#     Read-only in dry-run. It only ever previews reversible, service-restoration actions;
#     anything that edits config or changes the product is out of scope by design. Command
#     names/flags follow the WebLogic 14c / OUAF model — verify for your version before use.

set -u

ACTION=""
TARGET=""
APPLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --action) ACTION="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --apply)  APPLY=1; shift ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

ADMIN_URL="${ADMIN_URL:-t3://your-admin-host:7001}"

echo "== OC2MRCA Remediation (smallest safe restore) =="
if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi
if [ -z "$ACTION" ] || [ -z "$TARGET" ]; then
  echo "Usage: OC2MRCA-Remediation.sh --action restart|datasource|jms --target NAME [--apply]"
  echo "Run OC2MRCA-Validation.py first to isolate the failing layer and pick the action/target."
  exit 2
fi

echo "Action : ${ACTION}"
echo "Target : ${TARGET}"
echo "Mode   : $( [ "$APPLY" -eq 1 ] && echo 'APPLY (change window runbook)' || echo 'DRY-RUN (preview only)')"
echo

echo "-- Preconditions (always) --"
echo "  1. Capture evidence first:   ./OC2MRCA-Discovery.sh   (do not lose it to a log roll)"
echo "  2. Back up domain + product config before any production action."
echo "  3. This is a change: change window + documented rollback."
echo

case "$ACTION" in
  restart)
    echo "-- Smallest safe restore: orderly restart of a single server (${TARGET}) --"
    echo "  Layer: middleware (server FAILED / stuck-thread saturation not clearing)."
    echo "  Intended step (admin runs under change control):"
    echo "    java weblogic.WLST <<'WLST'"
    echo "    connect(url='${ADMIN_URL}')      # read-capable admin"
    echo "    shutdown('${TARGET}', 'Server', force='false', block='true')   # graceful"
    echo "    start('${TARGET}', 'Server')"
    echo "    WLST"
    echo "  Prefer graceful (force='false'); ensure no orphaned JVM holds the port before start."
    ;;
  datasource)
    echo "-- Smallest safe restore: JDBC data-source re-sync (${TARGET}) --"
    echo "  Layer: middleware to DB (data source Suspended / failed reserves after DB recovered)."
    echo "  Intended step (reset the pool, NO config change):"
    echo "    java weblogic.WLST <<'WLST'"
    echo "    connect(url='${ADMIN_URL}')"
    echo "    # locate the data-source runtime, then suspend + resume to reset the pool"
    echo "    # (verify the exact control-MBean method names for your version)"
    echo "    #   ds.suspend()   ;   ds.resume()"
    echo "    WLST"
    echo "  Confirm the database/listener is actually back first (OC2MRCA-Report.sql section 1)."
    ;;
  jms)
    echo "-- Smallest safe restore: JMS destination re-sync (${TARGET}) --"
    echo "  Layer: middleware (consumers detached / production or consumption paused)."
    echo "  Intended step (resume consumption/production, NO config change):"
    echo "    java weblogic.WLST <<'WLST'"
    echo "    connect(url='${ADMIN_URL}')"
    echo "    # on the destination runtime, resume consumption/production if paused"
    echo "    #   dest.resume()      (verify method names for your version)"
    echo "    WLST"
    echo "  If the backlog is zero-consumer, restart the consuming component instead (that is the cause)."
    ;;
  *)
    echo "Unknown --action '${ACTION}'. Use: restart | datasource | jms"
    exit 2
    ;;
esac

echo
if [ "$APPLY" -eq 0 ]; then
  echo "DRY-RUN: nothing changed. This tool previews only; run the emitted step yourself in a change window."
else
  echo "APPLY: treat the emitted step as the change-window runbook — execute it under change control."
  echo "       This tool intentionally does not perform a live restart on its own."
fi
echo "AFTER the restore: re-run  java weblogic.WLST OC2MRCA-Validation.py  to confirm the layer now PASSes,"
echo "then record the C2M RCA - Root-Cause Record."
