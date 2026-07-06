-- OC2MMIG-Report.sql — read-only source-vs-target compare report for a promoted scope.
--
-- PURPOSE
--     Produce the environment-comparison evidence that a promotion reached parity. Run once against
--     the source schema and once against each target schema, then diff the two outputs: it lists,
--     for the objects in a Migration Request, each object's key and last-change stamp, plus the
--     configuration release/bundle level. Matching output across environments = parity for the
--     scope. Read-only — SELECT only, it changes nothing.
--
-- HOW TO RUN
--     run against source, then against target, capturing each to a file, then compare:
--       sqlplus -s cisadm@source  @OC2MMIG-Report.sql your-request-code > report_source.txt
--       sqlplus -s cisadm@target  @OC2MMIG-Report.sql your-request-code > report_target.txt
--       diff report_source.txt report_target.txt
--     Pass the Migration Request code as the first argument (defaults to a placeholder).
--
-- EXPECTED RESULTS
--     A stable, sorted listing (object type, key, version/last-changed) for the request's scope and
--     the config bundle level. An empty diff between source and target = PASS (parity, no drift).
--     Any diff names exactly which object is missing or mismatched on the target.
--
-- NOTES
--     White-label, the repeatable way. Read-only. Table/column names follow OUAF conventions; verify
--     names for your C2M version (C2M 25.4 / min v2.9). Detailed CMA reference behavior is on MOS —
--     pointed to, not reproduced here.

set heading off feedback off verify off pagesize 0 linesize 200 trimspool on
define req_code = '&1'

prompt === OC2MMIG Compare Report ===
prompt --- Migration Request scope: &req_code ---

-- Objects declared in the Migration Request, with a stable sort so source/target diff cleanly.
-- (Joins the request to its selector rows; adjust object-key columns to your version if needed.)
select rpad(nvl(sel.migr_plan_cd,'?'),20) || ' | ' ||
       rpad(nvl(sel.pk_value1,'-'),40)    || ' | ' ||
       to_char(nvl(sel.version,0))
from   f1_migr_req      req
join   f1_migr_req_sel  sel on sel.migr_req_cd = req.migr_req_cd
where  req.migr_req_cd = '&req_code'
order  by 1, 2;

prompt --- Configuration bundle / release level ---
select 'bundle_level | ' || nvl(max(bkt.batch_cd),'(none)')
from   ci_batch_ctrl bkt
where  bkt.batch_cd like 'CM%';   -- placeholder: point at your release-marker control; verify for your version

prompt === end OC2MMIG Compare Report (&req_code) ===
exit
