# OC2MLOG-Discovery.sh — read-only discovery of the C2M log landscape (OUAF, WebLogic, batch) and health signals.
#
# PURPOSE
#     Inventory the logs for an Oracle Utilities C2M environment across all three layers:
#     the OUAF application logs (your-splebase/logs/system, spl*.log), the WebLogic server
#     and domain logs (under your-domain-home/servers), and the batch logs
#     (your-sploutput, the threadpoolworker per-pool tech and user logs). For each it
#     reports the newest file, count, and directory size, and whether the log is current.
#     Read-only — it changes nothing. Run it before defining checks or SLOs (Step 1).
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MLOG-Discovery.sh
#     Optional: set DOMAIN_HOME=/path/to/your-domain to inventory the WebLogic logs.
#
# EXPECTED RESULTS
#     Prints, per layer, the log directory, newest file + age, file count, and directory
#     size. PASS = SPLEBASE/SPLOUTPUT resolve and each layer's log directory is present and
#     readable with a current file. FAIL = environment not sourced or a log layer missing/
#     unreadable — fix before continuing.
#
# NOTES
#     White-label, repeatable discovery — the same inventory every environment. Read-only
#     where it reads live systems: it only lists and stats log files. Log paths and the
#     threadpoolworker file-name pattern are from the OUAF/C2M Server Administration Guides
#     and the WebLogic logging docs — verify exact paths/names for your version.

set -u

echo "== OC2MLOG Discovery =="

# --- 1. Confirm the environment is sourced ---
if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi
echo "PASS: environment sourced (SPLEBASE=${SPLEBASE})"
echo "      SPLOUTPUT=${SPLOUTPUT:-<not set>}"
echo "      DOMAIN_HOME=${DOMAIN_HOME:-<not set — set it to inventory WebLogic logs>}"

# how recent (minutes) a newest log must be to count as "current"
CURRENT_MINS="${CURRENT_MINS:-1440}"   # 24h default

# report_dir <label> <dir> <glob>
report_dir() {
  label="$1"; dir="$2"; glob="$3"
  echo
  echo "-- ${label} --"
  echo "   dir: ${dir}"
  if [ ! -d "$dir" ]; then
    echo "   MISSING: directory not found (verify path for your version)"
    return 1
  fi
  if [ ! -r "$dir" ]; then
    echo "   UNREADABLE: no read access — grant read or run as the product user"
    return 1
  fi
  # newest matching file
  newest="$(ls -1t ${dir}/${glob} 2>/dev/null | head -1)"
  count="$(ls -1 ${dir}/${glob} 2>/dev/null | wc -l | tr -d ' ')"
  if [ -z "$newest" ]; then
    echo "   files: 0 matching '${glob}' — NOTE: no current log (blind spot?)"
  else
    echo "   files: ${count} matching '${glob}'"
    echo "   newest: ${newest}"
    # currency check (find newer-than CURRENT_MINS)
    if find "$newest" -mmin "-${CURRENT_MINS}" >/dev/null 2>&1 && \
       [ -n "$(find "$newest" -mmin "-${CURRENT_MINS}" 2>/dev/null)" ]; then
      echo "   currency: CURRENT (written within ${CURRENT_MINS} min)"
    else
      echo "   currency: STALE (older than ${CURRENT_MINS} min) — possible collection gap"
    fi
  fi
  # directory size
  du -sh "$dir" 2>/dev/null | awk '{print "   size: "$1}'
}

rc=0

# --- 2. OUAF application logs ---
report_dir "OUAF application logs (spl*.log)" "${SPLEBASE}/logs/system" "spl*.log" || rc=1

# --- 3. Batch / background-processing logs ---
if [ -n "${SPLOUTPUT:-}" ]; then
  report_dir "Batch logs (threadpoolworker.*)" "${SPLOUTPUT}" "threadpoolworker.*.log" || rc=1
else
  echo
  echo "-- Batch logs --"
  echo "   NOTE: SPLOUTPUT not set — cannot inventory batch logs."
fi

# --- 4. WebLogic server + domain logs ---
if [ -n "${DOMAIN_HOME:-}" ]; then
  echo
  echo "-- WebLogic server logs (per managed server) --"
  if [ -d "${DOMAIN_HOME}/servers" ] && [ -r "${DOMAIN_HOME}/servers" ]; then
    for srv in "${DOMAIN_HOME}"/servers/*/; do
      [ -d "${srv}logs" ] || continue
      name="$(basename "$srv")"
      report_dir "server: ${name}" "${srv}logs" "*.log" || rc=1
    done
  else
    echo "   MISSING/UNREADABLE: ${DOMAIN_HOME}/servers — confirm DOMAIN_HOME and read access"
    rc=1
  fi
else
  echo
  echo "-- WebLogic logs --"
  echo "   NOTE: DOMAIN_HOME not set — set it to inventory server/domain logs."
fi

echo
if [ "$rc" -eq 0 ]; then
  echo "Discovery complete: all inventoried layers present and readable."
else
  echo "Discovery complete WITH GAPS: record each missing/unreadable/stale layer against the Requirements checklist."
fi
echo "Next: build C2M Log - Inventory - All Layers from this output, then define checks and signals."
exit "$rc"
