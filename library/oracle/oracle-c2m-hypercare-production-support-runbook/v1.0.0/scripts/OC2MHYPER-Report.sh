# OC2MHYPER-Report.sh — read-only daily health snapshot and open-incident / known-issue summary.
#
# PURPOSE
#     Render the operational side of the daily health routine (C2M Runbook - Health - Daily
#     Routine): WebLogic server presence, the batch worker and its live JMX summary, error/
#     fatal log deltas since yesterday, and the current open-incident and known-issue summary
#     read from the runbook files. Read-only — it reads live signals and text files, changing
#     nothing. Run it each hypercare morning; pair it with OC2MHYPER-Report.sql for DB detail.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MHYPER-Report.sh
#     Optional: JMX_URL=service:jmx:rmi:///jndi/rmi://your-host:your-jmx-port/oracle/ouaf/batchConnector
#     Optional: RUNBOOK_DIR=./runbook  (dir holding incident/known-issue registers)
#     Optional: LOG_DIR=path  (OUAF/WebLogic log dir; defaults to your-splebase/logs)
#
# EXPECTED RESULTS
#     Prints a green/amber/red-style snapshot: batch worker running (or not), JMX live-thread
#     summary, count of new ERROR/FATAL log lines since yesterday, and the open-incident /
#     known-issue counts from the registers. GREEN = worker up, JMX clean, no new errors, no
#     open Sev-1/Sev-2. Any amber/red line is a candidate incident. Attach the snapshot to the
#     shift handover.
#
# NOTES
#     White-label, repeatable health snapshot — the same morning routine every day of hypercare.
#     Read-only where it reads live systems (JMX summary, log scan) and text registers. Utility
#     and connector names are from the OUAF Server Administration Guide — verify for your version.

set -u

echo "== OC2MHYPER Health Report =="
date

if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi

# --- 1. Batch worker presence ---
echo
echo "-- Batch worker --"
if command -v pgrep >/dev/null 2>&1 && pgrep -f "threadpoolworker" >/dev/null 2>&1; then
  echo "  GREEN: threadpoolworker running"
else
  echo "  RED: no threadpoolworker running — open an incident"
fi

# --- 2. JMX live-thread summary ---
echo
echo "-- JMX live batch threads --"
if [ -n "${JMX_URL:-}" ] && { command -v jmxbatchclient.sh >/dev/null 2>&1 || [ -x "${SPLEBASE}/bin/jmxbatchclient.sh" ]; }; then
  if jmxbatchclient.sh -j "$JMX_URL" -s 2>/dev/null; then
    echo "  GREEN: JMX summary returned (review for stuck threads)"
  else
    echo "  AMBER: JMX summary did not return — confirm the connector URL/port"
  fi
else
  echo "  NOTE: set JMX_URL=service:jmx:rmi:///jndi/rmi://your-host:your-jmx-port/oracle/ouaf/batchConnector to include live threads"
fi

# --- 3. Error/fatal log delta since yesterday ---
echo
echo "-- New ERROR/FATAL log lines (last 24h) --"
LOG_DIR="${LOG_DIR:-${SPLEBASE}/logs}"
if [ -d "$LOG_DIR" ]; then
  # Count matching lines in files modified in the last day; a spike is an amber/red signal.
  count=$(find "$LOG_DIR" -type f -mtime -1 2>/dev/null -exec grep -Eic "ERROR|FATAL" {} + 2>/dev/null | awk -F: '{s+=$NF} END{print s+0}')
  echo "  matched ERROR/FATAL occurrences: ${count}"
  if [ "${count:-0}" -eq 0 ]; then
    echo "  GREEN: no new errors"
  else
    echo "  AMBER: review the error delta and correlate with any incident"
  fi
else
  echo "  NOTE: set LOG_DIR=... to scan the OUAF/WebLogic logs"
fi

# --- 4. Open incidents / known issues from the registers ---
echo
echo "-- Open incidents / known issues --"
RUNBOOK_DIR="${RUNBOOK_DIR:-./runbook}"
INC="${RUNBOOK_DIR}/incident-log.md"
KI="${RUNBOOK_DIR}/knownissue-register.md"

if [ -f "$INC" ]; then
  # Convention: open incidents are lines tagged OPEN with a severity token (SEV1..SEV4).
  sev1=$(grep -Eic "OPEN.*SEV1|SEV1.*OPEN" "$INC" 2>/dev/null || echo 0)
  sev2=$(grep -Eic "OPEN.*SEV2|SEV2.*OPEN" "$INC" 2>/dev/null || echo 0)
  openall=$(grep -Eic "\bOPEN\b" "$INC" 2>/dev/null || echo 0)
  echo "  incidents: open=${openall}  sev1=${sev1}  sev2=${sev2}"
  if [ "${sev1:-0}" -eq 0 ] && [ "${sev2:-0}" -eq 0 ]; then
    echo "  GREEN: no open Sev-1/Sev-2"
  else
    echo "  RED: open Sev-1/Sev-2 — hypercare exit gate not met"
  fi
else
  echo "  NOTE: set RUNBOOK_DIR with incident-log.md (lines tagged OPEN + SEV1..SEV4) to summarize incidents"
fi

if [ -f "$KI" ]; then
  ki=$(grep -Eic "^\s*[-|]" "$KI" 2>/dev/null || echo 0)
  echo "  known-issue register entries: ${ki}"
else
  echo "  NOTE: add knownissue-register.md to summarize known issues/workarounds"
fi

echo
echo "Health snapshot complete. Pair with OC2MHYPER-Report.sql for batch/integration/DB detail; attach to the shift handover."
