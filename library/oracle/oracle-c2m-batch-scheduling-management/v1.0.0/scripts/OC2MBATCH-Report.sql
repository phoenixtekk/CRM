-- OC2MBATCH-Report.sql — read-only batch run-status, throughput, and backlog report from the C2M schema.
--
-- PURPOSE
--     Render the C2M batch monitoring view (C2M Monitor - Batch - Run Status): recent
--     batch run status by control, run durations, thread completion and failures,
--     throughput signals, and the Batch Job Submission backlog. Read-only — SELECT only,
--     it changes no data. Use it during and after the nightly cycle to confirm every
--     control completed and no backlog remains.
--
-- HOW TO RUN
--     Via SQL*Plus or SQLcl against the C2M schema (read-only account is fine):
--         sqlplus user/pass@your-db @OC2MBATCH-Report.sql
--     (or  sql user/pass@your-db @OC2MBATCH-Report.sql  with SQLcl)
--
-- EXPECTED RESULTS
--     Four sections print: (1) runs in the last 24h with status and duration,
--     (2) failed/error threads, (3) currently in-flight runs, (4) pending Batch Job
--     Submission backlog. PASS = all in-scope controls Complete and backlog = 0.
--     FAIL = any Error thread, an overdue in-flight run, or a non-zero backlog.
--
-- NOTES
--     White-label, repeatable report — the standing operational view, same query set every
--     night. Read-only against live systems. Table/column names follow the OUAF/C2M batch
--     model — verify object names for your version (they are cited, not invented).

SET PAGESIZE 60
SET LINESIZE 180
SET FEEDBACK OFF

PROMPT ============================================================
PROMPT  C2M Monitor - Batch - Run Status  (read-only)
PROMPT ============================================================

PROMPT
PROMPT -- 1. Batch runs in the last 24 hours (status + duration) --
SELECT batch_cd,
       batch_nbr,
       COUNT(*)                                              AS threads,
       SUM(CASE WHEN batch_thread_stat_flg = '50' THEN 1 ELSE 0 END) AS completed,
       SUM(CASE WHEN batch_thread_stat_flg = '60' THEN 1 ELSE 0 END) AS errored,
       MIN(start_dttm)                                       AS started,
       MAX(end_dttm)                                         AS ended,
       ROUND((MAX(end_dttm) - MIN(start_dttm)) * 24 * 60, 1) AS minutes
  FROM ci_batch_inst
 WHERE start_dttm >= SYSDATE - 1
 GROUP BY batch_cd, batch_nbr
 ORDER BY started DESC;

PROMPT
PROMPT -- 2. Failed / errored threads (investigate each) --
SELECT batch_cd, batch_nbr, batch_thread_nbr, batch_thread_stat_flg AS status,
       start_dttm, end_dttm
  FROM ci_batch_inst
 WHERE batch_thread_stat_flg = '60'
   AND start_dttm >= SYSDATE - 1
 ORDER BY start_dttm DESC;

PROMPT
PROMPT -- 3. In-flight runs (started, not ended) --
SELECT batch_cd, batch_nbr, batch_thread_nbr, start_dttm,
       ROUND((SYSDATE - start_dttm) * 24 * 60, 1) AS running_minutes
  FROM ci_batch_inst
 WHERE end_dttm IS NULL
   AND start_dttm IS NOT NULL
 ORDER BY start_dttm;

PROMPT
PROMPT -- 4. Batch Job Submission backlog (pending / queued) --
PROMPT    A non-zero backlog after the cycle means pools are under-sized or a control is stuck.
SELECT batch_cd,
       COUNT(*) AS pending
  FROM f1_batch_job
 WHERE batch_job_stat_flg IN ('P', 'PN')   -- pending / not started (verify status codes for your version)
 GROUP BY batch_cd
 ORDER BY pending DESC;

PROMPT
PROMPT ============================================================
PROMPT  End of report. PASS = all controls Complete, backlog = 0.
PROMPT ============================================================
SET FEEDBACK ON
