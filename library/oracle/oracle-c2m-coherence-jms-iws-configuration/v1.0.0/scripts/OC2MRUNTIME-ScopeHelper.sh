#!/bin/sh
# OC2MRUNTIME-ScopeHelper.sh — resolve and export the C2M runtime target scope for the other scripts.
#
# PURPOSE
#     Centralise the connection details, expected object names, and in-scope server list so
#     the WLST scripts (Discovery, Validation, Report, Remediation) act only where intended
#     and use identical names across environments. Reads values from your environment or a
#     small config file, validates them, and prints export lines you can source. Reuses the
#     solution reference names by default; override per environment (your-env-config).
#
# HOW TO RUN
#     Print the resolved scope:      sh ./OC2MRUNTIME-ScopeHelper.sh
#     Load it into your shell:       . ./OC2MRUNTIME-ScopeHelper.sh --export
#     With a config file:            sh ./OC2MRUNTIME-ScopeHelper.sh --config myenv.conf
#     Then run e.g.:                 java weblogic.WLST OC2MRUNTIME-Validation.py
#
# EXPECTED RESULTS
#     Prints the resolved OC2M_* variables and a PASS/FAIL readiness check (admin URL set,
#     scope servers set, iwsdeploy present). Exit 0 when ready to run the WLST scripts;
#     exit 1 if a required value is missing so a pipeline stops before acting out of scope.
#
# NOTES
#     White-label, repeatable. Helper only: it neither connects nor changes anything — it
#     just resolves scope and env vars. Set OC2M_APPLY only when you intend Remediation to
#     write; it defaults to false so the runtime stays dry-run safe.

set -u

CONFIG=""
DO_EXPORT="no"
while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --export) DO_EXPORT="yes"; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

# Optional config file with KEY=VALUE lines (no secrets in version control).
if [ -n "$CONFIG" ]; then
  if [ ! -f "$CONFIG" ]; then
    echo "ERROR: config file not found: $CONFIG" >&2
    exit 2
  fi
  # shellcheck disable=SC1090
  . "$CONFIG"
fi

# ---- Resolve values (env or reference defaults) ----------------------------
OC2M_ADMIN_URL="${OC2M_ADMIN_URL:-t3://your-admin-host:7001}"
OC2M_ADMIN_USER="${OC2M_ADMIN_USER:-your-weblogic-admin}"
# Password should come from the environment or a secured prompt, never a committed file.
OC2M_ADMIN_PASS="${OC2M_ADMIN_PASS:-}"

OC2M_SCOPE_SERVERS="${OC2M_SCOPE_SERVERS:-}"       # comma-separated managed servers in scope
OC2M_JMS_TARGET="${OC2M_JMS_TARGET:-your-managed-server}"

OC2M_EXPECT_CLUSTER="${OC2M_EXPECT_CLUSTER:-c2m-coherence-cluster}"
OC2M_COHERENCE_PORT="${OC2M_COHERENCE_PORT:-7574}"  # verify for your version
OC2M_EXPECT_JMSSERVER="${OC2M_EXPECT_JMSSERVER:-C2MJMSServer}"
OC2M_EXPECT_JMSMODULE="${OC2M_EXPECT_JMSMODULE:-C2MJMSModule}"
OC2M_EXPECT_CF_JNDI="${OC2M_EXPECT_CF_JNDI:-jms/C2MConnectionFactory}"
OC2M_EXPECT_QUEUE_JNDI="${OC2M_EXPECT_QUEUE_JNDI:-jms/C2MRealTimeQueue}"
OC2M_TOPIC_JNDI="${OC2M_TOPIC_JNDI:-jms/C2MEventTopic}"
OC2M_SUBDEPLOYMENT="${OC2M_SUBDEPLOYMENT:-C2MJMSSubDeployment}"
OC2M_EXPECT_IWS="${OC2M_EXPECT_IWS:-spl-web-services}"

# Remediation stays dry-run unless explicitly enabled.
OC2M_APPLY="${OC2M_APPLY:-false}"

# SPLEBASE lets us confirm the OUAF iwsdeploy utility is reachable for IWS deployment.
SPLEBASE="${SPLEBASE:-}"

