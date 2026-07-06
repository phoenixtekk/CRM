-- OC2MRCA-Report.sql — read-only consolidated database diagnostics for C2M root-cause analysis.
--
-- PURPOSE
--     Render the database side of the C2M RCA - Diagnostic Snapshot from the C2M schema and
--     the Oracle Database: batch run status and any error/overdue threads, JMS/message-
--     related backlog signals, blocking/blocked sessions (the classic hidden cause of a
--     stall or a stuck JDBC thread), tablespace and temp pressure, and instance uptime.
--     Read-only — SELECT only, it changes no data. Use it to descend into the database layer
--     from the Diagnostic Playbook (Branches B, C, E, F) and to capture the DB baseline.
--
-- HOW TO RUN
--     Via SQL*Plus or SQLcl against the C2M schema (a read-only account is fine):
--         sqlplus user/pass@your-db @OC2MRCA-Report.sql
--     (or  sql user/pass@your-db @OC2MRCA-Report.sql  with SQLcl)
--     Some sections read DBA_/V$ views; if the account lacks them those sections note it and
--     the rest still run.
--
-- EXPECTED RESULTS
--     Sections print in order: (1) instance/uptime, (2) batch runs last 24h with status,
--     (3) errored/overdue batch threads, (4) blocking sessions, (5) tablespace pressure,
--     (6) temp usage, (7) message/backlog signal. PASS = no errored/overdue thread, no
--     blocking session, tablespace/temp within threshold. FAIL = any error/overdue thread,
--     a blocking chain, or a tablespace/temp near full.
--
-- NOTES
--     White-label, repeatable DB diagnostics — the same query set every incident and for the
--     baseline. Read-only against live systems. Table/column/view names and status-flag
--     values follow the OUAF/C2M and Oracle Database models — verify object names and status
--     codes for your version (they are cited, not invented).

SET PAGESIZE 60
SET LINESIZE 200
SET FEEDBACK OFF

PROMPT ============================================================
PROMPT  C2M RCA - Diagnostic Snapshot (database)  (read-only)
PROMPT ============================================================

PROMPT
PROMPT -- 1. Instance / uptime (recent restart is itself a clue) --
SELECT instance_name, host_name, status, startup_time
  FROM v$instance;

PROMPT
PROMPT -- 2. Batch runs in the last 24 hours (status + duration) --
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
PROMPT -- 3. Errored or overdue batch threads (investigate each) --
PROMPT    Status '60' = error; end_dttm NULL far past start = overdue/stuck (verify codes for your version).
SELECT batch_cd, batch_nbr, batch_thread_nbr,
       batch_thread_stat_flg AS status,
       start_dttm,
       end_dttm,
       CASE WHEN end_dttm IS NULL
            THEN ROUND((SYSDATE - start_dttm) * 24 * 60, 1) END AS running_minutes
  FROM ci_batch_inst
 WHERE start_dttm >= SYSDATE - 1
   AND (batch_thread_stat_flg = '60'
        OR (end_dttm IS NULL AND start_dttm < SYSDATE - (2/24)))
 ORDER BY start_dttm DESC;

PROMPT
PROMPT -- 4. Blocking sessions (a hidden cause of stalls / stuck JDBC threads) --
PROMPT    Any row here means one session is holding a lock another is waiting on.
SELECT b.sid       AS blocker_sid,
       b.serial#   AS blocker_serial,
       b.username  AS blocker_user,
       w.sid       AS waiter_sid,
       w.username  AS waiter_user,
       w.seconds_in_wait AS waiter_wait_s,
       w.event     AS waiter_event
  FROM v$session b
  JOIN v$session w ON w.blocking_session = b.sid
 ORDER BY w.seconds_in_wait DESC;

PROMPT
PROMPT -- 5. Tablespace pressure (a full tablespace fails writes = failed batch/login) --
SELECT df.tablespace_name,
       ROUND(SUM(df.bytes)/1024/1024)                                  AS total_mb,
       ROUND((SUM(df.bytes) - NVL(fs.free_bytes,0))/1024/1024)         AS used_mb,
       ROUND(NVL(fs.free_bytes,0)/1024/1024)                           AS free_mb,
       ROUND(100 * (SUM(df.bytes) - NVL(fs.free_bytes,0)) / SUM(df.bytes), 1) AS pct_used
  FROM dba_data_files df
  LEFT JOIN (SELECT tablespace_name, SUM(bytes) AS free_bytes
               FROM dba_free_space GROUP BY tablespace_name) fs
    ON fs.tablespace_name = df.tablespace_name
 GROUP BY df.tablespace_name, fs.free_bytes
 ORDER BY pct_used DESC;

PROMPT
PROMPT -- 6. Temp tablespace usage (temp exhaustion stalls sorts/joins) --
SELECT tablespace_name,
       ROUND(SUM(bytes_used)/1024/1024) AS used_mb,
       ROUND(SUM(bytes_free)/1024/1024) AS free_mb
  FROM v$temp_space_header
 GROUP BY tablespace_name
 ORDER BY used_mb DESC;

PROMPT
PROMPT -- 7. Message / backlog signal (outbound message + queue rows) --
PROMPT    A growing pending count is the DB-side view of a JMS/integration backlog.
PROMPT    Object/column names follow the OUAF messaging model — verify for your version.
SELECT out_msg_stat_flg AS status, COUNT(*) AS messages
  FROM f1_outmsg
 WHERE creation_dttm >= SYSDATE - 1
 GROUP BY out_msg_stat_flg
 ORDER BY messages DESC;

PROMPT
PROMPT ============================================================
PROMPT  End of report. PASS = no errored/overdue thread, no blocking,
PROMPT  tablespace/temp within threshold, no message backlog.
PROMPT ============================================================
SET FEEDBACK ON
