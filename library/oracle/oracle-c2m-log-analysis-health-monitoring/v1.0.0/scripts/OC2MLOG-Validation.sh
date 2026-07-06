# OC2MLOG-Validation.sh — read-only health checks and early-warning signal detection across the C2M logs.
#
# PURPOSE
#     Run the standard health checks (C2M Health - Checks - Standard) and report whether each
#     early-warning signal (C2M Health - Signals - EarlyWarning) fires in the inventoried
#     logs: error/exception rate, OutOfMemoryError, connection-pool exhaustion, stuck
#     threads, batch failures, and log currency. Read-only — it scans logs and reports
#     PASS/FAIL/FIRED, it changes nothing. Run it on the pilot (Step 8) and after expansion.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MLOG-Validation.sh
#     Optional: DOMAIN_HOME=/path/to/your-domain to scan WebLogic logs;
#               SCAN_MINS=1440 to bound how far back to scan (default 24h).
#
# EXPECTED RESULTS
#     For each check prints PASS/FAIL, and for each signal FIRED or clear. Overall PASS = all
#     logs current and readable and no signal FIRED. A FIRED signal is an early warning (act
#     on it); a FAIL check is a monitoring gap to remediate (see OC2MLOG-Remediation.sh)
#     before re-validating.
#
# NOTES
#     White-label, repeatable validation — the same checks and signals every environment.
#     Read-only where it reads live systems (greps and stats logs; it does not modify them).
#     Signal patterns follow the OUAF log format and WebLogic message wording — verify the
#     exact terms for your version and tune thresholds to your baseline.

set -u

echo "== OC2MLOG Validation =="

if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi

SCAN_MINS="${SCAN_MINS:-1440}"                 # scan window (minutes)
ERR_THRESHOLD="${ERR_THRESHOLD:-50}"           # ERROR/FATAL lines above this = signal fires (tune to baseline)
rc=0

OUAF_LOGS="${SPLEBASE}/logs/system"
BATCH_LOGS="${SPLOUTPUT:-}"

# collect the set of recent log files to scan (OUAF + batch + WebLogic servers)
collect_logs() {
  [ -d "$OUAF_LOGS" ] && find "$OUAF_LOGS" -name 'spl*.log' -mmin "-${SCAN_MINS}" 2>/dev/null
  [ -n "$BATCH_LOGS" ] && [ -d "$BATCH_LOGS" ] && \
    find "$BATCH_LOGS" -name 'threadpoolworker.*.log' -mmin "-${SCAN_MINS}" 2>/dev/null
  if [ -n "${DOMAIN_HOME:-}" ] && [ -d "${DOMAIN_HOME}/servers" ]; then
    find "${DOMAIN_HOME}"/servers/*/logs -name '*.log' -mmin "-${SCAN_MINS}" 2>/dev/null
  fi
}

LOGSET="$(collect_logs)"

# --- Check 1: collection health (logs current and readable) ---
echo "-- Check: collection health (logs current) --"
if [ -z "$LOGSET" ]; then
  echo "  FAIL: no logs written within ${SCAN_MINS} min — collection gap / stale logs"
  rc=1
else
  echo "  PASS: $(echo "$LOGSET" | wc -l | tr -d ' ') log file(s) current within ${SCAN_MINS} min"
fi

# signal_scan <label> <pattern> <files...>  -> prints FIRED (with count) or clear
signal_scan() {
  label="$1"; pat="$2"; shift 2
  [ -z "$*" ] && { echo "  ${label}: (no logs in scope)"; return; }
  n="$(grep -Eil "$pat" "$@" 2>/dev/null | wc -l | tr -d ' ')"
  hits="$(grep -Eih "$pat" "$@" 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${hits:-0}" -gt 0 ]; then
    echo "  ${label}: FIRED — ${hits} line(s) in ${n} file(s)  [early warning]"
    return 1
  else
    echo "  ${label}: clear"
    return 0
  fi
}

echo
echo "-- Early-warning signals (C2M Health - Signals - EarlyWarning) --"

# error/exception rate (thresholded)
if [ -n "$LOGSET" ]; then
  errlines="$(grep -Eih '(^| )(ERROR|FATAL)( |\b)|Exception|at [a-z].*\(' $LOGSET 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${errlines:-0}" -gt "$ERR_THRESHOLD" ]; then
    echo "  Error/exception rate: FIRED — ${errlines} lines > threshold ${ERR_THRESHOLD}  [early warning]"; rc=1
  else
    echo "  Error/exception rate: clear (${errlines} lines <= threshold ${ERR_THRESHOLD})"
  fi
fi

# OutOfMemoryError / heap (WebLogic + OUAF)
signal_scan "OutOfMemoryError / heap" 'OutOfMemoryError|java\.lang\.OutOfMemoryError' $LOGSET || rc=1
# connection-pool exhaustion (WebLogic)
signal_scan "Connection-pool exhaustion" 'No resources currently available|pool.*(exhaust|maximum)|connection pool' $LOGSET || rc=1
# stuck threads (WebLogic)
signal_scan "Stuck threads" 'has been busy for .* seconds|STUCK|stuck thread' $LOGSET || rc=1

# batch failures / overruns (batch logs only)
if [ -n "$BATCH_LOGS" ] && [ -d "$BATCH_LOGS" ]; then
  BATCHSET="$(find "$BATCH_LOGS" -name 'threadpoolworker.*.log' -mmin "-${SCAN_MINS}" 2>/dev/null)"
  signal_scan "Batch failure / overrun" 'batch.*(error|fail)|ERROR|Exception' $BATCHSET || rc=1
else
  echo "  Batch failure / overrun: (SPLOUTPUT not set — skipped)"
fi

# --- Check: ECID present for cross-layer correlation ---
echo
echo "-- Check: ECID present (cross-layer correlation) --"
if [ -n "$LOGSET" ] && grep -Eiq '[0-9a-f]{8,}.*ECID|ECID' $LOGSET 2>/dev/null; then
  echo "  PASS: ECID field present in log lines (correlation possible)"
else
  echo "  NOTE: ECID not detected in sampled lines — verify the log format for your version"
fi

# --- Check: log-filesystem headroom ---
echo
echo "-- Check: log filesystem headroom --"
for d in "$OUAF_LOGS" "$BATCH_LOGS" "${DOMAIN_HOME:-}"; do
  [ -n "$d" ] && [ -d "$d" ] || continue
  use="$(df -P "$d" 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')"
  if [ -n "$use" ] && [ "$use" -ge 90 ]; then
    echo "  FAIL: ${d} on a filesystem ${use}% full — low headroom, remediate"; rc=1
  elif [ -n "$use" ]; then
    echo "  PASS: ${d} filesystem ${use}% used"
  fi
done

echo
if [ "$rc" -eq 0 ]; then
  echo "OVERALL: PASS — logs current, no signal fired, headroom OK."
else
  echo "OVERALL: attention — a signal FIRED or a check FAILED. Act on early warnings; remediate gaps and re-run."
fi
exit "$rc"
