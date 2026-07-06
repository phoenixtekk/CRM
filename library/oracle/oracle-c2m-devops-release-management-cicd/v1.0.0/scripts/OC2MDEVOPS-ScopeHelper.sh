# OC2MDEVOPS-ScopeHelper.sh — resolve and print a release's scope before it runs through the pipeline.
#
# PURPOSE
#     Show exactly what a release will promote before you run the pipeline, so you deploy what you
#     intend and nothing more. It resolves the release tuple — the code build version, the CMA config
#     bundle / migration-request scope, and the in-scope Inbound Web Services — and flags any element
#     that is missing (no build recorded, request not found, an IWS not defined). Read-only — it
#     inspects the release and environment definitions, it never builds, imports, deploys, or restarts.
#
# HOW TO RUN
#     source the product environment, then:
#       ./OC2MDEVOPS-ScopeHelper.sh your-release-code
#     e.g.  ./OC2MDEVOPS-ScopeHelper.sh your-2026-r1-release
#     Point OC2MDEVOPS_ARTIFACTS at your build/bundle root; set OC2MDEVOPS_IWS to the in-scope IWS
#     list; set the schema connect string in OC2MDEVOPS_DB below or export OC2MDEVOPS_DB.
#
# EXPECTED RESULTS
#     A readable listing of the release scope — build artifact present?, config request found?, each
#     in-scope IWS defined? — with a PASS/GAP line per element. PASS across all means the release is
#     ready to run through the pipeline; any GAP names the element to fix before the build stage.
#
# NOTES
#     White-label, the repeatable way. Read-only against a live system. A release is one versioned
#     tuple (build + bundle + IWS list + settings) — resolve it once, run it every environment.
#     Table/column names follow OUAF conventions; verify names for your C2M version (C2M 25.4 / min v2.9).

set -u

REL_CODE="${1:-your-release-code}"
OC2MDEVOPS_DB="${OC2MDEVOPS_DB:-/ as sysdba}"          # override: export OC2MDEVOPS_DB="cisadm/password@//host:1521/SID"
OC2MDEVOPS_ARTIFACTS="${OC2MDEVOPS_ARTIFACTS:-/your/release/artifacts}"
IWS_LIST="${OC2MDEVOPS_IWS:-your-iws-app-1,your-iws-app-2}"

echo ""
echo "=== OC2MDEVOPS ScopeHelper — release: ${REL_CODE} ==="

# --- Build artifact present? (source control) --------------------------------------------------
echo ""
echo "[1] Code build artifact"
if [ -d "${OC2MDEVOPS_ARTIFACTS}/build/${REL_CODE}" ]; then
    echo "    PASS - build present: ${OC2MDEVOPS_ARTIFACTS}/build/${REL_CODE}"
else
    echo "    GAP  - no build for ${REL_CODE} under ${OC2MDEVOPS_ARTIFACTS}/build/ (produce/retain it — Requirement 2.4)"
fi

# --- Config bundle / migration-request scope ---------------------------------------------------
echo ""
echo "[2] Configuration bundle / migration-request scope (read-only query)"
sqlplus -s "${OC2MDEVOPS_DB}" <<SQL
set heading off feedback off verify off pagesize 0 linesize 200 trimspool on
prompt --- Migration request for the release found? ---
select case when count(*) > 0 then 'PASS - request ${REL_CODE} found'
            else 'GAP  - request ${REL_CODE} not found (create/scope it, then re-run)'
       end
from   f1_migr_req where migr_req_cd = '${REL_CODE}';
prompt --- Declared config scope (Migration Plan | object key) ---
select rpad(nvl(sel.migr_plan_cd,'?'),24) || ' | ' || nvl(sel.pk_value1,'-')
from   f1_migr_req_sel sel
where  sel.migr_req_cd = '${REL_CODE}'
order  by 1, 2;
SQL
RC=$?

# --- In-scope IWS defined? ---------------------------------------------------------------------
echo ""
echo "[3] In-scope Inbound Web Services"
OLD_IFS="${IFS}"; IFS=','
for svc in ${IWS_LIST}; do
    svc_trim="$(echo "${svc}" | sed 's/^ *//;s/ *$//')"
    [ -z "${svc_trim}" ] && continue
    FOUND="$(sqlplus -s "${OC2MDEVOPS_DB}" <<SQL
set heading off feedback off verify off pagesize 0 lines 100 trimspool on
select case when count(*) > 0 then 'Y' else 'N' end from f1_iws_svc where iws_name = '${svc_trim}';
SQL
)"
    if echo "${FOUND}" | grep -q 'Y'; then
        echo "    PASS - IWS defined: ${svc_trim}"
    else
        echo "    GAP  - IWS not defined: ${svc_trim} (define it before the deploy stage)"
    fi
done
IFS="${OLD_IFS}"

echo ""
[ "${RC}" -ne 0 ] && echo "NOTE: SQL step returned ${RC}. Confirm OC2MDEVOPS_DB connect string and schema access."
echo "Review the release scope above; resolve any GAP before running the pipeline (build stage)."
echo "=== end OC2MDEVOPS ScopeHelper (${REL_CODE}) ==="
