#!/bin/sh
# OWLS14C-ScopeHelper.sh — pin the domain/server/data-source targets the other scripts act on.
#
# PURPOSE
#     Capture, in one place, the environment coordinates the OWLS14C Discovery,
#     Validation, Report and Remediation scripts read: the domain home and name,
#     Admin URL and user, managed server names, machine and Node Manager host/port,
#     and the C2MDataSource data-source name and database service. Writes them to
#     owls14c-scope.env so every script runs against the same, consistent target.
#
# HOW TO RUN
#     Interactive (prompts for each value, shows current/default):
#         ./OWLS14C-ScopeHelper.sh --interactive
#     Non-interactive (pass what you know; unset values keep placeholders):
#         ./OWLS14C-ScopeHelper.sh --domain your-domain-home/c2m_domain \
#             --admin-url t3://your-admin-host:7001 --user your-admin-user
#     Show the current scope file:
#         ./OWLS14C-ScopeHelper.sh --show
#
# EXPECTED RESULTS
#     An owls14c-scope.env file in the current directory containing OWLS14C_*
#     variables. The other scripts auto-source it, so you set targets once per
#     environment (Dev/Test/Prod) and reuse them. Exit 0 on success.
#
# NOTES
#     White-label, repeatable: keep one scope file per environment (e.g.
#     owls14c-scope.dev.env) and copy it in as owls14c-scope.env before a run.
#     Read-only against live systems — it never touches the domain or database;
#     it only writes the local scope file. Never store the AdminServer password
#     here — pass it via OWLS14C_ADMIN_PASS or an interactive prompt at run time.

SCOPE_FILE="./owls14c-scope.env"

# defaults (placeholders WITHOUT angle brackets)
OWLS14C_DOMAIN_HOME="your-domain-home/c2m_domain"
OWLS14C_DOMAIN_NAME="c2m_domain"
OWLS14C_ADMIN_URL="t3://your-admin-host:7001"
OWLS14C_ADMIN_USER="your-admin-user"
OWLS14C_MS_NAMES="c2m_ms1"           # space-separated; add c2m_ms2 for HA
OWLS14C_CLUSTER="c2m_cluster"
OWLS14C_MACHINE="c2m_machine1"
OWLS14C_NM_HOST="your-nm-host"
OWLS14C_NM_PORT="5556"
OWLS14C_DS_NAME="C2MDataSource"
OWLS14C_DB_HOST="your-db-host"
OWLS14C_DB_PORT="1521"
OWLS14C_DB_SERVICE="your-service"

MODE="write"

# pre-load existing values so we don't clobber on a partial run
if [ -f "$SCOPE_FILE" ]; then
  # shellcheck disable=SC1091
  . "$SCOPE_FILE"
fi

prompt() {  # prompt VAR "Question"
  _var="$1"; _q="$2"
  eval _cur=\$$_var
  printf "%s [%s]: " "$_q" "$_cur"
  read _ans
  if [ -n "$_ans" ]; then
    eval $_var=\$_ans
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --interactive) MODE="interactive" ;;
    --show)        MODE="show" ;;
    --domain)      OWLS14C_DOMAIN_HOME="$2"; shift ;;
    --admin-url)   OWLS14C_ADMIN_URL="$2"; shift ;;
    --user)        OWLS14C_ADMIN_USER="$2"; shift ;;
    --ds)          OWLS14C_DS_NAME="$2"; shift ;;
    --nm-host)     OWLS14C_NM_HOST="$2"; shift ;;
    --nm-port)     OWLS14C_NM_PORT="$2"; shift ;;
    -h|--help)     grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ "$MODE" = "show" ]; then
  if [ -f "$SCOPE_FILE" ]; then
    echo "Current scope ($SCOPE_FILE):"
    cat "$SCOPE_FILE"
  else
    echo "No scope file yet. Run: ./OWLS14C-ScopeHelper.sh --interactive"
  fi
  exit 0
fi

if [ "$MODE" = "interactive" ]; then
  echo "OWLS14C ScopeHelper — set targets (Enter keeps the shown value)"
  echo "----------------------------------------------------------------"
  prompt OWLS14C_DOMAIN_HOME "Domain home path"
  prompt OWLS14C_DOMAIN_NAME "Domain name"
  prompt OWLS14C_ADMIN_URL   "Admin URL (t3://host:port)"
  prompt OWLS14C_ADMIN_USER  "Admin username"
  prompt OWLS14C_MS_NAMES    "Managed server name(s), space-separated"
  prompt OWLS14C_CLUSTER     "Cluster name (blank if none)"
  prompt OWLS14C_MACHINE     "Machine name"
  prompt OWLS14C_NM_HOST     "Node Manager host (real IP/hostname, not localhost)"
  prompt OWLS14C_NM_PORT     "Node Manager port"
  prompt OWLS14C_DS_NAME     "Data source name"
  prompt OWLS14C_DB_HOST     "Database host / SCAN"
  prompt OWLS14C_DB_PORT     "Database port"
  prompt OWLS14C_DB_SERVICE  "Database service name (not SID)"
  echo ""
fi

# sanity nudges (warn, do not block)
case "$OWLS14C_NM_HOST" in
  localhost|127.0.0.1) echo "WARN: Node Manager host is localhost — use a real IP/hostname." ;;
esac

cat > "$SCOPE_FILE" <<EOF
# owls14c-scope.env — OWLS14C target scope. Sourced by the OWLS14C scripts.
# One per environment (copy in as owls14c-scope.env before a run).
# Do NOT store the AdminServer password here (use OWLS14C_ADMIN_PASS at run time).
OWLS14C_DOMAIN_HOME="$OWLS14C_DOMAIN_HOME"
OWLS14C_DOMAIN_NAME="$OWLS14C_DOMAIN_NAME"
OWLS14C_ADMIN_URL="$OWLS14C_ADMIN_URL"
OWLS14C_ADMIN_USER="$OWLS14C_ADMIN_USER"
OWLS14C_MS_NAMES="$OWLS14C_MS_NAMES"
OWLS14C_CLUSTER="$OWLS14C_CLUSTER"
OWLS14C_MACHINE="$OWLS14C_MACHINE"
OWLS14C_NM_HOST="$OWLS14C_NM_HOST"
OWLS14C_NM_PORT="$OWLS14C_NM_PORT"
OWLS14C_DS_NAME="$OWLS14C_DS_NAME"
OWLS14C_DB_HOST="$OWLS14C_DB_HOST"
OWLS14C_DB_PORT="$OWLS14C_DB_PORT"
OWLS14C_DB_SERVICE="$OWLS14C_DB_SERVICE"
export OWLS14C_DOMAIN_HOME OWLS14C_DOMAIN_NAME OWLS14C_ADMIN_URL OWLS14C_ADMIN_USER
export OWLS14C_MS_NAMES OWLS14C_CLUSTER OWLS14C_MACHINE OWLS14C_NM_HOST OWLS14C_NM_PORT
export OWLS14C_DS_NAME OWLS14C_DB_HOST OWLS14C_DB_PORT OWLS14C_DB_SERVICE
EOF

echo "Wrote scope to $SCOPE_FILE:"
cat "$SCOPE_FILE"
echo ""
echo "The OWLS14C Discovery/Validation/Report/Remediation scripts will now use these targets."
exit 0
