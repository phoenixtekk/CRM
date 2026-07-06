#!/bin/sh
# OSOAC2M-ScopeHelper.sh — resolve and export the C2M SOA-integration target scope for the other scripts.
#
# PURPOSE
#     Centralise the connection details, expected object names, and in-scope interface/server
#     list so the WLST and SQL scripts (Discovery, Validation, Report, Remediation) act only
#     where intended and use identical names across environments. Reads values from your
#     environment or a small config file, validates them, and prints export lines you can
#     source. Reuses the solution reference names by default; override per environment
#     (your-env-config).
#
# HOW TO RUN
#     Print the resolved scope:      sh ./OSOAC2M-ScopeHelper.sh
#     Load it into your shell:       . ./OSOAC2M-ScopeHelper.sh --export
#     With a config file:            sh ./OSOAC2M-ScopeHelper.sh --config myenv.conf
#     Then run e.g.:                 java weblogic.WLST OSOAC2M-Validation.py
#
# EXPECTED RESULTS
#     Prints the resolved OSOAC2M_* variables and a PASS/FAIL readiness check (admin URL set,
#     scope set, iwsdeploy present). Exit 0 when ready to run the WLST scripts; exit 1 if a
#     required value is missing so a pipeline stops before acting out of scope.
#
# NOTES
#     White-label, repeatable. Helper only: it neither connects nor changes anything — it just
#     resolves scope and env vars. Set OSOAC2M_APPLY only when you intend Remediation to write;
#     it defaults to false so the integration objects stay dry-run safe. Never commit secrets.

set -u

CONFIG=""
DO_EXPORT="no"
while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --export) DO_EXPORT="yes"; shift ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
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
OSOAC2M_ADMIN_URL="${OSOAC2M_ADMIN_URL:-t3://your-admin-host:7001}"
OSOAC2M_ADMIN_USER="${OSOAC2M_ADMIN_USER:-your-weblogic-admin}"
# Password should come from the environment or a secured prompt, never a committed file.
OSOAC2M_ADMIN_PASS="${OSOAC2M_ADMIN_PASS:-}"

OSOAC2M_SCOPE_SERVERS="${OSOAC2M_SCOPE_SERVERS:-}"    # comma-separated managed servers in scope
OSOAC2M_JMS_TARGET="${OSOAC2M_JMS_TARGET:-your-managed-server}"

# Reference integration object names (Overview naming convention) — override per environment.
OSOAC2M_EXPECT_IWS="${OSOAC2M_EXPECT_IWS:-spl-web-services}"
OSOAC2M_EXPECT_IWS_SVC="${OSOAC2M_EXPECT_IWS_SVC:-C2M-IWS-CustomerSync}"
OSOAC2M_EXPECT_EXTSYS="${OSOAC2M_EXPECT_EXTSYS:-C2M-SOA-EXT}"
OSOAC2M_EXPECT_OMT="${OSOAC2M_EXPECT_OMT:-C2M-OMT-SOA}"
OSOAC2M_EXPECT_RT_SENDER="${OSOAC2M_EXPECT_RT_SENDER:-C2M-RTHTTP-SNDR}"
OSOAC2M_EXPECT_JMS_SENDER="${OSOAC2M_EXPECT_JMS_SENDER:-C2M-JMS-SNDR}"
OSOAC2M_EXPECT_JMSSERVER="${OSOAC2M_EXPECT_JMSSERVER:-C2MIntegrationJMSServer}"
OSOAC2M_EXPECT_JMSMODULE="${OSOAC2M_EXPECT_JMSMODULE:-C2MIntegrationJMSModule}"
OSOAC2M_EXPECT_CF_JNDI="${OSOAC2M_EXPECT_CF_JNDI:-jms/C2MConnectionFactory}"
OSOAC2M_EXPECT_QUEUE_JNDI="${OSOAC2M_EXPECT_QUEUE_JNDI:-jms/C2MOutboundQueue}"
OSOAC2M_SUBDEPLOYMENT="${OSOAC2M_SUBDEPLOYMENT:-C2MIntegrationSubDeployment}"

# SOA/OSB console (informational readiness only; deployment is done in the SOA tooling).
OSOAC2M_SOA_CONSOLE="${OSOAC2M_SOA_CONSOLE:-}"

# Remediation stays dry-run unless explicitly enabled.
OSOAC2M_APPLY="${OSOAC2M_APPLY:-false}"

# SPLEBASE lets us confirm the OUAF iwsdeploy utility is reachable for IWS deployment.
SPLEBASE="${SPLEBASE:-}"

