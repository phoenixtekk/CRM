-- OC2MHYPER-Report.sql — read-only batch, integration, and database health detail from the C2M schema.
--
-- PURPOSE
--     Render the database-side detail for the daily health routine (C2M Runbook - Health -
--     Daily Routine): batch run status and backlog for last night's cycle, integration
--     queue depth, and database/space health signals. Read-only — SELECT only, it changes
--     no data. Run it each hypercare morning alongside OC2MHYPER-Report.sh to produce the
--     green/amber/red health snapshot.
--
-- HOW TO RUN
--     Via SQL*Plus or SQLcl against the C2M schema (a read-only account is fine):
--         sqlplus user/pass@your-db @OC2MHYPER-Report.sql
--     (or  sql user/pass@your-db @OC2MHYPER-Report.sql  with SQLcl)
--
-- EXPECTED RESULTS
--     Four sections print: (1) batch runs in the last 24h with status and duration,
--     (2) failed/error threads, (3) Batch Job Submission backlog, (4) tablespace space
--     usage. GREEN = all controls Complete, backlog = 0, no space over threshold.
--     AMBER/RED = any error thread, a non-zero backlog, or a tablespace near full — each
--     opens an incident at the appropriate severity.
--
-- NOTES
--     White-label, repeatable health report — the standing morning query set, the same every
--     day. Read-only against live systems. Table/column names follow the OUAF/C2M batch model
--     and Oracle data-dictionary views — verify object names for your version (they are cited,
--     not invented). Integration/queue tables vary by adapter; the queue section is a template
--     to point at your integration staging table.

SET PAGESIZE 60
SET LINESIZE 180
SET FEEDBACK OFF

PROMPT ============================================================
PROMPT  C2M Runbook - Health - Daily Routine  (DB detail, read-only)
PROMPT ============================================================

PROMPT
PROMPT -- 1. Batch runs in the last 24 hours (status + duration) --
SELECT batch_cd,
       batch_nbr,
       COUNT(*)                                                       AS threads,
       SUM(CASE WHEN batch_thread_stat_flg = '50' THEN 1 ELSE 0 END)  AS completed,
       SUM(CASE WHEN batch_thread_stat_flg = '60' THEN 1 ELSE 0 END)  AS errored,
       MIN(start_dttm)                                                AS started,
       MAX(end_dttm)                                                  AS ended,
       ROUND((MAX(end_dttm) - MIN(start_dttm)) * 24 * 60, 1)          AS minutes
  FROM ci_batch_inst
 WHERE start_dttm >= SYSDATE - 1
 GROUP BY batch_cd, batch_nbr
 ORDER BY started DESC;

PROMPT
PROMPT -- 2. Failed / errored threads in the last 24h (investigate each) --
SELECT batch_cd, batch_nbr, batch_thread_nbr, batch_thread_stat_flg AS status,
       start_dttm, end_dttm
  FROM ci_batch_inst
 WHERE batch_thread_stat_flg = '60'
   AND start_dttm >= SYSDATE - 1
 ORDER BY start_dttm DESC;

PROMPT
PROMPT -- 3. Batch Job Submission backlog (pending / queued) --
PROMPT    A non-zero backlog after the nightly cycle is an amber/red health item.
SELECT batch_cd,
       COUNT(*) AS pending
  FROM f1_batch_job
 WHERE batch_job_stat_flg IN ('P', 'PN')   -- pending / not started (verify status codes for your version)
 GROUP BY batch_cd
 ORDER BY pending DESC;

PROMPT
PROMPT -- 4. Tablespace space usage (space health) --
PROMPT    Tablespaces above ~85% used are an amber/red health item — engage the DBA.
SELECT df.tablespace_name,
       ROUND(SUM(df.bytes) / 1024 / 1024)                                    AS total_mb,
       ROUND((SUM(df.bytes) - NVL(SUM(fs.free_bytes), 0)) / 1024 / 1024)     AS used_mb,
       ROUND(100 * (SUM(df.bytes) - NVL(SUM(fs.free_bytes), 0)) / SUM(df.bytes), 1) AS pct_used
  FROM dba_data_files df
  LEFT JOIN (SELECT tablespace_name, SUM(bytes) AS free_bytes
               FROM dba_free_space
              GROUP BY tablespace_name) fs
    ON df.tablespace_name = fs.tablespace_name
 GROUP BY df.tablespace_name
 ORDER BY pct_used DESC;

-- NOTE: integration queue depth is adapter-specific. Point the following template at your
--       integration staging/queue table to include it in the daily snapshot:
-- SELECT queue_name, COUNT(*) AS depth FROM your_integration_stage_table
--  WHERE msg_stat_flg = 'PENDING' GROUP BY queue_name ORDER BY depth DESC;

PROMPT
PROMPT ============================================================
PROMPT  End of DB health detail. GREEN = all Complete, backlog 0, no tablespace over threshold.
PROMPT ============================================================
SET FEEDBACK ON
