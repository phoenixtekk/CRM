-- OSOAC2M-Discovery.sql — read-only inventory of C2M integration metadata (companion to OSOAC2M-Discovery.py).
--
-- PURPOSE
--     Read the C2M/OUAF integration metadata straight from the application schema: the
--     External Systems, Outbound Message Types (with processing method), Message Senders,
--     and Inbound Web Services. This is the C2M-side of the integration surface that the
--     WLST discovery cannot see. Read-only SELECTs only; run as the C2M read user against
--     your-c2m-schema. Table names follow OUAF conventions; verify for your version because
--     some names/columns differ by release (flagged inline).
--
-- HOW TO RUN
--     Connect with SQL*Plus or SQLcl as a read-capable C2M schema account, then:
--         sqlplus your-read-user/your-password@your-c2m-db @OSOAC2M-Discovery.sql
--     Or from SQLcl:  sql /nolog  ->  connect ...  ->  @OSOAC2M-Discovery.sql
--
-- EXPECTED RESULTS
--     Four result sets printed to the spool/console: external systems, outbound message
--     types + processing method, message senders, and inbound web services with status.
--     No rows changed — SELECT only. If a table name differs on your release, adjust it
--     per the OUAF data dictionary (My Oracle Support).
--
-- NOTES
--     White-label, repeatable. Strictly read-only — no INSERT/UPDATE/DELETE/DDL, safe on
--     production. Reconcile these names against the WebLogic/SOA surface (Discovery.py) so
--     C2M config and the deployed endpoints agree. Never store DB credentials in this file.

SET PAGESIZE 200
SET LINESIZE 200
SET FEEDBACK ON
COLUMN name FORMAT A40
COLUMN descr FORMAT A50
COLUMN cd FORMAT A30

PROMPT
PROMPT ==== EXTERNAL SYSTEMS (integration targets) ====
-- OUAF external systems. Table CI_EXT_SYS / language table CI_EXT_SYS_L (verify for your version).
SELECT e.EXT_SYS_ID          AS cd,
       l.DESCR               AS descr
FROM   CI_EXT_SYS e
       LEFT JOIN CI_EXT_SYS_L l
              ON l.EXT_SYS_ID = e.EXT_SYS_ID
             AND l.LANGUAGE_CD = 'ENG'
ORDER  BY e.EXT_SYS_ID;

PROMPT
PROMPT ==== OUTBOUND MESSAGE TYPES (with processing method) ====
-- Outbound message types per external system. Table CI_OUTMSG_TYPE (verify for your version).
-- MSG_XSL / processing-method columns vary by release; the PROC_METH / rout-type distinguishes
-- SOA (OSB-polled) vs real-time vs JMS — confirm the column name in your OUAF data dictionary.
SELECT t.OUTMSG_TYPE_CD      AS cd,
       t.EXT_SYS_ID          AS name,
       l.DESCR               AS descr
FROM   CI_OUTMSG_TYPE t
       LEFT JOIN CI_OUTMSG_TYPE_L l
              ON l.OUTMSG_TYPE_CD = t.OUTMSG_TYPE_CD
             AND l.LANGUAGE_CD = 'ENG'
ORDER  BY t.EXT_SYS_ID, t.OUTMSG_TYPE_CD;

PROMPT
PROMPT ==== MESSAGE SENDERS ====
-- Message senders (real-time HTTP/SOAP, JMS, etc.). Table CI_MSG_SENDER (verify for your version).
-- INVOCATION_TYPE / class distinguishes the transport (real-time vs JMS vs SOA).
SELECT s.MSG_SENDER_CD       AS cd,
       l.DESCR               AS descr
FROM   CI_MSG_SENDER s
       LEFT JOIN CI_MSG_SENDER_L l
              ON l.MSG_SENDER_CD = s.MSG_SENDER_CD
             AND l.LANGUAGE_CD = 'ENG'
ORDER  BY s.MSG_SENDER_CD;

PROMPT
PROMPT ==== INBOUND WEB SERVICES (IWS) ====
-- Inbound web service metadata (the IWS records exposed via spl-web-services). Table
-- F1_IWS_SVC (verify for your version); ACTIVE / status column indicates enabled services.
SELECT w.IWS_NAME            AS name,
       w.IWS_ACTIVE_FLG      AS cd,
       l.DESCR               AS descr
FROM   F1_IWS_SVC w
       LEFT JOIN F1_IWS_SVC_L l
              ON l.IWS_NAME = w.IWS_NAME
             AND l.LANGUAGE_CD = 'ENG'
ORDER  BY w.IWS_NAME;

PROMPT
PROMPT ==== END OF C2M INTEGRATION METADATA INVENTORY ====
PROMPT Reconcile the above against the WebLogic/SOA surface from OSOAC2M-Discovery.py.
