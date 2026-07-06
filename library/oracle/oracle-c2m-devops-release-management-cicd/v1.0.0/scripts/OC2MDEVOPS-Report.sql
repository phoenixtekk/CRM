-- OC2MDEVOPS-Report.sql — read-only source-vs-target compare report for a promoted release scope.
--
-- PURPOSE
--     Produce the validate-stage evidence that a release reached parity. Run once against the source
--     schema and once against each target schema, then diff the two outputs: it lists the code
--     build/patch level, the CMA import history for the release, the in-scope Inbound Web Service
--     revisions, and the batch-control set (routine-admin scope) — each with a stable sort so the two
--     outputs diff cleanly. Matching output across environments = parity for the scope. Read-only —
--     SELECT only, it changes nothing.
--
-- HOW TO RUN
--     run against source, then against target, capturing each to a file, then compare:
--       sqlplus -s cisadm@source  @OC2MDEVOPS-Report.sql your-release-code > report_source.txt
--       sqlplus -s cisadm@target  @OC2MDEVOPS-Report.sql your-release-code > report_target.txt
--       diff report_source.txt report_target.txt
--     Pass the release / migration-request code as the first argument (defaults to a placeholder).
--
-- EXPECTED RESULTS
--     A stable, sorted listing (build level, CMA import history, IWS revisions, batch controls) for
--     the release scope. An empty diff between source and target = PASS (parity, no drift). Any diff
--     names exactly which build/config/IWS element is missing or mismatched on the target.
--
-- NOTES
--     White-label, the repeatable way. Read-only. Table/column names follow OUAF conventions; verify
--     names for your C2M version (C2M 25.4 / min v2.9). Detailed CMA/iwsdeploy reference behavior is
--     on MOS and in the migration sibling — pointed to, not reproduced here.

set heading off feedback off verify off pagesize 0 linesize 200 trimspool on
define rel_code = '&1'

prompt === OC2MDEVOPS Compare Report ===
prompt --- Release scope: &rel_code ---

prompt --- Code build / patch level ---
-- Release marker: point at your build-level source of truth; verify table/column for your version.
select 'build_level  | ' || nvl(max(bkt.batch_cd),'(none)')
from   ci_batch_ctrl bkt
where  bkt.batch_cd like 'CM%';   -- placeholder release marker — replace per your version

prompt --- CMA import history for the release (imported = config stage applied) ---
select rpad('cma_import',16) || ' | ' ||
       rpad(nvl(req.migr_req_cd,'-'),24) || ' | ' ||
       to_char(nvl(req.version,0))
from   f1_migr_req req
where  req.migr_req_cd = '&rel_code'
order  by 1, 2;

prompt --- In-scope Inbound Web Service revisions (deploy stage parity) ---
select rpad('iws',16) || ' | ' ||
       rpad(nvl(svc.iws_name,'-'),40) || ' | ' ||
       to_char(nvl(svc.version,0))
from   f1_iws_svc svc
order  by 2;

prompt --- Batch controls (routine-admin / batch automation scope) ---
select rpad('batch_ctrl',16) || ' | ' || nvl(batch_cd,'-')
from   ci_batch_ctrl
order  by batch_cd;

prompt === end OC2MDEVOPS Compare Report (&rel_code) ===
exit
