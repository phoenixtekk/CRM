# OC2MMIG-ScopeHelper.sh — resolve and print a Migration Request's declared scope.
#
# PURPOSE
#     Show exactly what a Migration Request will bundle before you export it, so you promote what you
#     intend and nothing more. It prints the request's selectors — the Migration Plans and object
#     keys it pulls — and flags any in-scope object type that has no Migration Plan (which CMA would
#     silently drop). Read-only — it inspects the request definition, it never exports or imports.
#
# HOW TO RUN
#     source the product environment, then:
#       ./OC2MMIG-ScopeHelper.sh your-request-code
#     e.g.  ./OC2MMIG-ScopeHelper.sh your-rate-config-request
#     Set the schema connect string in OC2MMIG_DB below or export OC2MMIG_DB.
#
# EXPECTED RESULTS
#     A readable listing of the request's declared scope (plan, object key) and a PASS/GAP line:
#     PASS if every selected object type has a Migration Plan, GAP (with the object named) if one
#     does not — author the missing plan before exporting, or the object will be left out.
#
# NOTES
#     White-label, the repeatable way. Read-only against a live system. The Migration Request is the
#     reusable unit of promotion — build once, reuse every release. Table/column names follow OUAF
#     conventions; verify names for your C2M version (C2M 25.4 / min v2.9).

set -u

REQ_CODE="${1:-your-request-code}"
OC2MMIG_DB="${OC2MMIG_DB:-/ as sysdba}"   # override: export OC2MMIG_DB="cisadm/password@//host:1521/SID"

echo ""
echo "=== OC2MMIG ScopeHelper — Migration Request: ${REQ_CODE} ==="

sqlplus -s "${OC2MMIG_DB}" <<SQL
set heading off feedback off verify off pagesize 0 linesize 200 trimspool on

prompt --- Request exists? ---
select case when count(*) > 0 then 'PASS - request ${REQ_CODE} found'
            else 'GAP  - request ${REQ_CODE} not found (create it, then re-run)'
       end
from   f1_migr_req where migr_req_cd = '${REQ_CODE}';

prompt
prompt --- Declared scope (Migration Plan | object key) ---
select rpad(nvl(sel.migr_plan_cd,'?'),24) || ' | ' || nvl(sel.pk_value1,'-')
from   f1_migr_req_sel sel
where  sel.migr_req_cd = '${REQ_CODE}'
order  by 1, 2;

prompt
prompt --- Coverage: any selected plan missing its definition? ---
select case when count(*) = 0
            then 'PASS - every selected object type has a Migration Plan'
            else 'GAP  - ' || to_char(count(*)) || ' selected object type(s) lack a Migration Plan'
       end
from   f1_migr_req_sel sel
where  sel.migr_req_cd = '${REQ_CODE}'
and    not exists (select 1 from f1_migr_plan p where p.migr_plan_cd = sel.migr_plan_cd);

prompt
prompt --- Names of any object types missing a Migration Plan (author these before export) ---
select distinct 'MISSING PLAN: ' || sel.migr_plan_cd
from   f1_migr_req_sel sel
where  sel.migr_req_cd = '${REQ_CODE}'
and    not exists (select 1 from f1_migr_plan p where p.migr_plan_cd = sel.migr_plan_cd);
SQL
RC=$?

echo ""
[ "${RC}" -ne 0 ] && echo "NOTE: SQL step returned ${RC}. Confirm OC2MMIG_DB connect string and schema access."
echo "Review the scope above; resolve any GAP before exporting the bundle."
echo "=== end OC2MMIG ScopeHelper (${REQ_CODE}) ==="
