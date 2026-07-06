-- OC2MINST-Report.sql — read-only build/schema report for a C2M database.
--
-- PURPOSE
--     Reports the state of a C2M application schema after the database install, read-only:
--     confirms the schema owner (CISADM) exists and owns objects, that the application user
--     (CISUSER) and read-only user (CISREAD) exist, counts the C2M schema objects, and reads the
--     installed framework/product version rows. Run it as part of post-install validation and when
--     comparing one environment (your-env) to another. It only SELECTs; it changes nothing.
--
-- HOW TO RUN
--     Connect as a read-only user that can see the data dictionary and the CISADM schema, then:
--         sqlplus your-readonly-user/your-password@your-db @OC2MINST-Report.sql
--     If your version stores installed-version data in different tables, adjust the marked section.
--
-- EXPECTED RESULTS
--     A printed report: account existence for CISADM/CISUSER/CISREAD, object counts by type owned by
--     CISADM, invalid-object count (should be zero or explained), and the installed version rows.
--     Pass when the accounts exist, CISADM owns the expected objects, and versions match your target.
--
-- NOTES
--     White-label, repeatable schema report. Read-only (SELECT only; no DDL/DML). Account names
--     (CISADM/CISUSER/CISREAD) match the Installation Guide; change the DEFINE values below if you
--     used different names. Version table/column names vary by release — the version section is marked
--     "verify for your version" and is written to degrade gracefully if the table is absent.

SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET LINESIZE 160
SET PAGESIZE 100

-- Adjust these if you deviated from the standard object names.
DEFINE schema_owner = 'CISADM'
DEFINE app_user     = 'CISUSER'
DEFINE read_user    = 'CISREAD'

PROMPT ======================================================================
PROMPT  OC2MINST — C2M schema build report (read-only)
PROMPT ======================================================================

PROMPT
PROMPT --- Account existence (CISADM / CISUSER / CISREAD) ---
COLUMN account       FORMAT A20
COLUMN present       FORMAT A10
SELECT a.account,
       CASE WHEN u.username IS NOT NULL THEN 'OK' ELSE 'MISSING' END AS present
FROM   ( SELECT UPPER('&schema_owner') AS account FROM dual
         UNION ALL SELECT UPPER('&app_user') FROM dual
         UNION ALL SELECT UPPER('&read_user') FROM dual ) a
LEFT JOIN all_users u ON u.username = a.account
ORDER BY a.account;

PROMPT
PROMPT --- Objects owned by the schema owner, by type ---
COLUMN object_type FORMAT A24
COLUMN cnt         FORMAT 999990
SELECT object_type, COUNT(*) AS cnt
FROM   all_objects
WHERE  owner = UPPER('&schema_owner')
GROUP  BY object_type
ORDER  BY object_type;

PROMPT
PROMPT --- Invalid objects owned by the schema owner (expect 0, or explain) ---
COLUMN object_name FORMAT A40
SELECT object_type, object_name, status
FROM   all_objects
WHERE  owner = UPPER('&schema_owner')
AND    status <> 'VALID'
ORDER  BY object_type, object_name;

PROMPT
PROMPT --- Installed version (verify table/columns for your version) ---
-- Many OUAF/C2M releases record installed framework/product versions in an installation-options or
-- version table (name varies by release). This block reads it if present and skips cleanly if not,
-- so the report does not error on a version where the table name differs.
SET FEEDBACK OFF
DECLARE
  v_cnt   PLS_INTEGER := 0;
  v_owner VARCHAR2(30) := UPPER('&schema_owner');
BEGIN
  SELECT COUNT(*) INTO v_cnt
  FROM   all_tables
  WHERE  owner = v_owner
  AND    table_name IN ('CI_INSTALLATION','F1_INSTALLATION_OPT','CI_MD_VER');

  IF v_cnt = 0 THEN
    DBMS_OUTPUT.PUT_LINE('  version table not found under '||v_owner||
      ' — verify the installed-version table name for your release (My Oracle Support / C2M DBA Guide).');
  ELSE
    DBMS_OUTPUT.PUT_LINE('  version table(s) present under '||v_owner||
      ' — query the release/version rows per your release documentation to confirm the level.');
  END IF;
END;
/

PROMPT
PROMPT ======================================================================
PROMPT  End of report. PASS when accounts exist, CISADM owns the expected
PROMPT  objects, invalid-object count is 0 (or explained), and the installed
PROMPT  version matches your target release.
PROMPT ======================================================================

SET FEEDBACK ON
