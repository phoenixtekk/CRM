# OC2MHYPER-Remediation.sh — align safe operational hypercare settings to the standard (DRY-RUN by default).
#
# PURPOSE
#     Print (and, only when explicitly asked, apply) safe operational alignments that hypercare
#     commonly needs: the batch-worker restart guidance, log/space cleanup targets when the
#     daily health snapshot is amber/red on space, and the health-threshold config used by the
#     report scripts. DRY-RUN by default: it prints the exact change it WOULD make and changes
#     nothing. It never touches business logic and never restarts a running server itself.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MHYPER-Remediation.sh                     # DRY-RUN: prints intended actions only
#         ./OC2MHYPER-Remediation.sh --apply             # applies safe file writes (change window only)
#     Override thresholds:  TS_PCT=85 LOG_RETAIN_DAYS=14 ./OC2MHYPER-Remediation.sh
#
# EXPECTED RESULTS
#     DRY-RUN prints: the standard health thresholds, the log/space cleanup targets (old log
#     files beyond retention), and the exact worker restart command the admin must run — and
#     exits without changing anything. With --apply it writes the health-threshold config file
#     (backing up any existing one) and prints the cleanup and restart steps for the admin to
#     perform under change control. It never deletes files or restarts services itself.
#
# NOTES
#     White-label, repeatable remediation — DRY-RUN by default so it is safe to run anywhere.
#     It aligns only operational settings and prints manual steps for anything impacting a
#     running service; it never changes business data or logic. Utility names are from the OUAF
#     Server Administration Guide — verify for your version.

set -u

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

TS_PCT="${TS_PCT:-85}"                      # tablespace % used that flags amber/red
LOG_RETAIN_DAYS="${LOG_RETAIN_DAYS:-14}"    # keep log files this many days
BACKLOG_MAX="${BACKLOG_MAX:-0}"             # acceptable post-cycle backlog

echo "== OC2MHYPER Remediation =="
if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi

THRESH_FILE="${RUNBOOK_DIR:-./runbook}/health-thresholds.conf"
LOG_DIR="${LOG_DIR:-${SPLEBASE}/logs}"

echo "Standard health thresholds: tablespace_pct=${TS_PCT}  log_retain_days=${LOG_RETAIN_DAYS}  backlog_max=${BACKLOG_MAX}"
echo "Threshold config file: ${THRESH_FILE}"
echo

# --- 1. Log/space cleanup targets (print only; never deletes) ---
echo "-- Log cleanup targets (older than ${LOG_RETAIN_DAYS} days) --"
if [ -d "$LOG_DIR" ]; then
  n=$(find "$LOG_DIR" -type f -mtime +"$LOG_RETAIN_DAYS" 2>/dev/null | wc -l | tr -d ' ')
  echo "  ${n} log file(s) older than ${LOG_RETAIN_DAYS} days in ${LOG_DIR}"
  echo "  Intended admin action (change window): archive/remove these after confirming they are not in use, e.g.:"
  echo "    find ${LOG_DIR} -type f -mtime +${LOG_RETAIN_DAYS} -print   # review, then archive"
else
  echo "  NOTE: set LOG_DIR=... to compute log cleanup targets"
fi

# --- 2. Worker restart guidance (print only; never restarts) ---
echo
echo "-- Batch worker restart guidance --"
echo "  If the health snapshot shows the worker down, the admin restarts it in the change window, e.g.:"
echo "    threadpoolworker.sh -p your-pool=your-count      # verify flags/pools for your version"
echo "  Then re-run OC2MHYPER-Validation.sh and OC2MHYPER-Report.sh to confirm GREEN."

# --- 3. Health-threshold config ---
echo
echo "-- Health-threshold config --"
echo "  Intended contents:"
echo "    tablespace_pct=${TS_PCT}"
echo "    log_retain_days=${LOG_RETAIN_DAYS}"
echo "    backlog_max=${BACKLOG_MAX}"

if [ "$APPLY" -eq 0 ]; then
  echo
  echo "DRY-RUN: no changes made. Re-run with --apply in a change window to write the threshold config."
  exit 0
fi

# --- Apply (change window only): writes the threshold config file, backing up any existing one ---
echo
echo "APPLY: writing health-threshold config (backup first)..."
mkdir -p "$(dirname "$THRESH_FILE")"
if [ -f "$THRESH_FILE" ]; then
  cp -p "$THRESH_FILE" "${THRESH_FILE}.bak.$(date +%Y%m%d%H%M%S)"
  echo "  backed up ${THRESH_FILE}"
fi
{
  echo "# Written by OC2MHYPER-Remediation.sh on $(date)"
  echo "tablespace_pct=${TS_PCT}"
  echo "log_retain_days=${LOG_RETAIN_DAYS}"
  echo "backlog_max=${BACKLOG_MAX}"
} > "$THRESH_FILE"
echo "  wrote ${THRESH_FILE}"
echo
echo "NEXT (admin, in the change window): perform any printed log-cleanup / worker-restart steps above,"
echo "then re-run OC2MHYPER-Validation.sh and OC2MHYPER-Report.sh to confirm GREEN."
