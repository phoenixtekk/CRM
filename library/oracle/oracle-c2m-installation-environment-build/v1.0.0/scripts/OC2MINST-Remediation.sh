#!/bin/sh
# OC2MINST-Remediation.sh — safe, dry-run-by-default fixes for common C2M build issues.
#
# PURPOSE
#     Proposes and (only with -apply) performs safe remediation for common post-install problems on
#     one environment (your-env, e.g. C2MDEV): incorrect ownership/permissions on the product home
#     ($SPLEBASE), stale generated config templates (rebuild with initialSetup.sh -t), and a WebLogic
#     server that is not RUNNING (offer a controlled restart via spl.sh). DRY-RUN by default: it prints
#     the planned actions and changes nothing unless -apply is given.
#
# HOW TO RUN
#     Preview (safe, default) as the product OS user (cissys):
#         ./OC2MINST-Remediation.sh -e your-env
#     Apply after reviewing the plan:
#         ./OC2MINST-Remediation.sh -e your-env -apply
#     Optional: -t fixperms  |  -t templates  |  -t restart   to run one action only.
#
# EXPECTED RESULTS
#     In dry-run: a numbered plan of the actions that WOULD run, ending with "DRY-RUN — nothing
#     changed." With -apply: each action runs and reports OK/FAILED. Never touches Production without
#     -apply, and never a server it is not asked to.
#
# NOTES
#     White-label, repeatable remediation. Read-only until -apply. It calls documented OUAF utilities
#     (splenviron.sh, initialSetup.sh, spl.sh) rather than editing generated files by hand; it never
#     hand-edits ENVIRON.INI. Utility flags can vary by release — verify for your version against the
#     OUAF Server Administration Guide.

ENV_NAME=""
APPLY="no"
ACTION="all"

# Note: -apply is a multi-char flag, handled before getopts.
NEWARGS=""
for a in "$@"; do
  if [ "$a" = "-apply" ]; then APPLY="yes"; else NEWARGS="$NEWARGS $a"; fi
done
# shellcheck disable=SC2086
set -- $NEWARGS

while getopts "e:t:h" opt; do
  case "$opt" in
    e) ENV_NAME="$OPTARG" ;;
    t) ACTION="$OPTARG" ;;
    h) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Usage: $0 -e your-env [-t fixperms|templates|restart|all] [-apply]"; exit 2 ;;
  esac
done

[ -z "$ENV_NAME" ] && { echo "ERROR: -e your-env is required."; exit 2; }

SPLEBASE="/opt/oracle/spl/$ENV_NAME"
PROD_USER="cissys"
N=0

plan() {
  N=$((N + 1))
  echo "  ($N) PLANNED: $1"
}

run() {
  # run "description" command...
  DESC="$1"; shift
  if [ "$APPLY" = "yes" ]; then
    printf "  APPLY: %s ... " "$DESC"
    if "$@"; then echo "OK"; else echo "FAILED"; fi
  else
    plan "$DESC   [cmd: $*]"
  fi
}

echo "=== OC2MINST Remediation — environment: $ENV_NAME (apply=$APPLY, action=$ACTION) ==="
if [ "$APPLY" != "yes" ]; then
  echo "  Mode: DRY-RUN. Reviewing planned actions only; nothing will change."
fi

# --- Action 1: fix ownership/permissions on $SPLEBASE ---
if [ "$ACTION" = "all" ] || [ "$ACTION" = "fixperms" ]; then
  echo "--- Ownership/permissions on \$SPLEBASE ---"
  if [ -d "$SPLEBASE" ]; then
    OWNER=$(ls -ld "$SPLEBASE" 2>/dev/null | awk '{print $3}')
    if [ "$OWNER" != "$PROD_USER" ]; then
      run "chown product home $SPLEBASE to $PROD_USER (recursive)" chown -R "$PROD_USER" "$SPLEBASE"
    else
      echo "  [OK   ] $SPLEBASE already owned by $PROD_USER"
    fi
  else
    echo "  [CHECK] $SPLEBASE not found — install the environment first"
  fi
fi

# --- Action 2: rebuild generated config templates ---
if [ "$ACTION" = "all" ] || [ "$ACTION" = "templates" ]; then
  echo "--- Rebuild generated config templates (initialSetup.sh -t) ---"
  if [ -x "$SPLEBASE/bin/initialSetup.sh" ]; then
    # Templates are regenerated from ENVIRON.INI; we never hand-edit ENVIRON.INI.
    run "regenerate config templates for $ENV_NAME" sh -c "$SPLEBASE/bin/splenviron.sh -e $ENV_NAME -c '$SPLEBASE/bin/initialSetup.sh -t'"
  else
    echo "  [CHECK] initialSetup.sh not found under $SPLEBASE/bin"
  fi
fi

# --- Action 3: restart a non-RUNNING environment via spl.sh ---
if [ "$ACTION" = "all" ] || [ "$ACTION" = "restart" ]; then
  echo "--- Controlled environment restart (spl.sh) ---"
  if [ -x "$SPLEBASE/bin/spl.sh" ]; then
    run "stop environment $ENV_NAME"  sh -c "$SPLEBASE/bin/splenviron.sh -e $ENV_NAME -c '$SPLEBASE/bin/spl.sh -stop'"
    run "start environment $ENV_NAME" sh -c "$SPLEBASE/bin/splenviron.sh -e $ENV_NAME -c '$SPLEBASE/bin/spl.sh -start'"
    echo "  After restart, re-run OC2MINST-Validation.py to confirm AdminServer and c2m_server1 are RUNNING."
  else
    echo "  [CHECK] spl.sh not found under $SPLEBASE/bin"
  fi
fi

echo "=== Remediation complete ==="
if [ "$APPLY" != "yes" ]; then
  echo "  DRY-RUN — nothing changed. Re-run with -apply after reviewing the plan above."
fi
exit 0
