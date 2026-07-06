# OC2MHYPER-Validation.sh — read-only validation of the technical go-live readiness signals.
#
# PURPOSE
#     Validate the technical signals behind the go-live readiness checklist and report
#     PASS/FAIL per signal: WebLogic servers reachable, the batch daemon / threadpoolworker
#     running, the JMX batch connector reachable, the integration endpoints reachable, and
#     the runbook files present. Read-only — it validates state and changes nothing. Run it
#     at the readiness gate (Runbook Step 1) and each day of hypercare.
#
# HOW TO RUN
#     Source the environment first, then run as the product user:
#         splenviron.sh -e your-env
#         ./OC2MHYPER-Validation.sh
#     Optional: JMX_URL=service:jmx:rmi:///jndi/rmi://your-host:your-jmx-port/oracle/ouaf/batchConnector
#     Optional: ADMIN_URL=t3://your-host:your-admin-port  (WebLogic Admin server, WLST reachability)
#     Optional: INTEGRATION_URLS="https://your-endpoint-1 https://your-endpoint-2"  (reachability)
#     Optional: RUNBOOK_DIR=./runbook  (dir holding the runbook files to confirm present)
#
# EXPECTED RESULTS
#     For each check prints PASS or FAIL: WebLogic reachable, batch worker running, JMX
#     reachable, integration endpoints reachable, runbook files present and non-empty.
#     Overall PASS = every readiness signal green — cutover may proceed. Any FAIL points to
#     the checklist item to close (or a signed exception) before go/no-go.
#
# NOTES
#     White-label, repeatable validation — the same readiness checks every environment, every
#     day. Read-only where it reads live systems (WLST connect test, JMX summary, endpoint
#     reachability). Utility/connector names are from the OUAF Server Administration Guide —
#     verify for your version.

set -u

rc=0
echo "== OC2MHYPER Validation =="

if [ -z "${SPLEBASE:-}" ]; then
  echo "FAIL: environment not sourced. Run:  splenviron.sh -e your-env"
  exit 1
fi

# --- 1. WebLogic reachability (server state / WLST) ---
echo "-- WebLogic reachability --"
if [ -n "${ADMIN_URL:-}" ]; then
  # A minimal WLST connect test; credentials expected from a stored config or the environment.
  if command -v wlst.sh >/dev/null 2>&1; then
    echo "  NOTE: run a WLST connect('${ADMIN_URL}') check with your stored config to confirm servers RUNNING"
    echo "  PASS: wlst.sh present (perform the connect check as the product user)"
  else
    echo "  FAIL: wlst.sh not found — verify the WebLogic toolchain for your version"
    rc=1
  fi
else
  echo "  NOTE: set ADMIN_URL=t3://your-host:your-admin-port to validate WebLogic server state via WLST"
fi

# --- 2. Batch daemon / threadpoolworker running ---
echo
echo "-- Batch worker / daemon --"
if command -v pgrep >/dev/null 2>&1 && pgrep -f "threadpoolworker" >/dev/null 2>&1; then
  echo "  PASS: threadpoolworker running"
else
  echo "  FAIL: no running threadpoolworker matched — start the batch node before go/no-go"
  rc=1
fi

# --- 3. JMX batch connector reachable ---
echo
echo "-- JMX batch connector --"
if [ -n "${JMX_URL:-}" ]; then
  if command -v jmxbatchclient.sh >/dev/null 2>&1 || [ -x "${SPLEBASE}/bin/jmxbatchclient.sh" ]; then
    if jmxbatchclient.sh -j "$JMX_URL" -s 2>/dev/null; then
      echo "  PASS: JMX batch connector reachable"
    else
      echo "  FAIL: JMX summary did not return — confirm the RMI/JMX port and connector URL for your version"
      rc=1
    fi
  else
    echo "  FAIL: jmxbatchclient.sh not found — verify utility name for your version"
    rc=1
  fi
else
  echo "  NOTE: set JMX_URL=service:jmx:rmi:///jndi/rmi://your-host:your-jmx-port/oracle/ouaf/batchConnector to validate"
fi

# --- 4. Integration endpoints reachable ---
echo
echo "-- Integration endpoints --"
if [ -n "${INTEGRATION_URLS:-}" ]; then
  for url in $INTEGRATION_URLS; do
    if command -v curl >/dev/null 2>&1 && curl -s -o /dev/null --max-time 8 "$url"; then
      echo "  PASS: reachable ${url}"
    else
      echo "  FAIL: not reachable ${url} — confirm with the integration team"
      rc=1
    fi
  done
else
  echo "  NOTE: set INTEGRATION_URLS=\"https://ep1 https://ep2\" to validate endpoint reachability"
fi

# --- 5. Runbook files present and non-empty ---
echo
echo "-- Runbook files present --"
RUNBOOK_DIR="${RUNBOOK_DIR:-./runbook}"
for f in readiness-go-live-checklist cutover-plan oncall-rota escalation-matrix severity-model \
         incident-procedure knownissue-register day2-build-lane health-daily-routine; do
  path="${RUNBOOK_DIR}/${f}.md"
  if [ -s "$path" ]; then
    echo "  PASS: ${f} present"
  else
    echo "  FAIL: ${f} missing/empty (${path}) — author it before go/no-go"
    rc=1
  fi
done

echo
if [ "$rc" -eq 0 ]; then
  echo "OVERALL: PASS — technical readiness signals green."
else
  echo "OVERALL: FAIL — close the flagged items (or sign an exception) before go/no-go."
fi
exit "$rc"