# ---- Emit resolved scope ---------------------------------------------------
emit() {
  echo "OC2M_ADMIN_URL=$OC2M_ADMIN_URL"
  echo "OC2M_ADMIN_USER=$OC2M_ADMIN_USER"
  echo "OC2M_SCOPE_SERVERS=$OC2M_SCOPE_SERVERS"
  echo "OC2M_JMS_TARGET=$OC2M_JMS_TARGET"
  echo "OC2M_EXPECT_CLUSTER=$OC2M_EXPECT_CLUSTER"
  echo "OC2M_COHERENCE_PORT=$OC2M_COHERENCE_PORT"
  echo "OC2M_EXPECT_JMSSERVER=$OC2M_EXPECT_JMSSERVER"
  echo "OC2M_EXPECT_JMSMODULE=$OC2M_EXPECT_JMSMODULE"
  echo "OC2M_EXPECT_CF_JNDI=$OC2M_EXPECT_CF_JNDI"
  echo "OC2M_EXPECT_QUEUE_JNDI=$OC2M_EXPECT_QUEUE_JNDI"
  echo "OC2M_TOPIC_JNDI=$OC2M_TOPIC_JNDI"
  echo "OC2M_SUBDEPLOYMENT=$OC2M_SUBDEPLOYMENT"
  echo "OC2M_EXPECT_IWS=$OC2M_EXPECT_IWS"
  echo "OC2M_APPLY=$OC2M_APPLY"
}

echo "== C2M RUNTIME SCOPE =="
emit

# ---- Readiness checks ------------------------------------------------------
echo ""
echo "== READINESS =="
READY=0

case "$OC2M_ADMIN_URL" in
  *your-admin-host*|"") echo "[FAIL] OC2M_ADMIN_URL not set to a real admin URL"; READY=1 ;;
  *) echo "[PASS] admin URL set: $OC2M_ADMIN_URL" ;;
esac

if [ -z "$OC2M_SCOPE_SERVERS" ]; then
  echo "[WARN] OC2M_SCOPE_SERVERS empty — scripts will consider all managed servers"
else
  echo "[PASS] scope servers: $OC2M_SCOPE_SERVERS"
fi

if [ -z "$OC2M_ADMIN_PASS" ]; then
  echo "[WARN] OC2M_ADMIN_PASS not set — export it securely before running WLST scripts"
else
  echo "[PASS] admin password provided via environment"
fi

# Confirm the OUAF iwsdeploy utility is reachable for the IWS phase.
if [ -n "$SPLEBASE" ] && [ -x "$SPLEBASE/bin/iwsdeploy.sh" ]; then
  echo "[PASS] iwsdeploy found: $SPLEBASE/bin/iwsdeploy.sh"
elif [ -n "$SPLEBASE" ]; then
  echo "[WARN] iwsdeploy.sh not found under $SPLEBASE/bin — check the OUAF product home"
else
  echo "[WARN] SPLEBASE not set — set it to enable the IWS deploy readiness check"
fi

if [ "$OC2M_APPLY" = "true" ]; then
  echo "[WARN] OC2M_APPLY=true — Remediation will WRITE changes. Ensure a change window + backup."
else
  echo "[PASS] OC2M_APPLY=false — Remediation stays dry-run (safe default)"
fi

# ---- Optional: export into the caller's shell ------------------------------
if [ "$DO_EXPORT" = "yes" ]; then
  export OC2M_ADMIN_URL OC2M_ADMIN_USER OC2M_ADMIN_PASS OC2M_SCOPE_SERVERS OC2M_JMS_TARGET
  export OC2M_EXPECT_CLUSTER OC2M_COHERENCE_PORT OC2M_EXPECT_JMSSERVER OC2M_EXPECT_JMSMODULE
  export OC2M_EXPECT_CF_JNDI OC2M_EXPECT_QUEUE_JNDI OC2M_TOPIC_JNDI OC2M_SUBDEPLOYMENT
  export OC2M_EXPECT_IWS OC2M_APPLY
  echo ""
  echo "Scope exported into the current shell."
fi

exit $READY
