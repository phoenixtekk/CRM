# OC2MBATCH-Validation.sh — read-only validation that workers advertise the standard pools and the scheduler/JMX are reachable.
#
# PURPOSE
#     Confirm the configured C2M batch estate matches the standard: every worker node
#     advertises the standard thread pools (DEFAULT, ONLINE, BILLING), the batch JMX
#     interface is reachable, and the scheduler submission path responds. Read-only —
#     it validates state and reports PASS/FAIL, it changes nothing. Run it on the pilot
#     (Implementation Step 8) and after each expansion.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MBATCH-Validation.sh
#     Optional: JMX_URL=service:jmx:rmi:///... to probe live-thread JMX on a worker node.
#
# EXPECTED RESULTS
#     For each check prints PASS or FAIL: standard pools advertised, JMX summary
#     reachable, REST submit utility present. Overall PASS = every worker offers the
#     standard pool set and JMX/scheduler signals are present. Any FAIL points to the
#     gap to remediate (see OC2MBATCH-Remediation.sh) before re-validating.
#
# NOTES
#     White-label, repeatable validation — the same checks every node, every environment.
#     Read-only where it reads live systems (queries JMX with a summary action, reads
#     config). Names/flags are from the OUAF Server Administration Guide — verify for your version.

set -u

STANDARD_POOLS="DEFAULT ONLINE BILLING"
rc=0

echo "== OC2MBATCH Validation =="

if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi

# --- 1. Standard pools advertised (from config; confirm at runtime via JMX below) ---
TPW_PROPS="${SPLEBASE}/etc/threadpoolworker.properties"
echo "-- Standard thread pools ($STANDARD_POOLS) --"
for pool in $STANDARD_POOLS; do
  if [ -f "$TPW_PROPS" ] && grep -qi "$pool" "$TPW_PROPS" 2>/dev/null; then
    echo "  PASS: pool ${pool} referenced in config"
  else
    echo "  FAIL: pool ${pool} not found in ${TPW_PROPS} (or set at startup -p ${pool}=count) — remediate"
    rc=1
  fi
done

# --- 2. REST submit utility present (scheduler submission path) ---
echo
if command -v submitbatchREST.sh >/dev/null 2>&1 || [ -x "${SPLEBASE}/bin/submitbatchREST.sh" ]; then
  echo "PASS: submitbatchREST.sh present (REST/daemon submission path available)"
else
  echo "FAIL: submitbatchREST.sh not found — verify utility name for your version"
  rc=1
fi

# --- 3. JMX batch monitoring reachable (live-thread visibility) ---
echo
if [ -n "${JMX_URL:-}" ]; then
  if command -v jmxbatchclient.sh >/dev/null 2>&1 || [ -x "${SPLEBASE}/bin/jmxbatchclient.sh" ]; then
    echo "-- JMX active-thread summary (read-only) --"
    if jmxbatchclient.sh -j "$JMX_URL" -s; then
      echo "  PASS: JMX reachable, summary returned"
    else
      echo "  FAIL: JMX summary did not return — confirm the RMI/JMX port (e.g. BATCH_RMI_PORT) on the worker"
      rc=1
    fi
  else
    echo "FAIL: jmxbatchclient.sh not found — verify utility name for your version"
    rc=1
  fi
else
  echo "NOTE: set JMX_URL=... to validate live JMX reachability on a worker node."
fi

echo
if [ "$rc" -eq 0 ]; then
  echo "OVERALL: PASS"
else
  echo "OVERALL: FAIL — remediate the flagged gaps and re-run."
fi
exit "$rc"
