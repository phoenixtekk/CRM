# OC2MPERF-Remediation.py — apply ONE validated WebLogic tuning change (DRY-RUN by default).
#
# PURPOSE
#     Apply a single, validated tuning change to a WebLogic 14c JDBC data-source connection pool
#     from the measure-first method: Maximum Capacity, Initial Capacity, Test-Connections-On-Reserve,
#     and Statement Cache Size. It changes ONE data source per run and, by default, only PRINTS the
#     planned edit (dry-run). It applies nothing unless explicitly told to. Use it after a change has
#     passed its gate on the pilot. Fill placeholders (admin-url, admin-user, datasource-name) for
#     your-domain.

# HOW TO RUN
#     Dry-run (default, changes nothing):
#         java weblogic.WLST OC2MPERF-Remediation.py
#     Apply for real (edits + activates the change):
#         java weblogic.WLST OC2MPERF-Remediation.py apply
#     (prompts for the admin password. Back up the domain config first; run in a change window.)

# EXPECTED RESULTS
#     Dry-run: prints current vs proposed values for the target data source and exits WITHOUT
#     editing. Apply: opens an edit session, sets the values, and activates — printing the before
#     and after. PASS = dry-run shows the intended change, or apply reports activation succeeded;
#     FAIL = it reports the data source was not found or activation failed (nothing left half-applied
#     — it cancels the edit on error).

# NOTES
#     White-label, repeatable, production-safe remediation. DRY-RUN by default; it WRITES only when
#     the 'apply' argument is passed AND after opening a proper edit/activate session. Tunes one data
#     source per run (one change at a time, per the method). Attribute names are for WebLogic 14c
#     (14.1.1) — verify for your version. Re-measure with OC2MPERF-Validation after applying.

import sys
from java.lang import Exception as JException

# --- settings (edit for your-domain; no angle brackets) ---
ADMIN_URL       = 't3://your-weblogic-admin-host:7001'
ADMIN_USER      = 'weblogic'
DATASOURCE_NAME = 'your-datasource-name'

# --- proposed values (set only the ones you intend to change; None = leave unchanged) ---
PROPOSED_MAX_CAPACITY        = None    # e.g. 50
PROPOSED_INITIAL_CAPACITY    = None    # e.g. 50 (match Maximum Capacity to pre-create)
PROPOSED_TEST_ON_RESERVE     = None    # e.g. True
PROPOSED_STMT_CACHE_SIZE     = None    # e.g. 100

APPLY = (len(sys.argv) > 1 and sys.argv[1].lower() == 'apply')

def show(label, cur, proposed):
    if proposed is None:
        print('    %-26s current=%s  (unchanged)' % (label, cur))
    else:
        print('    %-26s current=%s  -> proposed=%s' % (label, cur, proposed))

def main():
    mode = 'APPLY' if APPLY else 'DRY-RUN'
    print('OC2MPERF-Remediation : data-source pool tuning [%s]' % mode)
    print('Target data source: ' + DATASOURCE_NAME)

    try:
        connect(ADMIN_USER, url=ADMIN_URL)
    except JException, e:
        print('FAIL: could not connect: ' + str(e))
        return

    dsPath = '/JDBCSystemResources/' + DATASOURCE_NAME + '/JDBCResource/' + DATASOURCE_NAME
    try:
        # Read current values (read-only navigation of the config MBeans).
        cd(dsPath + '/JDBCConnectionPoolParams/' + DATASOURCE_NAME)
        curMax   = cmo.getMaxCapacity()
        curInit  = cmo.getInitialCapacity()
        curTest  = cmo.getTestConnectionsOnReserve()
        curStmt  = cmo.getStatementCacheSize()
    except JException, e:
        print('FAIL: data source not found or not readable: ' + DATASOURCE_NAME + ' (' + str(e) + ')')
        disconnect()
        return

    print('  Planned change:')
    show('MaxCapacity',           curMax,  PROPOSED_MAX_CAPACITY)
    show('InitialCapacity',       curInit, PROPOSED_INITIAL_CAPACITY)
    show('TestConnectionsOnReserve', curTest, PROPOSED_TEST_ON_RESERVE)
    show('StatementCacheSize',    curStmt, PROPOSED_STMT_CACHE_SIZE)

    if not APPLY:
        print('')
        print('DRY-RUN: no changes made. Re-run with the argument  apply  to write these values.')
        disconnect()
        return

    # APPLY path: proper edit session with activate; cancel on any error.
    try:
        edit()
        startEdit()
        cd(dsPath + '/JDBCConnectionPoolParams/' + DATASOURCE_NAME)
        if PROPOSED_MAX_CAPACITY is not None:
            cmo.setMaxCapacity(int(PROPOSED_MAX_CAPACITY))
        if PROPOSED_INITIAL_CAPACITY is not None:
            cmo.setInitialCapacity(int(PROPOSED_INITIAL_CAPACITY))
        if PROPOSED_TEST_ON_RESERVE is not None:
            cmo.setTestConnectionsOnReserve(bool(PROPOSED_TEST_ON_RESERVE))
        if PROPOSED_STMT_CACHE_SIZE is not None:
            cmo.setStatementCacheSize(int(PROPOSED_STMT_CACHE_SIZE))
        save()
        activate(block='true')
        print('')
        print('PASS: change activated for ' + DATASOURCE_NAME + '. Now re-measure with OC2MPERF-Validation.')
    except JException, e:
        print('FAIL during apply: ' + str(e))
        try:
            cancelEdit('y')
            print('Edit session cancelled — no partial change left in place.')
        except:
            pass
    finally:
        try:
            disconnect()
        except:
            pass

main()
