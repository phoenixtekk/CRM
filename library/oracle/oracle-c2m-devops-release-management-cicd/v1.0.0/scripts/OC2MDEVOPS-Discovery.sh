# OC2MDEVOPS-Discovery.sh — read-only inventory of a C2M/OUAF environment and its release pipeline.
#
# PURPOSE
#     Inventory one Oracle Utilities C2M / OUAF environment so you can assess it before wiring or
#     running the release pipeline: whether the environment is reachable, its OUAF release/patch
#     level, which pipeline utilities are present (splenviron, iwsdeploy, threadpoolworker, batch),
#     and whether the release-artifact locations (code build, CMA config bundle, settings snapshot)
#     are in place. Read-only — it inventories the environment, it never builds, imports, deploys,
#     restarts, or changes anything. Run it against your-source-env and each your-target-env.
#
# HOW TO RUN
#     source the product environment first, then:
#       ./OC2MDEVOPS-Discovery.sh your-env-name
#     e.g.  ./OC2MDEVOPS-Discovery.sh QA
#     Requires: product OS account with splenviron access and SQL*Plus (or SQLcl) to the C2M schema.
#     Point OC2MDEVOPS_ARTIFACTS at your build/bundle/settings root; set the schema connect string in
#     OC2MDEVOPS_DB below or export OC2MDEVOPS_DB.
#
# EXPECTED RESULTS
#     A one-screen summary: reachability, release/patch level, a PASS/GAP line per pipeline utility,
#     a PASS/GAP line for each release-artifact location, and CMA/IWS object counts. Record these
#     against the Requirements checklist. GAP lines are what you remediate before configuring.
#
# NOTES
#     White-label, the repeatable way. Read-only against a live system. Object/utility names follow
#     OUAF conventions; verify names for your C2M version (C2M 25.4 / min v2.9, WebLogic 14c).
#     MOS-gated reference detail is pointed to, never reproduced.

set -u

ENV_NAME="${1:-your-env}"
OC2MDEVOPS_DB="${OC2MDEVOPS_DB:-/ as sysdba}"          # override: export OC2MDEVOPS_DB="cisadm/password@//host:1521/SID"
SPLEBASE="${SPLEBASE:-}"                                # product home; normally set by splenviron
OC2MDEVOPS_ARTIFACTS="${OC2MDEVOPS_ARTIFACTS:-/your/release/artifacts}"   # root holding build/, bundles/, settings/

echo ""
echo "=== OC2MDEVOPS Discovery — environment: ${ENV_NAME} ==="

# --- Release / patch level (from the product environment) --------------------------------------
echo ""
echo "[1] Release / patch level"
if [ -n "${SPLEBASE}" ] && [ -r "${SPLEBASE}/etc/ENVIRON.INI" ]; then
    grep -E '^(BLD_LEVEL|SPLENVIRON|SERVER_ROLES|SPLVERSION)' "${SPLEBASE}/etc/ENVIRON.INI" 2>/dev/null \
        || echo "    (version keys not found in ENVIRON.INI — verify keys for your version)"
else
    echo "    SPLEBASE not set / ENVIRON.INI unreadable — source splenviron for this environment first."
fi

# --- Pipeline utilities present (read-only presence check) -------------------------------------
echo ""
echo "[2] Pipeline utilities on the path"
for util in splenviron.sh initialSetup.sh configureEnv.sh iwsdeploy.sh threadpoolworker.sh submitjob.sh; do
    if command -v "${util}" >/dev/null 2>&1; then
        echo "    PASS - ${util}"
    else
        echo "    GAP  - ${util} not on path (source splenviron; verify utility name for your version)"
    fi
done

# --- Release-artifact locations (read-only presence check) -------------------------------------
echo ""
echo "[3] Release-artifact locations under ${OC2MDEVOPS_ARTIFACTS}"
for sub in build bundles settings; do
    if [ -d "${OC2MDEVOPS_ARTIFACTS}/${sub}" ]; then
        echo "    PASS - ${sub}/ present"
    else
        echo "    GAP  - ${sub}/ missing (create the source-controlled artifact location — Requirement 2.1)"
    fi
done

# --- CMA / IWS object counts (read-only SQL) ---------------------------------------------------
echo ""
echo "[4] CMA readiness and IWS scope (read-only query)"
sqlplus -s "${OC2MDEVOPS_DB}" <<'SQL'
set heading off feedback off verify off pagesize 0 lines 200 trimspool on
prompt --- Migration Assistant master configuration present? ---
select case when count(*) > 0 then 'PASS - Migration Assistant Configuration present'
            else 'GAP  - no Migration Assistant Configuration (CMA not enabled)'
       end
from   ci_md_mstr_cfg
where  msconfig_type_flg = 'F1MA';
prompt --- Inbound Web Services defined (IWS deploy scope) ---
select 'Inbound Web Svcs  : ' || to_char(count(*)) from f1_iws_svc;
prompt --- Batch controls defined (routine-admin / batch automation scope) ---
select 'Batch Controls    : ' || to_char(count(*)) from ci_batch_ctrl;
SQL
RC=$?

echo ""
if [ "${RC}" -ne 0 ]; then
    echo "NOTE: SQL step returned ${RC}. Confirm OC2MDEVOPS_DB connect string and schema access."
    echo "      (Table names follow OUAF conventions; verify names for your C2M version.)"
fi
echo "Discovery complete. Record reachability, release/patch, utility PASS/GAP, and artifact locations."
echo "=== end OC2MDEVOPS Discovery (${ENV_NAME}) ==="
