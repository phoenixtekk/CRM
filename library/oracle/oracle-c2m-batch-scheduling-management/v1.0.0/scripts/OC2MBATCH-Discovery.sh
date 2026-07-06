# OC2MBATCH-Discovery.sh — read-only discovery of C2M batch controls, thread pools, and recent run history.
#
# PURPOSE
#     Capture the current-state batch estate for an Oracle Utilities C2M environment:
#     the in-scope batch controls and their default thread counts, the thread pools and
#     thread counts currently configured on each worker node, and recent batch run
#     history (durations, failures) from the C2M schema. Read-only — it changes nothing.
#     Run it before sizing pools or building a schedule (Implementation Step 1).
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MBATCH-Discovery.sh
#     Optional: set DB_CONN=user/pass@your-db to include run-history from the schema.
#
# EXPECTED RESULTS
#     Prints: environment sourced OK and batch utilities on PATH; the configured thread
#     pools/counts from threadpoolworker.properties; and (if DB_CONN is set) the recent
#     batch run history and per-control defaults. PASS = environment sourced and pools
#     listed. FAIL = environment not sourced or utilities not found — fix before continuing.
#
# NOTES
#     White-label, repeatable discovery. Read-only where it reads live systems: it only
#     SELECTs from the schema and reads config files. Command/script names are from the
#     OUAF Server Administration Guide — verify exact names/flags for your version.

set -u

echo "== OC2MBATCH Discovery =="

# --- 1. Confirm the environment is sourced and utilities are on PATH ---
if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi
echo "PASS: environment sourced (SPLEBASE=${SPLEBASE})"

for util in threadpoolworker.sh submitbatchREST.sh jmxbatchclient.sh; do
  if command -v "$util" >/dev/null 2>&1 || [ -x "${SPLEBASE}/bin/${util}" ]; then
    echo "  found: ${util}"
  else
    echo "  MISSING: ${util} (verify utility name for your version)"
  fi
done

# --- 2. Report configured thread pools / counts from threadpoolworker.properties ---
TPW_PROPS="${SPLEBASE}/etc/threadpoolworker.properties"
echo
echo "-- Configured thread pools (threadpoolworker.properties) --"
if [ -f "$TPW_PROPS" ]; then
  # distributed threadpool thread limit and any pool sizing lines
  grep -E "distThreadPool|threads|threadpool|pool" "$TPW_PROPS" 2>/dev/null || echo "  (no pool lines matched — inspect ${TPW_PROPS})"
else
  echo "  NOTE: ${TPW_PROPS} not found — pools may be set at startup via  threadpoolworker.sh -p NAME=count,..."
fi

# --- 3. Optional: recent batch run history and per-control defaults from the schema ---
if [ -n "${DB_CONN:-}" ]; then
  echo
  echo "-- Recent batch run history (read-only) --"
  sqlplus -s "$DB_CONN" <<'SQL'
set pagesize 50 linesize 160 feedback off
prompt Batch controls and default thread counts (top 25 by recent activity):
SELECT batch_cd, MAX(thread_cnt) AS max_threads, COUNT(*) AS runs
  FROM ci_batch_inst
 WHERE batch_nbr >= 0
 GROUP BY batch_cd
 ORDER BY runs DESC
 FETCH FIRST 25 ROWS ONLY;
prompt
prompt Most recent 25 batch runs (status, duration):
SELECT batch_cd, batch_nbr, batch_thread_nbr, batch_thread_stat_flg AS status,
       start_dttm, end_dttm
  FROM ci_batch_inst
 ORDER BY start_dttm DESC
 FETCH FIRST 25 ROWS ONLY;
SQL
else
  echo
  echo "NOTE: set DB_CONN=user/pass@your-db to include batch run history and per-control defaults."
fi

echo
echo "Discovery complete. Record gaps against the Requirements Guide checklist."
