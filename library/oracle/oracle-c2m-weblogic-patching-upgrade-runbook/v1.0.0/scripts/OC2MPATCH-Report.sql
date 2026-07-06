-- OC2MPATCH-Report.sql — read-only patch/version coverage report from the C2M database.
--
-- PURPOSE
--     Produce the database side of the patch/version coverage record for the change: the Oracle
--     Database version, the OUAF/C2M schema release and applied-fix rows, and a count of invalid
--     objects (a post-patch health signal). Run against the C2M schema. Read-only SELECTs only;
--     it makes no changes. Pair its output with the WebLogic/OS baseline from OC2MPATCH-Discovery.sh.
--
-- HOW TO RUN
--     sqlplus your-c2m-schema/your-password@your-tns @OC2MPATCH-Report.sql
--     (or:  sql your-c2m-schema/your-password@your-tns @OC2MPATCH-Report.sql )
--
-- EXPECTED RESULTS
--     A printed report: DB version, C2M/OUAF schema release/fixes, and invalid-object count.
--     Compare release/fixes to the intended target (e.g. 25.4). Invalid-object count should not
--     have grown because of the change; investigate any increase before promoting (Gate C).
--
-- NOTES
--     Oracle — C2M/WebLogic patching. Read-only SQL. The repeatable way: run the same report in
--     every environment, baseline vs post-apply, so drift between nodes/environments is caught.
--     Table/view names for the OUAF fix inventory vary by release — verify for your version.

SET PAGESIZE 200
SET LINESIZE 200
SET FEEDBACK OFF

PROMPT
PROMPT === OC2MPATCH — database coverage report (read-only) ===

PROMPT
PROMPT -- Oracle Database version --
SELECT banner AS db_version FROM v$version;

PROMPT
PROMPT -- C2M / OUAF schema release (verify table/view name for your version) --
-- The framework records its installed version in a framework table; the name differs by release.
-- Common candidates include CI_INSTALLATION / F1_* metadata. Adjust to your schema, then uncomment:
-- SELECT version_number, patch_level FROM ci_installation;
PROMPT (edit this query to your framework version table — see the release install guide on MOS)

PROMPT
PROMPT -- Invalid objects in the C2M schema (post-patch health signal) --
SELECT object_type, COUNT(*) AS invalid_count
FROM   user_objects
WHERE  status = 'INVALID'
GROUP  BY object_type
ORDER  BY object_type;

PROMPT
PROMPT -- Total invalid objects (should not have grown due to the change) --
SELECT COUNT(*) AS total_invalid
FROM   user_objects
WHERE  status = 'INVALID';

PROMPT
PROMPT === Report complete — compare release/fixes to target; investigate any new invalid objects ===

SET FEEDBACK ON
