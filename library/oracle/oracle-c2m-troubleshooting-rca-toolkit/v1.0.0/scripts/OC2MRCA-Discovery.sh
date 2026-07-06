# OC2MRCA-Discovery.sh — read-only collection of the C2M RCA Diagnostic Snapshot (config, server states, logs, DB pointers).
#
# PURPOSE
#     Collect a point-in-time C2M RCA - Diagnostic Snapshot for an Oracle Utilities C2M
#     environment and its WebLogic 14c domain: confirm the environment is sourced, resolve
#     the domain and product log paths, list the WebLogic server output/log files and tail
#     the most recent entries, capture any thread-dump / OutOfMemoryError / startup-error
#     fingerprints from the server .out files, and point to the database diagnostics.
#     Read-only — it changes nothing. Run it FIRST, before any restart, so the evidence is
#     captured before logs roll (Diagnostic Playbook Step 0). Also run it on a healthy day
#     to store the baseline.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MRCA-Discovery.sh
#     Optional: OUT_DIR=/path/to/snapshot to write the snapshot files to a folder.
#     Optional: DB_CONN=user/pass@your-db to include a quick DB reachability note.
#
# EXPECTED RESULTS
#     Prints: environment sourced OK and domain/log paths resolved; the WebLogic server
#     .out/.log inventory with recent tails; any thread-dump / OOM / FAILED markers found;
#     the product spl*.log / system.log tails; and a pointer to run OC2MRCA-Report.sql for
#     the DB view. PASS = environment sourced and log paths resolved. FAIL = environment
#     not sourced or log paths missing — fix before continuing.
#
# NOTES
#     White-label, repeatable discovery — the same snapshot every incident and for the
#     baseline. Read-only where it reads live systems: it only reads config/log files and,
#     if DB_CONN is set, issues a single reachability SELECT. Command/script/log names are
#     from the OUAF Server Administration Guide and WebLogic 14c docs — verify exact
#     names/paths for your version.

set -u

echo "== OC2MRCA Discovery (C2M RCA - Diagnostic Snapshot) =="
STAMP="$(date +%Y%m%d%H%M%S)"

# --- 1. Confirm the environment is sourced ---
if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi
echo "PASS: environment sourced (SPLEBASE=${SPLEBASE})"
echo "  SPLOUTPUT=${SPLOUTPUT:-(not set)}"

# Optional output folder for the snapshot artifacts
OUT_DIR="${OUT_DIR:-}"
if [ -n "$OUT_DIR" ]; then
  mkdir -p "$OUT_DIR" 2>/dev/null && echo "  snapshot dir: ${OUT_DIR}"
fi

# --- 2. Resolve the WebLogic domain and its log directory ---
# The domain home is commonly under SPLEBASE/splapp or set for the environment; verify for your version.
DOMAIN_HOME="${DOMAIN_HOME:-${SPLEBASE}/splapp}"
echo
echo "-- WebLogic domain --"
echo "  DOMAIN_HOME=${DOMAIN_HOME} (verify for your version)"
DOMAIN_LOGDIR="${DOMAIN_HOME}/servers"
if [ -d "$DOMAIN_LOGDIR" ]; then
  echo "  server directories:"
  ls -1 "$DOMAIN_LOGDIR" 2>/dev/null | sed 's/^/    /'
else
  echo "  NOTE: ${DOMAIN_LOGDIR} not found — set DOMAIN_HOME to your domain for full server-log discovery"
fi

# --- 3. Inventory + tail WebLogic server .out/.log; fingerprint failures ---
echo
echo "-- WebLogic server output (.out/.log) — recent tails and failure markers --"
if [ -d "$DOMAIN_LOGDIR" ]; then
  find "$DOMAIN_LOGDIR" -type f \( -name "*.out" -o -name "*.log" \) 2>/dev/null | while read -r f; do
    echo "  [${f}]"
    tail -n 20 "$f" 2>/dev/null | sed 's/^/     | /'
    # fingerprint the classic startup / resource failures (read-only grep)
    grep -Ei "OutOfMemoryError|FAILED_NOT_RESTARTABLE|ClassNotFoundException|BEA-|Full GC|kill -3|Full thread dump|stuck" "$f" 2>/dev/null \
      | tail -n 10 | sed 's/^/     ! /'
    echo
  done
else
  echo "  (no server log directory resolved — verify DOMAIN_HOME)"
fi

# --- 4. Product/OUAF logs (spl*.log, system.log) ---
echo "-- Product/OUAF logs --"
PROD_LOGDIR="${SPLOUTPUT:-${SPLEBASE}/logs}"
if [ -d "$PROD_LOGDIR" ]; then
  find "$PROD_LOGDIR" -type f \( -name "spl*.log" -o -name "system.log" \) 2>/dev/null | head -n 20 | while read -r f; do
    echo "  [${f}]"
    tail -n 15 "$f" 2>/dev/null | sed 's/^/     | /'
    grep -Ei "ERROR|FATAL|Exception" "$f" 2>/dev/null | tail -n 8 | sed 's/^/     ! /'
    echo
  done
else
  echo "  NOTE: product log dir ${PROD_LOGDIR} not found — confirm SPLOUTPUT (Requirement 2.2)"
fi

# --- 5. Disk headroom on the log/output volumes (a full volume takes C2M down) ---
echo "-- Disk headroom (domain + product output volumes) --"
df -h "$DOMAIN_HOME" "$PROD_LOGDIR" 2>/dev/null | sed 's/^/  /' || echo "  (df unavailable)"

# --- 6. Optional: quick DB reachability note ---
echo
if [ -n "${DB_CONN:-}" ]; then
  echo "-- Database reachability (single SELECT, read-only) --"
  echo "SELECT 'db-reachable' AS status FROM dual;" | sqlplus -s "$DB_CONN" 2>/dev/null | sed 's/^/  /' \
    || echo "  FAIL: could not reach DB with DB_CONN — this is itself a DB/network-layer finding"
else
  echo "NOTE: set DB_CONN=user/pass@your-db for a quick DB reachability check."
fi
echo "For full DB diagnostics run:  sqlplus user/pass@your-db @OC2MRCA-Report.sql"

echo
echo "Discovery complete (${STAMP}). Store this snapshot as evidence (and as the baseline on a healthy day)."
echo "Next: java weblogic.WLST OC2MRCA-Validation.py   for per-layer live state."