# ---- Emit resolved scope ---------------------------------------------------
emit() {
  echo "OSOAC2M_ADMIN_URL=$OSOAC2M_ADMIN_URL"
  echo "OSOAC2M_ADMIN_USER=$OSOAC2M_ADMIN_USER"
  echo "OSOAC2M_SCOPE_SERVERS=$OSOAC2M_SCOPE_SERVERS"
  echo "OSOAC2M_JMS_TARGET=$OSOAC2M_JMS_TARGET"
  echo "OSOAC2M_EXPECT_IWS=$OSOAC2M_EXPECT_IWS"
  echo "OSOAC2M_EXPECT_IWS_SVC=$OSOAC2M_EXPECT_IWS_SVC"
  echo "OSOAC2M_EXPECT_EXTSYS=$OSOAC2M_EXPECT_EXTSYS"
  echo "OSOAC2M_EXPECT_OMT=$OSOAC2M_EXPECT_OMT"
  echo "OSOAC2M_EXPECT_RT_SENDER=$OSOAC2M_EXPECT_RT_SENDER"
  echo "OSOAC2M_EXPECT_JMS_SENDER=$OSOAC2M_EXPECT_JMS_SENDER"
  echo "OSOAC2M_EXPECT_JMSSERVER=$OSOAC2M_EXPECT_JMSSERVER"
  echo "OSOAC2M_EXPECT_JMSMODULE=$OSOAC2M_EXPECT_JMSMODULE"
  echo "OSOAC2M_EXPECT_CF_JNDI=$OSOAC2M_EXPECT_CF_JNDI"
  echo "OSOAC2M_EXPECT_QUEUE_JNDI=$OSOAC2M_EXPECT_QUEUE_JNDI"
  echo "OSOAC2M_SUBDEPLOYMENT=$OSOAC2M_SUBDEPLOYMENT"
  echo "OSOAC2M_SOA_CONSOLE=$OSOAC2M_SOA_CONSOLE"
  echo "OSOAC2M_APPLY=$OSOAC2M_APPLY"
}

echo "== C2M SOA INTEGRATION SCOPE =="
emit

# ---- Readiness checks ------------------------------------------------------
echo ""
echo "== READINESS =="
READY=0

case "$OSOAC2M_ADMIN_URL" in
  *your-admin-host*|"") echo "[FAIL] OSOAC2M_ADMIN_URL not set to a real admin URL"; READY=1 ;;
  *) echo "[PASS] admin URL set: $OSOAC2M_ADMIN_URL" ;;
esac

if [ -z "$OSOAC2M_SCOPE_SERVERS" ]; then
  echo "[WARN] OSOAC2M_SCOPE_SERVERS empty — scripts will consider all managed servers"
else
  echo "[PASS] scope servers: $OSOAC2M_SCOPE_SERVERS"
fi

if [ -z "$OSOAC2M_ADMIN_PASS" ]; then
  echo "[WARN] OSOAC2M_ADMIN_PASS not set — export it securely before running WLST scripts"
else
  echo "[PASS] admin password provided via environment"
fi

# Confirm the OUAF iwsdeploy utility is reachable for the inbound (IWS) phase.
if [ -n "$SPLEBASE" ] && [ -x "$SPLEBASE/bin/iwsdeploy.sh" ]; then
  echo "[PASS] iwsdeploy found: $SPLEBASE/bin/iwsdeploy.sh"
elif [ -n "$SPLEBASE" ]; then
  echo "[WARN] iwsdeploy.sh not found under $SPLEBASE/bin — check the OUAF product home"
else
  echo "[WARN] SPLEBASE not set — set it to enable the IWS deploy readiness check"
fi

if [ -z "$OSOAC2M_SOA_CONSOLE" ]; then
  echo "[WARN] OSOAC2M_SOA_CONSOLE not set — set it for interfaces that use the SOA/OSB tier"
else
  echo "[PASS] SOA/OSB console: $OSOAC2M_SOA_CONSOLE"
fi

if [ "$OSOAC2M_APPLY" = "true" ]; then
  echo "[WARN] OSOAC2M_APPLY=true — Remediation will WRITE changes. Ensure a change window + backup."
else
  echo "[PASS] OSOAC2M_APPLY=false — Remediation stays dry-run (safe default)"
fi

# ---- Optional: export into the caller's shell ------------------------------
if [ "$DO_EXPORT" = "yes" ]; then
  export OSOAC2M_ADMIN_URL OSOAC2M_ADMIN_USER OSOAC2M_ADMIN_PASS OSOAC2M_SCOPE_SERVERS OSOAC2M_JMS_TARGET
  export OSOAC2M_EXPECT_IWS OSOAC2M_EXPECT_IWS_SVC OSOAC2M_EXPECT_EXTSYS OSOAC2M_EXPECT_OMT
  export OSOAC2M_EXPECT_RT_SENDER OSOAC2M_EXPECT_JMS_SENDER OSOAC2M_EXPECT_JMSSERVER OSOAC2M_EXPECT_JMSMODULE
  export OSOAC2M_EXPECT_CF_JNDI OSOAC2M_EXPECT_QUEUE_JNDI OSOAC2M_SUBDEPLOYMENT OSOAC2M_SOA_CONSOLE OSOAC2M_APPLY
  echo ""
  echo "Scope exported into the current shell."
fi

exit $READY
