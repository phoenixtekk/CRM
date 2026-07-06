# OC2MHYPER-Discovery.sh — read-only discovery of C2M go-live readiness and health current state.
#
# PURPOSE
#     Capture the current state that backs the go-live readiness checklist and the daily
#     health routine for an Oracle Utilities C2M environment: WebLogic server state, the
#     batch daemon / threadpoolworker, the JMX batch connector, configured integrations,
#     backup presence, and the monitoring signals. Read-only — it changes nothing. Run it
#     before building the readiness checklist (Runbook Step 1) and each hypercare morning.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MHYPER-Discovery.sh
#     Optional: DB_CONN=user/pass@your-db to include batch/integration status from the schema.
#     Optional: JMX_URL=service:jmx:rmi:///jndi/rmi://your-host:your-jmx-port/oracle/ouaf/batchConnector
#
# EXPECTED RESULTS
#     Prints: environment sourced OK and OUAF/WebLogic utilities on PATH; the batch daemon /
#     threadpoolworker presence; the JMX batch connector reachability (if JMX_URL set); the
#     configured log locations and recent backup presence; and (if DB_CONN set) recent batch
#     run status. PASS = environment sourced and signals collected. FAIL = environment not
#     sourced or utilities not found — fix before continuing.
#
# NOTES
#     White-label, repeatable discovery — the same current-state capture every environment and
#     every hypercare morning. Read-only where it reads live systems: it only SELECTs from the
#     schema, queries JMX with a summary action, and reads config/log paths. Utility and
#     connector names are from the OUAF Server Administration Guide — verify for your version.

set -u

echo "== OC2MHYPER Discovery =="

# --- 1. Confirm the environment is sourced and utilities are on PATH ---
if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi
echo "PASS: environment sourced (SPLEBASE=${SPLEBASE})"

for util in threadpoolworker.sh starttpw.sh jmxbatchclient.sh; do
  if command -v "$util" >/dev/null 2>&1 || [ -x "${SPLEBASE}/bin/${util}" ]; then
    echo "  found: ${util}"
  else
    echo "  NOTE: ${util} not found on PATH/bin (verify utility name for your version)"
  fi
done

# --- 2. Batch daemon / threadpoolworker process presence (health readiness) ---
echo
echo "-- Batch worker / daemon presence --"
if command -v pgrep >/dev/null 2>&1 && pgrep -f "threadpoolworker" >/dev/null 2>&1; then
  echo "  PASS: a threadpoolworker process is running"
else
  echo "  NOTE: no running threadpoolworker matched — confirm the batch node is started for cutover/hypercare"
fi

# --- 3. JMX batch connector reachability (live batch threads) ---
echo
echo "-- JMX batch connector --"
if [ -n "${JMX_URL:-}" ]; then
  if command -v jmxbatchclient.sh >/dev/null 2>&1 || [ -x "${SPLEBASE}/bin/jmxbatchclient.sh" ]; then
    if jmxbatchclient.sh -j "$JMX_URL" -s 2>/dev/null; then
      echo "  PASS: JMX batch connector reachable, summary returned"
    else
      echo "  NOTE: JMX summary did not return — confirm the RMI/JMX port and connector URL for your version"
    fi
  else
    echo "  NOTE: jmxbatchclient.sh not found — verify utility name for your version"
  fi
else
  echo "  NOTE: set JMX_URL=service:jmx:rmi:///jndi/rmi://your-host:your-jmx-port/oracle/ouaf/batchConnector to probe live threads"
fi

# --- 4. Log locations and backup presence (readiness signals) ---
echo
echo "-- Log locations --"
for d in "${SPLEBASE}/logs" "${SPLEBASE}/splapp/applications" "${SPLOUTPUT:-}"; do
  [ -n "$d" ] && [ -d "$d" ] && echo "  present: $d"
done
echo
echo "-- Recent backup presence (readiness) --"
BK_DIR="${BACKUP_DIR:-${SPLEBASE}/backup}"
if [ -d "$BK_DIR" ]; then
  echo "  backup dir: ${BK_DIR}"
  ls -1t "$BK_DIR" 2>/dev/null | head -5 | sed 's/^/    /' || true
else
  echo "  NOTE: set BACKUP_DIR=... to confirm pre-cutover backups exist"
fi

# --- 5. Optional: recent batch run status from the schema (health) ---
if [ -n "${DB_CONN:-}" ]; then
  echo
  echo "-- Recent batch run status (read-only) --"
  sqlplus -s "$DB_CONN" <<'SQL'
set pagesize 40 linesize 160 feedback off
prompt Most recent 15 batch threads (control, status, times):
SELECT batch_cd, batch_nbr, batch_thread_nbr, batch_thread_stat_flg AS status,
       start_dttm, end_dttm
  FROM ci_batch_inst
 ORDER BY start_dttm DESC
 FETCH FIRST 15 ROWS ONLY;
SQL
else
  echo
  echo "NOTE: set DB_CONN=user/pass@your-db to include recent batch run status."
fi

echo
echo "Discovery complete. Record gaps against the go-live readiness checklist."
