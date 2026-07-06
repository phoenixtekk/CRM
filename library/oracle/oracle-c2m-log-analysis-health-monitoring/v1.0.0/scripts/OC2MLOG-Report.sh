# OC2MLOG-Report.sh — read-only daily health/SLO report from the C2M logs and early-warning signals.
#
# PURPOSE
#     Render the standing health view (C2M Health - Report - Daily): the health-check
#     results, which early-warning signals fired, and each SLO's status and remaining error
#     budget (availability, batch-completion, error-rate, log-freshness/coverage). It reads
#     an SLO definition file for targets and computes current status from the logs. Read-only
#     — it changes nothing. Run it daily during the pilot and in production.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MLOG-Report.sh
#     SLO targets file (default ./oc2mlog-slo.conf) lines:  SLO,TARGET_PCT,SOURCE
#       e.g.   availability,99.5,uptime-signal
#     Optional: DOMAIN_HOME=/path/to/your-domain to include WebLogic logs.
#
# EXPECTED RESULTS
#     Prints three sections: (1) health-check results, (2) early-warning signals fired,
#     (3) each SLO with target, current, status (MET/AT-RISK/BREACHED), and remaining error
#     budget. PASS = every SLO MET and no signal fired. Any AT-RISK/BREACHED or fired signal
#     is the early warning to act on.
#
# NOTES
#     White-label, repeatable report — the same view every day, every environment. Read-only
#     against live systems. Current-status figures are computed from the inventoried logs;
#     the actual availability numerator (up/down) comes from your uptime source — the file
#     lets you record it. Verify log paths/format for your version.

set -u

echo "============================================================"
echo " C2M Health - Report - Daily   ($(date '+%Y-%m-%d %H:%M'))"
echo "============================================================"

if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi

SCAN_MINS="${SCAN_MINS:-1440}"
SLO_FILE="${SLO_FILE:-./oc2mlog-slo.conf}"
OUAF_LOGS="${SPLEBASE}/logs/system"
BATCH_LOGS="${SPLOUTPUT:-}"

collect_logs() {
  [ -d "$OUAF_LOGS" ] && find "$OUAF_LOGS" -name 'spl*.log' -mmin "-${SCAN_MINS}" 2>/dev/null
  [ -n "$BATCH_LOGS" ] && [ -d "$BATCH_LOGS" ] && \
    find "$BATCH_LOGS" -name 'threadpoolworker.*.log' -mmin "-${SCAN_MINS}" 2>/dev/null
  [ -n "${DOMAIN_HOME:-}" ] && [ -d "${DOMAIN_HOME}/servers" ] && \
    find "${DOMAIN_HOME}"/servers/*/logs -name '*.log' -mmin "-${SCAN_MINS}" 2>/dev/null
}
LOGSET="$(collect_logs)"

count_pat() { [ -z "$LOGSET" ] && { echo 0; return; }; grep -Eih "$1" $LOGSET 2>/dev/null | wc -l | tr -d ' '; }

ERR=$(count_pat '(^| )(ERROR|FATAL)( |\b)|Exception')
OOM=$(count_pat 'OutOfMemoryError')
POOL=$(count_pat 'No resources currently available|connection pool')
STUCK=$(count_pat 'has been busy for .* seconds|STUCK')
if [ -n "$BATCH_LOGS" ] && [ -d "$BATCH_LOGS" ]; then
  BATCHSET="$(find "$BATCH_LOGS" -name 'threadpoolworker.*.log' -mmin "-${SCAN_MINS}" 2>/dev/null)"
  BATCHFAIL="$( [ -n "$BATCHSET" ] && grep -Eih 'batch.*(error|fail)|ERROR|Exception' $BATCHSET 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
else
  BATCHFAIL=0
fi

echo
echo "-- 1. Health checks (C2M Health - Checks - Standard) --"
[ -n "$LOGSET" ] && echo "   Collection: PASS ($(echo "$LOGSET" | wc -l | tr -d ' ') logs current in ${SCAN_MINS} min)" \
                 || echo "   Collection: FAIL (no current logs — collection gap)"
[ "$OOM" -eq 0 ]  && echo "   Container : PASS (no OutOfMemoryError)" || echo "   Container : FAIL (${OOM} OOM line(s))"
[ "$BATCHFAIL" -eq 0 ] && echo "   Batch     : PASS (no batch failures)" || echo "   Batch     : FAIL (${BATCHFAIL} batch failure line(s))"

echo
echo "-- 2. Early-warning signals fired --"
echo "   Error/exception lines : ${ERR}"
echo "   OutOfMemoryError      : ${OOM}"
echo "   Connection-pool       : ${POOL}"
echo "   Stuck threads         : ${STUCK}"
echo "   Batch failures        : ${BATCHFAIL}"

echo
echo "-- 3. SLOs (C2M SLO - Uptime - Standard) --"
if [ ! -f "$SLO_FILE" ]; then
  echo "   NOTE: SLO file not found: ${SLO_FILE}"
  echo "   Create it with one line per SLO:  SLO,TARGET_PCT,SOURCE"
  echo "     # SLO,TARGET_PCT,SOURCE"
  echo "     availability,99.5,uptime-source"
  echo "     batch-completion,99.0,threadpoolworker"
  echo "     error-rate,99.9,spl-weblogic"
  echo "     log-freshness,100,collection"
else
  printf "   %-18s %-8s %-9s %-11s %s\n" "SLO" "TARGET" "CURRENT" "STATUS" "BUDGET-LEFT"
  # CURRENT is recorded in the file's optional 4th field, or computed for coverage
  awk -F, -v errc="$ERR" -v batchf="$BATCHFAIL" -v haslogs="$( [ -n "$LOGSET" ] && echo 1 || echo 0 )" '
    /^[[:space:]]*#/ { next }
    NF < 2 { next }
    {
      slo=$1; gsub(/[[:space:]]/,"",slo)
      target=$2+0
      current=($4!=""?$4+0:"")
      # compute a current for coverage if not supplied
      if (current=="" && slo ~ /freshness|coverage/) current=(haslogs?100:0)
      if (current=="") { cur="n/a"; status="RECORD"; budget="n/a" }
      else {
        cur=sprintf("%.2f", current)
        if (current >= target)          { status="MET" }
        else if (current >= target-0.5) { status="AT-RISK" }
        else                            { status="BREACHED" }
        # remaining error budget = current - target (positive = budget left)
        budget=sprintf("%+.2f", current-target)
      }
      printf "   %-18s %-8s %-9s %-11s %s\n", slo, sprintf("%.2f",target), cur, status, budget
    }
  ' "$SLO_FILE"
  echo "   (CURRENT from the file's optional 4th field / your uptime source; coverage computed from log currency.)"
fi

echo
echo "============================================================"
echo " End of report. PASS = every SLO MET and no signal fired."
echo " Act on any AT-RISK/BREACHED SLO or fired signal — that is the early warning."
echo "============================================================"
