# OC2MMIG-Discovery.sh — read-only inventory of a C2M/OUAF environment for migration & code promotion.
#
# PURPOSE
#     Inventory one Oracle Utilities C2M / OUAF environment so you can assess it before promoting:
#     the C2M/OUAF release and patch/bundle level, whether the Configuration Migration Assistant
#     (CMA) is ready (master config + export/import directories), and which Migration Plans and
#     Migration Requests exist. Read-only — it inventories the environment, it never exports,
#     imports, deploys, or changes anything. Run it against your-source-env and each your-target-env.
#
# HOW TO RUN
#     source the product environment first, then:
#       ./OC2MMIG-Discovery.sh your-env-name
#     e.g.  ./OC2MMIG-Discovery.sh QA
#     Requires: product OS account with splenviron/splquery access and SQL*Plus (or SQLcl) to the
#     C2M schema. Set the schema connect string in OC2MMIG_DB below or export OC2MMIG_DB.
#
# EXPECTED RESULTS
#     A one-screen summary: release/patch level, a CMA-ready PASS/GAP line (master config +
#     directories), and counts of Migration Plans and Migration Requests present. Record these
#     against the Requirements checklist. GAP lines are what you remediate before configuring.
#
# NOTES
#     White-label, the repeatable way. Read-only against a live system. Object/column names follow
#     OUAF conventions; verify names for your C2M version (C2M 25.4 / min v2.9). MOS-gated reference
#     detail is pointed to, never reproduced.

set -u

ENV_NAME="${1:-your-env}"
OC2MMIG_DB="${OC2MMIG_DB:-/ as sysdba}"      # override: export OC2MMIG_DB="cisadm/password@//host:1521/SID"
SPLEBASE="${SPLEBASE:-}"                      # product home; normally set by splenviron

echo ""
echo "=== OC2MMIG Discovery — environment: ${ENV_NAME} ==="

# --- Release / patch level (from the product environment) --------------------------------------
echo ""
echo "[1] Release / patch level"
if [ -n "${SPLEBASE}" ] && [ -r "${SPLEBASE}/etc/ENVIRON.INI" ]; then
    grep -E '^(BLD_LEVEL|SPLENVIRON|SERVER_ROLES|SPLVERSION)' "${SPLEBASE}/etc/ENVIRON.INI" 2>/dev/null \
        || echo "    (version keys not found in ENVIRON.INI — verify keys for your version)"
else
    echo "    SPLEBASE not set / ENVIRON.INI unreadable — source splenviron for this environment first."
fi

# --- CMA readiness + object counts (read-only SQL) ---------------------------------------------
echo ""
echo "[2] CMA readiness and migration objects (read-only query)"
sqlplus -s "${OC2MMIG_DB}" <<'SQL'
set heading off feedback off verify off pagesize 0 lines 200 trimspool on
prompt --- Migration Assistant master configuration present? ---
select case when count(*) > 0 then 'PASS - Migration Assistant Configuration present'
            else 'GAP  - no Migration Assistant Configuration (CMA not enabled)'
       end
from   ci_md_mstr_cfg
where  msconfig_type_flg = 'F1MA';
prompt --- Migration Plans defined ---
select 'Migration Plans   : ' || to_char(count(*)) from f1_migr_plan;
prompt --- Migration Requests defined ---
select 'Migration Requests: ' || to_char(count(*)) from f1_migr_req;
prompt --- Inbound Web Services defined (IWS promotion scope) ---
select 'Inbound Web Svcs  : ' || to_char(count(*)) from f1_iws_svc;
SQL
RC=$?

echo ""
if [ "${RC}" -ne 0 ]; then
    echo "NOTE: SQL step returned ${RC}. Confirm OC2MMIG_DB connect string and schema access."
    echo "      (Table names follow OUAF conventions; verify names for your C2M version.)"
fi
echo "Discovery complete. Record release/patch, CMA PASS/GAP, and object counts on the checklist."
echo "=== end OC2MMIG Discovery (${ENV_NAME}) ==="
