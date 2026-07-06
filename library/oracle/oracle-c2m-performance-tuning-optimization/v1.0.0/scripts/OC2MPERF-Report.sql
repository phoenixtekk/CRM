-- OC2MPERF-Report.sql — read-only Oracle Database performance snapshot for C2M tuning.
--
-- PURPOSE
--     Companion to OC2MPERF-Report.sh: capture the database side of the baseline/evidence pack
--     WITHOUT changing anything. Reports the top SQL by elapsed time, the top wait events, and
--     the session/process capacity headroom that pool and batch tuning depend on. Use it to see
--     whether the database is the bottleneck (layer 4) and whether it has headroom for more
--     connections/threads. Connect as a monitoring account for the C2M schema/instance.

-- HOW TO RUN
--     sqlplus /nolog @OC2MPERF-Report.sql
--     (it issues CONNECT and prompts for credentials; or run it from OC2MPERF-Report.sh -d.
--      Requires read access to V$ views; AWR views additionally require the Diagnostics Pack.)

-- EXPECTED RESULTS
--     Three read-only sections printed: top-10 SQL by elapsed time, top-10 foreground wait events,
--     and processes/sessions usage vs limit. PASS = sections print and sessions/processes are
--     within limit with headroom; FAIL = a section errors (insufficient privilege or unlicensed
--     AWR view) — grant read access or fall back to the V$ sections only.

-- NOTES
--     White-label, repeatable DB baseline. READ-ONLY: SELECT-only against V$/GV$ dynamic
--     performance views. AWR/ASH require the Oracle Diagnostics Pack — verify your licensing;
--     if unlicensed, use Statspack or the V$ sections here only. Never alter product schema.

WHENEVER SQLERROR CONTINUE
SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK OFF

-- Prompted connect keeps credentials out of the script.
CONNECT

PROMPT
PROMPT ============================================================
PROMPT  OC2MPERF DB snapshot (read-only) : &_DATE
PROMPT ============================================================

PROMPT
PROMPT --- Section 1: Top 10 SQL by total elapsed time (V$SQL) ---
COLUMN sql_id        FORMAT A15
COLUMN elapsed_sec   FORMAT 999990.0
COLUMN execs         FORMAT 99999990
COLUMN per_exec_ms   FORMAT 999990.00
COLUMN sql_text      FORMAT A70 TRUNCATE
SELECT * FROM (
  SELECT sql_id,
         ROUND(elapsed_time/1e6, 1)                                   AS elapsed_sec,
         executions                                                   AS execs,
         ROUND(elapsed_time/1000/GREATEST(executions,1), 2)           AS per_exec_ms,
         SUBSTR(sql_text, 1, 70)                                       AS sql_text
  FROM   v$sql
  ORDER BY elapsed_time DESC
)
WHERE ROWNUM <= 10;

PROMPT
PROMPT --- Section 2: Top 10 foreground wait events (V$SYSTEM_EVENT) ---
COLUMN event              FORMAT A45
COLUMN total_waits        FORMAT 999999999990
COLUMN time_waited_sec    FORMAT 99999990.0
COLUMN avg_ms             FORMAT 999990.00
SELECT * FROM (
  SELECT event,
         total_waits,
         ROUND(time_waited_micro/1e6, 1)                              AS time_waited_sec,
         ROUND(average_wait*10, 2)                                    AS avg_ms
  FROM   v$system_event
  WHERE  wait_class <> 'Idle'
  ORDER BY time_waited_micro DESC
)
WHERE ROWNUM <= 10;

PROMPT
PROMPT --- Section 3: Sessions / processes headroom (pool + batch capacity gate) ---
COLUMN resource_name  FORMAT A20
COLUMN current_util   FORMAT 9999990
COLUMN max_util       FORMAT 9999990
COLUMN limit_value    FORMAT A12
SELECT resource_name,
       current_utilization AS current_util,
       max_utilization     AS max_util,
       limit_value
FROM   v$resource_limit
WHERE  resource_name IN ('processes', 'sessions');

PROMPT
PROMPT --- Optional (Diagnostics Pack): top SQL from the latest AWR interval ---
PROMPT --- If the next query errors, AWR is not licensed/available; ignore and use Sections 1-3. ---
COLUMN sql_id      FORMAT A15
COLUMN awr_ela_sec FORMAT 999990.0
SELECT * FROM (
  SELECT sql_id,
         ROUND(SUM(elapsed_time_delta)/1e6, 1) AS awr_ela_sec
  FROM   dba_hist_sqlstat
  GROUP BY sql_id
  ORDER BY SUM(elapsed_time_delta) DESC
)
WHERE ROWNUM <= 10;

PROMPT
PROMPT DB snapshot complete. Record top-SQL, top-waits, and sessions/processes headroom as baseline.
SET FEEDBACK ON
DISCONNECT
