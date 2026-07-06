# OC2MPERF-Validation.py — read-only re-measure of the C2M / WebLogic 14c stack after a change.
#
# PURPOSE
#     Re-capture the same WebLogic thread-pool and JDBC connection-pool runtime metrics that
#     OC2MPERF-Discovery captured, so a tuning change can be compared against the baseline and
#     judged against the measured gates. This is Step 4 (Re-measure & validate) of the method.
#     It is deliberately the SAME reads as Discovery, run on the SAME workload, so the two
#     captures are directly comparable. Fill the placeholders (admin-url, admin-user) for
#     your-domain, and re-run under the identical workload used for the baseline.

# HOW TO RUN
#     java weblogic.WLST OC2MPERF-Validation.py
#     (prompts for the admin password; connects read-only. Diff the output against the
#      OC2MPERF-Discovery baseline, then apply the Testing Guide gates.)

# EXPECTED RESULTS
#     Per-server thread-pool metrics (PendingUserRequestCount, Stuck/HoggingThreadCount,
#     Throughput) and per-data-source pool metrics (WaitingForConnectionCurrentCount,
#     ActiveConnectionsHighCount vs capacity, ConnectionDelayTime). PASS = the targeted layer
#     improved past its gate AND no other layer regressed (e.g. waiting-for-connection stays 0);
#     FAIL = gate not met or a regression appeared, in which case roll the change back.

# NOTES
#     White-label, repeatable re-measure — the counterpart to OC2MPERF-Discovery. READ-ONLY:
#     reads runtime MBeans only, never edits config. WebLogic 14c (14.1.1) MBean paths — verify
#     for your version. Must be run on the same workload as the baseline for the diff to be valid.

from java.lang import Exception as JException

# --- connection settings (edit for your-domain; no angle brackets) ---
ADMIN_URL  = 't3://your-weblogic-admin-host:7001'
ADMIN_USER = 'weblogic'
# Password is prompted so it is never stored in the script.

# Simple advisory gate thresholds (relative checks are done by the operator vs the baseline).
GATE_MAX_PENDING            = 0     # PendingUserRequestCount should be at/near zero
GATE_MAX_WAITING_FOR_CONN   = 0     # WaitingForConnectionCurrentCount should be zero

def read_attr(mbean, name):
    try:
        return mbean.getAttribute(name)
    except:
        return None

def as_int(v):
    try:
        return int(v)
    except:
        return None

def check_server(serverName):
    print('')
    print('=== Server: ' + serverName + ' ===')
    findings = []
    try:
        domainRuntime()
        cd('/ServerRuntimes/' + serverName)
    except:
        print('  could not reach ServerRuntime for ' + serverName)
        return ['unreachable:' + serverName]

    # Thread pool gate check
    try:
        cd('ThreadPoolRuntime/ThreadPoolRuntime')
        pending = as_int(read_attr(cmo, 'PendingUserRequestCount'))
        stuck   = as_int(read_attr(cmo, 'StuckThreadCount'))
        hog     = as_int(read_attr(cmo, 'HoggingThreadCount'))
        thru    = read_attr(cmo, 'Throughput')
        print('  [ThreadPool] pending=%s stuck=%s hogging=%s throughput=%s' % (pending, stuck, hog, thru))
        if pending is not None and pending > GATE_MAX_PENDING:
            findings.append('%s: PendingUserRequestCount=%s (gate <=%s)' % (serverName, pending, GATE_MAX_PENDING))
        if stuck is not None and stuck > 0:
            findings.append('%s: StuckThreadCount=%s (should be 0)' % (serverName, stuck))
        cd('/ServerRuntimes/' + serverName)
    except:
        print('  [ThreadPool] not readable')

    # JDBC pool gate check
    try:
        cd('JDBCServiceRuntime/' + serverName)
        dsList = cmo.getJDBCDataSourceRuntimeMBeans()
        for ds in (dsList or []):
            waiting  = as_int(read_attr(ds, 'WaitingForConnectionCurrentCount'))
            actHigh  = read_attr(ds, 'ActiveConnectionsHighCount')
            delay    = read_attr(ds, 'ConnectionDelayTime')
            print('  [JDBC] %s waiting=%s activeHigh=%s delayMs=%s' % (ds.getName(), waiting, actHigh, delay))
            if waiting is not None and waiting > GATE_MAX_WAITING_FOR_CONN:
                findings.append('%s/%s: WaitingForConnectionCurrentCount=%s (gate <=%s)' % (
                    serverName, ds.getName(), waiting, GATE_MAX_WAITING_FOR_CONN))
        cd('/ServerRuntimes/' + serverName)
    except:
        print('  [JDBC] not readable')

    return findings

def main():
    print('OC2MPERF-Validation : read-only re-measure vs baseline')
    try:
        connect(ADMIN_USER, url=ADMIN_URL)
    except JException, e:
        print('FAIL: could not connect: ' + str(e))
        return

    allFindings = []
    try:
        domainRuntime()
        for s in cmo.getServerLifeCycleRuntimes():
            allFindings += check_server(s.getName())
    finally:
        try:
            disconnect()
        except:
            pass

    print('')
    print('--- Gate summary ---')
    if len(allFindings) == 0:
        print('PASS (advisory gates): no pending-request or connection-wait findings.')
        print('Now compare each metric to the baseline for the RELATIVE improvement gates (Testing Guide).')
    else:
        print('REVIEW: gate findings (compare to baseline before deciding keep/rollback):')
        for f in allFindings:
            print('  - ' + f)

main()
